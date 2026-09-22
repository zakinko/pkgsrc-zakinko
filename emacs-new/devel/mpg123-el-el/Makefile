# $NetBSD$

DISTNAME=	mpg123-el-1.65
PKGNAME=	${EMACS_PKGNAME_PREFIX}mpg123-el-el-1.65
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.tar.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.gentei.org/~yuuji/software/mpg123el/
COMMENT=	Emacs front-end to mpg123 audio player and OggVorbis audio player
LICENSE=	# XXX mpg123-el

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on media-sound/alsa-utils
# XXX Gentoo also depends on media-sound/mpg123

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mpg123-el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/mpg123-el

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
