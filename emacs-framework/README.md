# pkgsrc Emacs framework: version selection, per-version lisp, pbulk

Work on `editors/emacs/modules.mk` and `mk/pbulk/pbulk-index.mk`, started
2026-09-15 after Thomas Klausner (wiz@) asked whether the Emacs framework
could be brought up to what `lang/python` and `lang/ruby` do:

1. `EMACS_TYPE` is a default, not a requirement.  A package that does not
   accept it is built for a version it does accept, instead of failing.
2. Lisp goes under the Emacs it was built for
   (`share/emacs/<version>/site-lisp`), and the package name carries the
   version (`emacs30-apel`), the way `py313-` packages do.
3. pbulk enumerates every version a package accepts, so a bulk build
   makes all of them.

Everything here is diffs against pkgsrc trunk, not an overlay package:
pkgsrc-zakinko cannot hold `editors/emacs/modules.mk` in place.  The
base is trunk `c8e5216` (2026-09-18); every diff applies with `patch -p0`
from the top of a pkgsrc tree, in any order, with no offset and no fuzz.

## 2026-09-26: most of it is upstream

wiz@ committed the framework on 2026-09-25: `modules.mk,v 1.43`
(7789547c2d), `pbulk-index.mk,v 1.32` (68291956e4), and the package side
in 7bd856ba40.  Against trunk 8a7ccb58ad (2026-09-26) every hunk of 34 of
the 36 package diffs here was either already present or had been done
upstream in its own form, so those diffs are gone from this directory;
`git log` has them.  `pbulk-index.mk,v 1.32` is this branch's file
byte for byte apart from the RCS id, so its three files went too.

What is left is what 1.43 does not do: the nox build kept beside the X
one (`EMACS_VARIANT`, its own lisp tree and `emacs-<ver>-nox11` binary,
`FOR_emacs_x`), `emacs21` to `emacs28` as types, and the CONFLICTS pruning
that goes with installing them side by side.  1.43 instead has one
`emacs30-foo` serve both emacs30 and emacs30-nox11.  `modules.mk.diff`
is now against 1.43, and `fixes/` holds the two package diffs that still
apply and are still needed (`artist-emacs-bin`, `vm-lispdir`).

Until this date the CI never laid the trunk files over the guest tree:
the workflow passed `zakinko/emacs-framework` to `fetch-trunk-files.sh`,
the files landed outside what `run-in-qemu.sh` sends, and every run
applied to the cdn tarball as it was.  It passes `emacs-framework` now.

## Layout

The diffs are in the three parts wiz asked for on 2026-09-19.

| directory | what | depends on |
|---|---|---|
| `modules.mk.diff` | the framework itself | – |
| `pkg-fixes/framework/` | the Emacs packages' own side of it: `version.mk` written once per Emacs, `buildlink3.mk` reading the new variables, a `site-start.el` that lets Emacs find info under its version directory | the framework |
| `pkg-fixes/fixes/` | packages that are wrong on trunk today, with the `modules.mk` that is there now | nothing |

`fixes/emacs29-nox11-version.diff` is the one of those that only shows up
once the lisp moves under a version directory.  `editors/emacs29` went to
29.4 and `editors/emacs29-nox11/version.mk` stayed at
`_EMACS_VERSION_MINOR= 1`, so a package built for emacs29nox installs its
lisp into `share/emacs/29.1/site-lisp` while the Emacs that is meant to
read it looks in `share/emacs/29.4/site-lisp`.  Found by building
`www/emacs-w3m-snapshot` against emacs29nox: `devel/apel` installed, and
the build then stopped with "Cannot open load file: product".  The other
six Emacs packages and all four XEmacs ones agree with their own version.
| `pkg-fixes/adaptations/` | packages that are right today and break once the prefix lands on their name | the framework |
| `pkg-fixes/not-sent/` | a diff that applies but does not make its package build (`devel/ecb`), kept for the record | – |

`modules.mk` is the patched file; `modules.mk.orig` is the trunk
revision it was made from (`modules.mk,v 1.43` since 2026-09-26), and
`modules.mk.diff` is the difference.

