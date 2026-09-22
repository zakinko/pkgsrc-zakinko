import json,re,os,shutil
eb=json.load(open('ebuilds.json'))
lic={'GPL-3+':'gnu-gpl-v3','GPL-3':'gnu-gpl-v3','GPL-2+':'gnu-gpl-v2','GPL-2':'gnu-gpl-v2','MIT':'mit','BSD':'modified-bsd','BSD-2':'2-clause-bsd','Apache-2.0':'apache-2.0','Unlicense':'unlicense','public-domain':'public-domain','MPL-2.0':'mpl-2.0','ISC':'isc','ZLIB':'zlib','WTFPL-2':'wtfpl','LGPL-3+':'gnu-lgpl-v3','LGPL-2.1+':'gnu-lgpl-v2.1','CC0-1.0':'cc0-1.0-universal','||':'mit'}
existing={'apel':('devel','apel','apel'),'auctex':('print','auctex','auctex'),'bbdb':('misc','bbdb3','bbdb','bbdb'),'emacs-w3m':('www','emacs-w3m','w3m'),'flim':('devel','flim','flim'),'muse':('textproc','emacs-muse','muse'),'reformatter':('devel','reformatter-el','reformatter'),'semi':('devel','semi','semi'),'dash':('devel','dash-el','dash'),'rainbow-delimiters':('devel','rainbow-delimiters-el','rainbow-delimiters'),'markdown-mode':('textproc','markdown-mode',''),'flycheck':('textproc','flycheck-mode',''),'color-theme':('misc','color-theme','color-theme'),'howm':('misc','howm','howm')}
modes={'systemd-mode','yaml-mode','rust-mode','emacs-bazel-mode','git-modes','lsp-mode'}
uiish={'doom-themes','zenburn','autothemer','which-key','powerline','dashboard','treemacs','lsp-ui','lsp-treemacs','ivy','consult','corfu','evil','expand-region','hydra','undo-tree','diff-hl','hl-todo','highlight-indentation','paredit','key-chord','keymap-popup','posframe','popup','spinner','tablist','wgrep','rg','session','no-littering','develock','boxquote','browse-kill-ring','bm','diminish','initsplit','volume','xclip','calfw','pdf-tools','emacs-eat','dape','gptel','mastodon','geiser-guile','pyvenv','editorconfig-emacs','exec-path-from-shell','system-packages','pass','atomic-chrome','auto-complete','lsp-docker','esup','wfnames','ace-window','avy','password-store-otp'}
def pkgname(n): return n if re.search(r'-(mode|modes|themes)$',n) else n+'-el'
def cat(n): return 'editors' if (n in modes or n in uiish) else 'devel'
recs={}
for n,e in eb.items():
    t=e['text']; v=re.sub(r'-r\d+$','',e['version']); P=f'{n}-{v}'
    def g1(k):
        m=re.search(r'(?m)^\s*'+k+r'="([^"]*)"',t) or re.search(r'(?m)^\s*'+k+r'=(\S+)\s*$',t); return m.group(1).strip() if m else ''
    desc=g1('DESCRIPTION'); home=g1('HOMEPAGE').split()[0] if g1('HOMEPAGE') else ''; l=g1('LICENSE'); m_=re.search(r'(?m)^\s*S="?([^\n]*)$',t); s=(m_.group(1).replace('"','') if m_ else ''); myp=g1('MY_P'); mypn=g1('MY_PN'); mypv=g1('MY_PV')
    m=re.search(r'(?s)^\s*RDEPEND="(.*?)"',t,re.M); rd=m.group(1) if m else ''
    for dv in re.findall(r'\$\{([A-Z_]*DEPEND)\}',rd):
        m=re.search(r'(?s)^\s*'+dv+r'="(.*?)"',t,re.M); rd=rd.replace('${'+dv+'}',m.group(1) if m else '')
    other=sorted(set(re.findall(r'(?<![A-Za-z/])((?!app-emacs/)[a-z]+-[a-z]+/[A-Za-z0-9._+-]+)',rd)))
    m=re.search(r'(?s)^\s*SRC_URI="(.*?)"',t,re.M); src=m.group(1) if m else ''
    vs=dict(re.findall(r'(?m)^\s*(?:\[\[[^\n]*\]\] && )?([A-Z_][A-Z0-9_]*)="?([^"\s]*)"?[^\n]*$',t))
    def sub(x):
        for _ in range(5):
            for k,val in vs.items():
                if k in ('PV','P','PN','MY_PV','MY_PN','MY_P','S','SRC_URI','HOMEPAGE','DESCRIPTION','LICENSE'): continue
                x=x.replace('${'+k+'}',val)
        x=x.replace('${MY_PV}',mypv.replace('${PV}',v) if mypv else v); x=x.replace('${MY_PN}',mypn or n)
        x=x.replace('${MY_P}',(myp.replace('${PN}',n).replace('${PV}',v).replace('${MY_PN}',mypn or n).replace('${MY_PV}',mypv.replace('${PV}',v) if mypv else v)) if myp else P)
        return x.replace('${PV}',v).replace('${P}',P).replace('${PN}',n)
    src=sub(src); s=sub(s.replace('"',''))
    rd=sub(rd)
    deps=[re.sub(r'-\d.*$','',d) for d in re.findall(r'app-emacs/([A-Za-z0-9._+-]+)',rd) if not d.startswith('ert-runner')]
    deps=sorted(set(deps))
    pv=re.sub(r'_p(\d)',r'.\1',v).replace('_pre','pre').replace('_rc','rc').replace('_beta','beta').replace('_alpha','alpha')
    subdir='lisp' if re.search(r'mv \./?lisp/\*\.el|S="?\$\{WORKDIR\}"?/[^\n]*/lisp"?\s*$',t) else ''
    m=re.search(r'BYTECOMPFLAGS="[^"]*-L (?!\.)([^\s"]+)',t) or re.search(r'elisp-compile \./?([a-z/]+)/\*\.el',t)
    if m and not subdir: subdir=m.group(1).strip('/')
    rec={'pkg':pkgname(n),'subdir':subdir,'cat':cat(n),'ver':pv,'gver':v,'other':other,'desc':desc,'home':home,'lic':lic.get(l.split()[0] if l else '','') or ('# XXX '+l),'deps':deps}
    m=re.search(r'https://github\.com/([^/]+)/([^/]+)/archive/([^\s]+)',src)
    if m:
        owner,repo,rest=m.group(1),m.group(2),m.group(3); tag=re.sub(r'\.tar\.gz$','',rest.split()[0]).replace('refs/tags/','')
        rec.update(src='github',owner=owner,repo=repo,tag=tag,wrksrc=s.replace('${WORKDIR}/','').replace('${WORKDIR}',''))
    elif re.search(r'https://dev\.gentoo\.org/\S+',src):
        u=re.search(r'(https://dev\.gentoo\.org/\S+)',src).group(1); rec.update(src='gentoodev',site=u.rsplit('/',1)[0]+'/',file=u.rsplit('/',1)[1])
    elif 'elpa' in src or 'savannah' in src: rec.update(src='elpa',elpaname=f'{n}-{v}')
    elif re.search(r'https://gitlab\.com/([^/]+)/([^/]+)/-/archive/([^/\s]+)/([^\s]+)',src):
        m=re.search(r'https://gitlab\.com/([^/]+)/([^/]+)/-/archive/([^/\s]+)/([^\s]+)',src)
        rec.update(src='gitlab',owner=m.group(1),repo=m.group(2),tag=m.group(3),suffix=re.sub(r'^.*?(\.tar\.[a-z0-9]+)$',r'\1',m.group(4)))
    elif re.search(r'https://codeberg\.org/([^/]+)/([^/]+)/archive/([^\s]+)\.tar\.gz',src):
        m=re.search(r'https://codeberg\.org/([^/]+)/([^/]+)/archive/([^\s]+)\.tar\.gz',src)
        rec.update(src='codeberg',owner=m.group(1),repo=m.group(2),tag=m.group(3))
    elif re.search(r'https://git\.sr\.ht/~([^/]+)/([^/]+)/archive/([^\s]+)\.tar\.gz',src):
        m=re.search(r'https://git\.sr\.ht/~([^/]+)/([^/]+)/archive/([^\s]+)\.tar\.gz',src)
        rec.update(src='srht',owner=m.group(1),repo=m.group(2),tag=m.group(3))
    elif re.search(r'mirror://gentoo/(\S+)',src):
        f=re.search(r'mirror://gentoo/(\S+)',src).group(1)
        import hashlib; h=hashlib.blake2b(f.encode()).hexdigest()[:2]
        rec.update(src='gentoo',file=f,hash2=h)
    else: rec['skip']='src: '+src[:90]
    recs[n]=rec
