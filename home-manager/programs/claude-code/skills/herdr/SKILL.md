---
name: herdr
description: Control herdr — the terminal multiplexer for coding agents. Use only when the user explicitly mentions herdr or asks to inspect/split panes, run commands in sibling panes, wait on other agents, or coordinate with another agent through herdr. Upstream reference — https://github.com/ogulcancelik/herdr/blob/master/SKILL.md.
allowed-tools: Bash(herdr:*)
---

# Herdr: Terminal Multiplexer for Coding Agents

Herdr organizes work into **workspaces → tabs → panes** and tracks agent state (`idle` / `working` / `blocked` / `done`) for panes running Claude Code, Codex, opencode, pi, omp, Copilot CLI, Devin, and others.

## Before Operating

**Always** verify you are running inside a herdr-managed pane before touching any `herdr` command:

```bash
test "${HERDR_ENV:-}" = 1
```

If this fails, do NOT invoke `herdr` — you are not attached to a herdr session and commands like `pane split` will target the wrong context.

Injected env vars inside herdr panes:

- `HERDR_WORKSPACE_ID` (e.g. `w1`)
- `HERDR_TAB_ID` (e.g. `w1:t1`)
- `HERDR_PANE_ID` (e.g. `w1:p1`)

## Resource IDs

IDs are short stable strings: workspace `w1`, tab `w1:t1`, pane `w1:p1`, terminal `term_…`.

- Treat IDs as **opaque strings**. Parse them from JSON output — never construct them by pattern (`w2:p3` may not exist).
- Closed tabs/panes do not reuse their IDs — later resources are not retargeted onto old IDs.

## Discovery

```bash
herdr workspace list                 # all workspaces
herdr tab list --workspace w1        # tabs in a workspace
herdr pane list --workspace w1       # panes in a workspace
herdr pane current --current         # the pane you are inside
herdr pane get w1:p1                 # full pane record
```

Add `--json` to any list/get command to get machine-readable output.

## Splitting panes and launching agents

```bash
# split the CURRENT pane to the right without stealing focus
herdr pane split --current --direction right --no-focus

# split downward
herdr pane split --current --direction down --no-focus

# rename a pane for legibility
herdr pane rename w1:p2 "reviewer"

# run a command in a specific pane
herdr pane run w1:p2 "claude"
```

Default to `--no-focus` for background helpers — grabbing focus interrupts the user.

Herdr also has a higher-level `agent` verb that combines split + rename + launch + status wait:

```bash
herdr agent start reviewer --cwd ~/project --split right -- pi
herdr agent start docs --workspace w1 --tab w1:t1 -- claude
herdr agent attach reviewer                    # jump to it interactively
herdr agent attach reviewer --takeover         # take control from another client
herdr agent rename w1:p1 reviewer
herdr agent explain w1:p1                      # why herdr labeled this state
```

## Reading pane output

```bash
# recent history, unwrapped — best for logs / transcripts
herdr pane read w1:p2 --source recent-unwrapped

# current viewport only
herdr pane read w1:p2 --source visible

# bottom-buffer snapshot used by state detection
herdr pane read w1:p2 --source detection
```

Pass `--format ansi` when styling matters; otherwise omit for plain text.

## Waiting

```bash
# wait until the agent in this pane reaches a state
herdr wait agent-status w1:p2 --status idle    --timeout 60000
herdr wait agent-status w1:p2 --status blocked --timeout 300000
herdr wait agent-status w1:p2 --status done    --timeout 600000

# wait until specific text appears in a pane
herdr wait output w1:p2 --match "listening on" --timeout 30000
```

Timeouts are in milliseconds. Always set one — infinite waits deadlock the session.

## Custom status reporting (integrations)

If you own a long-running process that isn't a standard agent, report its state so herdr's sidebar reflects it:

```bash
herdr pane report-agent w1:p1 \
  --source custom:indexer \
  --agent docs-bot \
  --state working \
  --custom-status "indexing"
```

## Integrations & agent manifests

```bash
herdr integration install claude          # install Claude Code lifecycle hooks
herdr integration status                  # what's currently installed
herdr server reload-agent-manifests       # after editing local manifest overrides
herdr server update-agent-manifests       # pull latest remote manifests
```

Local manifest overrides live at `~/.config/herdr/agent-detection/<agent>.toml` and always win over the bundled / remote manifest.

## Session lifecycle

```bash
herdr                    # launch or attach to the default background session
herdr server reload-config
herdr server stop        # DO NOT run from an active session — you'll disconnect
```

## Safety rules

- Only act on herdr when the user asked you to. Random tasks do not need herdr.
- Do **not** kill or close panes, tabs, or workspaces you did not create — the user or another agent may be using them.
- Do **not** run `herdr server stop` while attached; you'll blow up the session you're inside.
- Use `--current` or an ID you parsed from JSON. Never rely on "the focused pane" from another client — focus is per-client.
- Read a pane's existing output (`pane read`) before waiting on future output — the event you care about may have already happened.

## Reference

Canonical upstream skill: https://github.com/ogulcancelik/herdr/blob/master/SKILL.md — re-check when herdr updates, as command shape may evolve.
