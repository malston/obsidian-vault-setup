---
title: "How my AI chief-of-staff vault works"
author: Mark Alston
status: draft
modified: 2026-06-28
---

# How my AI chief-of-staff vault works

I keep my notes in Obsidian, but I almost never browse them by hand. I read them through Claude. The vault is built for that: a folder of plain Markdown that an AI can walk into cold, get oriented in about thirty seconds, and start being useful.

This post explains the design. If you just want the scaffold built for you, the [setup recipe](obsidian-vault-setup-recipe.md) does that in one paste. This is the version for someone who wants to understand the moving parts and change them to fit their own work.

The core idea: a note system optimized for synthesis, not storage. Most note-taking advice optimizes for capture and retrieval -- get it in, find it later. That breaks down the moment you have a few thousand notes and an assistant that can read all of them. At that point the bottleneck isn't finding a note, it's the assistant knowing _which_ notes matter for the conversation you're having right now. Everything below is in service of that.

## The shape: six folders

Notes move through a lifecycle, and the folders are the stages.

- **`_inbox/`** is the catch-all. Anything I capture in a hurry lands here and gets sorted later. Without it, half-formed thoughts end up scattered or lost.
- **`active/`** is what I'm thinking about right now. I keep it deliberately small -- around fifteen files. When it grows past that, that's a signal something is done and should move on.
- **`positions/`** holds durable opinions: what I currently think about a topic, written down so I don't re-derive it every time it comes up.
- **`sources/`** is raw input -- articles, transcripts, PDFs. Read-only, on purpose (more on that below).
- **`vault/`** is the archive: finished work, dated `YYYY-MM-DD-slug.md` so it sorts chronologically.
- **`logs/`** is the running record, one file per day.

Separating these does more than keep things tidy. It lets Claude reason about _where_ something is and infer _what_ it is. A file in `sources/` is something to mine. A file in `positions/` is a settled view to defend or revisit. A file in `active/` is live. The folder is metadata.

## The operating manual

The single most important file is `CLAUDE.md` at the vault root. Claude Code reads it automatically at the start of every session, so it's where I encode how I want the assistant to behave: that it's a chief of staff and not a search box, that it should push back, that it should synthesize rather than summarize.

This is the file most worth customizing. Mine tells Claude to be direct and opinionated and to challenge me when I contradict something I've already written. Yours might tell it to be gentler, or to always cite sources, or to never touch a particular folder. Whatever you put here is the standing instruction for every future conversation, so it's worth getting right.

## Cold start: "catch me up"

Every session starts the same way. I say "catch me up," and the operating manual tells Claude exactly what to do:

1. Read `active/ref-trajectory.md` -- my current focus and open questions.
2. Scan `active/` for anything recently changed.
3. Check `logs/` for the latest session log.
4. Brief me on what's active, what's open, and what I last touched.

`ref-trajectory.md` is the keystone. It's a small, always-current file that answers "what is this person working on?" in one read. Because Claude reads it first, every session inherits my context without me re-explaining it. The instruction to _not_ load everything at once matters too -- the vault can grow large, and you don't want the assistant burning its first response slurping in a thousand files. It loads on demand, following the conversation.

## Position docs and the lifecycle field

A position doc is my current thinking on something, stated plainly. Each one has a `lifecycle:` field in its frontmatter with one of four values:

- **`draft`** -- written by the assistant or half-baked by me.
- **`reviewed`** -- I've read it and it's roughly right.
- **`verified`** -- I stand behind it.
- **`disputed`** -- I no longer fully agree, but I'm keeping it visible.

The rule I care about: only I promote a doc past `draft`, and time alone never demotes a `verified` doc. That last part is a guard against a failure mode I've watched assistants fall into -- treating an old file as stale just because it's old. A view I verified two years ago isn't wrong because the timestamp aged. The lifecycle field lets the assistant tell the difference between "Mark hasn't confirmed this" and "Mark confirmed this and it still holds."

When a topic comes up, Claude checks `positions/` before reasoning from a blank slate. That's what stops it from giving me generic advice on questions I've already worked through.

## Source preservation

When I bring in outside material, the raw text goes into `sources/` and stays there untouched. Synthesis happens elsewhere -- in a position doc, an active note, an archive entry -- and links back to the source.

This is about provenance. When a note of mine says "Karpathy argues X," the original is one click away, and I can check whether that's what he actually said or what I remembered him saying. The read-only rule keeps the assistant from "tidying up" a transcript and quietly changing what the source said. The source is ground truth; everything downstream is my interpretation, and the two never get mixed.

## The write-back loop

After a real session -- not task execution, but genuine thinking -- Claude appends a short entry to `logs/YYYY-MM-DD.md`: decisions made, ideas worth keeping, position docs that should change. And the `index.md` catalog at the root gets updated whenever a page is created, renamed, or deleted.

