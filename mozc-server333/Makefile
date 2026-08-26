# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-server-/}

INSTALLATION_DIRS+=	libexec

# GUI を建てないので Qt は要らない。
MOZC_GYP_ARGS=	--noqt

post-configure:
	cd ${WRKSRC}/dist && \
		unzip -o -d ../dictionary jigyosyo.zip && \
		unzip -o -d ../dictionary ken_all.zip

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c ${MOZC_BUILD_MODE} \
			server/server.gyp:mozc_server

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_server \
		${DESTDIR}${PREFIX}/libexec/mozc_server

.include "Makefile.common"
.include "../../mk/bsd.pkg.mk"
