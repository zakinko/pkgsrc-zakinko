# pkgsrc の emacs 枠組みを Python/Ruby 並みにする

2026-09-15、wiz さん (Thomas Klausner) から「emacs の枠組みは Python や Ruby の
ものに比べて足りていない。やってみる気はあるか」という誘いがあった。挙がった
三点を実装して測ったもの。**まだ誰にも送っていない。**

土台は `NetBSD/pkgsrc` の `editors/emacs/modules.mk` 1.42 (2026-09-14、wiz さんが
emacs21 を外した直後の版) と `mk/pbulk/pbulk-index.mk`。

## 言われた三点

1. `EMACS_TYPE` を立てないと動かない。bulk build では emacs29 を建てたあと、
   pcl-cvs が emacs20 を要るために**黙って建たない**。
2. どの emacs 用の .elc も一つの prefix に入る。Python module のように、その
   interpreter の隣へ入れたい。`EMACS_PKGNAME_PREFIX` にも版を入れて
   `emacs20-pcl-cvs`、`emacs29-apel` のようにしたい。
3. そのうえで bulk が emacs package の全組み合わせを建てるようにしたい
   (`mk/pbulk/pbulk-index.mk`)。

## 実装

`modules.mk.diff` (91 行) と `pbulk-index.mk.diff` (13 行)。

**版の選び方**は lang/python の三段そのまま。

	EMACS_VERSION_REQD が在る → それを使う。package が受けなければ落とす
	                            (bulk がその周回で触らないため)
	無ければ                  → EMACS_VERSION_DEFAULT (= 従来の EMACS_TYPE)
	                            を package が受けるなら使う
	それも駄目なら            → package が受ける先頭の版

`_EMACS_VERSIONS_ALL` は**新しい順**に並べ替えた。Python の
`PYTHON_VERSIONS_ACCEPTED` と同じで「先頭 = 第一希望」にするため。

**置き場**は `share/emacs/site-lisp` から
`share/emacs/${_EMACS_VERSION_MAJOR}.${_EMACS_VERSION_MINOR}/site-lisp` へ。
Emacs は元からその場所を探すので、追加の仕掛けは要らない。

**名前**は `EMACS_PKGNAME_PREFIX= ${_EMACS_TYPE}-`。

## 測った結果 (techne、root を使わない bootstrap に emacs20 を入れて)

	== devel/pcl-cvs (emacs20 のみ受ける)
	  指定なし          前: 落ちる   後: emacs20-pcl-cvs-2.9.9nb4  share/emacs/20.7/site-lisp
	  REQD=emacs20      前: 通る     後: 同上
	  REQD=emacs31      前: 落ちる   後: 落ちる (理由が明確)

	== devel/apel (emacs29 以降を受ける)
	  指定なし          後: emacs30nox-apel-...  share/emacs/30.2/site-lisp
	  REQD=emacs29nox   後: emacs29nox-apel-...  share/emacs/29.1/site-lisp
	  REQD=emacs31      後: emacs31-apel-...     share/emacs/31.1/site-lisp
	  REQD=emacs20      後: 落ちる (apel は受けない)

通しの build も確かめた。`EMACS_TYPE=emacs30nox` を与えたまま
`bmake package` が rc=0 で `emacs20-pcl-cvs-2.9.9nb4.tgz` を作り、中身は
`share/emacs/20.7/site-lisp/pcl-cvs/` に入る。**前はここで落ちていた。**

## 残っている仕事

- **install の置き場を package ごとに直す。**PLIST は 98 個のうち 85 個が既に
  `${EMACS_LISPPREFIX}` を使っているので安いが、**PLIST が変数でも install が
  自前の path を書いている package が在る**。pcl-cvs がそれで、同梱 makefile の
  `lispdir = $(datadir)/emacs/site-lisp` に入れていた。
  `INSTALL_MAKE_FLAGS+= lispdir=${DESTDIR:Q}${EMACS_LISPPREFIX:Q}` を足して直した。
  **106 個ぶん、建てて確かめる以外に見つける方法が無い。**
- 置き場を直書きしている PLIST が 6 個 (cqual, rsltc, tamago-tsunagi, mailutils,
  twittering-mode, emacs-dict-client)。emacs 本体の 1 行ずつは自分の
  `subdirs.el` なので正しい。
- `EMACS_VERSIONS_ACCEPTED` を自分で並べている package は、Python の慣行に
  合わせて新しい順に直す。いまは昇順のものが多く、「先頭 = 第一希望」が
  最も古い版になる。
- emacs29 と emacs29nox は同じ版番号なので `share/emacs/29.x/site-lisp` を
  共有する。両者は元から CONFLICTS しているので同時には入らないが、
  `emacs29-apel` と `emacs29nox-apel` の CONFLICTS をどう書くかは要相談。
- 既存利用者の pkg_add は一度壊れる。PKGNAME が変わるので。

## 置き場

原型を試した場所は techne の `/usr/pkgsrc/zakinko/e-emacs`、`e-pcl`、`e-apel`
(木の外へ出す写し。`editors/emacs` は触っていない)。建てたのは
`~/w/claude/6a6d47e0/e13/pkg` の bootstrap。
