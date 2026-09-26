#!/bin/sh
# devel/libuuid が DragonFly で lib/cpuset.c を compile できない。
#
#	./include/cpuset.h:43:13: error: '__cpu_mask' undeclared
#	lib/cpuset.c:122:8: error: unknown type name '__cpu_mask'
#
# include/cpuset.h の CPU_ALLOC が無い libc 向けの補いは glibc の内部名で
# 書かれていて、DragonFly は glibc でないのに cpu_set_t を持つので、そこへ
# 入って落ちる。上流は 2026-09-14 に Makefile.common rev 1.16 (PR 60697) で
#
#	CONFIGURE_ENV.DragonFly+=	ac_cv_type_cpu_set_t=no
#
# を置いて configure に lib/cpuset.c を外させた。cdn の current の tarball は
# 2026-09-12 01:18 UTC で止まっているのでまだ入っていない。同じ一行を足す。
# 追いついたら grep が当たって何もしない。
#
# croc は go127 <- go124 <- go122 <- go120 <- python313 <- libuuid でここを
# 通る。DragonFly の run 35092623482 はこれで croc に着かずに落ちた。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
f=$TREE/devel/libuuid/Makefile.common
[ -f "$f" ] || { echo "!! $f が無い" >&2; exit 1; }
if grep -q 'ac_cv_type_cpu_set_t=no' "$f"; then
	echo "  libuuid: 上流に追いついている。何もしない"
	exit 0
fi
# rev 1.16 と同じ位置、.include "../../mk/bsd.prefs.mk" の手前に置く。
awk '
/^\.include "\.\.\/\.\.\/mk\/bsd\.prefs\.mk"/ && !done {
	print "CONFIGURE_ENV.DragonFly+=\tac_cv_type_cpu_set_t=no"
	print ""
	done = 1
}
{ print }' "$f" > "$f.n"
mv "$f.n" "$f"
grep -q 'ac_cv_type_cpu_set_t=no' "$f" || { echo "!! libuuid: 足せていない" >&2; exit 1; }
echo "  libuuid: CONFIGURE_ENV.DragonFly+= ac_cv_type_cpu_set_t=no を足した (上流 rev 1.16 と同じ)"
