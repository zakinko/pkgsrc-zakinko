# Two Emacsen in one prefix: two ways, measured

The framework work stops short of letting `editors/emacs29` and
`editors/emacs30` be installed together: they share 93 files
(`bin/emacs`, `bin/ctags`, 66 info files, the icons, `emacs-module.h`,
`share/emacs/site-lisp/subdirs.el`).  emacs20 shares only four with
them, because it already renames what it installs.

Python solves the same problem with three pieces: `make altinstall`
(never create the unversioned names), `${PY_VER_SUFFIX}` in every PLIST
line, and an `ALTERNATIVES` file for `bin/python`.  Emacs has no
`altinstall`, so the question is what plays its part.

## A: let configure do it (`A/`)

    CONFIGURE_ARGS+=	--program-transform-name='s/$$/-${EMACS_VERSION}/'
    GNU_CONFIGURE_INFODIR=	${PREFIX}/share/emacs/${EMACS_VERSION}/info
    CONFIGURE_ARGS+=	--includedir=${PREFIX}/include/emacs-${EMACS_VERSION}
    INFO_FILES=		# private to this Emacs now
    PLIST_SUBST+=		EMACS_VERSION=${EMACS_VERSION}
    PRINT_PLIST_AWK+=	{ gsub(/${EMACS_VERSION}/, "$${EMACS_VERSION}"); }

plus a five-line `ALTERNATIVES`.  Upstream is not touched.

Emacs honours `program_transform_name` in `Makefile.in` for the emacs
binary, emacsclient, the man pages and the icons, and in
`lib-src/Makefile.in` for etags, ctags and ebrowse.  Of the 4374 lines
`print-PLIST` then produces, **4373 carry the version**; the one that
does not is `share/emacs/site-lisp/subdirs.el`, and the versioned
`share/emacs/${EMACS_VERSION}/site-lisp/subdirs.el` is there beside it,
so post-install removes the shared one.

One oddity to know about: `Makefile.in` runs `emacs-${version}` through
TRANSFORM as well, so with a suffix the real binary lands as
`bin/emacs-30.2-30.2` and `bin/emacs-30.2` is a symlink to it.  Nothing
breaks -- `ALTERNATIVES` points `bin/emacs` at `emacs-30.2` -- but it
looks like something upstream did not think about.

## B: let pkgsrc do it (`B/`)

A `post-install` that moves the five binaries, their five man pages,
the header and the info files, the way `editors/emacs20` does it today
with patches to `Makefile.in` and `lib-src/Makefile.in`.  Same
`ALTERNATIVES`.

It works, and it does not need configure to cooperate -- which matters
for Emacs 20.7, whose Makefiles ignore `program_transform_name`
entirely (it is accepted by configure and then never used).

But the list of names is written by hand, so it is only as complete as
whoever wrote it: this one missed the icons and `share/metainfo`, which
A renamed without being asked.  Every file upstream adds is a file B
forgets.

## Which

A, where configure cooperates -- that is emacs29, emacs30, emacs31.
For emacs20 the same shape needs four small hunks backported into
20.7's Makefiles (lib-src install and uninstall, the emacs binary, the
man pages), after which its three existing renaming patches can go and
it follows the same six lines as the others.

## What is here

    A/emacs30-A, A/emacs30-nox11-A, A/emacs31-A, A/emacs31-nox11-A
    B/emacs30-B, B/emacs30-nox11-B

They are copies of the tree's packages with the change applied, as
built on NetBSD 11.0/amd64 under /usr/pkgsrc/<session>/ so that the
tree itself stayed untouched.  A's PLIST is the generated one.

## Measured while doing it

**It works.**  On NetBSD 11.0/amd64, `/usr/pkg` now has
`emacs30-nox11-30.2nb1` and `emacs31-nox11-31.1nb1` installed together;
`emacs-30.2` and `emacs-31.1` both open a file, insert text and save it,
and `bin/emacs` is the alternatives symlink.  69 info files live under
`share/emacs/30.2/info` and 77 under `share/emacs/31.1/info`.

**`pkgtools/pkg_alternatives` has to be installed**, or the
`ALTERNATIVES` file is read and then silently ignored -- the framework
writes `+INSTALL` with a `test -x` guard around the registration.  The
box this was done on had no `bin/python` for exactly that reason.

**x11 and nox11 are not the axis.**  `editors/emacs30-nox11` points its
`PKGDIR`, `PLIST`, `PATCHDIR` and `DISTINFO_FILE` at `editors/emacs30`,
so the two share one PLIST and the `.el` files in it are identical; the
difference is what configure is told.  `modules.mk` does offer
`FOR_emacs_x`, `NOTFOR_emacs_x`, `FOR_emacs_nox` and `NOTFOR_emacs_nox`
for a package that wants to install different lisp for the two, and
documents them at line 189 -- but nothing in pkgsrc, `wip` or this
repository uses any of the four.  Other distributions do not split lisp
that way either: Debian has `emacs-gtk`, `emacs-lucid`, `emacs-pgtk` and
`emacs-nox` sharing one `emacs-common` for the lisp, Fedora the same
with `emacs-nw`, and Gentoo and FreeBSD build one package with the X
support behind a USE flag or an OPTION.  So the version is the only axis
worth splitting on, and that is what this does.

**What still shares a name across versions.**  Nine elisp packages
install a helper program under a version-less name -- `bin/mozc_emacs_helper`
(inputmethod/mozc-elisp), `bin/gnuclient` and four more (editors/gnuserv),
`bin/incm` and friends (mail/mew), `bin/base64-decode` (mail/vm),
`bin/doxymacs_parser`, `bin/tcinput`, `bin/dcc`,
`libexec/emacs-jabber-uri-handler`.  Their lisp goes to the versioned
directory but the helper does not, so the emacs30 and emacs31 builds of
those packages collide on that one file.  None of them links X
(`mozc_emacs_helper` pulls in zero X libraries), so they are candidates
for a `-bin` package shared between versions, the way Debian has
`emacs-bin-common`.  Not done here.
