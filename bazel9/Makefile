# $NetBSD$
#
# devel/bazel は 6.4.0 で止まっている。mozc 3.34 は bazel 9 を要求するので、
# それが無いと建たない。当て物は zakinko/bazel の netbsd-support と同じもの。

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

# 上流の bazel は NetBSD を知らない (OS.java の enum は FreeBSD と OpenBSD
# だけ)。当て物で足しているが、32bit で JVM を回す前提は上流にも FreeBSD
# ports の bazel9 にも OpenBSD ports にも無い。singlejar が
# #error This code for 64 bit Unix と断っている。
NOT_FOR_PLATFORM=	${LP32PLATFORMS}

WRKSRC=		${WRKDIR}
NO_CONFIGURE=	yes
USE_LANGUAGES=	c c++
USE_TOOLS+=	bash:run pkg-config unzip zip

USE_JAVA=		yes
USE_JAVA2=		21
PKG_JVMS_ACCEPTED=	openjdk21

# rules_go は go.mod に合わせて Go SDK を落としに行くが、NetBSD 向けの Go は
# 配布されていない。当て物で host の Go を使わせるので、それが要る。
TOOL_DEPENDS+=	go-[0-9]*:../../lang/go

CHECK_PIE_SUPPORTED=	no
CHECK_PORTABILITY_SKIP+=	*

INSTALLATION_DIRS+=	bin

.include "../../mk/bsd.prefs.mk"

# 新しく置くものは patch ではなく files/ から。
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

# LD_LIBRARY_PATH は立てないこと。立てると OpenJDK のランチャが自分を
# 再 exec しようとして、NetBSD では自分の path を引けずに死ぬ。

# 2GB の箱では javac が素の -Xmx で溢れる。
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
	# bazel の実体は末尾に zip を抱えた ELF なので strip しない。
	${INSTALL_SCRIPT} ${WRKSRC}/output/bazel ${DESTDIR}${PREFIX}/bin/bazel

.include "../../lang/python/tool.mk"
.include "../../mk/java-vm.mk"
.include "../../mk/bsd.pkg.mk"
