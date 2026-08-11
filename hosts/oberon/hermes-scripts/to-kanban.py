#!/usr/bin/env python3
"""mattpocock/to-tickets の local files を Hermes kanban タスクへ変換する。

Usage:
    to-kanban <board-slug> <repo-path> <feature-slug>

Example:
    to-kanban thinceller-net /var/lib/hermes/workspace/thinceller.net add-hermes-kanban-post

以下の場所にチケットファイルがあることを期待する:
    <repo-path>/.scratch/<feature-slug>/issues/<NN>-<slug>.md

各ファイルは to-tickets の local-ticket-template 形式:
    # <NN> — <Ticket title>

    **What to build:** ...

    **Blocked by:** None — can start immediately
    # または
    **Blocked by:** #01, #02

    **Status:** ready-for-agent

    - [ ] Acceptance criterion 1

依存は必ず `#<番号>` の形で書くこと。タイトルだけの記述は解釈できない。
"""

import json
import re
import subprocess
import sys
from pathlib import Path

# 見出し: "# 01 — タイトル"。区切りは em dash / en dash / hyphen / コロン。
# 見出しレベルは # 1〜3個まで許す (upstream の to-tickets が ## や ### で書くことがある)。
_HEADING_RE = re.compile(r"^#{1,3}\s*(\d+)\s*[—–\-:：]\s*(.+)$")
# ファイル名からのフォールバック: "01-add-foo.md"
_FILENAME_NUM_RE = re.compile(r"^(\d+)")
# 依存先は '#' 必須。'#' を省くと本文中の数字を拾って依存を捏造してしまう。
_BLOCKER_RE = re.compile(r"#(\d+)")
# "None — can start immediately" のような「依存なし」表現。
_NO_BLOCKER_RE = re.compile(r"none|can start immediately", re.IGNORECASE)
# "**Blocked by:** ..." 行。upstream の to-tickets は箇条書き記号付きや
# コロンが太字の外に出た形も出力するため、緩めに受ける。
_BLOCKED_BY_LINE_RE = re.compile(
    r"^[-*+]?\s*\*\*\s*blocked\s+by\s*:?\s*\*\*\s*:?\s*(.*)$",
    re.IGNORECASE,
)


class TicketError(Exception):
    """チケットの内容や hermes 呼び出しが不正なときに送出する。"""


def normalize_num(raw: str) -> str:
    """チケット番号を2桁ゼロ埋めへ正規化する。'1' も '01' も '01' になる。"""
    return f"{int(raw):02d}"


def parse_blocked_by(rest: str, path: Path, line: str) -> list[str]:
    nums = _BLOCKER_RE.findall(rest)
    if nums:
        return [normalize_num(n) for n in nums]
    if not rest or _NO_BLOCKER_RE.search(rest):
        return []
    raise TicketError(
        f"Blocked by の依存先を解釈できません: {path}\n"
        f"  行: {line}\n"
        f"  依存先は '#01, #02' のようにチケット番号を # 付きで書いてください。"
    )


def parse_ticket(path: Path) -> dict:
    lines = path.read_text(encoding="utf-8").splitlines()

    num = None
    title = None
    body_start = 0

    if lines:
        m = _HEADING_RE.match(lines[0].strip())
        if m:
            num = normalize_num(m.group(1))
            title = m.group(2).strip()
            body_start = 1

    # 見出しが壊れていてもファイル名から番号を拾う。
    # この場合 1 行目は本文なので body から落とさない。
    if num is None:
        m = _FILENAME_NUM_RE.match(path.stem)
        if m:
            num = normalize_num(m.group(1))

    if num is None:
        raise TicketError(
            f"チケット番号を特定できません: {path}\n"
            f"  見出しを '# 01 — タイトル' 形式にするか、"
            f"ファイル名を '01-<slug>.md' 形式にしてください。"
        )

    if title is None:
        title = path.stem

    blocked_by = None
    for line in lines:
        m = _BLOCKED_BY_LINE_RE.match(line.strip())
        if m:
            blocked_by = parse_blocked_by(m.group(1).strip(), path, line.strip())
            break

    if blocked_by is None:
        raise TicketError(
            f"'**Blocked by:**' の行がありません: {path}\n"
            f"  依存が無いチケットにも "
            f"'**Blocked by:** None — can start immediately' を書いてください。"
        )

    return {
        "num": num,
        "title": title,
        "body": "\n".join(lines[body_start:]).strip(),
        "blocked_by": blocked_by,
    }


