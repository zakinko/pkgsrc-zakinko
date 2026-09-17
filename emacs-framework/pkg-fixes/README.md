# 置き場の配線が要る package

`_EMACS_LISPDIR` を版の下へ動かすと、**PLIST は `${EMACS_LISPPREFIX}` に追従するが、
install 側が自前の path を書いている package はずれる。**PLIST が変数なので
file-check が「PLIST に在るのに destdir に無い」と言って落ちる。

**静的な grep では見つからない。**pcl-cvs の Makefile には `lispdir` の文字が無く
(`EMACS_LISPPREFIX` は MESSAGE_SUBST にだけ在る)、同梱 makefile が
`lispdir = $(datadir)/emacs/site-lisp` と決めている。**建てるのが検査。**

2026-09-16、emacs20 を選ぶ 13 個を建てて見つかったのは二つ。

	devel/pcl-cvs    同梱 makefile の lispdir
	editors/tamago   同梱 configure の lispdir (--with-lispdir は受けない)

どちらも一行で直る。

## 建たないので送らないもの

`ecb.diff` は **当てても devel/ecb は建たない。**外へ出す当て物には入れない。

`GITHUB_PROJECT` を足すと fetch と WRKSRC は通るが、次で止まる。

	Symbol's function definition is void: semantic-mode

`ecb-2.50` の `Makefile:89` が compile script に `(semantic-mode 1)` を書く。
`xemacs-nox11-21.5.36nb1` + `xemacs-packages-1.19nb1` で

	(fboundp 'semantic-mode) → nil      素の状態でも (require 'semantic) の後でも

`devel/ecb` が受けるのは xemacs215/215nox/214/214nox だけなので、**受ける
Emacs のどれでも byte-compile 出来ない。**当て物は一つ目の壁を越えて二つ目に
当たるだけで、直したことにならない。

`editors/xemacs-packages` が既に ECB を入れている (lisp/ecb 以下 63 file)。
