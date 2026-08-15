# mule

Mule 2.3 — 多言語化された GNU Emacs 19.28。本家 pkgsrc から 2022 年 9 月に
削除されたものを引き取り、今の NetBSD で建って動くところまで直したもの。

## これは何で、なぜ別物だったのか

Mule (MULtilingual Enhancement to GNU Emacs) は電子技術総合研究所で作られた、
GNU Emacs への多言語化パッチ集である。当時の Emacs 18/19 には多バイト文字の
概念が無く、日本語だけを足した Nemacs (Nihongo Emacs) を任意の文字集合へ
広げたものが Mule だった。

**Emacs 20.1 (1997) で本流に取り込まれた。** 今の Emacs の多バイト処理は
Mule の直系の子孫で、`set-buffer-file-coding-system` のような名前や、
`find-charset-region` のような関数にその痕跡が残っている。mule 2.3
(Emacs 19.28 ベース) が最後の独立版である。

したがって「日本語を扱うために mule が要る」時代はとうに終わっている。今これを
動く形で残す値打ちは、軽さと、多バイト Emacs の出発点そのものであることの
ほうにある。

## 直したもの

### ダンプが壊れる

`temacs` は起動に必要な Lisp を読み込んだ状態で `unexec()` を呼び、走っている
自分自身の ELF イメージを書き換えて実行ファイルとして吐き出す。

- **PIE** はそのイメージを再配置する
- **RELRO** は `unexec()` が書き換えねばならない領域を write-protect する
- **FORTIFY** の `__builtin_object_size` は 1995 年の pre-ANSI な文字列処理と
  同居できない

三つとも切ってある。緩めると、ビルドは通るのにダンプ済みバイナリが起動時に
落ちる、という分かりにくい壊れ方をする。

### 割り当てフックが無限再帰する

`alloc.c` は `__malloc_hook` などを差し替え、本物を呼ぶ前に自分を外して、
戻ってから戻す。GCC 10 以降は `free` と `realloc` を組み込み関数として扱い、
「大域を読まない」と見なして、外す代入を死んだ書き込みとして消してしまう。
結果フックが自分を呼び続けて落ちる。

`-fno-builtin-malloc -fno-builtin-realloc -fno-builtin-free` で止めている。
逆アセンブルして、外す代入が消えていることと、指定後に戻ることを確かめた。

### `-fno-common`

GCC 10 から既定になった。このツリーはそれ以前の書き方なので `-fcommon`。
これは語長ではなくコンパイラの世代の問題で、i386 でも amd64 でも同じく要る。

### 宣言なしに呼ばれる Lisp_Object 関数

宣言が無いと戻り値は `int` と見なされる。`Lisp_Object` を返す関数では、
LP64 で上半分が落ちる。`src/lisp.h` に 75 個の宣言を足した
(`patch-af`)。2017 年に tsutsui が amd64 で「`mule -nw` は動くが Xt 版は
core を吐く」と記録しており、その筋を疑ったもの。**NetBSD 11.0/amd64 では
その core dump は再現しない。**

同じ理由で `src/frame.h` の前方宣言の塊を `MULTI_FRAME` の外へ出した
(`patch-src_frame.h`)。`keyboard.c` が `record_unwind_protect (init_sys_modes, 0)`
と関数の番地を取るため、暗黙の宣言では賄えない。

### info が建たない

`man/vip.texi` と `man/gnus.texi` には、今の `makeinfo` が誤りとする書き方が
残っている。`@itemx` が続けるべき `@item` の本文の後ろに置かれているもの、
TeX のコメントが本文として読まれるもの、入れ子になった `@ignore`。

最後のものは、1994 年の著者がどこで閉じるつもりだったかを推測しないと直せない。
文書の中身を当て推量で書き換えるのは筋が悪いので、`makeinfo --force` を使う。
当時の `makeinfo` がしていたことと同じで、対象八本すべてが素の配布物から建つ。

手で markup を直した版も試したが、**出力は一バイトも変わらなかった**。

### autoload が動かない (未解決)

**gcc 12 が `-O2` で組んだ `eval.c` では autoload が機能しない。**
`do_autoload` が `load` に渡す文字列は呼び出し地点では正しく (gdb で確認)、
Lisp 側の `load` に届く時点でスタックアドレスに化けている。
`substitute-in-file-name` が文字列でないものを受け取り、autoload するもの全て
が失敗する。`byte-optimize-lapcode` が autoload されるため `byte-compile` が
目に見える犠牲者になるが、被害はそこに留まらない。

gcc 7.5 は同じソースから健全な `eval.c` を作る。`eval.c` だけを `-O0` か
`-O1`、あるいは `-fno-inline` で組んでも直り、`-fno-inline-small-functions`
でも直る。三つのうち一番狭いものを入れてある。

**ただし何を抑えているのかは分かっていない。** gcc が `do_autoload` に inline
する二つの関数を `noinline` にしても直らないので、特定の inline を止めている
のではなく別の最適化判断を動かしている。診断ではなく経験的な回避である。

