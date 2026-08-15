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

### autoload が動かない (i386、原因判明)

`call0` から `call6` と `apply1` は、**最初の仮引数の番地を取り、引数がそこに
並んでいるものとして `Ffuncall` に配列として渡す**。

```c
RETURN_UNGCPRO (Ffuncall (5, &fn));
```

関数が自分の枠を持っているうちは成り立つ。**inline 展開された瞬間に崩れる。**
仮引数は配置を持たない値になり、`&fn` は 1 語ぶんの場所しか指さず、2 つ目以降
はスタックに残っていた何かになる。

gcc 12 は `call4` を `do_autoload` に inline する。その結果、`load` に渡される
はずのファイル名がスタックアドレスに化け、`substitute-in-file-name` が文字列
でないものを受け取り、**autoload するもの全てが動かなくなる**。
`byte-optimize-lapcode` が autoload されるため `byte-compile` が目に見える
犠牲者になる。gcc 7.5 は inline しないので、この症状は新しいコンパイラでのみ
出る。

このツリーには `NO_ARG_ARRAY` という切り替えが最初から用意されている。定義
すると、これらの関数は明示的な配列を組む。**私たちが建てる他の機種 — amd64、
sparc、alpha、powerpc — はすべて定義しており、i386 だけがコメントアウトされて
いた** (`patch-src_m_intel386.h`)。

    /* Define NO_ARG_ARRAY if you cannot take the address of the first of a
     * group of arguments and treat it as an array of the arguments.  */

今のコンパイラでは、まさに「できない」。

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

109 本ある。名前 (`patch-aa` … `patch-cc`) からは中身が分からないので、すべてに
何のための物かを書いてある。

**確認**の欄は、その当て物について何をしたかを表す。

- **実証** — 当てる前と後の両方を動かして違いを見た
- **読了** — 差分を読み、直している対象を原典で確かめた
- **未確認** — 差分は読んだが、それ以上は追っていない

**上流**の欄は、現在の GNU Emacs が同じ問題をどう扱っているかを実際に見た結果。

### 一つずつ見たもの

