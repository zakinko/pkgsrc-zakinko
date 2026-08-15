# $NetBSD: Makefile,v 1.20 2026/01/07 08:48:48 wiz Exp $
#
# 上流 pkgsrc の sysutils/augeas/Makefile の写し。直しているのは三つ。
#
# 一つめが本題で、patches/patch-configure と patch-Makefile.in。上流の
# Makefile.am が
#
#	dist_lens_DATA=$(wildcard lenses/*.aug)
#
# と書いていて、$(wildcard) は GNU make の関数なので bmake では文字列の
# まま展開される。結果 lens が一本も入らず、augtool は設定ファイルを何も
# 読めない。pkgsrc が 2014 年にこの package を入れてから一度もである。
# NetBSD 11.0/amd64 の公式パッケージでも確認した。PLIST もその 462 本ぶん
# 膨らむ。
#
# FreeBSD は USES に gmake、OpenBSD は USE_GMAKE=Yes を足して回避している
# が、ここでは configure で glob して @LENS_FILES@ に埋める。gmake を
# 建てさせずに済み、上流が取り込んだら patch を消すだけになる。
#
# makefile に素の glob (dist_lens_DATA = lenses/*.aug) を置く手もあって、
# in-tree なら通る。install 規則がリストをシェルに渡すためである。ただし
# ソース外ビルドで壊れる。automake の
#
#	for p in $$list; do if test -f "$$p"; then d=; else d="$(srcdir)/"; fi
#
# という代替は、$$p が実在の名前でないと働かない。パターンのままでは
# builddir にも srcdir にも見つからず、lens が 0 本になる。四通り
# (in-tree/VPATH x bmake/gmake) で確かめて、configure で展開する方に
# した。上流にも同じものを出す。
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
# PKGREVISION は当て物を触るたびに上げている。入るファイルが変わらなくても、
# 番号を据え置くと「もうある」と見なされて建て直されず、検証にならない。
# 3 -> 4 が gmake をやめたぶん、4 -> 5 が configure で展開する形に変えたぶん。
#
# pkgsrc が取り込んだら overlay/sysutils/augeas ごと消すこと。

DISTNAME=	augeas-1.14.1
PKGREVISION=	5
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
