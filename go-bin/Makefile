# $NetBSD: Makefile,v 1.25 2025/12/23 19:19:36 bsiegert Exp $

PKGNAME=	go-bin-1.27.1
CATEGORIES=	lang
MASTER_SITES=	https://dl.google.com/go/

MAINTAINER=	tnn@NetBSD.org
HOMEPAGE=	https://golang.org/
COMMENT=	Bootstrap toolchain for lang/go*
LICENSE=	modified-bsd

NO_BUILD=	yes
PLIST_SRC=	${WRKDIR}/PLIST_DYNAMIC
USE_LANGUAGES=	# none
USE_TOOLS+=	pax perl:run bash:run
WRKSRC=		${WRKDIR}/go

.include "../../lang/go/go-vars.mk"

REPLACE_PERL+=			src/*/*.pl src/*/*/*.pl
REPLACE_PERL+=			src/net/http/cgi/testdata/test.cgi
REPLACE_BASH+=			*/*.bash */*/*.bash */*/*/*.bash */*/*/*/*.bash
REPLACE_BASH+=			*/*/*/*/*/*/*.bash */*/*/*/*/*/*/*.bash
REPLACE_BASH+=			*/*/*.sh */*/*/*.sh */*/*/*/*.sh */*/*/*/*/*/*/*.sh
REPLACE_BASH+=			lib/wasm/go_js_wasm_exec
REPLACE_BASH+=			lib/wasm/go_wasip1_wasm_exec
CHECK_INTERPRETER_SKIP+=	*/*.rc
CHECK_PORTABILITY_SKIP+=	misc/ios/clangwrap.sh
CHECK_SHLIBS_SUPPORTED=		no
CHECK_RELRO_SUPPORTED=		no

.include "../../mk/bsd.prefs.mk"

.include "platforms.mk"

.for _platform_ in ${GO_BIN_PLATFORMS}
ONLY_FOR_PLATFORM+=	${_platform_}
DIST.${_platform_}=	go${PKGVERSION_NOREV}.${GO_BIN_ARCHIVE.${_platform_}}.tar.gz
.  if !empty(MACHINE_PLATFORM:M${_platform_}) || make(distinfo) || make(mdi)
DISTFILES+=		${DIST.${_platform_}}
EXTRACT_ONLY+=		${DIST.${_platform_}}
.  endif
.endfor

INSTALLATION_DIRS+=	go-bin

do-install:
	cd ${WRKSRC} && ${PAX} -rw . ${DESTDIR}${PREFIX}/go-bin
#
# Removing the signatures is required to operate inside a chroot, but breaks
# running them outside.  We're left with no choice but to make it configurable
# by the user.
#
.if ${MACHINE_PLATFORM:MDarwin-*-*} && defined(DARWIN_CHROOTED)
	for f in ${DESTDIR}${PREFIX}/go-bin/bin/* \
		 ${DESTDIR}${PREFIX}/go-bin/pkg/tool/darwin_*/*; do \
		/usr/bin/codesign --remove-signature $$f; \
	done
.endif

post-install:
	cd ${DESTDIR}${PREFIX} && find go-bin -type f -print	\
	    > ${WRKDIR}/PLIST_DYNAMIC

.include "../../mk/bsd.pkg.mk"
