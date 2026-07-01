#!/usr/bin/env bash
# custom launcher override: ALWAYS use tmux to open revdiff and capture annotations.
# location: ${CLAUDE_PLUGIN_DATA}/scripts/launch-revdiff.sh (user override layer)
# behavior: default overlay popup (tmux display-popup); falls back to a split pane
#           (inside tmux, popup unsupported) or a new detached session (no client).
# usage: launch-revdiff.sh [base] [against] [--staged] [--untracked] [--only=file]
#        [--all-files] [--exclude=prefix] [--stdin] [--stdin-name] [--annotations=path]
#        [--description=text] [--description-file=path]
# output: annotation text from revdiff stdout (empty if no annotations)
# exit: 0 clean, 10 annotations captured, other nonzero failure

set -euo pipefail

# tmux is mandatory for this launcher.
if ! command -v tmux >/dev/null 2>&1; then
    echo "error: this custom launcher always uses tmux, but tmux was not found in PATH" >&2
    echo "install: brew install tmux (or your platform's package manager)" >&2
    exit 1
fi

# resolve revdiff to absolute path so overlay shells (sh -c) can find it
# even when /opt/homebrew/bin or similar dirs are not in sh's default PATH
REVDIFF_BIN=$(command -v revdiff 2>/dev/null || true)
if [ -z "$REVDIFF_BIN" ]; then
    echo "error: revdiff not found in PATH" >&2
    echo "install: brew install umputun/apps/revdiff (or download from https://github.com/umputun/revdiff/releases)" >&2
    exit 1
fi

TMPBASE="${TMPDIR:-/tmp}"
OUTPUT_FILE=$(mktemp "$TMPBASE/revdiff-output-XXXXXX")
trap 'rm -f "$OUTPUT_FILE"' EXIT

# shell-quote a single argument for safe embedding in sh -c strings.
sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

REVDIFF_CMD="$(sq "$REVDIFF_BIN")"
if [ -n "${REVDIFF_CONFIG:-}" ] && [ -f "$REVDIFF_CONFIG" ]; then
    REVDIFF_CMD="$REVDIFF_CMD $(sq "--config=$REVDIFF_CONFIG")"
fi
# pass exit-code-on-annotations via env, not a CLI flag: an old revdiff binary
# silently ignores an unknown env var but hard-fails on an unknown flag
REVDIFF_CMD="REVDIFF_EXIT_CODE_ON_ANNOTATIONS=true $REVDIFF_CMD $(sq "--output=$OUTPUT_FILE")"
for arg in "$@"; do
    REVDIFF_CMD="$REVDIFF_CMD $(sq "$arg")"
done

write_rc_cmd() {
    local sentinel="$1"
    # single-quoted format keeps $?/$rc literal for the generated inner script
    # shellcheck disable=SC2016
    printf '%s; rc=$?; printf "%%s" "$rc" > %s.tmp && mv -f %s.tmp %s' \
        "$REVDIFF_CMD" "$(sq "$sentinel")" "$(sq "$sentinel")" "$(sq "$sentinel")"
}

read_rc() {
    cat "$1" 2>/dev/null || echo 1
}

print_output_and_exit() {
    local rc="${1:-0}"
    cat "$OUTPUT_FILE"
    exit "$rc"
}

# overlay backends (tmux display-popup, tmux new-window, etc.) spawn children from
# a server process whose env predates user shell rc files, so EDITOR/VISUAL exports
# from .zshrc/.bashrc are otherwise lost. prepend `env KEY=VAL` so revdiff itself
# starts with the caller's editor env, which its multi-line annotation flow passes
# to the spawned editor child.
ENV_PREFIX=""
for _name in EDITOR VISUAL; do
    if [ "${!_name+x}" = x ]; then
        ENV_PREFIX="$ENV_PREFIX $(sq "${_name}=${!_name}")"
    fi
done
unset _name
if [ -n "$ENV_PREFIX" ]; then
    REVDIFF_CMD="/usr/bin/env$ENV_PREFIX $REVDIFF_CMD"
fi

CWD="$(pwd)"

# build descriptive title: "rd: dirname [ref]"
DIR_NAME=$(basename "$CWD")
TITLE_REF=""
SKIP_NEXT=0
for arg in "$@"; do
    if [ "$SKIP_NEXT" -eq 1 ]; then SKIP_NEXT=0; continue; fi
    case "$arg" in
        -o|--output) SKIP_NEXT=1 ;;
        --output=*) ;;
        -*) ;;
        *) TITLE_REF="$arg"; break ;;
    esac
done
OVERLAY_TITLE="rd: ${DIR_NAME}${TITLE_REF:+ [$TITLE_REF]}"

# popup size: override via REVDIFF_POPUP_WIDTH / REVDIFF_POPUP_HEIGHT env vars
POPUP_W="${REVDIFF_POPUP_WIDTH:-90%}"
POPUP_H="${REVDIFF_POPUP_HEIGHT:-90%}"

