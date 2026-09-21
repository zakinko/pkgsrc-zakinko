# $NetBSD$

DISTNAME=	libhimmelblau-0.8.41
CATEGORIES=	zakinko security
EXTRACT_SUFX=	.crate

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://gitlab.com/samba-team/libhimmelblau
COMMENT=	Microsoft Entra ID and Intune interoperability library
LICENSE=	gnu-lgpl-v3

TOOL_DEPENDS+=	cargo-c>=0.9.27:../../devel/cargo-c

USE_TOOLS+=	pkg-config patch

PKGCONFIG_OVERRIDE=		${DESTDIR}${PREFIX}/lib/pkgconfig/himmelblau.pc
PKGCONFIG_OVERRIDE_STAGE=	post-install

# libkrimes binds "res" in get_domainname() only under cfg(target_os =
# "macos") and cfg(target_os = "linux"), so on any other target the
# following "if res == -1" refers to a value that was never bound and the
# crate does not compile.  Every BSD hits this.  The fix is offered
# upstream; until it is taken, patch it here.
#
# The crate is vendored under WRKDIR, not WRKSRC, so patches/ does not
# reach it.  That is safe: the .cargo-checksum.json written by cargo.mk
# carries an empty "files" map, so cargo does not verify the individual
# files of a vendored crate.
#
# patch is given -f so that a diff which no longer applies fails instead
# of asking "File to patch:" forever.
LIBKRIMES=	libkrimes-0.1.0

pre-configure:
	cd ${CARGO_VENDOR_DIR}/${LIBKRIMES} &&				\
	${PATCH} -f -p0 < ${FILESDIR}/libkrimes-bsd-getdomainname.patch

.include "cargo-depends.mk"

do-install:
	${RUN} cd ${WRKSRC} && cargo cinstall			\
		--destdir=${DESTDIR} --prefix=${PREFIX}		\
		--libdir=${PREFIX}/lib

.include "../../security/openssl/buildlink3.mk"
.include "../../lang/rust/cargo.mk"
.include "../../mk/bsd.pkg.mk"
