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

## 未解決 — 二人の報告が食い違っているもの

### 3.33 の `FinalizeSingletons` は何を踏んでいるのか

同じコードについて逆アセンブルの読みが割れている。**PR の文面がこれに依るので、
どちらかに寄せる必要がある。**

25689 の読み — 256 個を無条件に舐める

	.L14:  call *(%rbx)
	       addq $8, %rbx
	       cmpq $…finalizersE+2048, %rbx    2048/8 = 256
	       jne  .L14

15aaa173 の読み — `size` で止まっており、その範囲の中に null が居る

	+28: mov  …N_14sizeE,%eax
	+34: test %eax,%eax
	+36: jle  <+63>                          size <= 0 なら抜ける
	+47: call *(%r12,%rbx,8)                 ← ここで番地 0 を呼んだ

	constinit std::array<void (*)(void), 256> finalizers = {};
	constinit int size = 0;
	void FinalizeSingletons() {
	  for (int i = 0; i < internal::size; ++i) {   ← 256 ではなく size
	    internal::finalizers[i]();

**「未登録の枠を舐めた」と「登録済みのはずの枠が null だった」では、直し方も
書き方も変わる。** 最適化の度合いが違う二つの binary を見ている可能性がある。
どちらの binary をどの版から建てたかを添えて突き合わせること。

### 334 の abseil — 当て物が要る

15aaa173 から「素で正しい (当て物不要)」と報告があったが、**引用されていた
コードそのものが問題の形である。** 24db8d が実物で確認した。

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
