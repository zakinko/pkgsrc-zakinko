$NetBSD$

Pull in <machine/limits.h> on NetBSD for DBL_DIG.

Declare the functions this tree defines.  Every one of them was reached
through an implicit declaration, which C99 removed and which clang 16 and
gcc 14 make an error by default.  On LP64 it is also only safe while the
return value fits in an int, which is how the truncation bugs in this tree
were reached.

Three groups.  The first was written by hand for the Lisp_Object returns
that were losing their top half.  The second is generated from definitions
that carry a type, with that type.  The third is generated from definitions
that carry no type at all: in C that means int, so int is what they are
declared as -- the same thing the compiler was already assuming, spelled
out.  Whether those should return void instead is a separate question and
a separate patch, because it means changing the definitions.

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

--- src/lisp.h.orig
+++ src/lisp.h
@@ -30,6 +30,10 @@
 /* 93.1.15  modified for Mule Ver.0.9.7.1 by Y.Akiba <akiba@cbs.canon.co.jp>
 	Patch for NeXT is updated. */
 
+#if defined(__NetBSD__)
+#include <machine/limits.h> /* for DBLL_DIG */
+#endif
+
 /* Define the fundamental Lisp data structures */
 
 /* Define an integer type with the same size as Lisp_Object.
@@ -1550,3 +1554,710 @@
  
 /* Set up the name of the machine we're running on.  */
 extern void init_system_name ();
