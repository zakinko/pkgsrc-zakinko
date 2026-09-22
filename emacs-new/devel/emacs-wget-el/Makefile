# $NetBSD$

DISTNAME=	emacs-wget-0.5.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-wget-el-0.5.0
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/4e/
EXTRACT_SUFX=	.tar.gz
# upstream (pop-club.hp.infoseek.co.jp) is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/EmacsWget
COMMENT=	Wget interface for Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on net-misc/wget-1.8.2

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-wget

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el lpath.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/emacs-wget
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/emacs-wget; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
