# $NetBSD$

DISTNAME=	binutils-2.40
PKGNAME=	${EMACS_PKGNAME_PREFIX}dwarf-mode-2.40
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GNU:=binutils/}
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/b9/
EXTRACT_SUFX=	.tar.xz
# binutils/dwarf-mode.el from the binutils tarball
WRKSRC=		${WRKDIR}/${DISTNAME}/binutils

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://sourceware.org/binutils/
COMMENT=	Emacs mode to browse DWARF information
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on sys-devel/binutils

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/dwarf-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile dwarf-mode.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} dwarf-mode.el ${DESTDIR}${EMACS_LISPPREFIX}/dwarf-mode
	cd ${WRKSRC} && for f in dwarf-mode.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/dwarf-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
