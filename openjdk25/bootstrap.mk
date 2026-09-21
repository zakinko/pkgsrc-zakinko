# $NetBSD$

# JDK 25 accepts only a 24 or 25 boot JDK (make/conf/version-numbers.conf),
# and pkgsrc stops at lang/openjdk21, so the chain that carried openjdk11
# through openjdk21 does not reach here.  The kit below breaks that: a JDK 25
# cross-built from Linux against a NetBSD sysroot.
#
# Only amd64 has a kit, so that is the only platform this can be built on.
# Adding another means producing a kit for it first -- and because there is
# only one platform, the rest of the package does not test OPSYS.
ONLY_FOR_PLATFORM+=		NetBSD-*-x86_64

# A 9.4 sysroot stops in os_posix.cpp, where PTHREAD_STACK_MIN is undeclared
# until NetBSD 10, so 10 is as far back as the kit can be built.  The kit
# below was started, and used to compile a program, on NetBSD 10.1 and 11.0
# (amd64) before it was put where this fetches it from.  NetBSD 10's
# ld.elf_so accepts only two PT_LOAD segments per object, and the first kit
# produced had four and could not load libjli.so there; every object in this
# one carries two.
.if ${OPSYS} == "NetBSD" && ${OPSYS_VERSION} < 100000
PKG_FAIL_REASON+=		"Only supports NetBSD >= 10"
.endif

BOOT.nb10-amd64=		bootstrap-jdk-1.25.0.5.0-netbsd-10-amd64-20260921.tar.xz
# Fetched from the release the kit was built for, so the package can be
# tried before it is in the tree.  On import the committer puts the file in
# LOCAL_PORTS and this becomes ${MASTER_SITE_LOCAL:=openjdk25/}.
SITES.${BOOT.nb10-amd64}=	https://github.com/zakinko/jdk25u/releases/download/bootstrap-kit-25-20260921/
.if !empty(MACHINE_PLATFORM:MNetBSD-*-x86_64) || make(distinfo)
DISTFILES+=			${BOOT.nb10-amd64}
EXTRACT_ONLY+=			${BOOT.nb10-amd64}
.endif

ALT_BOOTDIR=		${WRKDIR}/bootstrap

# The kit is linked with an RPATH of $ORIGIN and $ORIGIN/../lib, so it finds
# its own libraries from wherever it is unpacked.  Do not set LD_LIBRARY_PATH
# for it: the launcher re-execs itself after rewriting that variable, and on
# NetBSD it cannot work out its own path to re-exec, so it dies with
# "Error: trying to exec (null)".  lang/openjdk21 sets it because the kit it
# uses has an RPATH pointing at the directory it was built in.

# NetBSD refuses a mapping that is both writable and executable while
# security.pax.mprotect.global is 1, and the JIT asks for one, so every
# unmarked launcher dies with "Could not reserve enough space in CodeHeap".
# A JDK built on NetBSD gets marked as it is linked; one cross-built from
# Linux cannot be, because paxctl(8) only exists here.  Mark the kit on the
# way in rather than requiring whoever produced it to have remembered.
.if !empty(TOOLS_PLATFORM.paxctl)
post-extract: pax-mark-bootstrap

.PHONY: pax-mark-bootstrap
pax-mark-bootstrap:
	${RUN} ${FIND} ${ALT_BOOTDIR}/bin ${ALT_BOOTDIR}/lib -type f \
	    \( -perm -u+x -o -name '*.so' \) -print |			\
	  while read f; do						\
		${TOOLS_PLATFORM.paxctl} +m "$$f" >/dev/null 2>&1 || :;	\
	  done
.endif
