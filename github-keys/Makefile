# $NetBSD$

DISTNAME=	github-keys-0.1.0
CATEGORIES=	zakinko security
MASTER_SITES=	${MASTER_SITE_GITHUB:=zakinko/}
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://github.com/zakinko/github-keys/
COMMENT=	Serve a user's published GitHub SSH keys to sshd
LICENSE=	2-clause-bsd

# A shell script, but not NO_BUILD: the build substitutes in the paths, since
# sshd runs AuthorizedKeysCommand with a PATH that has no ${LOCALBASE}/bin.
USE_LANGUAGES=	# none
DEPENDS+=	curl-[0-9]*:../../www/curl

MAKE_FLAGS+=	PREFIX=${PREFIX}
MAKE_FLAGS+=	LOCALBASE=${LOCALBASE}
MAKE_FLAGS+=	SYSCONFDIR=${PKG_SYSCONFDIR}

EGDIR=		${PREFIX}/share/examples/github-keys
CONF_FILES=	${EGDIR}/github-keys.map ${PKG_SYSCONFDIR}/github-keys.map

TEST_TARGET=	test

.include "../../mk/bsd.pkg.mk"
