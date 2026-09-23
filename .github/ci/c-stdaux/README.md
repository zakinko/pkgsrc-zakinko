# c-stdaux を BSD で使えるようにする当て物

上流 (c-util/c-stdaux) へ出すための三箇所の変更と、それを四つの BSD で測る物。

`c-stdaux.h` は `c-stdaux-unix.h` を `C_OS_LINUX` か `C_OS_MACOS` のときだけ
読む。BSD にはどちらも立たないので、`c_close()` も `c_closedir()` も
`C_MODULE_UNIX` も現れない。`c-stdaux-unix.h` の中身 —
dirent/fcntl/sys/time/sys/types/unistd と close(2)/closedir(3) — に Linux
固有の物は一つも無いので、`C_OS_BSD` を足して条件に並べるだけで足りる。

NetworkManager が `src/c-stdaux/` に同梱している写しは、ここで触る三つの file
については上流 main (652caf87) と一 byte も違わない。だから継ぎ目の検査
(`../n-acd/verify-seam.sh`) が展開する配布物にそのまま当てられる。当たる先が
素であることは、当てる前に probe が建たないことで測っている。
