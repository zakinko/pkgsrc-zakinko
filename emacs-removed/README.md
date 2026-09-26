# 既に消された package (2026-09-25 時点)

pkgsrc から取り除かれたが、こちらでは emacs20 や XEmacs で使えるもの。
上流の木にはもう無い。

| package | いつ消えたか | ここでの状態 |
|---|---|---|
| `misc/bbdb2` | 2026-09-12 emacs21 と一緒に | emacs20 で建つ。20 の feature 中 16 が load |
| `editors/jde` | 同上 | 建たない (下記) |
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

「emacs20 では compile できない」という注記は古く、37 file が speedbar,
eieio, semantic, elib に対して byte-compile する — というのが以前の報告。

**2026-09-25 の測定ではこれが再現しない。** `devel/semantic` が emacs20 で

	!! Symbol's value as variable is void ((speedbar-dynamic-tags-function-list))

で落ち、jde はその先へ進めない。semantic 1.4.4 は speedbar 0.15 以降を
求めるが、木には 0.14 しかない。手を加えていない木でも同じ落ち方をする
ことを対照で確かめた。以前の報告と今日の測定のどちらが正しいか、外へ出す
前に確かめる必要がある。

Debian の 2.3.5.1 向けの直しが二つ当たる、というのも以前の報告で、これも
確かめ直していない。

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
