# mule

Mule 1.1 (帚木) — GNU Emacs 18.59 を多言語化した、Mule の最初の系統。19.28
ベースの 2.3 ([mule2](../mule2/)) の一代前にあたる。

## 配布物が世の中に残っていない

1.1 は 1994 年 3 月 8 日に、作者の handa さんが mule-jp メーリングリストの中
だけでリリースした。

> Mule Ver.1.1 をこの ML だけでリリースします。外部へのアナウンスは Patch 01
> になってからですね。
>
> おっと、肝心のことを書いていませんでしたが、
> `etlport.etl.go.jp:/pub/mule/mule-1.1.tar.gz` から持っていって下さい。

外へアナウンスされる前に 2.0α (同年 6 月) が来て、`/pub/mule` からは消えた。
ETL のドメインは 2001 年の産総研への統合で失われ、`ftp.m17n.org` も落ちて
いる。2.3 の写しは KAIST にも龍谷大にも今なお在るのに、**1.x はどの mirror にも
無い** — mirror が写した時点 (最古の痕跡が 1995 年 7 月) で、もう存在して
いなかったためである。配り方の違いが三十年後の残り方をそのまま決めている。

今その木を持っているのは [tsutsui/mule1.1-netbsd](https://github.com/tsutsui/mule1.1-netbsd)
で、2015 年 2 月の最初の commit が「Import stock mule-1.1 distribution」、続く
四本が ETL の公式パッチ 01〜04 である。tsutsui は 1998 年に NetBSD 1.3 の
{i386,sparc,sun3} 向け emacs-18.59 差分を current-users に出していて、その線が
そのまま今に続いている。素の木の `src/s-netbsd.h` は 14 行しかなく、しかも
3 行目のコメントが閉じていないので中身が全部死んでいる。今の木では 136 行に
書き直され、ダンプも emacs22 の `unexelf.c` に差し替えられている。

## この package

pkgsrc-wip の [mule11](https://github.com/NetBSD/pkgsrc-wip/tree/master/mule11)
(makoto@ki.nu) と、tsutsui 自身の写し
[pkgsrc-wip-mule11](https://github.com/tsutsui/pkgsrc-wip-mule11) があり、
新しい後者を土台にした。変えたのは四点。

- `GITHUB_TAG` を 20200918 から 20260622 へ
- `PKGNAME` を `mule11-` から `mule-` へ。ここでは 1.x が `mule`、2.3 が
  `mule2` という並びにしている。wip も 2015 年 10 月までは `mule` だった
- PIE と RELRO と FORTIFY を切る
- 効いていなかった `exclusive` option を直す

## ダンプが壊れる

`temacs` は起動に必要な Lisp を読み込んだ状態で `unexec()` を呼び、走っている
自分自身の image を書き換えて実行ファイルとして吐き出す。PIE はその image を
再配置し、RELRO は `unexec()` が書き換えねばならない領域を write-protect
する。切らずに建てると、コンパイルは全部通った上で

	Dumping under names xemacs and emacs-18.59.1
	make[2]: *** [xmakefile:54: xemacs] Segmentation fault

で落ちる。mule2 と同じ形である。

## exclusive option が一度も効いていなかった

`options.mk` が見ていたのは `PKG_OPTIONS:Mexclusives` で、option の名前は
`exclusive`、s は付かない。この綴りでは選んでも常に空になり、`post-install`
が `ctags` `etags` `emacsclient` を消す腕にいつも入る。2015 年からずっと
死んでいた。pkgsrc-wip の mule11 にも同じ綴りが残っている。

直すと、それに隠れていた二つが出てくる。

- `PLIST` の `bin/etag` (s 落ち)。`exclusive` のときだけ効く行なので
  `file-check` に掛からずにいた
- `CONFLICTS` の範囲。`emacs2[0-9]-[0-9]*` は emacs30 と emacs31 を掬わず、
  `emacs-nox11-30.2` や `emacs30-nox11-30.2nb1` のように `-nox11` が挟まる
  名前も外れる。`pkg_admin pmatch` で一つずつ当てて三本にした
  (`emacs-packages-0.12` は掬わないこと込みで)

既定では `ctags` `etags` `emacsclient` を入れないので emacs 系とはぶつからない。
そのため emacs の `CONFLICTS` は option の腕の中に置き、`Makefile` には
`mule2-[0-9]*` だけを残してある。1.x と 2.3 は option によらず `bin/mule` と
`bin/m2ps` と man を同じ名前で入れるため。

## 動くと分かっている範囲

NetBSD 11.0/amd64 で建てて `pkg_add` し、実際に動かした。1994 年の Emacs 18
系のコードが LP64 の x86-64 で動いている。

| 見たもの | 結果 |
| --- | --- |
| 版 | `18.59.1` |
| 日本語文字列の長さ | 3 文字が内部表現で 9 バイト |
| 日本語での検索・置換 | 通る |
| EUC-JP で書き出し | `306 374 313 334 270 354` |
| Shift_JIS で書き出し | `223 372 226 173 214 352` |
| JUNET (ISO-2022-JP) で書き出し | `ESC $ B F| K\ 8l ESC ( B` |
| 日本語入りの byte-compile | `.elc` から読み直して長さもバイト列も一致 |
| 五回起動して同じ結果か | 一致 |

判定に stderr は使っていない。結果ファイルの中身と、書き出させた符号化済み
ファイルの実バイトだけで見ている。

## 残っているもの

wip の TODO から引き継いだもの。

- canna に対応していない (`src/mconfig.h` の定義を option で振る)
- 中国語と韓国語の設定 (`site-init.el` を option で振る)
