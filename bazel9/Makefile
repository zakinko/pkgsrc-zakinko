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
#	src/tools/singlejar/mapped_file_posix.inc
#	#if !((defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__) || \
#	       defined(__OpenBSD__)) && __SIZEOF_POINTER__ == 8)
#	#error This code for 64 bit Unix.
#
# Two things are in that condition.  __NetBSD__ is not in the list at all,
# which is why the patches here add it; and __SIZEOF_POINTER__ == 8 is what
# stops a 32-bit build, so adding __NetBSD__ does not help i386.  port.h
# only asserts that off64_t is 64 bits, which holds on i386 as well because
# NetBSD's off_t does not vary with the architecture.
#
# So x86_64 and aarch64 are the only platforms where this can be built at
# all.  Both lines below are needed to say that, for different reasons.
# ONLY_FOR_PLATFORM names the two positively, because NOT_FOR_PLATFORM on
# its own would claim sparc64 and powerpc64 work; they have no JDK, so the
# build would stop later with a confusing "no acceptable JVM found".
#
# Only x86_64 has been built.  aarch64 is listed because the JDK and the
# 64-bit requirement are both satisfied, not because anyone has built it.
#
# NOT_FOR_PLATFORM is not redundant with the line above and must not be
# tidied away.  java-vm.mk appends to ONLY_FOR_PLATFORM rather than
# replacing it:
#
#	mk/java-vm.mk:199
#	.for _jvm_ in ${PKG_JVMS_ACCEPTED}
#	ONLY_FOR_PLATFORM+=	${_ONLY_FOR_PLATFORMS.${_jvm_}}
#
# and _ONLY_FOR_PLATFORMS.openjdk21 names i386.  The list is a union, so
# i386 matches through that entry and the line above never excludes it.
# Read the file and it looks right; run
#
#	make show-var VARNAME=ONLY_FOR_PLATFORM
#
# and i386 is in the value.  NOT_FOR_PLATFORM is subtractive, so it is what
# actually keeps a 32-bit build from starting and running as far as
# singlejar before it stops.  lang/go/version.mk assigns NOT_FOR_PLATFORM
# with "=", so ours has to be appended after that include (below), not set
# here where it would be overwritten.
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
# No bash, at build time or after.  NetBSD has none in base, so every
# mention of one here was a dependency on another package -- to build this,
# and then to run a single genrule with the bazel it produced.
#
# Two halves went into removing it.  The bootstrap scripts are patched to
# /bin/sh (patch-compile.sh and the six beside it), and the genrule shell
# in patch-src_main_java_..._BazelRuleClassProvider.java names /bin/sh
# rather than a bash.  The second half is a real change in behaviour on
# this platform: a genrule cmd written in bash syntax will fail here and
# work on Linux.  BAZEL_SH overrides the default, so installing a bash and
# pointing BAZEL_SH at it restores the old behaviour for anyone who needs
# it.
USE_TOOLS+=	pkg-config unzip zip

USE_JAVA=		yes
USE_JAVA2=		21
# No PKG_JVMS_ACCEPTED here on purpose: any JDK from 21 on will do.  The
# bootstrap did need 21 or 22, because javac 23 stopped running annotation
# processors found on the classpath, but patch-scripts_bootstrap_compile.sh
# asks for them and the build no longer cares which JDK it gets.

# rules_go fetches a Go SDK to match go.mod, and no Go SDK is distributed
# for NetBSD.  The patches make it use the host Go instead, so that is
# needed at build time.
TOOL_DEPENDS+=	go-[0-9]*:../../lang/go

# rules_go looks for a Go SDK to build the toolchain from.  There is no
# published SDK for NetBSD, so //toolchain_local points it at the one
# installed here, which means GOROOT has to be passed.  lang/go is a meta
# package; the directory is named for the version it points at.
.include "../../lang/go/version.mk"
GOROOT=		${TOOLBASE}/go${GOVERSSUFFIX}

# Keep 32-bit out (see the ONLY_FOR_PLATFORM note above): append rather than
# assign, so this survives lang/go/version.mk having just set it.
NOT_FOR_PLATFORM+=	${LP32PLATFORMS}

# cwrappers appends -pie to anything it takes for a link of an executable
# (mk/cwrappers.mk, append_executable), and it cannot see inside the @params
# files bazel writes.  Every shared library is therefore linked with both the
# -shared that is in the params and a -pie appended after it; -pie wins and
# the link stops at
#
#	ld: /usr/lib/crt0.o: in function `___start':
#	undefined reference to `main'
#
# lang/go/version.mk happens to set this too, but relying on that would make
# the build depend on an include that is here for GOROOT.

# scripts/packages/bazel.sh keeps its #!/bin/bash and is not patched.  It
# is the self-extracting installer's own script; pkgsrc installs
# output/bazel directly and never runs it, so marking it as anything else
# would be a lie about what it is written in.
#
# Where the shebang rewriting used to live: a SUBST class, not REPLACE_BASH.
# Worth recording in case anyone reaches for the latter, since it looks
# like the right variable and does nothing here.  REPLACE_BASH hangs off
# do-configure-pre-hook, and mk/configure/bsd.configure.mk wraps the
# configure machinery in .if !defined(NO_CONFIGURE).  This package sets
# NO_CONFIGURE=yes, so the replacement is never reached and the variable is
# silently ignored.

CHECK_PIE_SUPPORTED=		no
CHECK_PORTABILITY_SKIP+=	*

INSTALLATION_DIRS+=	bin

.include "../../mk/bsd.prefs.mk"

