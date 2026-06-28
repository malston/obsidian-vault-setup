#!/usr/bin/env bash
#
# setup.sh -- scaffold an AI-native Obsidian vault and, optionally, install the
# tooling that makes it sharper. Safe to re-run: it never overwrites a file that
# already exists, and it skips anything already installed or registered.
#
# Usage:
#   ./setup.sh [options]
#
# With no options it creates the vault structure (folders + seed files) in the
# current directory. Nothing is installed. That is all most people need.
#
# Folders: in an interactive terminal you're asked which folders to create --
# keep, rename, or skip each default, then add your own. Run non-interactively
# (piped, or with --defaults or --full) to accept the default set silently. The
# generated CLAUDE.md adapts to whatever folders you end up with.
#
# Options:
#   --vault <path>   Target vault directory (default: current directory).
#   --defaults       Use the default folders without prompting.
#   --prompt         Force the folder prompts even if no terminal is detected.
#   --mcp            Register the Obsidian MCP server with Claude Code.
#   --clis           Install the command-line tools (vlt, rtk, beads, gemini, claudeup).
#   --plugins        Add marketplaces and install the curated Claude Code plugins.
#   --full           Do everything: --mcp --clis --plugins (implies --defaults).
#   --dry-run        Print the commands that would run, without running them.
#   -h, --help       Show this help.
#
# Prerequisites are detected, never silently installed. If something needed is
# missing (Homebrew, Go, npx, Claude Code), the script tells you and skips that
# step instead of changing your system behind your back.

set -euo pipefail

# ---- defaults -------------------------------------------------------------

VAULT="."
DO_MCP=false
DO_CLIS=false
DO_PLUGINS=false
DO_DEFAULTS=false
FORCE_PROMPT=false
DRY_RUN=false

# Default folder roles, in canonical order. NAMES[i] holds the chosen name for
# ROLES[i], or "" when the user skips it. EXTRAS holds user-added folders that
# have no operating-manual role.
ROLES=(active positions sources vault logs _inbox)
NAMES=(active positions sources vault logs _inbox)
EXTRAS=()

# ---- helpers --------------------------------------------------------------

c_info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
c_ok()    { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
c_skip()  { printf '\033[1;33m skip\033[0m %s\n' "$*"; }
c_warn()  { printf '\033[1;31m warn\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# run CMD...  -- echo and execute, or just echo under --dry-run
run() {
  if $DRY_RUN; then
    printf '       [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

usage() { awk 'NR>=2 && /^#/ {sub(/^# ?/,""); print; next} NR>=2 {exit}' "$0"; exit 0; }

# ---- folder model ---------------------------------------------------------

role_desc() {
  case "$1" in
    active)    echo "current work in progress (keep this small, ~15 files max)";;
    positions) echo "durable opinion docs: what I currently think about a topic";;
    sources)   echo "immutable raw inputs: articles, transcripts, PDFs. Read, never modify.";;
    vault)     echo "completed and archived work, dated YYYY-MM-DD-slug.md";;
    logs)      echo "session logs and decision records";;
    _inbox)    echo "landing zone for captures, triaged into the folders above";;
    *)         echo "your folder";;
  esac
}

# name_for_role ROLE -- echo the chosen name for ROLE, or "" if skipped
name_for_role() {
  local r="$1" i=0
  while [ "$i" -lt "${#ROLES[@]}" ]; do
    if [ "${ROLES[$i]}" = "$r" ]; then printf '%s' "${NAMES[$i]}"; return; fi
    i=$((i + 1))
  done
  printf ''
}

# traj_path -- where ref-trajectory.md lives (in the active-role folder, or at
# the vault root if that role was skipped)
traj_path() {
  local a; a="$(name_for_role active)"
  if [ -n "$a" ]; then printf '%s/ref-trajectory.md' "$a"; else printf 'ref-trajectory.md'; fi
}

# chosen_folders -- print every folder to create, one per line
chosen_folders() {
  local i=0
  while [ "$i" -lt "${#ROLES[@]}" ]; do
    [ -n "${NAMES[$i]}" ] && printf '%s\n' "${NAMES[$i]}"
    i=$((i + 1))
  done
  if [ "${#EXTRAS[@]}" -gt 0 ]; then
    local e; for e in "${EXTRAS[@]}"; do printf '%s\n' "$e"; done
  fi
}

trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

