# $NetBSD$

DISTNAME=	sly-1.0.43.20260403
PKGNAME=	${EMACS_PKGNAME_PREFIX}sly-el-1.0.43.20260403
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=joaotavora/}
GITHUB_PROJECT=	sly
GITHUB_TAG=	759c0ff8741ced8793257f2b7ed95a23e13e1407
WRKSRC=		${WRKDIR}/sly-759c0ff8741ced8793257f2b7ed95a23e13e1407

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/joaotavora/sly/
COMMENT=	Sylvester the Cat's Common Lisp IDE for GNU Emacs
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-lisp/asdf
# XXX Gentoo also depends on dev-lisp/sbcl

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/sly

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/sly

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
