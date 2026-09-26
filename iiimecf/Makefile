# $NetBSD$
#

DISTNAME=	IIIMECF-0.6
PKGNAME=	${EMACS_PKGNAME_PREFIX}iiimecf-0.6
PKGREVISION=	4
CATEGORIES=	inputmethod japanese
MASTER_SITES=	http://unit.aist.go.jp/itri/itri-gist/ftp.m17n.org/pub/mule/IIIM/

MAINTAINER=	uebayasi@NetBSD.org
#HOMEPAGE=
COMMENT=	Emacs Lisp library for IIIM Protocol
LICENSE=	gnu-gpl-v2

# 2026-09-23 に手元の Emacs 31.1 で測った。当て物四本で 6/6 compile し、
# iiimcf-sc の load も通る。IIIM の server そのものは pkgsrc に無いので、
# 載っても話す相手が居ない点は変わらない。
EMACS_VERSIONS_ACCEPTED=	emacs21 emacs21nox emacs20
EMACS_VERSIONS_ACCEPTED+=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox
EMACS_BUILDLINK=		# yes

do-build:
	${RUN} cd ${WRKSRC} && \
		${EMACS_BIN} -q --no-site-file -batch -l iiimcf-comp.el

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}/iiimecf
	${RUN} for f in ${WRKSRC}/lisp/*.el ${WRKSRC}/lisp/*.elc; do \
		${INSTALL_DATA} $$f ${DESTDIR}${EMACS_LISPPREFIX}/iiimecf; \
	done

.include "../../editors/emacs/modules.mk"

# 当て物で (require 'un-define nil t) にしたので、新しい Emacs では
# 無くても建つ。ここを残すのは emacs20/21 のため。mule-ucs の
# buildlink3.mk は EMACS_VERSION_MAJOR < 22 で自分を囲っているので、
# emacs22 以降ではこの行は空になる。
.include "../../editors/mule-ucs/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