# sources Gentoo takes from its own mirrors, pointed at the upstream copy
OVR={
 'autothemer': dict(src='github',owner='jasonm23',repo='autothemer',tag='0.2.18',wrksrc=''),
 'oauth2': dict(src='elpa',elpaname='oauth2-0.19',ver='0.19'),
 'develock': dict(src='jpl'),
 # calfw-howm.el needs howm at compile time, and misc/howm drags ruby in
 # through migemo; ship that one file as source only
 'calfw': dict(deps=[],compile='calfw.el calfw-cal.el calfw-compat.el calfw-ical.el calfw-org.el',note='# calfw-howm.el needs misc/howm, which pulls in ruby through migemo;\n# it is installed as source only, for those who have howm'),
 'emacs-bazel-mode': dict(owner='bazel-contrib',repo='bazel.el'),
 'htmlize': dict(owner='emacsorphanage',repo='htmlize'),
 'ivy': dict(compile='colir.el ivy.el ivy-overlay.el ivy-faces.el',install='colir.el ivy.el ivy-overlay.el ivy-faces.el',note='# Ivy proper, as Gentoo splits it: swiper, counsel and the ivy-* extensions\n# in the same tarball are not built'),
 'geiser': dict(src='nongnu',elpaname='geiser-0.33.2'),
 'noflet': dict(preload='dash'),
 'volume': dict(src='github',owner='dbrock',repo='volume.el',tag='050d3e6d2543a6771a13f95612055864679b6301',wrksrc=''),
 # run 4: Gentoo's SRC_URI uses shell substitutions the parser does not
 # follow, or a Gentoo mirror of something GNU/NonGNU ELPA carries
 'adaptive-wrap': dict(src='elpa',elpaname='adaptive-wrap-0.9',ver='0.9'),
 'poke-mode': dict(src='elpa',elpaname='poke-mode-3.1',ver='3.1'),
 'org-mode': dict(src='elpa',elpaname='org-9.8.10'),
 'go-mode': dict(src='nongnu',elpaname='go-mode-1.6.0'),
 'cdlatex': dict(src='nongnu',elpaname='cdlatex-4.18.5'),
 'zenburn-theme': dict(src='nongnu',elpaname='zenburn-theme-2.11.0'),
 'elpher': dict(src='nongnu',elpaname='elpher-3.7.0'),
 'gnuplot-mode': dict(src='github',owner='emacs-gnuplot',repo='gnuplot',tag='0.12',wrksrc=''),
 'vterm': dict(skip='a C module built with cmake against libvterm, not an elisp-only package'),
 'keymap-popup': dict(skip='upstream account gone from codeberg (user redirect does not exist)'),
 # run 4 build failures: the lisp lives in a subdirectory, or an extra
 # directory has to be compiled and installed alongside
 # lsp-mode calls make-mutex, so it needs an Emacs with threads; pkgsrc
 # builds every emacs*-nox11 with --without-all, and the X builds were not
 # tried here.  The whole family stays out until one can be built and run.
 'lsp-mode': dict(skip='needs threads (make-mutex); emacs30-nox11 is --without-all'),
 'lsp-ui': dict(skip='needs lsp-mode'), 'lsp-treemacs': dict(skip='needs lsp-mode'), 'lsp-docker': dict(skip='needs lsp-mode'),
 'lsp-java': dict(skip='needs lsp-mode'), 'dap-mode': dict(skip='needs lsp-mode'), 'emacs-ccls': dict(skip='needs lsp-mode'),
 'slime': dict(subdir='',subdirs=['contrib']),
 'with-editor': dict(subdir='lisp'), 'mastodon': dict(subdir='lisp'),
 'erlang-mode': dict(subdir='lib/tools/emacs'), 'edit-server': dict(subdir='servers'),
 'emacs-ansilove': dict(subdir='src'), 'ocaml-mode': dict(subdir='emacs'),
 'treemacs-all-the-icons': dict(subdir='src/extra',compile='treemacs-all-the-icons.el',install='treemacs-all-the-icons.el'),
 'lean-mode': dict(repo='lean3-mode'),
 'ebuild-run-mode': dict(skip='the mode is tangled out of an org file with umake; nothing to byte-compile as shipped'),
 'nerd-icons': dict(subdirs=['data']), 'all-the-icons': dict(subdirs=['data']),
 'emojify': dict(datadirs=['data']), 'package-lint': dict(datadirs=['data']),
 # data the code finds next to itself (Gentoo moves these to SITEETC and patches
 # the paths; here they stay where load-file-name expects them)
 'dashboard': dict(owner='emacs-dashboard',repo='dashboard',wrksrc='',datadirs=['banners']), 'geiser-guile': dict(src='nongnu',elpaname='geiser-guile-0.28.5',datadirs=['src']),
 'systemd-mode': dict(datafiles=['*-directives.txt']),
 'treemacs': dict(datadirs=[('../../icons',''),('../scripts','src')]),
 # optional pieces that need what is not here: elfeed for aio-contrib.el,
 # ImageMagick's mogrify for dired-images.el
 'emacs-aio': dict(compile='aio.el'),
 'wikipedia-mode': dict(deps=['outline-magic']),
 'julia-repl': dict(nobuild=True),
 'ledger-mode': dict(tag='b0e71b7e9ee612ccb0b0e5f8bfefcfddb69ae861',ver='4.0.0.20260727',wrksrc='',notests=True),
 'rpm-spec-mode': dict(owner='Thaodan',repo='rpm-spec-mode',tag='283d2aac4ede343586a1fb9e9d2a5917f34809a1',ver='0.16.20241209',wrksrc=''),
 'magit': dict(subdir='lisp'), 'org-contrib': dict(subdir='lisp'), 'distel': dict(subdir='elisp'), 'boogie-friends': dict(subdir='emacs'),
 'lyskom-elisp-client': dict(skip='built by its own Makefile into one lyskom.elc; src/ also carries copies of custom.el and cus-edit.el that would shadow the bundled ones'), 'blogmax': dict(top='blogmax'),
 # cider-test.el is the test-runner integration, not a test file
 'cider': dict(subdir='lisp',notests=True), # icicles-cmd1.el calls hexrgb at top level, so hexrgb has to be there at compile time
 'icicles': dict(deps=['hexrgb']),
 'queue': dict(src='elpa',elpaname='queue-0.2'),
 'external-completion': dict(skip='bundled with Emacs since 29, the oldest version accepted here, at the same 0.1'),
 # the tarball is use-package's; only bind-chord.el is this package (use-package
 # itself is in Emacs 29)
 'bind-chord': dict(compile='bind-chord.el',install='bind-chord.el'),
 'emacs-el-fetch': dict(subdir='src/el-fetch'), 'forge': dict(subdir='lisp'),
 'emms': dict(skip='needs threads (make-mutex, reached from emms-setup); emacs30-nox11 is --without-all'),
 # planner-gnats.el needs a gnats.el that is nowhere; jsee.el needs JDE
 # planner-gnats.el needs a gnats.el that is nowhere; planner-ledger.el the
 # pre-ledger-mode ledger.el
 'remember': dict(tolerant=True,note='# remember-bibl.el needs bibl-mode; each file is compiled on its own and\n# the ones whose requirement is absent stay source'),
 'planner': dict(rmfiles='planner-gnats.el planner-ledger.el',tolerant=True,note='# The planner-*.el integrations require what they integrate with (psvn,\n# vm, wl, xtla...); each file is compiled on its own and the ones whose\n# requirement is absent stay source'),
 # emhacks (2007) carries its own recentf, ruler-mode and tree-widget, older than
 # the ones in Emacs; site-lisp comes first on load-path, so they would shadow
 # the bundled ones for every package
 'emhacks': dict(rmfiles='jsee.el recentf.el ruler-mode.el tree-widget.el tree-widget-examples.el'),
 'emacs-common': dict(skip='Gentoo-specific helper (circular with emacs-daemon)'), 'emacs-daemon': dict(skip='Gentoo-specific helper'),
 'eselect-mode': dict(skip="mode for Gentoo's eselect, shipped inside eselect"),
 'cask': dict(skip='a package.el-driven CLI tool; cask-cli needs the ELPA packages at compile time'),
 'bison-mode': dict(skip='dev.gentoo.org/~nicolasbock/bison-mode-0.3.tar.bz2 is gone (404)'),
 'pymacs': dict(skip='needs python to build and run (setup.py); outside an elisp-only set'),
 'dired-hacks': dict(compile='dired-avfs.el dired-collapse.el dired-filter.el dired-hacks-utils.el dired-list.el dired-narrow.el dired-open.el dired-rainbow.el dired-ranger.el dired-subtree.el dired-tagsistant.el'),
}
assert len(re.findall(r"'([a-z0-9.+-]+)': dict\(",open(__file__).read().split('OVR={')[1].split('\n}')[0]))==len(OVR), 'duplicate OVR key'
for k,v in OVR.items():
    if 'skip' not in v: recs[k].pop('skip',None)
    recs[k].update(v)