| 当て物 | 対象 | 役割 | 確認 | 上流 |
| --- | --- | --- | --- | --- |
| `patch-src_m_intel386.h` | `src/m/intel386.h` | `NO_ARG_ARRAY` を定義。`&fn` の仮定が inline で崩れ autoload が全滅する | **実証** | `src/m/*` は Emacs 24 で廃止。`&fn` の仕組みごと捨て、常に配列を組む `CALLN` に置換 |
| `patch-CVE-2022-45939` | `lib-src/etags.c` | `system(3)` に渡す値を引用。固定長 `sprintf` を除去 | **実証** | **同じ手法**。単一引用符で包み `'` を `'\''` に escape |
| `patch-af` | `src/lisp.h` | `Lisp_Object` を返す関数 77 個を宣言。無いと LP64 で戻り値が切れる | 読了 | 上流は型付きで宣言 (`get_local_map (ptrdiff_t, struct buffer *, Lisp_Object)`) |
| `patch-src_search.c` | `src/search.c` | `compile_pattern` と `skip_chars` に戻り値の型と引数の型を与える | 読了 | `compile_pattern` は型付き。`skip_chars` は書き直され現存せず |
| `patch-src_casefiddle.c` | `src/casefiddle.c` | `casify_region` を ANSI 定義に | 読了 | **同一の形** `casify_region (enum case_action, Lisp_Object, Lisp_Object)` |
| `patch-src_cm.c` / `.h` | `src/cm.c` `cm.h` | `cmgoto` の定義と宣言を型付きで揃える | 読了 | 型付き (`struct tty_display_info *` が増えている) |
| `patch-src_insdel.c` | `src/insdel.c` | `del_range` 等を ANSI 定義に | 読了 | 型付き (`ptrdiff_t`) |
| `patch-src_undo.c` | `src/undo.c` | `record_insert` `record_delete` を ANSI 定義に | 読了 | 型付き。引数の型は後年変わっている |
| `patch-src_dired_c` | `src/dired.c` | 標準ヘッダ + `compile_pattern` の引数不足を直す | 読了 | 該当箇所は書き直され現存せず |
| `patch-ak` | `src/keyboard.c` | window system が無いとき `last_event_timestamp` に実体を与える | **実証** | 該当変数は現存せず |
| `patch-src_frame.h` | `src/frame.h` | 前方宣言を `MULTI_FRAME` の外へ | **実証** | `MULTI_FRAME` 自体が廃止 |
| `patch-cj` | `src/wnnfns.c` | `wnn-server-set-rev` が値を返さずに終わるのを直す | **実証** | wnn 対応は上流に無い |
| `patch-src_canna.c` | `src/canna.c` | 値を返すはずの関数が返さずに終わるのを直す | 読了 | canna 対応は上流に無い |
| `patch-ab` | `src/unexelf.c` | 新しい emacs の `unexelf.c` を持ってくる | 未確認 | `unexec` ごと廃止 (Emacs 28 で portable dumper に) |
| `patch-ad` | `configure` | 機種と OS の追加 + cpp の検査を直す | 読了 | `configure` は全面的に書き直されている |
| `patch-ae` | `src/m/powerpc.h` | PowerPC の機種記述を追加 | 未確認 | `src/m/*` ごと廃止 |
| `patch-aa` / `patch-bc` / `patch-ca` | `src/s/netbsd.h` `m/alpha.h` `s/dragonfly.h` | 機種と OS の記述 | 未確認 | `src/s/*` `src/m/*` ごと廃止 |
| `patch-src_m_amd64.h` | `src/m/amd64.h` | amd64 の機種記述を追加 | **実証** | 同上 |
| `patch-bd` | `src/fns.c` | 標準ヘッダ + 衝突する手書き `extern` を無効化 | 読了 | 手書き宣言は現存せず |
| `patch-bw` | `lib-src/movemail.c` | `xmalloc` を `size_t`/`void *` に | 読了 | 上流も型付き |
| `patch-src_tparam_c` | `src/tparam.c` | `xmalloc`/`xrealloc` の宣言を LP64 でも有効に | 読了 | 該当の条件分岐は現存せず |
| `patch-be` | `src/config.h.in` | `HAVE_STRERROR` を定義 | 読了 | configure が検出する |
| `patch-an` / `patch-ao` | `Makefile.in` `man/Makefile` | `SUBDIR` に man を足し、info を既定で建てる | **実証** | 構成が全く異なる |
| `patch-bb` | `man/texinfo.tex` | 1994 年版を 1997 年版へ | 未確認 | 現在の texinfo.tex は別物 |
| `patch-cc` | `src/mcpath.h` | `NAME_MAX` が無い環境への逃げ道 | 未確認 | mcpath は上流に無い |
| `patch-aj` | `src/getloadavg.c` | `unix` が未定義の環境を救う | 読了 | gnulib に移管 |
| `patch-ac` | `lib-src/Makefile.in.in` | `INSTALL_PROGRAM` ではデータに合わない | 読了 | 構成が異なる |

### まとめて同じことをしているもの

| 当て物 | 本数 | 役割 | 確認 | 上流 |
| --- | --- | --- | --- | --- |
| `patch-ap` ほか | 20 | 生成済み info に `INFO-DIR-SECTION` を足す | 読了 | 上流は info を配布物に含めないので不要 |
| `patch-ar` ほか | 7 | 同じことを `.texi` に `@dircategory` で | 読了 | **同じ書き方**を使っている |
| `patch-src_data.c` ほか | 8 | K&R の定義を ANSI に直す | 読了 | 上流も全て ANSI |
| `patch-ai` ほか | 5 | `extern int errno` を落とす | 読了 | 手書き宣言は現存せず |
| `patch-src_bytecode_c` ほか | 25 | 標準ヘッダを足す | 未確認 | 上流も標準ヘッダを使う |

注意が要るものが二つある。**`patch-src_search_c` は名前に反して `src/regex19.c` を
当てている** (`patch-src_search.c` のほうが `src/search.c`)。名前を変えると distinfo
ごと動くので、当て物の中に断り書きを入れてある。

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
