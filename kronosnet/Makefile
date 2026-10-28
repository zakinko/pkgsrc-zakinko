# $NetBSD$
#
# kronosnet (libknet) は corosync 3 の通信層。複数の link を束ね、切り替え、
# 暗号化と圧縮を plugin で載せる。本家 pkgsrc には無い。FreeBSD ports の
# devel/kronosnet は 1.26 で止まっていて、当て物も man の一本だけなので、
# 1.35 を NetBSD に合わせ直した。当て物の理由は各 patch の頭に書いた。
#
#	patch-libknet_crypto__openssl.c		explicit_bzero、EVP_MD_size の -1
#	patch-libknet_threads__common.h		pthread_setname_np の引数
#	patch-libknet_handle.c			float を通した buffer 長 (-Werror)
#	patch-libknet_transport__common.c	SO_RCVBUF の ENOBUFS、IP_BINDANY の EPERM
#	patch-libknet_tests_test-common.c	試験補助の長さ (-Werror)
#	patch-libknet_tests_fun__pmtud__crypto.c	<net/ethernet.h>
#
# configure は libqb と同じく BSD の date を `date -v` で見分けて止まる
# ので、cache 変数で答えを渡す。explicit_bzero も無いと止まるので、有る
# ことにして crypto_openssl.c で explicit_memset に読み替える。
#
# 外したもの。nss の暗号 plugin (openssl の方を使う)、libnozzle (tap
# device の library で、BSD 版が FreeBSD の <net/ethernet.h> 前提。corosync
# は使わない)、wireshark の dissector、doxygen で作る man。
#
# libknet は socket buffer を 8 MB 求めるが、NetBSD の kern.sbmax の既定
# (256 KB) では 128 KB までしか取れない。root で動く handle (corosync) は
# 取れなかったときに止まる作りなので、必要な sysctl を README.pkgsrc に
# 書いて doc に入れる。
#
# make test は 83 本全て通る (NetBSD 11.0/amd64、一般ユーザ)。当て物を
# 入れる前は 70 本が落ちた。

DISTNAME=	kronosnet-1.35
CATEGORIES=	zakinko net
MASTER_SITES=	${MASTER_SITE_GITHUB:=kronosnet/}
GITHUB_RELEASE=	v${PKGVERSION_NOREV}
EXTRACT_SUFX=	.tar.xz

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://kronosnet.org/
COMMENT=	Network abstraction layer for high-availability clusters
LICENSE=	gnu-lgpl-v2.1 AND gnu-gpl-v2

USE_LIBTOOL=		yes
USE_TOOLS+=		gmake pkg-config
GNU_CONFIGURE=		yes
PKGCONFIG_OVERRIDE+=	libknet/libknet.pc.in
TEST_TARGET=		check

CONFIGURE_ARGS+=	--disable-man
CONFIGURE_ARGS+=	--disable-crypto-nss
CONFIGURE_ARGS+=	--disable-libnozzle
CONFIGURE_ARGS+=	--disable-wireshark-dissector
CONFIGURE_ENV+=		ax_cv_prog_date_bsd=yes
CONFIGURE_ENV+=		ax_cv_prog_date_bsd_date=yes
CONFIGURE_ENV+=		ac_cv_func_explicit_bzero=yes

INSTALLATION_DIRS+=	share/doc/kronosnet

post-install:
	${INSTALL_DATA} ${FILESDIR}/README.pkgsrc \
	    ${DESTDIR}${PREFIX}/share/doc/kronosnet/README.pkgsrc

.include "../../archivers/bzip2/buildlink3.mk"
.include "../../archivers/lz4/buildlink3.mk"
.include "../../archivers/lzo/buildlink3.mk"
.include "../../archivers/xz/buildlink3.mk"
.include "../../archivers/zstd/buildlink3.mk"
.include "../../devel/zlib/buildlink3.mk"
.include "../../security/openssl/buildlink3.mk"
# <qb/qblist.h> だけを使い、link はしない。
BUILDLINK_DEPMETHOD.libqb=	build
.include "../../zakinko/libqb/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
