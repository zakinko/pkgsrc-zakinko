B=~/w/claude/6a6d47e0; T=$B/upd/tree5; P=$B/fw/p30; export PATH=$P/bin:$P/sbin:/usr/sbin:$PATH; G=$B/gen; L=$G/logs; mkdir -p $L; cd $G && rm -rf pk && tar xf pk.tar
# work from private copies: order.txt and pk.tar get replaced from the Mac while a run is going
cp order.txt order.run; cp result.txt result.base
: > $G/result.new
while read p; do
  case "$p" in */*) ;; *) echo "bad entry: '$p'" >&2; continue;; esac
  if grep -q "^$p	OK$" $G/result.base 2>/dev/null; then printf '%s\tOK\n' $p >> $G/result.new; continue; fi
  n=$(echo $p | tr / _); rm -rf $T/$p; cp -R $G/pk/$p $T/$p; cd $T/$p
  if ! { bmake makesum > $L/$n.makesum 2>&1 && bmake makepatchsum >> $L/$n.makesum 2>&1; }; then printf '%s\tNG-FETCH\t%s\n' $p "$(grep -m1 -E 'Unable|404|Not Found|ERROR' $L/$n.makesum | cut -c1-80)" | tee -a $G/result.new; continue; fi
  if bmake show-depends-pkgpaths 2>/dev/null | grep -q 'lang/rust\|lang/ruby\|lang/python\|textproc/ripgrep\|security/password-store\|devel/git'; then printf '%s\tNG-HEAVYDEP\t%s\n' $p "$(bmake show-depends-pkgpaths | grep 'lang/rust\|lang/ruby\|lang/python\|textproc/ripgrep\|security/password-store\|devel/git' | head -1)" | tee -a $G/result.new; continue; fi
  bmake clean >/dev/null 2>&1; pkg_delete -f "$(bmake show-var VARNAME=PKGBASE)-[0-9]*" >/dev/null 2>&1
  if bmake package-install > $L/$n.build 2>&1; then r=OK; else
    if grep -q 'file-check results' $L/$n.build; then bmake print-PLIST > PLIST.new 2>/dev/null; sed -i.bak '1s|.*|@comment $NetBSD$|' PLIST.new; rm -f PLIST.new.bak; mv PLIST.new PLIST; bmake clean >/dev/null 2>&1
      if bmake package-install > $L/$n.build2 2>&1; then r=OK; else r="NG $(grep -m1 -E '^ERROR: [A-Z]|Error code|error:|!! ' $L/$n.build2 | cut -c1-90)"; fi
    else r="NG $(strings $L/$n.build | grep -m1 -E '^ERROR: [A-Z]|Error code|error:|!! |Cannot open' | cut -c1-90)"; fi
  fi
  if [ "$r" = OK ]; then
    # a package that installs a file Emacs already ships shadows it for everyone, since site-lisp comes first
    for f in $(pkg_info -L "$(bmake show-var VARNAME=PKGNAME)" 2>/dev/null | grep '\.el$' | xargs -n1 basename 2>/dev/null); do
      if [ -n "$(find $P/share/emacs/[0-9]*/lisp -name "$f.gz" 2>/dev/null | head -1)" ]; then printf '%s\t%s\n' $p $f >> $G/shadow.txt; fi
    done
  fi
  printf '%s\t%s\n' $p "$r" | tee -a $G/result.new
done < $G/order.run
mv $G/result.new $G/result.txt
echo "=== gen build done $(date '+%H:%M:%S')"; grep -c 'OK$' $G/result.txt; grep -vc 'OK$' $G/result.txt
