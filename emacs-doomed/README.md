# 消される予定の package (2026-09-25)

tech-pkg@ の "new emacs framework in tree, some PKGNAMEs changed, some
packages will be removed" で、どの (x)emacs 版でも建たないとして一週間後に
消すと予告された 10 本のうち、木にある 6 本をここに置く。

上流は 2026-09-25 の時点でどれも `EMACS_VERSIONS_ACCEPTED= # empty` に
されている。ここでは受け付け版を戻し、建たない原因を直した。

## 測って建ったもの

2026-09-26 に、この branch の file そのものから建て直して測った。load は
package が案内する入口 (`(require 'vm)` など) を読んでから、package が
`provide` する feature を一つずつ `require` した数。site-start は読まない。

| package | 版 | 直し | load |
|---|---|---|---|
| `mail/vm` | emacs30, 31 | 8.3.2 へ上げた | 52 中 51 |
| `devel/ecb` | emacs30 | 2.52 へ上げた | 3/3 |
| `misc/elscreen` | emacs20 | 当て物 1 本、SUBST、elisp-compat | 10 中 9 |

`mail/vm` は 2026-09-26 に 8.3.2 (2025-12-29、gitlab の emacs-vm) へ
上げた。8.2.0b に足していた当て物 4 本 (info 2 本、vm-folder、vm-pcrisis) は
どれも上流で直っていた。gitlab の tarball には生成済みの configure が無いので
autoconf を回す。configure は Emacs を `--with-emacs` か PATH の `emacs` で
決めるので、版付きの `EMACS_BIN` を渡す。8.3 の texinfo は NetBSD の
makeinfo 4.8 では node の検査で落ちるので texinfo 5 を求める。8.3 は
bin/base64-encode などの補助 program を持たず、変換を Emacs の中でする。
読めない 1 つは `vm-w3m` で emacs-w3m を求める。

`devel/ecb` は 2.50 (GitHub の 1330a44) のままでは emacs30 で建たない。
`defmethod` が Emacs 29 で `lisp/obsolete/eieio-compat` へ移り、その先も
`button-release-event` など XEmacs の型で止まる。上流の 2.52 はどちらも
直っていて、emacs-updates branch の直しをそのまま使った。2026-09-25 の
「3/3」は 2.52 を測った数字で、この branch の 2.50 ではなかった。

`misc/elscreen` は「apel が emacs20 を支えない」という理由で `BROKEN` に
されていた。上流の `devel/apel` は 2020 年の版で、その年に落とされた
Emacs 20 と XEmacs の互換層が入っていない。層を戻した apel なら建つ。
ただし建っても Emacs 20 では load できなかった。`booleanp` (Emacs 22) と
`add-to-list` の三つ目の引数 (Emacs 21) で止まり、`propertize` と
`elscreen-dnd` の `mapc` も無い。当て物で前二つを直し、`propertize` は
elisp-compat から取り、`mapc` は別の distfile なので SUBST で `mapcar` に
した。読めない 1 つは `elscreen-wl` で Wanderlust を求める。2026-09-25 の
「10 中 9」は、load-path に入れた destdir に `.elc` が無く、箱に入っていた
別の elscreen を読んでいた測定の誤り。

`misc/lookup` は emacs20 で建ち、24 の feature が全部 load できる
(`stem` は `stem-english.el` が provide するので file 名で読む)。
configure が PATH の `emacs` を拾うので、emacs20 向けの build を別の
Emacs が byte-compile していた。`--with-emacs` で版付きの binary を
渡す。1.4.1 は Emacs 27 で消えた古い backquote `(\` (...))` を使うので、
今の Emacs では建たない。実行には eblook が要る。

## chat/emacs-jabber

emacs30 と emacs31 で建ち、70 の feature が全部 load できる。止まって
いたのは autoload を作る段で、`batch-update-autoloads` は Emacs 29 で
`lisp/obsolete/autoload.el` に移り、読まれなくなっていた。当て物で
`-l autoload` を足す。Emacs 20 の autoload.el にも同じ関数がある。

2026-09-25 は Emacs 20 で建てようとしていた。0.8.92 は `xml` `ewoc`
`format-spec` `mailcap` `time-date` `sha1` `dns` `sasl` `tls` `auth-source`
など、Emacs 20 に無い library を 20 近く求めるので、emacs20 は受け付けから
外し、そのためだけの elisp-compat への依存も外した。

emacs29 は木の editors/emacs29-nox11/version.mk が 29.1 のままで、lisp の
置き場が 29.1 になって落ちる。jabber ではなく木の問題。XEmacs は
測れていない。EMACS_MODULES=base が xemacs-packages を求め、それが上流の
素の xemacs package を求めるが、この箱の XEmacs は別名で入っている。
受け付けは上流どおり xemacs214 と xemacs215 を残した。

## devel/semantic

emacs20 で建ち、25 の feature が全部 load できる。2026-09-25 に
「speedbar 0.15 の変数を求めるが木には 0.14 しかない」と書いたのは誤り
だった。`speedbar-dynamic-tags-function-list` は入っている 0.14beta4 にも
在る。build が `EMACSLOADPATH` で Emacs 自身の `lisp/` を site-lisp より
前に置くので、Emacs 20 に同梱の speedbar 0.8 が先に見つかっていた。
semantic の Makefile は `LOADPATH` の dir を `add-to-list` で足すが、
site-lisp の下の dir は既に load-path の後ろに在るので何も起きない。
当て物で `setq` と `cons` にして前へ置き、`LOADPATH` に入っている speedbar
と eieio の dir を渡す。手を加えていない木でも落ちたのは同じ理由。

## wip/undo-tree と wip/queue-el

wip/undo-tree は 0.3 (2012) を 0.8.2 (2024-03-31、GNU ELPA) へ上げた。0.8 は
GNU ELPA の `queue` を求め、pkgsrc には無いので wip/queue-el (0.2、
2024-03-31) を新しく作った。emacs30 と emacs31 で建ち、`global-undo-tree-mode`
のもとで undo と redo が期待どおり動く (a、b と入れて undo で "a"、redo で
"ab")。

## 測った機械

NetBSD 11.0 amd64、emacs20 から emacs31 と xemacs214/215 が同居している木。
上流 `editors/emacs/modules.mk` は 1.42 相当で、1.43 (2026-09-25) では
確かめ直していない。
