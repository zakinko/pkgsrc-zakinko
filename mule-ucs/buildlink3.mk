# $NetBSD: buildlink3.mk,v 1.5 2018/01/07 13:04:11 rillig Exp $
#

#
# Only for older GNU Emacs.  Emacs 22 or later doesn't need this because it
# incorporated Unicode support.
#

.include "../../editors/emacs/modules.mk"
# The whole file is conditional: nothing should be linked against Mule-UCS
# on an Emacs that has Unicode of its own.  That has to be decided at load
# time, which is also why BUILDLINK_TREE sits inside the .if.
.if ${EMACS_FLAVOR} == "emacs" && ${EMACS_VERSION_MAJOR} < 22

BUILDLINK_TREE+=	mule-ucs

.  if !defined(MULE_UCS_BUILDLINK3_MK)
MULE_UCS_BUILDLINK3_MK:=

BUILDLINK_API_DEPENDS.mule-ucs+=	${EMACS_PKGNAME_PREFIX}Mule-UCS>=0.84
BUILDLINK_PKGSRCDIR.mule-ucs?=		../../editors/mule-ucs

BUILDLINK_CONTENTS_FILTER.mule-ucs=	${EGREP} '.*\.el$$|.*\.elc$$'

.  endif # MULE_UCS_BUILDLINK3_MK

BUILDLINK_TREE+=	-mule-ucs
.endif
