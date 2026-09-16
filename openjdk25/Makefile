# $NetBSD$

DISTNAME=	jdk25u-${GITHUB_TAG:C/\+/-/}
# The package version is the JDK version, with nothing in front of it.
# lang/openjdk* used to carry a leading 1. -- an epoch, kept because the old
# tags folded the upstream build number into the version and a newer release
# could otherwise sort lower. Taking the tag's version straight makes that
# unnecessary: 21.0.12.1 is already above 1.21.0.12.8 on the first component,
# and the next release is above it on the third. Checked with pkg_admin
# pmatch, both directions.
#
# lang/openjdk8 keeps its 1.8 -- that one is not an epoch. JDK 8 declares
# JDK_MAJOR_VERSION=1, JDK_MINOR_VERSION=8 in common/autoconf/version-numbers,
# so 1.8.504 is what it calls itself.
PKGNAME=	openjdk25-${GITHUB_TAG:C/\+/./:C/jdk-([.0-9]+).*/\1/}
CATEGORIES=	lang
MASTER_SITES=	${MASTER_SITE_GITHUB:=battleblow/}
GITHUB_PROJECT=	jdk25u
GITHUB_TAG=	jdk-25.0.4+7-1

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://openjdk.java.net/
COMMENT=	Open-source implementation of the Java Platform, 25 LTS
LICENSE=	gnu-gpl-v2

DISTFILES=	${DEFAULT_DISTFILES}
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

JAVA_NAME=	openjdk25
JAVA_HOME=	${PREFIX}/java/${JAVA_NAME}
JAVA_WRAPPERS=	jar jarsigner java javac javadoc javap jcmd jconsole jdb \
		jdeprscan jdeps jfr jimage jinfo jlink jmap jmod jnativescan \
		jps jrunscript jshell jstack jstat jstatd jwebserver keytool \
		rmiregistry serialver

TOOL_DEPENDS+=		mozilla-rootcerts>=1.0.20140820nb2:../../security/mozilla-rootcerts

# alloca() is a GNU extension, and the JDK calls it from files it compiles
# with a strict -std=, where the declaration is not visible.
BUILDLINK_TRANSFORM+=		opt:-std=c99:-std=gnu99
BUILDLINK_TRANSFORM+=		opt:-std=c11:-std=gnu11
BUILDLINK_TRANSFORM+=		opt:-std=c++14:-std=gnu++14
BUILDLINK_TRANSFORM+=		opt:-std=c++11:-std=gnu++11

.include "../../mk/bsd.prefs.mk"

GNU_CONFIGURE=		yes
# The tree ships configure as a wrapper that runs autoconf on
# make/autoconf/configure.ac, so the usual checks for a generated script
# do not apply.
GNU_CONFIGURE_STRICT=	no
GNU_CONFIGURE_ICONV=	no
USE_GNU_CONFIGURE_HOST=	no
CONFIGURE_SCRIPT=	configure
CONFIG_SHELL=		bash
CONFIG_SUB_OVERRIDE+=	make/autoconf/build-aux/config.sub
CONFIG_GUESS_OVERRIDE+=	make/autoconf/build-aux/config.guess
CONFIG_SUB_OVERRIDE+=	make/autoconf/build-aux/autoconf-config.sub
CONFIG_GUESS_OVERRIDE+=	make/autoconf/build-aux/autoconf-config.guess
USE_LANGUAGES=		c c++
# flags-cflags.m4 still sets -std=c++14 in JDK 25.
USE_CXX_FEATURES=	c++14
# configure requires zip and unzip (basic_tools.m4), and the build runs zip
# to make the .diz debug bundles.  Neither is needed once the JDK is
# installed, so they are build tools rather than run-time dependencies.
USE_TOOLS+=		bash gmake pax pkg-config unzip zip autoconf automake
UNLIMIT_RESOURCES=	datasize stacksize virtualsize cputime

BUILDLINK_PASSTHRU_DIRS+=	${ALT_BOOTDIR}

# ${WRKSRC}/doc/building.md states that the build is not safe under make -j.
# It parallelises itself from --with-jobs instead.
MAKE_JOBS_METHOD=	manual