json.dump(recs,open('recs.json','w'),indent=1)
def depinfo(d):
    # (category, directory, lisp subdir, PKGBASE when it differs from the directory)
    if d in existing: return existing[d][:3]
    if d in recs and 'skip' not in recs[d]: return recs[d]['cat'],recs[d]['pkg'],d
    return None
def deppkg(d): return existing[d][3] if d in existing and len(existing[d])>3 else depinfo(d)[1]
def transitive(n,acc):
    for d in recs.get(n,{}).get('deps',[]):
        if d in acc: continue
        acc.append(d); transitive(d,acc)
    return acc
shutil.rmtree('pk',ignore_errors=True)
# Patches the other trees carry for these packages, read one by one; only
# the ones that fix code are taken.  (file, description); paths are
# reduced to the basename, since each package's WRKSRC is the directory the
# lisp sits in.
PG=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','pg')
PATCHES={
 'dropdown-list':[(PG+'/gentoo-gen/dropdown-list--dropdown-list-20090814-selection-face.patch','The selection face inherits from dropdown-list-face, the face the file\ndefines; dropdown-list is the group, not a face.  From Gentoo.')],
 'erobot':[(PG+'/gentoo-gen/erobot--erobot-2.1.0-fix-interactive.patch','The interactive spec began with "i\\n\\n", which hands two ignored\narguments to a function that takes two; the candidates were never read.\nFrom Gentoo.')],
 'icicles':[(PG+'/gentoo-gen/icicles--icicles-2018.10.15.23738-emacs-28.patch','make-obsolete requires its WHEN argument since Emacs 29; icicles-fn.el\nfails to load without it.  From Gentoo.')],
 'regress':[(PG+'/gentoo-gen/regress--1.5.1-regress.el-gentoo.patch','The loop macro comes from cl, which the file never loads; without it\nbyte-compilation stops at "for" being an unbound variable.  From Gentoo.')],
 'remember':[(PG+'/gentoo-gen/remember--remember-2.0-emacs-28.patch','define-obsolete-function-alias requires its WHEN argument since Emacs 29.\nFrom Gentoo.')],
 'rnc-mode':[(PG+'/gentoo-gen/rnc-mode--rnc-mode-1.0.6-flymake.patch','Emacs 26 moved the legacy flymake backend to flymake-proc-*; the old\nnames are gone, so the flymake integration errored out.  From Gentoo.')],
 # Gentoo's order; the later two carry the first one's context
 'teco':[(PG+'/gentoo-gen/teco--teco-7-minibuffer-prompt.patch','The command reader tracked ESC positions by hand to show them as $;\na display table on the minibuffer does the same and survives the\nminibuffer changes since Emacs 24.  From Gentoo.'),(PG+'/gentoo-gen/teco--teco-7-emacs-24.patch','interactive-p and last-command-char were removed in Emacs 24.  From Gentoo.'),(PG+'/gentoo-gen/teco--teco-7-backquotes.patch','Old-style backquote, which Emacs stopped reading in 24.  From Gentoo.')],
 'uboat':[(PG+'/gentoo-gen/uboat--uboat-1.2-iap.patch','interactive-p was removed in Emacs 24.  From Gentoo.')],
 'xrdb-mode':[(PG+'/gentoo-gen/xrdb-mode--xrdb-mode-3.0-backquotes.patch','Old-style backquote, which Emacs stopped reading in 24.  From Gentoo.')],
 'wikipedia-mode':[(PG+'/gentoo-gen/wikipedia-mode--wikipedia-mode-0.5-require-outline-magic.patch','The mode calls outline-cycle from outline-magic without requiring it.\nFrom Gentoo.')],
 'deferred':[(PG+'/debian-gen/deferred/emacs-deferred_0.5.1-6/0004-fix-wrong-number-of-arguments.diff','start-process-shell-command takes one command string, not a command\nand an argument list; deferred:process-shell passed the list through and\nfailed with wrong-number-of-arguments.  From Debian.')],
 'bongo':[(PG+'/debian-gen/bongo/bongo_1.1-6/Adaptation-for-mpv-s-argument-parser-changes.patch','mpv takes --input-ipc-server=FILE as one argument now.  From Debian.')],
 'atomic-chrome':[(PG+'/debian-gen/atomic-chrome/atomic-chrome-el_2.0.0-6/0001-Fixes-56-change-key-binding-for-saving-modifications.patch','C-x C-s in the edit buffer was shadowed; the save binding is C-c C-s\nnow.  Upstream commit ae2a6158 (issue 56), via Debian.')],
}
def convert_patch(src,desc):
    t=open(src,errors='replace').read().splitlines()
    out=[]; keep=False; files=[]
    i=0
    while i<len(t):
        l=t[i]
        if l.startswith('--- ') and i+1<len(t) and t[i+1].startswith('+++ '):
            path=t[i+1][4:].split('\t')[0].strip(); base=os.path.basename(path); keep=base.endswith('.el')
            if keep: files.append(base); out+=[f'--- {base}.orig',f'+++ {base}']
            i+=2; continue
        if keep and (l.startswith(('@@',' ','+','-')) or l==''): out.append(l)
        elif l.startswith(('@@',' ','+','-')) or l=='': pass
        else: keep=False if not l.startswith(('@@',' ','+','-')) and l.startswith(('diff ','index ','From ','Subject','---','Description','Bug','Origin','Forwarded','Author','Date','Applied')) else keep
        i+=1
    while out and out[-1]=='': out.pop()
    return files,'$NetBSD$\n\n'+desc+'\n\n'+'\n'.join(out)+'\n'
