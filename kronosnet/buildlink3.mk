# $NetBSD$

BUILDLINK_TREE+=	kronosnet

.if !defined(KRONOSNET_BUILDLINK3_MK)
KRONOSNET_BUILDLINK3_MK:=

BUILDLINK_API_DEPENDS.kronosnet+=	kronosnet>=1.35
BUILDLINK_PKGSRCDIR.kronosnet?=		../../zakinko/kronosnet
.endif	# KRONOSNET_BUILDLINK3_MK

BUILDLINK_TREE+=	-kronosnet
