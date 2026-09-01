/* System description file for OpenBSD.
   Copyright (C) 1996 Free Software Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */

/* OpenBSD is NetBSD with a different name and a few of its own habits,
   so take that file and change what differs.  */

#include "netbsd.h"

#undef SYSTEM_TYPE
#define SYSTEM_TYPE "openbsd"

/* OpenBSD has never shipped crypt in a separate library.  */
#undef LIBS_SYSTEM
#define LIBS_SYSTEM

/* Every OpenBSD that pkgsrc still builds for is ELF.  netbsd.h already
   picks unexelf.o under __ELF__; this is here to say so out loud.  */
tail -6 $C/mule2/files/openbsd.h | cut -c1-70

/* OpenBSD は union wait を捨てた。syswait.h は BSD が定義されていると
   WAITTYPE を union wait にするので、先にこちらで決めて止める。中身は
   syswait.h の POSIX 側と同じもの。  */
#define WAITTYPE int
#define WIFSTOPPED(w) (((w) & 0377) == 0177)
#define WIFSIGNALED(w) (((w) & 0377) != 0177 && ((w) & ~0377) == 0)
#define WIFEXITED(w) (((w) & 0377) == 0)
#define WRETCODE(w) ((w) >> 8)
#define WSTOPSIG(w) ((w) >> 8)
#define WTERMSIG(w) ((w) & 0377)
#define WCOREDUMP(w) (((w) & 0200) != 0)
