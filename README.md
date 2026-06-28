# AI-native Obsidian vault: setup bundle

Everything you need to set up an Obsidian vault that works the way mine does:
a folder of plain Markdown that Claude can walk into, get oriented in, and help
you think with.

## What's in here

- **`setup.sh`** -- the setup script. Run it to build the vault structure, and
  optionally install the tooling.
- **`obsidian-vault-setup-recipe.md`** -- the setup guide. Read this if you want
  to do it by hand, or hand it to Claude Code and let it set things up for you.
- **`obsidian-vault-explained.md`** -- how the whole thing works and how to bend
  it to your own habits. Read this if you want to understand it, not just run it.

## Quick start

You need [Obsidian](https://obsidian.md) and
[Claude Code](https://docs.claude.com/en/docs/claude-code/overview) installed first.

Then, from a terminal inside the folder you want to use as your vault:

```bash
bash setup.sh           # just the vault structure (all most people need)
bash setup.sh --full    # also install the CLIs, MCP server, and Claude Code plugins
bash setup.sh --help    # see every option
```

It's safe to re-run. It never overwrites a file you already have, and it skips
anything already installed.

Prefer not to run a script? Open Claude Code in your vault and say:

> "Read obsidian-vault-setup-recipe.md and set up my vault as described."

## Open it in Obsidian

The script creates the folder on disk, but Obsidian doesn't find it on its own.
Open Obsidian, choose **"Open folder as vault"**, and pick the folder you just
set up. It'll show up in your vault list from then on.

(Use "Open folder as vault," not "Create new vault" -- the folder already exists.)

## Then what

Open Claude Code in your vault and say **"catch me up."** The first time there's
nothing to catch up on, which is expected. Open `active/ref-trajectory.md`,
write down what you're working on, and you're running.

For the why behind all of it, read `obsidian-vault-explained.md`.

## Claudian and your `.claude` settings

If you use the **Claudian** plugin (chat with Claude inside Obsidian), it reads
your Claude settings with the same precedence as the Claude Code CLI, as long as
its **"Load user settings"** toggle is on (Settings -> Claude). That toggle is on
by default.

With it on, settings load in this order, where each level overrides the one
before it:

1. `~/.claude` -- user scope (your machine-wide defaults)
2. `<vault>/.claude` -- project scope (overrides user)
3. `<vault>/.claude/settings.local.json` -- local scope (overrides project)

This covers both `settings.json` and `CLAUDE.md` at each level: your vault's
`CLAUDE.md` loads as project memory, and `~/.claude/CLAUDE.md` as user memory.

Under the hood, Claudian runs the Claude Agent SDK with your vault as the working
directory and tells it to load all three sources (`user`, `project`, `local`).
Worth knowing: the Agent SDK loads no filesystem settings on its own, so this is
a deliberate choice Claudian makes to match Claude Code. If you turn
"Load user settings" off, Claudian drops to `project` + `local` only and ignores
`~/.claude` entirely -- that one switch is what breaks parity with Claude Code.
