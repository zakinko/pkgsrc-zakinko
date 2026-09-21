# Patches for the Emacs packages, gathered from the other packaging trees

Diffs against pkgsrc trunk (2026-09-21).  Each brings into a pkgsrc
package a fix that another tree already carries -- Gentoo's emacs
patchsets, Debian, FreeBSD ports, DragonFly DPorts, MacPorts, Fedora --
after reading it with pkgsrc's spread of operating systems in mind, and
after building the package with it on NetBSD 11.0/amd64.  Every pkgsrc
patch file carries a description and the origin; PKGREVISION is bumped.

## What is taken, and from where

| package | fix | origin | CVE |
|---|---|---|---|
| editors/emacs30 | tree-sitter query predicate names for tree-sitter 0.26 (merged into the existing patch-src_treesit.c) | Gentoo 02, Debian 0028 | |
| editors/emacs30 | nullify read-symbol-shorthands around intern (crafted file runs Lisp when visited, bug#80574) | Gentoo 04, Debian 0030 | (none assigned yet) |
| editors/emacs30, emacs31 | trusted-content-p in flymake | Gentoo, FreeBSD | |
| editors/emacs30 | flymake ruby backend with ruby 4.0 | Gentoo 03 | |
| editors/emacs29, emacs30 | svg_load_image off-by-one (bug#80851) | Debian 0025 | CVE-2026-6861 |
| editors/emacs29, emacs30 | PBM/PPM/PGM loader integer overflow (bug#81344), from emacs commit b07e634e; Emacs 29 gets INT_MULTIPLY_WRAPV for ckd_mul | upstream 31.0.91 | CVE-2026-77219 |
| editors/emacs29 | tramp local command execution | Gentoo 10 | CVE-2026-79992 (emacs30 was fixed by wiz@ on 2026-08-25) |
| editors/emacs29 | trusted-content mechanism for elisp-completion-at-point | Gentoo 07 | CVE-2024-53920 |
| editors/emacs29 | shorthands (as for 30); epg: no pinentry loopback for gpgsm (debbugs 67012) | Gentoo 09, 02 | |
| editors/emacs30 | do not dereference a NULL GSettingsSchemaSource | MacPorts | |
| editors/emacs30 | include <sys/signal.h> in process.h | DragonFly DPorts | |
| editors/emacs30 | pgtk: fall back to the terminal when there is no display | Fedora | |
| editors/emacs20 | etags/ctags -u ran "mv ... OTAGS; fgrep ..." through the shell with the file name unquoted; filter in C instead (Emacs 28.2's fix, rewritten for the K&R source) | own, after Debian's XEmacs version | CVE-2022-45939 |
| editors/xemacs (21.4.25) | the same etags fix; movemail drops the privileged gid around the file operations | Debian xemacs21 | CVE-2022-45939, CVE-2010-0825 |
| chat/emacs-jabber | make-obsolete WHEN argument (Emacs 28); autoloads through loaddefs-generate (Emacs 30).  With these it builds on emacs29-31, so they are accepted now | Gentoo, own | |
| misc/lookup | typo, coding tags, new-style backquotes, set-process-query-on-exit-flag.  Builds on emacs29-31 now, so they are accepted | Debian lookup-el | |
| editors/gnuserv | strerror instead of sys_errlist; old-style backquote; obsolete variables | Debian | |
| textproc/emacs-muse | quote the file name given to the shell in three viewer commands | after Debian (without Debian's viewer change) | |
| inputmethod/anthy-unicode-elisp | anthy.el: use a marker for the preedit start | Debian anthy | |
| inputmethod/iiimecf | symbol keys in the input table | Debian | |
| devel/semantic | pass LOADPATH to the bundled Makefile so speedbar and eieio are found (it did not build under emacs20) | own | |

## Read and not taken

- DragonFly: the ieee754.in.h hunk tests `__DragonFLy__` (a typo) and so
  does nothing; the dired.el hunk forces LC_TIME=C on every listing, a
  behaviour change upstream did not take.
- MacPorts: dbusbind (allows session-bus autolaunch, a policy change);
  allow-powerpc (configure.ac only; this package does not run autoconf).
- OpenBSD: install man/info uncompressed -- pkgsrc handles MANZ itself.
- Nix and Fedora: distribution policy (early-init order, native-comp
  driver options, spellchecker default, crypto policy, error wording).
- Gentoo emacs 29: sanity-check (Gentoo's build check), autoconf-2.72
  (configure.ac), and the test-only patches.
- FreeBSD riece, Gentoo doxymacs, Debian emacspeak: pkgsrc's riece
  patches, the doxymacs source and emacspeak 60.0 already have them.
- Debian mew: C.UTF-8 for gpg -- not every pkgsrc platform has that
  locale.
- Debian gnuserv 1-fix-bufferovs (already in 3.12.8) and 4-xauth (does
  not apply to 3.12.8).

## Not resolved

- XEmacs 21.5.36 (editors/xemacs-current) has the CVE-2010-0825 movemail
  code; Debian's patch is for 21.4 and does not apply.
- editors/emacs20 is also listed for CVE-2017-1000383 (backup files
  ignore umask); not patched here.
- Reviving jde/bbdb2/nxml-mode for emacs20: nxml-mode refuses Emacs 20
  itself, bbdb2 2.35 needs mail-parse (Gnus), jde's dependency chain
  did not complete here.
