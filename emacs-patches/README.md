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
| editors/emacs20 | backup-buffer creates the backup under a 0700 umask; copy-file created it with the default modes and copied the original's over it afterwards, so a private file's backup was world-readable in between. files.elc is recompiled and emacs dumped again in post-build, since the distfile's files.elc is what gets dumped | own, after Emacs 25.3's backup-buffer-copy | CVE-2017-1000383 |
| editors/emacs20 | in batch mode with stdin from /dev/null, the first sleep-for or accept-process-output after a subprocess is started killed Emacs with SIGHUP (exit 129): keyboard.c sends itself SIGHUP when FIONREAD on the input fd fails, and NetBSD answers ENOTSUP for /dev/null. Found with ktrace while testing tamago-tsunagi; treat the failure as no input when noninteractive, as later Emacsen do. A 3-second wait now takes 3 s of wall clock and 0.02 s of CPU | own | — |
| editors/emacs20 | on a 64-bit host, setting file-name-coding-system (which `set-language-environment "Japanese"` does) made every `insert-file-contents` and `load` fail with "Wrong type argument: stringp, <number>": code_convert_string_norecord returns a Lisp_Object but had no prototype, so fileio.c and five other files called it as an int-returning function and truncated the pointer. Same for Fcurrent_time in frame.c and window.c. Found because inputmethod/tc's build does `(set-language-environment "Japanese")` first. Two prototypes added; the Japanese environment loads files again | own | — |
| editors/emacs20 | rcs2log wrote its two rlog scratch files to $TMPDIR/rcs2log<pid>{l,r}, predictable names that a symlink planted by another user redirects onto the caller's files (CVE-2001-1301, fixed in Emacs 21 by mktemp). A private mktemp -d directory holds them now and is removed on every exit path; run on a two-revision RCS file, same ChangeLog as before and nothing left in $TMPDIR | own, after Emacs 21 | CVE-2001-1301 |
| devel/mell | mell.el and mell-alist.el call define-obsolete-function-alias without the WHEN argument, which Emacs 29 made mandatory, so (require 'mell-alist) failed with "Eager macro-expansion failure: wrong-number-of-arguments" on emacs29–31 and every package on top of mell was unloadable there. The eleven calls carry "1.0.0" now; built and loaded on emacs30 | own | |
| inputmethod/tc | tc-sysdep.el picked the NEmacs code path on Emacs 22 and later (version regexp matched only 19–21), so tcode-redo-command set a variable modern Emacs lacks; its isearch shim read last-command-char, gone since 24; the Makefile's SUBST turning string-to-int into string-to-number lacked the g flag and left one call in eelll.el; tc-mkmzdic built its obarray from nils, which Emacs 30 rejects (Debian). Accepts emacs30/31 now too; built and probed on emacs30 and emacs20 | own; one from Debian | — |
| editors/xemacs (21.4.25) | the same etags fix; movemail drops the privileged gid around the file operations; cvtmail's name[14] overruns on a fourteen-digit ~/Messages/Directory entry (fscanf %14[…] stores fifteen bytes) — the stock binary aborts under the stack protector, the patched one converts | Debian xemacs21; OpenBSD (cvtmail) | CVE-2022-45939, CVE-2010-0825 |
| editors/xemacs-current (21.5.36) | the movemail fix, rebased by hand (the gid assignments sit after the declarations, so -Wdeclaration-after-statement stays quiet); 21.5.36's etags already filters in C, so CVE-2022-45939 does not apply | Debian xemacs21, rebased | CVE-2010-0825 |
| chat/emacs-jabber | make-obsolete WHEN argument (Emacs 28); autoloads through loaddefs-generate (Emacs 30).  With these it builds on emacs29-31, so they are accepted now | Gentoo, own | |
| misc/lookup | typo, coding tags, new-style backquotes, set-process-query-on-exit-flag.  Builds on emacs29-31 now, so they are accepted | Debian lookup-el | |
| editors/gnuserv | strerror instead of sys_errlist; old-style backquote; obsolete variables | Debian | |
| textproc/emacs-muse | quote the file name given to the shell in three viewer commands | after Debian (without Debian's viewer change) | |
| inputmethod/anthy-unicode-elisp | anthy.el: use a marker for the preedit start | Debian anthy | |
| inputmethod/iiimecf | symbol keys in the input table | Debian | |
| devel/semantic | pass LOADPATH to the bundled Makefile so speedbar and eieio are found (it did not build under emacs20) | own | |
| misc/color-theme | make-variable-frame-local, set-face-property, the modeline face, user-variable-p and cl are gone from Emacs 26–29, so color-theme-print died with a void user-variable-p and per-frame themes could not be set (Gentoo); the themes directory was joined as DIR//themes, which Emacs 20 reads as /themes, so it never found its own theme files (own). color-theme-print runs on emacs30 and emacs20 | Gentoo (Drew Adams), own | |

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
- OpenBSD xemacs21: the CVE-2009-2688 image-size checks and the png-1.5
  calls are in 21.4.25 already; movemail's mktemp→mkstemp changes a
  lock file that is opened with O_EXCL anyway; the rest is OpenBSD's
  layout (dump file name, find-paths, ctags.1, no inet gnuserv).  The
  lisp.h max_align_t clash only shows with a C11 clang and was not
  built here.
- Gentoo xemacs 21.5.36: berkdb/postgresql/xaw3d configure choices and
  test-only changes; the cus-dep lock-file change has no visible effect
  in a pkgsrc build.
- MacPorts xemacs: the two png changesets are in 21.4.25; texinfo5 is
  for 21.4.22's manuals, which build with texinfo 7.2 as they are.
- Fedora vm marker-pointer: written for a later snapshot whose
  vm-vs-header already has with-current-buffer; 8.2.0b's does not, the
  hunk does not apply, and the failure was not reproduced here.
- FreeBSD howm (--exclude-dir → --exclude, for FreeBSD's grep; howm
  probes the option itself), dictionary.el (1.11 already guards
  make-local-hook with featurep xemacs), ess (ess-jags-d moved in 2026
  git, still present in 25.01.0).
- Debian xslide (quotes face variables the file defvars to themselves),
  zenirc (notify rewrite and font-lock: features), howm auto-mode
  `\'` (lint-level), pcl-cvs 2.0b2 (pkgsrc has 2.9.9), migemo UTF-8
  and File.foreach (pkgsrc sets Encoding.default_external instead).
- Debian egg (tamago-tsunagi 5.0.7.1 descends from it and has these;
  FreeBSD's its.el obarray-make hunks are pkgsrc's patch-its.el), w3-el
  (a maintenance fork: HTML 4 entities, utf-8 — features on a package
  that only emacs20/21 build), ilisp (a 562-hunk single-patch fork).
- Gentoo mic-paren cl-lib: taken, but as part of the 3.15 update on the
  emacs-updates branch, where it belongs.
- Gentoo mailcrypt backquotes: the old-style backquote sits in a
  with-current-buffer fallback that never runs on any Emacs pkgsrc has;
  mc-gpg loads unpatched on emacs30 and emacs20, the patch only silences
  a byte-compiler warning.

## Not resolved

- Reviving jde/bbdb2/nxml-mode for emacs20: nxml-mode refuses Emacs 20
  itself, bbdb2 2.35 needs mail-parse (Gnus), jde's dependency chain
  did not complete here.
