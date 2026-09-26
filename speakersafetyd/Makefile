# $NetBSD$

DISTNAME=	speakersafetyd-2.0.1
CATEGORIES=	zakinko audio
EXTRACT_SUFX=	.crate

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	https://github.com/AsahiLinux/speakersafetyd
COMMENT=	Software speaker protection daemon for Apple Silicon Macs
LICENSE=	mit

# main.rs reads PREFIX with option_env!() at compile time to find the
# per-machine configuration files; without it they are looked for
# under /usr/local.
MAKE_ENV+=	PREFIX=${PREFIX}

# Cold boot detection needs a flag file that rc(8) clears at boot.
SUBST_CLASSES+=		varbase
SUBST_STAGE.varbase=	pre-configure
SUBST_MESSAGE.varbase=	Setting the run directory.
SUBST_FILES.varbase=	src/backend_netbsd.rs
SUBST_VARS.varbase=	VARBASE

INSTALLATION_DIRS=	sbin share/doc/speakersafetyd share/speakersafetyd/apple

.include "cargo-depends.mk"

# The upstream Makefile installs a systemd unit and a udev rule, neither
# of which means anything here, so install by hand.
do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/target/release/speakersafetyd	\
		${DESTDIR}${PREFIX}/sbin
	${INSTALL_DATA} ${WRKSRC}/conf/apple/*.conf			\
		${DESTDIR}${PREFIX}/share/speakersafetyd/apple
	${INSTALL_DATA} ${WRKSRC}/README.md ${WRKSRC}/docs/speakers.txt	\
		${DESTDIR}${PREFIX}/share/doc/speakersafetyd

.include "../../lang/rust/cargo.mk"
.include "../../mk/bsd.pkg.mk"
