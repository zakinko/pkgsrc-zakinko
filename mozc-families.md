# mozc の四家族 — 誰が何を持ち、何が確かめてあるか

pkgsrc の `inputmethod/mozc-*` を、四つの版で同時に触っている。発見が家族を
またいで飛ぶので、**どれがどの版に当たるか**を取り違えると時間を溶かす。
実際に何度か溶かした。ここはその照合表である。

**書き方の約束。** 「確認済み」は自分で実物を見たものだけ。人から聞いたものは
「伝聞」と書き、確かめたらそこで書き換える。今日この区別を守らずに二度、
誤った内容を人に渡した。

| 家族 | 版 | ビルド系 | 状態 |
|---|---|---|---|
| 2.29 | 2.29.5268.102 | bazel (既定) / gyp (option) | tree に在る。pkg/60654 で直し中 |
| 226 | 2.26.4282.100 | gyp | tree に在る |
| 333 | 3.33.6089 | gyp | 新規登録を提案中 |
| 334 | 3.34.x | gyp | 新規登録を提案中 |

## 家族をまたぐ論点

`○` = その版に当てはまる、`×` = 当てはまらない、`?` = 未確認。

| 論点 | 2.29 | 226 | 333 | 334 |
|---|---|---|---|---|
| `sun_len` が 1 バイト短い | ○ | ○ | ○ | ○ |
| `IsPeerValid` が `*pid` を埋めない | ○ | ○ | ○ | ○ (NetBSD の枝が無い) |
| server path が `/proc` 依存 | ○ | × (元から sysctl、MIB が 3 要素で誤り) | ○ | ○ |
| 同梱 abseil の `->vs_vers` | ○ | × | ○ | ○ **当て物なし** |
| `FinalizeSingletons` が null を舐める | × | × | ○ (機序に異論あり、下記) | — (3.34 で Singleton ごと消えた) |
| gyp の Qt/renderer 用の当て物が要る | × (`--noqt`、renderer を建てない) | ○ | ○ | ○ |
| gyp の既定を LP32 だけで決めている | × (直した) | — | × (元から正しい) | ? |

**× の根拠。**

- 226 の abseil — `mozc-2.26.4282.100` の `elf_mem_image.cc` に `__NetBSD__` の
  枝が一つも無く、`version_symbol[0] & VERSYM_VERSION` と配列添字で読む。
  `Elfnn_Versym` が struct でも整数でも通る形。distfile を展開して確認済み。
- 2.29 の singleton — `SingletonFinalizer::Finalize` が
  `g_finalizers_size - 1` から逆順に回る。登録済みの分しか触らない。確認済み。
- 2.29 の Qt/renderer — `options.mk` を include するのは `mozc-server` と
  `mozc-elisp` の二本だけで、どちらも `--noqt` を渡し renderer を建てない。
- 226 の singleton — `SingletonFinalizer::Finalize` が
  `g_finalizers_size - 1` から逆順に回る。2.29 と同じ形。work の
  `mozc-2.26.4282.100/src/base/singleton.cc:78` を読んで確認済み。
- 334 の singleton — `base/singleton.cc` も `.h` も無く、`FinalizeSingletons`
  を呼ぶ場所も無い。上流が 3.34 で Singleton ごと廃止した。work の
  `mozc-3.34.6239/src` で確認済み。

**334 の ○ の根拠。** 当て物が当たった木ではなく、`.orig` を読んでいる。

- `sun_len` — `unix_ipc.cc.orig:384` が
  `sizeof(addr.sun_family) + server_address_.size()`。NetBSD は
  `sun_family` が 1 バイトなので 1 バイト足りない。
- `IsPeerValid` — `.orig` には `SO_PEERCRED` と `struct ucred` の枝しか無く、
  NetBSD の枝が存在しない。「埋めない」以前に通らない。
- server path — `ipc_path_manager.cc.orig:394` が
  `absl::StrFormat("/proc/%u/exe", pid)`。
- abseil — 同梱の `elf_mem_image.cc` に当て物が無く、
  380 行が `#if defined(__NetBSD__)`、381 行が `version_symbol->vs_vers`。

**334 の当て物の MIB は正しい。** `ipc_path_manager.cc` の `__NetBSD__` の枝は

	int name[] = {CTL_KERN, KERN_PROC_ARGS, static_cast<int>(pid),
	              KERN_PROC_PATHNAME};

