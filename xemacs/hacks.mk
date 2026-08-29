# $NetBSD$

.if !defined(XEMACS_HACKS_MK)
XEMACS_HACKS_MK=	defined

.include "../../mk/compiler.mk"

### Position-independent code does not rhyme well with dumped emacsen.
###
.if ${CC_VERSION:Mgcc-[6789].*} || ${CC_VERSION:Mgcc-[1-9][0-9].*}
PKG_HACKS+=		disable-gcc-pie
CFLAGS+=		-no-pie
.endif

.if ${CC_VERSION:Mclang-*}
PKG_HACKS+=		disable-clang-pie
CFLAGS+=		-fno-pie
.endif

.endif  # XEMACS_HACKS_MK