# detect tmux version once: sets TMUX_MAJOR / TMUX_MINOR (0 0 if unparseable)
TMUX_MAJOR=0
TMUX_MINOR=0
if [[ "$(tmux -V 2>/dev/null)" =~ ([0-9]+)\.([0-9]+) ]]; then
    TMUX_MAJOR="${BASH_REMATCH[1]}"
    TMUX_MINOR="${BASH_REMATCH[2]}"
fi
# display-popup landed in tmux 3.2; -T (popup title) requires 3.3+
tmux_has_popup() {
    [ "$TMUX_MAJOR" -gt 3 ] || { [ "$TMUX_MAJOR" -eq 3 ] && [ "$TMUX_MINOR" -ge 2 ]; }
}
tmux_has_popup_title() {
    [ "$TMUX_MAJOR" -gt 3 ] || { [ "$TMUX_MAJOR" -eq 3 ] && [ "$TMUX_MINOR" -ge 3 ]; }
}

# When invoked outside a tmux client ($TMUX unset), display-popup/new-window have
# no target client and would fail. Ensure a server + attachable target exists by
# picking a session (or creating a detached one) and pointing tmux at it via -t.
# Inside tmux, $TMUX is set and every tmux subcommand targets the current client,
# so no explicit target is needed.
TMUX_TARGET=()
if [ -z "${TMUX:-}" ]; then
    RD_SESSION=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | head -1 || true)
    if [ -z "$RD_SESSION" ]; then
        RD_SESSION="revdiff-$$"
        # detached session rooted at CWD; -x/-y give the popup room to size against
        tmux new-session -d -s "$RD_SESSION" -c "$CWD" -x 200 -y 50 2>/dev/null || {
            echo "error: could not start a tmux session for revdiff" >&2
            exit 1
        }
        trap 'tmux kill-session -t "$RD_SESSION" >/dev/null 2>&1 || true; rm -f "$OUTPUT_FILE"' EXIT
    fi
    TMUX_TARGET=(-t "$RD_SESSION")
fi

# --- primary path: overlay popup (tmux display-popup -E blocks until cmd exits) ---
if tmux_has_popup; then
    POPUP_ARGS=(tmux display-popup "${TMUX_TARGET[@]}" -E -w "$POPUP_W" -h "$POPUP_H")
    if tmux_has_popup_title; then
        POPUP_ARGS+=(-T " $OVERLAY_TITLE ")
    fi
    POPUP_ARGS+=(-d "$CWD" -- sh -c "$REVDIFF_CMD")
    rc=0
    if "${POPUP_ARGS[@]}"; then
        print_output_and_exit 0
    else
        rc=$?
        # exit 10 is success-with-annotations, not a popup failure; pass it through.
        if [ "$rc" -eq 10 ]; then
            print_output_and_exit 10
        fi
        # any other nonzero: fall through to the pane/window fallback below, since
        # display-popup can also fail for environmental reasons (e.g. control mode).
        echo "warning: tmux display-popup failed (rc=$rc); falling back to a tmux window" >&2
    fi
fi

# --- fallback path: run revdiff in a separate tmux window and poll a sentinel ---
# Used when display-popup is unavailable (tmux < 3.2) or the popup call failed.
# A background window + sentinel file replaces the popup's blocking behavior:
# revdiff runs in its own window, writes its exit code to the sentinel on exit,
# and we wait for that file before reading the captured annotations.
SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
rm -f "$SENTINEL"

LAUNCH_SCRIPT=$(mktemp "$TMPBASE/revdiff-launch-XXXXXX")
# preserve any session-cleanup trap set above while adding the fallback temp files
if [ -n "${RD_SESSION:-}" ] && [ -z "${TMUX:-}" ]; then
    trap 'tmux kill-session -t "$RD_SESSION" >/dev/null 2>&1 || true; rm -f "$OUTPUT_FILE" "$SENTINEL" "$SENTINEL.tmp" "$LAUNCH_SCRIPT"' EXIT
else
    trap 'rm -f "$OUTPUT_FILE" "$SENTINEL" "$SENTINEL.tmp" "$LAUNCH_SCRIPT"' EXIT
fi
cat > "$LAUNCH_SCRIPT" <<LAUNCHER
#!/bin/sh
$(write_rc_cmd "$SENTINEL")
LAUNCHER
chmod +x "$LAUNCH_SCRIPT"

# open a new window running the launch script; -P/-F would print the id but we
# only need it to run and self-report via the sentinel. When inside tmux this
# adds a window to the current session; otherwise it targets RD_SESSION.
if ! tmux new-window "${TMUX_TARGET[@]}" -n "$OVERLAY_TITLE" -c "$CWD" \
        "sh $(sq "$LAUNCH_SCRIPT")" >/dev/null 2>&1; then
    echo "error: failed to open tmux window for revdiff" >&2
    exit 1
fi

while [ ! -f "$SENTINEL" ]; do
    sleep 0.3
done
rc=$(read_rc "$SENTINEL")
print_output_and_exit "${rc:-1}"
