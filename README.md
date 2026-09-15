# chicago/appwiz — Add/Remove Programs

A module of the Windows 95 shell for the terminal desktop
([chicago/shell](https://github.com/chicago-desktop/shell) on
[chicago/tui-desktop](https://github.com/chicago-desktop/tui-desktop)): it adds
**Add/Remove Programs** to Start → Settings. A program here is a wippy
module. The window lists the application's modules — the `ns.dependency`
declarations in the registry plus the vendor cache with version and size —
and edits the application's declarations file: it removes and appends
entries.

The change takes effect after `wippy update` and a restart, and the window
says so itself. It does not touch the registry or the Hub: there is nothing
in a running runtime to install or remove a module with, and pretending to
have installed one is the worst thing this panel could do. How the file is
edited, and what the window refuses and why: [docs/appwiz.md](docs/appwiz.md).

## What the application provides

**The application names the declarations folder.** The environment variable
`CHICAGO_DEPS_FS` is the id of an `fs.directory` entry over the folder that
holds the application's dependency declarations (`_index.yaml` with the
`ns.dependency` entries). The module declares no such entry itself — only the
application knows where its declarations live. For example, an application
whose dependencies are in `src/app/deps`:

```yaml
# src/app/desktop/_index.yaml
- name: deps_source
  kind: fs.directory
  directory: ./src/app/deps
  auto_init: false
```

```yaml
# .wippy.yaml
override:
  "app.env:defaults:data.CHICAGO_DEPS_FS": app.desktop:deps_source
```

Without the variable the window opens read-only and says what is missing;
with a variable it may not read, it says it lacks `env.get` rather than
calling the variable unset. The window reads this one variable and nothing
else (`chicago.appwiz:window_env` grants it by name — neighbouring names
hold tokens).

**Only an administrator opens it.** The window edits the application's
dependencies, so its entry names `requires: chicago.admin`, and the base's
compositor asks the logged-on person's scope before opening it. An
application grants `chicago.admin` to its administrators; a group whose
policy allows `*` has it already.

## Inside

- `chicago.appwiz:model` — the pure model: merging declarations with the
  cache, editing the declarations text (removing an item with its comments,
  appending one), checking an edit before it is written, writing with a
  backup and a read-back.
- `chicago.appwiz:window` — the process on the shell's SDK
  (`chicago.shell.sdk:app`): a table of modules, Install… / Remove / Refresh,
  the status line.
- `chicago.appwiz:images` — the module carries its own picture, an image
  pack of the shell (`meta.type: chicago.images`) under
  `assets/images/{32,16}`: `appwizard`, named
  `chicago.appwiz:images/appwizard` by the entry; copied from the shell's
  icon set (Microsoft's artwork from `shell32.dll`, see
  `assets/images/SOURCE.md`) and embedded at publish through `embed:` in
  `wippy.yaml`.
- `chicago.appwiz:window_scope`, `chicago.appwiz:window_env` — its
  permissions: read the registry, the module cache and the declarations
  folder, the one environment variable; no processes, no registry changes.

The module depends on `chicago/shell` (the SDK, the image packs, the
environment reader `chicago.shell.config:environment`) and
`chicago/tui-desktop` (the compositor).

## Developing

```bash
make setup     # resolve the dependencies from the Hub (once, and after changing them)
make check     # the repository's invariants
make lint      # late locals, then wippy lint of this namespace and the harness
make test      # the harness in test/: the model, the window, a shot in test/shots/
make publish   # to the Hub, after `wippy auth login`
```

**A local build of the runtime fork is required**
([chicago-desktop/runtime](https://github.com/chicago-desktop/runtime), branch
`wippy-projects`): the shell declares the `gfx` module, which the release
runtime does not have, and `wippy` from PATH does not load the shell at all.
The Makefile's `WIPPY` names the build; override it with `make test WIPPY=…`.

The window SDK is documented in [docs/sdk.md](docs/sdk.md), a copy of the
shell's guide, and the skill for agents in
[skills/wippy-window-app/SKILL.md](skills/wippy-window-app/SKILL.md); the
rules of this repository are in [AGENTS.md](AGENTS.md).

Made from [the Windows module template](https://github.com/chicago-desktop/module-template) for
modules of the Windows 95 shell. Repository:
https://github.com/chicago-desktop/appwiz. Add/Remove Programs was part of
`chicago/shell` up to 0.1.0.

## Licence

MIT. The picture in `assets/images` is Microsoft's artwork (`shell32.dll`),
copied from the shell's icon set, and is not covered by the licence.
