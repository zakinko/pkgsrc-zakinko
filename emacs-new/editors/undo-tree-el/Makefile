# $NetBSD$

DISTNAME=	undo-tree-0.8.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}undo-tree-el-0.8.2
CATEGORIES=	editors
MASTER_SITES=	https://elpa.gnu.org/packages/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.dr-qubit.org/undo-tree.html
COMMENT=	Undo trees and visualization
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}queue-el-[0-9]*:../../devel/queue-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/undo-tree

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/queue -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/undo-tree

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