で、pid が三番目、`KERN_PROC_PATHNAME` が最後。同じファイルの `__FreeBSD__`
の枝は `{CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, pid}` で並びが違い、
**両方が別々に書かれている。** 333 の当て物も同じ並びで、二つは一致している。

## 取り違えやすいもの

**`/usr/pkg/libexec/mozc_server` は家族が違っても同じパス。** 333 を測って
いるつもりで 2.29 を測っていた、という取り違えが実際に起きた。`pkg_info` か
`ls /var/db/pkg` で今どれが入っているかを先に見ること。

**`mozc_renderer` に `sysctl` が出ないのは正常。** `IPCServer` を継承していて
`IPCClient::Init` を通らないので `IsValidServer` に到達しない。当て物が
効いていないのではない。`bind` は通るので `sun_len` の直しは効く。

**gyp の `ld = $ldxx` は master の `build.ninja` には出ない。** target ごとの
`obj/*/….ninja` に書かれる。master だけ数えて「上書きが 0」と読むと、
「C++ を C コンパイラでリンクしている」という誤った結論になる。2.29 で 430 本
中 111 本、3.33 で 357 本中 106 本。

### emacs は同じ箱に二つ入らない

`bin/ctags` を版ごとに持つので、`emacsNN-nox11` は同時に一つしか入らない。

	pkg_add: emacs30-nox11-30.2nb1: conflicting PLIST with
	         emacs28-nox11-28.2nb1: bin/ctags

`/etc/mk.conf` の `EMACS_TYPE` が指す版が入っていないと、`mozc-elisp` も
`anthy-elisp` も建たない。**emacs の版を入れ替えるときは、elisp 系を
建てているセッションに一声かけること。** 8/28 23:45 に emacs30-nox11 が
emacs28-nox11 に替わり、8/29 の mozc-elisp が落ちた。

### pkgsrc の glob は `-` を跨ぐ。目で読まず `pkg_admin pmatch` に訊く

	emacs[0-9]*-[0-9]*   emacs30-nox11-30.2nb1   当たる
	emacs[0-9]*-[0-9]*   emacs28-nox11-28.2nb1   当たる
	emacs-nox11-[0-9]*   emacs30-nox11-30.2nb1   当たらない
	emacs-[0-9]*         emacs30-nox11-30.2nb1   当たらない

`*` が `-` も食うので、`emacs` + `[0-9]`=3 + `*`=`0-nox11` + `-` +
`[0-9]`=3 + `*`=`0.2nb1` と分解される。**「`emacs30-nox11` は
`emacs[0-9]*-[0-9]*` の形ではない」という目視は外れる。**

	pkg_admin pmatch '<pattern>' '<pkgname>'    → 終了状態で答える

`DEPENDS` の `>=` や `CONFLICTS` を読むときは、必ずこれに訊く。
**ただし終了状態を見る測定なので、下の「失敗と偽の区別」も併せて。**

### mule2 と emacs も同じ箱に入らない

emacs の版どうしが `bin/ctags` で排他なのと同じ理由で、`zakinko/mule2` と
`emacsNN-nox11` も同居できない。

	mule2/PLIST     bin/ctags  bin/etags  bin/emacsclient  ...
	emacs30-nox11   /usr/pkg/bin/ctags  /usr/pkg/bin/etags

`CONFLICTS` の書き方が緩いのではなく、実態が書いてある。**techne では
「mule2 を入れて確かめる」と「elisp 系を建てる」が排他。** 直す類の話では
なく、順番を決める話。

### binary の文字列を見て「持っていない」と読むのは外れる

gyp で建てた `mozc_server` と `mozc_emacs_helper` に `/usr/pkg/libexec` が
無い、と `grep -a` が答えた。bazel 版には在る。**「gyp 版はサーバの path を
持っていない」と読みかけた。**

	grep -a -c 'usr/pkg/libexec'   bazel 1 / gyp 0
	strings                        bazel /usr/pkg/libexec
	                               gyp   /usr/pkg と /libexec が別々

**実際は動く。** gyp 版の helper を PATH の先頭に置いて変換させたら
`にほんご → 日本語` が通った。gcc が定数を分けて持ち、実行時に連結して
いるだけだった。

