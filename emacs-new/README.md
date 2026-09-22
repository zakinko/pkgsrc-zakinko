# New Emacs packages, generated from Gentoo's app-emacs set

Gentoo's app-emacs category (444 packages on 2026-09-21) was read against
pkgsrc; the 412 that pkgsrc does not have were turned into packages by a
generator (bin/ in NetBSD-i386 has it as gen.py) that reads each ebuild for
its source, version, licence, dependencies and the Emacs versions it
supports, and writes a pkgsrc package that byte-compiles with
`${EMACS_BIN} -batch -f batch-byte-compile` and installs into
`${EMACS_LISPPREFIX}/<name>`.  Each package here was then built with
`bmake package-install` against emacs30-nox11 30.2 on NetBSD 11.0/amd64,
and its PLIST regenerated from what was installed.

`patch -p0` is not the form here: these are whole package directories.
Copy `<category>/<pkg>` into a pkgsrc tree and add the SUBDIR line.

What every package has in common:

- `EMACS_VERSIONS_ACCEPTED= emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox`
  (Gentoo's set requires Emacs 24 or later; 29 is the oldest pkgsrc has
  besides 20)
- dependencies on other Emacs packages come from the ebuild's RDEPEND and
  point at the pkgsrc package (existing ones where pkgsrc has them, these
  otherwise); the same directories go on the byte-compiler's load-path
- files named `*-test.el`, `test-*.el` and the like, and `.dir-locals.el`,
  are removed before compiling: they are test suites, and a `.dir-locals.el`
  that sets `require-final-newline` to a string aborts batch compilation
- a file upstream marks `no-byte-compile` is installed as source
- data next to the lisp (icons, banners, emoji tables, directive lists)
  is installed next to it, where `load-file-name` relative code expects it

## Built and installed (408)

| package | version | source | notes |
|---|---|---|---|

