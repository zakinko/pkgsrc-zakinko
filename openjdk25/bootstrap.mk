# $NetBSD$

# openjdk21 は ftp.NetBSD.org に置かれた bootstrap kit で自分を建てる。25 の
# kit はまだ誰も作っていないので、ここでは二つの道を用意する。
#
#   1. OPENJDK25_BOOT_JDK に、この箱で動く JDK 24 か 25 の path を渡す
#   2. 何も渡さなければ、kit を distfiles に置いて使う (kit が出来てから)
#
# 25 の source が要求する boot は 24 か 25 である (make/conf/version-numbers.conf
# の DEFAULT_ACCEPTABLE_BOOT_VERSIONS)。ただしこれは宣言であって、実際の制約は
# 言語機能なので、22 でも建つことを確かめてある。22 で建てるときは
# BOOT_RELAX を yes にする。

.if ${OPSYS} == "NetBSD" && ${OPSYS_VERSION} < 090000
PKG_FAIL_REASON+=		"Only supports NetBSD >= 9"
.endif

ONLY_FOR_PLATFORM+=		NetBSD-*-x86_64

.if defined(OPENJDK25_BOOT_JDK)
ALT_BOOTDIR=			${OPENJDK25_BOOT_JDK}
.else
PKG_FAIL_REASON+=		"OPENJDK25_BOOT_JDK に JDK 24/25 (または BOOT_RELAX=yes で 22) の path を渡してください" \
				"NetBSD 向けの bootstrap kit はまだ配られていません"
.endif

# 22 を boot にするときは、受け入れ版の宣言を緩める。javac が JDK 22 の言語
# 機能 (unnamed variable の _) を解釈できれば通ることを確認済み。21 では
# Check.java の _ で parse error になる。
.if defined(BOOT_RELAX) && !empty(BOOT_RELAX:M[Yy][Ee][Ss])
SUBST_CLASSES+=			bootrelax
SUBST_STAGE.bootrelax=		pre-configure
SUBST_MESSAGE.bootrelax=	Relaxing the accepted boot JDK versions
SUBST_FILES.bootrelax=		make/conf/version-numbers.conf
SUBST_SED.bootrelax=		-e 's/^DEFAULT_ACCEPTABLE_BOOT_VERSIONS=.*/DEFAULT_ACCEPTABLE_BOOT_VERSIONS="22 23 24 25"/'
.endif

CONFIGURE_ENV+=			LD_LIBRARY_PATH=${ALT_BOOTDIR}/lib
