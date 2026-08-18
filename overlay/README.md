# overlay

上流 pkgsrc のパッケージに、こちらで手を入れたものを置くところ。ここは
`zakinko` カテゴリではなく、**上流のカテゴリ**への当て物。

```
overlay/<カテゴリ>/<パッケージ>/...  →  /usr/pkgsrc/<カテゴリ>/<パッケージ>/...
```

## 誰が使うか

[NetBSD-i386](https://github.com/zakinko/NetBSD-i386) の CI。この repo を
`zakinko` カテゴリとして clone したあと、`overlay/` の中身を上流 pkgsrc の
同じ場所へ上書きコピーし、`zakinko/overlay` はツリーから取り除いてから
ビルドに入る (`ci/make-pkgsrc-tarball.sh`)。

当てた場所は `.overlay-dirs` に記録され、ゲスト側で `make makepatchsum` が
走って distinfo に patch の SHA1 が入る。pkgsrc 標準のターゲットなので、
こちらでハッシュを計算する必要はない。

この repo の CI のうち、NetBSD 以外を回す
[.github/ci/build-on-bsd.sh](../.github/ci/build-on-bsd.sh) も当てる。
あちらはツリーを焼き込まずその場で展開するので、`zakinko` カテゴリを
重ねた直後に同じことをする。`makepatchsum` が転けても止めないのが違いで、
ここに置いてあるものの大半は mule の依存に入っておらず、入ったときは
patch のチェックサム不一致で必ず止まるため。

**pkgsrc から見ると package でないディレクトリがカテゴリに混ざる形になる。**
カテゴリの `Makefile` は `SUBDIR` を明示しているので `make` は無視するが、
`pkglint` は文句を言うかもしれない。CI は取り除いてから渡すのでビルドには
影響しない。

## 決まりごと

- **PKGREVISION を上げる。** patch を足しただけだと PKGNAME が変わらず、
  手元の pkgin が「同じものが入っている」と判断して入れ替えてくれない。
  Makefile ごと写して番号を上げるのが手っ取り早い。ただし入れるものが
  変わらない修正 (依存側が要求する名前を直すなど) では上げない。
- **一時的なものとして扱う。** ここに置くのは「上流 pkgsrc がまだ取り込んで
  いない」ものだけ。取り込まれたらディレクトリごと消す。消し忘れると、
  上流が直したあとも古い写しの Makefile を使い続けることになる。
- **上流にも送る。** ここに置くのはあくまで手元をすぐ直すためで、本筋は
  pkgsrc 本体に入れること。送るための diff とメールは
  [NetBSD-i386 の doc/upstream/](https://github.com/zakinko/NetBSD-i386/tree/main/doc/upstream)
  にある。

## 今あるもの

| | 何 | 消してよくなる条件 |
|---|---|---|
| `sysutils/augeas` | lens 462 本が入らないのを直す、CVE-2025-2588 の NULL 参照修正、`time_t` の書式。PKGREVISION 4 | pkgsrc が同等の変更を入れるか、augeas が 1.14.2 を出して pkgsrc が追随したとき |
| `inputmethod/anthy-elisp` | `EMACS_VERSIONS_ACCEPTED` に emacs26〜30 を追加、PKGREVISION 9 | pkgsrc が同等の変更を入れたとき |
| `inputmethod/anthy` | anthy.el と anthy-dic.el が使う廃止シンボル 5 つを直す patch | 同上 (anthy-elisp と PATCHDIR を共有している) |
| `devel/zls` | zig 0.13.0 で壊れているとして `BROKEN` を抱えたまま止まっている。0.12.0 から 0.16.0 へ上げ、`zig-depends.mk` を作り直して `BROKEN` を外す | 上流 pkgsrc が同等の更新を入れたとき |
| `security/fail2ban` | 1.0.2 から 1.1.1 へ。`2to3` の前処理と Python 3.12 固定を外せる。`compat/asyncore.py` と `compat/asynchat.py` が同梱されたので GitHub issue #174 (asynchat が無い) も閉じる | 同上 |
| `devel/libuuid` | DragonFly で util-linux が組めないのを直す。`Makefile.common` に `CONFIGURE_ENV.DragonFly+= ac_cv_type_cpu_set_t=no` 一行 | pkgsrc が同等の変更を入れるか、util-linux が cpu_set_t の判定を直して pkgsrc が追随したとき |

`augeas` は 9.4 / 10.1 / 11.0 の三つで建つことを確認済み。`make test` は
263 件中 7 件落ちるが、patch を外しても同じ 7 件が落ちるので当て物とは
無関係で、CVE の回帰テスト (`fatest`) は三つとも通っている。

lens が入っていない件は pkgsrc 全体の話で、当て物とは別に元から壊れている。
NetBSD 11.0/amd64 に公式パッケージを入れた実機で、`augtool print
/files/etc/hosts` が何も返さないことを確認した。`$(wildcard)` が GNU make
の関数なのが原因。FreeBSD も OpenBSD も gmake を足して回避しているが、ここ
では素の glob に変えて gmake を要らなくしている。CVE の方は同じ 11.0/amd64
で `augparse` が SIGSEGV になることを確認した。

patch 4 本を当てて `--prefix` に入れ、`-I` を付けずに `augtool` が lens を
見つけて読み書きできるところまで確かめてある。`DATADIR` が `--prefix` から
生成され `AUGEAS_LENS_DIR` がそれを使うので、`/usr/pkg` でも同じになる。

`anthy-elisp` は `inputmethod/anthy` の patch と組で、そちらが emacs30 で
実際に動くようにしている。

`anthy-elisp` は上流が emacs21 世代しか受け付けず、`~/.emacs` の
`(load-library "anthy")` を塞いでいた。26 以降を足すと emacs26 では `.elc`
が 6 本生成されるが、**emacs30 では版を広げるだけでは足りない**。

`inputmethod/anthy` の patch はそこを埋めるもの。emacs26 と emacs30 の
実バイナリ (9.4/i386 の公式パッケージ) を techne に展開して突き合わせた
結果は次のとおり。

| emacs30 で | `.elc` | 実際に変換できるか |
|---|---|---|
| 当て物なし | 4/6 | 読むだけで落ちる |
| `set-face-underline-p` だけ直す | 6/6 | **落ちる** (`process-kill-without-query`) |
| 当て物あり (5 件) | 6/6 | できる |

`.elc` が 2 本欠けるのは `set-face-underline-p` のせいで、これは PLIST との
食い違いとして build を落とす。厄介なのは真ん中の行で、
`process-kill-without-query` は関数の中にあるため byte-compile が「知らない
関数」の警告で済ませてしまう。`.elc` は全部そろい PLIST とも合い、**build は
緑になるのに最初の変換で落ちる**。`.elc` の本数だけ見ていると気付けない。

確認は byte-compile だけでなく、anthy-agent を実際に起動して
`nihongo` → `にほんご` → `日本語` の変換が emacs26 と emacs30 で一致する
ところまで見た。これは CI の煙試験として
[NetBSD-i386 の ci/guest-build.sh](https://github.com/zakinko/NetBSD-i386/blob/main/ci/guest-build.sh)
に入れてある。

**当て方の順番に注意。** `inputmethod/anthy/patches` には上流の
`patch-anthy.el` が既にあり、旧式バッククォート (`anthy-deflocalvar`) は
2023 年にそちらで直っている。当て物を作るときは素の tarball ではなく、
`patch-anthy.el` を当てた状態を基準にすること。一度これを見落として、
同じ箇所を二重に直す hunk を書き、CI で reject を出した。

`editors/emacs30-nox11` の当て物もその続きで踏んだものだった。`version.mk`
の `_EMACS_REQD` が `emacs30-no-x11` と綴られていて、実際の PKGNAME
(`emacs30-nox11`) と食い違い、依存する側が一つも建たなかった。PR 60590 で
上流が直したので、当て物は消してある。

`devel/libuuid` は DragonFly のためのもので、mule そのものとは離れている。
mule は makeinfo を要り、`devel/gtexinfo` は help2man と gettext-tools を
経て `lang/python313` を引き、python313 は libuuid を引く。その libuuid が
DragonFly で組めないので、CI は mule の configure まで一度も届いていなかった。

止まる場所は util-linux の `lib/cpuset.c`。DragonFly の `<sched.h>` は
`cpu_set_t` を `cpumask_t` の別名として定義しているので型はあるが、持って
いるのは `CPU_ZERO()` や `CPU_ISSET()` といった固定長のものだけで、glibc の
`CPU_ALLOC()` / `CPU_SET_S()` のような可変長のものは無い。util-linux の
configure は型の有無だけで `lib/cpuset.c` を組む対象に入れ、`CPU_ALLOC` が
無いのを見て `include/cpuset.h` の代替定義に落ちる。その代替が glibc から
写したもので `(cpusetp)->__bits` を直に触るため、`__uint64_t` の配列でしか
ない DragonFly の `cpumask_t` では通らない。

NetBSD と FreeBSD が通っているのは、あちらが同じものを `cpuset_t` と綴って
いて `cpu_set_t` が無いから。DragonFly だけが「型はあるが API が無い」中間に
いて、util-linux はその場合を想定していない。master でも同じままである。

libuuid と libblkid と mcookie はどれも cpuset を使わず、util-linux 側の
参照も全部 `HAVE_CPU_SET_T` で囲われている。そこで configure に型が無いと
言わせて、NetBSD や FreeBSD と同じ構成にしている。同じ `Makefile.common` が
既に SunOS へ `ac_cv_header_sys_vfs_h=no` を渡しているので、手としても
その場にあるものである。

patch を足していないので PKGREVISION は上げていない。DragonFly 以外では
入るものが変わらず、DragonFly では今まで一つも建っていない。
