# helix-litigate

litigate (`.lit` rule modules, `.case` matters) support for the
[Helix](https://helix-editor.com/) editor.

**Helix has no plugin system** (the project's own FAQ: "While there is
currently no plugin system available, we do intend to eventually have one"),
so this is not a plugin you install into Helix. It is the thing Helix actually
consumes: a language entry, the queries, and the grammar Helix builds a parser
from -- packaged so you don't have to assemble it.

Three files do all the work:

| file | goes where | why |
| --- | --- | --- |
| `languages.toml` | merged into `~/.config/helix/languages.toml` | declares the `litigate` language, the `litigate lsp --stdio` language server, and where the grammar comes from |
| `queries/litigate/*.scm` | `~/.config/helix/runtime/queries/litigate/` | Helix reads queries from its **own** runtime dir, never from a grammar repo |
| `install.sh` | run it | fetches the grammar, compiles the parser, installs the queries |

## Install

```sh
git clone https://github.com/davidawad/helix-litigate
cd helix-litigate
./install.sh
```

Then append the `[[language]]` / `[[language-server]]` / `[[grammar]]` entries
that `install.sh` prints to your `~/.config/helix/languages.toml` (it detects
and skips this if you already have it), and verify:

```sh
hx --health litigate
```

Expected:

```
Tree-sitter parser:  ✓
Highlight queries:   ✓
Textobject queries:  ✓
Indent queries:      ✓
```

The language server line shows `✘ litigate-lsp: 'litigate' not found in $PATH`
until the `litigate` binary is on `PATH`; highlighting, indentation and
textobjects do not need it.

`install.sh` needs `hx`, `git`, a C compiler and the `tree-sitter` CLI
(`cargo install tree-sitter-cli` or `npm i -g tree-sitter-cli`).
Alternatively, with the entries in `languages.toml` and the queries copied
into `~/.config/helix/runtime/queries/litigate/`, `hx --grammar fetch &&
hx --grammar build` builds the pinned grammar by itself.

The committed grammar parser is tree-sitter **ABI 15**, which Helix 25.07+
(libtree-sitter 0.25) loads. An older Helix needs the parser regenerated at
ABI 14 (`tree-sitter generate --abi 14` in the grammar checkout).

## What it covers

- Highlighting, indentation (`indents.scm`, two spaces) and locals for both
  file kinds: whatever
  [tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate)
  provides, with Helix's capture names (`@constant.numeric` for `@number`,
  `@namespace` for `@module`, ...). This repo owns no grammar; it pins one.
- Textobjects (`m` then `i`/`a`): `f` selects a declaration (nodes, rules,
  counting rules, calendars, transitions, deadlines, events, types,
  instances, ...; `]f` jumps to the next), `T` a test block, `e` an edge or
  link, `a` an event parameter or call argument, `c` a comment.
- Language server: `litigate lsp --stdio`, started from the workspace root
  marked by `Lit.toml` or `Lit.lock`. `auto-format` is off.
- `//` and `///` line comment tokens and `/* */` block comments, so `C-c`
  toggles comments.

## Keeping it in sync

`queries/litigate/{highlights,indents,locals,injections}.scm` are the
grammar's own queries (`queries/litigate/*.scm` in tree-sitter-litigate) with
capture names renamed for Helix; `textobjects.scm` is hand-written and
Helix-only. When you bump the grammar pin (`rev` in `languages.toml`,
`GRAMMAR_REV` in `install.sh`), re-derive the four from the new commit.

## Why a separate repo

Because the grammar has consumers that are not this one (Helix, plus
nvim-treesitter and the [litigate.vim](https://github.com/davidawad/litigate.vim)
plugin), and because a repo named `tree-sitter-litigate` should not have to
pretend to be Helix packaging. The grammar is the reusable artifact; this is
one distribution of it. The upstream-at-everyone answer is a PR to
[helix-editor/helix](https://github.com/helix-editor/helix) adding the
language, grammar and queries to Helix's own registry. Not done.

## Other editors

- Vim / Neovim: [litigate.vim](https://github.com/davidawad/litigate.vim)
- Emacs: [litigate-mode.el](https://github.com/davidawad/litigate-mode.el)
- Grammar (any other tree-sitter editor): [tree-sitter-litigate](https://github.com/davidawad/tree-sitter-litigate)

## Provenance

Seeded on 2026-10-23 from `editors/helix` in litgraph (commit `6dbf033`),
restructured to the layout of
[helix-bend](https://github.com/davidawad/helix-bend): the grammar entry points
at the standalone grammar repo instead of a subpath of litgraph, and
`install.sh` is new. litgraph keeps its in-repo copy.

## License

GPL-3.0-or-later, the license of litgraph, where this was seeded from -- see
[LICENSE](LICENSE).
