#!/usr/bin/env bash
# install.sh -- make litigate (.lit, .case) highlight in Helix.
#
# Helix has no plugin system, so there is nothing to install *into*. What a
# language actually needs is: a tree-sitter parser Helix can load, and queries
# in one of Helix's runtime dirs. Helix reads queries from ITS OWN runtime dirs
# and never from a grammar repo, which is the one thing that makes this more
# than a config line.
#
# This script does the mechanical parts. The one part it will not do for you is
# edit your languages.toml, because it cannot know what else is in there --
# it prints the snippet and tells you if it is already present.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELIX_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/helix"
RUNTIME="$HELIX_CONFIG/runtime"
GRAMMAR_REPO="https://github.com/davidawad/tree-sitter-litigate"
# Pinned on purpose; keep equal to the rev in languages.toml.
GRAMMAR_REV="ceb16e66552f524fde0c47ef6ffcf86dda2499af"

if ! command -v hx >/dev/null 2>&1; then
  echo "install: the 'hx' binary is not on PATH." >&2
  exit 1
fi
if ! command -v tree-sitter >/dev/null 2>&1; then
  echo "install: the tree-sitter CLI is not on PATH." >&2
  echo "  install: cargo install tree-sitter-cli   (or: npm i -g tree-sitter-cli)" >&2
  exit 1
fi

mkdir -p "$RUNTIME/grammars/sources" "$RUNTIME/queries/litigate"

if [ ! -d "$RUNTIME/grammars/sources/litigate/.git" ]; then
  git clone --quiet "$GRAMMAR_REPO" "$RUNTIME/grammars/sources/litigate"
fi
git -C "$RUNTIME/grammars/sources/litigate" fetch --quiet origin
git -C "$RUNTIME/grammars/sources/litigate" checkout --quiet "$GRAMMAR_REV"

# The committed parser is tree-sitter ABI 15; Helix 25.07+ (libtree-sitter
# 0.25) loads it. An older Helix needs the parser regenerated at ABI 14.
tree-sitter build -o "$RUNTIME/grammars/litigate.so" "$RUNTIME/grammars/sources/litigate"
cp "$HERE/queries/litigate/"*.scm "$RUNTIME/queries/litigate/"

echo "install: built $RUNTIME/grammars/litigate.so from $GRAMMAR_REPO @ ${GRAMMAR_REV:0:12}"
echo "install: installed $RUNTIME/queries/litigate/*.scm"

if grep -q 'name = "litigate"' "$HELIX_CONFIG/languages.toml" 2>/dev/null; then
  echo "install: a 'litigate' language entry is already present in $HELIX_CONFIG/languages.toml"
else
  echo
  echo "install: still to do -- add this to $HELIX_CONFIG/languages.toml:"
  echo "---------------------------------------------------------------"
  cat "$HERE/languages.toml"
  echo "---------------------------------------------------------------"
fi

echo
echo "install: verify with:  hx --health litigate"
echo "install: expected --    Tree-sitter parser OK, Highlight, Textobject and Indent queries OK"
echo "install: The language server shows missing until 'litigate' is on PATH."
