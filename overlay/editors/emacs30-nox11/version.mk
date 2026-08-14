# $NetBSD: version.mk,v 1.1 2025/12/16 20:33:22 gdt Exp $
#
# 上流 pkgsrc の editors/emacs30-nox11/version.mk の写しに、_EMACS_REQD の
# 綴りを直しただけのもの。
#
# 上流は存在しないパッケージを要求している。
#
#	_EMACS_REQD=	emacs30-no-x11>=30.1<31
#
# だが Makefile が作るのは emacs30-nox11-30.2 で、他の世代も全部 nox11。
# emacs30-no-x11 という文字列はツリー全体でこの一箇所にしか無い。
#
#	emacs26-nox11	emacs26-nox11>=26.1<27
#	emacs27-nox11	emacs27-nox11>=27.1<28
#	emacs28-nox11	emacs28-nox11>=28.1<29
#	emacs29-nox11	emacs29-nox11>=29.1<30
#	emacs30-nox11	emacs30-no-x11>=30.1<31		← ここ
#
# emacs30-nox11 自体は建つ。壊れるのは依存する側で、modules.mk が
# _EMACS_REQD をそのまま DEPENDS にするため、EMACS_TYPE=emacs30nox では
# Emacs Lisp パッケージが一つも建たない。anthy-elisp がそれで止まった。
#
# PKGREVISION は上げない。この変更が動かすのは依存側の要求する名前で
# あって、emacs30-nox11 が入れるものではないため。
#
# rev 1.1 のまま、つまり emacs30-nox11 が追加された 2025-12-16 からこう。

_EMACS_FLAVOR=	emacs
_EMACS_REQD=	emacs30-nox11>=30.1<31

_EMACS_VERSION_MAJOR=	30
_EMACS_VERSION_MINOR=	2
