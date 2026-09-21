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
| cad/verilog-mode | 3.60 (2005, MASTER_SITE_LOCAL) | 2026.08.31 | veripool ships `verilog-mode.el` without a version in its name; fetched under DIST_SUBDIR |
| devel/apel | 2020-11-07 snapshot | 2025-05-31 snapshot | and serves Emacs 20 and XEmacs again: the compatibility layer upstream removed in 2020 comes back as 17 patches and 11 files under files/, keeping the fixes made since (pccl-20 uses define-coding-system where it exists, so Emacs 30 still builds it). Built for emacs20 20.7 and emacs30 30.2; misc/lookup, which accepts only emacs20 and XEmacs and needs apel, builds on emacs20 again. poe.el also gains dolist, dotimes, mapc, declare-function and the three-argument make-obsolete for Emacs 20, which FLIM and SEMI use |
| devel/flim | 1.14.9 + 2023 branch | same | builds on emacs20 again: ?\s (Emacs 22 syntax) spelled ?\  in the eight files that use it, folded into the existing patches; hmac-def.el, which the package deletes as "included in Emacs", is kept on Emacs before 22; cl-lib comes from the new devel/cl-lib-el below on Emacs before 24. Exercised on emacs20: eword-decode-string on an ISO-2022-JP encoded-word |
| devel/semi | 1.14.6 | same | the cl-lib buildlink for Emacs before 24; mime-parse-buffer on a multipart message works on emacs20 |
| devel/emacs20-compat | – | 20260922 | **new** (`new/emacs20-compat/`): one file, e20-compat.el, defining only when missing what elisp written for Emacs 21–26 uses on Emacs 20: hash tables (over alists), replace-regexp-in-string, propertize, nbutlast, subr-x's strings, setq-local, with-eval-after-load, prog-mode, syntax-ppss, syntax-propertize (rules become a function run from post-command-hook and, on Emacs 20, also font-lock-syntactic-keywords), and a regexp translator for shy groups, `\\{n,m\\}`, `[:alpha:]` and `\\_<` that remaps the match data afterwards. nxml-mode and graphviz-dot-mode use it |
| devel/cl-lib-el | – | 0.6.1 | **new** (`new/cl-lib-el/`): GNU ELPA's forward-compatibility cl-lib, for Emacs before 24.3; accepts emacs20. The distfile is a single lzip-compressed .el, which pkgsrc's extract does not handle, so do-extract calls lzip |
| devel/cflow-mode | 1.7 | 1.8 | |
| devel/dash-el | 2.19.1 | 2.20.0 | |
| devel/ecb | 2.50 | 2.52 | now builds and loads with the CEDET bundled in Emacs; accepts emacs29–31 instead of XEmacs only |
| devel/haskell-mode | 1.44 | 17.5 | from GitHub; one patch for a defcustom Emacs 30 rejects; needs pkgsrc texinfo (TEXINFO_REQD) |
| devel/js2-mode | 20080406 | 20231224 | from GitHub (googlecode is gone) |
| devel/php-mode | 1.13.1 | 1.28.0 | from GitHub (sourceforge is stale); installs all of lisp/ |
| devel/rainbow-delimiters-el | 1.3.5 | 2.1.5 | |
| devel/reformatter-el | – | 0.7 | **new**, needed by zig-mode |
| devel/ruby-rd-mode | 0.6.38 | 0.6.39 | the one not built through the package: it needs ruby34, whose build here kept pulling rust. The gem was fetched (distinfo is real) and its rd-mode.el byte-compiled and loaded by hand under 30.2 |
| devel/sml-mode | 3.9.5 (2000) | 6.12 | from GNU ELPA, one file now; needs Emacs 24.3. With Debian's fixes: the texinfo's direntry line, braces in @center and @setchapternewpage, which newer makeinfo rejects, and sml-indent-level marked safe as a file-local variable |
| devel/zig-mode | 2022-01-05 snapshot | 2025-11-21 snapshot | depends on reformatter-el |
| editors/matlab-mode | 2.3.1 | 8.2.1 | upstream moved to mathworks/Emacs-MATLAB-Mode; many more files |
| graphics/graphviz-dot-mode | 0.3.7 | 0.5.0 | from GitHub. 0.5.0 asks for Emacs 25; the package also accepts emacs20, where devel/cl-lib-el and the new devel/emacs20-compat supply cl-lib, subr-x, setq-local, prog-mode, syntax-ppss and syntax-propertize, and files/graphviz-dot-e20.el the two things particular to this mode (the compile.el error table, and the comment styles: Emacs 20 makes a single-character comment starter style a whatever its flags say, so `//`/`#` and `/* */` swap styles there). Built for emacs20 and emacs30; on both, the same buffer indents the same and fontifies `//`, `/* */` and `#` comments the same |
| inputmethod/skk | 17.1 | 17.2 | patch-ccc.el is upstream now; tar-util.el is gone |
| mail/wl-snapshot | 2023-08-18 snapshot | 2025-10-29 snapshot | needs www/emacs-w3m-snapshot to accept emacs30 |
| math/ess | 13.09.1 | 25.01.0 | from GitHub; julia-mode.el and julia-mode-latexsubs.el fetched as distfiles (lisp/Makefile would download them at build time); etc/ under the lisp directory where ESS looks for it |
| misc/elscreen | 1.4.6 | 20180321 (knu/elscreen) | the maintained fork; no longer needs APEL, so it builds again (1.4.6 needed emacs20 and an apel that no longer accepts it) |
| misc/emacs-neotree | 0.5.2 snapshot | 0.6.0 | |
| print/auctex | 13.3 | 14.2.0 | from GNU ELPA, which is the only place 14.x is released; installed whole under `${EMACS_LISPPREFIX}/auctex` as the ELPA package expects. Built with `DEPENDS=` here, since the texlive chain does not fit this box; the dependency line is unchanged |
| textproc/emacs-dict-client | 1.8.2 | 1.11 | from GitHub (myrkr/dictionary-el). Emacs 28+ bundles a newer dictionary.el; this package shadows it |
| textproc/flycheck-mode | 33.0 | 39.0 | needs Emacs 28.1; flycheck-ert.el is no longer shipped; dash no longer used |
| textproc/markdown-mode | 2.4 | 2.8 | |
| textproc/psgml-mode | 1.3.2 (2005 alpha) | 1.4.0 | the last upstream tarball, which SourceForge never listed; fetched from Debian's pool, where it is the .orig. Builds without the four Emacs 24 patches, which are upstream now |
| textproc/po-mode | 2.2 (gettext 0.18.1.1) | 2.32 (gettext 1.0) | gettext moved the elisp to gettext-tools/emacs |
| www/emacs-w3m | 1.4.5 + 2023 snapshot | 1.4.632 (2026-08-27 snapshot) | |
| www/emacs-w3m-snapshot | 2021-01-06 (Debian) | 2022-12-06 (Debian) | and accepts emacs30/31; the 2021 snapshot's configure refuses Emacs 30 |
