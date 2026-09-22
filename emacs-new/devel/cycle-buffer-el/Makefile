# $NetBSD$

DISTNAME=	cycle-buffer-2.16
PKGNAME=	${EMACS_PKGNAME_PREFIX}cycle-buffer-el-2.16
CATEGORIES=	devel
MASTER_SITES=	https://github.com/gavv/distfiles/raw/master/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/7e/
EXTRACT_SUFX=	.el.xz
# upstream is gone; this is the copy Gentoo's ebuild points at
WRKSRC=		${WRKDIR}
USE_TOOLS+=	xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/cycle-buffer.el
COMMENT=	Select buffer by cycling through
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/cycle-buffer

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	xz -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/cycle-buffer.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/cycle-buffer
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/cycle-buffer; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
