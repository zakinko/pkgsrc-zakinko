# $NetBSD$

DISTNAME=	ef-themes-2.2.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}ef-themes-2.2.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=protesilaos/}
GITHUB_PROJECT=	ef-themes
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://protesilaos.com/emacs/ef-themes/
COMMENT=	Colourful and legible themes for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}modus-themes-[0-9]*:../../devel/modus-themes

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ef-themes

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/modus-themes -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ef-themes

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
