$NetBSD$

Bring back the eBPF stubs that 1.58.1 dropped.

n-acd installs an eBPF program on the packet socket to filter by the addresses
it is probing for, and n-acd-bpf.c is written against <linux/bpf.h> and the
bpf() syscall.  Up to 1.50.0 the tree carried n-acd-bpf-fallback.c beside it -
five functions that hand back -1 and succeed - and meson chose between them on
enable_ebpf.  1.58.1 removed both the option and the file, because on Linux
the real one now copes with bpf() being unavailable at runtime.

That does not help a system where the header does not exist at all, so the
file comes back unchanged from 1.50.0 and meson picks it on anything that is
not Linux.  n_acd_has_bpf() asks whether fd_bpf_map is -1, which is what these
stubs leave it as, so 1.58.1's own "carry on without eBPF" path is what runs.

--- src/n-acd/src/n-acd-bpf-fallback.c.orig
+++ src/n-acd/src/n-acd-bpf-fallback.c
@@ -0,0 +1,30 @@
+/*
+ * A noop implementation of eBPF filter for IPv4 Address Conflict Detection
+ *
+ * These are a collection of dummy functions that have no effect, but allows
+ * n-acd to compile without eBPF support.
+ *
+ * See n-acd-bpf.c for documentation.
+ */
+
+#include <c-stdaux.h>
+#include <stddef.h>
+#include "n-acd-private.h"
+
+int n_acd_bpf_map_create(int *mapfdp, size_t max_entries) {
+        *mapfdp = -1;
+        return 0;
+}
+
+int n_acd_bpf_map_add(int mapfd, struct in_addr *addrp) {
+        return 0;
+}
+
+int n_acd_bpf_map_remove(int mapfd, struct in_addr *addrp) {
+        return 0;
+}
+
+int n_acd_bpf_compile(int *progfdp, int mapfd, struct ether_addr *macp) {
+        *progfdp = -1;
+        return 0;
+}