**文字列の有無は実装の都合で変わる。動かして確かめる。** `ktrace -t cn` で
open するパスを見る手もあるが、helper は `CreateSession` を受けて初めて
サーバを探すので、`/dev/null` を食わせても何も出ない。

### 他家族の当て物と突き合わせる — 何が要らないかを確かめる

「2.29 にまだバグは無いか」を、226 が持っていて 2.29 に無い当て物から逆算
した。**五つとも 2.29 には要らなかったが、要らないことを一つずつ確かめる
までは分からなかった。**

	ipc_named__event.cc    sem_open(...,0) は NetBSD 11.0 で通る (実測)
	graphcycles.cc         2.29 は既に #include <limits> を持つ
	base_clock.cc          2.29 は書き換わっていて該当しない
	base_run__level.cc     同上
	base_base.gyp          server_dir!="" が偽なので platform を足しても
	                       効かない。#ifndef の既定値で足りることを実測

**当て物の名前とファイルの有無だけで判断すると、要らない当て物を足す。**
`ipc_named__event.cc` は「226 が直しているのに 2.29 が直していない」形に
見えたが、2021 年の NetBSD の問題で 11.0 では直っていた。

	探し方   for f in 226/patches/patch-*; do
	           2.29 に同名の当て物が無く、かつ 2.29 に同名ソースが在るものを挙げる

### 手元の記録も、後で誰かが根拠に使う

「送るもの」には気を張っても、`README.md` や照合表のような**手元の記録**には
張らないことがある。**記録も後で根拠として引かれる**ので、同じ扱いが要る。

実例。ある PR 番号を「226 の分」と peer から聞いて、確かめずに送信済み表へ
書き込んだ。実際は別セッションの emacs の PR で、226 はまだ送られていな
かった。**「人から聞いた話は実物を開くまで伝聞のまま」を各セッションに配って
回った側が、その日のうちに四度目を踏んだ。**

	送るもの   気を張る
	記録       張らない   ← ここが抜ける

確かめ方は同じ。**その PR の実物を開く。**

	ls -la ~/w/claude/*/*.pr        誰が何を置いたか
	head -4 <file>                  Subject と宛先

### 終了状態を見る測定は、失敗と「偽」の区別が付かない

	$ pkg_admin pmatch 'mozc-server>=2.26...' mozc-server-2.29...nb14
	  → 「一致しない」

**実際は `pkg_admin` が非対話 ssh の PATH に無く、command-not-found の
終了状態を「不一致」と読んでいた。** 絶対 path で取り直したら全件逆だった
(226 の実例)。

同じ形が `make show-var` にもある。**空の出力は「変数が空」とも
「コマンドが失敗」とも読める。**

	$ make show-var VARNAME=NO_SUCH_VAR_XYZ
	rc=0  出力=[]        ← 存在しない変数も同じ答え

**区別するには、同じコマンドが別の入力で値を返すことを並べて示す。**
pkg/60666 では、同じ箱の同じコマンドが `BROKEN_ON_PLATFORM` と
`MACHINE_PLATFORM` には値を返し、当て物の後には `PKG_FAIL_REASON` にも
値を返すことを見せている。

rc を三分岐 (0 / 1 / それ以外) にして「測定失敗」を別に出すのが確実。

### 実物を開いても、当てる先を間違えると伝聞と変わらない

334 の abseil を「素で正しい」と読んだ例。distfile を開いて
`->vs_vers` を目で見ているので「実物を見た」つもりになる。**見るべきは
-current の `sys/exec_elf.h` との組み合わせだった。**

	11.0        #define _SYS_EXEC_ELF_H_        値なし → Versym は struct
	-current    #define _SYS_EXEC_ELF_H_  2     Elf_Half になる

**「11.0 で通る形か」と「-current で壊れないか」は別の問い。** 開いた file が
正しくても、問いが違えば答えは使えない (af 自身の弁)。

### 変数は定義を grep せず、展開させて測る

`mozc-renderer226/Makefile` が `${MOZC_VERSION}` を参照しているのに、
`Makefile.common` が定義しているのは `MOZC_VER` だった。**空に展開されて
pattern が `mozc-server-*` になり、何にでも一致する。**

	$ make show-var VARNAME=MOZC_VERSION      → []
	$ make show-depends | grep mozc-server    → mozc-server-*:...

逆向きの誤りもある。`PKGVERSION_NOREV` を package の Makefile の中だけで
grep して「未定義」と読んだ例。**実際は pkgsrc の組み込み**
(`mk/bsd.pkg.mk:46`)。**「定義が見つからない」と「未定義」は別。**

	$ make show-var VARNAME=PKGVERSION_NOREV   → 3.33.6089

**どちらも `make show-var` で展開まで見れば一発で分かる。**

家族間の依存の縛りも、展開して初めて強さが見える。2.29 の場合:

	mozc-elisp     mozc-server-2.29.5268.102{,nb*}   厳密
	mozc-renderer  mozc-server-[0-9]*                任意の版
	ibus-mozc      mozc-{renderer,server,tool}>=2.29  2.29 以上なら何でも

**`>=2.29` は 3.33 でも満たされる。** PKGBASE が同じで同居できない以上、
install の順序によっては噛み合わない。新しく足すときは
`PKGVERSION_NOREV` を使うと家族固有の変数が要らず、名前の食い違いも
起きない。

### 写しで測ると、送る形の条件が一度も踏まれない

`zakinko/` の写しで建てている限り `PKGPATH` は `zakinko/...` のまま。
**`options.mk` や `Makefile.common` が `PKGPATH` で分岐していると、送る形の
条件を一度も通らない。** 写しでは測れない条件が入った時点で、写しでの検証が
嘘になる (76431e7e)。

333 は `inputmethod/mozc-*333` を symlink にし、CI では実体を動かして
`PKGPATH` まで送る形に揃えている。

2.29 は式が等価であることを測って済ませた。

	提出   empty(PKGPATH:Minputmethod/mozc-server) && ...mozc-elisp)
	fork   empty(PKGPATH:M*/mozc-server) && ...mozc-elisp)

	                提出          fork
	mozc-server     しない        しない
	mozc-elisp      しない        しない
	mozc-tool       する          する
	mozc-renderer   する          する
	ibus-mozc       する          する

