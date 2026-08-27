# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	gyp

.include "../../mk/bsd.prefs.mk"

# 3.34.6239 に gyp は入っていない。src/build_mozc.py も src/gyp/ も .gyp も
# 一本も無く、建て方は bazel だけである。消えたのは 3.34 ではなく 3.33.6133
# で、その一つ前の 3.33.6089 が gyp を積んだ最後のタグになる。gyp option は
# その足場を 3.33.6089 の tarball から持ってきて使う (Makefile.common の
# post-extract)。
#
# bazel の道は zakinko/bazel9 が要る。bazel は bootstrap に JVM が要り、
# mk/java-vm.mk が NetBSD で openjdk21 を出すのは x86_64 と i386 と aarch64
# だけで、そのうち i386 は bazel 自身が拒む:
#
#	src/tools/singlejar/mapped_file_posix.inc
#	#error This code for 64 bit Unix.	(__SIZEOF_POINTER__ == 8 を要求)
#
# 残るのは x86_64 と aarch64 の二つ。それ以外では bazel が建たないので、
# gyp を既定にする。
#
# 実測したのは NetBSD/x86_64 だけである。aarch64 を数に入れているのは JDK と
# 64bit の条件が両方満たされるからで、誰かが建てたからではない。
.if ${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64")
PKG_SUGGESTED_OPTIONS+=	gyp
.endif

.include "../../mk/bsd.options.mk"

# 既定を外して bazel を頼まれたときの止め方。ここが無いと
# zakinko/bazel9 の ONLY_FOR_PLATFORM に当たって「bazel-9.2.0 is not
# available for this platform」で止まり、package が足りないように見えて、
# option の選び方が違うようには見えない。
.if empty(PKG_OPTIONS:Mgyp) && (${OPSYS} != "NetBSD" || \
    (${MACHINE_ARCH} != "x86_64" && ${MACHINE_ARCH} != "aarch64"))
PKG_FAIL_REASON+=	"The bazel build needs zakinko/bazel9, which builds"	\
			"only on NetBSD x86_64 and aarch64."			\
			"Set PKG_OPTIONS.mozc=gyp to build mozc here."
.endif

# gyp の道が届く範囲は build_mozc.py が決める。当て物で NetBSD を足したので
# NetBSD と、上流が元から見ている Linux では通る。FreeBSD や SunOS では
#
#	CRITICAL: target_platform FreeBSD is invalid.
#
# で止まる。理由が明示されるので、ここでは platform を狭めていない。

# どちらで建てても版の文字列は同じなので、実行時には入れ替えが利く。
# なぜそれを言う必要があるかは patch-build__tools_mozc__version.py を参照。
