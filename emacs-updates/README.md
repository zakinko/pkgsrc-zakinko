# Updates for the Emacs packages in pkgsrc

Diffs against pkgsrc trunk (2026-09-21) bringing the packages that read
`editors/emacs/modules.mk` up to their current upstream releases.  One
diff per package, `patch -p0` from the top of a pkgsrc tree; they are
independent of each other except where noted.

Each (but ruby-rd-mode, see the table) was built on NetBSD 11.0/amd64 against emacs30-nox11 30.2 with the
`modules.mk` that is on trunk, with `bmake package-install`, and the
package's main library loaded into that Emacs afterwards.  Where the
PLIST changed it was regenerated from the installed files, keeping the
original `$NetBSD$` line and any `${PLIST.*}` conditionals.

| package | from | to | notes |
|---|---|---|---|
| cad/verilog-mode | 3.60 (2005, MASTER_SITE_LOCAL) | 2026.08.31 | veripool ships `verilog-mode.el` without a version in its name; fetched under DIST_SUBDIR.  2026.08.31 wants dolist and cl's remove at byte-compile time and make-obsolete-variable's WHEN at load time, none of which Emacs 20 has, so `files/verilog-e20.el` pulls in APEL's poe when the Emacs is older than 21 and a one-line soft require reaches it; builds and loads on emacs20 and emacs30 |
| devel/apel | 2020-11-07 snapshot | 2025-05-31 snapshot | and serves Emacs 20 and XEmacs again: the compatibility layer upstream removed in 2020 comes back as 17 patches and 11 files under files/, keeping the fixes made since (pccl-20 uses define-coding-system where it exists, so Emacs 30 still builds it). Built for emacs20 20.7, emacs30 30.2 and xemacs214nox 21.4.25; misc/lookup, which accepts only emacs20 and XEmacs and needs apel, builds on emacs20 again. poe.el also gains dolist, dotimes, mapc, declare-function and the three-argument make-obsolete for Emacs 20, which FLIM and SEMI use, booleanp and add-to-list's APPEND for misc/elscreen (wrapped again after bytecomp.el loads, since that file carries the two-argument originals on Emacs 20/21). XEmacs is accepted again: the apel in xemacs-packages predates detect-mime-charset-string, which FLIM's eword-encode has needed since 2020, and that function is also added to the legacy-Mule branch of mcs-20.el (on Emacs 20 eword-encode-string was void without it). EMU-ELS's mcharset block is a cond again — upstream's 2017 rewrite left the XEmacs branch returning nil, so mcs-20/mcs-xm/mcharset were never compiled or installed there. For XEmacs, post-install runs upstream's install-update-package-files so auto-autoloads.el and custom-load.el exist; PLIST.xemacs loses timezone.el, gone since 10.8 |
| devel/flim | 1.14.9 + 2023 branch | same | builds on emacs20 again: ?\s (Emacs 22 syntax) spelled ?\  in the eight files that use it, folded into the existing patches; hmac-def.el, which the package deletes as "included in Emacs", is kept on Emacs before 22; cl-lib comes from the new devel/cl-lib-el below on Emacs before 24 (XEmacs 21 included). std11.el requires poe first: mime-view reaches std11 through mime before anything loads poe's wrapper, and std11's make-obsolete passes WHEN. The XEmacs build target was gone — the 2023 patches dropped `package`/`install-package` from Makefile and FLIM-MK, so XEmacs never built; they are kept now, PLIST's info lines use ${EMACS_INFOPREFIX}, and devel/apel is required on XEmacs too. Exercised on emacs20, emacs30nox and xemacs214nox: eword-decode-string and eword-encode-string round-trip an ISO-2022-JP encoded-word, mime-open-entity on a buffer, mime-view and mime-edit load |
| devel/semi | 1.14.6 | same | the cl-lib buildlink for Emacs before 24 (XEmacs 21 included); do-install matched `/site-lisp/semi/`, which installed nothing for XEmacs, so it matches `/semi/`; mime-parse-buffer on a multipart message works on emacs20; builds and loads on xemacs214nox too; patch-SEMI-MK makes the autoload pass call batch-update-directory-autoloads with the feature name and the directory, the way FLIM-MK in devel/flim already does, so XEmacs 21.5 no longer stops at "Wrong type argument: stringp, nil" -- clean builds green on xemacs215nox and emacs30nox |
| graphics/artist | 1.2.6 | same | its PKGNAME carries EMACS_PKGNAME_PREFIX but its DOCDIR did not, so under the emacs-framework branch (which puts the version in the name) `pkg_add` refuses the second copy: "emacs30-artist-1.2.6nb4: conflicting PLIST with artist-1.2.6nb4: share/doc/artist/BUGS". DOCDIR and the PLIST now spell `${EMACS_PKGNAME_PREFIX}artist`, which needed modules.mk to hand the prefix to the PLIST at all. Measured: artist, emacs30-artist and emacs20-artist installed together in one prefix, each with its own share/doc/<name>/ |
| devel/libuuid | 2.42.3 | same | not an Emacs package, but it is the floor under devel/apel and so under flim, semi and emacs-w3m. Its configure runs libtool's C++ test while the Makefile declares `USE_LANGUAGES= c`, so on a prefix with no C++ compiler the build stops: pkgsrc itself prints "but it is not added to USE_LANGUAGES in the package Makefile" and then libtool says "problem compiling CXX test program". `USE_LANGUAGES= c c++` builds (rc=0), and xemacs215-apel then installs. It builds on an ordinary machine because something else has already pulled a C++ compiler in |
| devel/elisp-compat | – | 20260922 | **new** (`new/elisp-compat/`): one file, elisp-compat.el, defining only when missing what elisp written for Emacs 21–26 uses on Emacs 20: dolist, cl's remove and the WHEN argument make-obsolete-variable grew in Emacs 23 (devel/apel is marked incompatible with emacs20, so the poe that used to supply these is out of reach; measured on a real 20.7: `dolist=(3 2 1)`, `remove=(1 3)`, the three-argument make-obsolete-variable accepted), hash tables (over alists), replace-regexp-in-string, propertize, nbutlast, subr-x's strings, setq-local, with-eval-after-load, prog-mode, syntax-ppss, syntax-propertize (rules become a function run from post-command-hook and, on Emacs 20, also font-lock-syntactic-keywords), obarray-make, set-process-query-on-exit-flag, and a regexp translator for shy groups, `\\{n,m\\}`, `[:alpha:]` and `\\_<` that remaps the match data afterwards. nxml-mode and graphviz-dot-mode use it |
| devel/cl-lib-el | – | 0.6.1 | **new** (`new/cl-lib-el/`): GNU ELPA's forward-compatibility cl-lib, for Emacs before 24.3; accepts emacs20 and XEmacs 21.4/21.5 (cl-loop and cl-remove-if work on 21.4.25). The distfile is a single lzip-compressed .el, which pkgsrc's extract does not handle, so do-extract calls lzip |
| devel/cflow-mode | 1.7 | 1.8 | |
| devel/dash-el | 2.19.1 | 2.20.0 | |
| devel/ecb | 2.50 | 2.52 | now builds and loads with the CEDET bundled in Emacs; accepts emacs29–31 instead of XEmacs only |
| devel/haskell-mode | 1.44 | 17.5 | from GitHub; one patch for a defcustom Emacs 30 rejects; needs pkgsrc texinfo (TEXINFO_REQD) |
| devel/js2-mode | 20080406 | 20231224 | from GitHub (googlecode is gone) |
| devel/php-mode | 1.13.1 | 1.28.0 | from GitHub (sourceforge is stale); installs all of lisp/ |
| devel/rainbow-delimiters-el | 1.3.5 | 2.1.5 | |
| devel/reformatter-el | – | 0.7 | **new**, needed by zig-mode |
| devel/ruby-rd-mode | 0.6.38 | 0.6.39 | built through the package on emacs30 once lang/ruby34 was fixed (below); rd-mode loads |
| devel/sml-mode | 3.9.5 (2000) | 6.12 | from GNU ELPA, one file now; needs Emacs 24.3. With Debian's fixes: the texinfo's direntry line, braces in @center and @setchapternewpage, which newer makeinfo rejects, and sml-indent-level marked safe as a file-local variable |
| devel/zig-mode | 2022-01-05 snapshot | 2025-11-21 snapshot | depends on reformatter-el |
| editors/matlab-mode | 2.3.1 | 8.2.1 | upstream moved to mathworks/Emacs-MATLAB-Mode; many more files |
| graphics/graphviz-dot-mode | 0.3.7 | 0.5.0 | from GitHub. 0.5.0 asks for Emacs 25; the package also accepts emacs20, where devel/cl-lib-el and the new devel/elisp-compat supply cl-lib, subr-x, setq-local, prog-mode, syntax-ppss and syntax-propertize, and files/graphviz-dot-e20.el the two things particular to this mode (the compile.el error table, and the comment styles: Emacs 20 makes a single-character comment starter style a whatever its flags say, so `//`/`#` and `/* */` swap styles there). Built for emacs20 and emacs30; on both, the same buffer indents the same and fontifies `//`, `/* */` and `#` comments the same |
| inputmethod/skk | 17.1 | 17.2 | patch-ccc.el is upstream now; tar-util.el is gone |
| mail/wl-snapshot | 2023-08-18 snapshot | 2025-10-29 snapshot | needs www/emacs-w3m-snapshot to accept emacs30 |
| math/ess | 13.09.1 | 25.01.0 | from GitHub; julia-mode.el and julia-mode-latexsubs.el fetched as distfiles (lisp/Makefile would download them at build time); etc/ under the lisp directory where ESS looks for it |
| misc/bbdb3 | 3.2.2a (2022 git snapshot, autoconf) | 3.2.2.4 (GNU ELPA) | the ELPA tarball is the release (git's head is the same 3.2.2d plus one notmuch guard), and git.savannah.nongnu.org answers 400/502 to snapshot fetches too often to keep as MASTER_SITES. ELPA ships the flat tree without configure, so the package byte-compiles the same files upstream's make does (the VM, mu4e, notmuch and WL glue stays source) and generates bbdb-loaddefs.el with loaddefs-generate-batch, prefixed with upstream's load-path prelude; bbdb-site.el's @PACKAGE_VERSION@/@pkgdatadir@ are filled in, and tex/bbdb.sty goes to share/bbdb where bbdb-site looks. Exercised on emacs30: bbdb-initialize, a record created and saved, bbdb-version 3.2.2.4, bbdb.sty found through bbdb-tex-path |
| misc/mic-paren | 3.13 (emacsattic git) | 3.15 | the last release, from gnuvola.org, which now sits behind a cookie check fetch cannot pass; Gentoo's copy (same SHA512 as their Manifest) is the MASTER_SITE, a single .el.xz, so do-extract runs xz. 3.15 dropped (require 'cl) but calls cl-oddp/cl-minusp, so paren-activate died with a void cl-oddp — Gentoo's (require 'cl-lib) patch is taken; with it paren-activate and a highlight in an emacs-lisp buffer work on emacs30 |
| misc/elscreen | 1.4.6 | same | stays at 1.4.6, the version that serves emacs20 (the only flavour it accepts). With devel/apel accepting emacs20 again it builds, but elscreen-display-tab's :set function calls booleanp at load and nothing had loaded poe, so elscreen.el requires poe; poe.el gains booleanp and an add-to-list with APPEND (Emacs 22) for it. elscreen-start and elscreen-create work on emacs20 |
| misc/elscreen-current | – | 20180321 (knu/elscreen) | **new** (`new/elscreen-current/`): the maintained fork, for Emacs 24 and later, under the name the tree's own comment points at (wip has it as elscreen-git). Conflicts with misc/elscreen. elscreen-start/elscreen-create work on emacs30 |
| misc/emacs-neotree | 0.5.2 snapshot | 0.6.0 | |
| print/auctex | 13.3 | 14.2.0 | from GNU ELPA, which is the only place 14.x is released; installed whole under `${EMACS_LISPPREFIX}/auctex` as the ELPA package expects. Built with `DEPENDS=` here, since the texlive chain does not fit this box; the dependency line is unchanged |
| textproc/emacs-dict-client | 1.8.2 | 1.11 | from GitHub (myrkr/dictionary-el). Emacs 28+ bundles a newer dictionary.el; this package shadows it |
| textproc/flycheck-mode | 33.0 | 39.0 | needs Emacs 28.1; flycheck-ert.el is no longer shipped; dash no longer used |
| textproc/markdown-mode | 2.4 | 2.8 | |
| textproc/psgml-mode | 1.3.2 (2005 alpha) | 1.4.0 | the last upstream tarball, which SourceForge never listed; fetched from Debian's pool, where it is the .orig. Builds without the four Emacs 24 patches, which are upstream now |
| textproc/po-mode | 2.2 (gettext 0.18.1.1) | 2.32 (gettext 1.0) | gettext moved the elisp to gettext-tools/emacs |
| inputmethod/tamago-tsunagi | 5.0.7.1 | same | accepts emacs20 again instead of being marked incompatible. 5.0.7.1 is Tamago 4 ported to the Mule of Emacs 23+; its egg-com.el defines the fixed-euc coding systems with define-charset keywords Emacs 20 has no idea of, so on Emacs 20 Tamago 4.0.6's own egg-com.el is used (files/egg-com-e20.el) and devel/elisp-compat supplies obarray-make and set-process-query-on-exit-flag; its/aynu (JIS X 0213) is left out there. Built for emacs20 and emacs30. On emacs20 and on emacs30 the installed package starts anthy-agent, sends にほんごをかく through egg-convert-region and gets 日本語を 書く back (the earlier "Invalid code(s)" on emacs30 was the test's own doing: (string 164 203 …) is Latin-1 text on Emacs 23+, not EUC bytes) |
| www/emacs-w3m | 1.4.5 + 2023 snapshot | 1.4.632 (2026-08-27 snapshot) | |
| www/emacs-w3m-snapshot | 2021-01-06 (Debian) | 2022-12-06 (Debian) | and accepts emacs30/31; the 2021 snapshot's configure refuses Emacs 30 |
| devel/sml-mode | 3.9.5 (2000) | 6.12 | accepts emacs29-31 only: XEmacs stops first on `require` with three arguments (APEL's poe has it), then on `?λ` in the prettify table, then on pcase's backquote patterns; Emacs 20's reader gives up before any of that |
| textproc/markdown-mode | 2.4 | 2.8 | accepts emacs29-31 only: 2.8 requires color.el, which arrived in Emacs 24 and XEmacs does not have |
| misc/emacs-neotree | 0.5.2 snapshot | 0.6.0 | accepts emacs29-31 only: pcase backquote patterns, which the XEmacs reader takes for the old backquote and rejects.  WRKSRC is spelled out because GitHub's default derives it from PKGNAME, which carries EMACS_PKGNAME_PREFIX and so names a directory that does not exist under XEmacs |

## lang/ruby34 — in the tree now

ruby34 3.4.10 would not link with the `ruby-rjit` option on a system
where dtrace rewrites objects (NetBSD): rjit_c.c has a DTrace hook but
rjit_c.o was missing from DTRACE_DEPENDENT_OBJS.  Sent as pkg/60763 on
2026-09-22 and committed by taca@ the same day
(patch-template_Makefile.in rev 1.2), so the diff that was here is gone.
howm, mew, migemo-elisp and ruby-rd-mode depend on ruby34 and build
through the package again.

## Checked and left alone (2026-09-22)

The rest of the elisp packages, compared with their upstreams on the
same day.  "last" means the upstream site is gone or that version is
the last it ever published; "current" means it matches what upstream
ships today.

| package | pkgsrc | upstream | |
|---|---|---|---|
| cad/dinotrace-mode | 9.4f | v9.4f (2023-04) | current. Accepts only emacs26/emacs29, and emacs26 is not in the tree; builds and loads on emacs30 with EMACS_VERSIONS_ACCEPTED overridden |
| chat/emacs-jabber | 0.8.92 | 0.14.0 (git.thanosapollo.org; Debian ships it) | the tree's package is the emacs20/XEmacs one; 0.14 wants Emacs 27 and would be a second package, as elscreen-current is |
| chat/irchat-pj | 2.4.24.22 | his.luky.org is gone | last |
| chat/riece | 9.0.0 | 9.0.0 | current |
| chat/zenicb | 19981202 | LOCAL | last; accepts emacs31 only since 2026-09-08 |
| chat/zenirc | 2.112 | splode.com lists no tarballs | last |
| devel/cobol-mode | 20150505 | emacswiki | last |
| devel/doxymacs | 1.8.0 | 1.8.0 | current |
| devel/lua-mode | 20210802 | v20210802 (git goes on to 2025-03 without a tag) | current tag |
| devel/mell | 1.0.0 | taiyaki.org is gone | last; fixed for Emacs 29+ in emacs-patches |
| devel/semantic, editors/speedbar, lang/eieio | 1.4.4 / 0.14beta4 / 0.17 | last standalone releases; CEDET is in Emacs since 23 | last, for emacs20/XEmacs |
| editors/gnuserv | 3.12.8 | 3.12.8 | last |
| editors/javascript-mode | 2.2.1 | brgeight.se is gone | last |
| editors/manued | 20191018 | git stops at 2019-10-17 | current |
| graphics/artist | 1.2.6 | 1.2.6 | current (Emacs bundles it too) |
| inputmethod/tc | 2.3.1 | 2.3.1 | current |
| mail/etach | 1.2.9 | rulnick.com 404 | last |
| mail/mailcrypt | 3.5.9 | 3.5.9 | current |
| mail/mew | 6.11 | v6.11 | current |
| mail/rmail-mime | 1.13.0 | m17n.org ftp is gone | last |
| mail/vm | 8.2.0b | 8.2.0b | current |
| math/texdrive | 20081126 | one file, never updated | last; loads and byte-compiles clean on emacs30 |
| misc/color-theme | 6.6.0 | 6.6.0 | current (emacs-patches makes it work on 26–30) |
| misc/emacs-wiki | 2.72 | mwolson.org is gone (muse succeeded it) | last |
| misc/emacspeak | 60.0 | 60.0 | current |
| misc/howm | 1.5.6 | 1.5.6 | current |
| misc/lookup | 1.4.1 | 1.4.1 (openlab.jp) | current; 2.x is a different line |
| net/twittering-mode | 3.0.0 | v3.0.0 (2018) | current |
| textproc/dictem | 1.0.4 | 1.0.4 | current |
| textproc/flyspell | 1.7m | inria 404 (Emacs bundles it) | last |
| textproc/ispell-emacs | 3.6 | kdstevens.com ftp | last |
| textproc/xslide | 0.2.2 | 0.2.2 | current |

NVD was searched by name for all 99 packages that read modules.mk.
Everything that came back and is about one of them is already fixed
in the version the tree has: CVE-2008-4952 (emacs-jabber 0.7.91's
/tmp log; 0.8.92 has no such file), CVE-2004-0422 (flim before
1.14.3), CVE-2001-0191 (gnuserv before 3.12), CVE-2008-4191
(emacspeak 26/28's extract-table.pl; 60.0's writes to stdout),
CVE-2007-2833 (an Emacs 21 image bug reported through vm).  The
emacs20 and xemacs entries are in emacs-patches.