+void init_data (void);
+
+/* The declarations below used to be missing entirely.  On an ILP32 host
+   that was harmless: an implicitly declared function returns int, and
+   int is the same width as Lisp_Object there.  On an LP64 host with
+   LONG_LISP_OBJECT the two no longer agree, so every one of these calls
+   silently truncated a 64-bit Lisp_Object to 32 bits and handed back a
+   garbage object.  */
+
+/* defined in buffer.c */
+extern Lisp_Object Fbuffer_disable_undo (), Fbuffer_enable_undo ();
+extern Lisp_Object Fbuffer_modified_p (), Fset_buffer_modified_p ();
+extern Lisp_Object Ferase_buffer (), Fkill_buffer ();
+extern Lisp_Object Fnext_overlay_change (), Foverlay_start (), Foverlay_end ();
+
+/* defined in casefiddle.c */
+extern Lisp_Object Fcapitalize_word (), Fupcase_region ();
+extern Lisp_Object upcase_initials_region ();
+
+/* defined in cmds.c */
+extern Lisp_Object Fend_of_line (), Fforward_byte (), Fforward_char ();
+extern Lisp_Object Fforward_line ();
+
+/* defined in data.c */
+extern Lisp_Object Fmake_local_variable (), do_symval_forwarding ();
+
+/* defined in dispnew.c */
+extern Lisp_Object Fding (), Fredraw_frame (), Fsit_for (), Fsleep_for ();
+
+/* defined in editfns.c */
+extern Lisp_Object Fdelete_region (), Finsert_and_inherit ();
+extern Lisp_Object Finsert_before_markers (), Finsert_buffer_substring ();
+extern Lisp_Object Finsert_char (), Fnarrow_to_region (), Fwiden ();
+
+/* defined in emacs.c */
+extern Lisp_Object Fkill_emacs ();
+
+/* defined in eval.c */
+extern Lisp_Object call6 ();
+
+/* defined in fileio.c */
+extern Lisp_Object Fdo_auto_save (), Fwrite_region ();
+
+/* defined in filelock.c */
+extern Lisp_Object Funlock_buffer ();
+
+/* defined in fns.c */
+extern Lisp_Object Felt (), Fmember ();
+
+/* defined in frame.c */
+extern Lisp_Object Fframe_first_window (), Fhandle_switch_frame ();
+extern Lisp_Object Fraise_frame (), Fredirect_frame_focus (), get_frame_param ();
+
+/* defined in indent.c */
+extern Lisp_Object Fmove_to_column ();
+
+/* defined in keyboard.c */
+extern Lisp_Object Fset_input_mode (), command_loop_1 ();
+extern Lisp_Object menu_bar_items (), recursive_edit_1 ();
+
+/* defined in keymap.c */
+extern Lisp_Object Fdefine_key (), Fkey_binding (), Flookup_key ();
+extern Lisp_Object Fmake_sparse_keymap ();
+
+/* defined in marker.c */
+extern Lisp_Object Fset_marker (), set_marker_restricted ();
+
+/* defined in minibuf.c */
+extern Lisp_Object get_minibuffer ();
+
+/* defined in mule.c */
+extern Lisp_Object Fdefine_word_pattern ();
+
+/* defined in print.c */
+extern Lisp_Object internal_with_output_to_temp_buffer ();
+
+/* defined in process.c */
+extern Lisp_Object Fwaiting_for_user_input_p ();
+
+/* defined in search.c */
+extern Lisp_Object Fmatch_beginning (), Fmatch_end ();
+extern Lisp_Object Fskip_chars_backward (), Fskip_chars_forward ();
+
+/* defined in syntax.c */
+extern Lisp_Object Fforward_word ();
+
+/* defined in textprop.c */
+extern Lisp_Object Fget_char_property (), Fget_text_property ();
+extern Lisp_Object Fprevious_single_property_change (), Fput_text_property ();
+
+/* defined in window.c */
+extern Lisp_Object Fpos_visible_in_window_p (), Frecenter ();
+extern Lisp_Object Freplace_buffer_in_windows (), Fscroll_other_window ();
+extern Lisp_Object Fselected_window (), Fset_window_start ();
+
+/* defined in intervals.c.  keymap.c calls this without including
+   intervals.h, where the only other declaration lives. */
+extern Lisp_Object get_local_map ();
+
+/* defined in search.c, and called from the DEFUNs above its definition. */
+extern Lisp_Object skip_chars ();
+
+/* defined in keymap.c, and called from intervals.c, where the value
+   decides whether a local-map text property beats the buffer's keymap. */
+extern Lisp_Object Fkeymapp ();
+
+/* defined in textprop.c, and called from lread.c */
+extern Lisp_Object Fset_text_properties ();
+
+
+/* The rest of the tree's own functions, generated from their definitions.
+   Each was reached through an implicit declaration before, which is only
+   safe while the return value fits in an int.  The type is the one the
+   definition carries; anything the generator could not read as a plain
+   type was left alone.  */
+
+/* defined in alloc.c */
+extern void syms_of_alloc ();
+extern void uninterrupt_malloc ();
+
+/* defined in buffer.c */
+extern void buffer_slot_type_mismatch ();
+extern void fix_overlays_before ();
+extern void fix_overlays_in_range ();
+extern int overlays_at ();
+extern void recenter_overlay_lists ();
+extern void set_buffer_internal ();
+extern int sort_overlays ();
+extern void verify_overlay_modification ();
+
+/* defined in callproc.c */
+extern int relocate_fd ();
+
+/* defined in category.c */
+extern int check_category_at ();
+
+/* defined in charset.c */
+extern int mchar_to_string ();
+
+/* defined in cmds.c */
+extern int forward_point ();
+
+/* defined in data.c */
+extern void store_symval_forwarding ();
+extern void syms_of_data ();
+
+/* defined in dispnew.c */
+extern void adjust_window_charstarts ();
+extern int buffer_posn_from_coords ();
+extern int direct_output_for_insert ();
+extern int direct_output_forward_char ();
+extern void free_frame_glyphs ();
+extern void quit_error_check ();
+extern void redraw_garbaged_frames ();
+extern int scroll_frame_lines ();
+extern int update_frame ();
+
+/* defined in editfns.c */
+extern int clip_to_bounds ();
+extern void init_editfns ();
+extern void insert1 ();
+extern void syms_of_editfns ();
+
+/* defined in eval.c */
+extern void record_unwind_protect ();
+extern void specbind ();
+
+/* defined in fileio.c */
+extern int a_write ();
+extern int e_write ();
+
+/* defined in filelock.c */
+extern int current_lock_owner ();
+extern int current_lock_owner_1 ();
+extern void lock_file ();
+extern int lock_file_1 ();
+extern int lock_if_free ();
+extern void unlock_all_files ();
+extern void unlock_file ();
+
+/* defined in filemode.c */
+extern void filemodestring ();
+
+/* defined in frame.c */
+extern int other_visible_frames ();
+extern void store_frame_param ();
+extern void store_in_alist ();
+
+/* defined in indent.c */
+extern int current_column ();
+extern int indented_beyond_p ();
+extern int pos_tab_offset ();
+
+/* defined in insdel.c */
+extern void del_range ();
+extern void del_range_1 ();
+extern void insert_char ();
+extern void insert_string ();
+
+/* defined in intervals.c */
+extern void set_point ();
+
+/* defined in keyboard.c */
+extern int gobble_input ();
+extern SIGTYPE input_poll_signal ();
+extern int input_polling_used ();
+extern void record_asynch_buffer_change ();
+extern void reinvoke_input_signal ();
+extern void set_poll_suppress_count ();
+extern void swallow_events ();
+
+/* defined in keymap.c */
+extern int current_minor_maps ();
+extern void describe_map_tree ();
+extern void initial_define_key ();
+extern void initial_define_lispy_key ();
+
+/* defined in lread.c */
+extern void close_load_descs ();
+extern void defvar_lisp_nopro ();
+extern void defvar_per_buffer ();
+extern void init_obarray ();
+extern int isfloat_string ();
+extern void map_obarray ();
+extern int openp ();
+extern void syms_of_lread ();
+
+/* defined in mcpath.c */
+extern int mc_access ();
+extern int mc_chdir ();
+extern int mc_chmod ();
+extern int mc_execvp ();
+extern int mc_link ();
+extern int mc_lstat ();
+extern int mc_mkdir ();
+extern ssize_t mc_readlink ();
+extern int mc_rename ();
+extern int mc_rmdir ();
+extern int mc_symlink ();
+extern int mc_unlink ();
+
+/* defined in msdos.c */
+extern void glyph_to_pixel_coords ();
+extern void pixel_to_glyph_coords ();
+
+/* defined in print.c */
+extern void float_to_string ();
+extern void syms_of_print ();
+
+/* defined in process.c */
+extern void change_keyboard_wait_descriptor ();
+extern int wait_reading_process_input ();
+
+/* defined in ralloc.c */
+extern void r_alloc_free ();
+
+/* defined in regex19.c */
+extern int compile_charset ();
+extern int lookup_charset ();
+
+/* defined in scroll.c */
+extern int scrolling_max_lines_saved ();
+
+/* defined in search.c */
+extern int fast_string_match ();
+extern int find_next_newline ();
+extern int find_next_newline_no_quit ();
+
+/* defined in sysdep.c */
+extern void change_input_fd ();
+extern int emacs_get_tty ();
+extern int emacs_set_tty ();
+extern void init_sys_modes ();
+extern void reset_sys_modes ();
+extern int set_window_size ();
+
+/* defined in term.c */
+extern int per_line_cost ();
+extern void ring_bell ();
+extern int string_cost ();
+
+/* defined in termcap.c */
+extern int tgetent ();
+extern int tgetflag ();
+extern int tgetnum ();
+extern void tputs ();
+
+/* defined in textprop.c */
+extern int property_change_between_p ();
+
+/* defined in unexelf.c */
+extern int unexec ();
+
+/* defined in vm-limit.c */
+extern void memory_warnings ();
+
+/* defined in vmsproc.c */
+
+/* defined in widget.c */
+extern void EmacsFrameSetCharSize ();
+
+/* defined in window.c */
+extern void check_frame_size ();
+extern void delete_all_subwindows ();
+extern int window_height ();
+
+/* defined in wnnfns.c */
+extern int check_wnn_server_type ();
+extern int dai_end ();
+
+/* defined in xdisp.c */
+extern void mark_window_display_accurate ();
+extern void message ();
+extern void message1 ();
+extern void message2 ();
+extern void prepare_menu_bars ();
+extern void redisplay ();
+extern void redisplay_region ();
+extern void syms_of_xdisp ();
+extern void truncate_echo_area ();
+
+/* defined in xfaces.c */
+extern void clear_face_vector ();
+extern int compute_char_face ();
+extern int compute_glyph_face ();
+extern int compute_glyph_face_1 ();
+extern int frame_update_line_height ();
+extern void init_frame_faces ();
+extern void recompute_basic_faces ();
+extern void syms_of_xfaces ();
+
+/* defined in xfns.c */
+extern int using_x_p ();
+extern void x_implicitly_set_name ();
+extern void x_real_positions ();
+extern void x_set_frame_parameters ();
+extern void x_set_menu_bar_lines ();
+extern void x_sync ();
+
+/* defined in xmenu.c */
+extern void initialize_frame_menubar ();
+
+/* defined in xselect.c */
+extern void Xatoms_of_xselect ();
+extern void syms_of_xselect ();
+extern void x_clear_frame_selections ();
+extern void x_handle_property_notify ();
+extern void x_handle_selection_clear ();
+extern void x_handle_selection_notify ();
+extern void x_handle_selection_request ();
+
+/* defined in xterm.c */
+extern void syms_of_xterm ();
+extern int x_bitmap_icon ();
+extern void x_catch_errors ();
+extern void x_check_errors ();
+extern int x_had_errors_p ();
+extern void x_set_mouse_pixel_position ();
+extern void x_set_mouse_position ();
+extern void x_start_queuing_selection_requests ();
+extern void x_stop_queuing_selection_requests ();
+extern void x_term_init ();
+extern int x_text_icon ();
+extern void x_uncatch_errors ();
+
+
+/* The tree's own functions whose definitions carry no type at all.  In C
+   that means int, so int is what they are declared as here: the same thing
+   the compiler was already assuming, spelled out.  Whether they should
+   instead return void is a separate question, and a separate patch: it
+   means changing the definitions, not just naming them.  */
+
+/* defined in abbrev.c */
+extern int syms_of_abbrev ();
+
+/* defined in alloc.c */
+extern int display_malloc_warning ();
+extern int free_cons ();
+extern int init_alloc ();
+extern int init_alloc_once ();
+extern int memory_full ();
+
+/* defined in buffer.c */
+extern int init_buffer ();
+extern int init_buffer_once ();
+extern int keys_of_buffer ();
+extern int nsberror ();
+extern int record_buffer ();
+extern int reset_buffer_local_variables ();
+extern int syms_of_buffer ();
+extern int validate_position ();
+extern int validate_region ();
+
+/* defined in bytecode.c */
+extern int syms_of_bytecode ();
+
+/* defined in callint.c */
+extern int syms_of_callint ();
+
+/* defined in callproc.c */
+extern int child_setup ();
+extern int init_callproc ();
+extern int init_callproc_1 ();
+extern int set_process_environment ();
+extern int syms_of_callproc ();
+
+/* defined in canna.c */
+extern int syms_of_canna ();
+
+/* defined in casefiddle.c */
+extern int keys_of_casefiddle ();
+extern int syms_of_casefiddle ();
+
+/* defined in casetab.c */
+extern int init_casetab_once ();
+extern int syms_of_casetab ();
+
+/* defined in category.c */
+extern int init_category_once ();
+extern int pack_mnemonic_string ();
+extern int syms_of_category ();
+
+/* defined in ccl.c */
+extern int ccl_driver ();
+extern int set_ccl_program ();
+extern int syms_of_ccl ();
+
+/* defined in charset.c */
+extern int init_charset_once ();
+extern int search_cmpchar ();
+extern int string_to_mchar ();
+extern int strwidth ();
+extern int syms_of_charset ();
+
+/* defined in cmds.c */
+extern int internal_self_insert ();
+extern int keys_of_cmds ();
+extern int syms_of_cmds ();
+
+/* defined in coding.c */
+extern int encode_code ();
+extern int init_coding ();
+extern int syms_of_coding ();
+
+/* defined in data.c */
+extern int pure_write_error ();
+
+/* defined in dired.c */
+extern int file_name_completion_stat ();
+extern int syms_of_dired ();
+
+/* defined in dispnew.c */
+extern int bitch_at_user ();
+extern int cancel_line ();
+extern int cancel_my_columns ();
+extern int clear_frame_records ();
+extern int do_pending_window_change ();
+extern int preserve_other_columns ();
+extern int redraw_frame ();
+extern int scrolling ();
+extern int syms_of_display ();
+extern int verify_charstarts ();
+
+/* defined in doc.c */
+extern int syms_of_doc ();
+
+/* defined in doprnt.c */
+extern int doprnt ();
+
+/* defined in emacs.c */
+extern int syms_of_emacs ();
+
+/* defined in eval.c */
+extern int do_autoload ();
+extern int init_eval ();
+extern int init_eval_once ();
+extern int syms_of_eval ();
+
+/* defined in fileio.c */
+extern int report_file_error ();
+extern int syms_of_fileio ();
+
+/* defined in filelock.c */
+extern int init_filelock ();
+extern int syms_of_filelock ();
+extern int unlock_buffer ();
+
+/* defined in floatfns.c */
+extern int init_floatfns ();
+extern int syms_of_floatfns ();
+
+/* defined in fns.c */
+extern int syms_of_fns ();
+
+/* defined in fontset.c */
+extern int find_fontset_from_font ();
+extern int fs_load_font ();
+extern int init_fontset ();
+extern int load_query_fontset ();
+extern int query_fontset ();
+extern int syms_of_fontset ();
+
+/* defined in frame.c */
+extern int choose_minibuf_frame ();
+extern void keys_of_frame ();
+extern void syms_of_frame ();
+
+/* defined in indent.c */
+extern int invalidate_current_column ();
+extern int position_indentation ();
+extern int syms_of_indent ();
+
+/* defined in insdel.c */
+extern int adjust_markers2 ();
+extern int insert ();
+extern int insert_and_inherit ();
+extern int insert_before_markers ();
+extern int insert_from_string ();
+extern int make_gap ();
+extern int modify_region ();
+extern int move_gap ();
+extern int prepare_to_modify_buffer ();
+extern int signal_after_change ();
+extern int signal_before_change ();
+
+/* defined in keyboard.c */
+extern int bind_polling_period ();
+extern int clear_input_pending ();
+extern int clear_waiting_for_input ();
+extern int detect_input_pending ();
+extern int echo ();
+extern int init_keyboard ();
+extern int keys_of_keyboard ();
+extern int quit_throw_to_read_char ();
+extern int record_auto_save ();
+extern int restore_getcjmp ();
+extern int save_getcjmp ();
+extern int set_waiting_for_input ();
+extern int start_polling ();
+extern int stop_polling ();
+extern int stuff_buffered_input ();
+extern int syms_of_keyboard ();
+
+/* defined in keymap.c */
+extern int describe_vector ();
+extern int keys_of_keymap ();
+extern int syms_of_keymap ();
+
+/* defined in lread.c */
+extern int init_lread ();
+
+/* defined in macros.c */
+extern int finalize_kbd_macro_chars ();
+extern int init_macros ();
+extern int keys_of_macros ();
+extern int store_kbd_macro_char ();
+extern int syms_of_macros ();
+
+/* defined in marker.c */
+extern int marker_position ();
+extern int syms_of_marker ();
+
+/* defined in mcpath.c */
+extern int syms_of_mcpath ();
+
+/* defined in minibuf.c */
+extern int init_minibuf_once ();
+extern int keys_of_minibuf ();
+extern int scmp ();
+extern int syms_of_minibuf ();
+
+/* defined in mocklisp.c */
+extern int syms_of_mocklisp ();
+
+/* defined in mule.c */
+extern int syms_of_mule ();
+
+/* defined in print.c */
+extern int write_string ();
+extern int write_string_1 ();
+
+/* defined in process.c */
+extern int close_process_descs ();
+extern int create_process ();
+extern int deactivate_process ();
+extern int init_process ();
+extern int kill_buffer_processes ();
+extern int read_process_output ();
+extern int status_notify ();
+extern int syms_of_process ();
+
+/* defined in regex19.c */
+extern int init_compile_charset_information ();
+
+/* defined in scroll.c */
+extern int scroll_cost ();
+
+/* defined in search.c */
+extern int scan_buffer ();
+extern int search_buffer ();
+extern int set_pattern ();
+extern int syms_of_search ();
+
+/* defined in syntax.c */
+extern int scan_words ();
+extern int syms_of_syntax ();
+
+/* defined in sysdep.c */
+extern int child_setup_tty ();
+extern int flush_pending_output ();
+extern int get_frame_size ();
+extern int init_baud_rate ();
+extern int init_sigio ();
+extern int request_sigio ();
+extern int restore_signal_handlers ();
+extern int save_signal_handlers ();
+extern int setup_pty ();
+extern int stuff_char ();
+extern int sys_subshell ();
+extern int sys_suspend ();
+extern int tabs_safe_p ();
+extern int unrequest_sigio ();
+extern int wait_for_termination ();
+
+/* defined in term.c */
+extern int clear_end_of_line ();
+extern int set_scroll_region ();
+extern int syms_of_term ();
+extern int term_init ();
+extern int turn_off_highlight ();
+extern int turn_off_insert ();
+extern int update_begin ();
+
+/* defined in undo.c */
+extern int record_change ();
+extern int syms_of_undo ();
+
+/* defined in window.c */
+extern int init_window_once ();
+extern int keys_of_window ();
+extern int syms_of_window ();
+
+/* defined in wnnfns.c */
+extern int c2m ();
+extern int m2w ();
+extern int syms_of_wnn ();
+extern int w2m ();
+
+/* defined in xdisp.c */
+extern int init_xdisp ();
+extern int redisplay_preserve_echo_area ();
+
+/* defined in xfns.c */
+extern int syms_of_xfns ();
+extern int x_char_height ();
+extern int x_char_width ();
+extern int x_pixel_height ();
+extern int x_pixel_width ();
+extern int x_report_frame_params ();
+extern int x_set_border_pixel ();
+
+/* defined in xmenu.c */
+extern int syms_of_xmenu ();
+
+/* defined in xterm.c */
+extern int x_calc_absolute_position ();
+extern int x_destroy_window ();
+extern int x_display_cursor ();
+extern int x_focus_on_frame ();
+extern int x_lower_frame ();
+extern int x_make_frame_invisible ();
+extern int x_make_frame_visible ();
+extern int x_raise_frame ();
+extern int x_scroll_bar_clear ();
+extern int x_set_offset ();
+extern int x_set_window_size ();
+extern int x_unfocus_frame ();
+extern int x_wm_set_icon_pixmap ();
+extern int x_wm_set_icon_position ();
+extern int x_wm_set_size_hint ();
+extern int x_wm_set_window_state ();
+
+
+/* The last of them: functions of this tree that were still being reached
+   through an implicit declaration after the two generated groups above.  */
+
+extern int fatal ();
+extern int init_syntax_once ();
+extern int insert_with_specified_function ();
+extern void safe_bcopy ();
+extern int describe_syntax_2 ();
+extern int insert_character_description ();
+extern int string_width ();
+extern char *r_alloc ();
+extern char *r_re_alloc ();
+#ifdef HAVE_X_WINDOWS
+/* defined in xfns.c */
+extern Lisp_Object Fx_close_current_connection (), x_get_focus_frame ();
+
+/* defined in xmenu.c */
+extern Lisp_Object Fx_popup_dialog (), Fx_popup_menu ();
+#endif /* HAVE_X_WINDOWS */
+
+/* Linux の枝でだけ通る所が呼ぶもの。X を切ると frame.c 側の宣言が
+   届かなくなる。 */
+extern void change_frame_size ();
+extern void init_signals ();