select_folders() {
  $DO_DEFAULTS && return 0
  if ! $FORCE_PROMPT && [ ! -t 0 ]; then
    c_info "Non-interactive: using the default folders. (Run in a terminal, or pass --defaults to silence this, or --prompt to force the questions.)"
    return 0
  fi

  c_info "Folder setup"
  echo "For each folder: press Enter to keep it, type a new name to rename it, or '-' to skip."
  local i ans r
  i=0
  while [ "$i" -lt "${#ROLES[@]}" ]; do
    r="${ROLES[$i]}"
    printf '  %-9s [Enter=keep / new name / - to skip]: ' "$r"
    IFS= read -r ans || ans=""
    ans="$(trim "$ans")"
    if [ "$ans" = "-" ]; then
      NAMES[$i]=""
    elif [ -n "$ans" ]; then
      case "$ans" in
        */*) c_warn "names can't contain '/'; keeping '$r'";;
        *)   NAMES[$i]="$ans";;
      esac
    fi
    i=$((i + 1))
  done

  echo "Add your own folders (one name at a time; blank line to finish):"
  while :; do
    printf '  add folder: '
    IFS= read -r ans || break
    ans="$(trim "$ans")"
    [ -z "$ans" ] && break
    case "$ans" in
      */*) c_warn "names can't contain '/'; skipped"; continue;;
    esac
    EXTRAS+=("$ans")
  done
}

# ---- argument parsing -----------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --vault)    VAULT="${2:?--vault needs a path}"; shift 2 ;;
    --defaults) DO_DEFAULTS=true; shift ;;
    --prompt)   FORCE_PROMPT=true; shift ;;
    --mcp)      DO_MCP=true; shift ;;
    --clis)     DO_CLIS=true; shift ;;
    --plugins)  DO_PLUGINS=true; shift ;;
    --full)     DO_MCP=true; DO_CLIS=true; DO_PLUGINS=true; DO_DEFAULTS=true; shift ;;
    --dry-run)  DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    *) c_warn "unknown option: $1"; echo "Try --help."; exit 2 ;;
  esac
done

# ---- scaffold the vault ---------------------------------------------------

scaffold() {
  c_info "Scaffolding vault at: $VAULT"
  run mkdir -p "$VAULT"
  # Resolve to an absolute path for the MCP registration step.
  if ! $DRY_RUN; then VAULT="$(cd "$VAULT" && pwd)"; fi

  local d
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    if [ -d "$VAULT/$d" ]; then
      c_skip "$d/ exists"
    else
      run mkdir -p "$VAULT/$d"
      c_ok "$d/"
    fi
  done <<EOF
$(chosen_folders)
EOF

  write_file "$VAULT/CLAUDE.md"        claude_md
  write_file "$VAULT/README.md"        readme_md
  write_file "$VAULT/index.md"         index_md
  write_file "$VAULT/$(traj_path)"     trajectory_md
}

# write_file PATH FUNC -- write FUNC's output to PATH only if PATH is absent
write_file() {
  local path="$1" producer="$2"
  if [ -f "$path" ]; then
    c_skip "${path#"$VAULT"/} exists (left untouched)"
    return
  fi
  if $DRY_RUN; then
    printf '       [dry-run] write %s\n' "${path#"$VAULT"/}"
    return
  fi
  "$producer" > "$path"
  c_ok "${path#"$VAULT"/}"
}

# folder_list -- print "- `name/` -- description" for every chosen folder
folder_list() {
  local i=0
  while [ "$i" -lt "${#ROLES[@]}" ]; do
    [ -n "${NAMES[$i]}" ] && printf -- '- `%s/` -- %s\n' "${NAMES[$i]}" "$(role_desc "${ROLES[$i]}")"
    i=$((i + 1))
  done
  if [ "${#EXTRAS[@]}" -gt 0 ]; then
    local e; for e in "${EXTRAS[@]}"; do printf -- '- `%s/` -- your folder\n' "$e"; done
  fi
}

