# $NetBSD$

DISTNAME=	pdf-tools-1.3.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}pdf-tools-el-1.3.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=vedang/}
GITHUB_PROJECT=	pdf-tools
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/pdf-tools-1.3.0/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/vedang/pdf-tools/
COMMENT=	Emacs Lisp support library for PDF documents
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-text/poppler
# XXX Gentoo also depends on dev-libs/glib
# XXX Gentoo also depends on media-libs/freetype
# XXX Gentoo also depends on media-libs/harfbuzz
# XXX Gentoo also depends on media-libs/libpng
DEPENDS+=	${EMACS_PKGNAME_PREFIX}tablist-el-[0-9]*:../../editors/tablist-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/pdf-tools

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/tablist -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/pdf-tools

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
