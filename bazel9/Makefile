# $NetBSD$
#
# devel/bazel is stuck at 6.4.0.  mozc 3.34 requires bazel 9, and mozc 3.33
# needs it too once its bzlmod graph is moved forward, so neither builds
# without this.  In pkgsrc bazel is a TOOL_DEPENDS of the mozc packages and
# nothing else -- no package pulls it in through buildlink3.mk.

DISTNAME=	bazel-9.2.0-dist
PKGNAME=	${DISTNAME:S/-dist//}
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=bazelbuild/}
GITHUB_PROJECT=	bazel
GITHUB_RELEASE=	${PKGVERSION_NOREV}
EXTRACT_SUFX=	.zip

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://bazel.build/
COMMENT=	Fast and correct build automation tool (LTS 9)
LICENSE=	apache-2.0

CONFLICTS+=	bazel-[0-9]*

# Upstream bazel does not know about NetBSD: the enum in OS.java lists
# FreeBSD and OpenBSD only.  The patches here add it.
#
# bazel needs a JVM to bootstrap, and mk/java-vm.mk offers openjdk21 on
# NetBSD only for x86_64, i386 and aarch64
# (_ONLY_FOR_PLATFORMS.openjdk21).  Of those, bazel's own singlejar refuses
# 32-bit outright:
#
#	src/tools/singlejar/port.h
#	#error This code for 64 bit Unix.
#
# So x86_64 and aarch64 are the only platforms where this can be built at
# all.  Saying so directly is clearer than NOT_FOR_PLATFORM=${LP32PLATFORMS},
# which claims sparc64 and powerpc64 would work; they have no JDK, so the
# build stops later with a confusing "no acceptable JVM found".
#
# Only x86_64 has been built.  aarch64 is listed because the JDK and the
# 64-bit requirement are both satisfied, not because anyone has built it.
ONLY_FOR_PLATFORM=	NetBSD-*-x86_64 NetBSD-*-aarch64

# What breaks on -current is not bazel but the abseil it fetches: the
# __NetBSD__ branch in absl/debugging/internal/elf_mem_image.cc dereferences
# version_symbol->vs_vers, and NetBSD changed Elf_Versym from a struct to an
# Elf_Half.  devel/bazel excludes -current for the same reason, and
# devel/abseil already carries the fix, keyed on _SYS_EXEC_ELF_H_ rather than
# on __NetBSD_Version__.
BROKEN_ON_PLATFORM=	NetBSD-11.99.*-*

WRKSRC=		${WRKDIR}
NO_CONFIGURE=	yes
USE_LANGUAGES=	c c++
USE_TOOLS+=	bash:run pkg-config unzip zip

USE_JAVA=		yes
USE_JAVA2=		21
PKG_JVMS_ACCEPTED=	openjdk21

# rules_go fetches a Go SDK to match go.mod, and no Go SDK is distributed
# for NetBSD.  The patches make it use the host Go instead, so that is
# needed at build time.
TOOL_DEPENDS+=	go-[0-9]*:../../lang/go

CHECK_PIE_SUPPORTED=	no
CHECK_PORTABILITY_SKIP+=	*

INSTALLATION_DIRS+=	bin

.include "../../mk/bsd.prefs.mk"

# New files come from files/ rather than from a patch.
post-extract:
	${CP} -R ${FILESDIR}/toolchain_local ${WRKSRC}/toolchain_local
	${CP} ${FILESDIR}/md5_netbsd.sh ${WRKSRC}/src/md5_netbsd.sh
	${CHMOD} +x ${WRKSRC}/src/md5_netbsd.sh

SUBST_CLASSES+=		python
SUBST_STAGE.python=	pre-patch
SUBST_MESSAGE.python=	Pointing the python toolchain at ${PYTHONBIN}
SUBST_FILES.python+=	toolchain_local/BUILD
SUBST_VARS.python+=	PYTHONBIN

MAKE_ENV+=	BAZEL_SH=${TOOLS_PATH.bash}
MAKE_ENV+=	JAVA_HOME=${PKG_JAVA_HOME}
MAKE_ENV+=	JAVA_VERSION=21
MAKE_ENV+=	EMBED_LABEL=${PKGVERSION_NOREV}
MAKE_ENV+=	BAZEL_DEV_VERSION_OVERRIDE=${PKGVERSION_NOREV}
MAKE_ENV+=	TMPDIR=${WRKDIR}/bazel_tmp

# Do not set LD_LIBRARY_PATH.  With it set, the OpenJDK launcher tries to
# re-exec itself, and on NetBSD it cannot work out its own path and dies.

# On a 2 GB machine javac runs out of memory with the default -Xmx.
BAZEL_JAVAC_OPTS=	-J-Xmx1g -J-Xms128m
MAKE_ENV+=		BAZEL_JAVAC_OPTS=${BAZEL_JAVAC_OPTS:Q}

EXTRA_BAZEL_ARGS+=	--tool_java_runtime_version=local_jdk
EXTRA_BAZEL_ARGS+=	--java_language_version=21
EXTRA_BAZEL_ARGS+=	--tool_java_language_version=21
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:netbsd_python3_toolchain
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_runtime
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_bootstrap
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_runtime_v
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_bootstrap_v
EXTRA_BAZEL_ARGS+=	--repo_env=GOROOT=${GOROOT}
EXTRA_BAZEL_ARGS+=	--host_linkopt=-lm
EXTRA_BAZEL_ARGS+=	--linkopt=-lm
EXTRA_BAZEL_ARGS+=	--jobs=${MAKE_JOBS:U1}
MAKE_ENV+=		EXTRA_BAZEL_ARGS=${EXTRA_BAZEL_ARGS:Q}

do-build:
	${MKDIR} ${WRKDIR}/bazel_tmp
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${TOOLS_PATH.bash} ./compile.sh

do-install:
	# The bazel binary is an ELF with a zip appended, so do not strip it.
	${INSTALL_SCRIPT} ${WRKSRC}/output/bazel ${DESTDIR}${PREFIX}/bin/bazel

.include "../../lang/python/tool.mk"
.include "../../mk/java-vm.mk"
.include "../../mk/bsd.pkg.mk"
