# $NetBSD: Makefile,v 1.20 2026/01/07 08:48:48 wiz Exp $
#
# 上流 pkgsrc の sysutils/augeas/Makefile の写し。上流には patches が一本も
# 無く、PKGREVISION は 1 である。ここで足しているのは当て物 12 本。
#
# 一本を除いて全て上流 augeas にも出してあり、取り込まれたものから順に消せる。
#
#	patch-CVE-2025-2588			上流 commit af2aa88 の写し
#	patch-Makefile.in			hercules-team/augeas#889
#	patch-configure				同 #889 と #891
#	patch-src_augtool.c			#890
#	patch-examples_dump.c			#890
#	patch-man_Makefile.in			#892
#	patch-lenses_pg_hba.aug			#888
#	patch-lenses_postgresql.aug		#888
#	patch-lenses_rsyslog.aug		#888
#	patch-lenses_shellvars.aug		#893
#	patch-lenses_simplevars.aug		#893 と #887
#	patch-lenses_tests_test_simplevars.aug	#893
#
# 本題は #889 で、上流の Makefile.am が
#
#	dist_lens_DATA=$(wildcard lenses/*.aug)
#
# と書いている。$(wildcard) は GNU make の関数なので bmake では文字列のまま
# 残り、lens が一本も入らない。augtool は設定ファイルを何も読めない。pkgsrc が
# 2014 年にこの package を入れてから一度もである。NetBSD 11.0/amd64 の公式
# パッケージでも確認した。PLIST もその 462 本ぶん膨らむ。
#
# FreeBSD は USES に gmake、OpenBSD は USE_GMAKE=Yes を足して回避しているが、
# ここでは configure で glob して @LENS_FILES@ に埋める。gmake を建てずに済む。
#
# 当てているのが configure と Makefile.in、つまり生成物であることに注意。
# 上流が直すのは configure.ac と Makefile.am の方だが、そちらを当てると
# autoreconf が要る。autoconf は help2man を、automake は autoconf と perl と
# gm4 を連れてくるので、lens を並べて置くために gmake 一つを建てるのを嫌った
# のに五つ建てることになる。Fedora と OpenBSD も生成物を当てている。Debian と
# FreeBSD は元から autoreconf を回すので、あちらはソースを当てている。
#
# ソースだけ当てて autoreconf を回さない、という中間の手は無い。生成物が素の
# ままなので効かないうえ、Makefile.am の方が新しくなって automake の再生成
# 規則が発火し、aclocal が無いところで build が止まる。
#
# patch-CVE-2025-2588 は上流 commit af2aa88ab37fc48167d8c5e43b1770a4ba2ff403 を
# そのまま写したもので、手は入れていない。上流の使う _REG_ENOSYS は NetBSD の
# <regex.h> には無いが、augeas は -I ../gnulib/lib 付きで組まれ、同梱の gnulib
# の <regex.h> が読まれるので通る。1.14.1 にはまだ入っていない。
#
# TEST_TARGET=check があるので make test で回帰テストが走る。当て物から
# src/fa.c の hunk だけ外すと tests/fatest が SIGSEGV で落ちる。それがこの CVE。
#
# lens の filter を触る四本 (#887 #888 #893) は NetBSD では効かない。
# /etc/adduser.conf も /etc/wsconsctl.conf も NetBSD には無いためである。
# pkgsrc は OpenBSD でも FreeBSD でも Linux でも動くので、そちらで効く。
#
# man のパスは SUBST ではなく patch-man_Makefile.in で直している。上流 #892 が
# man/Makefile.am に install-data-hook を足す形なので、生成物側に同じものを
# 置いた。install 時に $(datadir) が埋まるので ${PREFIX} を問わない。
#
# PKGREVISION は上流の 1 に対して 2。当て物を足した一段ぶんである。CI で建て
# 直したいだけなら上げる必要はない。ゲスト側は同じ PKGBASE で PKGNAME の違う
# .tgz を消してから建てるので、番号を戻しても建て直される。
#
# pkgsrc が取り込んだら overlay/sysutils/augeas ごと消すこと。

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
