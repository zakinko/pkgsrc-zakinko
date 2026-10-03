# $NetBSD$

BUILDLINK_TREE+=	cl-lib-el

.if !defined(CL_LIB_EL_BUILDLINK3_MK)
CL_LIB_EL_BUILDLINK3_MK:=

BUILDLINK_API_DEPENDS.cl-lib-el+=	${EMACS_PKGNAME_PREFIX}cl-lib-el>=0.6
BUILDLINK_PKGSRCDIR.cl-lib-el?=		../../devel/cl-lib-el

BUILDLINK_CONTENTS_FILTER.cl-lib-el=	${EGREP} '.*\.el$$|.*\.elc$$'
.endif # CL_LIB_EL_BUILDLINK3_MK

BUILDLINK_TREE+=	-cl-lib-el