**測り方に注意。** `.for` の中で `empty(PKGPATH:M...)` と書くと、loop 変数
ではなく未設定の実変数を読み、常に真になる。`.for` が置換するのは
`${PKGPATH}` の形だけ。**コマンドラインで `make -f t.mk PKGPATH=...` と
渡すのが正しい。** 誤った書き方は「全部 buildlink する」というもっともらしい
答えを返すので気づきにくい。

### 片付けると証拠も消える

**「手元で一度測った」は、work や package を消した時点で消える。**
PR の本文に書いた主張の裏付けが、掃除で無くなっていることがある
(226 が四件それで取り直しになった)。

`CLEANUP` に undo を書く決まりの裏側である。**証拠を残さない片付けは、
主張も一緒に消す。** 送るまでは、測定に使った成果物を退避しておく。

### `pkg_delete` と pkgsrc が別の DB を見る

	$ make show-var VARNAME=PKG_DBDIR
	/var/db/pkg
	$ pkg_delete <pkg>            → 既定で /usr/pkg/pkgdb を見る

食い違うと `pkg_delete` は「そんな package は無い」と言い、`pkg_add` は
「もう入っている」と言い、ファイルは古いまま残る。三つが食い違って原因が
見えなくなる。**`sudo env PKG_DBDIR=/var/db/pkg pkg_delete <pkg>` と
指すこと。**

### `+BUILD_INFO` で package の出所が引ける

「この package は誰が、どの木から、いつ建てたか」は package 側に在る。

	/var/db/pkg/<pkg>/+BUILD_INFO
	BUILD_DATE=2026-08-28 23:44:47 +0000
	PKGPATH=zakinko/emacs28-nox11        ← 木の editors/ ではない

**共有の箱で「これは誰のものか」を追うときの最初の一手。**

### `make install` が当て物前の binary を入れることがある

`ninja` で relink しただけでは `work/.destdir` も `packages/All/*.tgz` も
作り直されない。**`make install` が rc=0 で返っても、入るのは前の binary。**

	sudo rm -f $W/.install_done $W/.package_done
	sudo rm -rf $W/.destdir $W/.packages

`make clean` から建て直していれば当たらない。

