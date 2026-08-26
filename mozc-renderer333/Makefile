# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-renderer-/}

INSTALLATION_DIRS+=	libexec share/icons

DEPENDS+=	xdg-utils-[0-9]*:../../misc/xdg-utils
DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../zakinko/mozc-server333

# **これだけは gyp で建たないので options.mk を読まない。** 3.33 の
# renderer/renderer.gyp が mozc_renderer を定義しているのは OS=="win" と
# OS=="mac" の conditions の中だけで、Qt を有効にした configure でも
# ninja のターゲットに現れない。bazel の側には renderer/qt:mozc_renderer が
# 在る。2.29 の docs/build_mozc_in_docker.md の
#
#	⚠️ The GYP build no longer support the Ibus client and the GTK
#	   candidate window.
#
# が実装側でそうなっている、というだけで、抜けではなく上流の決定である。
#
# PKG_OPTIONS.mozc=gyp を書いた箱ではこれは建たない。32bit では bazel が
# 建たないので (singlejar の #error This code for 64 bit Unix)、i386 に
# 候補窓は載らない。mozc-server と mozc-elisp と mozc-tool は載る。

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			--client_debug \
			build \
			renderer/qt:mozc_renderer \
			--jobs=${MAKE_JOBS:U1} \
			--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--host_action_env=PATH=${PATH} \
			--action_env=PATH=${PATH} \
			--sandbox_debug \
			--verbose_failures \
			--subcommands \
			${BAZEL_ARGS} \
			--config oss_linux --config release_build

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/bazel-out/${OSDEST}/bin/renderer/qt/mozc_renderer \
		${DESTDIR}${PREFIX}/libexec
.for f in ui-alpha_full ui-alpha_half ui-dictionary ui-direct \
	ui-hiragana ui-katakana_full ui-katakana_half ui-properties ui-tool
	${INSTALL_DATA} ${WRKSRC}/data/images/unix/${f}.png \
		${DESTDIR}${PREFIX}/share/icons/${f:S/^ui-/mozc-/}.png
.endfor
	${INSTALL_DATA} ${WRKSRC}/data/images/product_icon_32bpp-128.png \
		${DESTDIR}${PREFIX}/share/icons/mozc.png

.include "../../zakinko/mozc-server333/Makefile.common"
.include "../../mk/bsd.pkg.mk"