# OpenJDK decides native vs cross by comparing the two autoconf triples as
# strings, not the platforms they name (platform.m4: "if test
# x$OPENJDK_BUILD_AUTOCONF_NAME != x$OPENJDK_TARGET_AUTOCONF_NAME").  pkgsrc
# calls the target x86_64--netbsd while config.guess calls the build machine
# x86_64-unknown-netbsd10.1, so a plain native build is taken for a cross
# compile: it builds a second, complete JDK to compile the first one with.
# That costs an hour here and, in JDK 25, does not finish -- the buildjdk's
# adlc setup expands to something make cannot parse.  Give both the same
# name so configure sees what is actually happening.
# pkglint says gnu-configure.mk already handles --build.  It does, but only
# under USE_GNU_CONFIGURE_HOST, which is no here, so this is the only one
# that gets passed -- checked by counting --build in CONFIGURE_ARGS.
CONFIGURE_ARGS+=	--build=${MACHINE_GNU_PLATFORM}
CONFIGURE_ARGS+=	--openjdk-target=${MACHINE_GNU_PLATFORM}
CONFIGURE_ARGS+=	--with-boot-jdk=${ALT_BOOTDIR}
CONFIGURE_ARGS+=	--with-giflib=bundled
CONFIGURE_ARGS+=	--with-lcms=bundled
CONFIGURE_ARGS+=	--with-cups-include=${BUILDLINK_PREFIX.libcups}/include
CONFIGURE_ARGS+=	--with-freetype=system
CONFIGURE_ARGS+=	--with-freetype-lib=${BUILDLINK_PREFIX.freetype2}/lib
CONFIGURE_ARGS+=	--with-freetype-include=${BUILDLINK_PREFIX.freetype2}/include
CONFIGURE_ARGS+=	--with-jobs=${MAKE_JOBS:U1}
CONFIGURE_ARGS+=	--with-num-cores=${MAKE_JOBS:U1}
CONFIGURE_ARGS+=	--disable-precompiled-headers
CONFIGURE_ARGS+=	--disable-ccache
CONFIGURE_ARGS+=	--disable-javac-server
CONFIGURE_ARGS+=	--with-extra-ldflags="${COMPILER_RPATH_FLAG}${X11BASE}/lib ${COMPILER_RPATH_FLAG}${JAVA_HOME}/lib ${LDFLAGS}"
CONFIGURE_ARGS+=	--with-extra-cflags=${CFLAGS:Q}
CONFIGURE_ARGS+=	--with-extra-cxxflags=${CXXFLAGS:Q}
CONFIGURE_ARGS+=	--disable-warnings-as-errors
CONFIGURE_ARGS+=	--with-cacerts-file=${WRKDIR}/cacerts.out
CONFIGURE_ARGS+=	--with-default-make-target=product-images
# Fixing the configuration name fixes the build directory, which do-install
# has to name.  Deriving it instead means reproducing the JDK's own mapping
# from OPSYS and MACHINE_ARCH, and that mapping changes without notice.
CONFIGURE_ARGS+=	--with-conf-name=pkgsrc
# It is intentional to use CONFIGURE_ARGS instead of CONFIGURE_ENV here.
CONFIGURE_ARGS+=	USER=pkgsrc

# Avoid build errors when JAVA_HOME and CLASSPATH are defined by user.
MAKE_ENV+=	JAVA_HOME=
MAKE_ENV+=	CLASSPATH=

BUILDDIR=			${WRKSRC}/build/pkgsrc
BUILDLINK_PASSTHRU_RPATHDIRS+=	${JAVA_HOME}/lib
BUILDLINK_PASSTHRU_RPATHDIRS+=	${JAVA_HOME}/lib/server
WRKSRC=				${WRKDIR}/${DISTNAME}

.include "../../mk/compiler.mk"

.if !empty(PKGSRC_COMPILER:Mclang)
CONFIGURE_ARGS+=	--with-toolchain-type=clang
_WRAP_EXTRA_ARGS.CC+=	-Wno-format-nonliteral -Wno-sign-compare -Wno-char-subscripts
CWRAPPERS_APPEND.cc+=	-Wno-format-nonliteral -Wno-sign-compare -Wno-char-subscripts
_WRAP_EXTRA_ARGS.CXX+=	-Wno-tautological-undefined-compare
CWRAPPERS_APPEND.cxx+=	-Wno-tautological-undefined-compare

BUILDLINK_TRANSFORM+=	rm:-fcheck-new
BUILDLINK_TRANSFORM+=	rm:-fpch-deps
.  if ${MACHINE_ARCH} == "x86_64"
_WRAP_EXTRA_ARGS.CXX+=	-mstackrealign
CWRAPPERS_APPEND.cxx+=	-mstackrealign
.  endif
.else
CONFIGURE_ARGS+=	--with-toolchain-type=gcc
.endif

.include "bootstrap.mk"
.include "options.mk"

SUBST_CLASSES+=		libpath
SUBST_STAGE.libpath=	pre-configure
SUBST_FILES.libpath+=	src/hotspot/os/bsd/os_bsd.cpp
SUBST_FILES.libpath+=	make/autoconf/flags-cflags.m4
SUBST_FILES.libpath+=	make/autoconf/lib-bundled.m4
SUBST_FILES.libpath+=	make/autoconf/lib-freetype.m4
SUBST_FILES.libpath+=	make/autoconf/lib-x11.m4
SUBST_VARS.libpath=	PREFIX COMPILER_RPATH_FLAG JAVA_NAME BUILDLINK_PREFIX.zlib X11BASE

SUBST_CLASSES+=			fontpaths
SUBST_STAGE.fontpaths=		pre-configure
SUBST_MESSAGE.fontpaths=	fixing font paths
SUBST_FILES.fontpaths=		src/java.desktop/bsd/data/fontconfig/fontconfig.properties
SUBST_FILES.fontpaths+=		src/java.desktop/unix/native/common/awt/fontpath.c
SUBST_VARS.fontpaths=		PREFIX BUILDLINK_PREFIX.fontconfig