## 測り方

334 の書き方に倣う。**「建った」と「動いた」と「届く見込み」を分ける。**

	建った        make package が rc=0
	動いた        mozc_emacs_helper から実際に変換した
	届く見込み    理屈では通るはずだが、その platform で建てていない

2.29 の現状:

	amd64 + bazel   七本とも建った。変換した。socket 名と nm を見た
	amd64 + gyp     確認中
	i386            建てていない。gyp option の対象はここなので、
	                「届く見込み」に留まる

## 送り先

| | 宛先 | 状態 |
|---|---|---|
| 2.29 | pkg/60654 | 本体は送信済み。follow-up は未送 |
| 226 | 未送 | |
| 333 | 未送 | |
| 334 | 未送 | |
| `devel/bazel` の `BROKEN_ON_PLATFORM` | 未送 | 2.29 の側から別 PR で出す |

`mk/defaults/options.description` へ足す `gyp` の行は、2.29 と 333 で同じ
文面に揃えてある。先に入った方が有効になり、もう片方は当たらなくなるだけ。

	gyp			Build with gyp and ninja instead of bazel.

## 333 の i386 実測 (2026-08-29 時点)

**当て物前と当て物後を分けて書く。** 混ぜると「当て物が効いた」ことの
証拠にならない。

| | 版 | 箱 | 結果 |
|---|---|---|---|
| CI run 33133363071 | patch-base_singleton.cc **前** | 11.0/i386 | server 690/690、elisp 379/379、変換 通った |
| techne 手測り | 当て物 **後** | 11.0/amd64 | 二重起動・profile 無しとも core 出ず |
| CI run 33238670456 | 当て物 **後** | 9.4 / 10.1 / 11.0 の i386 | 実行中 |

**前者で変換が通ったのは、当て物のおかげではない。** CI が profile を先に
作るようにしたので、`Run()` が早期に戻る経路に入らなかっただけである。
`FinalizeSingletons` は呼ばれてはいるが、そのとき登録済みの finalizer が
あって配列の先頭が null でなかったか、あるいは経路そのものに入っていない。

**当て物が効くことは amd64 の前後比較で示した。**

	未修正  二重起動 → SIGSEGV / core    profile 無し → SIGSEGV / core
	修正後  二重起動 → exit 255 / 無し   profile 無し → exit 255 / 無し

## `.orig` を読む

pkgsrc は `patch` の `.orig` を work に残す。**「当て物を入れる前はどう
だったか」を distfile を展開し直さずに読める。** 334 の四項目はこれで
5 分だった。

	/var/tmp/pkgsrc.work/<cat>/<pkg>/work/<distname>/src/ipc/unix_ipc.cc.orig

**`make clean` すると消える。** 他のセッションが同じ木で `make clean` を
走らせることがあるので、読みたいものは先に控える。

## 報告が食い違ったもの — どちらも決着済み

### 3.33 の `FinalizeSingletons` — 決着済み

