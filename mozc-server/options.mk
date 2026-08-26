# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mozc
PKG_SUPPORTED_OPTIONS=	gyp

.include "../../mk/bsd.prefs.mk"

# mozc can be built either with bazel, which is what upstream tests, or with
# gyp, which upstream keeps in maintenance mode.  The gyp build needs neither
# bazel nor a JDK, but upstream has dropped the ibus client and the GTK
# candidate window from it, so only inputmethod/mozc-server and
# inputmethod/mozc-elisp include this file.
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