# NetBSD numbers the kqueue filters and flags differently from the FreeBSD
# and OpenBSD values the BSD port carries, and the Java side has them
# hardcoded rather than reading them from a header.
SUBST_CLASSES+=			kqueue
SUBST_STAGE.kqueue=		pre-configure
SUBST_MESSAGE.kqueue=		fixing kqueue filter values
SUBST_FILES.kqueue=		src/java.base/bsd/classes/sun/nio/ch/KQueue.java
SUBST_SED.kqueue=		-e 's/static final int EVFILT_READ  = -1;/static final int EVFILT_READ  = 0;/'
SUBST_SED.kqueue+=		-e 's/static final int EVFILT_WRITE = -2;/static final int EVFILT_WRITE = 1;/'
SUBST_SED.kqueue+=		-e 's/static final int EV_ONESHOT = 0x0010;/static final int EV_ONESHOT = 0x0004;/'
SUBST_SED.kqueue+=		-e 's/static final int EV_CLEAR   = 0x0020;/static final int EV_CLEAR   = 0x0008;/'

# Key these off the variant options.mk settled on rather than off the
# option: the group is optional, so turning jdk-hotspot-vm off without
# turning jdk-zero-vm on still builds server, and the PLIST has to agree
# with what was built.
# jdk.internal.vm.compiler -- Graal -- is gone in JDK 25; lang/openjdk21 still
# lists its jmod and its legal files, and nothing here has them.  Only jvmci
# is left of that pair.
PLIST_VARS+=			jvmci
.if ${BUILD_VARIANT} == "server"
PLIST.jvmci=			yes
.endif

pre-configure: ${WRKDIR}/cacerts.out

${WRKDIR}/cacerts.out:
	mkdir ${WRKDIR}/cacerts && cd ${WRKDIR}/cacerts && 		\
		${PREFIX}/sbin/mozilla-rootcerts extract
	${_ULIMIT_CMD} for cert in ${WRKDIR}/cacerts/*.pem; do				\
		${INFO_MSG} "Importing $$cert" &&			\
		 ${SETENV} ${CONFIGURE_ENV} LC_ALL=C			\
		  ${ALT_BOOTDIR}/bin/keytool				\
		  -noprompt						\
		  -importcert						\
		  -keystore ${.TARGET}.tmp				\
		  -alias `${ECHO} $$cert | sed 's,.*/\\([^/]*\\)\\.pem,\\1,'` \
		  -file $$cert						\
		  -storetype jks					\
		  -storepass changeit;					\
	done
	mv ${.TARGET}.tmp ${.TARGET}

# The JDK being built cannot find its own libraries.  The pkgsrc patch to
# flags-cflags.m4 -- "We prefer to use explicit run paths" -- replaces
# $ORIGIN in the run path with the installed location, so the interim JDK
# the build runs partway through (build/pkgsrc/jdk/bin/javac, which
# generates ct.sym) searches only ${PREFIX}/java/${JAVA_NAME}/lib, which
# does not exist yet:
#
#   build/pkgsrc/jdk/bin/javac: Shared object "libjli.so" not found
#
# It has to be the boot JDK's lib, not the in-tree JDK's own.  One variable
# serves the whole build and both JDKs run under it, so whichever directory
# is named, the other one finds libraries that are not its.  Naming the
# in-tree lib gets past the launcher and then breaks the boot JDK:
#
#   bootstrap/lib/libnio.so: bootstrap/lib/server/libjvm.so: version
#   SUNWprivate_1.1 required by build/pkgsrc/jdk/lib/libnet.so not defined
#
# The other direction survives because all the in-tree launcher wants from
# the boot JDK's directory is libjli.so, which is a thin shim.  This is why
# lang/openjdk21 names ALT_BOOTDIR/lib.
do-build:
	${_ULIMIT_CMD} cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
	  LD_LIBRARY_PATH=${ALT_BOOTDIR}/lib ${MAKE_PROGRAM}

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${JAVA_HOME}
	cd ${BUILDDIR}/images/jdk && pax -rwpp .		\
	  ${DESTDIR}${JAVA_HOME}/.

.include "../../audio/alsa-lib/buildlink3.mk"
CONFIGURE_ARGS+=	--with-alsa=${BUILDLINK_PREFIX.alsa-lib}
.include "../../converters/libiconv/buildlink3.mk"
.include "../../fonts/fontconfig/buildlink3.mk"
.include "../../graphics/freetype2/buildlink3.mk"
# Headers from CUPS are required to build the native implementation of
# sun.print.* which is used by java.awt.print.
BUILDLINK_DEPMETHOD.libcups?=	build
.include "../../print/libcups/buildlink3.mk"
.include "../../mk/java-env.mk"
.include "../../mk/bsd.pkg.mk"
