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

Herdr also has a higher-level `agent` verb (0.7.5+). `agent start` launches a
named agent into an EXISTING pane sitting at an interactive shell prompt, and
returns only after the agent is detected and ready (default timeout 30000ms):

```bash
# split first, then start a named agent in the new pane
new_pane=$(herdr pane split --current --direction right --no-focus | jq -r '.result.pane.pane_id')
herdr agent start reviewer --kind claude --pane $new_pane
herdr agent start reviewer --kind codex --pane $new_pane -- <agent-args...>

herdr agent list                               # named/live agents
herdr agent get reviewer                       # state + metadata
herdr agent attach reviewer                    # jump to it interactively
herdr agent rename w1:p1 reviewer
herdr agent explain w1:p1                      # why herdr labeled this state
```

Agent commands accept a unique live agent name or the pane ID hosting it.
Names are cleared when the occupant exits or is replaced.
Name rules (strict): start with a lowercase letter; only `[a-z0-9_-]`;
1-32 chars. Uppercase or leading symbols fail with `invalid_agent_name`.

## Prompting agents

`agent prompt` submits a prompt and can atomically wait for the outcome —
prefer this over hand-rolled send-keys + wait loops:

```bash
# submit and wait until the agent settles (idle / done / blocked)
herdr agent prompt reviewer "Review the current diff and report only actionable findings." --wait --timeout 120000

# match a specific state instead of the settled default (repeat --until to allow more)
herdr agent prompt reviewer "run the tests" --wait --until idle --timeout 300000

# interactive controls
herdr agent send-keys reviewer esc
herdr agent send-keys reviewer ctrl+c
```

`--wait` requires an observed state change within 5000ms of submission,
otherwise it returns `agent_prompt_stalled`. It does not track turns: if the
agent was already working, that active turn's completion may match.

## Reading pane output

```bash
# recent history, unwrapped — best for logs / transcripts
herdr pane read w1:p2 --source recent-unwrapped

# current viewport only
herdr pane read w1:p2 --source visible

# bottom-buffer snapshot used by state detection
herdr pane read w1:p2 --source detection

# same, addressed by agent name
herdr agent read reviewer --source recent-unwrapped --lines 120
```

Pass `--format ansi` when styling matters; otherwise omit for plain text.

## Waiting

```bash
# wait until an agent (by name or pane ID) reaches a state
herdr agent wait reviewer --until idle    --timeout 60000
herdr agent wait w1:p2    --until blocked --timeout 300000
# without --until: settled-state default (idle / done / blocked)
herdr agent wait reviewer --timeout 600000

# wait until specific text appears in a pane
herdr pane wait-output w1:p2 --match "listening on" --timeout 30000
herdr pane wait-output w1:p2 --regex "tests? passed" --timeout 120000
```

Timeouts are in milliseconds. Always set one — infinite waits deadlock the session.
(0.7.4 以前の `herdr wait agent-status` / `herdr wait output` / `herdr agent send` は
0.7.5 で削除された。それぞれ `agent wait` / `pane wait-output` / `agent send-keys` を使う。)

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
