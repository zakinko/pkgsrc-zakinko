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
配布物の版が固定されていますし、`mule` のようにパッチが 100 個を超えるものは
そのチェックサムこそが中身の保証になるためです。

## 収録パッケージ

| パッケージ | 内容 |
| --- | --- |
| [emacs26](emacs26/) / [emacs26-nox11](emacs26-nox11/) | GNU Emacs 26.3。本家では 2026 年 8 月に削除済み |
| [emacs27](emacs27/) / [emacs27-nox11](emacs27-nox11/) | GNU Emacs 27.2。本家では 2026 年 8 月に削除済み |
| [emacs28](emacs28/) / [emacs28-nox11](emacs28-nox11/) | GNU Emacs 28.2。本家では 2026 年 8 月に削除済み |
| [meibo](meibo/) | 日本の会社と学校のための ID ライフサイクル管理と SSO のサーバ |
| [mule](mule/) | 多言語 Emacs (Mule 2.3 / Emacs 19.28 ベース)。本家では 2022 年に削除済み |
| [nss_stns](nss_stns/) | STNS の名前解決スイッチモジュール |
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
| [anthy-elisp/](anthy-elisp/) | `inputmethod/anthy-elisp` | emacs26〜30 を受け付けるように |
| [augeas/](augeas/) | `sysutils/augeas` | CVE-2025-2588 の修正と、lens が一本も入らないのを直す |
| [autogen/](autogen/) | `devel/autogen` | mmap の失敗を見ずに走査していたのを直す (CVE-2025-8746) |
| [fail2ban/](fail2ban/) | `security/fail2ban` | 1.1.1 へ上げ、2to3 と python 固定を外す (pkgsrc PR #175) |
| [libuuid/](libuuid/) | `devel/libuuid` | DragonFly で util-linux が組めるように |
| [ntp4/](ntp4/) | `net/ntp4` | 4.2.8p16 で直った境界外書き込みを当てる |
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

## 引き取った emacs26 / emacs27 / emacs28

2026 年 8 月 25 日に、本家 pkgsrc から `editors/emacs26` `emacs27` `emacs28` と
それぞれの `-nox11` が消えました。ここにあるのは削除直前の版です。相対パスだけ
`../../editors/emacsNN` から `../../zakinko/emacsNN` に振り替えてあります。

そのままビルドして入れられます。

```sh
cd /usr/pkgsrc/zakinko/emacs28-nox11
make install
```

ただし `EMACS_TYPE=emacs28nox` を選べるようにはなりません。どの Emacs を使うかを
決めているのは `editors/emacs/modules.mk` の二つの表で、削除と同時にそこからも
落ちているためです。カテゴリの外にある `.mk` なので、こちらから足せません。
手元で選びたい場合は本家側に書き戻してください。

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

版ごとの `_EMACS_FLAVOR` や `_EMACS_REQD` は各パッケージの `version.mk` が
持っているので、書き戻すのはこの二つだけで足ります。

## 対象

NetBSD で動かすことを前提にしています。

meibo は純 Go（cgo なし）なので `netbsd/amd64`, `netbsd/arm64`, `netbsd/386`
でそのままビルドできます。

nss_stns は pkgsrc が FreeBSD と DragonFly にも bootstrap できることを踏まえ、
`OPSYS` からモジュール名 (`nss_stns.so.0` / `nss_stns.so.1`) を決めるので、
同じパッケージディレクトリで三者に通ります。

mule だけは自作ではなく、本家から引き取ったものです。NetBSD 9.4/i386 (gcc 7.5)
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

## mule が PIE と RELRO を切っている理由

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

## mule を NetBSD 以外の BSD で

pkgsrc は FreeBSD にも OpenBSD にも DragonFly にも bootstrap できるので、
mule もそこで通るのかを CI で見ています
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
