# $NetBSD$

# 21.4 と 21.5 を同じ prefix に入れられるようにした版。XEmacs は本体を
# bin/xemacs-21.4.25、自分の lisp と etc を lib/xemacs-21.4.25/ に置くので
# 既に大半が版で分かれている。衝突するのは版なしの bin 10 本と man 7 本
# だけなので、そこに版を付け、素の名前は ALTERNATIVES が引き受ける。
PKGNAME=	${DISTNAME:S/xemacs/xemacs214/:S/-/-nox11-/}
PKGREVISION=	1
COMMENT=	XEmacs text editor version 21.4 (no x11 support)

XEVER=		${DISTNAME:S/xemacs-//}
PLIST_SUBST+=	XEVER=${XEVER}
PRINT_PLIST_AWK+=	{ gsub(/${XEVER}/, "$${XEVER}"); }


.include "../../editors/xemacs/Makefile.common"
.include "../../editors/xemacs/options.mk"

# Makefile.common が PLIST_SRC を = で置くので、その後ろで上書きする。
PLIST_SRC=	${.CURDIR}/PLIST

# configure の --program-transform-name は使わない。XEmacs の Makefile は
# 本体を bin/xemacs-${version} として入れてから bin/xemacs の symlink を
# 自分で張るので、transform を掛けると本体が二重に版を持つ。改名の方が
# 何が出来るか読んで分かる。
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