claude_md() {
  local active positions sources logs traj
  active="$(name_for_role active)"
  positions="$(name_for_role positions)"
  sources="$(name_for_role sources)"
  logs="$(name_for_role logs)"
  traj="$(traj_path)"

  echo "# CLAUDE.md -- Vault Operating Manual"
  echo
  echo "## Who you are"
  echo
  echo "You are my AI chief of staff. Your job is to ground every session in current"
  echo "context, surface relevant prior thinking, and help me synthesize knowledge --"
  echo "not just retrieve it."
  echo
  echo "## Vault structure"
  echo
  folder_list
  echo
  echo "## Cold start"
  echo
  echo 'When I start a session or say "catch me up" or "orient me":'
  echo
  local n=1
  printf '%d. Read `%s` -- my current focus and open questions.\n' "$n" "$traj"; n=$((n + 1))
  if [ -n "$active" ]; then printf '%d. Scan `%s/` for anything modified recently.\n' "$n" "$active"; n=$((n + 1)); fi
  if [ -n "$logs" ]; then printf '%d. Check `%s/` for the most recent session log.\n' "$n" "$logs"; n=$((n + 1)); fi
  printf "%d. Tell me what's active, what's open, and what I last worked on.\n" "$n"
  echo
  echo "Don't load everything at once. Load on demand based on where the conversation goes."

  if [ -n "$positions" ]; then
    echo
    echo "## Position docs"
    echo
    printf 'Files in `%s/` are my current thinking on a topic. Each one states:\n' "$positions"
    echo
    echo "- The position, directly."
    echo "- Decisions already settled (don't relitigate these)."
    echo "- Open questions, where pushback is welcome."
    echo '- A `lifecycle:` field in frontmatter: draft | reviewed | verified | disputed.'
    echo '  I am the only one who promotes a doc past `draft`. Age alone never demotes it.'
    echo
    printf 'When a topic comes up, check `%s/` before reasoning from scratch.\n' "$positions"
  fi

  if [ -n "$sources" ]; then
    echo
    echo "## Sources"
    echo
    echo "When I bring in outside material (an article, transcript, PDF):"
    echo
    printf '1. Save the raw text to `%s/` with a descriptive, dated filename.\n' "$sources"
    echo "2. Treat it as read-only. Synthesize from it; never edit it."
    echo "3. Link back to it from any note that draws on it, so the original is one click away."
  fi

  if [ -n "$logs" ]; then
    echo
    echo "## Writing back"
    echo
    printf 'After a substantive session, append a short entry to `%s/YYYY-MM-DD.md`:\n' "$logs"
    echo "decisions made, ideas worth keeping, any position docs that should change."
    echo "Good thinking shouldn't disappear into chat history."
  fi

  echo
  echo "## Index"
  echo
  echo '`index.md` at the vault root lists every page with a one-line summary. Read it'
  echo "first to find relevant pages instead of scanning folders. Update it whenever you"
  echo "create, rename, or delete a page."
  echo
  echo "## Tone"
  echo
  echo "Direct. Opinionated. Push back when something conflicts with a position I've"
  echo "already written down. Don't just agree -- synthesize."
}

readme_md() {
  echo "# Knowledge Vault"
  echo
  echo "A personal knowledge system optimized for AI-assisted synthesis, not human browsing."
  echo
  echo '- `CLAUDE.md` -- operating manual for Claude Code sessions'
  echo '- `index.md` -- catalog of every page, for navigation'
  folder_list
  echo
  echo 'To start a session: open Claude Code here and say "catch me up".'
}

index_md() {
  local traj; traj="$(traj_path)"
  echo "# Index"
  echo
  echo "The catalog of this vault. Every page gets one line: a link and a one-sentence"
  echo "summary. Keep it current."
  echo
  echo "## Pages"
  echo
  printf -- '- [[%s]] -- current focus, projects, and open questions.\n' "${traj%.md}"
}

trajectory_md() {
  local today
  today="$( $DRY_RUN && echo 'YYYY-MM-DD' || date +%F )"
cat <<EOF
# Trajectory

The first file read each session. Keep it short and current.

## Current focus

_What I'm spending attention on right now. Replace this line._

## Active projects

- _Project -- one line on status._

## Open questions

- _A question I'm still chewing on._

## Last updated

$today
EOF
}

# ---- MCP server -----------------------------------------------------------

register_mcp() {
  c_info "Registering the Obsidian MCP server"
  if ! have claude; then
    c_warn "Claude Code ('claude') not found. Install it, then re-run with --mcp."
    return
  fi
  if ! have npx; then
    c_warn "'npx' (Node.js) not found. Install Node, then re-run with --mcp."
    return
  fi
  if claude mcp get obsidian >/dev/null 2>&1; then
    c_skip "MCP server 'obsidian' already registered"
  elif run claude mcp add obsidian -- npx @bitbonsai/mcpvault@latest "$VAULT"; then
    c_ok "MCP server 'obsidian' -> $VAULT"
  else
    c_warn "could not register MCP server 'obsidian'"
  fi
}

# ---- command-line tools ---------------------------------------------------

install_clis() {
  c_info "Installing command-line tools"

  if have brew; then
    for f in rtk beads gemini-cli; do
      if brew list "$f" >/dev/null 2>&1; then
        c_skip "$f (brew, already installed)"
      elif run brew install "$f"; then
        c_ok "$f"
      else
        c_warn "$f install failed"
      fi
    done
  else
    c_warn "Homebrew not found -- skipping rtk, beads, gemini-cli. See https://brew.sh"
  fi

  if have vlt; then
    c_skip "vlt (already installed)"
  elif have go; then
    if run go install github.com/paivot-ai/vlt/cmd/vlt@latest; then c_ok "vlt"; else c_warn "vlt install failed"; fi
  else
    c_warn "Go not found -- skipping vlt. See https://go.dev/dl (needs Go 1.26+)."
  fi

  if have claudeup; then
    c_skip "claudeup (already installed)"
  elif have curl; then
    if run bash -c 'curl -fsSL https://claudeup.github.io/install.sh | bash'; then c_ok "claudeup"; else c_warn "claudeup install failed"; fi
  else
    c_warn "curl not found -- skipping claudeup."
  fi
}

