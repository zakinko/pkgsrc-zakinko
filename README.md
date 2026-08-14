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
| [meibo](meibo/) | 日本の会社と学校のための ID ライフサイクル管理と SSO のサーバ |
| [mule](mule/) | 多言語 Emacs (Mule 2.3 / Emacs 19.28 ベース)。本家では 2022 年に削除済み |
| [nss_stns](nss_stns/) | STNS の名前解決スイッチモジュール |
| [stnsd](stnsd/) | 小さな STNS API サーバ |

どのパッケージも第二カテゴリを併記してあるので (`stnsd` は `zakinko` と
`security` の両方)、本家の分類でも探せます。

FreeBSD ports 版は [ports-zakinko](https://github.com/zakinko/ports-zakinko)
にあります。

## overlay

[overlay/](overlay/) は自作パッケージではなく、**上流 pkgsrc への当て物**を
置くところです。カテゴリの `Makefile` の `SUBDIR` には入れていないので、
`make` からは見えません。

```
overlay/textproc/libxml2/         2.15.1 → 2.15.3 (CVE 5 件)
overlay/sysutils/augeas/          CVE-2025-2588 の修正
overlay/inputmethod/anthy-elisp/  emacs26〜30 を受け付けるように
```

[NetBSD-i386](https://github.com/zakinko/NetBSD-i386) の CI が、この repo を
`zakinko` カテゴリとして重ねたあとに `overlay/` を上流のカテゴリへ上書き
コピーしてからビルドします。上流 pkgsrc が取り込んだら消します。詳しくは
[overlay/README.md](overlay/README.md)。

## 対象

NetBSD で動かすことを前提にしています。

meibo は純 Go（cgo なし）なので `netbsd/amd64`, `netbsd/arm64`, `netbsd/386`
でそのままビルドできます。

nss_stns は pkgsrc が FreeBSD と DragonFly にも bootstrap できることを踏まえ、
`OPSYS` からモジュール名 (`nss_stns.so.0` / `nss_stns.so.1`) を決めるので、
同じパッケージディレクトリで三者に通ります。

mule だけは自作ではなく、本家から引き取ったものです。端末のみの構成と X11
(Lucid) の構成の両方が、NetBSD 9.4/i386 (gcc 7.5) と NetBSD 11.0/amd64
(gcc 12.5) でビルドでき、ダンプまで通って動くことを確認しています。

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