同じ関数の逆アセンブルで読みが割れた。**どちらの読みも正しく、対象が
違った。** 素の distfile で確定:

	=== distfiles/mozc-3.33.6089.tar.gz を展開したもの ===
	for (auto func : internal::finalizers) {      ← 256 個ぜんぶ
	  func();

	=== 当て物 patch-base_singleton.cc を当てた work ===
	for (int i = 0; i < internal::size; ++i) {    ← 「原文」として引かれた形
	  internal::finalizers[i]();

一方は素、もう一方は当て物の後を見ていた。逆アセンブルした binary は
8/28 に relink されたもので、core は 8/27。**`exec file is newer than
core file` が出ていた**が、それが警告どおりの結果だった。

**教訓は二つ。**

	逆アセンブルを根拠に出すときは、その binary が素か当て物後かを添える
	gdb の "exec file is newer than core file" は無視してよい警告ではない

**切り分けに効いたのは「backtrace だけでは区別が付かない、区別が付くのは
`size` の値」**という問い方だった。結果的に対象違いと分かったが、同じ
対象なら決め手になっていた。

### 334 の abseil — 当て物が要る (決着済み)

「素で正しい (当て物不要)」という報告だったが、**引用されていたコードその
ものが問題の形だった。** 本人が確かめ直して訂正済み。

	mozc-3.34.6239/src/third_party/abseil-cpp/absl/debugging/internal/elf_mem_image.cc:380
	#if defined(__NetBSD__)
	  const int version_index = version_symbol->vs_vers & VERSYM_VERSION;

	patches/ に elf_mem_image を触る当て物   0 本

11.0 では `Elfnn_Versym` が struct なので通る。**-current で `Elf_Half` に
変わると `->vs_vers` が名前を指さない。** 2.29 と 3.33 に入れたのと同じ
当て物が 334 にも要る。

## 環境 — 誰がどこで測ったか

**「i386 で測った」と言っても OS の版が違えば別の結果になる。**実際に
「bambi は 11.0」という伝聞が 10.1 だった例がある。

| 箱 | OS | arch | base cc | pkgsrc の道具 |
|---|---|---|---|---|
| techne | NetBSD 11.0 | amd64 | gcc 12.5.0 | clang-21.1.8, bazel-6.4.0 |
| bambi | NetBSD 10.1 | **i386** | gcc 10.5.0 | gcc12-12.5.0nb1 (pkgsrc 側) |
| vm-aarch64 | NetBSD **11.99.7** | evbarm/aarch64 | ? | ? |
| CI の VM | 9.4 / 10.1 / 11.0 | i386 | ? | ? |

**bambi だけ base が gcc 10.5.0 で、pkgsrc の gcc12 が別に入っている。**
10.x の undefined reference を追うならこの箱だが、**i386 と 10.x の
libstdc++ の両方を一度に踏む**ので、切り分けを分けて書くこと。

**vm-aarch64 は 11.99.7 = -current である。** 誰も -current の箱が無いと
言っていたが、これが使えるかもしれない。持ち主に確認すること。

## gyp を既定にする条件 — word size ではなく JVM の有無

24db8d が LP32PLATFORMS だけで判定していて、**64bit だが JVM が無い
platform を取りこぼしていた。** 333 は最初から正しい形で書いていたので、
そちらに合わせた。

	# 誤り — 32bit だけを見ている
	.for mozc_lp32 in ${LP32PLATFORMS}
	.  if !empty(MACHINE_PLATFORM:M${mozc_lp32})
	PKG_SUGGESTED_OPTIONS+=	gyp

	# 正しい — 動く二つを名指しする (333 の形)
	.if ${OPSYS} != "NetBSD" || \
	    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64")
	PKG_SUGGESTED_OPTIONS+=	gyp

**根拠は pkgsrc の中に在る。** `devel/bazel` が JVM を要求し、
`mk/java-vm.mk` がその platform を持っている。

	devel/bazel/Makefile      PKG_JVMS_ACCEPTED= openjdk11
	mk/java-vm.mk:175         _ONLY_FOR_PLATFORMS.openjdk11=
	                            x86_64  i386  aarch64  earmv[67]hf

powerpc64 / riscv64 / mips64 / sparc64 / alpha / ia64 は**一つも居ない**。
JVM が在る四つのうち i386 と earmv[67]hf は 32bit で bazel 自身が建たない。
差し引くと x86_64 と aarch64 だけになる。

測った結果 (24db8d、`make MACHINE_ARCH=... show-var`):

	x86_64 aarch64                     (空) = bazel
	i386 earmv7hf                      gyp
	powerpc64 riscv64 mips64el
	sparc64 alpha ia64                 gyp
	Linux-x86_64                       gyp

**「動かないものを数える」より「動く二つを名指しする」方が保つ。**
platform が後から増えたとき、既定が動く側に倒れる。

## devel/bazel の BROKEN_ON_PLATFORM — 実 i386 で前後を測った

	bambi = NetBSD-10.1-i386

	直す前   BROKEN_ON_PLATFORM = NetBSD-11.99.*-*
	         PKG_FAIL_REASON    = (空)                  ← i386 なのに止まらない

	直した後 BROKEN_ON_PLATFORM = *-*-earm* ... *-*-i386 ... NetBSD-11.99.*-*
	         PKG_FAIL_REASON    = "[bsd.pkg.mk] bazel-6.4.0 is marked broken
	                               on NetBSD-10.1-i386"

`=` を `+=` にする一文字。amd64 で `show-var` を見せるより、当の platform の
上で測る方が強い。**24db8d が別 PR として出す。**