# ---- Claude Code plugins --------------------------------------------------

# marketplace repo -> name pairs, then plugin@marketplace identifiers
install_plugins() {
  c_info "Installing Claude Code plugins"
  if ! have claude; then
    c_warn "Claude Code ('claude') not found. Install it, then re-run with --plugins."
    return
  fi

  local marketplaces=(
    "kepano/obsidian-skills"
    "malston/marks-marketplace"
    "thedotmack/claude-mem"
    "obra/superpowers-marketplace"
    "anthropics/claude-plugins-official"
    "upstash/context7"
  )
  for m in "${marketplaces[@]}"; do
    run claude plugin marketplace add "$m" 2>/dev/null \
      && c_ok "marketplace $m" \
      || c_skip "marketplace $m (already added or unavailable)"
  done

  local installed
  installed="$(claude plugin list 2>/dev/null || true)"

  local plugins=(
    "obsidian@obsidian-skills"
    "marks-vault@marks-marketplace"
    "marks-writing@marks-marketplace"
    "claude-mem@thedotmack"
    "superpowers@superpowers-marketplace"
    "episodic-memory@superpowers-marketplace"
    "remember@claude-plugins-official"
    "context7@context7-marketplace"
  )
  for p in "${plugins[@]}"; do
    if printf '%s' "$installed" | grep -qF "$p"; then
      c_skip "plugin $p (already installed)"
    elif run claude plugin install "$p" 2>/dev/null; then
      c_ok "plugin $p"
    else
      c_warn "could not install $p (check the marketplace name)"
    fi
  done
}

# ---- Obsidian community plugins (manual) ----------------------------------

obsidian_checklist() {
  local vname; vname="$(basename "$VAULT")"
cat <<EOF

------------------------------------------------------------------------
Obsidian plugins (optional, but nice to have)
------------------------------------------------------------------------
First open this folder in Obsidian: choose "Open folder as vault" and pick
  $VAULT
Obsidian must be running with the vault open for the commands below to work.

Fast path -- Obsidian ships a command-line tool that installs community
plugins by id. Enable it once: Settings -> General -> turn on "Command line
interface", then follow the prompt to register it (adds 'obsidian' to your
PATH; on macOS you approve a system dialog). Full steps: https://obsidian.md/cli

Then, with the vault open, run these in a terminal:

  obsidian plugin:install id=dataview enable vault="$vname"
  obsidian plugin:install id=obsidian-tasks-plugin enable vault="$vname"
  obsidian plugin:install id=calendar enable vault="$vname"
  obsidian plugin:install id=nldates-obsidian enable vault="$vname"
  obsidian plugin:install id=frontmatter-modified-date enable vault="$vname"
  obsidian plugin:install id=custom-sort enable vault="$vname"
  obsidian plugin:install id=auto-card-link enable vault="$vname"
  obsidian plugin:install id=obsidian-importer enable vault="$vname"

What each one does:
  dataview                   -- live lists and tables built from your notes
  obsidian-tasks-plugin      -- to-dos with due dates across notes
  calendar                   -- a calendar in the sidebar for daily notes
  nldates-obsidian           -- type dates like "tomorrow" or "next friday"
  frontmatter-modified-date  -- auto-update a note's last-edited date
  custom-sort                -- control the order files show in the sidebar
  auto-card-link             -- turn pasted web links into preview cards
  obsidian-importer          -- import notes from Notion, Evernote, etc.

No CLI handy? Install the same ones from inside the app:
Settings -> Community plugins -> turn them on -> Browse -> search by name.

To chat with Claude inside Obsidian, install Claudian. It's in the community
store (and needs the Claude Code CLI, which you already have):

  obsidian plugin:install id=realclaudian enable vault="$vname"

(or search "Claudian" in Browse.)

Prefer the in-Obsidian MCP server over the mcpvault one (--mcp sets up)?
  obsidian plugin:install id=obsidian-local-rest-api enable vault="$vname"
  obsidian plugin:install id=mcp-tools enable vault="$vname"
------------------------------------------------------------------------
EOF
}

# ---- main -----------------------------------------------------------------

select_folders
scaffold
$DO_MCP     && register_mcp     || true
$DO_CLIS    && install_clis     || true
$DO_PLUGINS && install_plugins  || true

c_info "Done."
echo "Next:"
echo "  1. In Obsidian, choose \"Open folder as vault\" and pick: $VAULT"
echo "     (Use \"Open folder as vault,\" not \"Create new vault\" -- the folder already exists.)"
echo "  2. Open Claude Code in your vault and say \"catch me up\"."

if $DO_PLUGINS || $DO_MCP; then
  obsidian_checklist
else
  echo "Tip: run with --full to also install the CLIs, MCP server, and Claude Code plugins."
fi
