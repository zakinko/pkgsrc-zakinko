# $NetBSD$

# The version comes from EMACS_PKGNAME_PREFIX, so this package is named
# once and installs for whichever Emacs it is built for.  Writing the
# version into the name as well gave emacs20-emacs20-compat.
#
# Not emacs-compat: wip/emacs-compat is already GNU ELPA's compat, which
# is a different library (it serves Emacs 25.1 and later, and its
# compat-29.el cannot even be read by an Emacs 20 or XEmacs reader --
# measured: "Invalid escape character syntax" and "Weird old-backquote
# syntax").  And under the xemacs prefix emacs-compat would come out as
# xemacs-emacs-compat.
DISTNAME=	elisp-compat-20260927
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel editors
MASTER_SITES=	# empty
DISTFILES=	# empty

MAINTAINER=	pkgsrc-users@NetBSD.org
COMMENT=	What an older Emacs lacks, for elisp written since
LICENSE=	gnu-gpl-v3

# One file serves every version: each definition is made only when the
# running Emacs does not have it, so on a recent Emacs the file is a
# no-op.  It is written in the syntax Emacs 20's reader accepts, which
# is what lets the same file be used from 20 to 31.
EMACS_VERSIONS_ACCEPTED=	emacs31 emacs31nox emacs30 emacs30nox \
				emacs29 emacs29nox emacs28 emacs28nox \
				emacs27 emacs27nox emacs26 emacs26nox \
				emacs25 emacs25nox emacs24 emacs24nox \
				emacs23 emacs23nox emacs22 emacs22nox \
				emacs21 emacs21nox emacs20 \
				xemacs215 xemacs215nox xemacs214 xemacs214nox

NO_CHECKSUM=	yes
NO_CONFIGURE=	yes
WRKSRC=		${WRKDIR}

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

# The old names each need a file of their own: require looks for a file,
# so a provide inside elisp-compat.el does not answer (require 'emacs-compat).
_COMPAT_ALIASES=	e20-compat emacs-compat xemacs-compat

do-extract:
	${CP} ${FILESDIR}/elisp-compat.el ${WRKSRC}/
.for _a_ in ${_COMPAT_ALIASES}
	${CP} ${FILESDIR}/${_a_}.el ${WRKSRC}/
.endfor

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q ${_ELISP_COMPAT_BATCH} \
		-f batch-byte-compile elisp-compat.el
.for _a_ in ${_COMPAT_ALIASES}
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q ${_ELISP_COMPAT_BATCH} \
		-f batch-byte-compile ${_a_}.el
.endfor

do-install:
	${INSTALL_DATA} ${WRKSRC}/elisp-compat.el ${WRKSRC}/elisp-compat.elc \
		${DESTDIR}${EMACS_LISPPREFIX}
.for _a_ in ${_COMPAT_ALIASES}
	${INSTALL_DATA} ${WRKSRC}/${_a_}.el ${WRKSRC}/${_a_}.elc \
		${DESTDIR}${EMACS_LISPPREFIX}
.endfor

.include "../../editors/emacs/modules.mk"

# XEmacs and GNU Emacs disagree on two of the batch options.  XEmacs
# takes -no-site-file with one hyphen and does not understand
# --no-site-file, and it has no -L at all: it reads the argument as a
# file to load and stops with "work is a directory".  Both are silent
# about the option itself; what you see is the next argument being
# treated as a file name.
.if ${EMACS_FLAVOR} == "xemacs"
_ELISP_COMPAT_BATCH=	-no-site-file -eval '(setq load-path (cons "." load-path))'
.else
_ELISP_COMPAT_BATCH=	--no-site-file -L .
.endif

.include "../../mk/bsd.pkg.mk"
