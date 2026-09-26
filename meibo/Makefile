# $NetBSD$

DISTNAME=	meibo-0.1.0
CATEGORIES=	zakinko security
MASTER_SITES=	${MASTER_SITE_GITHUB:=zakinko/}
GITHUB_PROJECT=	meibo
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://github.com/zakinko/meibo/
COMMENT=	Identity lifecycle and SSO server for Japanese schools and companies
LICENSE=	apache-2.0

# 純 Go なので NetBSD/amd64, NetBSD/arm64 でそのままビルドできる。
# cgo は使わないため libc の版差にも強い。
GO_SRCPATH=	github.com/zakinko/meibo
GO_BUILD_PATTERN=	${GO_SRCPATH}/cmd/meibod \
			${GO_SRCPATH}/cmd/meiboctl \
			${GO_SRCPATH}/cmd/torii

.include "../../lang/go/go-module.mk"

# 実行時に PostgreSQL サーバが要る。同一ホストに置く必要はないので
# クライアントライブラリではなく実行時依存として書く。
DEPENDS+=	postgresql16-client-[0-9]*:../../databases/postgresql16-client

USE_TOOLS+=	pax

# meibo は自分専用のユーザで動かす。秘密鍵 (secret.key) を読めるのは
# このユーザだけにする。
PKG_GROUPS=	meibo
PKG_USERS=	meibo:meibo
PKG_GECOS.meibo=	meibo identity daemon
PKG_HOME.meibo=		${VARBASE}/db/meibo
PKG_SHELL.meibo=	${NOLOGIN}

RCD_SCRIPTS=	meibod torii

EGDIR=		${PREFIX}/share/examples/meibo
CONF_FILES=	${EGDIR}/meibo.conf ${PKG_SYSCONFDIR}/meibo.conf
CONF_FILES+=	${EGDIR}/torii.conf ${PKG_SYSCONFDIR}/torii.conf
CONF_FILES+=	${EGDIR}/routes.json ${PKG_SYSCONFDIR}/routes.json

PKG_SYSCONFSUBDIR=	meibo

# 状態ディレクトリ。secret.key を置くので 0700。
OWN_DIRS_PERMS+=	${VARBASE}/db/meibo meibo meibo 0700

INSTALLATION_DIRS=	bin ${EGDIR} share/doc/meibo

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/bin/meibod ${DESTDIR}${PREFIX}/bin/meibod
	${INSTALL_PROGRAM} ${WRKSRC}/bin/meiboctl ${DESTDIR}${PREFIX}/bin/meiboctl
	${INSTALL_PROGRAM} ${WRKSRC}/bin/torii ${DESTDIR}${PREFIX}/bin/torii
	${INSTALL_DATA} ${WRKSRC}/examples/meibo.conf ${DESTDIR}${EGDIR}/meibo.conf
	${INSTALL_DATA} ${WRKSRC}/examples/torii.conf ${DESTDIR}${EGDIR}/torii.conf
	${INSTALL_DATA} ${WRKSRC}/examples/routes.json ${DESTDIR}${EGDIR}/routes.json
	${INSTALL_DATA} ${WRKSRC}/docs/runbook.md ${DESTDIR}${PREFIX}/share/doc/meibo/runbook.md
	${INSTALL_DATA} ${WRKSRC}/docs/connectors.md ${DESTDIR}${PREFIX}/share/doc/meibo/connectors.md
	${INSTALL_DATA} ${WRKSRC}/README.md ${DESTDIR}${PREFIX}/share/doc/meibo/README.md

.include "../../mk/bsd.pkg.mk"
