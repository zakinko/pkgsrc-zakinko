# $NetBSD$
#
# pkglint says the _EMACS_* names are reserved for pkgsrc's own use and that
# some of them are defined but never read.  Both are false here, and renaming
# is not open to us: these are the names zakinko/emacs/modules.mk expects,
# because that file is a copy of editors/emacs/modules.mk and reads them as
# they are.  Every one of them has a reader --
#
#	_EMACS_REQD	buildlink3.mk in this same directory
#	_EMACS_FLAVOR	modules.mk, around line 380
#	_EMACS_PKGDEP.*	modules.mk, around line 371
#	_EMACS_VERSION_*  Makefile.common, for EMACS_VERSION
#
# -- and pkglint follows none of those includes.
#

_EMACS_FLAVOR=	emacs
_EMACS_REQD=	emacs23>=23.2<24

_EMACS_VERSION_MAJOR=	23
_EMACS_VERSION_MINOR=	4