The catalog is how navigation scales. Instead of scanning folders, Claude reads `index.md` first to find the handful of relevant pages, then drills in. It's a table of contents the assistant maintains for itself.

The write-back habit is what makes the vault compound instead of leak. Good answers that live only in a chat window are gone next session. Written back, they become context the next session inherits for free.

## The optional tooling layer

Everything above runs on vanilla Claude Code and plain files. You need nothing else, and I'd start there. But once the core is comfortable, a few add-ons make it sharper. Everything here is optional -- skip any that doesn't earn its place. Here's exactly what I run and where to get it.

### Inside Obsidian

Obsidian community plugins install from **Settings → Community plugins → Browse**. A couple of mine are beta builds installed through **BRAT** (the Beta Reviewers Auto-update Tool, itself a community plugin), which pulls a plugin straight from a GitHub repo.

The one that brings Claude into the app:

- **Claudian** (by Yishen Tu, [github.com/YishenTu](https://github.com/YishenTu)) -- a Claude chat panel inside Obsidian, so I can work the vault without leaving the app. Installed via BRAT.

Connecting Claude Code in the terminal to the vault is a separate step, covered in [Connecting Claude Code to your vault](#connecting-claude-code-to-your-vault) below.

The daily drivers, all from the community store:

- **Dataview** -- live queries over your notes (tables of recent files, open tasks, and so on).
- **Tasks** -- checkbox tasks with due dates and queries.
- **Calendar** + **Natural Language Dates** -- daily-note navigation and "tomorrow"-style date parsing.
- **Frontmatter Modified Date** -- keeps the `modified:` field current automatically.
- **Custom Sort**, **Auto Card Link**, **Importer** -- folder ordering, link previews, and importing from other note apps.

### Connecting Claude Code to your vault

This is the piece people get stuck on, so here's the whole thing.

Out of the box, Claude Code can already read and edit files in whatever folder you launch it from. So if you open Claude Code inside your vault, it works -- no setup. An **MCP server** adds a layer on top of that: instead of raw file edits, Claude gets vault-aware operations -- search notes, read frontmatter, follow backlinks, manage tags, find orphans -- that understand Obsidian's structure. It's the difference between editing text and working with notes.

MCP (Model Context Protocol) is just a standard way for Claude to talk to an external tool. You register a server once and Claude Code picks it up automatically. The one I use for the vault is **mcpvault** ([mcpvault.org](https://mcpvault.org)), an npm package that points at a vault folder and exposes it over MCP. It reads the files directly, so Obsidian doesn't even need to be open.

Register it with one command. Run this in a terminal, swapping in the real path to your vault:

```bash
claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest /path/to/your/vault
```

That's it. `claude mcp add` writes the configuration for you; `npx` downloads and runs the package on demand, so there's nothing to install first. Start a new Claude Code session and the vault tools are available. To confirm it registered, run `claude mcp get obsidian`.

If you keep more than one vault, add a server per vault under different names:

```bash
claude mcp add obsidian-work    -- npx @bitbonsai/mcpvault@latest /path/to/work-vault
claude mcp add obsidian-private -- npx @bitbonsai/mcpvault@latest /path/to/private-vault
```

Under the hood this lands in an `mcp.json` file, which you can also edit by hand if you prefer. The shape is a `mcpServers` object keyed by name, each with a `command` (`npx`) and its `args` (the package and the vault path). The `claude mcp add` command is just a friendlier way to write that.

There's a second route worth knowing about: the **Local REST API** plugin (by Adam Coddington, now shipping MCP support) paired with **MCP Tools** (by Jack Steam, [github.com/jacksteamdev](https://github.com/jacksteamdev)). That runs the MCP server _inside_ Obsidian rather than as a standalone process. The trade-off: it requires Obsidian to be running, but it can do things only the live app can, like triggering commands. For pure note reading and editing, mcpvault is simpler and I'd start there.

### Claude Code plugins

Claude Code plugins come from marketplaces. Add a marketplace once, then install plugins from it:

```bash
claude plugin marketplace add <github-owner/repo>
claude plugin install <plugin-name>@<marketplace-name>
```

What I run for vault work:

- **obsidian** (`kepano/obsidian-skills`) -- skills for Obsidian Markdown, Bases, and Canvas, from Obsidian's own CEO.
- **marks-vault** (`malston/marks-marketplace`) -- my vault skills: a `vlt` wrapper, a "rename to dated slugs and fix every wikilink" skill, and more.
- **marks-writing** (`malston/marks-marketplace`) -- the antislop checker that scrubbed the post you're reading.
- **claude-mem** (`thedotmack/claude-mem`) -- cross-session memory: persists facts and decisions between conversations, so the assistant remembers things that don't belong in any single note.
- **episodic-memory** and **superpowers** (`obra/superpowers-marketplace`) -- searchable history of past sessions, plus a large skill library.
- **remember** (`anthropics/claude-plugins-official`) -- lightweight session-state capture.
- **context7** (`upstash/context7`) -- pulls current library and API docs on demand instead of trusting the model's memory.

### Command-line tools

These run in the terminal alongside Claude Code:

- **vlt** -- vault CLI: search, backlink checks, orphan detection, integrity baselines. Useful for automation and health checks, overkill if you're only writing.

  ```bash
  go install github.com/paivot-ai/vlt/cmd/vlt@latest   # requires Go 1.26+
  ```

  (Note the `/cmd/vlt` suffix -- the bare module path won't build.) Pre-built binaries are on the repo's [Releases](https://github.com/paivot-ai/vlt/releases) page.

- **claudeup** -- manages Claude Code itself: profiles, plugin state, and a `doctor` command that fixes broken plugin paths.

  ```bash
  curl -fsSL https://claudeup.github.io/install.sh | bash
  # or: go install github.com/claudeup/claudeup/v5/cmd/claudeup@latest
  ```

- **rtk** -- a CLI proxy that trims token use on dev commands. `brew install rtk`
- **bd** (beads) -- issue and work-item tracking that survives across sessions. `brew install beads`
- **gemini** -- Google's Gemini CLI, which I use for token-heavy fetches like refreshing the antislop pattern list. `brew install gemini-cli`

The order matters. Get value from the plain-files core first. Add tooling to remove a specific friction you've actually felt, not because it's available.

## Make it yours

The structure isn't sacred -- it's a set of defaults that happen to work for how I think. Things worth bending:

- **The taxonomy.** Six folders is what fits my work. If you don't ingest much outside material, drop `sources/`. If you don't archive, fold `vault/` into `logs/`. Fewer folders, less to maintain.
- **The cold-start protocol.** Rewrite the steps in `CLAUDE.md` to read whatever _you_ want surfaced first. The mechanism is just "here's what to read at the start" -- the specific files are yours to choose.
- **The lifecycle states.** Four worked for me. You might want only two (`draft` and `verified`), or a different vocabulary entirely. The point is giving the assistant a signal about trust, not the exact labels.
- **The tone.** My operating manual tells Claude to be blunt and argumentative because that's what I want from a thinking partner. If that's not you, change it. It's a single paragraph and it sets the personality of every session.

What's worth preserving is the underlying move, not any one folder or field: write down, in plain files, both the knowledge _and_ the instructions for how to work with it -- then let the assistant read both. The vault is a brain; `CLAUDE.md` is the instructions for the brain. Keep those two ideas and the rest is yours to reshape.

---

## Appendix: full inventory

The body covers the tools that serve the vault directly. For the completionist, here's everything I have enabled. Most of the non-vault entries are general development tooling and aren't needed to run the system above.

### Obsidian community plugins

Auto Card Link, Calendar, Custom Sort, Dataview, File Explorer Note Count, Obsidian Git, Natural Language Dates, Open Tab Settings, Cycle Through Panes, Tasks, Frontmatter Modified Date, VSCode Editor, Editor Shortcuts, Claudian, BRAT, Importer, Local REST API (with MCP), MCP Tools.

### Claude Code plugins

Vault and knowledge work: `obsidian@obsidian-skills`, `marks-vault`, `marks-writing`, `claude-mem`, `episodic-memory`, `superpowers`, `superpowers-developing-for-claude-code`, `remember`, `context7`, `elements-of-style`, `document-skills`, `skill-creator`, `claude-md-management`.

My own marketplace (`malston/marks-marketplace`): `marks-ai-eng`, `marks-book-knowledge`, `marks-cca`, `marks-dev-practice`, `marks-forgd-training`, `marks-git-workflow`, `marks-guardrails`, `marks-iterm`, `marks-languages`, `marks-vault`, `marks-vsphere`, `marks-writing`.

Development and review: `code-review`, `code-simplifier`, `commit-commands`, `comprehensive-review`, `feature-dev`, `frontend-design`, `git-pr-workflows`, `github`, `gopls-lsp`, `playwright`, `playground`, `pr-review-toolkit`, `security-compliance`, `agent-orchestration`, `agent-sdk-dev`, `architect-refine-critique`, `agent-skills`, `codex`, `andrej-karpathy-skills`, `octo`.

### Command-line tools

`vlt` (vault operations), `claudeup` (Claude Code management), `rtk` (token-optimizing proxy), `bd` / beads (work tracking), `gemini` (Gemini CLI). Install commands are in the section above.

### MCP servers

`obsidian` via `@bitbonsai/mcpvault` (one per vault), and `github` (HTTP, for repo operations). Registered with `claude mcp add`; see [Connecting Claude Code to your vault](#connecting-claude-code-to-your-vault).