for n,r in recs.items():
    if 'skip' in r: continue
    d=f"pk/{r['cat']}/{r['pkg']}"; os.makedirs(d,exist_ok=True); L=[]
    if r['src']=='github':
        tag=r['tag']; tagexpr='${PKGVERSION_NOREV}' if tag==r['ver'] else ('v${PKGVERSION_NOREV}' if tag=='v'+r['ver'] else tag)
        if r['ver']!=r['gver'] and tag==r['gver']: tagexpr=tag
        L+=[f"DISTNAME=\t{n}-{r['ver']}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}",f"MASTER_SITES=\t${{MASTER_SITE_GITHUB:={r['owner']}/}}",f"GITHUB_PROJECT=\t{r['repo']}",f"GITHUB_TAG=\t{tagexpr}"]
        # GitHub names the archive's top directory <repo>-<tag>, with a leading v dropped and / turned into -
        top=f"{r['repo']}-{r['tag'].lstrip('v').replace('/','-')}"
        if r.get('subdir'): L.append(f"WRKSRC=\t\t${{WRKDIR}}/{top}/{r['subdir']}")
        elif top!=f"{n}-{r['ver']}": L.append(f"WRKSRC=\t\t${{WRKDIR}}/{top}")
    elif r['src']=='nongnu':
        L+=[f"DISTNAME=\t{r['elpaname']}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}","MASTER_SITES=\thttps://elpa.nongnu.org/nongnu/","EXTRACT_SUFX=\t.tar"]
    elif r['src']=='gitlab':
        t=r['tag']; tagexpr='${PKGVERSION_NOREV}' if t==r['ver'] else ('v${PKGVERSION_NOREV}' if t=='v'+r['ver'] else t)
        L+=[f"DISTNAME=\t{r['repo']}-{t}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}",f"MASTER_SITES=\thttps://gitlab.com/{r['owner']}/{r['repo']}/-/archive/{tagexpr}/",f"EXTRACT_SUFX=\t{r['suffix']}"]
    elif r['src']=='codeberg':
        t=r['tag']; tagexpr='${PKGVERSION_NOREV}' if t==r['ver'] else ('v${PKGVERSION_NOREV}' if t=='v'+r['ver'] else t)
        L+=[f"DISTNAME=\t{r['repo']}-{t}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}",f"MASTER_SITES=\thttps://codeberg.org/{r['owner']}/{r['repo']}/archive/",f"DISTFILES=\t{tagexpr}${{EXTRACT_SUFX}}",f"DIST_SUBDIR=\t${{DISTNAME}}",f"WRKSRC=\t\t${{WRKDIR}}/{r['repo']}"]
    elif r['src']=='srht':
        t=r['tag']; tagexpr='${PKGVERSION_NOREV}' if t==r['ver'] else ('v${PKGVERSION_NOREV}' if t=='v'+r['ver'] else t)
        L+=[f"DISTNAME=\t{r['repo']}-{t}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}",f"MASTER_SITES=\thttps://git.sr.ht/~{r['owner']}/{r['repo']}/archive/",f"DISTFILES=\t{tagexpr}${{EXTRACT_SUFX}}",f"DIST_SUBDIR=\t${{DISTNAME}}"]
    elif r['src']=='gentoo':
        f=r['file']; base=re.sub(r'\.(tar\.(gz|bz2|xz)|el\.(gz|bz2)|tgz)$','',f); sfx=f[len(base):]
        L+=[f"DISTNAME=\t{base}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}",f"MASTER_SITES=\thttps://distfiles.gentoo.org/distfiles/{r['hash2']}/",f"EXTRACT_SUFX=\t{sfx}","# an old library that Gentoo keeps on its own mirror; upstream is gone"]
        if sfx.startswith('.el'):
            tool={'.el.xz':'xz','.el.bz2':'bzip2','.el.gz':'gzip'}[sfx]
            L+=["WRKSRC=\t\t${WRKDIR}",f"USE_TOOLS+=\t{tool}"]; r['extract']=["# a single compressed file; pkgsrc's extract would leave it as "+base+".el","do-extract:",f"\t{tool} -dc ${{DISTDIR}}/${{DISTFILES}} > ${{WRKSRC}}/{n}.el",""]
    elif r['src']=='gentoodev':
        f=r['file']; base=re.sub(r'\.(tar\.(gz|bz2|xz)|el\.(gz|bz2|xz)|tgz)$','',f); sfx=f[len(base):]
        L+=[f"DISTNAME=\t{base}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}",f"MASTER_SITES=\t{r['site']}",f"EXTRACT_SUFX=\t{sfx}","# upstream is gone; Gentoo keeps the file on its developers' mirror"]
        if sfx.startswith('.el'):
            tool={'.el.xz':'xz','.el.bz2':'bzip2','.el.gz':'gzip'}[sfx]
            L+=["WRKSRC=\t\t${WRKDIR}",f"USE_TOOLS+=\t{tool}"]; r['extract']=["# a single compressed file, which pkgsrc's extract does not unpack","do-extract:",f"\t{tool} -dc ${{DISTDIR}}/${{DISTFILES}} > ${{WRKSRC}}/{n}.el",""]
    elif r['src']=='jpl':
        L+=[f"DISTNAME=\t{n}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}","MASTER_SITES=\thttps://www.jpl.org/ftp/pub/elisp/",f"DIST_SUBDIR=\t{n}-{r['ver']}","EXTRACT_SUFX=\t.el.gz","WRKSRC=\t\t${WRKDIR}"]
    else:
        L+=[f"DISTNAME=\t{r['elpaname']}",f"PKGNAME=\t${{EMACS_PKGNAME_PREFIX}}{r['pkg']}-{r['ver']}",f"CATEGORIES=\t{r['cat']}","MASTER_SITES=\thttps://elpa.gnu.org/packages/","EXTRACT_SUFX=\t.tar"]
    if not any(x.startswith('WRKSRC=') for x in L):
        top=r.get('top'); sub=r.get('subdir')
        if r['src']=='codeberg': pass
        elif top or sub: L.append("WRKSRC=\t\t${WRKDIR}/"+'/'.join(x for x in [top or '${DISTNAME}',sub] if x))
    elif r.get('subdir') and r['src'] in ('codeberg',):
        L=[x+'/'+r['subdir'] if x.startswith('WRKSRC=') else x for x in L]
    L+=["",f"MAINTAINER=\tpkgsrc-users@NetBSD.org",f"HOMEPAGE=\t{r['home']}",f"COMMENT=\t{r['desc'][:70].rstrip('.')}",f"LICENSE=\t{r['lic']}","","EMACS_VERSIONS_ACCEPTED=\temacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox"]
    lp=[]
    OTH={'sys-apps/ripgrep':('textproc/ripgrep','ripgrep'),'net-misc/curl':('www/curl','curl'),'app-admin/pass':('security/password-store','password-store'),'dev-scheme/guile':('lang/guile30','guile30')}
    for o in r.get('other',[]):
        if o in OTH: L.append(f"DEPENDS+=\t{OTH[o][1]}-[0-9]*:../../{OTH[o][0]}")
        else: L.append(f"# XXX Gentoo also depends on {o}")
    for dep in r['deps']:
        di=depinfo(dep)
        if not di: L.append(f"# XXX dependency {dep} is not in pkgsrc"); continue
        c,p,sub=di; L.append(f"DEPENDS+=\t${{EMACS_PKGNAME_PREFIX}}{deppkg(dep)}-[0-9]*:../../{c}/{p}")
    for dep in transitive(n,[]):
        di=depinfo(dep)
        if di and di[2]: lp.append(f"-L ${{EMACS_LISPPREFIX}}/{di[2]}")
    subs=r.get('subdirs',[]); dds=r.get('datadirs',[])
    L+=["",f"INSTALLATION_DIRS=\t${{EMACS_LISPPREFIX}}/{n}"+''.join(f" ${{EMACS_LISPPREFIX}}/{n}/{sd}" for sd in subs),*(["USE_TOOLS+=\tpax"] if dds else []),"",*r.get('extract',[]),"post-extract:","\tcd ${WRKSRC} && ${RM} -f "+("" if r.get('notests') else "*-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el ")+".dir-locals.el"+(" "+r['rmfiles'] if r.get('rmfiles') else ''),"",*([r['note']] if r.get('note') else []),*(["# upstream marks the file no-byte-compile","NO_BUILD=\tyes"] if r.get('nobuild') else ["do-build:",f"\tcd ${{WRKSRC}} && for f in *.el; do ${{EMACS_BIN}} --no-init-file --no-site-file -batch \\",("\t\t-L . "+' '.join(lp)+" -f batch-byte-compile $$f || ${TRUE}; done").replace('  ',' ')] if r.get('tolerant') else ["do-build:",f"\tcd ${{WRKSRC}} && ${{EMACS_BIN}} --no-init-file --no-site-file -batch \\",("\t\t-L . "+ ' '.join(f"-L {sd}" for sd in subs)+' '+' '.join(lp)+(" -l "+r['preload'] if r.get('preload') else '')+" -f batch-byte-compile "+r.get('compile','*.el')+''.join(f" {sd}/*.el" for sd in subs)).replace('  ',' ')]),"","# files marked no-byte-compile leave no .elc behind","do-install:",f"\tcd ${{WRKSRC}} && ${{INSTALL_DATA}} "+(r['install'] if r.get('install') else '*.el')+f" ${{DESTDIR}}${{EMACS_LISPPREFIX}}/{n}",f"\tcd ${{WRKSRC}} && for f in "+(' '.join(f[:-3]+'.elc' for f in r['install'].split()) if r.get('install') else '*.elc')+"; do \\",f"\t\ttest ! -f \"$$f\" || ${{INSTALL_DATA}} \"$$f\" ${{DESTDIR}}${{EMACS_LISPPREFIX}}/{n}; done"]
    for sd in subs: L+=[f"\tcd ${{WRKSRC}} && ${{INSTALL_DATA}} {sd}/*.el ${{DESTDIR}}${{EMACS_LISPPREFIX}}/{n}/{sd}",f"\tcd ${{WRKSRC}} && for f in {sd}/*.elc; do \\",f"\t\ttest ! -f \"$$f\" || ${{INSTALL_DATA}} \"$$f\" ${{DESTDIR}}${{EMACS_LISPPREFIX}}/{n}/{sd}; done"]
    for sd in dds:
        src,dest=(sd,'') if isinstance(sd,str) else sd; par,base=os.path.split(src); par=par or '.'; dd=f"${{DESTDIR}}${{EMACS_LISPPREFIX}}/{n}"+(f"/{dest}" if dest else '')
        L+=[(f"\t${{MKDIR}} {dd}\n" if dest else '')+f"\tcd ${{WRKSRC}}/{par} && ${{PAX}} -rw {base} {dd}"]
    for gl in r.get('datafiles',[]): L+=[f"\tcd ${{WRKSRC}} && ${{INSTALL_DATA}} {gl} ${{DESTDIR}}${{EMACS_LISPPREFIX}}/{n}"]
    L+=["",'.include "../../editors/emacs/modules.mk"','.include "../../mk/bsd.pkg.mk"']
    open(d+'/Makefile','w').write('# $NetBSD$\n\n'+'\n'.join(L)+'\n'); open(d+'/DESCR','w').write(r['desc'].rstrip('.')+'.\n'); open(d+'/PLIST','w').write('@comment $NetBSD$\n')
    for src,desc in PATCHES.get(n,[]):
        files,txt=convert_patch(src,desc); os.makedirs(d+'/patches',exist_ok=True)
        name='patch-'+files[0].replace('/','_') if files else None
        if not files: print('no .el hunks in',src); continue
        pth=d+'/patches/'+name
        if os.path.exists(pth): pth=pth+'-'+str(len(os.listdir(d+'/patches')))  # second patch to the same file
        open(pth,'w').write(txt)
