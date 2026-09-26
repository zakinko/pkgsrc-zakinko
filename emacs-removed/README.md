# 既に消された package (2026-09-25 時点)

pkgsrc から取り除かれたが、こちらでは emacs20 や XEmacs で使えるもの。
上流の木にはもう無い。

| package | いつ消えたか | ここでの状態 |
|---|---|---|
| `misc/bbdb2` | 2026-09-12 emacs21 と一緒に | emacs20 で建つ。20 の feature 中 16 が load |
| `editors/jde` | 同上 | emacs20 で建つ。37 の feature 中 37 が load |
| `textproc/nxml-mode` | 同上 | emacs20 で建つ。24 の feature 中 24 が load |

三本とも Makefile が emacs21 しか受け付けていなかったために、emacs21 が
消えたとき一緒に消えた。どれも emacs20 で動く。

emacs21 そのものは拾っていない。

## misc/bbdb2

当て物が二本要る。`bbdb-hooks.el` が `mail-parse` を読むが、これは Gnus
5.8 のもので Emacs 20.7 は 5.7 を積んでいる。`bbdb-rmail.el` は `rmailsum`
を require するが、Emacs 20 の `rmailsum.el` はそれを provide しない。

2026-09-25 に二つ直した。`--with-emacs` を xemacs の腕でしか渡しておらず、
GNU Emacs では configure が `PATH` の emacs を拾っていた。木に emacs30 が
入っていると emacs20 の package を建てているのに emacs30 が走り、その
`2>&1` に混ざる起動メッセージが configure の出力ごと `lisp/Makefile` へ
書き込まれて、bmake が `Invalid line "Loading site-init..."` で落ちる。
併せて `bbdb-autoloads.elc` が PLIST に無かった。

2026-09-26 に XEmacs を受け付けから外した。XEmacs を受け付けるのに
`CONFLICTS+= xemacs-packages-[0-9]*` を持ち、XEmacs 向けに建てるのに要る
`timezone` を配るのはその package だけなので、XEmacs では原理的に建た
なかった。bbdb は xemacs-packages に入っているので、XEmacs ではそちらを
使う。読めない 4 つは `reportmail` `gnuserv` `vm` を求めるものと、XEmacs
専用の `bbdb-xemacs`。

## editors/jde

2026-09-26 に emacs20 で建ち、37 の feature が全部 load できるように
なった。以前の「37 file が byte-compile する」は確かめられない。jde の
makefile は compile の行を `-$(EMACS)` と書いていて、失敗しても build が
進み `.el` だけを入れていたので、そう見えただけの可能性が高い。

止まっていたのは四つ。devel/semantic が建たなかった (emacs-doomed 側で
直した)。makefile の `EMACS = emacs` が PATH の Emacs を使っていたので
`EMACS_BIN` を渡す。`jde-new-buffer-menu` の `:set` が batch では無い
Files menu に項目を足そうとして `keymapp nil` で止まるので、当て物で
menu が在るときだけにする。依存の path が `devel/elib` を指していたが、
名前は `emacs20-elib` で、それは `devel/emacs20-elib` にある。

compile の失敗を無視しないよう makefile の `-` を外した。PLIST は版の
無い `share/emacs/site-lisp/jde` を書いていて、建てた結果から取り直した。

木の devel/elib も `EMACS=${EMACS_FLAVOR}` で素の `emacs` を使うので、
emacs20 向けを別の Emacs が compile する。測るときは emacs-20.7 を渡して
建てた。これは elib 側の問題で、ここでは直していない。

Java は PKG_JVM=openjdk21 で測った。

## textproc/nxml-mode

source が `#x` を 14,490 回使っていて、Emacs 20 の reader にその syntax が
無い。当て物ではなく `post-patch` の一手で十進に変える。`elisp-compat` が
Emacs 21 の関数を供給し、`mule-ucs` が `decode-char` を供給する。

2026-09-26 に測り直すと、当て物 8 本がどれも distinfo に無く、
"Ignoring patch file ... no checksum found" と言われて一本も当たって
いなかった。案内どおり `rng-auto.el` を読むと "FSF GNU Emacs version 21
or later required" で止まり、何も使えなかった。distinfo を直すと 24 の
feature が全部 load できる。2026-09-25 の「12 中 10」は、入口を通さずに
feature を直に読んだ数字だった。

## 送り先

tech-pkg での 2026-09-25 の返信で、上流の維持者は「emacs 考古学にはあまり
興味が無い」として dholland さんへ送るよう勧めている。
