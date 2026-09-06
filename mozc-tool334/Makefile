# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-tool-/}

INSTALLATION_DIRS+=	libexec

DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../zakinko/mozc-server334

# gui.gyp は mozc_tool を条件節の外で定義しているので、gyp では Qt を見つけ
# させるだけで建つ (patch-gui_qt__libraries.gypi と
# patch-gui_qt__tool__dir.gypi)。そこが mozc-renderer と違う。
# 3.34 に gyp は無いが、Makefile.common の post-extract が 3.33.6089 から
# 足場を持ってくる。

# Qt6 の QtGui は qopengl.h 越しに GL/gl.h を引く。MesaLib を依存に挙げて
# いないと buildlink が GL を compiler へ見せず、
#
#	gui/base/util.cc
#	qopengl.h:115:13: fatal error: GL/gl.h: No such file or directory
#
# で止まる。header は在って見えないだけである。gyp で建てていた 333 では
# 露見しなかった。bazel へ生の -I を渡す手は execution root の外を指すと
# 拒まれるので、cc_configure に渡す。BAZEL_CXXOPTS を見て toolchain を組む
# ときに compiler の search path を読むので、そこに入った場所は
# cxx_builtin_include_directories に載り、sandbox にも mount される。
# buildlink だけでは compiler からは見えても sandbox の中には現れない。
.include "../../graphics/MesaLib/buildlink3.mk"

MAKE_ENV+=	BAZEL_CXXOPTS=-std=gnu++17:-I${PREFIX}/include:-I${X11BASE}/include
# link も同じ穴で、mozc の pkg_config_repository は --libs-only-l で -l しか
# 集めない (Linux では Qt が既定の path に居る)。pkgsrc の Qt6 は
# ${PREFIX}/qt6/lib に居て buildlink は LDFLAGS で -L を渡すが、bazel は
# env - で環境を捨て、cc_configure は LDFLAGS を読まない。読むのは
# BAZEL_LINKOPTS なので、そこから toolchain に焼き込む。
MAKE_ENV+=	BAZEL_LINKOPTS=-L${PREFIX}/qt6/lib:-Wl,-R${PREFIX}/qt6/lib:-L${PREFIX}/lib:-Wl,-R${PREFIX}/lib:-L${X11BASE}/lib:-Wl,-R${X11BASE}/lib

.include "../../zakinko/mozc-server334/options.mk"

.if empty(PKG_OPTIONS:Mgyp)
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			build \
			gui/tool:mozc_tool \
			--jobs=${MAKE_JOBS:U1} \
			--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--host_action_env=PATH=${PATH} \
			--action_env=PATH=${PATH} \
			--verbose_failures \
			${BAZEL_ARGS} \
			--config oss_linux --config release_build

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/bazel-out/${OSDEST}/bin/gui/tool/mozc_tool \
		${DESTDIR}${PREFIX}/libexec
.else
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c ${MOZC_BUILD_MODE} \
			--jobs=${MAKE_JOBS:U1} \
			gui/gui.gyp:mozc_tool

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_tool \
		${DESTDIR}${PREFIX}/libexec
.endif

.include "../../zakinko/mozc-server334/Makefile.common"
.include "../../mk/bsd.pkg.mk"
