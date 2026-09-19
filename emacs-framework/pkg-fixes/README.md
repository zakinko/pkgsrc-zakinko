# package 側の差分 — wiz さんの三分割

2026-09-19、wiz さんの返事で「framework / いま壊れている物の直し / この変更で
要る適応、の三つに分けてほしい」と言われたので、部屋を三つにした。

	framework/     editors/emacs*/ と xemacs*/ の配線。modules.mk と
	               pbulk-index.mk 本体は一つ上の階 (CI が別扱いで当てる)
	fixes/         いまの trunk で既に間違っている物。この変更が無くても直す
	               価値が有り、freeze 中でも commit できる筋
	adaptations/   いまは正しく、この変更が入って初めて壊れる物
	not-sent/      当てても建たないので送らない物 (ecb)

線の引き方は「trunk の今日の modules.mk で、pkgsrc に在るどれかの Emacs
で壊れるか」。xemacs で今日壊れる物 (gnuserv, dictem, matlab-mode, xslide,
emacs-w3m) と emacs20 で今日壊れる物 (doxymacs) は fixes。lisp の置き場を
`${EMACS_LISPPREFIX}` でなく手で綴る物 (cqual, tamago, tamago-tsunagi,
pcl-cvs, rsltc, emacs-wiki, twittering-mode, emacs-dict-client, mailutils)
も fixes に入れた。今日は共有 site-lisp と同じ場所を指すので害は無いが、
枠組みを使っていない、という wiz さんの分類のとおり。`GITHUB_PROJECT` を
省いている四つ、emacs20 の下で w3 を prefix 無しで求める doxymacs、mew の
etc PLIST は今日は正しいので adaptations。

info は PLIST を書き換える形をやめた (2026-09-19)。modules.mk が PKGINFODIR
を版の下に立てれば、plist-info.awk の正規化と gnu-configure.mk の --infodir
が付いてくるので、PLIST の `info/` はそのままで正しい。`info-plist-prefix.diff`
(11 PLIST) はそれで要らなくなった。残るのは `info` を直書きしている二つ
(emacs-w3m の --infodir、mu の -Dinfodir) で、それぞれの fixes に入っている。

全 29 本 (framework 4、fixes 19、adaptations 6) を trunk (2026-09-18 22:08Z、
c8e5216) の現物へ、名前順・逆順・部屋順・部屋逆順の四通りで `-F0` の空当て
→ 本当てで通した。rej 0。modules.mk.diff と pbulk-index.mk.diff も同じ
trunk へ空当てで通る。

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
