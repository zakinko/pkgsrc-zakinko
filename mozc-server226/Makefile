# $NetBSD: Makefile,v 1.21 2026/05/14 16:41:20 ryoon Exp $

PKGNAME=	${DISTNAME:S/mozc-/mozc-server-/}
PKGREVISION=	46

# mozc-server226 が入れるのは libexec/mozc_server 一つだけで、ldd を取ると
# -lstdc++ -lm -lc -lgcc_s -lpthread しか使っていない。GUI は要らない。
# 共有 Makefile.common が gtk2 と qt5 を無条件に buildlink していて、それが
# USE_X11 を立てるので、X を入れていない箱では fetch にも進めなかった。
MOZC_NO_GUI=	yes

INSTALLATION_DIRS+=	libexec

post-patch:
	${RM} ${WRKSRC}/unix/uim/uim.gyp

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build \
		-c ${MOZC_BUILD_MODE} \
			dictionary/dictionary_base.gyp:text_dictionary_loader \
			server/server.gyp:mozc_server

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_server \
		${DESTDIR}${PREFIX}/libexec/mozc_server

.include "../../zakinko/mozc-server226/Makefile.common"
.include "../../mk/bsd.pkg.mk"
