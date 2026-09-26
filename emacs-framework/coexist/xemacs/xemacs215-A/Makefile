# $NetBSD$

# 21.4 と同じ形。衝突するのは版なしの bin と man だけなので、そこへ版を
# 付け、素の名前は ALTERNATIVES が引き受ける。
PKGNAME=	${DISTNAME:S/xemacs/xemacs215/:S/-/-nox11-/}
PKGREVISION=	1
COMMENT=	*BETA* XEmacs text editor version 21.5 (no X11 support)

XEVER=		${DISTNAME:S/xemacs-//}
PLIST_SUBST+=	XEVER=${XEVER}
PRINT_PLIST_AWK+=	{ gsub(/${XEVER}/, "$${XEVER}"); }

.include "../../editors/xemacs-current/Makefile.common"
.include "../../editors/xemacs-current/options.mk"

# Makefile.common が PLIST_SRC を = で置くので、その後ろで上書きする。
PLIST_SRC=	${.CURDIR}/PLIST

# Makefile.common が post-install の script を持っているので、こちらで
# もう一つ書くと bmake が黙って無視する (duplicate script for target)。
# 向こうが post-install-x11 を依存に並べているのと同じ形で繋ぐ。
post-install: xemacs-versioned-names

xemacs-versioned-names:
	cd ${DESTDIR}${PREFIX}/bin &&					\
	for f in ellcc gnuattach gnuclient gnudoit ootags		\
		 xemacs-b2m xemacs-ctags xemacs-etags			\
		 xemacs-rcs-checkin; do					\
		${TEST} ! -f $$f || ${MV} $$f $$f-${XEVER};		\
	done;								\
	${RM} -f xemacs
	cd ${DESTDIR}${PREFIX}/${PKGMANDIR}/man1 &&			\
	for m in gnuattach gnuclient gnudoit gnuserv			\
		 xemacs-ctags xemacs-etags xemacs; do			\
		${TEST} ! -f $$m.1 || ${MV} $$m.1 $$m-${XEVER}.1;	\
	done

.include "../../mk/bsd.pkg.mk"