### CVE-2022-45939

`etags` は文字列を継ぎ足してシェルの命令を組み立て、引用せずに `system(3)` に
渡す。CVE が挙げるファイル名経由はこの版では踏めない (入力を回す繰り返しが
`optind` を `argc` まで進めるため、update の per-file 処理が一度も回らない)。
生きているのは `-o` の値で、

    ctags -u -o 'tags;command' file.c

でその命令が走る。NetBSD 11.0/i386 で当てる前と後の両方を動かして確かめた。
100 バイトの固定領域への `sprintf` も同時に無くなる (`patch-CVE-2022-45939`)。

### canna と wnn

パッケージが入れるのはクライアント側だけで、変換にはサーバと辞書が別に要る。

`cannaserver` が `Initialize failed` としか言わずに落ちる場合、たいてい辞書の
置き場所である。辞書は `/usr/pkg/libdata/canna/` に入るが、サーバが読むのは
`/var/dict/canna/canna/`。`ktrace` を当てると
`/var/dict/canna/canna/fuzokugo.cbd` の `open` が `ENOENT` で落ちているのが
見える。

Wnn 側は `egg` が起動ファイルを探すが、上流は候補である `eggrc-wnn` と
`eggrc-sj3` しか置かず `eggrc` を作らない。無いと egg は辞書をひとつも登録
しないまま止まる。`wnn4` オプションが有効なとき `eggrc-wnn` を複写している。

## 当て物の構成

108 本ある。名前 (`patch-aa` … `patch-cc`) からは中身が分からないので、
すべてに何のための物かを書いてある。目的は八つに分かれる。

| 本数 | 目的 |
| --- | --- |
| 20 | 生成済み info に `INFO-DIR-SECTION` を足す。`install-info` が読むのはこれ |
| 7 | 同じことを `.texi` 側に `@dircategory` で。作り直しても消えないように |
| 12 | K&R の定義を ANSI に直し、戻り値と引数の型を宣言する |
| 6 | `extern int errno` を落とす。今の libc では errno はマクロ |
| 3 | ビルドの繕い |
| 3 | 機種と OS の記述 (netbsd.h, alpha.h, dragonfly.h) |
| 1 | CVE-2022-45939 |
| 残り | 単発のもの |

注意が要るものが一つある。**`patch-src_search_c` は名前に反して
`src/regex19.c` を当てている。** 名前を変えると distinfo ごと動くので、
当て物の中に断り書きを入れてある。

## 検査

`.github/ci/` にある。ビルドが通っただけでは通したことにしない。このコードは
「ビルドは通るのにダンプ済みバイナリが起動時に落ちる」「変換サーバにつながる
のに辞書がひとつも登録されず読みがそのまま返る」という壊れ方をする。

**判定に stderr を使わない。** mule 2.3 は batch でエラーが起きると内容に
関わらず `INVALID DATATYPE` としか言わないので、メッセージから成否は決め
られない。elisp に結果ファイルを書かせ、その中身と、書き出させた符号化済み
ファイルのバイト列で判定する。検査ごとに `condition-case` で包んであるので、
ひとつ落ちても残りの結果が取れる。

踏むもの:

- 起動と版の確認
- `*euc-japan*` `*sjis*` `*junet*` `*internal*` の往復と、実際のバイト列の照合
- 符号化の指定が効いているかの交差確認 (効いていなければ往復は何を指定しても通る)
- 日本語に対する検索・置換・正規表現・kill/yank・undo・文字単位の削除・大文字化・並べ替え
- 日本語を含む `.el` の byte-compile と、`.elc` から読み直した文字列の一致
- 五回起動して結果が変わらないこと
- canna が `nihongo` を `日本語` にすること (EUC のバイト列で照合)
- wnn が `にほんごのへんかん` を `日本語の変換` にすること
- X のフレームが実際にマップされ、`window-system` が `x` になること
- core を吐いていないこと

イメージは [netbsd-ci-images](https://github.com/zakinko/netbsd-ci-images)
から取る。NetBSD が配っているのはインストーラが主で、インストール済みのものは
amd64 の 10.0 以降しかないため、anita で組んだものを置いてある。

## 動くと分かっている範囲

| | 端末のみ | X11 |
| --- | --- | --- |
| NetBSD 11.0 i386 / amd64 | 通る | 確認中 |
| NetBSD 10.1 i386 / amd64 | 通る | 確認中 |
| NetBSD 9.4 i386 / amd64 | 通る | 確認中 |

より古い版は、イメージを作れる範囲を広げながら順に確かめている。

## 分かっている限界

- **`open-network-stream` は IPv4 のみ。** `gethostbyname()` は A レコード
  しか返さず、`::1` のようなリテラルは解釈できない。実測で確認済み。canna と
  wnn は UNIX socket なので影響しない
- `emacsclient` と `callproc.c` が `/tmp` を決め打ちし、`mktemp(3)` を使う
- 既知の型の脆弱性を数個確かめただけで、網羅的な監査はしていない
