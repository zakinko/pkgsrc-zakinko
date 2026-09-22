$NetBSD$

mpv takes --input-ipc-server=FILE as one argument now.  From Debian.

--- bongo.el.orig
+++ bongo.el
@@ -6428,7 +6428,7 @@ Also fetch metadata and length of track if not fetched already."
   "Get the command line argument for starting mpv's remote interface at SOCKET-FILE."
   (when (equal bongo-mpv-remote-option 'unknown)
     (setq bongo-mpv-remote-option (bongo--mpv-get-remote-option)))
-  (list bongo-mpv-remote-option socket-file))
+  (list (concat bongo-mpv-remote-option "=" socket-file)))
 
 (defun bongo-mpv-player-pause/resume (player)
   "Play/pause mpv PLAYER."
