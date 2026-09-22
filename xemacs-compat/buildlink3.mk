# $NetBSD$

BUILDLINK_TREE+=	xemacs-compat

.if !defined(XEMACS_COMPAT_BUILDLINK3_MK)
XEMACS_COMPAT_BUILDLINK3_MK:=

.include "../../editors/emacs/modules.mk"
BUILDLINK_API_DEPENDS.xemacs-compat+=	${EMACS_PKGNAME_PREFIX}xemacs-compat>=20260923
BUILDLINK_PKGSRCDIR.xemacs-compat?=	../../zakinko/xemacs-compat

BUILDLINK_CONTENTS_FILTER.xemacs-compat=	${EGREP} '.*\.el$$|.*\.elc$$'
.endif # XEMACS_COMPAT_BUILDLINK3_MK

BUILDLINK_TREE+=	-xemacs-compat
