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
| `mail/vm` | emacs30 | `--with-lispdir`、当て物 2 本 | 52 中 51 |
| `devel/ecb` | emacs30 | 2.52 へ上げた | 3/3 |
| `misc/elscreen` | emacs20 | 当て物 1 本、SUBST、elisp-compat | 10 中 9 |

`mail/vm` は `MAKE_ENV` で `LISPDIR` を渡していたが、`configure` が
`lispdir` を決めて生成後の Makefile に書き込むので環境変数は届かない。
file は版を含まない `share/emacs/site-lisp/vm` に入り、PLIST と合わずに
落ちていた。`--with-lispdir` を直接渡す。`vm-folder` は load 時に呼ぶ
`vm-add-write-file-hook` の定義元 `vm-misc` を compile 時にしか読んで
いなかった。`vm-pcrisis` は `make-face` に XEmacs の二つ目の引数を渡して
いた。読めない 1 つは `vm-w3m` で emacs-w3m を求める。

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

## 途中まで直したもの

`chat/emacs-jabber` は二つ直したが、まだ建たない。

- `--without-gconf` は configure に存在しない option で、"unrecognized
  options" を出しながら `gconftool-2` が呼ばれていた。
  `GCONF_SCHEMA_INSTALL_SOURCE` を与えると呼ばれない
- `jabber-util.el` の `cond` が Emacs 20 では
  `error (("No implementation of \`jabber-replace-in-string' available"))`
  で終わる。`devel/elisp-compat` が `replace-regexp-in-string` を供給する
  ので、soft な `require` を足す当て物を入れた

その先で `xml` が無くて止まる。Emacs 20 に無く Emacs 21 にある library が
`xml` `ewoc` `format-spec` `mailcap` `time-date` の 5 本、21 にも無いものが
`sha1` (flim が持つ) と `dbus` (任意)。ここから先は Emacs 21 からの移植に
なるので手を付けていない。

## 直していないもの

`devel/semantic` は semantic 1.4.4 が `speedbar-dynamic-tags-function-list`
を求めるが、これは speedbar 0.15 からのもので木には 0.14 しかない。手を
加えていない木でも同じ落ち方をすることを対照で確かめた。`editors/jde` は
この semantic に依存しているので、semantic が消えると道連れになる。



## 測った機械

NetBSD 11.0 amd64、emacs20 から emacs31 と xemacs214/215 が同居している木。
上流 `editors/emacs/modules.mk` は 1.42 相当で、1.43 (2026-09-25) では
確かめ直していない。
