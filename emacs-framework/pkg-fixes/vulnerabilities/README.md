# doc/pkg-vulnerabilities: the Emacs entries

Measured against `doc/pkg-vulnerabilities` rev 1.794 (2026-09-16) with
`pkg_admin pmatch`, on NetBSD 11.0/amd64.

Two kinds of change.

**Bounded what was unbounded.**  `emacs20-[0-9]*` matches every emacs20
there will ever be, so the two entries below keep firing after the hole
is closed.  `pkg_admin pmatch "emacs20<20.7nb28" emacs20-20.7nb26`
matches and `...nb28` does not, so the bound does what it says.

    emacs20-[0-9]*  ->  emacs20<20.7nb28   CVE-2017-1000383
    emacs20-[0-9]*  ->  emacs20<20.7nb28   CVE-2022-45939

**Added what was missing.**  These are fixed in the tree but have no
entry, so `pkg_admin audit` stays quiet on versions that are not:

    CVE-2001-1301   emacs20 rcs2log writes $TMPDIR/rcs2log<pid>{l,r}
    CVE-2026-79992  tramp local command execution (emacs29, emacs30)
    CVE-2026-6861   memory corruption (emacs29, emacs30)
    CVE-2026-77219  PBM/PPM/PGM heap over-read (emacs29, emacs30)
    CVE-2024-53920  elisp-completion-at-point (emacs29; emacs30 has it)

The emacs20 rcs2log fix is the patch in the branch's emacs20 diff; the
others are already committed in the tree (wiz@ from 2026-08-25 on), the
entries were just never written.

The `emacs21*` and `emacs25*` lines are left alone here: emacs21 was
removed from pkgsrc on 2026-09-12, and emacs25 is not in the tree
either, so those entries match nothing.
