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
# devel/bazel does not build on the 32-bit platforms, and there is no bazel
# binary package for any of them either: on the NetBSD 11.0 sets bazel exists
# for x86_64 and aarch64 only.  Its Makefile means to say the first part with
# BROKEN_ON_PLATFORM= ${LP32PLATFORMS}, but a second assignment further down
# overwrites that line, so at present nothing stops a 32-bit build from being
# attempted.  Default to the gyp build everywhere else, so that the Emacs
# input method can be built at all on those platforms.
.for mozc_lp32 in ${LP32PLATFORMS}
.  if !empty(MACHINE_PLATFORM:M${mozc_lp32})
PKG_SUGGESTED_OPTIONS+=	gyp
.  endif
.endfor

# The option is acted on in Makefile.common rather than here, because
# inputmethod/mozc-tool, inputmethod/mozc-renderer and inputmethod/ibus-mozc
# share that file without including this one, and they have no gyp build to
# choose.  Keeping the .if there lets them take the bazel branch unchanged.
.include "../../mk/bsd.options.mk"

# Both builds produce the same version string, so packages built either way
# are interchangeable at run time; see patch-build__tools_mozc__version.py
# for why that needs saying.