| devel/a-el | 1.0.0 | GitHub |  |
| devel/a68-mode | 1.3.20260615 | sr.ht |  |
| editors/ace-window-el | 0.10.0 | GitHub | needs avy |
| devel/acp-el | 0.15.1 | GitHub |  |
| devel/actionscript-mode | 7.2.2.20180527 | GitHub |  |
| devel/adaptive-wrap-el | 0.9 | GNU ELPA |  |
| devel/agent-shell-el | 0.74.3 | GitHub | needs acp, shell-maker |
| devel/agitjo-el | 2.0.0 | Codeberg | needs magit, markdown-mode, transient |
| devel/all-the-icons-el | 5.0.0.20230316 | GitHub | data/*.el likewise |
| devel/all-the-icons-dired-el | 2.0 | GitHub | needs all-the-icons |
| devel/all-the-icons-ibuffer-el | 1.3.0 | GitHub | needs all-the-icons |
| devel/all-the-icons-ivy-rich-el | 1.9.0 | GitHub | needs all-the-icons, ivy-rich |
| devel/amx-el | 3.4 | GitHub | needs ivy, s |
| devel/analog-el | 1.9.99 | Gentoo mirror |  |
| devel/anaphora-el | 1.0.4 | GitHub |  |
| devel/ansi-el | 0.4.1.20211104 | GitHub |  |
| devel/apache-mode | 2.2.0 | GitHub |  |
| devel/apheleia-el | 4.6.0 | GitHub |  |
| devel/assess-el | 0.7 | GitHub | needs m-buffer |
| devel/async-el | 1.9.9 | GitHub |  |
| editors/atomic-chrome-el | 2.0.0 | GitHub | save binding C-c C-s, upstream commit ae2a6158 via Debian; exercised: C-c C-s is atomic-chrome-send-buffer-text; needs websocket |
| editors/auto-complete-el | 1.5.1 | GitHub | needs popup |
| devel/autoconf-mode | 2.72 | url | autoconf-mode.el and autotest-mode.el from the autoconf 2.72 tarball (devel/autoconf does not install them) |
| devel/autocrypt-el | 0.4.2pre20260126 | Codeberg |  |
| editors/autothemer-el | 0.2.18 | GitHub | needs dash |
| editors/avy-el | 0.5.0 | GitHub |  |
| devel/avy-embark-collect-el | 1.2 | GitHub | needs avy, embark |
| devel/biblio-el | 0.3 | GitHub | needs dash |
| devel/binclock-el | 1.12 | GitHub |  |
| devel/bind-chord-el | 2.4.4 | GitHub | only bind-chord.el from the use-package tarball (use-package is in Emacs 29); needs key-chord |
| devel/blogmax-el | 20170321 | dev.gentoo.org |  |
| editors/bm-el | 202506 | GitHub |  |
| devel/bnf-mode | 0.4.5 | GitHub |  |
| devel/bongo-el | 1.1 | GitHub | mpv's --input-ipc-server=FILE as one argument (Debian); exercised: bongo-compose-remote-option gives ("--input-ipc-server=/tmp/sock"); needs volume |
| devel/boogie-friends-el | 0.1.20220922 | GitHub | needs company-mode, dash, flycheck, yasnippet |
| editors/boxquote-el | 2.4.1 | GitHub |  |
| editors/browse-kill-ring-el | 2.1.0 | GitHub |  |
| devel/bubblet-el | 0.74 | Gentoo mirror |  |
| devel/bui-el | 1.3 | GitHub |  |
| devel/burly-el | 0.3 | GitHub |  |
| devel/buttercup-el | 1.40 | GitHub |  |
| editors/calfw-el | 2.0 | GitHub |  |
| devel/cape-el | 2.9 | GitHub | needs compat |
| devel/cask-mode | 0.1 | GitHub |  |
| devel/cdlatex-el | 4.18.5 | NonGNU ELPA | needs auctex |
| devel/centaur-tabs-el | 3.2 | GitHub | needs powerline |
| devel/cfrs-el | 1.7.0 | GitHub | needs dash, posframe, s |
| devel/chess-el | 2.0.5 | dev.gentoo.org |  |
| devel/cider-el | 2.0.1 | GitHub | the test-file removal is turned off: cider-test.el is the test-runner integration; needs clojure-mode, compat, parseedn, queue, sesman, spinner, transient |
| devel/circe-el | 2.14 | GitHub |  |
| devel/citar-el | 1.4.0 | GitHub | needs citeproc-el, parsebib |
| devel/citeproc-el-el | 0.9.4 | GitHub | needs compat, dash, f, parsebib, queue, s, string-inflection |
| devel/citre-el | 0.4.2 | GitHub |  |
| devel/clatter-el | 0.8.1 | GitHub |  |
| devel/cldoc-el | 1.16 | dev.gentoo.org | needs slime |
| devel/clojure-mode | 5.23.0 | GitHub |  |
| devel/closql-el | 2.4.1 | GitHub | needs compat, cond-let, emacsql, llama |
| devel/cmake-font-lock-el | 0.1.13 | GitHub | needs cmake-mode |
| devel/color-browser-el | 0.3 | Gentoo mirror | needs color-theme |
| devel/color-moccur-el | 2.73 | dev.gentoo.org |  |
| devel/commander-el | 0.7.0 | GitHub | needs dash, f, s |
| devel/commenter-el | 0.5.2 | GitHub |  |
| devel/company-coq-el | 1.0.1.20220314 | GitHub | needs company-math, company-mode, dash, proofgeneral, yasnippet |
| devel/company-math-el | 1.5.1 | GitHub | needs company-mode, math-symbol-lists |
| devel/company-mode | 1.1.0 | GitHub | needs posframe |
| devel/company-quickhelp-el | 2.3.0 | GitHub | needs company-mode, pos-tip |
| devel/compat-el | 31.0.0.2 | GitHub |  |
| devel/cond-let-el | 1.1.4 | GitHub |  |
| editors/consult-el | 3.8 | GitHub | needs compat |
| devel/consult-flycheck-el | 1.2 | GitHub | needs consult, flycheck |
| editors/corfu-el | 2.15 | GitHub | needs compat |
| devel/counsel-el | 0.15.1 | GitHub | needs ivy, swiper |
| devel/crontab-mode | 1.20 | Gentoo mirror |  |
| devel/crux-el | 0.5.0 | GitHub |  |
| devel/css-sort-buffer-el | 0.2 | dev.gentoo.org |  |
| devel/csv-mode | 1.27 | GNU ELPA |  |
| devel/ctable-el | 0.1.3 | GitHub |  |
| devel/cycle-buffer-el | 2.16 | url | the copy Gentoo's ebuild points at (github.com/gavv/distfiles); upstream is gone |
| devel/d-mode | 2.0.12 | GitHub |  |
| editors/dape-el | 0.27.1 | GitHub |  |
| editors/dashboard-el | 1.8.0 | GitHub | banners/ installed next to dashboard.el |
| devel/deferred-el | 0.5.1 | GitHub | deferred:process-shell passes one command string to start-process-shell-command (Debian); exercised: (deferred:process-shell "echo" "hello" "world") returns "hello world" |
| devel/deft-el | 08.20210707 | GitHub |  |
| devel/demap-el | 1.4.0 | GitLab |  |
| devel/denote-el | 4.2.3 | GitHub |  |
| devel/desktop+-el | 0.2 | GitHub | needs dash, f |
| devel/desktop-entry-mode | 0.28 | url | misc/desktop-entry-mode.el from desktop-file-utils 0.28 |
| editors/develock-el | 0.47 | jpl.org |  |
| devel/devil-el | 0.6.0 | GitHub |  |
| devel/df-mode | 20050509 | Gentoo mirror |  |
| editors/diff-hl-el | 1.10.0 | GitHub |  |
| editors/diminish-el | 0.46pre20220128 | GitHub |  |
| devel/dircolors-el | 1.0 | Gentoo mirror |  |
| devel/dired-hacks-el | 0.0.1.20230621 | GitHub | dired-images.el looks for ImageMagick's mogrify at load and stays source; needs dash, eimp, f, s |
| devel/dired-sort-menu-el | 1.26 | Gentoo mirror |  |
| devel/distel-el | 4.1.1 | GitHub | needs erlang-mode |
| devel/docker-el | 2.5.0 | GitHub | needs dash, emacs-aio, s, tablist, transient |
| devel/dockerfile-mode | 1.9 | GitHub |  |
| devel/doom-modeline-el | 4.2.1 | GitHub | needs compat, nerd-icons, shrink-path |
| editors/doom-themes | 2.3.0.20231208 | GitHub |  |
| devel/dropdown-list-el | 20120329 | dev.gentoo.org | selection face inherits dropdown-list-face, not the group (Gentoo) |
| devel/dts-mode | 1.0 | GNU ELPA |  |
| devel/dune-format-el | 0.1 | GitHub | needs reformatter |
| devel/dwarf-mode | 2.40 | url | binutils/dwarf-mode.el from binutils 2.40 |
| devel/earthfile-mode | 0.1.0.20230810 | GitHub |  |
| devel/ebib-el | 2.51.1 | GitHub | needs compat, parsebib |
| devel/ecukes-el | 0.6.18 | GitHub | needs ansi, commander, dash, espuds, f, s |
| devel/edit-indirect-el | 0.1.13 | GitHub |  |
| devel/edit-list-el | 0.3 | dev.gentoo.org |  |
| devel/edit-server-el | 1.16 | GitHub |  |
| editors/editorconfig-emacs-el | 0.11.0 | GitHub | the same 0.11.0 Emacs 30 bundles; kept for emacs29 |
| devel/ef-themes | 2.2.1 | GitHub | needs modus-themes |
| devel/eimp-el | 1.4.0 | GitHub |  |
| devel/el-mock-el | 1.25.1 | GitHub |  |
| devel/eldev-el | 1.11.3 | GitHub |  |
| devel/eldoc-box-el | 1.14.1 | GitHub |  |
| devel/elfeed-el | 4.2.0 | GitHub | needs compat |
| devel/elfeed-protocol-el | 1.0.0 | GitHub | needs elfeed |
| devel/elixir-mode | 2.5.0 | GitHub |  |
| devel/elm-mode | 0.22.0.20250401 | GitHub | needs f, reformatter, s |
| devel/elpa-mirror-el | 2.3.0 | GitHub |  |
| devel/elpher-el | 3.7.0 | NonGNU ELPA |  |
| devel/elpy-el | 1.35.0.20260415 | GitHub | needs company-mode, highlight-indentation, pyvenv, s, yasnippet |
| devel/emacs-aio-el | 1.1 | GitHub | aio-contrib.el needs elfeed and stays source |
| devel/emacs-ansilove-el | 2.0.0 | GitLab |  |
| editors/emacs-bazel-mode | 0.20230919 | GitHub |  |
| devel/emacs-crystal-mode | 0.2.0.20260111 | GitHub | needs flycheck |
| editors/emacs-eat-el | 0.9.4 | Codeberg | needs compat |
| devel/emacs-el-fetch-el | 3.3.0 | GitLab |  |
| devel/emacs-ipython-notebook-el | 0.17.1pre20251212 | GitHub | needs anaphora, dash, deferred, polymode, request, websocket, with-editor |
| devel/emacs-secil-mode | 1.2 | url | salsa.debian.org tarball |
| devel/emacs-websearch-el | 2.1.0 | GitLab |  |
| devel/emacs-wget-el | 0.5.0 | Gentoo mirror | upstream (infoseek) is gone; Gentoo's distfiles mirror; lpath.el (a build helper) not installed |
| devel/emacs-wttrin-el | 0.3.2 | GitHub | needs xterm-color |
| devel/emacsql-el | 4.4.1 | GitHub |  |
| devel/embark-el | 1.2 | GitHub | needs compat |
| devel/embark-consult-el | 1.2 | GitHub | needs consult, embark |
| devel/emhacks-el | 20070920 | dev.gentoo.org | recentf.el, ruler-mode.el and tree-widget.el (2007 copies of what Emacs ships, which would shadow it from site-lisp) and jsee.el (needs JDE) are removed |
| devel/emojify-el | 1.2.20210309 | GitHub | data/ (emoji tables) installed; emojify-set-emoji-data loads 5489 emoji; needs ht |
| devel/engrave-faces-el | 0.3.1 | GitHub |  |
| devel/epc-el | 0.1.1 | GitHub | needs ctable, deferred |
| devel/epl-el | 0.9 | GitHub |  |
| devel/erefactor-el | 0.7.2 | GitHub |  |
| devel/erlang-mode | 28.3 | GitHub |  |
| devel/erobot-el | 2.1.0 | Gentoo mirror | interactive spec no longer starts with two ignored arguments (Gentoo) |
| devel/ert-async-el | 0.1.2.20200105 | GitHub |  |
| devel/ert-runner-el | 0.8.0 | GitHub | needs ansi, commander, dash, f, shut-up |
| devel/espuds-el | 0.3.3.20171111 | GitHub | needs dash, f, s |
| editors/esup-el | 0.7.1.20220203 | GitHub | needs s |
| editors/evil-el | 1.14.2 | GitHub | needs undo-tree |
| editors/exec-path-from-shell-el | 2.3 | GitHub |  |
| editors/expand-region-el | 1.0.0 | GitHub |  |
| devel/exwm-el | 0.35 | GitHub | needs compat, xelb |
| devel/f-el | 0.21.0 | GitHub | needs dash, s |
| devel/fedi-el | 0.4 | Codeberg | needs markdown-mode |
| devel/fennel-mode | 0.9.2 | sr.ht |  |
| devel/fff-el | 20050517 | Gentoo mirror |  |
| devel/filladapt-el | 2.12.2 | dev.gentoo.org |  |
| devel/flashcard-el | 2.3.3 | Gentoo mirror |  |
| devel/flycheck-clang-tidy-el | 0.3.0.20201116 | GitHub | needs flycheck |
| devel/flycheck-guile-el | 0.5 | GitHub | needs flycheck, geiser-guile |
| devel/flycheck-inline-el | 0pre20200808 | GitHub | needs flycheck |
| devel/flycheck-nimsuggest-el | 0.8.1.20171027 | GitHub | needs flycheck |
| devel/flycheck-package-el | 0.14 | GitHub | needs flycheck, package-lint |
| devel/folding-el | 2019.0524.1621 | GitHub |  |
| devel/forge-el | 0.6.9 | GitHub | needs closql, compat, cond-let, emacsql, ghub, llama, magit, markdown-mode, transient, yaml |
| devel/fsharp-mode | 2.0.20230622 | GitHub |  |
| devel/fsm-el | 0.2.1 | GNU ELPA |  |
| devel/gap-mode | 2.2.2 | GitLab | needs company-mode, flycheck |
| devel/geiser-el | 0.33.2 | NonGNU ELPA |  |
| devel/geiser-chez-el | 0.18 | GitLab | needs geiser |
| devel/geiser-chicken-el | 0.17 | GitLab | needs geiser |
| devel/geiser-gambit-el | 0.18.1 | GitLab | needs geiser |
| editors/geiser-guile-el | 0.28.5 | NonGNU ELPA | src/ (the scheme side) installed next to the lisp; needs geiser, transient |
| devel/geiser-mit-el | 0.15 | GitLab | needs geiser |
| devel/ghub-el | 5.3.2 | GitHub | needs compat, cond-let, llama, treepy |
| editors/git-modes | 1.5.0 | GitHub | needs compat |
| devel/git-timemachine-el | 4.13 | Codeberg |  |
| devel/gnuplot-mode | 0.12 | GitHub | needs compat |
| devel/go-mode | 1.6.0 | NonGNU ELPA |  |
| devel/god-mode | 2.19.0 | GitHub |  |
| devel/google-c-style-el | 20140929 | dev.gentoo.org |  |
| editors/gptel-el | 0.9.9.6 | GitHub | needs compat, transient |
| devel/graphql-el | 0.1.2 | GitHub |  |
| devel/groovy-emacs-modes | 2.1 | GitHub | needs dash, s |
| devel/gruvbox-theme-el | 1.30.3 | GitHub | needs autothemer |
| devel/h4x0r-el | 0.13 | Gentoo mirror |  |
| devel/haxe-mode | 0.3.3 | GitHub |  |
| devel/helm-el | 4.0.7 | GitHub | needs async, wfnames |
| devel/helm-system-packages-el | 1.10.2 | GitHub | needs helm |
| devel/hexrgb-el | 0.1019 | dev.gentoo.org | dev.gentoo.org copy; upstream (emacswiki) is not a fetchable site |
| editors/highlight-indentation-el | 0.7.0.20210221 | GitHub |  |
| devel/highline-el | 7.2.2 | dev.gentoo.org |  |
| editors/hl-todo-el | 3.9.3 | GitHub | needs compat |
| devel/ht-el | 2.3 | GitHub | needs dash |
| devel/htmlize-el | 1.59 | GitHub |  |
| devel/httpd-el | 1.1 | Gentoo mirror |  |
| editors/hydra-el | 0.15.0 | GitHub | needs lv |
| devel/icicles-el | 2018.10.15.23738 | GitHub | Gentoo's make-obsolete WHEN patch (icicles-fn.el fails to load on 29+ without it); hexrgb added as a dependency, icicles-cmd1.el calls it at top level; needs hexrgb |
| devel/igrep-el | 2.113 | Gentoo mirror |  |
| devel/indent-bars-el | 0.9.2 | GitHub | needs compat |
| devel/inf-clojure-el | 3.4.0 | GitHub | needs clojure-mode |
| devel/inform-mode | 2.0.1 | GitHub |  |
| editors/initsplit-el | 1.8pre20160919 | GitHub |  |
| editors/ivy-el | 0.15.1 | GitHub |  |
| devel/ivy-rich-el | 0.1.7 | GitHub | needs ivy |
| devel/jam-mode | 0.3 | dev.gentoo.org |  |
| devel/jasmin-el | 1.2 | Gentoo mirror |  |
| devel/jinx-el | 2.10 | GitHub | needs compat |
| devel/joplin-mode | 202401009.2024 | GitHub | needs markdown-mode |
| devel/jq-mode | 0.5.0.20220610 | GitHub |  |
| devel/js-comint-el | 1.2.0 | GitHub |  |
| devel/julia-mode | 0.4.20211023 | GitHub |  |
| devel/julia-repl-el | 1.5.2 | GitHub | upstream marks it no-byte-compile; installed as source; needs julia-mode, s |
| devel/kaolin-themes | 1.7.7 | GitHub | needs autothemer |
| editors/key-chord-el | 0.8.2 | GitHub |  |
| devel/keywiz-el | 1.4 | Gentoo mirror |  |
| devel/kind-icon-el | 0.2.2 | GitHub | needs svg-lib |
| devel/lean-mode | 0.20230611 | GitHub | needs dash, f, flycheck, s |
| devel/ledger-mode | 4.0.0.20260727 | GitHub | git master 2026-07-27 rather than 4.0.0: the release's define-obsolete-function-alias lacks WHEN and does not load on Emacs 29+; ledger-test.el is a real module and is kept |
| devel/lice-el-el | 0.3 | GitHub |  |
| devel/llama-el | 1.0.5 | GitHub | needs compat |
| devel/load-relative-el | 1.3.2 | GitHub |  |
| devel/log4e-el | 0.4.1 | GitHub |  |
| devel/lv-el | 0.15.0 | GitHub |  |
| devel/m-buffer-el | 0.16.1 | GitHub |  |
| devel/macrostep-el | 0.9.5 | GitHub | needs compat |
| devel/macrostep-geiser-el | 0.2.0.20210717 | GitHub | needs geiser, macrostep |
| devel/magit-el | 4.7.0 | GitHub | needs compat, cond-let, llama, transient, with-editor |
| devel/magit-popup-el | 2.13.3 | GitHub | needs dash |
| devel/marginalia-el | 2.12 | GitHub | needs compat |
| editors/mastodon-el | 2.0.7 | Codeberg | Codeberg; lisp/ subdirectory; needs persist, request, tp |
| devel/math-symbol-lists-el | 1.3 | GitHub |  |
| devel/mediawiki-el | 2.3.1 | GitHub |  |
| devel/meson-mode | 0.4 | GitHub |  |
| devel/metamath-mode | 0.20221005 | GitHub |  |
| devel/mldonkey-el | 0.0.4b | Gentoo mirror | upstream (fu-berlin.de) is gone; Gentoo's distfiles mirror and its two patches (the second fixes a lambda list with two &optional, which the byte-compiler rejects) |
| devel/mmm-mode | 0.5.11 | GitHub |  |
| devel/moccur-edit-el | 2.16 | dev.gentoo.org | needs color-moccur |
| devel/mocker-el | 0.5.0 | GitHub |  |
| devel/modus-themes | 5.3.0 | GitHub |  |
| devel/mpg123-el-el | 1.65 | dev.gentoo.org |  |
| devel/mu-cite-el | 8.1.202011031127 | url | jpl.org snapshot 2020-11-03 (Gentoo's 8.1_p...); needs apel, flim, bbdb; needs apel, bbdb, flim |
| devel/multi-term-el | 1.4 | dev.gentoo.org |  |
| devel/multiple-cursors-el | 1.5.0 | GitHub |  |
| devel/nagios-mode | 0.4 | url | 0.4 from orlitzky.com |
| devel/navi2ch-el | 1.8.4 | url | SourceForge; the *.el compile without its configure |
| devel/nerd-icons-el | 0.1.0 | GitHub | data/*.el compiled and installed under data/, where nerd-icons-data requires them |
| devel/nginx-mode | 1.1.10 | GitHub |  |
| devel/nim-mode | 0.4.2.20231101 | GitHub | needs commenter, epc |
| devel/ninja-mode | 1.12.1 | GitHub | misc/ninja-mode.el from the ninja 1.12.1 tarball |
| devel/nix-mode | 1.5.0 | GitHub | needs company-mode, magit, mmm-mode, transient |
| editors/no-littering-el | 1.9.1 | GitHub | needs compat |
| devel/noflet-el | 0.0.15.20141102 | GitHub | needs dash |
| devel/oauth2-el | 0.19 | GNU ELPA |  |
| devel/ocaml-mode | 4.05.0 | GitHub |  |
| devel/orderless-el | 1.7 | GitHub | needs compat |
| devel/org-appear-el | 0.3.1 | GitHub |  |
| devel/org-contrib-el | 0.8 | sr.ht | needs org-mode |
| devel/org-mode | 9.8.10 | GNU ELPA | GNU ELPA org 9.8.10; shadows the org bundled with Emacs 30 (9.7), which is the point |
| devel/org-modern-el | 1.15 | GitHub | needs compat |
| devel/org-roam-el | 2.3.1 | GitHub | needs buttercup, dash, emacsql, magit |
| devel/org-static-blog-el | 1.7.0 | GitHub |  |
| devel/org-superstar-mode | 1.6.0 | GitHub |  |
| devel/osm-el | 2.5 | GitHub | needs compat |
| devel/outline-magic-el | 0.9 | Gentoo mirror |  |
| devel/package-build-el | 5.0.2 | GitHub | needs compat |
| devel/package-lint-el | 0.26 | GitHub | data/ installed; package-lint-buffer runs; needs compat |
| devel/pandoc-mode | 2.90.2 | GitHub | needs dash, hydra |
| editors/paredit-el | 26 | GitHub |  |
| devel/parsebib-el | 6.7 | GitHub |  |
| devel/parseclj-el | 1.1.1 | GitHub |  |
| devel/parseedn-el | 1.2.1 | GitHub | needs parseclj |
| editors/pdf-tools-el | 1.3.0 | GitHub | needs tablist |
| devel/persist-el | 0.8 | dev.gentoo.org |  |
| devel/pfuture-el | 1.10.3 | GitHub |  |
| devel/pinentry-el | 0.1.20250408 | GitHub |  |
| devel/pkg-info-el | 0.6 | GitHub | needs epl |
| devel/pkl-mode | 1.0.3 | GitHub |  |
| devel/planner-el | 3.42 | dev.gentoo.org | planner-gnats.el (needs a gnats.el nobody has) and planner-ledger.el (the pre-ledger-mode ledger.el) removed; needs bbdb, emacs-w3m, muse |
| devel/plz-el | 0.9.1 | GitHub |  |
| devel/poke-el | 3.2 | dev.gentoo.org | needs poke-mode |
| devel/poke-mode | 3.1 | GNU ELPA |  |
| devel/polymode-el | 0.2.2.20260505 | GitHub |  |
| editors/popup-el | 0.5.9 | GitHub |  |
| devel/popwin-el | 1.0.2 | GitHub |  |
| devel/pos-tip-el | 0.4.7 | GitHub |  |
| editors/posframe-el | 1.5.2 | GitHub |  |
| devel/pov-mode | 3.3 | GitHub |  |
| editors/powerline-el | 2.5.20221110 | GitHub |  |
| devel/powershell-el | 0.3pre20220805 | GitHub |  |
| devel/projectile-el | 3.4.0 | GitHub | needs compat |
| devel/proofgeneral-el | 4.5 | GitHub |  |
| devel/protbuf-el | 1.7 | Gentoo mirror |  |
| devel/puppet-mode | 0.4 | GitHub |  |
| editors/pyvenv-el | 1.21 | GitHub |  |
| devel/quack-el | 0.48 | dev.gentoo.org |  |
| devel/queue-el | 0.2 | GNU ELPA |  |
| devel/qwerty-el | 1.1 | Gentoo mirror |  |
| devel/racket-mode | 1.20260303 | GitHub |  |
| devel/rainbow-mode | 1.0.7 | dev.gentoo.org |  |
| devel/raku-mode | 0.2.1.20211121 | GitHub |  |
| devel/reazon-el | 0.4.1 | GitHub |  |
| devel/redo+-el | 1.19 | dev.gentoo.org |  |
| devel/regress-el | 1.5.1 | Gentoo mirror | (eval-when-compile (require 'cl)) from Gentoo: the loop macro was used without it |
| devel/remember-el | 2.0 | GitHub | define-obsolete-function-alias WHEN (Gentoo); needs bbdb, planner |
| devel/repology-el | 1.2.4 | dev.gentoo.org |  |
| devel/request-el | 0.3.3.20220318 | GitHub | needs deferred |
| devel/rescript-mode | 0.1.0.20220613 | GitHub |  |
| devel/restclient-el | 0.20220426 | GitHub | needs helm, jq-mode |
| devel/revive-el | 2.25 | dev.gentoo.org |  |
| devel/rfcview-el | 0.13 | dev.gentoo.org |  |
| devel/rnc-mode | 1.0.6 | GitHub | flymake-proc-* names (Gentoo); the flymake integration errored on the pre-26 names |
| devel/rpm-spec-mode | 0.16.20241209 | GitHub | Thaodan's fork at the commit Fedora ships (2024-12-09): the 2016 original's define-obsolete-variable-alias calls lack WHEN |
| devel/rudel-el | 0.3.2 | dev.gentoo.org |  |
| editors/rust-mode | 1.0.6 | GitHub |  |
| devel/s-el | 1.13.1 | GitHub |  |
| devel/scad-mode | 99.0 | GitHub | needs compat |
| devel/scala-mode | 2.10.7 | url | scala-tool-support 2.10.7 from scala-lang.org, the scala-emacs-mode/ subtree |
| devel/scala-ts-mode | 1.0.0.20250418 | GitHub | GitHub commit Gentoo pins |
| devel/scheme-complete-el | 0.9.9 | url | single .el.gz from synthcode.com |
| devel/scss-mode | 0.5.0.20180123 | GitHub |  |
| devel/servant-el | 0.3.0 | GitHub | needs ansi, commander, dash, epl, f, s, shut-up, web-server |
| devel/sesman-el | 0.3.4 | GitHub |  |
| editors/session-el | 2.4b | url | SourceForge; a flat tarball (WRKSRC=${WRKDIR}) |
| devel/setnu-el | 1.06 | Gentoo mirror |  |
| devel/setup-el | 1.5.0 | dev.gentoo.org |  |
| devel/sharper-el | 1.0.20230129 | GitHub | needs transient |
| devel/shell-maker-el | 0.97.3 | GitHub |  |
| devel/shell-split-string-el | 0.1 | GitHub |  |
| devel/shrink-path-el | 0.3.1 | GitLab | needs dash, f, s |
| devel/shut-up-el | 0.3.3 | GitHub |  |
| devel/slime-el | 2.31 | GitHub |  |
| devel/sly-el | 1.0.43.20260403 | GitHub |  |
| devel/sokoban-el | 1.4.9 | GNU ELPA |  |
| devel/spacemacs-theme-el | 0.3.20241101 | GitHub |  |
| devel/speed-type-el | 20230206 | GitHub | needs compat |
| editors/spinner-el | 1.7.4 | GitHub |  |
| devel/ssass-mode | 0.2.20200211 | GitHub |  |
| devel/ssh-el | 20120709 | dev.gentoo.org |  |
| devel/string-inflection-el | 1.0.16 | GitHub |  |
| devel/stripes-el | 0.3.1.1 | GitLab |  |
| devel/sumibi-el | 0.7.4 | url | 0.7.4 from OSDN, client/elisp; the server side is a separate program |
| devel/sunrise-commander-el | 6.20210927 | GitHub |  |
| devel/svg-lib-el | 0.3 | dev.gentoo.org |  |
| devel/swift-mode | 10.0.0 | GitHub |  |
| devel/swiper-el | 0.15.1 | GitHub | needs ivy |
| devel/switch-window-el | 1.6.2.20210808 | GitHub |  |
| editors/system-packages-el | 1.1.2 | GitLab |  |
| editors/systemd-mode | 1.6 | GitHub | the *-directives.txt tables installed; 305 unit directives load |
| editors/tablist-el | 1.1 | GitHub |  |
| devel/teco-el | 7 | dev.gentoo.org | Gentoo's three patches in Gentoo's order: display-table for ESC in the command minibuffer, interactive-p/last-command-char, old backquotes |
| devel/telega-el | 0.8.660.20260806 | GitHub | needs all-the-icons, company-mode, dashboard, transient, visual-fill-column |
| devel/tempel-el | 1.14 | GitHub | needs compat |
| devel/template-el | 3.3b | url | SourceForge; a flat tarball |
| devel/tempo-snippets-el | 0.1.5 | dev.gentoo.org |  |
| devel/thinks-el | 1.13 | GitHub |  |
| devel/timu-caribbean-theme-el | 1.5 | GitLab |  |
| devel/tp-el | 0.9 | Codeberg | needs transient |
| devel/transient-el | 0.13.8 | GitHub | GNU ELPA 0.13.8, newer than the 0.7 bundled with Emacs 30; magit needs it; needs compat, cond-let, llama |
| editors/treemacs-el | 3.2 | GitHub | icons/ and src/scripts/ installed under the package directory, where treemacs-dir points; needs ace-window, cfrs, dash, ht, hydra, pfuture, s |
| devel/treemacs-all-the-icons-el | 3.2 | GitHub | needs all-the-icons, treemacs |
| devel/treepy-el | 0.1.3 | GitHub |  |
| devel/treesit-auto-el | 1.0.9 | GitHub |  |
| devel/ts-el | 0.3 | GitHub | needs dash, s |
| devel/tty-format-el | 12 | dev.gentoo.org |  |
| devel/tuareg-mode | 3.1.0 | GitHub |  |
| devel/typescript-mode | 0.4 | GitHub |  |
| devel/typing-el | 1.1.4 | dev.gentoo.org |  |
| devel/uboat-el | 1.2 | dev.gentoo.org | interactive-p (Gentoo) |
| devel/undercover-el | 0.8.1 | GitHub | needs dash, shut-up |
| editors/undo-tree-el | 0.8.2 | dev.gentoo.org | needs queue |
| devel/unison-ts-mode | 0.3.0 | GitHub |  |
| devel/uptimes-el | 3.8 | GitHub |  |
| devel/uxntal-mode | 0.3 | GitHub |  |
| devel/vertico-el | 2.14 | GitHub | needs compat |
| devel/vhdl-mode | 3.39.3 | url | 3.39.3 from ETH; its site-start.el (an installation hook) is not installed, it would shadow the real one |
| devel/visual-basic-mode | 1.5 | dev.gentoo.org |  |
| devel/visual-fill-column-el | 2.7.1 | Codeberg |  |
| editors/volume-el | 1.0 | GitHub |  |
| devel/vscode-dark-plus-emacs-theme-el | 2.1.0.20260606 | GitHub |  |
| devel/vue-html-mode | 0.2 | GitHub |  |
| devel/vue-mode | 0.4 | GitHub | needs edit-indirect, mmm-mode, ssass-mode, vue-html-mode |
| devel/vw-mode | 1.0.20250609 | sr.ht |  |
| devel/w3mnav-el | 0.5 | Gentoo mirror | needs emacs-w3m |
| devel/web-mode | 17.3.20 | GitHub |  |
| devel/web-server-el | 0.1.2.20210708 | GitHub |  |
| devel/webpaste-el | 3.2.2 | GitHub | needs request |
| devel/websocket-el | 1.16 | GitHub |  |
| editors/wfnames-el | 1.2 | GitHub |  |
| editors/wgrep-el | 3.0.0 | GitHub |  |
| editors/which-key-el | 3.6.1 | dev.gentoo.org | GNU ELPA 3.6.1 (Emacs 30 bundles 3.6.0) |
| devel/whine-el | 20231020 | dev.gentoo.org |  |
| devel/wikipedia-mode | 0.5 | Gentoo mirror | requires outline-magic, which it calls (Gentoo); dependency added; needs outline-magic |
| devel/with-editor-el | 3.5.4 | GitHub | needs compat, cond-let, llama |
| devel/with-simulated-input-el | 3.0 | GitHub |  |
| devel/ws-butler-el | 1.3 | GitHub |  |
| editors/xclip-el | 1.11.1 | GNU ELPA |  |
| devel/xelb-el | 0.23 | GitHub | needs compat |
| devel/xrdb-mode | 3.0 | dev.gentoo.org | old-style backquote (Gentoo) |
| devel/xterm-color-el | 2.0 | GitHub |  |
| devel/yaml-el | 1.2.4 | GitHub |  |
| editors/yaml-mode | 0.0.16 | GitHub |  |
| devel/yasnippet-el | 0.14.3.20250604 | GitHub |  |
| devel/yasnippet-snippets-el | 1.1 | GitHub | needs yasnippet |
| devel/yatex-el | 1.84 | url | 1.84 from yatex.org. Two fixes: yatexlib's XEmacs colour probe tested device-class, which Emacs 30 now has (frame.el) without selected-device, so the library died without a display; yahtml-define-instag-key passed a void env and a fourth argument its callee did not take (both as in upstream git 2026). yatex19.el/yatex23.el refuse batch compilation and stay source. Exercised: yatex-mode and yahtml-mode set up in a buffer |
| editors/zenburn-el | 20110907 | GitHub | needs color-theme |
| devel/zenburn-theme-el | 2.11.0 | NonGNU ELPA | NonGNU ELPA; the theme file is no-byte-compile |

## Not built (4)

These are left out of the branch.

- editors/password-store-el, editors/password-store-otp-el, editors/pass-el:
  they depend on security/password-store, whose devel/git-base dependency
  did not build on the machine used here (its objects were moved into a
  trash directory by something in that build environment, and libgit.a
  never appeared); the elisp itself was not reached
- editors/rg-el: needs textproc/ripgrep, which needs lang/rust; not built here

## Skipped before building (33)

- bison-mode: dev.gentoo.org/~nicolasbock/bison-mode-0.3.tar.bz2 is gone (404)
- cask: a package.el-driven CLI tool; cask-cli needs the ELPA packages at compile time
- company-ebuild: Gentoo-specific
- dap-mode: needs lsp-mode
- doctest-mode: a single file checked out of a SourceForge svn viewer that no longer exists
- ebuild-mode: Gentoo-specific
- ebuild-run-mode: the mode is tangled out of an org file with umake; nothing to byte-compile as shipped
- edb: built by its own configure/make, which generates edbcore.el; gnuvola.org is behind a cookie check besides
- emacs-ccls: needs lsp-mode
- emacs-common: Gentoo-specific helper (circular with emacs-daemon)
- emacs-daemon: Gentoo-specific helper
- emacs-ebuild-snippets: Gentoo-specific
- emacs-eix: Gentoo-specific
- emacs-openrc: Gentoo-specific
- emms: needs threads (make-mutex, reached from emms-setup); emacs30-nox11 is --without-all
- eselect-mode: mode for Gentoo's eselect, shipped inside eselect
- exheres-mode: dev.exherbo.org answers 403; Exherbo-specific
- external-completion: bundled with Emacs since 29, the oldest version accepted here, at the same 0.1
- keymap-popup: upstream account gone from codeberg (user redirect does not exist)
- lsp-docker: needs lsp-mode
- lsp-java: needs lsp-mode
- lsp-mode: needs threads (make-mutex); emacs30-nox11 is --without-all
- lsp-treemacs: needs lsp-mode
- lsp-ui: needs lsp-mode
- lyskom-elisp-client: built by its own Makefile into one lyskom.elc; src/ also carries copies of custom.el and cus-edit.el that would shadow the bundled ones
- nxml-docbook5-schemas: schema files that belong with the DocBook packages
- nxml-gentoo-schemas: Gentoo-specific
- nxml-libvirt-schemas: schema files out of the libvirt tarball; they belong with sysutils/libvirt
- nxml-svg-schemas: a W3C schema zip; not elisp
- pariemacs: needs PARI/GP installed and its Makefile to generate pari-conf.el; upstream site is gone
- pymacs: needs python to build and run (setup.py); outside an elisp-only set
- scim-bridge-el: needs SCIM, which pkgsrc does not have
- vterm: a C module built with cmake against libvterm, not an elisp-only package