The line between `fixes/` and `adaptations/` is whether the package
breaks today under some Emacs pkgsrc has.  XEmacs already carries a
prefix, so `gnuserv`, `dictem`, `matlab-mode` and `xslide` are broken
today for XEmacs users; `lang/eieio` shadows the eieio bundled with
every current GNU Emacs; the packages that spell the lisp directory by
hand instead of using `${EMACS_LISPPREFIX}` are "not using the framework
correctly" in wiz's words, and go here even though the hand-written path
happens to coincide with the variable today.  A missing `GITHUB_PROJECT`,
by contrast, costs nothing until `PKGBASE` moves.

## What the framework does

- Version selection follows `pyversion.mk`: `EMACS_VERSION_REQD` is
  honoured or refused; otherwise `EMACS_TYPE` is the default, and a
  package that does not accept it falls back to the first entry of its
  own `EMACS_VERSIONS_ACCEPTED`, in the order the package wrote it.
  `EMACS_VERSIONS_INCOMPATIBLE`, previously set by `devel/apel` and read
  by nothing, is subtracted.  The dependency pattern is read back through
  `PKGNAME_REQD`, so a dependency is built for the version its dependent
  chose.
- The nox and X builds of one Emacs share a name: `emacs30-foo` serves
  either, and the dependency is written `{emacs30,emacs30-nox11}>=30.1<31`
  so `pkg_add` accepts either.  A package that refuses the X build in
  `EMACS_VERSIONS_INCOMPATIBLE` is named `emacs30-nox11-foo` and pinned.
- `share/emacs/<version>/site-lisp`, `share/emacs/<version>/etc`, and
  for packages whose name carries the prefix `share/emacs/<version>/info`
  via `PKGINFODIR`, so pkgsrc's own info handling (`plist-info.awk`,
  `gnu-configure.mk`'s `--infodir`, the `dir` file) follows.  A package
  that keeps one name whatever Emacs it is built for (`mail/mailutils`,
  `lang/bigloo`) keeps its info where the user's `PKGINFODIR` says.
- `EMACS_BIN` is the versioned binary (`bin/emacs-30.2`), so building for
  emacs29 no longer byte-compiles with whichever Emacs owns `bin/emacs`.
- Each nox `version.mk` includes its X11 twin and sets only what differs.
- `_EMACS_REQD` is widened in place to accept either twin, so a package
  whose dependency is already met by the nox11 build is not told to build
  the X11 one.  All twelve readers in the tree -- the `DEPENDS` line here
  and the `BUILDLINK_API_DEPENDS` line in each of the eleven Emacs
  `buildlink3.mk` files -- already spell `${_EMACS_REQD}`, so none of
  them changes.  The `BUILDLINK_ABI_DEPENDS` lines are left alone too:
  nothing in the tree includes an Emacs `buildlink3.mk`, so that floor is
  not read today, and when something does, the value belongs in that
  Emacs's `version.mk`.
- `EMACS_PKGNAME_PREFIX` is offered to the PLIST, because a package whose
  name carries it still installs `share/doc/<name>` and `info/` without it.
  `graphics/artist` is the one that already fails: `pkg_add` refuses
  `emacs30-artist` against a plain `artist` on `share/doc/artist/BUGS`.
  Across the tree, 48 packages whose PKGNAME carries the prefix have 1192
  PLIST lines that do not -- 30 of them under `bin/` and 14 under `man/`,
  which break coexistence outright, the rest under `share/` and `info/`,
  which stop the second Emacs's copy from installing.
- pbulk: `emacs` is added to `_PBULK_MULTI` with the filtered list, so
  `devel/apel` yields `emacs30-apel`, `emacs29-apel`, `emacs31-apel`.

What it does not do: let two Emacsen coexist.  `editors/emacs29` and
`editors/emacs30` share 93 files (`bin/emacs`, `bin/ctags`, 66 info
files, ...) and declare no conflict; that is a larger change and is left
as a question.

## Measuring

`.github/workflows/emacs-framework.yml` boots NetBSD 11.0/i386 under KVM,
fetches today's trunk copy of every file the diffs touch
(`.github/ci/fetch-trunk-files.sh`), applies the three parts in order,
builds ten packages, and checks that the installed lisp is on Emacs's
`load-path`.  The amd64 measurements are on a NetBSD 11.0 box with two
unprivileged bootstraps (emacs30nox and emacs20).

Records, drafts and the mail thread with wiz are kept outside this
repository.
