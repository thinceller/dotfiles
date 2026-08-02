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
"""

import json
import re
import subprocess
import sys
from pathlib import Path

# 見出し: "# 01 — タイトル"。区切りは em dash / en dash / hyphen / コロン。
_HEADING_RE = re.compile(r"^#\s*(\d+)\s*[—–\-:：]\s*(.+)$")
# ファイル名からのフォールバック: "01-add-foo.md"
_FILENAME_NUM_RE = re.compile(r"^(\d+)")

WORKER_SKILL = "kanban-worker-impl"


def normalize_num(raw: str) -> str:
    """チケット番号を2桁ゼロ埋めへ正規化する。'1' も '01' も '01' になる。"""
    return f"{int(raw):02d}"


def parse_ticket(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    title = None
    num = None

    if lines:
        m = _HEADING_RE.match(lines[0].strip())
        if m:
            num = normalize_num(m.group(1))
            title = m.group(2).strip()

    # 見出しが壊れていてもファイル名から番号を拾う。
    if num is None:
        m = _FILENAME_NUM_RE.match(path.stem)
        if m:
            num = normalize_num(m.group(1))

    if num is None:
        raise ValueError(
            f"チケット番号を特定できません: {path}\n"
            f"  見出しを '# 01 — タイトル' 形式にするか、"
            f"ファイル名を '01-<slug>.md' 形式にしてください。"
        )

    if title is None:
        title = path.stem

    body = "\n".join(lines[1:]).strip()

    blocked_by = []
    for line in lines:
        if line.strip().startswith("**Blocked by:**"):
            rest = line.split("**Blocked by:**", 1)[1].strip()
            if "None" in rest or "can start immediately" in rest.lower():
                break
            blocked_by = [normalize_num(n) for n in re.findall(r"#?(\d+)", rest)]
            break

    return {
        "num": num,
        "title": title,
        "body": body,
        "blocked_by": blocked_by,
        "path": path,
    }


def create_task(board: str, ticket: dict, repo_path: str) -> str:
    """kanban タスクを作成して task id を返す。"""
    cmd = [
        "hermes", "kanban", "--board", board, "create", ticket["title"],
        "--body", ticket["body"],
        "--assignee", "worker",
        "--workspace", f"dir:{repo_path}",
        "--skill", WORKER_SKILL,
        "--json",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(result.stdout)["id"]


def link_tasks(board: str, parent_id: str, child_id: str) -> None:
    """親→子の依存辺を張る。子は親が done になるまで ready にならない。"""
    subprocess.run(
        ["hermes", "kanban", "--board", board, "link", parent_id, child_id],
        capture_output=True, text=True, check=True,
    )


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

    tickets = [parse_ticket(f) for f in files]

    nums = [t["num"] for t in tickets]
    duplicates = sorted({n for n in nums if nums.count(n) > 1})
    if duplicates:
        print(f"チケット番号が重複しています: {duplicates}", file=sys.stderr)
        sys.exit(1)

    # パス1: 依存を張らずに全タスクを作る。
    # 後続チケットへの依存 (前方参照) があっても取りこぼさないため。
    num_to_id = {}
    for t in tickets:
        task_id = create_task(board_slug, t, repo_path)
        num_to_id[t["num"]] = task_id
        print(f"作成 {t['num']} -> {task_id}: {t['title']}")

    # パス2: 依存辺を張る。
    unresolved = []
    for t in tickets:
        child_id = num_to_id[t["num"]]
        for parent_num in t["blocked_by"]:
            parent_id = num_to_id.get(parent_num)
            if parent_id is None:
                unresolved.append((t["num"], parent_num))
                continue
            link_tasks(board_slug, parent_id, child_id)
            print(f"依存 {t['num']} <- {parent_num}")

    if unresolved:
        print("", file=sys.stderr)
        print("以下の依存を解決できませんでした (対応するチケットがありません):", file=sys.stderr)
        for child_num, parent_num in unresolved:
            print(f"  #{child_num} の Blocked by: #{parent_num}", file=sys.stderr)
        print(
            "作成済みのタスクは board に残っています。"
            "チケットファイルを直してから、不要なタスクを削除して再実行してください。",
            file=sys.stderr,
        )
        sys.exit(1)

    print("完了。")


if __name__ == "__main__":
    main()
