# $NetBSD: Makefile,v 1.20 2026/01/07 08:48:48 wiz Exp $
#
# 上流 pkgsrc の sysutils/augeas/Makefile の写し。直しているのは三つ。
#
# 一つめが本題で、USE_TOOLS に gmake を足している。上流の Makefile.am が
#
#	dist_lens_DATA=$(wildcard lenses/*.aug)
#
# と書いていて、$(wildcard) は GNU make の関数なので bmake では文字列の
# まま展開される。結果 lens が一本も入らず、augtool は設定ファイルを何も
# 読めない。pkgsrc が 2014 年にこの package を入れてから一度もである。
# NetBSD 11.0/amd64 の公式パッケージでも確認した。FreeBSD は USES に
# gmake、OpenBSD は USE_GMAKE=Yes で、どちらも 462 本入れている。
# PLIST もその 462 本ぶん膨らむ。
#
# 二つめが patches/patch-CVE-2025-2588。上流 commit
# af2aa88ab37fc48167d8c5e43b1770a4ba2ff403 をそのまま写したもので、手は
# 入れていない。上流の使う _REG_ENOSYS は NetBSD の <regex.h> には無いが、
# augeas は -I ../gnulib/lib 付きで組まれ、同梱の gnulib の <regex.h> が
# 読まれるので通る。システムヘッダは見ていない。
#
# TEST_TARGET=check があるので make test で回帰テストが走る。patch から
# src/fa.c の hunk だけ外すと tests/fatest が SIGSEGV で落ちる。それがこの CVE。
#
# 三つめは time_t の書式。32bit 移植では long が 32bit で time_t が 64bit
# なので "%ld" は誤り。上流は今もそのままで、issue も出ていない。
#
# PKGREVISION 2 -> 3 は gmake と PLIST のぶん。2 は既に CI が Releases に
# 上げていて、据え置くと「もうある」と見なされて建て直されない。
#
# pkgsrc が取り込んだら overlay/sysutils/augeas ごと消すこと。

DISTNAME=	augeas-1.14.1
PKGREVISION=	3
CATEGORIES=	sysutils
MASTER_SITES=	${MASTER_SITE_GITHUB:=hercules-team/}
GITHUB_RELEASE=	release-${PKGVERSION_NOREV}

MAINTAINER=	bsiegert@NetBSD.org
HOMEPAGE=	https://augeas.net/
COMMENT=	Tool for editing configuration programmatically
LICENSE=	gnu-lgpl-v2.1

USE_LIBTOOL=		yes
USE_TOOLS+=		gmake pkg-config
GNU_CONFIGURE=		yes
PKGCONFIG_OVERRIDE+=	augeas.pc.in
TEST_TARGET=		check

# rl_char_is_quoted_p
.include "../../devel/readline/buildlink3.mk"
.include "../../textproc/libxml2/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
