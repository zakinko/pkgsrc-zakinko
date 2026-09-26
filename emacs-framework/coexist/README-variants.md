# X と nox も並べて入れる (2026-09-25)

`README.md` は版違いの同居を扱う。こちらはその先、**同じ版の X 版と nox
版**を並べる話と、XEmacs の elisp を一組で済ませる話。

## 測ったこと

`editors/emacs30` と `editors/emacs30-nox11` は `PKGDIR` を共有していて、
PLIST が同一である。つまり **4341 の path が全部ぶつかる**。X か nox かは
configure の引数だけの違いで、上流はそれを `CONFLICTS` で表している。

版違いのほうは、展開してから数えると衝突はごく僅かだった。

	emacs29 × emacs30        93 件   bin/ 5 本, info/ 66 本, man, icon, include
	emacs20 × emacs30         4 件
	xemacs  × xemacs-current 15 件
	emacs30 × xemacs          0 件   ← Emacs と XEmacs は元から同居できる

`share/emacs/${PKGVERSION}/…` を展開せずに比べると 4210 件に見えるが、
これは PLIST の文字列が同じなだけの偽の重なり。

## 何が本当に X/nox で変わるのか

入っている nox 版と配布物の tarball を突き合わせると、`share/emacs/30.2`
の 4341 件は

	2644 件  配布物と byte 単位で同一   ← 変わりようがない
	1689 件  build が圧縮しただけ       ← 変わりようがない
	   5 件  tramp 系 .elc              ← pkgsrc の当て物が触った file
	   1 件  info/dir
	   1 件  etc/DOC                    ← binary から docstring を抜く

Emacs は `.elc` を配布物に同梱していて (lisp の .el 1654 本に対し .elc
1621 本)、build が作り直すのは `.el` が新しくなった物だけ。pkgsrc が当てる
のは tramp 系 4 本だけなので、作り直されるのもその 4 + 1 本に限られる。

その当て物は CVE-2026-79992 の修正で、正規表現の `bol`/`eol` を
`bos`/`eos` に直しているだけ。`x11` `window-system` `featurep 'x`
`display-graphic` の出現数はいずれも 0 なので、**X の有無で違う .elc に
なる理由が無い**。

つまり確実に変わるのは `bin/emacs-30.2`、`libexec/…/emacs.pdmp`、
`etc/DOC`、`info/dir` の 4 件。

## 実装

`EMACS_TAG` を導入した。X 版では版そのもの、nox 版では版に変種を足す。

	EMACS_TAG?=	${EMACS_VERSION}		A/emacs30-A
	EMACS_TAG=	${EMACS_VERSION}-nox11		A/emacs30-nox11-A

これが `--program-transform-name` と `--datadir` と `--libexecdir` と
`--includedir` と infodir に渡る。Emacs の置き場はすべて `${datadir}`、
`${libexecdir}`、program 名から導かれるので、**当て物は一枚も要らない**。

	configure 6515: lispdir='${datadir}/emacs/'${lispdirrel}
	configure 6520: etcdir='${datadir}/emacs/${version}/etc'
	configure 6522: etcdocdir='${datadir}/emacs/${version}/etc'
	configure 6523: archlibdir='${libexecdir}/emacs/${version}/${configuration}'

`EMACS_TAG` を版のままにすれば、二つの変種は今までどおり衝突する。上流の
既定はそちら。

## 代償

lisp の dir が変種ごとに分かれるので、**elisp package が
`emacs30-foo` と `emacs30-nox11-foo` の二通りになる**。上流の新しい枠組みは
逆に「X と nox は同じ lisp dir を使うから `emacs30-foo` 一つで足りる」と
いう設計なので、そこは真っ向から違う。bulk build の量は倍になる。

ディスクは一版あたり +162MB (lisp 90 / etc 16 / info 9)。14 版すべてで
両方入れても +2.2GB。

## 共通 package に切り出す案 (採らなかった)

変わるのが 4 件なら、残り 4337 件を `emacs30-common` に切り出して両変種が
共有する形が一番小さい (+2MB/版)。`lisp/` は一つで済み、elisp package も
`emacs30-foo` 一つのまま。

引っかかるのは `etc/DOC` で、`etcdocdir` には専用の option が無く
(`--datadir` を動かすと lisp ごと動く)、当て物が一枚要る。実行時は
`EMACSDOC` 環境変数で上書きできるが、package の解にはならない。

`--enable-locallisppath` は `standardlisppath` より前に置かれるので、
変種固有の `.elc` だけを先に見つけさせる余地はある。tramp の 5 本が本当に
同一なら、その仕掛けも要らない。

## XEmacs の elisp は一組で足りる

`xemacs-21.5-b36` が byte-compile した `elisp-compat.elc` は
`xemacs-21.4.25` で load でき、逆も成り立つ。25 本を両版で建てたところ
**結果が完全に一致した** (各 7 OK / 18 NG、食い違い 0 件)。だから
`xemacs-foo` 一本で 21.4 にも 21.5 にも出せる。