def validate(tickets: list[dict]) -> None:
    """タスクを1つも作る前に、チケット集合の整合性を確かめる。"""
    nums = [t["num"] for t in tickets]
    duplicates = sorted({n for n in nums if nums.count(n) > 1})
    if duplicates:
        raise TicketError(f"チケット番号が重複しています: {duplicates}")

    known = set(nums)
    unknown = [
        (t["num"], b) for t in tickets for b in t["blocked_by"] if b not in known
    ]
    if unknown:
        raise TicketError(
            "対応するチケットのない依存があります:\n"
            + "\n".join(f"  #{child} の Blocked by: #{parent}" for child, parent in unknown)
        )


def topo_sort(tickets: list[dict]) -> list[dict]:
    """依存元が必ず先に来る順へ並べ替える。循環があれば TicketError。"""
    by_num = {t["num"]: t for t in tickets}
    pending = {t["num"]: set(t["blocked_by"]) for t in tickets}
    ordered = []

    while pending:
        ready = sorted(num for num, deps in pending.items() if not deps)
        if not ready:
            cycle = ", ".join(
                f"#{num} -> {sorted(deps)}" for num, deps in sorted(pending.items())
            )
            raise TicketError(f"チケットの依存関係が循環しています: {cycle}")
        for num in ready:
            ordered.append(by_num[num])
            del pending[num]
        for deps in pending.values():
            deps.difference_update(ready)

    return ordered


def create_task(board: str, ticket: dict, repo_path: str, parent_ids: list[str]) -> str:
    """kanban タスクを作成して task id を返す。"""
    cmd = [
        "hermes", "kanban", "--board", board, "create", ticket["title"],
        "--body", ticket["body"],
        "--assignee", "worker",
        "--workspace", f"dir:{repo_path}",
        "--json",
    ]
    for parent_id in parent_ids:
        cmd.extend(["--parent", parent_id])

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise TicketError(
            f"hermes kanban create に失敗しました (exit {result.returncode}): {ticket['title']}\n"
            f"{result.stderr.strip() or result.stdout.strip()}"
        )
    return json.loads(result.stdout)["id"]


def main():
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    board_slug, repo_path, feature_slug = sys.argv[1:4]
    issues_dir = Path(repo_path) / ".scratch" / feature_slug / "issues"

    if not issues_dir.exists():
        print(f"チケットディレクトリがありません: {issues_dir}", file=sys.stderr)
        sys.exit(1)

    files = sorted(issues_dir.glob("*.md"))
    if not files:
        print(f"{issues_dir} に .md ファイルがありません", file=sys.stderr)
        sys.exit(1)

    try:
        tickets = [parse_ticket(f) for f in files]
        validate(tickets)
        ordered = topo_sort(tickets)
    except TicketError as e:
        print(e, file=sys.stderr)
        print("タスクは1つも作成していません。", file=sys.stderr)
        sys.exit(1)

    # 依存元が先に来る順に並んでいるので、作成時に --parent を渡すだけで依存が張れる。
    # 依存なしで作ってから link で張ると、その隙にタスクが ready のまま dispatcher に
    # 拾われてしまう (link は status='ready' のときしか todo へ降格させない)。
    num_to_id = {}
    for ticket in ordered:
        parent_ids = [num_to_id[n] for n in ticket["blocked_by"]]
        try:
            task_id = create_task(board_slug, ticket, repo_path, parent_ids)
        except TicketError as e:
            print(e, file=sys.stderr)
            print(
                f"{len(num_to_id)} 件のタスクは作成済みです。board を確認してください。",
                file=sys.stderr,
            )
            sys.exit(1)
        num_to_id[ticket["num"]] = task_id
        deps = ", ".join(f"#{n}" for n in ticket["blocked_by"]) or "なし"
        print(f"作成 {ticket['num']} -> {task_id}: {ticket['title']} (依存: {deps})")

    print("完了。")


if __name__ == "__main__":
    main()
