#!/usr/bin/env bash
# tools/test.sh — kyoten's whole suite, and the gate before every commit (AGENTS.kyoten.md § Rules). CI (KYR-13) runs
# this same script.
#
#   tools/test.sh
#
# It runs:
#   - `kama check` on the engine and on its tests program;
#   - the engine's tests (engine/tests/, one program), built debug and release and run natively, then built for wasm
#     and run under node;
#   - the 32 KiB frame guard: tools/fixtures/frame-guard, a game with a 40 KB frame, refused on every target but
#     Windows (natively off Windows, and on wasm), and built natively on Windows, where the guard is off;
#   - each example game that is cloned under examples/games/: `examples/games/fps` checked, then run natively and on
#     wasm, its output held to "fps example, on kyoten"; `examples/games/vr` checked. A game that is not cloned is
#     skipped, and says so.
#
# Run it from msys2 UCRT64 on Windows (`bash -lic`, so emcc and node are on PATH for the wasm legs), or any shell
# elsewhere. Without emcc or node the wasm legs are skipped, and say so.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) PLAT="${MSYSTEM:-$(uname -s)}-$(uname -m)"; EXE=.exe ;;
    *) PLAT="$(uname -s)-$(uname -m)"; EXE= ;;
esac
if [ -n "${KAMA:-}" ]; then :
elif command -v kama >/dev/null 2>&1; then KAMA=kama
elif [ -x "$ROOT/../kama/out/$PLAT/kama$EXE" ]; then KAMA="$ROOT/../kama/out/$PLAT/kama$EXE"
else echo "test: no kama (set KAMA)" >&2; exit 1
fi

failed=0
step() { echo; echo "== $*"; }
wasm=0
if command -v emcc >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then wasm=1; fi

TESTS=engine/tests
GAMES=examples/games
OUT="$TESTS/out"
mkdir -p "$OUT"

echo "test: $("$KAMA" --version)"

step "kama check"
"$KAMA" pkg install kama_workspace.json > /dev/null
"$KAMA" check engine/kama.json || failed=1
"$KAMA" pkg install "$TESTS/kama.json" > /dev/null
"$KAMA" check "$TESTS/kama.json" || failed=1

for mode in debug release; do
    step "engine tests, native, $mode"
    flag=""
    [ "$mode" = release ] && flag="--release"
    exe="$OUT/native-$mode/kyotentests$EXE"
    if "$KAMA" build "$TESTS/kama.json" $flag -o "$exe" > "$OUT/build-$mode.log" 2>&1; then
        "$exe" || failed=1
    else
        tail -20 "$OUT/build-$mode.log"
        failed=1
    fi
done

step "engine tests, wasm, under node"
if [ "$wasm" = 1 ]; then
    if "$KAMA" build "$TESTS/kama.json" --target WASM -o "$OUT/wasm/kyotentests.js" > "$OUT/build-wasm.log" 2>&1; then
        node "$OUT/wasm/kyotentests.js" || failed=1
    else
        tail -20 "$OUT/build-wasm.log"
        failed=1
    fi
else
    echo "skip no emcc or node on PATH (run from an interactive UCRT64 shell, bash -lic)"
fi

# The 32 KiB frame guard (components § Decided, question 6, choice 5). The engine's manifest sets it on every target
# but Windows, and a dependency's cflags reach its consumer's build, so it holds for every game without the game
# saying so. tools/fixtures/frame-guard is a game with a 40 KB frame and no flag of its own: its build must be
# refused by the guard, and on Windows, where the guard is off, it must build.
FIXTURE=tools/fixtures/frame-guard
guard_build() {
    local label="$1" want="$2"; shift 2
    local log="$OUT/frame-guard-$label.log"
    if "$KAMA" build "$FIXTURE/kama.json" "$@" > "$log" 2>&1; then
        if [ "$want" = built ]; then echo "ok   frame guard, $label: off on Windows, so a 40 KB frame builds"
        else echo "FAIL frame guard, $label: a 40 KB frame built"; failed=1; fi
    elif [ "$want" = refused ] && grep -q "frame-larger-than" "$log"; then
        echo "ok   frame guard, $label: a 40 KB frame is refused"
    else
        tail -20 "$log"
        echo "FAIL frame guard, $label: the build failed, but not by the guard"
        failed=1
    fi
}
step "the frame guard"
"$KAMA" pkg install "$FIXTURE/kama.json" > /dev/null
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) guard_build native built -o "$OUT/frame-guard/native/frameguard$EXE" ;;
    *) guard_build native refused -o "$OUT/frame-guard/native/frameguard$EXE" ;;
esac
if [ "$wasm" = 1 ]; then
    guard_build wasm refused --target WASM -o "$OUT/frame-guard/wasm/frameguard.js"
else
    echo "skip the frame guard on wasm: no emcc or node on PATH"
fi

# An example's run: build it with the given flags, run it with the given runner, and hold its output to the line it
# must print.
run_example() {
    local game="$1" label="$2" want="$3" out="$4" runner="$5"; shift 5
    local log="$OUT/games/$game-$label.log"
    mkdir -p "$OUT/games"
    if "$KAMA" build "$GAMES/$game/kama.json" "$@" -o "$out" > "$log" 2>&1; then
        local said
        if said="$($runner "$out" 2>&1)" && printf '%s\n' "$said" | grep -qF "$want"; then
            echo "ok   $GAMES/$game, $label: $want"
        else
            printf '%s\n' "$said"
            echo "FAIL $GAMES/$game, $label: no \"$want\""
            failed=1
        fi
    else
        tail -20 "$log"
        failed=1
    fi
}
native() { "$1"; }
under_node() { node "$1"; }

for game in fps vr; do
    step "$GAMES/$game"
    if [ ! -f "$GAMES/$game/kama.json" ]; then
        echo "skip $GAMES/$game is not cloned (it is its own repository, kyoten-example-$game)"
        continue
    fi
    "$KAMA" pkg install "$GAMES/$game/kama.json" > /dev/null
    "$KAMA" check "$GAMES/$game/kama.json" || failed=1
    if [ "$game" = fps ]; then
        want="fps example, on kyoten"
        run_example fps native "$want" "$OUT/games/fps/native/fps$EXE" native
        if [ "$wasm" = 1 ]; then
            run_example fps wasm "$want" "$OUT/games/fps/wasm/fps.js" under_node --target WASM
        else
            echo "skip $GAMES/fps on wasm: no emcc or node on PATH"
        fi
    fi
done

echo
if [ "$failed" = 0 ]; then echo "test: all passed"; else echo "test: FAILED" >&2; fi
exit "$failed"
