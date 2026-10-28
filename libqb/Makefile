# $NetBSD$
#
# libqb は corosync と pacemaker の土台で、ログ、主循環、プロセス間通信を持つ。
# pkgsrc には無い。FreeBSD ports の devel/libqb を参考にしたが、FreeBSD の
# 当て物 (configure.ac から python の検査を外すもの) は要らなかった。
#
# NetBSD で直すものは三つ。
#
# configure は epoch を UTC にする date の書き方を探し、GNU の -d@ も BSD の
# -r も無いと止まる。BSD の date かどうかを FreeBSD 固有の `date -v 1d` で
# 見分けているので、NetBSD は -r を持つのに BSD と見なされない。cache 変数で
# 答えを渡す。
#
# patch-include_os__base.h は、プロセス間で共有する semaphore に POSIX の
# sem_init(pshared) を使わせる。libqb は _POSIX_THREAD_PROCESS_SHARED を見て
# 選ぶが、NetBSD は pthread の pshared を持たないのでこれを定義せず、SysV
# semaphore に落ちる。NetBSD の既定は system 全体で kern.ipc.semmns=60 しか
# なく、一接続に三つ使うので二十接続で尽き、shm の IPC が ENOSPC で失敗する。
#
# patch-lib_ringbuffer__helper.c は、その pshared semaphore が作った側の
# プロセスと一緒に消えることへの対処。NetBSD の ksem は作成者の fd として
# 生きていて (sys/kern/uipc_sem.c)、作成者が exit すると他のプロセスからは
# EINVAL になる。ringbuffer を作るのは server なので、client がそれを見たら
# server が去ったということで、ENOTCONN として返す。
#
# 測った結果 (techne、NetBSD 11.0/amd64、tests/ipc.test 35 件):
#
#	当て物なし		16 件失敗 (ENOSPC)
#	os_base.h だけ		14 件失敗 (server 終了時に -EINVAL)
#	両方			全件通過
#
# make test で tests/ が走る。check が要る。試験で socket を作る
# QB_SOCKET_DIR は sun_path の 104 バイトに収まる長さでなければならない。
# 長いと名前が黙って切り詰められて request と response の socket が潰れ、
# unix socket 系の試験が NetBSD と関係なく落ちる。

DISTNAME=	libqb-2.0.10
CATEGORIES=	zakinko devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ClusterLabs/}
GITHUB_RELEASE=	v${PKGVERSION_NOREV}
EXTRACT_SUFX=	.tar.xz

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://github.com/ClusterLabs/libqb
COMMENT=	High performance logging, tracing, IPC, and polling library
LICENSE=	gnu-lgpl-v2.1

USE_LIBTOOL=		yes
USE_TOOLS+=		gmake pkg-config
GNU_CONFIGURE=		yes
PKGCONFIG_OVERRIDE+=	lib/libqb.pc.in
TEST_TARGET=		check

BUILD_DEFS+=		VARBASE
QB_SOCKET_DIR=		${VARBASE}/run/qb
CONFIGURE_ARGS+=	--with-socket-dir=${QB_SOCKET_DIR}
# man は doxygen と libxml2 で header から作る。FreeBSD の既定と同じく作らない。
CONFIGURE_ARGS+=	--disable-man
CONFIGURE_ENV+=		ax_cv_prog_date_bsd=yes
CONFIGURE_ENV+=		ax_cv_prog_date_bsd_date=yes

OWN_DIRS+=		${QB_SOCKET_DIR}

.include "../../devel/check/buildlink3.mk"
BUILDLINK_DEPMETHOD.check=	build
.include "../../mk/bsd.pkg.mk"
