#!/bin/sh
# 新しい pkgsrc で、最初に make makepatchsum を打つと distinfo が壊れるか。
# checksum.mk に bootstrap-depends を前置すると直るか。
#
# bootstrap は digest を入れない。digest は USE_TOOLS の digest:bootstrap
# として bootstrap-depends が入れるが、fetch と違い distinfo / makesum /
# makepatchsum はそれを走らせない。NetBSD は base の道具で pkgsrc を使う
# ので bootstrap はしないが、digest は base に無いので同じことになる。
#
# 当て物を持つ package として devel/libffi を使う。security/polkit は
# 128 で当て物が無くなった。当て物を直さない場合と一本直す場合を、
# 直す前と後で同じ VM で測る。各回の前に digest を消しておく。

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

M=$W/pkgsrc/mk/checksum/checksum.mk
cp $M $M.orig
P=$W/pkgsrc/devel/libffi
cd $P || exit 1
p=$(ls patches/patch-* | head -1)
cp distinfo $W/distinfo.orig
cp $p $W/patch.orig
echo "=== $(uname -sr), $(sed -n 's/.*\$NetBSD: \(checksum.mk,v [0-9.]* [0-9/]*\).*/\1/p' $M.orig), edited: $p"

for fix in no yes; do
	cp $M.orig $M
	[ $fix = yes ] && awk '/^distinfo:$/ && !d {print "distinfo makesum makepatchsum: bootstrap-depends"; print ""; d=1} {print}' $M.orig > $M
	[ $fix = yes ] && (cd $W/pkgsrc && diff -u mk/checksum/checksum.mk.orig mk/checksum/checksum.mk)
	for edit in no yes; do
		echo "=== fix=$fix edit=$edit"
		$PKG_INFO -q -e digest && $PKG_DELETE digest
		t=$($MAKE show-var VARNAME=TOOLS_DIGEST)
		[ -x "$t" ] && echo "  digest present before" || echo "  digest absent before"
		cp $W/distinfo.orig distinfo
		cp $W/patch.orig $p
		[ $edit = yes ] && { awk 'NR==2{print; print "Local edit."; next}{print}' $p > $p.new && mv $p.new $p; }
		$MAKE makepatchsum > $W/out 2> $W/err; echo "  rc=$?"
		echo "  'not found' on stderr: $(grep -c 'digest: not found' $W/err)"
		[ -x "$t" ] && echo "  digest present after" || echo "  digest absent after"
		echo "  joined lines: $(grep -c '= SHA1 (' distinfo)"
		if [ $edit = no ]; then
			cmp -s distinfo $W/distinfo.orig && echo "  distinfo identical to the tree's" || echo "  distinfo differs from the tree's"
		elif [ -x "$t" ]; then
			# pkgsrc は当て物の $NetBSD 行を除いてから hash を取る
			want=$(sed '/\$NetBSD.*/d' $p | $t sha1)
			got=$(sed -n "s/^SHA1 ($(basename $p)) = //p" distinfo)
			[ "$got" = "$want" ] && echo "  edited patch hash correct" || echo "  edited patch hash WRONG ($got != $want)"
			echo "  lines changed: $(diff $W/distinfo.orig distinfo | grep -c '^>')"
		fi
	done
done
