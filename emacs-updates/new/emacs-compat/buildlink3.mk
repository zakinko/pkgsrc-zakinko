# $NetBSD$

BUILDLINK_TREE+=	emacs-compat

.if !defined(EMACS_COMPAT_BUILDLINK3_MK)
EMACS_COMPAT_BUILDLINK3_MK:=

BUILDLINK_API_DEPENDS.emacs-compat+=	${EMACS_PKGNAME_PREFIX}emacs-compat>=20260924
BUILDLINK_PKGSRCDIR.emacs-compat?=	../../devel/emacs-compat

BUILDLINK_CONTENTS_FILTER.emacs-compat=	${EGREP} '.*\.el$$|.*\.elc$$'
.endif # EMACS_COMPAT_BUILDLINK3_MK

BUILDLINK_TREE+=	-emacs-compat
