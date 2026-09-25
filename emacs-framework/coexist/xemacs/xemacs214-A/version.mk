# $NetBSD: version.mk,v 1.2 2019/06/08 10:41:00 rillig Exp $

_EMACS_FLAVOR=		xemacs
_EMACS_REQD=		xemacs214-nox11>=21.4<21.5
_EMACS_PKGDEP.base=	xemacs-packages>=1.15:../../editors/xemacs-packages
_EMACS_PKGDEP.leim=

_EMACS_VERSION_MAJOR=	21
_EMACS_VERSION_MINOR=	4

# The binary to byte-compile with.  Without this EMACS_BIN falls back to
# bin/xemacs, which is the pkg_alternatives wrapper: with 21.4 and 21.5
# both installed it points at one of them, and every package built for
# the other is compiled by the wrong XEmacs.  Measured here -- a run
# labelled 21.5 was compiled by 21.4 from end to end.
# Track this with DISTNAME in the package's Makefile.
_EMACS_BIN_NAME=	xemacs-21.4.25
