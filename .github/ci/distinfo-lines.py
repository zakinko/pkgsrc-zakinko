#!/usr/bin/env python3
"""pkgsrc の distinfo 行を作る。BLAKE2s / SHA512 / Size。

手で写すと必ずどこかが古くなるので、取った実物から出す。BLAKE2s は
pkgsrc の digest(1) が使うもので、BLAKE2s-256 (digest_size=32)。b2sum は
BLAKE2b なので使えない。

自分の計算が正しいことを、既知の distinfo 行と突き合わせて先に確かめる
(--selftest)。突き合わせずに出した値は、桁が合っているだけの数字かもしれない。
"""
import argparse, hashlib, sys, urllib.request, os


def digests(path):
    b2 = hashlib.blake2s(digest_size=32)
    s5 = hashlib.sha512()
    s2 = hashlib.sha256()
    n = 0
    with open(path, "rb") as f:
        while True:
            c = f.read(1 << 20)
            if not c:
                break
            n += len(c)
            b2.update(c); s5.update(c); s2.update(c)
    return b2.hexdigest(), s5.hexdigest(), s2.hexdigest(), n


def fetch(url, out):
    print(f"取得: {url}", flush=True)
    with urllib.request.urlopen(url) as r, open(out, "wb") as f:
        while True:
            c = r.read(1 << 20)
            if not c:
                break
            f.write(c)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--url")
    ap.add_argument("--name", help="distinfo に書く名前 (例 rust-bin-1.96.1/rust-...tar.gz)")
    ap.add_argument("--expect-sha256", help="独立な照合用 (rust の channel manifest が持っている)")
    a = ap.parse_args()

    if a.selftest:
        # 小さくて distinfo が公開されている物で、計算そのものを確かめる。
        # pkgsrc の distinfo に在る値と一字一句合わなければ、この道具は使わない。
        # 8.5KB。小さいので手元でも回せる。DIST_SUBDIR が付くので
        # distinfo の名前は "thttpd-2.29/sitedrivenby.gif" で、取得先も
        # distfiles/ の下にその directory がある。
        want = "thttpd-2.29/sitedrivenby.gif"
        url = "https://cdn.NetBSD.org/pub/pkgsrc/distfiles/" + want
        want_b2 = None
        di = urllib.request.urlopen(
            "https://raw.githubusercontent.com/NetBSD/pkgsrc/trunk/www/thttpd/distinfo"
        ).read().decode()
        for line in di.splitlines():
            p = line.split()
            if len(p) >= 4 and p[1] == "(" + want + ")":
                if p[0] == "BLAKE2s":
                    want_b2 = p[3]
                elif p[0] == "SHA512":
                    want_s5 = p[3]
                elif p[0] == "Size":
                    want_sz = int(p[3])
        if want_b2 is None:
            print("!! 自己試験の distinfo が読めない。道具を使わない。")
            return 1
        f = fetch(url, os.path.join(os.environ.get("TMPDIR", "."), "distinfo-selftest.bin"))
        b2, s5, _s2, n = digests(f)
        ok = (b2 == want_b2 and s5 == want_s5 and n == want_sz)
        print(f"  BLAKE2s 計算 {b2}\n          distinfo {want_b2}")
        print(f"  SHA512  {'一致' if s5 == want_s5 else '不一致'}")
        print(f"  Size    {n} / {want_sz}")
        print("自己試験: " + ("通った" if ok else "!! 合わない"))
        os.unlink(f)
        return 0 if ok else 1

    if not a.url or not a.name:
        print("--url と --name が要る", file=sys.stderr)
        return 2
    f = fetch(a.url, os.path.basename(a.url))
    b2, s5, s2, n = digests(f)
    if a.expect_sha256:
        if s2 != a.expect_sha256:
            print(f"!! SHA256 が合わない。取得が壊れている\n   計算 {s2}\n   期待 {a.expect_sha256}",
                  file=sys.stderr)
            return 1
        print(f"  SHA256 は manifest と一致 ({s2[:16]}…)")
    print()
    print(f"BLAKE2s ({a.name}) = {b2}")
    print(f"SHA512 ({a.name}) = {s5}")
    print(f"Size ({a.name}) = {n} bytes")
    os.unlink(f)
    return 0


if __name__ == "__main__":
    sys.exit(main())