# New files come from files/ rather than from a patch.
post-extract:
	${CP} -R ${FILESDIR}/toolchain_local ${WRKSRC}/toolchain_local
	${CP} ${FILESDIR}/md5_netbsd.sh ${WRKSRC}/src/md5_netbsd.sh
	${CHMOD} +x ${WRKSRC}/src/md5_netbsd.sh

# The patches above name the JDK by placeholder rather than by path,
# because pkglint rejects a patch that writes ${PREFIX} into the source and
# because the JDK is wherever java-vm.mk settled on, which is not fixed.
#
# LOCALBASE used to be substituted here as well, for the two places that
# named a bash under it.  Neither names one any more, so the variable and
# the two files that only appeared for it are gone.  A SUBST class whose
# pattern matches nothing is not harmless: it is reported, and then it is
# ignored, which is how a substitution quietly stops being applied.
SUBST_CLASSES+=		paths
SUBST_STAGE.paths=	pre-build
SUBST_MESSAGE.paths=	Setting the path to the JDK
SUBST_FILES.paths+=	scripts/bootstrap/buildenv.sh
SUBST_FILES.paths+=	scripts/packages/template_bin.sh
SUBST_FILES.paths+=	src/main/cpp/blaze_util_bsd.cc
SUBST_VARS.paths+=	PKG_JAVA_HOME

SUBST_CLASSES+=		python
SUBST_STAGE.python=	pre-build
SUBST_MESSAGE.python=	Pointing the python toolchain at ${PYTHONBIN}
SUBST_FILES.python+=	toolchain_local/BUILD
SUBST_VARS.python+=	PYTHONBIN

# bazel reads BAZEL_SH to find the shell it runs genrules and the bootstrap
# scripts with.  It is only required on Windows, but the bootstrap passes it
# through, so name the shell the scripts are now written for.
MAKE_ENV+=	BAZEL_SH=${SH}
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

# patch-scripts_bootstrap_compile.sh puts -proc:full on the javac that builds
# the bootstrap bazel.  That is not the only javac in the build.  Once the
# bootstrap bazel runs, tools/build_rules/java_rules_skylark.bzl builds the
# VanillaJavaBuilder with a genrule that calls the JDK's javac directly:
#
#	cmd += "%s/bin/javac" % java_runtime.java_home
#	cmd += " " + " ".join(ctx.fragments.java.default_javac_flags)
#
# so on JDK 23 and later the AutoValue processor does not run there either and
# the build stops 1,778 actions in with
#
#	JarOwner.java:37: error: cannot find symbol
#	  symbol: class AutoValue_JarOwner
#	... 4 errors
#
# default_javac_flags is exactly --javacopt (JavaConfiguration.java's
# commandLineJavacFlags), so the flag reaches it without a patch.  The genrule
# runs in the exec configuration, hence --host_javacopt as well.
#
# Harmless before 23: -proc:full exists from 21 on and is the default there,
# and this package asks for 21 at the least.
EXTRA_BAZEL_ARGS+=	--javacopt=-proc:full
EXTRA_BAZEL_ARGS+=	--host_javacopt=-proc:full
EXTRA_BAZEL_ARGS+=	--tool_java_runtime_version=local_jdk
EXTRA_BAZEL_ARGS+=	--java_language_version=21
EXTRA_BAZEL_ARGS+=	--tool_java_language_version=21
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:netbsd_python3_toolchain
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_runtime
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_bootstrap
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_runtime_v
EXTRA_BAZEL_ARGS+=	--extra_toolchains=//toolchain_local:local_jdk_21_bootstrap_v
EXTRA_BAZEL_ARGS+=	--repo_env=GOROOT=${GOROOT}
# bazel runs every action with "env -" and hands it PATH and nothing else.
# pkgsrc compiles through a wrapper that reads its configuration from the
# environment, so the first compile stops with
#
#	gcc: CWRAPPERS_CONFIG_DIR is missing from environment
#
# The exec configuration needs it too, and --action_env does not reach
# there, hence both spellings.
# --repo_env as well as --action_env.  cc_configure probes the compiler
# from a repository rule, which does not see --action_env, and a probe that
# fails is not an error: the feature is simply recorded as unsupported.
# Without it the toolchain decides the linker cannot make shared objects and
# links libzstd-jni.so as a program, which stops at
#
#	ld: /usr/lib/crt0.o: undefined reference to `main'
EXTRA_BAZEL_ARGS+=	--repo_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR}
EXTRA_BAZEL_ARGS+=	--repo_env=PATH=${PATH:Q}
EXTRA_BAZEL_ARGS+=	--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR}
EXTRA_BAZEL_ARGS+=	--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR}
EXTRA_BAZEL_ARGS+=	--action_env=PATH=${PATH:Q}
EXTRA_BAZEL_ARGS+=	--host_action_env=PATH=${PATH:Q}
EXTRA_BAZEL_ARGS+=	--jobs=${MAKE_JOBS:U1}
MAKE_ENV+=		EXTRA_BAZEL_ARGS=${EXTRA_BAZEL_ARGS:Q}

do-build:
	${MKDIR} ${WRKDIR}/bazel_tmp
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${SH} ./compile.sh

do-install:
	# The bazel binary is an ELF with a zip appended, so do not strip it.
	${INSTALL_SCRIPT} ${WRKSRC}/output/bazel ${DESTDIR}${PREFIX}/bin/bazel

.include "../../lang/python/tool.mk"
.include "../../mk/java-vm.mk"
.include "../../mk/bsd.pkg.mk"
