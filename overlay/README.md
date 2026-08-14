# overlay

上流 pkgsrc のパッケージに、こちらで手を入れたものを置くところ。ここは
`zakinko` カテゴリではなく、**上流のカテゴリ**への当て物。

```
overlay/<カテゴリ>/<パッケージ>/...  →  /usr/pkgsrc/<カテゴリ>/<パッケージ>/...
```

## 誰が使うか

[NetBSD-i386](https://github.com/zakinko/NetBSD-i386) の CI。この repo を
`zakinko` カテゴリとして clone したあと、`overlay/` の中身を上流 pkgsrc の
同じ場所へ上書きコピーし、`zakinko/overlay` はツリーから取り除いてから
ビルドに入る (`ci/make-pkgsrc-tarball.sh`)。

当てた場所は `.overlay-dirs` に記録され、ゲスト側で `make makepatchsum` が
走って distinfo に patch の SHA1 が入る。pkgsrc 標準のターゲットなので、
こちらでハッシュを計算する必要はない。

**pkgsrc から見ると package でないディレクトリがカテゴリに混ざる形になる。**
カテゴリの `Makefile` は `SUBDIR` を明示しているので `make` は無視するが、
`pkglint` は文句を言うかもしれない。CI は取り除いてから渡すのでビルドには
影響しない。

## 決まりごと

- **PKGREVISION を上げる。** patch を足しただけだと PKGNAME が変わらず、
  手元の pkgin が「同じものが入っている」と判断して入れ替えてくれない。
  Makefile ごと写して番号を上げるのが手っ取り早い。ただし入れるものが
  変わらない修正 (依存側が要求する名前を直すなど) では上げない。
- **一時的なものとして扱う。** ここに置くのは「上流 pkgsrc がまだ取り込んで
  いない」ものだけ。取り込まれたらディレクトリごと消す。消し忘れると、
  上流が直したあとも古い写しの Makefile を使い続けることになる。
- **上流にも送る。** ここに置くのはあくまで手元をすぐ直すためで、本筋は
  pkgsrc 本体に入れること。送るための diff とメールは
  [NetBSD-i386 の doc/upstream/](https://github.com/zakinko/NetBSD-i386/tree/main/doc/upstream)
  にある。

## 今あるもの

| | 何 | 消してよくなる条件 |
|---|---|---|
| `sysutils/augeas` | CVE-2025-2588 の NULL 参照修正 + PKGREVISION 2 | pkgsrc が同等の patch を入れるか、augeas が 1.14.2 を出して pkgsrc が追随したとき |
| `textproc/libxml2` | 2.15.1 → 2.15.3。CVE 5 件分 | pkgsrc が 2.15.2 以降に上がったとき |
| `inputmethod/anthy-elisp` | `EMACS_VERSIONS_ACCEPTED` に emacs26〜30 を追加 | pkgsrc が同等の変更を入れたとき |
| `editors/emacs30-nox11` | `_EMACS_REQD` の綴りを `emacs30-no-x11` から `emacs30-nox11` へ | pkgsrc が同等の変更を入れたとき |

`libxml2` と `anthy-elisp` は NetBSD 11.0/i386 でビルド確認済み (pkgsrc
trunk `fa7ad771c96929bf742033e6ccfd8bb45b9cab49`)。`augeas` は patch を
上流 commit そのものに差し替えたところで、9.4/i386 でビルドと `make test`
を確認済み、11.0 は CI で確認中。`emacs30-nox11` も同じ CI で見る。

`anthy-elisp` は上流が emacs21 世代しか受け付けず、`~/.emacs` の
`(load-library "anthy")` を塞いでいた。26 以降を足したところ `.elc` が 6 本
生成され、anthy.el 自体は新しい Emacs で問題ないことが分かっている。

`emacs30-nox11` はその続きで踏んだもの。emacs30 で建てようとすると、
`modules.mk` が要求する名前と実際の PKGNAME が食い違っていて
`depends.mk` で止まる。emacs30-nox11 自体は建つので、壊れているのは
依存する側すべて。
