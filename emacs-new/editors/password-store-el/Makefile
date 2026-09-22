# $NetBSD$

DISTNAME=	password-store-1.7.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}password-store-el-1.7.4
CATEGORIES=	editors security
MASTER_SITES=	http://git.zx2c4.com/password-store/snapshot/
EXTRACT_SUFX=	.tar.xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.passwordstore.org/
COMMENT=	Emacs interface to pass, the standard UNIX password manager
LICENSE=	gnu-gpl-v2

# the same distfile as security/password-store; this is its contrib/emacs
DEPENDS+=	password-store-[0-9]*:../../security/password-store
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}with-editor-el-[0-9]*:../../devel/with-editor-el

WRKSRC=		${WRKDIR}/${DISTNAME}/contrib/emacs
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/password-store

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/with-editor \
		-f batch-byte-compile password-store.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} password-store.el password-store.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/password-store

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
