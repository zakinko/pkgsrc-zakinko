# $NetBSD$

BUILDLINK_TREE+=	elisp-compat

.if !defined(ELISP_COMPAT_BUILDLINK3_MK)
ELISP_COMPAT_BUILDLINK3_MK:=

BUILDLINK_API_DEPENDS.elisp-compat+=	${EMACS_PKGNAME_PREFIX}elisp-compat>=20260924
BUILDLINK_PKGSRCDIR.elisp-compat?=	../../zakinko/elisp-compat

BUILDLINK_CONTENTS_FILTER.elisp-compat=	${EGREP} '.*\.el$$|.*\.elc$$'
.endif # ELISP_COMPAT_BUILDLINK3_MK

BUILDLINK_TREE+=	-elisp-compat
