# pkgsrc-zakinko

zakinko が自作したソフトウェアの pkgsrc パッケージ置き場。本家から削除された
パッケージを引き取って手元で維持する場合も、ここに置いています。

本家 pkgsrc ツリーの `security` や `www` に混ぜず、`zakinko` という独立した
カテゴリとして切っています。本家を更新しても自作分が消えず、どれが自作かも
一目で分かります。

## 置き方

このリポジトリを `/usr/pkgsrc/zakinko` として配置します。

```sh
git clone git@github.com:zakinko/pkgsrc-zakinko.git /usr/pkgsrc/zakinko
```

すでに pkgsrc ツリーを git で管理していて中に別リポジトリを置きたくない場合は、
別の場所に clone してシンボリックリンクを張ってください。

```sh
git clone git@github.com:zakinko/pkgsrc-zakinko.git /home/zakinko/pkgsrc-zakinko
ln -s /home/zakinko/pkgsrc-zakinko /usr/pkgsrc/zakinko
```

カテゴリの `Makefile` が `../mk/misc/category.mk` を読むので、**必ず pkgsrc
ツリーの直下**に置く必要があります。

## 使い方

```sh
cd /usr/pkgsrc/zakinko/meibo
make install
```

`bmake` を使っている環境では読み替えてください。

自作パッケージの配布物のチェックサムは追跡していません。初回は次で生成します。

```sh
make makesum
```

第三者のソフトウェアを引き取ったものは例外で、`distinfo` を追跡しています。
配布物の版が固定されていますし、`mule2` のようにパッチが 100 個を超えるものは
そのチェックサムこそが中身の保証になるためです。

## 収録パッケージ

| パッケージ | 内容 |
| --- | --- |
| [anthy-unicode](anthy-unicode/) / [anthy-unicode-elisp](anthy-unicode-elisp/) | anthy の Unicode 版 fork。本家 pkgsrc にはまだ無い |
| [elscreen](elscreen/) | ElScreen を 1.4.6 (2007) から knu/elscreen の 20180321 へ。本家は Emacs 24 以降に非対応のまま、作者のサイトも消えている。当て物一本で emacs20 でも使える |
| [emacs26](emacs26/) / [emacs26-nox11](emacs26-nox11/) | GNU Emacs 26.3。本家では 2026 年 8 月に削除済み |
| [emacs27](emacs27/) / [emacs27-nox11](emacs27-nox11/) | GNU Emacs 27.2。本家では 2026 年 8 月に削除済み |
| [emacs28](emacs28/) / [emacs28-nox11](emacs28-nox11/) | GNU Emacs 28.2。本家では 2026 年 8 月に削除済み |
| [meibo](meibo/) | 日本の会社と学校のための ID ライフサイクル管理と SSO のサーバ |
| [mule](mule/) | 多言語 Emacs (Mule 1.1 / Emacs 18.59 ベース)。pkgsrc-wip の mule11 を、tsutsui の今の木に上げたもの |
| [mule2](mule2/) | 多言語 Emacs (Mule 2.3 / Emacs 19.28 ベース)。本家では 2022 年に削除済み |
| [nss_stns](nss_stns/) | STNS の名前解決スイッチモジュール |
| [speakersafetyd](speakersafetyd/) | Apple Silicon Mac のスピーカーを熱から守る Asahi Linux の daemon。NetBSD 用の backend を当て物で足した。動かすには NetBSD 側の applemacaudio(4) が要り、まだ本家に無い |
| [stnsd](stnsd/) | 小さな STNS API サーバ |

どのパッケージも第二カテゴリを併記してあるので (`stnsd` は `zakinko` と
`security` の両方)、本家の分類でも探せます。