# password-store.el ships inside the pass tarball (contrib/emacs); pkgsrc's
# security/password-store installs it only under share/examples
d='pk/editors/password-store-el'; os.makedirs(d,exist_ok=True)
open(d+'/Makefile','w').write('''# $NetBSD$

DISTNAME=	password-store-1.7.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}password-store-el-1.7.4
CATEGORIES=	editors security
MASTER_SITES=	http://git.zx2c4.com/password-store/snapshot/
EXTRACT_SUFX=	.tar.xz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.passwordstore.org/
COMMENT=	Emacs interface to pass, the standard UNIX password manager
LICENSE=	gnu-gpl-v2

# the same distfile as security/password-store; this is its contrib/emacs
DEPENDS+=	password-store-[0-9]*:../../security/password-store
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}with-editor-el-[0-9]*:../../devel/with-editor-el

WRKSRC=		${WRKDIR}/${DISTNAME}/contrib/emacs
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/password-store

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \\
		-L . -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/with-editor \\
		-f batch-byte-compile password-store.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} password-store.el password-store.elc \\
		${DESTDIR}${EMACS_LISPPREFIX}/password-store

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
''')
open(d+'/DESCR','w').write('password-store.el is the Emacs interface to pass, the standard UNIX\npassword manager.\n')
open(d+'/PLIST','w').write('@comment $NetBSD$\n')
recs['password-store']={'pkg':'password-store-el','cat':'editors','ver':'1.7.4','deps':['s','with-editor'],'hand':True}
order=[]; seen=set()
def visit(n):
    if n in seen or n not in recs or 'skip' in recs[n]: return
    seen.add(n); [visit(d) for d in recs[n]['deps']]; order.append(n)
for n in recs: visit(n)
open('order.txt','w').write('\n'.join(f"{recs[n]['cat']}/{recs[n]['pkg']}" for n in order)+'\n')
sk=[n for n in recs if 'skip' in recs[n]]
print(len(order),'packages; skipped:',sk); print('unresolved deps:',sorted(set(d for n in recs for d in recs[n]['deps'] if not depinfo(d))))