GNU Emacs はそうならない。emacs30 が建てた `elisp-compat.elc` は emacs20 で
`invalid-read-syntax` になる。逆向きは通る。両方の site-lisp に在る `.elc`
7 件のうち 3 件が相手の版で load できない。

	reader \ built   20.7   30.2
	20.7             OK     NG
	30.2             OK     OK

上流 1.43 は XEmacs を `xemacs214-` / `xemacs215-` と版ごとに分けている。
こちらは `xemacs-` 一本。置き場はどちらも
`lib/xemacs/site-packages/lisp` で共通なので、名前だけの違い。

## elisp-compat

`devel/elisp-compat` は emacs20 から emacs31 と XEmacs 21.4/21.5 の
すべてで同じ file が読めるように書いてある。古い Emacs に無いものだけを、
無いときだけ定義する。

2026-09-25 に欠陥を一つ直した。`elisp-compat.el` の中で

	(provide 'e20-compat)
	(provide 'emacs-compat)
	(provide 'xemacs-compat)

としていたが、`require` は**その名前の file を探す**ので

	(file-missing "Cannot open load file" "No such file or directory"
	              "emacs-compat")

になる。置き換えた三つの package の名前で `require` している側は全部
落ちる。同名の小さな file を三つ置いて本体を `require` させる形にし、
emacs30 / emacs20 / xemacs215 の三つで四つの名前すべてが通ることを
確かめた。

`subr-x` は `provide` のままにしてある。`site-lisp` に `subr-x.el` を置くと
自前で持っている新しい Emacs のものを隠す。

## 測った結果 (2026-09-25)

`emacs30-nox11-A` に `EMACS_TAG= ${EMACS_VERSION}-nox11` を与えて建て、
`stage-install` まで通した。

	stage-install rc=0
	出来た path            4372 件
	入っている emacs30-nox11  4372 件
	重なり                    0 件

当て物は使っていない。`post-install` と `SPECIAL_PERMS` と
`CHECK_WRKREF_SKIP` が `libexec/emacs/...` を直書きしていたので、
`_EMACS_ARCHLIB` を通すようにした。

PLIST は `make print-PLIST` で取り直した。`${EMACS_TAG}` と
`${EMACS_VERSION}` の二つが要る — 前者は dir 名、後者は Emacs 自身が
自分の版として作る階層。

	bin/emacs-${EMACS_TAG}
	bin/emacs-${EMACS_VERSION}-${EMACS_TAG}
	share/emacs-${EMACS_TAG}/emacs/${EMACS_VERSION}/lisp/...
	libexec/emacs-${EMACS_TAG}/emacs/${EMACS_VERSION}/${MACHINE_GNU_PLATFORM}/emacs.pdmp

### 直っていない粗

`bin/emacs-${EMACS_VERSION}-${EMACS_TAG}` は二重に名前が付いている。上流が
`bin/emacs` と `bin/emacs-30.2` の両方を入れるところへ transform が一律に
後置するため。既存の版違い同居でも同じ物 (`emacs-30.2-30.2`) が出来ていて、
動作には影響しない (ALTERNATIVES が指すのは短いほう) が、版ごとに一つずつ
無駄な複製が入る。

transform を 5 本の名前に限れば消せるが、man page と icon も transform に
乗っているので、そちらの追従を確かめてからにする。

### emacs31 には入れていない

`emacs31-nox11-A` は別の `Makefile.common` (`netbsd-i386-3e/emacs31-A` の
もの) を読んでいて、`EMACS_TAG` の仕掛けが入っていない。そこへ
`EMACS_TAG` だけ書くと、値は使われないのに `CONFLICTS` が消えて
**衝突するのに衝突しないと宣言する**状態になる。建てて確かめていないので
入れていない。31 に広げるときは `Makefile.common` を先に揃えること。

## 動作確認 (2026-09-26)

file 一覧が重ならないことと、実際に動くことは別なので、入れて起動させた。

	GNU Emacs 30.2 が起動
	data=/usr/pkg/share/emacs-30.2-nox11/emacs/30.2/etc/
	exec=/usr/pkg/libexec/emacs-30.2-nox11/emacs/30.2/x86_64--netbsd/
	doc =/usr/pkg/share/emacs-30.2-nox11/emacs/30.2/etc/
	subr=/usr/pkg/share/emacs-30.2-nox11/emacs/30.2/lisp/subr.elc
	(cl-remove-if #'cl-evenp '(1 2 3 4 5)) -> (1 3 5)

`doc-directory` も移した先を指す。`etcdocdir` に option が無いので当て物が
要ると見ていたが、`--datadir` を動かせば追随する。**当て物は不要だった。**

### そこで見つかった穴 — elisp が届かない

移した Emacs の `load-path` は

	share/emacs-30.2-nox11/emacs/30.2/site-lisp

を見るのに、elisp package は `modules.mk` の `EMACS_LISPPREFIX` が版だけで
決まるので

	share/emacs/30.2/site-lisp

へ入る。`require 'elisp-compat` が NG になった。「elisp package が二通りに
なる」と書いておきながら、その仕掛けを入れていなかった。

`modules.mk` を三箇所直した。`EMACS_VARIANT` が空なら何も変わらない。

	_EMACS_LISPDIR.emacs	変種の木の下の site-lisp を指す
	_EMACS_BIN_NAME.emacs	emacs-30.2-nox11 を呼ぶ (でないと別の
				Emacs が .elc を作って変種の木に置く)
	EMACS_PKGNAME_PREFIX	emacs30-nox11- を名乗る (でないと同じ
				名前の package が二つになる)

直したあとの値。

	VARIANT 無し   PKGNAME=emacs30-elisp-compat
	               BIN=bin/emacs-30.2
	               LISP=share/emacs/30.2/site-lisp
	VARIANT=nox11  PKGNAME=emacs30-nox11-elisp-compat
	               BIN=bin/emacs-30.2-nox11
	               LISP=share/emacs-30.2-nox11/emacs/30.2/site-lisp

変種として建てて入れ、移した Emacs で `require 'elisp-compat` が OK に
なるところまで見た。

### 途中で二度壊した

`EMACS_VARIANT?= # empty` と書いたら "# empty" が値になり、`:D` が真に
なって変種無しでも `bin/emacs-30.2-` を指した。`:M*:S/^/-/` も空に効いて
同じ結果。`${empty(EMACS_VARIANT):?:-${EMACS_VARIANT}}` で直した。

emacs30-nox11 を移した build に入れ替えたままにしたので、`bin/emacs-30.2`
が箱から消え、そこへ依存する 30 本余りの elisp package が読めなくなった。
9/22 の binary package から戻した。**実験のために入れ替えたものは、確かめ
たらその場で戻すこと。**

## emacs20 の X と nox (2026-09-26)

emacs20 は上流どおり一つの package のままにする。X は `x11` option で
入れ替えるもので、既定の option (`emacs-pop inet6`) では X 無しで建つ。
版付きの名前 (`bin/emacs-20.7` ほか) で入るので、他の版とはこのまま
同居できる。

X 版と nox 版を並べたいときは分けられる。`emacs20-A` は既に
`EMACS_TAG` を受け取り、`-nox11` で終わるときは `options.mk` が `x11` と
toolkit を出さない。足すのは次の二つ。

- `emacs20-A/Makefile` を読み込み `EMACS_TAG= 20.7-nox11`、
  `PLIST_SRC= ${.CURDIR}/PLIST` を与える package (`emacs20-nox11`)
- modules.mk の `_EMACS_VERSIONS_ALL` に `emacs20nox`、
  `_EMACS_PKGDIR_MAP` に `emacs20nox@../../editors/emacs20-nox11`

a3f8727 がその形で、techne で `x11 xaw` 付きの emacs20 (libX11 と
libXaw に link、`x-open-connection` を持つ) と emacs20-nox11 (どちらも
持たない) を並べて入れ、どちらを消しても残った方が起動し自分用の
elisp-compat と data-directory を読むことを確かめた。既定を変えない
以上、分けると既定の emacs20 と中身の同じ nox 版が並ぶので、既定では
入れていない。

## 21 から 28 (2026-09-27)

emacs21-A から emacs28-A と nox 版を netbsd-i386-3e から取り込み、30 と
同じ EMACS_TAG の仕組みを入れた (ba4a7cf)。techne で 21、23 から 28 の
X 版と nox 版、22 の nox 版、それぞれの elisp-compat を並べて入れ、15 の
package の間で重なる path は 0。どちらを消しても残った方は起動して自分用の
elisp-compat を読み、bin/emacs の候補は消した方だけ外れる。27 と 28 は
emacs.pdmp を読む (27、28 は <argv0>.pdmp が無ければ emacs.pdmp も探す)。

版ごとに要ったこと:

- 21: install で prefix を DESTDIR 付きに上書きするので、datadir、
  libexecdir、infodir を install にも渡し直す。変換式は $ を使わない形
- 23: desktop file と icon を datarootdir に版無しで置くので、nox 版は
  datarootdir ごと移す (X 版と 12 の path がぶつかっていた)
- 26、27: nox 版の version.mk が 26.1、27.1 のままだった

22 の X 版は建たない。unexec の dump が memcpy で落ちる。temacs の ASLR を
切ると (paxctl +a) dump は通るが、出来た emacs が init_alloc から
make_float で落ち、番地が dump 前と違う。-z nocombreloc は効かなかった。
22 は nox 版だけにしてある。

