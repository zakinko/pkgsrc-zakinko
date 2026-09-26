# $NetBSD$

.if !defined(OPENJDK25_HACKS_MK)
OPENJDK25_HACKS_MK=	# empty

# The JDK bundles its own libjpeg and compiles it with its own jconfig.h.
# If a jpeg package has put its headers in the buildlink directory they are
# found first, and the two sets of defines do not agree -- libjpeg-turbo's
# in particular.  Nothing here wants the system jpeg, so take the headers
# back out.
post-wrapper:
	${RM} -f ${BUILDLINK_DIR}/include/jconfig.h
	${RM} -f ${BUILDLINK_DIR}/include/jerror.h
	${RM} -f ${BUILDLINK_DIR}/include/jmorecfg.h
	${RM} -f ${BUILDLINK_DIR}/include/jpeglib.h

.endif
