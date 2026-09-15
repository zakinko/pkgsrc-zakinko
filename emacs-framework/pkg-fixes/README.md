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
