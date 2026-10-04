#!/bin/sh
# 新しい pkgsrc で、当て物を直して最初に make makepatchsum を打つと
# distinfo が壊れるか。checksum.mk に bootstrap-depends を前置すると
# 直るか。
#
# bootstrap は digest を入れない。digest は USE_TOOLS の digest:bootstrap
# として bootstrap-depends が入れるが、fetch と違い distinfo / makesum /
# makepatchsum はそれを走らせない。NetBSD は base の道具で pkgsrc を使う
# ので bootstrap はしないが、digest は base に無いので同じことになる。
#
# 前と後を同じ VM で測る。後の前には digest を消しておく。

W=/var/tmp/probe
rm -rf $W; mkdir -p $W; cd $W || exit 1

case $(uname -s) in
NetBSD)
	ftp -V -o pkgsrc.tar.gz https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz || exit 1
	;;
*)
	fetch -q -o pkgsrc.tar.gz https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz || exit 1
	;;
esac
gzip -t pkgsrc.tar.gz || { echo "truncated"; exit 1; }
tar xzf pkgsrc.tar.gz && rm pkgsrc.tar.gz

case $(uname -s) in
NetBSD)
	MAKE=make
	PKG_INFO=pkg_info; PKG_DELETE=pkg_delete
	;;
*)
	(cd pkgsrc/bootstrap && ./bootstrap --prefix $W/pkg --workdir $W/bw \
	    --make-jobs 4 > $W/bootstrap.log 2>&1) || { tail -30 $W/bootstrap.log; exit 1; }
	MAKE=$W/pkg/bin/bmake
	PKG_INFO=$W/pkg/sbin/pkg_info; PKG_DELETE=$W/pkg/sbin/pkg_delete
	;;
esac
echo "=== $(uname -sr), pkgsrc $(sed -n 's/.*\$NetBSD: checksum.mk,v \([0-9.]*\) \([0-9/]*\).*/checksum.mk \1 \2/p' pkgsrc/mk/checksum/checksum.mk)"

M=$W/pkgsrc/mk/checksum/checksum.mk
cp $M $M.orig
P=$W/pkgsrc/security/polkit
p=$P/patches/patch-src_polkitagent_polkitagenthelper-pam.c
cp $P/distinfo $W/distinfo.orig
cp $p $W/patch.orig

run() {
	cd $P
	$PKG_INFO -q -e digest && $PKG_DELETE digest
	t=$($MAKE show-var VARNAME=TOOLS_DIGEST)
	[ -x "$t" ] && echo "  digest present before: $t" || echo "  digest absent before: $t"
	cp $W/patch.orig $p
	cp $W/distinfo.orig distinfo
	awk 'NR==2{print; print "Local edit."; next}{print}' $p > $p.new && mv $p.new $p
	$MAKE makepatchsum > $W/out 2> $W/err
	echo "  rc=$?"
	grep 'digest' $W/err | sed 's/^/  stderr: /' | head -3
	[ -x "$t" ] && echo "  digest present after" || echo "  digest absent after"
	echo "  joined lines: $(grep -c '= SHA1 (' distinfo)"
	grep '^SHA1 (patch-' distinfo | sed 's/^/  /'
	# pkgsrc は当て物の $NetBSD 行を除いてから hash を取る
	if [ -x "$t" ]; then
		want=$(sed '/\$NetBSD.*/d' $p | $t sha1)
		got=$(sed -n "s/^SHA1 ($(basename $p)) = //p" distinfo)
		[ "$got" = "$want" ] && echo "  edited patch hash correct" || echo "  edited patch hash WRONG ($got != $want)"
	fi
}

echo "=== before: checksum.mk as shipped"
run
echo "=== after: distinfo makesum makepatchsum: bootstrap-depends"
awk '/^distinfo:$/ && !done {print "distinfo makesum makepatchsum: bootstrap-depends"; print ""; done=1} {print}' $M.orig > $M
(cd $W/pkgsrc && diff -u mk/checksum/checksum.mk.orig mk/checksum/checksum.mk)
run
