# $NetBSD$

BUILDLINK_TREE+=	corosync

.if !defined(COROSYNC_BUILDLINK3_MK)
COROSYNC_BUILDLINK3_MK:=

BUILDLINK_API_DEPENDS.corosync+=	corosync>=3.0
BUILDLINK_PKGSRCDIR.corosync?=		../../zakinko/corosync

.include "../../zakinko/libqb/buildlink3.mk"
.endif	# COROSYNC_BUILDLINK3_MK

BUILDLINK_TREE+=	-corosync
