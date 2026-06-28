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

## Then what

Open Claude Code in your vault and say **"catch me up."** The first time there's
nothing to catch up on, which is expected. Open `active/ref-trajectory.md`,
write down what you're working on, and you're running.

For the why behind all of it, read `obsidian-vault-explained.md`.
