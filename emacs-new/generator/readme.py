import json,re,sys,os
S=os.path.dirname(os.path.abspath(__file__))
recs=json.load(open(S+'/recs.json'))
res={}
for l in open(S+'/result.final.txt'):
    p,_,r=l.rstrip('\n').partition('\t'); res[p]=r
src=open(S+'/gen.py').read()
ok=[(n,r) for n,r in sorted(recs.items()) if 'skip' not in r and res.get(f"{r['cat']}/{r['pkg']}")=='OK']
ng=[(n,r,res.get(f"{r['cat']}/{r['pkg']}",'not built')) for n,r in sorted(recs.items()) if 'skip' not in r and res.get(f"{r['cat']}/{r['pkg']}")!='OK']
sk=[(n,r['skip']) for n,r in sorted(recs.items()) if 'skip' in r]
def srcdesc(r):
    return {'github':'GitHub','elpa':'GNU ELPA','nongnu':'NonGNU ELPA','gitlab':'GitLab','codeberg':'Codeberg','srht':'sr.ht','gentoo':'Gentoo mirror','gentoodev':'dev.gentoo.org','jpl':'jpl.org'}.get(r['src'],r['src'])
out=[]
out.append("""# New Emacs packages, generated from Gentoo's app-emacs set

Gentoo's app-emacs category (444 packages on 2026-09-21) was read against
pkgsrc; the 412 that pkgsrc does not have were turned into packages by a
generator (bin/ in NetBSD-i386 has it as gen.py) that reads each ebuild for
its source, version, licence, dependencies and the Emacs versions it
supports, and writes a pkgsrc package that byte-compiles with
`${EMACS_BIN} -batch -f batch-byte-compile` and installs into
`${EMACS_LISPPREFIX}/<name>`.  Each package here was then built with
`bmake package-install` against emacs30-nox11 30.2 on NetBSD 11.0/amd64,
and its PLIST regenerated from what was installed.

`patch -p0` is not the form here: these are whole package directories.
Copy `<category>/<pkg>` into a pkgsrc tree and add the SUBDIR line.

What every package has in common:

- `EMACS_VERSIONS_ACCEPTED= emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox`
  (Gentoo's set requires Emacs 24 or later; 29 is the oldest pkgsrc has
  besides 20)
- dependencies on other Emacs packages come from the ebuild's RDEPEND and
  point at the pkgsrc package (existing ones where pkgsrc has them, these
  otherwise); the same directories go on the byte-compiler's load-path
- files named `*-test.el`, `test-*.el` and the like, and `.dir-locals.el`,
  are removed before compiling: they are test suites, and a `.dir-locals.el`
  that sets `require-final-newline` to a string aborts batch compilation
- a file upstream marks `no-byte-compile` is installed as source
- data next to the lisp (icons, banners, emoji tables, directive lists)
  is installed next to it, where `load-file-name` relative code expects it

## Built and installed (%d)

| package | version | source | notes |
|---|---|---|---|
""" % len(ok))
notes=json.load(open(S+'/notes.json')) if os.path.exists(S+'/notes.json') else {}
for n,r in ok:
    note=notes.get(n,'')
    if r.get('deps'): note=(note+'; ' if note else '')+'needs '+', '.join(r['deps'])
    out.append(f"| {r['cat']}/{r['pkg']} | {r['ver']} | {srcdesc(r)} | {note} |")
out.append(f"\n## Not built ({len(ng)})\n\nThese are left out of the branch.\n")
for n,r,why in ng: out.append(f"- {r['cat']}/{r['pkg']}: {why[:120]}")
out.append(f"\n## Skipped before building ({len(sk)})\n")
for n,why in sk: out.append(f"- {n}: {why}")
open(S+'/README.new.md','w').write('\n'.join(out)+'\n')
print(len(ok),len(ng),len(sk))