FreeBSD ports 版は [ports-zakinko](https://github.com/zakinko/ports-zakinko)
にあります。

## 上流パッケージの写し

上流 pkgsrc の package に手を入れたものは、`zakinko` カテゴリの中に他と同じ
ように平らに置いています。カテゴリの `Makefile` の `SUBDIR` にも入れてあり、
`make` から普通に見えます。

| ここ | 上流のどこ | 何を直したか |
| --- | --- | --- |
| [anthy/](anthy/) | `inputmethod/anthy` | anthy.el が Emacs 27 以降で使えない廃止シンボル、人名と辞書の誤り |
| [anthy-elisp/](anthy-elisp/) | `inputmethod/anthy-elisp` | emacs29〜31 を受け付けるように |
| [augeas/](augeas/) | `sysutils/augeas` | CVE-2025-2588 の修正と、lens が一本も入らないのを直す |
| [autogen/](autogen/) | `devel/autogen` | mmap の失敗を見ずに走査していたのを直す (CVE-2025-8746) |
| [bbdb2/](bbdb2/) | `misc/bbdb2` | emacs20 と emacs21 で建つように。configure が PATH の emacs を拾っていたので版付きの binary を渡す |
| [calc/](calc/) | `math/calc` | **/tmp に予測できる名前で書いていたのを直す**。LICENSE が gnu-gpl-v1 (1989 年版)。site-start.d で autoload を登録。当て物の説明 |
| [ecb/](ecb/) | `devel/ecb` | 2.52 へ上げる。2.50 は Emacs 29 で defmethod が eieio-compat へ移って止まる |
| [emacs-ilisp/](emacs-ilisp/) | `devel/emacs-ilisp` | GPL でない独自許諾の文面を files/ に用意。当て物 4 本の説明 |
| [emacs-jabber/](emacs-jabber/) | `chat/emacs-jabber` | Emacs 29 で autoload.el が obsolete/ へ移り、autoload を作る段で止まっていた |
| [emacs20/](emacs20/) | `editors/emacs20` | LP64 で Lisp_Object を切り詰めていた宣言もれ。日本語入力が使えない。積み残しの CVE 二本も当てる |
| [emacs21/](emacs21/) / [emacs21-nox11/](emacs21-nox11/) | `editors/emacs21` | 本家に残っている CVE 二本 (etags と copy-file) を当てる |
| [croc/](croc/) | `net/croc` | 11.5.3 へ上げ、GO_BUILD_PATTERN で NetBSD と DragonFly でも建つようにする |
| [fail2ban/](fail2ban/) | `security/fail2ban` | 1.1.1 へ上げ、2to3 と python 固定を外す (pkgsrc PR #175) |
| [iiimecf/](iiimecf/) | `inputmethod/iiimecf` | LICENSE と category の順。shell を ${RUN} で書く |
| [jde/](jde/) | `editors/jde` | emacs20 でも建つように。効いていなかった PKGSRC_MAKE_ENV+= EMACS=${EMACS} を直す。compile の失敗を無視しない。LICENSE |
| [leim20/](leim20/) | `editors/leim20` | 版を四箇所直書きしていたのを `${VERSION}` へ。LICENSE と当て物の説明 |
| [leim21/](leim21/) | `editors/leim21` | LICENSE と当て物の説明 |
| [libuuid/](libuuid/) | `devel/libuuid` | DragonFly で util-linux が組めるように |
| [lookup/](lookup/) | `misc/lookup` | emacs20 で建つように。configure が PATH の emacs を拾っていたので版付きの binary を渡す |
| [mule-ucs/](mule-ucs/) | `editors/mule-ucs` | LICENSE。MESSAGE を DESCR へ。当て物の説明 |
| [ntp4/](ntp4/) | `net/ntp4` | 4.2.8p16 で直った境界外書き込みを当てる |
| [nxml-mode/](nxml-mode/) | `textproc/nxml-mode` | emacs20 でも建つように。同梱の Makefile が PATH の emacs で compile していた。LICENSE。MESSAGE を DESCR へ。要らない :Q と字下げ |
| [pcl-cvs/](pcl-cvs/) | `devel/pcl-cvs` | 当たらない CONFLICTS 二本と、重複した emacs20 判定を落とす。LICENSE と当て物の説明 |
| [queue-el/](queue-el/) | (上流に無い) | GNU ELPA の queue 0.2。undo-tree 0.8 が求める |
| [semantic/](semantic/) | `devel/semantic` | emacs20 で建つように。Emacs 20 同梱の speedbar 0.8 が先に読まれていた |
| [tamago/](tamago/) | `editors/tamago` | LICENSE。12786 行の当て物が何かを書く |
| [undo-tree/](undo-tree/) | `wip/undo-tree` (pkgsrc-wip) | GNU ELPA の 0.8.2 へ上げる |
| [vm/](vm/) | `mail/vm` | 8.3.2 へ上げ、8.2.0b の当て物 4 本を外す。版付きの Emacs を configure に渡す |
| [w3/](w3/) | `www/w3` | LICENSE と当て物 3 本の説明 |
| [xemacs/](xemacs/) | `editors/xemacs` | MESSAGE を DESCR へ。COMMENT が package 名で始まるのを直す。効いていない PLIST_VARS+= debug |
| [xemacs-current/](xemacs-current/) | `editors/xemacs-current` | 同上 |
| [xemacs-packages/](xemacs-packages/) | `editors/xemacs-packages` | CATEGORIES の位置。LICENSE を単一で書けない理由を残す |
| [xwpe/](xwpe/) | `editors/xwpe` | 1.6.9 へ上げ、当て物を 9 本から 3 本に減らす (pkgsrc PR #180) |
| [zls/](zls/) | `devel/zls` | 0.16.0 へ上げて BROKEN を外す (pkgsrc PR #164) |

平らに置くと、どの上流 package の写しなのかがディレクトリ名から読めなく
なります。**上流へ送るときの当て先はこの表が持ちます。**`CATEGORIES` は
上流のまま残してあるので (`zakinko/augeas` なら `sysutils`)、そちらからも
辿れます。ただし写しが在る場所はあくまで `zakinko/` で、`CATEGORIES` が
ディレクトリを決めるわけではありません。

`PKGNAME` も上流と同じなので、先にこちらを入れておけば依存を満たします。
ただし入るものが変わらない直しでは、どちらが入っているのか後から分からなく
なります。`libuuid` を `nb1` にしてあるのはそのためです。

**上流の同名 package を差し替えるわけではありません。** `zakinko/augeas` を
入れても `sysutils/augeas` は素のままなので、素から建てたときに依存で引かれる
のは上流の方です。当て物を効かせたい相手には、先にこちらを入れてください。

ここに置くのはあくまで手元をすぐ直すためで、**本筋は pkgsrc 本体に入れる
こと**です。上流が取り込んだら、ディレクトリごと消します。消し忘れると、
上流が直したあとも古い写しを使い続けることになります。

## 上流で消された・消される Emacs 向けの package

2026 年 9 月に上流から消えた、あるいは消すと予告された Emacs 向けの package
を引き取って直したものです。以前は上流の category ごとに分けた別の場所に
置いていましたが、どれも一番上へ移し、同じ package が二つあったものは一つに
まとめました (2026-09-27)。

- 既に消えたもの: `bbdb2` `jde` `nxml-mode`。2026-09-12 に emacs21 と一緒に
  消えた。三本とも Makefile が emacs21 しか受け付けていなかったために、
  emacs21 が消えたとき一緒に消えた。どれも emacs20 で動く
- 消すと予告されたもの: tech-pkg@ の "new emacs framework in tree, some
  PKGNAMEs changed, some packages will be removed" で、どの (x)emacs 版でも
  建たないとして一週間後に消すと予告された 10 本のうち、木にあった 6 本
  (`vm` `ecb` `elscreen` `lookup` `emacs-jabber` `semantic`)。上流は
  2026-09-25 の時点でどれも `EMACS_VERSIONS_ACCEPTED= # empty` にされて
  いる。ここでは受け付け版を戻し、建たない原因を直した

tech-pkg での 2026-09-25 の返信で、上流の維持者は「emacs 考古学にはあまり
興味が無い」として dholland さんへ送るよう勧めています。

### 測ったもの

load は package が案内する入口 (`(require 'vm)` など) を読んでから、
package が `provide` する feature を一つずつ `require` した数です。
`-q --no-site-file` で、destdir の site-lisp を load-path の先頭に足し、
feature がその destdir から読まれたことまで見ています。

| package | Emacs | load | 読めないもの |
|---|---|---|---|
| `bbdb2` | 20.7, 21.4 | どちらも 20 中 16 | `reportmail` `gnuserv` `vm` を求める 3 つと、XEmacs 専用の `bbdb-xemacs` |
| `jde` | 20.7, 21.4 | どちらも 37/37 | |
| `nxml-mode` | 20.7 / 21.4 | 24/24 / 23/23 | (21 には `nxml-e20` が無いので一つ少ない) |
| `elscreen` | 20.7 / 30.2 | 12 中 11 / 12 中 10 | `elscreen-wl` (Wanderlust)。30.2 では `elscreen-dnd` も。当て物を当てない 20180321 でも同じく invalid-function で落ちる |
| `vm` | 30, 31 | 52 中 51 | `vm-w3m` (emacs-w3m) |
| `ecb` | 30 | 3/3 | |
| `lookup` | 20 | 24/24 | |
| `emacs-jabber` | 30, 31 | 70/70 | |
| `semantic` | 20 | 25/25 | |

上の四本は 2026-09-27、下の五本は 2026-09-26 の数字です。

### bbdb2

2.35 は Emacs 23 より前の Emacs 向けの最後の BBDB で、今の Emacs には
bbdb3 があります。emacs20 と emacs21 を受け付けます。

Emacs 20 には当て物が二本要ります。`bbdb-hooks.el` が `mail-parse` を
読むが、これは Gnus 5.8 のもので Emacs 20.7 は 5.7 を積んでいる。
`bbdb-rmail.el` は `rmailsum` を require するが、Emacs 20 の `rmailsum.el`
はそれを provide しない。どちらも Emacs 21 では何も変えません。

2026-09-25 に二つ直しました。`--with-emacs` を xemacs の腕でしか渡して
おらず、GNU Emacs では configure が `PATH` の emacs を拾っていた。木に
emacs30 が入っていると emacs20 の package を建てているのに emacs30 が走り、
その `2>&1` に混ざる起動メッセージが configure の出力ごと `lisp/Makefile`
へ書き込まれて、bmake が `Invalid line "Loading site-init..."` で落ちる。
併せて `bbdb-autoloads.elc` が PLIST に無かった。

XEmacs は受け付けません。XEmacs を受け付けるのに
`CONFLICTS+= xemacs-packages-[0-9]*` を持ち、XEmacs 向けに建てるのに要る
`timezone` を配るのはその package だけなので、XEmacs では原理的に建た
なかった。bbdb は xemacs-packages に入っているので、XEmacs ではそちらを
使います。

### jde

emacs20 と emacs21 を受け付けます。Emacs 20 では elib が
`devel/emacs20-elib` という別の package なので、依存をそこで分けています。

止まっていたのは四つでした。semantic が建たなかった (下の semantic の節)。
makefile の `EMACS = emacs` が PATH の Emacs を使っていた。上流の
`PKGSRC_MAKE_ENV+= EMACS=${EMACS}` も、それを直したつもりの
`MAKE_ENV+= EMACS=${EMACS_BIN}` も効いておらず、makefile の中の代入は環境に
勝つので、`MAKE_FLAGS` で渡すほかない。`jde-new-buffer-menu` の `:set` が
batch では無い Files menu に項目を足そうとして `keymapp nil` で止まるので、
当て物で menu が在るときだけにする。依存の path が `devel/elib` を指して
いたが、Emacs 20 向けの名前は `emacs20-elib` で、それは
`devel/emacs20-elib` にある。

compile の失敗を無視しないよう makefile の `-` を外しました。以前の
「37 file が byte-compile する」は確かめられません。jde の makefile は
compile の行を `-$(EMACS)` と書いていて、失敗しても build が進み `.el`
だけを入れていたので、そう見えただけの可能性が高い。今は 20.7 でも 21.4
でも 37 本全部が `.elc` になります。PLIST は版の無い
`share/emacs/site-lisp/jde` を書いていて、建てた結果から取り直しました。

木の devel/elib も `EMACS=${EMACS_FLAVOR}` で素の `emacs` を使うので、
emacs20 向けを別の Emacs が compile します。これは elib 側の問題で、ここ
では直していません。

emacs21 で建てるには、木の editors/speedbar と lang/eieio と
`zakinko/semantic` が emacs20 しか受け付けないので、そのままでは依存が
通りません。21.4 の数字は、その三つと devel/elib を
`EMACS_VERSIONS_ACCEPTED=emacs21nox` で建てて入れた上で測ったものです。
jde 自身も受け付けは `emacs21` (X 付き) で、測ったのは emacs21-nox11 です。

2026-09-26 の emacs20 の測定は、Java を PKG_JVM=openjdk21 にして行いました。

### nxml-mode

emacs20 と emacs21 を受け付けます。当て物は Emacs 20 のときだけ働く形に
なっていて、Emacs 21 では何も変えません (`schema/xhtml-legacy.rnc` の
一本は Debian からの schema の直しで、どちらにも効く)。

Emacs 20 では、source が `#x` を 14,490 回使っていて、Emacs 20 の reader に
その syntax が無いので、当て物ではなく `post-patch` の一手で十進に変えます。
`elisp-compat` が Emacs 21 の関数を供給し、`mule-ucs` が `decode-char` を
供給します。

2026-09-26 に測り直すと、当て物 8 本がどれも distinfo に無く、
"Ignoring patch file ... no checksum found" と言われて一本も当たって
いなかった。案内どおり `rng-auto.el` を読むと "FSF GNU Emacs version 21
or later required" で止まり、何も使えなかった。distinfo を直すと 24 の
feature が全部 load できる。2026-09-25 の「12 中 10」は、入口を通さずに
feature を直に読んだ数字だった。

Emacs 21 では、同梱の Makefile が `EMACS=emacs` で compile するので、
`bin/emacs` が指す別の Emacs が `.elc` を作っていました。`EMACS_BIN` を
渡します。

### elscreen

knu/elscreen の 20180321 一つで、emacs20 と emacs29〜31 を受け付けます。
以前は emacs20 向けに 1.4.6 を別に置いていました。

1.4.6 は「apel が emacs20 を支えない」という理由で `BROKEN` にされていた。
上流の `devel/apel` は 2020 年の版で、その年に落とされた Emacs 20 と
XEmacs の互換層が入っていない。層を戻した apel なら建つが、建っても
Emacs 20 では load できなかった。`booleanp` と `add-to-list` の三つ目の
引数で止まり、`propertize` と `elscreen-dnd` の `mapc` も無い。2026-09-25
の「10 中 9」は、load-path に入れた destdir に `.elc` が無く、箱に入って
いた別の elscreen を読んでいた測定の誤りで、直したあとの 1.4.6 が 10 中 9
だった (2026-09-26)。

20180321 は apel を使わず、`Package-Requires` は Emacs 24 ですが、Emacs 20.7
で止めるのは 1.4.6 と同じ二つに加えて、`mapc` `window-list`
`called-interactively-p` `declare-function` `help-print-return-message`
`apply-partially` が無いことと、`make-obsolete-variable` が三つ目の引数を
取らないことだけでした。当て物で、無いときだけ定義します。`mapc` を
elscreen の中で定義するので、1.4.6 の `elscreen-dnd` に当てていた SUBST
は要りません。Emacs 20 には header line が無いので、tab は出ません。
20.7 と 30.2 で、screen を作って移って消し、help を出すところまで動かしています。

2026-09-27 に一つにまとめるとき、`PKGNAME` に `EMACS_PKGNAME_PREFIX` を
付けました。emacs20 向けと emacs30 向けが同じ名前の別物にならないように
するためで、1.4.6 は上流でもそうしていました。

### vm

2026-09-26 に 8.3.2 (2025-12-29、gitlab の emacs-vm) へ上げた。8.2.0b に
足していた当て物 4 本 (info 2 本、vm-folder、vm-pcrisis) はどれも上流で
直っていた。gitlab の tarball には生成済みの configure が無いので autoconf
を回す。configure は Emacs を `--with-emacs` か PATH の `emacs` で決める
ので、版付きの `EMACS_BIN` を渡す。8.3 の texinfo は NetBSD の makeinfo 4.8
では node の検査で落ちるので texinfo 5 を求める。8.3 は bin/base64-encode
などの補助 program を持たず、変換を Emacs の中でする。

### ecb

2.50 (GitHub の 1330a44) のままでは emacs30 で建たない。`defmethod` が
Emacs 29 で `lisp/obsolete/eieio-compat` へ移り、その先も
`button-release-event` など XEmacs の型で止まる。上流の 2.52 はどちらも
直っていて、emacs-updates branch の直しをそのまま使った。2026-09-25 の
「3/3」は 2.52 を測った数字で、当時の branch の 2.50 ではなかった。

### lookup

emacs20 で建ち、24 の feature が全部 load できる (`stem` は
`stem-english.el` が provide するので file 名で読む)。configure が PATH の
`emacs` を拾うので、emacs20 向けの build を別の Emacs が byte-compile して
いた。`--with-emacs` で版付きの binary を渡す。1.4.1 は Emacs 27 で消えた
古い backquote `(\` (...))` を使うので、今の Emacs では建たない。実行には
eblook が要る。

### emacs-jabber

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

### semantic

emacs20 で建ち、25 の feature が全部 load できる。2026-09-25 に
「speedbar 0.15 の変数を求めるが木には 0.14 しかない」と書いたのは誤り
だった。`speedbar-dynamic-tags-function-list` は入っている 0.14beta4 にも
在る。build が `EMACSLOADPATH` で Emacs 自身の `lisp/` を site-lisp より
前に置くので、Emacs 20 に同梱の speedbar 0.8 が先に見つかっていた。
semantic の Makefile は `LOADPATH` の dir を `add-to-list` で足すが、
site-lisp の下の dir は既に load-path の後ろに在るので何も起きない。
当て物で `setq` と `cons` にして前へ置き、`LOADPATH` に入っている speedbar
と eieio の dir を渡す。手を加えていない木でも落ちたのは同じ理由。

### undo-tree と queue-el

wip/undo-tree は 0.3 (2012) を 0.8.2 (2024-03-31、GNU ELPA) へ上げた。0.8 は
GNU ELPA の `queue` を求め、pkgsrc には無いので queue-el (0.2、
2024-03-31) を新しく作った。emacs30 と emacs31 で建ち、
`global-undo-tree-mode` のもとで undo と redo が期待どおり動く (a、b と
入れて undo で "a"、redo で "ab")。

### 測った機械

NetBSD 11.0 amd64 (techne)。

2026-09-26 の数字は、emacs20 から emacs31 と xemacs214/215 が同居している
箱で、当時の branch の file から建て直して測りました。modules.mk は版付きの
EMACS_BIN と lisp の置き場を返す枠組みのもの (上流の 1.42 系)。

2026-09-27 の四本は、箱の /usr/pkg を使わず、Emacs 20.7 と 21.4 と 30.2 を
それぞれ別の私的な prefix に建てて、その中で依存ごと建てました。20.7 と
30.2 は `/usr/pkgsrc` の modules.mk のまま、21.4 は上流の modules.mk が
emacs21 を知らないので、ここの `emacs/modules.mk` を差し込んだ木で建てて
います。jde の Java の依存 (java-vm.mk) は測定では外しました。

## anthy-unicode

anthy 9100h は 2009 年で止まっています。`anthy-unicode` は Takao Fujiwara
さんが引き継いだ fork で、今も出ています (`1.0.0.20260213`)。名前のとおり
内部の符号化を EUC-JP から UTF-8 に移したものです。

```elisp
;; anthy 9100h  anthy.el:750 — agent とのパイプを EUC-JP に固定する
(if (coding-system-p (find-coding-system 'euc-japan))
    (set-process-coding-system proc 'euc-japan 'euc-japan))

;; anthy-unicode  anthy-unicode.el:757 — 同じところが丸ごとコメントアウト
;;	    (if (coding-system-p (find-coding-system 'euc-japan))
;;		(set-process-coding-system proc 'euc-japan 'euc-japan))
```

入るものは全部 `-unicode` 付きなので、**anthy と同時に入れられます**。

| anthy 9100h | anthy-unicode |
| --- | --- |
| `bin/anthy-agent` | `bin/anthy-agent-unicode` |
| `lib/libanthy.so` | `lib/libanthy-unicode.so` |
| `share/emacs/site-lisp/anthy/anthy.el` | `.../anthy-unicode/anthy-unicode.el` |
| 入力メソッド `japanese-anthy` | `japanese-anthy-unicode` |

agent に直に投げると符号化の差が見えます。

```
$ printf 'nihongo\n' | anthy-agent-unicode
(2 ((UL) "にほんご" -1 -1) cursor)

$ printf 'nihongo\n' | anthy-agent | od -c
( 2   ( ( U L )   " 244 313 244 333 244 363 244 264 " ...   ← EUC-JP
```

pkgsrc の `inputmethod/anthy` / `inputmethod/anthy-elisp` に倣って二つに
割ってあります。C 側は `EMACS=no` で建て、elisp 側だけが `EMACS_TYPE` に
依存します。

こちらが 9100h に当てている廃止シンボル六つも旧式 backquote も、向こうでは
直っています。代わりに**逆向きの当て物**が要ります
(`anthy-unicode/patches/patch-src-util_anthy-unicode.el`)。9100h が emacs29 で
落ちるのと鏡像で、向こうが改名で直した名前が emacs20 と emacs21 にはまだ
無いためです。

| 名前 | 入ったのは | emacs20/21 での姿 |
| --- | --- | --- |
| `set-face-underline` | Emacs 22.1 | 20 は `set-face-underline-p` だけ。top level なので load が止まり `.elc` が二本落ちる |
| `mapc` | Emacs 21 | 9100h は同じ行で `mapcar` を使っていた |
| `set-process-query-on-exit-flag` | Emacs 22.1 | 20/21 は `process-kill-without-query`。最初の変換で死ぬ |
| `deactivate-current-input-method-function` / `deactivate-input-method` | Emacs 24.3 で改名 | 20/21 は `inactivate-*`。入力メソッドから抜けられない |

上のコメントアウトされた三行も当て物で埋めてあります。agent との pipe に
`utf-8` を明示しないと、Emacs 21 で Japanese language environment のときに
既定の euc-jp で decode され、変換結果が文字化けして返るためです。

NetBSD 11.0/amd64 で emacs20 21 26 28 29 30 31 で建て、`nihongo` が `日本語`
になり、`deactivate-input-method` のあと `input-method-function` が nil に
戻って続けて打った `abc` がそのまま入ることを確かめました。

**emacs20 と emacs21 には `editors/mule-ucs` が要ります。** agent は UTF-8 で
しか話しません (`src-util/input.c` が `ANTHY_UTF8_ENCODING` を無条件に設定
する。`--eucjp` は `--egg` の道にしか効かず、elisp はその道を使わない)。
ところが Emacs 20 に `utf-8` という coding system は無く、Emacs 21 の
`mule-utf-8` は CJK を落とせません。mule-unicode-* は U+0100〜U+33FF と
U+E000〜U+FFFF しか覆わず、U+4E00〜U+9FFF がどこにも入らないためで
(`utf-translate-cjk` は Emacs 22 から)、`日本語` の 9 バイトが eight-bit の
まま素通しします。同じ理由で 21 の byte-compiler が書いた `.elc` も読み戻せ
ません。mule-unicode の内部表現 (先頭 `0x9C` の 4 バイト) をそのまま書き出す
ためです。Mule-UCS の `utf-8` は CJK を japanese-jisx0208 に落とすので、
これで両方とも通ります。Makefile は `EMACS_VERSION_MAJOR < 22` のとき
Mule-UCS を `DEPENDS` に入れ、byte compile にも `-l un-define` を先に
食わせます。

Mule → Mule-UCS と anthy → anthy-unicode は同じ形の移り変わりで、しかも
前者が無いと後者は古い Emacs に載りません。

FreeBSD は `japanese/anthy` を削除して `japanese/anthy-unicode` だけに、
Debian は `anthy` のソースパッケージ自体を anthy-unicode 1.0.0 に差し替えて
います。Gentoo は `app-i18n/anthy` (9100h-r3) と `app-i18n/anthy-unicode` の
両方を持っています。9100h だけなのは pkgsrc と OpenBSD です。

## mozc-elisp226 の依存が両方向に狂っている

`inputmethod/mozc-elisp226` が入れるのは三つだけです。

```
bin/mozc_emacs_helper
share/emacs/site-lisp/mozc.el
share/emacs/site-lisp/mozc.elc
```

0.85MB の package です。それが **GTK2 と Qt5 と glib2 と zinnia と curl を
引きます**。gtk2 が X11 を要求するので、X を入れていない箱では

```
ERROR: [bsd.pkg.mk] mozc-elisp-2.26.4282.100nb46 uses X11, but /usr/X11R7 not found
```

で fetch にも進めません。ところが `ldd` を取ると、

```
/usr/pkg/bin/mozc_emacs_helper   -lstdc++ -lm -lc -lgcc_s -lpthread
/usr/pkg/libexec/mozc_server     -lstdc++ -lm -lc -lgcc_s -lpthread
```

**どちらも base の共有ライブラリしか使っていません。** GUI を引いているのは
`inputmethod/mozc-server226/Makefile.common` が無条件に buildlink している
だけで、`mozc-tool226` (Qt の設定 GUI) と `mozc-renderer226` (GTK の候補窓)
のためのものです。

逆に、**本当に要る `mozc-server` への依存がありません**。`mozc.el` は
`mozc_emacs_helper` を起動するだけで、変換は helper が `mozc_server` に
投げます。server が無いと

```
(1 CreateSession) → ((emacs-event-id . 1)(emacs-session-id . 1)(output . ()))
(2 SendKey 1 97)  → ((error . session-error)(message . "Session failed"))
```

と、セッションは作れるのに最初の一打で落ちます。**helper だけ入れても動かない**、
という形です。

**この応答は二つの原因で出ます。** server が無いときと、**root で動かした
とき**です。mozc は root を拒みます。`base/run_level.cc:268` に

```c
if (::geteuid() == 0) {
  // This process is started by root, or the executable is setuid to root.
  return RunLevel::DENY;
}
```

があるためで、server が正しく入っていても root から叩けば一字一句同じ
`Session failed` が返ります。**出力だけでは区別がつきません。** 依存を直した
かどうかを確かめるときに root で試すと、直っていないと読んでしまいます。
CI の VM は中が root なので、実際にここで一度落ちました。一般ユーザを
作って測る必要があります。

ここではその両方を直しました。

| | 上流 nb46 | ここ nb47 |
| --- | --- | --- |
| 依存 | emacs30, curl, glib2, gtk2+, qt5-qtbase, zinnia | **emacs30, mozc-server** |
| X11 | 要る | **要らない** |
| `EMACS_VERSIONS_ACCEPTED` | emacs29〜31 (rev 1.25 で追いついた) | emacs29〜31 |

GUI を切るには三箇所要りました。

1. `Makefile.common` の buildlink を `.if !defined(MOZC_NO_GUI)` で囲う
2. `build_mozc.py gyp` に `--noqt` を渡す。渡さないと
   `CRITICAL: Qt is required to build GUI Tool. Specify --noqt to skip` で止まる
3. `gyp/defines.gypi` の `'enable_gtk_renderer%': '1'` を `'0'` に落とす。
   `renderer.gyp` が gyp を走らせた時点で `pkg-config gtk+-2.0` を呼ぶため。
   NetBSD でその枝に入るのは pkgsrc の `patch-renderer_renderer.gyp` が
   `target_platform=="NetBSD"` を足しているから。`build_mozc.py` は任意の
   `-D` を素通ししないので、既定値の側を落とすしかない

`renderer.gyp` を消す手は使えません。`gui.gyp` `gyp/tests.gyp` `mac.gyp`
`unix/ibus/ibus.gyp` が `dependencies` で参照していて、gyp が not found で
死にます。

### 測ったもの

手元の箱では測りきれません。emacs は `bin/ctags` などが衝突して複数版を同時に
入れられず、`mozc-server` も 2.26 と 2.29 が PKGBASE を共有していて同居
できないからです。三版で測るには入れ替えを繰り返すことになり、同じ箱で
動いている他の作業を巻き込みます。job ごとに別の VM なら、その全部が
起きません。`NetBSD-i386` の `ci/netbsd-mozc226.sh` と
`.github/workflows/mozc226.yml` がそれで、`amd64-11.0` の image を使うので
送る PR の `>Environment` 行とも揃います。

出来た binary package そのものが証拠になります。

```
mozc-server-2.26.4282.100nb46.tgz
  中身      libexec/mozc_server ただ一つ
  ldd       -lstdc++ -lm -lc -lgcc_s -lpthread
  @pkgdep   0 本                      ← 実行時依存なし
  @blddep   digest py-gyp py-six ninja-build python313
            mktools gmake pkgconf cwrappers
```

上流の同じ package は `curl` `glib2` `gtk2+` `qt5-qtbase` `zinnia` の五本を
実行時依存として記録します。`buildlink3.mk` が `BUILD_DEPENDS` ではなく
`DEPENDS` に入れるので、`pkg_add` でも付いてきます。

`MOZC_NO_GUI` を書かない側が本当に何も変わらないことも測りました。この
`Makefile.common` を読む写しと本家側とを `make show-all` にかけ、package の
path を揃えて突き合わせると一行も動きません。

```
ibus-mozc226      3738 行中 差 0 行
mozc-renderer226  3716 行中 差 0 行
mozc-tool226      3722 行中 差 0 行
uim-mozc226       3788 行中 差 0 行
```

展開後の `do-configure` も `WRKDIR` の path を除いて同一で、gyp の呼び出しは
両方とも `build_mozc.py gyp --gypdir=/usr/pkg/bin` になります。`--noqt` は
付きません。この `Makefile.common` を読むのは六つだけで、`fcitx5-mozc226` は
存在せず、2.29 の `fcitx5-mozc` と `uim-mozc` は自前の `Makefile.common` を
持っていて入れ子にもしていません。

変換は `mozc-server` を入れたうえで helper に protocol を直に投げて
確かめました (root ではなく一般ユーザで)。

```
a → あ
i → あい      候補: 愛
u → あいう    候補: あいうえお / アイウェア / 相打ち
```

`(require 'mozc)` は要ります。`(setq default-input-method "japanese-mozc")`
だけでは効きません。ただしこれは欠陥ではなく、pkgsrc の `MESSAGE` が

```elisp
(set-language-environment "Japanese")
(require 'mozc)
(setq default-input-method "japanese-mozc")
```

と案内しているとおりです。上流の `mozc.el` も、読み込まれた時点で
`mozc-leim-register-input-method` をその場で呼ぶ作りになっています
(`emacs-startup-hook` に足すのと両方)。この三行だけで `nihongo` が `日本語`
になるところまで確かめました。

FreeBSD は `japanese/mozc-server/files/leim-list.el` を自前で持ち、`mozc.el`
に当て物をして `mozc-leim-activate` を名前付き関数に変えることで、
`(require 'mozc)` を書かずに済むようにしています。Gentoo は
`50mozc-gentoo.el` で autoload を張り、Debian は emacsen-common で見ています。
pkgsrc に同じ便宜を持ち込むかどうかは、直しというより方針の話なので、ここでは
手を付けていません。

## 引き取った emacs26 / emacs27 / emacs28

2026 年 8 月 25 日に、本家 pkgsrc から `editors/emacs26` `emacs27` `emacs28` と
それぞれの `-nox11` が消えました。ここにあるのは削除直前の版です。相対パスだけ
`../../editors/emacsNN` から `../../zakinko/emacsNN` に振り替えてあります。

そのままビルドして入れられます。

```sh
cd /usr/pkgsrc/zakinko/emacs28-nox11
make install
```

`EMACS_TYPE=emacs28nox` として他のパッケージから使うこともできますが、
そのままでは通りません。どの Emacs を使うかを決めているのは
`editors/emacs/modules.mk` の二つの表で、削除と同時にそこからも落ちたためです。

```
ERROR: Accepted versions are: emacs21 emacs21nox emacs20 xemacs215 ...
ERROR: No valid Emacs version installed found
```

カテゴリの外にある `.mk` なので、こちらから書き足すことはできません。ただし
`_EMACS_PKGDIR` は make の引数で上書きできるので、`.mk` を触らずに済みます。

```sh
cd /usr/pkgsrc/zakinko/anthy-elisp
make EMACS_TYPE=emacs26nox \
     EMACS_VERSIONS_ACCEPTED=emacs26nox \
     _EMACS_PKGDIR=../../zakinko/emacs26-nox11 \
     package-install
```

コマンドラインの変数は makefile の代入に勝つので、`modules.mk` の中の
`_EMACS_PKGDIR=` より後に効きます。版ごとの `_EMACS_FLAVOR` `_EMACS_REQD`
`EMACS_VERSION_MAJOR` は指した先の `version.mk` が持つので、これで足ります。
`EMACS_VERSIONS_ACCEPTED` も一緒に渡すのは、パッケージ側の一覧が
`modules.mk` の現状に合わせて emacs29 以降になっているためです。

NetBSD 11.0/amd64 で、この形で `anthy-elisp` を emacs26 emacs27 emacs28 の
三つとも建てて動かしました。Emacs 自体は本家の binary package をそのまま
使えます (`emacs26-nox11-26.3nb1` など、11.0/amd64 のセットに在ります)。

恒久的に選べるようにしたい場合は、本家の `modules.mk` に二行書き戻す方が
早いです。

```make
_EMACS_VERSIONS_ALL+=	emacs26 emacs26nox emacs27 emacs27nox emacs28 emacs28nox

_EMACS_PKGDIR_MAP+= \
	emacs26@../../zakinko/emacs26 \
	emacs26nox@../../zakinko/emacs26-nox11 \
	emacs27@../../zakinko/emacs27 \
	emacs27nox@../../zakinko/emacs27-nox11 \
	emacs28@../../zakinko/emacs28 \
	emacs28nox@../../zakinko/emacs28-nox11
```

## anthy-elisp をどの Emacs で確かめたか

`zakinko/anthy-elisp` を `EMACS_TYPE` ごとに実際に建てて入れ、変換して、
入力メソッドから抜けるところまで見ています。NetBSD 11.0/amd64 です。

| EMACS_TYPE | 版 | `.elc` | 変換 | 抜ける |
| --- | --- | --- | --- | --- |
| emacs20 | 20.7.1 | 7 | 日本語 | ○ |
| emacs21nox | 21.4.1 | 7 | 日本語 | ○ |
| emacs26nox | 26.3 | 6 | 日本語 | ○ |
| emacs27nox | 27.2 | 6 | 日本語 | ○ |
| emacs28nox | 28.2 | 6 | 日本語 | ○ |
| emacs29nox | 29.4 | 6 | 日本語 | ○ |
| emacs30nox | 30.2 | 6 | 日本語 | ○ |
| emacs31nox | 31.1 | 6 | 日本語 | ○ |

`.elc` が 20 と 21 だけ 7 本なのは `leim-list.elc` の分です。`modules.mk` の

```make
FOR_emacs_no_byte_compile="${${EMACS_VERSION_MAJOR}>22:?@comment :}"
```

で 23 以降は PLIST から外れます。どの版でも PLIST と一致しました。

「抜ける」は `activate-input-method "japanese-anthy"` で入り、変換・確定して
から `deactivate-input-method` し、`current-input-method` と
`input-method-function` と anthy 側の `anthy-leim-active-p` が三つとも nil に
戻り、続けて打った `abc` がそのままバッファに入ることを見ています。

ここを見るのは、当て物が相手にしている壊れかたの一つが**変換はできるのに
入力メソッドを切れない**という形だからです。`anthy.el` の 867 行が
`inactivate-current-input-method-function` に代入していますが、この変数は
Emacs 24.3 で改名され、旧名の alias は 29 で消えました。29 以降は代入が
どこにも届かず、`deactivate-input-method` が

```
Symbol's function definition is void: nil
  nil()
  deactivate-input-method()
```

になります。ビルドを止める `set-face-underline-p` だけ直すと必ずここに来ます。
境界はちょうど Emacs 29 で、26 27 28 では起きません。

emacs20 は `zakinko/emacs20` (nb28) が要ります。本家の nb26 では LP64 の
切り詰めで `set-language-environment "Japanese"` の時点で落ちるためです。

## emacs20 と emacs21 に積み残しの CVE を当てる

`zakinko/mule2` が三本の CVE を当てているのと同じ理由で、`editors/emacs20` と
`editors/emacs21` にも積み残しがあります。mule2 は Mule 2.3 / Emacs 19.28
ベースで、20.7 と 21.4 は同じ古い lib-src と src を引きずっているので、mule2 に
当てた当て物のうち二本がそのまま該当します。`pkg_admin audit` は emacs21 を
三件で挙げますが (下記)、emacs20 は一件も挙げません。DB に emacs20 の項目が
無いだけで、コードは同じように穴が開いています。

| CVE | 何 | emacs20 | emacs21 |
| --- | --- | --- | --- |
| CVE-2022-45939 / 48337 | etags が `-o` の引数などを無引用で `system(3)` に渡す | 当てる | 当てる |
| CVE-2017-1000383 | copy-file が `creat(...,0666)` の後で `chmod`。一瞬 world-readable、setuid も継承 | 当てる | 当てる |
| CVE-2008-1694 | vcdiff が `/tmp/geta$$` に `>` で書く | 済 (mktemp) | 済 (mktemp) |
| CVE-2017-14482 | enriched の `x-display` で任意 Lisp 実行 | 非該当 | 済 (tree) |

vcdiff は両版とも既に `mktemp` に直っています (emacs20 は dholland の jumbo
patch、emacs21 は tree の patch-xx)。enriched は emacs20 には脆弱なコードが
無く、emacs21 は tree が `patch-CVE-2017-14482` で当てています。残る二本を
`zakinko/mule2` と同じ形で当てました。

etags の方は mule2 より穴が広い。mule2 では file-name を回すループが optind を
argc まで進めた後で回るので死んでいますが、20.7 と 21.4 は `argbuffer[]` を
`current_arg` で回すので生きています。加えて 21.4 の etags は圧縮ファイルを
展開するとき、そのファイル名を無引用で `gzip -d -c <名前>` に渡して `popen`
します。`etags *` が `a;cmd.gz` のような名前のファイルに当たると `cmd` が
走ります。`sort %s -o %s` (mule2 と同じ) と file-name と、この圧縮経路の三つを
`shell_quote()` で塞ぎました (20.7 の etags には圧縮経路が無く、二箇所)。
`etags 'a;touch GOTCHA;.gz'` が当てる前は `GOTCHA` を作り、当てた後は作らず、
普通の `.gz` は中身を読めることを確かめました。

NetBSD 11.0/amd64 で、当てる前は

```
$ ctags -u -o 'tags;touch /tmp/pwned' file.c
```

が `/tmp/pwned` を作りました。当てた後は `tags;touch /tmp/pwned` という名前の
ファイルが出来るだけで何も走りません。普通の `-o out.tags` は変わらず効きます。
copy-file は、04755 のファイルを `(copy-file "src" "dst" t)` で写すと、当てる
前は 04755 (setuid) の写しが出来、当てた後は 0755 になって setuid が落ちます。
どちらも emacs20.7 と emacs21.4 を自前で建てて確かめました。

本家 pkgsrc にも send-pr で出します。mule2 と違ってこの二つは今も配られている
版なので、fork に留めず tree に戻すのが筋です。

## emacs20 の宣言もれ

`zakinko/emacs20` が上流と違うのは当て物 2 本だけです。amd64 のような LP64 で

```
Wrong type argument: stringp, 8510432
```

が出て、`set-language-environment "Japanese"` が通らなくなるのを直します。
中国語と韓国語も同じで、Greek や Latin-1 は通ります。anthy を読み込む前に
落ちるので、日本語入力そのものが立ち上がりません。i386 では起きません。

`Lisp_Object` を返す関数がどこにも宣言されておらず、暗黙の int 戻り値で
64bit が 32bit に切り詰められて、型タグ (bit 60-62) が落ちています。

```
call   code_convert_string_norecord
movslq %eax,%r8            ← ここ
```

多くの呼び手は結果をすぐ `XSTRING()` に渡し、そこでタグを外すので偶然
動きます。`openp` だけは `Ffind_file_name_handler` に渡すので、`CHECK_STRING`
がタグ無しのポインタを整数として見て落ちます。`openp` に `ENCODE_FILE` を
入れているのは pkgsrc が当てている Mule 4.1b の配布パッチです。

`prefer-coding-system` が `default-file-name-coding-system` を立てた瞬間から
**相対 `load` が全部落ちます**。`(load "subr")` すら通りません。Greek が無事
なのは `features` を持たず追加の読み込みが起きないからでした。

同じ切り詰めが `Fcurrent_message` `Fcurrent_time` `Fset_buffer_multibyte`
`Fwindow_end` にもあります。`Fcurrent_message` は `read_char` の入力メソッド
経路にあるので、これも日本語入力に効きます。

直しは自分で考えたものではありません。**Emacs 21 が 5 本とも宣言しています。**

	2000-06-05  Dave Love  <fx@gnu.org>
		* coding.h: Declare code_convert_string_norecord.

20.7 の公開は 2000-06-13 で、8 日後です。emacs-20 の枝には来ませんでした。
`lisp.h` の節の並びが 20.7 と 21.1 でほとんど同じなので、行も置き場所も
Emacs 21 のまま写してあります。

NetBSD 11.0/amd64 で、当て物ありの emacs20-20.7nb27 は Japanese,
Chinese-GB, Korean, Greek, Latin-1, English のすべてが通り、anthy で
`nihongo` が `日本語` になります。当て物なしの nb26 は Japanese で落ちます。

i386 では何も変わりません。NetBSD 10.1/i386 で建てて確かめました。ILP32 では
`int` も `Lisp_Object` も 32bit なので、戻り値が `%eax` のまま素通りします。

```
i386   mov    %eax,-0x10c(%ebp)      ← 切り詰めが起きない
amd64  movslq %eax,%r8               ← ここで 32bit になる
```

当て物ありの nb27 と、公式バイナリの nb26 とで、`openp` (264 命令)、
`Ffind_file_name_handler` (91)、`read_char` (1862)、`Fset_window_buffer` (151)、
`Fset_buffer_multibyte` (279) の機械語が完全に一致します。素の nb26 も 6 つの
言語環境がすべて通るので、i386 にはそもそもこの壊れ方がありません。

上の測定はいずれも nb27 で採ったものです。nb28 は CVE の当て物二本を足した
だけで、LP64 の当て物 (`patch-src_coding.h` と `patch-bj`) には触れていないので、
結果はそのまま通ります。

## 対象

NetBSD で動かすことを前提にしています。

meibo は純 Go（cgo なし）なので `netbsd/amd64`, `netbsd/arm64`, `netbsd/386`
でそのままビルドできます。

nss_stns は pkgsrc が FreeBSD と DragonFly にも bootstrap できることを踏まえ、
`OPSYS` からモジュール名 (`nss_stns.so.0` / `nss_stns.so.1`) を決めるので、
同じパッケージディレクトリで三者に通ります。

mule2 だけは自作ではなく、本家から引き取ったものです。NetBSD 9.4/i386 (gcc 7.5)
と NetBSD 11.0/amd64 (gcc 12.5) の両方で、端末のみの構成と X11 (Lucid) の構成が
ビルドでき、ダンプまで通って動きます。canna と wnn4 も両アーキテクチャで実際に
変換するところまで確認しました。ローマ字 `nihongo` が `日本語` に、読み
`にほんごのへんかん` が `日本語の変換` になります。

## nss_stns が `INSTALL` / `DEINSTALL` を持っている理由

libc は `dlopen("nss_stns.so.<version>")` を裸の名前で呼び、set-user-ID の
プログラムに対して ld.so は `/lib` と `/usr/lib` しか探しません。そのため
モジュールへの symlink が `/usr/lib` に要ります。無いと `su(1)` や `login(1)`
が STNS のアカウントを黙って引けなくなります。

`/usr/lib` は `PREFIX` の外で、どのパッケージマネージャも stage しません。
そこでパッケージは `NSSLIBDIR=${PREFIX}/lib` でビルドして upstream の
`make install` が張る symlink を止め、代わりに自分のフックから張ります。
pkgsrc では `INSTALL` と `DEINSTALL`、FreeBSD port では `pkg-plist` の
`@postexec` / `@postunexec` がそれです。

## stnsd と nss_stns を同じ機械に入れられる理由

`PKG_SYSCONFSUBDIR` が stnsd は `stns/server`、nss_stns は `stns/client` に
なっています。一台をサーバにもクライアントにもできるよう、設定ファイルの名前を
衝突させていません。素の `stns.conf` に平坦化していないのはこのためです。

stnsd の設定にはパスワードハッシュが入るので、`CONF_FILES_PERMS` で root 所有
0600 として置きます。

rc.d スクリプトは二重に持たず、upstream の `rc.d/stnsd.in` から `make` が
生成します。rc.conf のスイッチ名が NetBSD では `stnsd`、FreeBSD では
`stnsd_enable` と違うので、パスと一緒に変数名も差し替わります。おかげで
どちらのパッケージにも `files/` ディレクトリが要りません。

## mule2 が PIE と RELRO を切っている理由

`temacs` は起動に必要な Lisp を読み込んだ状態で `unexec()` を呼び、走っている
自分自身の ELF イメージを書き換えて実行ファイルとして吐き出します。初期化済み
データセグメントを丸ごと保存して、次回はそれをそのまま復元する方式です。

PIE はそのイメージを再配置してしまい、RELRO は `unexec()` が書き換えなければ
ならない領域を write-protect します。どちらもダンプを壊すので、パッケージの
`Makefile` で `MKPIE_SUPPORTED` と `RELRO_SUPPORTED` を `no` にしています。
FORTIFY の `__builtin_object_size` も、1995 年の pre-ANSI な文字列処理とは
同居できないので同様に切ってあります。

このあたりを緩めると、ビルドは通るのにダンプ済みバイナリが起動時に落ちる、
という分かりにくい壊れ方をします。

X (Lucid toolkit) の構成も通ります。i386 でも amd64 でも Xvfb 上で実際に
フレームが開き、`window-system` が `x` になることを確認しました。

2017 年に tsutsui が amd64 で「`mule -nw` は動くが Xt 版は core を吐く」と
記録しており、その原因を「LP64 で `Lisp_Object` を返す関数が宣言なしに呼ばれて
いて、暗黙の int 戻り値が 64bit の値を切り詰めている」と見て `src/lisp.h` に
宣言を 75 個足しました。NetBSD 11.0/amd64 で確認したところ、その core dump は
再現しません。EUC-JP を読ませて `forward-char` で数えると 8 文字ぶん進み、
ISO-2022-JP で書き出したバイト列も正しいので、多バイト文字が 64bit 環境でも
壊れていません。

## canna と wnn4 を実際に使うまで

パッケージが入れるのはクライアント側だけです。変換にはサーバと辞書が別に
要ります。

```sh
cd /usr/pkgsrc/inputmethod/canna-server    && make install
cd /usr/pkgsrc/inputmethod/canna-dict      && make install
cd /usr/pkgsrc/inputmethod/ja-freewnn-server && make install
```

`cannaserver` が `Initialize failed` としか言わずに落ちる場合、たいてい辞書の
置き場所です。辞書は `/usr/pkg/libdata/canna/` に入りますが、サーバが読むのは
`/var/dict/canna/canna/` です。`canna-dict` の導入時にそこへ複写されなかった
環境では、手で置いてやる必要があります。`ktrace` を当てると
`/var/dict/canna/canna/fuzokugo.cbd` の `open` が `ENOENT` で落ちているのが
見えます。

Wnn 側は `egg` が起動ファイルを探しますが、上流は候補である `eggrc-wnn` と
`eggrc-sj3` しか置かず、`eggrc` という名前のファイルを作りません。無いと egg は
辞書をひとつも登録しないまま止まるので、`wnn4` オプションが有効なときに
`eggrc-wnn` を `eggrc` として複写しています。

なお pkgsrc current は `Canna-lib>=3.8` を要求しますが、公式のバイナリ
パッケージは 11.0 / 10.0 とも `3.7pl3nb1` 止まりです (2026-05-25 ビルド)。
バイナリで済ませたい場合は `BUILDLINK_API_DEPENDS.Canna-lib` を緩めるか、
バイナリ集合と同じ枝の pkgsrc を使ってください。

## mule2 を NetBSD 以外の BSD で

pkgsrc は FreeBSD にも OpenBSD にも DragonFly にも bootstrap できるので、
mule2 もそこで通るのかを CI で見ています
([mule-otherbsd.yml](.github/workflows/mule-otherbsd.yml))。NetBSD 側と違って
pkgsrc そのものを組むところから始まり、バイナリパッケージも無いので依存は
全部その場で作ります。検査は NetBSD と同じ
[verify-mule.sh](.github/ci/verify-mule.sh) を通します。

まだ通りません。1995 年のツリーが 2026 年の BSD を知らないためで、止まる
場所がそれぞれ違います。

| | 見込み |
| --- | --- |
| FreeBSD | `patch-configure` が腕を足したので `configure` は通る。ただし上流の `s/freebsd.h` は a.out 時代のままで、`unexsunos4.o` と `pre-crt0.o` を使い、`PENDING_OUTPUT_COUNT` が `FILE` の中身を直接触る。FreeBSD の stdio はもう不透明なのでコンパイルで転けるはず |
| OpenBSD | `configure` に腕が無く `s/openbsd.h` も無い。OpenBSD の分岐がこのツリーより後なので当然で、unported で止まる |
| DragonFly | `patch-src_s_dragonfly.h` の `s/dragonfly.h` に初めて実際に届く。joerg が 2006 年に「DragonFly が無いので未確認」と書いたまま 20 年通っているもので、当たりが付くとすればここ |

赤いのは承知の上です。どこで止まっているかを毎回同じ形で読むための足場で、
緑にしていくのはこれからです。

i386 も一本だけ回しています。ILP32 のこのコードにとって i386 は本籍地で、
NetBSD 側でも 9.4/i386 が主戦場です。ただし借りられるイメージは amd64 と
aarch64 と riscv64 しかないので、公式に i386 の qcow2 を配っている FreeBSD
だけ、自前で QEMU を起動しています
([run-freebsd-i386.sh](.github/ci/run-freebsd-i386.sh))。鍵も cloud-init も
入っていないイメージなので、最初の一回だけシリアルコンソールから root で
入って公開鍵を置き、あとは ssh です。FreeBSD が i386 を配るのは 14 系まで
で、15.0 に i386 はありません。

OpenBSD の i386 は公式のイメージが無く、回すには自動インストールから
イメージを作ることになります。DragonFly は 4.0 (2014) で i386 を捨てて
いるので、そもそもありません。
