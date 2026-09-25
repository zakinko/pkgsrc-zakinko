# 消される予定の package (2026-09-25)

tech-pkg@ の "new emacs framework in tree, some PKGNAMEs changed, some
packages will be removed" で、どの (x)emacs 版でも建たないとして一週間後に
消すと予告された 10 本のうち、木にある 6 本をここに置く。

上流は 2026-09-25 の時点でどれも `EMACS_VERSIONS_ACCEPTED= # empty` に
されている。ここでは受け付け版を戻し、建たない原因を直した。

## 測って建ったもの

| package | 版 | 直し | load |
|---|---|---|---|
| `mail/vm` | emacs30 | `--with-lispdir` を configure へ | 52 の feature 中 49 |
| `devel/ecb` | emacs30 | 受け付け版を戻しただけ | 3/3 |
| `misc/elscreen` | emacs20 | 受け付け版を戻し `BROKEN` を外した | 10 中 9 |

`mail/vm` は `MAKE_ENV` で `LISPDIR` を渡していたが、`configure` が
`lispdir` を決めて生成後の Makefile に書き込むので環境変数は届かない。
file は版を含まない `share/emacs/site-lisp/vm` に入り、PLIST と合わずに
落ちていた。`--with-lispdir` を直接渡すと `share/emacs/30.2/site-lisp/vm`
に入る。読めない 3 つは `vm-w3m` (emacs-w3m を求める)、`vm-pcrisis`、
`vm-folder`。

`misc/elscreen` は「apel が emacs20 を支えない」という理由で `BROKEN` に
されていた。上流の `devel/apel` は 2020 年の版で、その年に落とされた
Emacs 20 と XEmacs の互換層が入っていない。層を戻した apel なら emacs20 で
建ち、elscreen も建つ。読めない 1 つは `elscreen-wl` で Wanderlust を求める。

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

`misc/lookup` は試していない。

## 測った機械

NetBSD 11.0 amd64、emacs20 から emacs31 と xemacs214/215 が同居している木。
上流 `editors/emacs/modules.mk` は 1.42 相当で、1.43 (2026-09-25) では
確かめ直していない。
