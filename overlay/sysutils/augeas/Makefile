# $NetBSD: Makefile,v 1.20 2026/01/07 08:48:48 wiz Exp $
#
# 上流 pkgsrc の sysutils/augeas/Makefile の写しに、PKGREVISION を 1 上げた
# だけのもの。patches/patch-CVE-2025-2588 を足したので、番号を上げないと
# PKGNAME が変わらず、手元の pkgin が入れ替えてくれない。
#
# patch は上流 commit af2aa88ab37fc48167d8c5e43b1770a4ba2ff403 をそのまま
# 写したもので、手は入れていない。上流の使う _REG_ENOSYS は NetBSD の
# <regex.h> には無いが、augeas は -I ../gnulib/lib 付きで組まれ、同梱の
# gnulib の <regex.h> が読まれるので通る。システムヘッダは見ていない。
#
# TEST_TARGET=check があるので make test で回帰テストが走る。patch から
# src/fa.c の hunk だけ外すと tests/fatest が SIGSEGV で落ちる。それがこの CVE。
#
# pkgsrc が patch を取り込んだら overlay/sysutils/augeas ごと消すこと。

DISTNAME=	augeas-1.14.1
PKGREVISION=	2
CATEGORIES=	sysutils
MASTER_SITES=	${MASTER_SITE_GITHUB:=hercules-team/}
GITHUB_RELEASE=	release-${PKGVERSION_NOREV}

MAINTAINER=	bsiegert@NetBSD.org
HOMEPAGE=	https://augeas.net/
COMMENT=	Tool for editing configuration programmatically
LICENSE=	gnu-lgpl-v2.1

USE_LIBTOOL=		yes
USE_TOOLS+=		pkg-config
GNU_CONFIGURE=		yes
PKGCONFIG_OVERRIDE+=	augeas.pc.in
TEST_TARGET=		check

# rl_char_is_quoted_p
.include "../../devel/readline/buildlink3.mk"
.include "../../textproc/libxml2/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
