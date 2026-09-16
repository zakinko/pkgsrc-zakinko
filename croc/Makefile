# $NetBSD$

DISTNAME=	croc-11.5.3
CATEGORIES=	net
MASTER_SITES=	${MASTER_SITE_GITHUB:=schollz/}
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	drixter@e-utp.net
HOMEPAGE=	https://schollz.com/tinker/croc6/
COMMENT=	Fast, simple, and secure file transfer between any two computers
LICENSE=	mit

USE_LANGUAGES=	c

GO_VERSION_REQD=	127

# go-module.mk builds ./... by default, which compiles internal/tailcat on
# its own even though main only reaches it through src/tailcattransport,
# whose build tags exclude NetBSD.  internal/tailcat carries no such tag and
# imports tailscale.com, which needs github.com/tailscale/wireguard-go/ipc:
#
#   imports github.com/tailscale/wireguard-go/ipc: build constraints exclude
#       all Go files in .../wireguard-go@v0.0.0-20260715223240-2e01ba5b00f0/ipc
#
# Build what upstream's own Makefile builds: the two commands.  This also
# stops src/install (package main) from being installed as bin/install, which
# the post-install target used to remove.
GO_BUILD_PATTERN=	. ./cmd/croc-web

.include "go-modules.mk"
.include "../../lang/go/go-module.mk"
.include "../../mk/bsd.pkg.mk"
