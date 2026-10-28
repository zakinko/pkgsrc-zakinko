# $NetBSD$
#
# corosync は cluster の node の間の membership と、順序の付いた multicast
# (CPG)、quorum を受け持つ daemon。pacemaker はこの上で動く。本家 pkgsrc
# には無い。FreeBSD ports の net/corosync3 は 3.1.10 で、当て物は無く
# 起動 script だけなので、3.2.0 をそのまま NetBSD で建てた。libqb と
# kronosnet の上に載る。
#
# 当て物は三つとも警告から見つけた未定義動作の直しで、NetBSD に限らない。
#
#	patch-exec_logsys.c		isdigit() に char を渡している
#	patch-tools_corosync-cmapctl.c	isblank() に char を渡している
#	patch-test_testcpg.c		tv_usec (NetBSD では int) を %ld で出す
#
# NetBSD の ctype は表引きなので、負の char を渡すと表の外を読む。設定
# file と cmapctl の入力 file から来る文字列で、8 bit の文字が入り得る。
#
# configure は libqb と同じく BSD の date を `date -v` で見分けて止まる
# ので、cache 変数で答えを渡す。
#
# rc.d の script は、起動の前に kern.sbmax を確かめる。libknet は root
# の handle で 8 MB の socket buffer を取れないと link を作らず、NetBSD
# の既定では取れない。zakinko/kronosnet の README.pkgsrc を参照。FreeBSD
# の rc.d も kern.ipc.maxsockbuf を同じ形で確かめている。
#
# kronosnet は nss 抜きで建てているので、暗号を使うなら corosync.conf に
# crypto_model: openssl が要る (corosync の既定は nss)。sysctl と合わせて
# README.pkgsrc に書いた。
#
# VM (NetBSD 11.0/amd64) で、一 node の cluster を rc.d から起動し、
# aes256/sha256 の knet で quorum が立ち、cfgtool、quorumtool、cmapctl が
# libqb の IPC で daemon と話せることを確かめた。kern.sbmax が既定のまま
# だと corosync は起動直後に止まり、rc.d は起動を拒む。

DISTNAME=	corosync-3.2.0
CATEGORIES=	zakinko sysutils
MASTER_SITES=	${MASTER_SITE_GITHUB:=corosync/}
GITHUB_RELEASE=	v${PKGVERSION_NOREV}

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://corosync.github.io/corosync/
COMMENT=	Cluster engine: membership, messaging and quorum
LICENSE=	modified-bsd

USE_LIBTOOL=		yes
USE_TOOLS+=		gmake pkg-config
GNU_CONFIGURE=		yes
TEST_TARGET=		check

CONFIGURE_ARGS+=	--sysconfdir=${PKG_SYSCONFBASE}
CONFIGURE_ARGS+=	--localstatedir=${VARBASE}
CONFIGURE_ENV+=		ax_cv_prog_date_bsd=yes
CONFIGURE_ENV+=		ax_cv_prog_date_bsd_date=yes

PKG_SYSCONFSUBDIR=	corosync
BUILD_DEFS+=		VARBASE PKG_SYSCONFBASE
OWN_DIRS+=		${VARBASE}/lib/corosync ${VARBASE}/log/cluster

# 設定の見本は examples に置く。動く設定は node の address と cluster の
# 名前を書くもので、見本を写しても起動はできないので CONF_FILES にはしない。
# Linux の init.d と logrotate.d は入れない。
EGDIR=			${PREFIX}/share/examples/corosync
INSTALLATION_DIRS+=	share/examples/corosync
OWN_DIRS+=		${PKG_SYSCONFDIR}/service.d ${PKG_SYSCONFDIR}/uidgid.d
RCD_SCRIPTS=		corosync

INSTALLATION_DIRS+=	share/doc/corosync
SUBST_CLASSES+=		readme
SUBST_STAGE.readme=	pre-install
SUBST_FILES.readme=	${WRKDIR}/README.pkgsrc
SUBST_VARS.readme=	PREFIX

post-extract:
	${CP} ${FILESDIR}/README.pkgsrc ${WRKDIR}/README.pkgsrc

post-install:
	${INSTALL_DATA} ${WRKDIR}/README.pkgsrc \
	    ${DESTDIR}${PREFIX}/share/doc/corosync/README.pkgsrc
	${MV} ${DESTDIR}${PKG_SYSCONFDIR}/corosync.conf.example \
	    ${DESTDIR}${EGDIR}/corosync.conf.example
	${RM} -rf ${DESTDIR}${PKG_SYSCONFDIR} \
	    ${DESTDIR}${PKG_SYSCONFBASE}/init.d \
	    ${DESTDIR}${PKG_SYSCONFBASE}/logrotate.d

.include "../../zakinko/kronosnet/buildlink3.mk"
.include "../../zakinko/libqb/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
