# $NetBSD: Makefile,v 1.18 2023/09/06 01:50:50 msaitoh Exp $

# 上流 inputmethod/anthy の写し。Makefile.common も一緒に持っているので、
# 上流ではなく隣の写しを読む。上流が動いてもこちらは動かない。
.include	"../../zakinko/anthy/Makefile.common"

# 上流の 1 に対して 3。patch を 8 本足した一段ぶん。上げないと PKGNAME が
# 上流と同じままで、pkgin が「同じものが入っている」と見て入れ替えない。
#
# 2 -> 3 は辞書と C の直しを足したぶん。elisp だけだった 2 と違って、
# 入る辞書の中身と共有ライブラリが変わる。
PKGREVISION=	3
EXTRACT_ONLY=	${DISTNAME}.tar.gz

MAINTAINER=	taya@NetBSD.org
COMMENT=	Kana Kanji conversion system

USE_LIBTOOL=		yes
USE_LANGUAGES=		c
USE_TOOLS+=		printf
GNU_CONFIGURE=		yes

CONFIGURE_ENV+=		EMACS=no
EGDIR=			${PREFIX}/share/examples/anthy
INSTALL_MAKE_FLAGS+=	sysconfdir=${EGDIR}
INSTALLATION_DIRS=	share/doc/anthy
CONF_FILES+=		${EGDIR}/anthy-conf ${PKG_SYSCONFDIR}/anthy-conf

PKGCONFIG_OVERRIDE+=	anthy.pc.in

UNLIMIT_RESOURCES+=	stacksize

.include	"options.mk"


post-patch:
.if !empty(PKG_OPTIONS:Manthy-2ch-dict)
	${CP} ${DISTDIR}/2ch.t ${WRKSRC}/mkworddic
	# Don't change "\n".
	@${PRINTF} "/read @top_srcdir@\\\\/mkworddic\\\\/base.t\na\nread @top_srcdir@/mkworddic/2ch.t\n.\nw\n" | \
	ed -s ${WRKSRC}/mkworddic/dict.args.in
.endif
.if !empty(PKG_OPTIONS:Manthy-okinawa-dict)
	${CP} ${DISTDIR}/${OKIDIC_VERSION}.t ${WRKSRC}/mkworddic/okinawa.t
	# Don't change "\n".
	@${PRINTF} "/read @top_srcdir@\\\\/mkworddic\\\\/base.t\na\nread @top_srcdir@/mkworddic/okinawa.t\n.\nw\n" | \
	ed -s ${WRKSRC}/mkworddic/dict.args.in
.endif

post-install:
	${INSTALL_DATA} ${WRKSRC}/doc/DICUTIL ${DESTDIR}${PREFIX}/share/doc/anthy
	${INSTALL_DATA} ${WRKSRC}/doc/ELISP ${DESTDIR}${PREFIX}/share/doc/anthy
	${INSTALL_DATA} ${WRKSRC}/doc/GUIDE.english ${DESTDIR}${PREFIX}/share/doc/anthy
	${INSTALL_DATA} ${WRKSRC}/README ${DESTDIR}${PREFIX}/share/doc/anthy
	${INSTALL_DATA} ${WRKSRC}/README.en ${DESTDIR}${PREFIX}/share/doc/anthy

.include "../../mk/bsd.pkg.mk"
