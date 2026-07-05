"""session-vault-export plugin — archive finished Hermes sessions into the
knowledge-base vault as Markdown, then push via git.

Wires a single hook:

``on_session_finalize`` — fires on ``/new``, gateway shutdown, and session
expiry (idle 24h / daily 4am sweep). Trivial sessions (fewer than
``_MIN_MESSAGES`` messages) are skipped. The Markdown file is named after the
session id so repeated finalize calls for the same session (e.g. shutdown
after an earlier idle-expiry pass) overwrite the same file instead of
duplicating it.

``invoke_hook`` calls registered callbacks synchronously on the gateway's
event loop thread, so this handler must never block. Reading the session DB
is a fast local SQLite read; the git push is offloaded to a detached
subprocess (``start_new_session=True``) so a slow or hanging network call
never stalls the gateway.
"""

from __future__ import annotations

import json
import logging
import re
import shlex
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from hermes_constants import get_hermes_home

logger = logging.getLogger(__name__)

_VAULT_REPO = Path("/var/lib/hermes/workspace/knowledge-base")
_SESSIONS_DIR = _VAULT_REPO / "Agents" / "Hermes-Agent" / "sessions"
_MIN_MESSAGES = 4
_SECRET_PREFIXES = ("xox", "ghp_", "sk-", "AKIA")


def _db_path() -> Path:
    return get_hermes_home() / "state.db"


def _redact_secrets(text: str) -> str:
    """Replace any line that looks like it carries a token/key with a marker."""
    lines = text.split("\n")
    return "\n".join(
        "[REDACTED]" if any(p in line for p in _SECRET_PREFIXES) else line
        for line in lines
    )


def _safe_short_id(session_id: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9_-]", "", session_id)
    return cleaned[:12] or "session"


def _iso(ts: Any) -> str:
    try:
        return datetime.fromtimestamp(float(ts), tz=timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        )
    except (TypeError, ValueError, OSError):
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _content_to_text(content: Any) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and "text" in item:
                parts.append(str(item["text"]))
            elif isinstance(item, dict):
                parts.append(json.dumps(item, ensure_ascii=False))
            else:
                parts.append(str(item))
        return "\n".join(parts)
    if isinstance(content, dict):
        return json.dumps(content, ensure_ascii=False, indent=2)
    return str(content)


def _render_tool_calls(tool_calls: Any) -> str:
    if not tool_calls:
        return ""
    try:
        body = json.dumps(tool_calls, ensure_ascii=False, indent=2)
    except (TypeError, ValueError):
        body = str(tool_calls)
    return f"```json\n{body}\n```"


def _render_message(msg: Dict[str, Any]) -> str:
    role = msg.get("role", "unknown")
    header = f"## {role} — {_iso(msg.get('timestamp'))}"
    parts = [header]
    text = _content_to_text(msg.get("content")).strip()
    if text:
        parts.append(text)
    tool_calls_md = _render_tool_calls(msg.get("tool_calls"))
    if tool_calls_md:
        parts.append(tool_calls_md)
    return "\n\n".join(parts)


def _derive_title(session: Dict[str, Any], messages: List[Dict[str, Any]]) -> str:
    title = session.get("title")
    if title:
        return str(title)
    for msg in messages:
        if msg.get("role") == "user":
            text = _content_to_text(msg.get("content")).strip().replace("\n", " ")
            if text:
                return text[:80]
    return "Untitled session"


def _find_existing(short_id: str) -> Optional[Path]:
    if not _SESSIONS_DIR.is_dir():
        return None
    matches = sorted(_SESSIONS_DIR.glob(f"*_auto-{short_id}*.md"))
    return matches[0] if matches else None


def _build_path(session: Dict[str, Any], short_id: str) -> Path:
    existing = _find_existing(short_id)
    if existing is not None:
        return existing
    try:
        dt = datetime.fromtimestamp(float(session.get("started_at")), tz=timezone.utc)
    except (TypeError, ValueError, OSError):
        dt = datetime.now(timezone.utc)
    stamp = dt.strftime("%Y-%m-%d_%H-%M")
    return _SESSIONS_DIR / f"{stamp}_auto-{short_id}.md"


def _build_markdown(
    session: Dict[str, Any],
    messages: List[Dict[str, Any]],
    platform: str,
    reason: str,
) -> str:
    title = _derive_title(session, messages)
    frontmatter = "\n".join(
        [
            "---",
            f"created: {_iso(session.get('started_at'))}",
            "tags: [session-log]",
            "type: session-log",
            "agent: Hermes-Agent",
            "auto: true",
            f"platform: {platform or 'unknown'}",
            f"end_reason: {reason or 'unknown'}",
            "---",
        ]
    )
    sections = [frontmatter, "", f"# {title}", ""]
    for msg in messages:
        rendered = _render_message(msg)
        if rendered:
            sections.append(rendered)
            sections.append("")
    return _redact_secrets("\n".join(sections))


def _push_to_vault(short_id: str) -> None:
    """Commit and push the exported file, detached so it never blocks the gateway."""
    cmd = (
        f"cd {shlex.quote(str(_VAULT_REPO))} && "
        "git pull --rebase -q; "
        "git add Agents/Hermes-Agent/sessions/ && "
        f"git commit -qm 'session(hermes): {short_id}' && "
        "git push -q"
    )
    subprocess.Popen(
        ["bash", "-c", cmd],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def _export_session(session_id: str, platform: str, reason: str) -> None:
    if not session_id:
        return
    if not _db_path().exists():
        return

    from hermes_state import SessionDB

    db = SessionDB(read_only=True)
    try:
        data = db.export_session(session_id)
    finally:
        conn = getattr(db, "_conn", None)
        if conn is not None:
            conn.close()

    if not data:
        return
    messages = data.get("messages") or []
    if len(messages) < _MIN_MESSAGES:
        return

    short_id = _safe_short_id(session_id)
    _SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    path = _build_path(data, short_id)
    path.write_text(_build_markdown(data, messages, platform, reason), encoding="utf-8")

    _push_to_vault(short_id)


def _on_session_finalize(
    session_id: str = "",
    platform: str = "",
    reason: str = "",
    **_: Any,
) -> None:
    try:
        _export_session(session_id, platform, reason)
    except Exception:
        logger.exception(
            "session-vault-export: failed to export session %s", session_id
        )


def register(ctx) -> None:
    ctx.register_hook("on_session_finalize", _on_session_finalize)
