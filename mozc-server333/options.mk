# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	gyp

.include "../../mk/bsd.prefs.mk"

# mozc can be built either with bazel, which is what upstream tests, or with
# gyp, which upstream keeps in maintenance mode.  3.33.6089 is the last
# release that carries gyp at all: the next tag, 3.33.6133, has neither
# src/build_mozc.py nor src/gyp/.
#
# The two builds do not produce the same set of programs.  gyp can build
# mozc_server, mozc_emacs_helper and mozc_tool, but not mozc_renderer --
# renderer.gyp only defines that target under OS=="win" and OS=="mac".  So
# inputmethod/mozc-renderer has no gyp path and does not include this file.
#
# devel/bazel does not build on 32-bit platforms -- its Makefile carries
# BROKEN_ON_PLATFORM= ${LP32PLATFORMS} -- and there is no bazel binary
# package for any of them; on the NetBSD 11.0 binary sets bazel exists for
# x86_64 and aarch64 only.  Default to the gyp build everywhere else, so that
# the Emacs input method can be built at all on those platforms.
.for _mozc_platform_ in ${LP32PLATFORMS}
.  if !empty(MACHINE_PLATFORM:M${_mozc_platform_})
PKG_SUGGESTED_OPTIONS+=	gyp
.  endif
.endfor

.include "../../mk/bsd.options.mk"

# Both builds produce the same version string, so packages built either way
# are interchangeable at run time; see patch-build__tools_mozc__version.py
# for why that needs saying.
