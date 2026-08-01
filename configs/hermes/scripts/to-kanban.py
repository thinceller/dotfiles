#!/usr/bin/env python3
"""Convert mattpocock/to-tickets local files into Hermes kanban tasks.

Usage:
    python to-kanban.py <board-slug> <repo-path> <feature-slug>

Example:
    python to-kanban.py thinceller-net /var/lib/hermes/workspace/thinceller.net add-hermes-kanban-post

Expects ticket files at:
    <repo-path>/.scratch/<feature-slug>/issues/<NN>-<slug>.md

Each ticket file is the mattpocock/to-tickets local-ticket-template format:
    # <NN> — <Ticket title>

    **What to build:** ...

    **Blocked by:** None — can start immediately
    # or
    **Blocked by:** #01, #02

    **Status:** ready-for-agent

    - [ ] Acceptance criterion 1
    - [ ] Acceptance criterion 2
"""

import json
import re
import subprocess
import sys
from pathlib import Path


def run_hermes(*args, check=True):
    cmd = ["hermes", "kanban", *args]
    result = subprocess.run(cmd, capture_output=True, text=True, check=check)
    return result


def parse_ticket(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    # Title from first heading: "# <NN> — <title>"
    title = None
    ticket_num = None
    if lines and lines[0].startswith("#"):
        m = re.match(r"^#\s*(\d+)\s*[—-]\s*(.+)$", lines[0].strip())
        if m:
            ticket_num = m.group(1)
            title = m.group(2).strip()

    if title is None:
        title = path.stem

    # Body is the rest of the file, excluding the heading
    body = "\n".join(lines[1:]).strip()

    # Find blocked-by ticket numbers
    blocked_by = []
    for line in lines:
        if line.strip().startswith("**Blocked by:**"):
            rest = line.split("**Blocked by:**", 1)[1].strip()
            if "None" in rest or "can start immediately" in rest.lower():
                break
            # Extract ticket numbers like #01, #1, 01, 1
            nums = re.findall(r"#?(\d+)", rest)
            blocked_by = [f"{int(n):02d}" for n in nums]
            break

    return {
        "num": ticket_num,
        "title": title,
        "body": body,
        "blocked_by": blocked_by,
        "path": path,
    }


def create_task(board: str, title: str, body: str, repo_path: str, parent_ids: list[str]) -> str:
    """Create a kanban task and return its id."""
    cmd = [
        "hermes", "kanban", "--board", board, "create", title,
        "--body", body,
        "--assignee", "worker",
        "--workspace", f"dir:{repo_path}",
        "--json",
    ]
    for pid in parent_ids:
        cmd.extend(["--parent", pid])

    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    return data["id"]


def link_tasks(board: str, parent_id: str, child_id: str) -> None:
    run_hermes("--board", board, "link", parent_id, child_id)


def main():
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    board_slug, repo_path, feature_slug = sys.argv[1:4]
    issues_dir = Path(repo_path) / ".scratch" / feature_slug / "issues"

    if not issues_dir.exists():
        print(f"No ticket directory: {issues_dir}", file=sys.stderr)
        sys.exit(1)

    files = sorted(issues_dir.glob("*.md"))
    if not files:
        print(f"No .md files in {issues_dir}", file=sys.stderr)
        sys.exit(1)

    tickets = [parse_ticket(f) for f in files]

    # Map ticket number (NN) to task id after creation
    num_to_id = {}

    # Create tasks in file order (to-tickets writes blockers first)
    for t in tickets:
        parent_ids = [num_to_id[n] for n in t["blocked_by"] if n in num_to_id]
        task_id = create_task(board_slug, t["title"], t["body"], repo_path, parent_ids)
        num_to_id[t["num"]] = task_id
        print(f"Created {t['num']} -> {task_id}: {t['title']}")

    # Add explicit links for any blocked_by relationships that weren't --parent
    for t in tickets:
        child_id = num_to_id.get(t["num"])
        if not child_id:
            continue
        for parent_num in t["blocked_by"]:
            parent_id = num_to_id.get(parent_num)
            if parent_id and parent_id not in [num_to_id.get(n) for n in t["blocked_by"] if n == parent_num]:
                # Actually --parent already links them; skip redundant link
                pass

    print("Done.")


if __name__ == "__main__":
    main()
