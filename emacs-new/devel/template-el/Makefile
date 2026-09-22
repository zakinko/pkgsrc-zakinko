# $NetBSD$

DISTNAME=	template-3.3b
PKGNAME=	${EMACS_PKGNAME_PREFIX}template-el-3.3b
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_SOURCEFORGE:=emacs-template/}
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/6e/
EXTRACT_SUFX=	.tar.gz
WRKSRC=		${WRKDIR}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://emacs-template.sourceforge.net/
COMMENT=	Use templates, decorate comments, auto-update buffers
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/template

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/template
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/template; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
