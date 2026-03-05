// ========================================================================
// Parallel Collatz - RAMBOard Version
// Author: kayto
// Version: 2026-03-03
// ========================================================================
//
// Optimised for fastest completion using both C64 and 1541 CPUs in
// parallel. No solo timing round — goes straight to dual-CPU compute.
//
// How it works:
//   The C64 and 1541 disk drive each contain a 6502 CPU at ~1 MHz.
//   This program uploads Collatz code to the 1541 and splits the
//   workload by odd/even:
//
//     C64 CPU:    computes ODDS   1, 3, 5, ..., 2999  (1500 numbers)
//     1541 CPU:   computes EVENS  2, 4, 6, ..., 3000  (1500 numbers)
//
//   Both CPUs run simultaneously with no synchronisation until done.
//   After computing, the drive bulk-sends its 1500 per-number step
//   counts from RAMBOard RAM ($8000+) back to the C64 over fast serial.
//
// Memory map (C64):
//   $0801-$080C  BASIC stub
//   $1000+       Main program
//   $0400-$07E7  Screen RAM
//   $A000-$A5DB  C64 step-count buffer (1500 odds)
//   $A600-$ABDB  Drive step-count buffer (1500 evens, received)
//
// Memory map (drive):
//   $0300-$05FF  Drive code (3 pages, stock 1541 RAM)
//   $8000-$85DB  RAMBOard step-count buffer (1500 evens)
//
// Requires: 1541 with RAMBOard (8KB RAM at $8000-$9FFF)
// VICE: Use -drive8ram8000 flag to enable drive RAM expansion.
// ========================================================================

.encoding "screencode_upper"

// ========================================
// CONSTANTS
// ========================================

.const SCREEN      = $0400
.const COLORRAM    = $d800
.const BORDER      = $d020
.const BGCOL       = $d021

// Range
.const N_MAX       = 3000
.const COUNT       = 1500       // numbers per CPU

// Drive code: 3 pages ($0300-$05FF)
.const DRV_PAGES   = 3

// C64-side buffers (BASIC ROM area, available when $01=$36)
.const C64_BUF     = $a000     // 1500 bytes: C64 odds step counts
.const DRV_BUF     = $a600     // 1500 bytes: drive evens step counts (received)

// Sequence viewer
.const ROWS_PER_PAGE = 22      // data rows per page (rows 2-23)
.const TOTAL_PAGES   = 137     // ceil(3000 / 22) = 137 pages

// ========================================
// ZERO PAGE VARIABLES
// ========================================

// 24-bit Collatz working value
.const colz_n_lo   = $02
.const colz_n_mid  = $03
.const colz_n_hi   = $04

// Temp for 3n+1 calculation
.const colz_t_lo   = $05
.const colz_t_mid  = $06
.const colz_t_hi   = $07

// Step count for current number
.const colz_steps  = $08

// Outer loop: current starting number (16-bit)
.const cur_n_lo    = $09
.const cur_n_hi    = $0a

// Outer loop: iteration counter
.const iter_lo     = $0b
.const iter_hi     = $0c

// Running total steps (24-bit accumulator)
.const total_lo    = $0d
.const total_mid   = $0e
.const total_hi    = $0f

// Outer n step (2 = parallel odds)
.const n_step      = $10

// Elapsed jiffies (16-bit)
.const time_lo     = $11
.const time_hi     = $12

// Mode: 0=parallel, 1=solo
.const run_mode    = $13

// Drive serial byte scratch
.const drv_byte    = $15

// Buffer pointer for C64 step-count storage
.const buf_ptr_lo  = $17
.const buf_ptr_hi  = $18

// Record holder tracking
.const max_steps   = $19
.const max_n_lo    = $1a
.const max_n_hi    = $1b

// Bulk receive counter
.const recv_cnt_lo = $1c
.const recv_cnt_hi = $1d

// Page viewer
.const page_num    = $1e       // current page (0-based)
.const rows_left   = $1f      // rows remaining on current page

// Screen/string pointers
.const scr_lo      = $fb
.const scr_hi      = $fc
.const str_lo      = $fd
.const str_hi      = $fe

// ========================================
// BASIC STUB
// ========================================
.pc = $0801
        .byte $0b, $08
        .byte $00, $00
        .byte $9e
        .text "4096"
        .byte $00, $00, $00

// ========================================
// MAIN PROGRAM
// ========================================
.pc = $1000

main:
        lda #$36                // BASIC ROM off, I/O on, Kernal on
        sta $01

        lda #$0e                // light blue border
        sta BORDER
        lda #$06                // dark blue background
        sta BGCOL

        jsr clear_screen
        jsr set_all_colors

        // ---- Title / info screen ----
        lda #<str_title
        ldy #>str_title
        ldx #0
        jsr print_at_row_inv

        lda #<str_subtitle
        ldy #>str_subtitle
        ldx #2
        jsr print_at_row

        lda #<str_explain1
        ldy #>str_explain1
        ldx #5
        jsr print_at_row

        lda #<str_explain2
        ldy #>str_explain2
        ldx #7
        jsr print_at_row

        lda #<str_explain3
        ldy #>str_explain3
        ldx #8
        jsr print_at_row

        lda #<str_explain4
        ldy #>str_explain4
        ldx #9
        jsr print_at_row

        lda #<str_press_start
        ldy #>str_press_start
        ldx #12
        jsr print_at_row

        lda #<str_mode_par
        ldy #>str_mode_par
        ldx #14
        jsr print_at_row

        lda #<str_mode_solo
        ldy #>str_mode_solo
        ldx #15
        jsr print_at_row

mode_select:
        jsr $ffe4
        cmp #$31                // '1' = parallel
        beq mode_parallel
        cmp #$32                // '2' = solo
        beq mode_solo
        bne mode_select

mode_solo:
        lda #1
        sta run_mode
        jmp compute_start

mode_parallel:
        lda #0
        sta run_mode

        // ---- Init drive (parallel only) ----
        lda #<str_init_drive
        ldy #>str_init_drive
        ldx #18
        jsr print_at_row

        jsr drive_bootstrap

        // ---- RAMBOard detection ----
        lda #'D'
        jsr senddriv
        jsr getdriv
        cmp #$01
        beq rb_found

        lda #<str_no_ramboard
        ldy #>str_no_ramboard
        ldx #20
        jsr print_at_row

        // Reset drive cleanly
        lda #'Q'
        jsr senddriv
        lda #$03
        sta $dd00

        lda #<str_press_go
        ldy #>str_press_go
        ldx #22
        jsr print_at_row
        jsr wait_key
        jmp main

rb_found:
        lda #<str_rb_ready
        ldy #>str_rb_ready
        ldx #20
        jsr print_at_row

        lda #<str_press_go
        ldy #>str_press_go
        ldx #22
        jsr print_at_row
        jsr wait_key

compute_start:
        // ==============================
        // COMPUTE
        // ==============================
        jsr clear_screen

        // Show mode-appropriate header
        lda run_mode
        bne solo_header

        lda #<str_computing_hdr
        ldy #>str_computing_hdr
        ldx #0
        jsr print_at_row_inv

        lda #<str_range_cpu
        ldy #>str_range_cpu
        ldx #2
        jsr print_at_row

        lda #<str_range_drv
        ldy #>str_range_drv
        ldx #3
        jsr print_at_row

        lda #<str_status_run
        ldy #>str_status_run
        ldx #5
        jsr print_at_row

        jmp compute_begin

solo_header:
        lda #<str_solo_hdr
        ldy #>str_solo_hdr
        ldx #0
        jsr print_at_row_inv

        lda #<str_solo_range
        ldy #>str_solo_range
        ldx #2
        jsr print_at_row

        lda #<str_solo_status
        ldy #>str_solo_status
        ldx #5
        jsr print_at_row

compute_begin:

        // Reset total
        lda #0
        sta total_lo
        sta total_mid
        sta total_hi

        // Check mode
        lda run_mode
        bne do_solo_jmp
        jmp do_parallel
do_solo_jmp:
        jmp do_solo

do_solo:
        // ---- SOLO: C64 computes ALL N=1..3000 contiguously ----
        lda #1
        sta cur_n_lo
        lda #0
        sta cur_n_hi

        lda #<N_MAX
        sta iter_lo
        lda #>N_MAX
        sta iter_hi

        // Init single contiguous buffer pointer at C64_BUF
        lda #<C64_BUF
        sta buf_ptr_lo
        lda #>C64_BUF
        sta buf_ptr_hi

        // ---- Reset TI to 0 via SETTIM ----
        lda #0
        ldx #0
        ldy #0
        jsr $ffdb

solo_loop:
        lda cur_n_lo
        sta colz_n_lo
        lda cur_n_hi
        sta colz_n_mid
        lda #0
        sta colz_n_hi
        sta colz_steps

        jsr collatz_run

        // Store step count contiguously
        lda colz_steps
        ldy #0
        sta (buf_ptr_lo),y
        inc buf_ptr_lo
        bne solo_acc
        inc buf_ptr_hi

solo_acc:
        // Accumulate total
        lda colz_steps
        clc
        adc total_lo
        sta total_lo
        bcc solo_acc_done
        inc total_mid
        bne solo_acc_done
        inc total_hi
solo_acc_done:

        // Advance cur_n by 1
        inc cur_n_lo
        bne solo_next
        inc cur_n_hi
solo_next:

        lda iter_lo
        bne !+
        dec iter_hi
!:      dec iter_lo
        lda iter_lo
        ora iter_hi
        bne solo_loop

        // Solo done — jump to timer readout
        jmp compute_done

do_parallel:
        // ---- Send 'C' command to drive ----
        lda #'C'
        jsr senddriv
        lda #2                  // start_lo = 2
        jsr senddriv
        lda #0                  // start_hi = 0
        jsr senddriv
        lda #<COUNT             // count_lo
        jsr senddriv
        lda #>COUNT             // count_hi
        jsr senddriv
        lda #2                  // step = 2
        jsr senddriv

        // Drive is now computing evens and buffering to RAMBOard!

        // C64: odds 1,3,...,2999 (start=1, step=2, count=1500)
        lda #1
        sta cur_n_lo
        lda #0
        sta cur_n_hi
        lda #2
        sta n_step

        lda #<COUNT
        sta iter_lo
        lda #>COUNT
        sta iter_hi

        // Init C64 buffer pointer
        lda #<C64_BUF
        sta buf_ptr_lo
        lda #>C64_BUF
        sta buf_ptr_hi

        // ---- Reset TI to 0 via SETTIM ----
        lda #0
        ldx #0
        ldy #0
        jsr $ffdb           // SETTIM: set TI to 0

        // ---- TIGHT COMPUTE LOOP (no display updates) ----
para_loop:
        lda cur_n_lo
        sta colz_n_lo
        lda cur_n_hi
        sta colz_n_mid
        lda #0
        sta colz_n_hi
        sta colz_steps

        jsr collatz_run

        // Buffer step count
        lda colz_steps
        ldy #0
        sta (buf_ptr_lo),y
        inc buf_ptr_lo
        bne para_buf_ok
        inc buf_ptr_hi
para_buf_ok:

        // Accumulate total
        lda colz_steps
        clc
        adc total_lo
        sta total_lo
        bcc para_acc_done
        inc total_mid
        bne para_acc_done
        inc total_hi
para_acc_done:

        // Advance cur_n by 2
        lda cur_n_lo
        clc
        adc #2
        sta cur_n_lo
        bcc para_next
        inc cur_n_hi
para_next:

        lda iter_lo
        bne !+
        dec iter_hi
!:      dec iter_lo
        lda iter_lo
        ora iter_hi
        bne para_loop

compute_done:
        // ---- C64 done — read timer ----
        jsr $ffde           // RDTIM
        sta time_lo
        stx time_hi

        lda #<str_c64_done
        ldy #>str_c64_done
        ldx #7
        jsr print_at_row

        // Print elapsed time
        lda #9
        sta pj_row
        lda #2
        sta pj_col
        lda time_hi
        sta pj_val_hi
        lda time_lo
        sta pj_val_lo
        jsr print_timer_at

        // Check if solo — skip drive receive
        lda run_mode
        beq do_receive
        jmp post_receive

do_receive:
        // 3-byte total
        jsr getdriv
        sta drv_recv_lo
        jsr getdriv
        sta drv_recv_mid
        jsr getdriv
        sta drv_recv_hi

        lda #<str_receiving
        ldy #>str_receiving
        ldx #11
        jsr print_at_row

        // Bulk receive 1500 step-count bytes
        lda #<DRV_BUF
        sta buf_ptr_lo
        lda #>DRV_BUF
        sta buf_ptr_hi
        lda #<COUNT
        sta recv_cnt_lo
        lda #>COUNT
        sta recv_cnt_hi

bulk_recv_loop:
        jsr getdriv
        ldy #0
        sta (buf_ptr_lo),y
        inc buf_ptr_lo
        bne bulk_recv_noinc
        inc buf_ptr_hi
bulk_recv_noinc:
        lda recv_cnt_lo
        bne bulk_recv_dec
        dec recv_cnt_hi
bulk_recv_dec:
        dec recv_cnt_lo
        lda recv_cnt_lo
        ora recv_cnt_hi
        bne bulk_recv_loop

post_receive:

        lda #<str_all_done
        ldy #>str_all_done
        ldx #13
        jsr print_at_row

        lda #<str_press_view
        ldy #>str_press_view
        ldx #15
        jsr print_at_row

        jsr wait_key

        // ==============================
        // SEQUENCE VIEWER: scan for record holder
        // ==============================
        lda #0
        sta max_steps
        sta max_n_lo
        sta max_n_hi

        lda run_mode
        beq scan_parallel

        // Solo: scan single contiguous buffer of 3000 entries
        lda #<C64_BUF
        sta buf_ptr_lo
        lda #>C64_BUF
        sta buf_ptr_hi
        lda #1
        sta cur_n_lo
        lda #0
        sta cur_n_hi
        lda #1
        sta n_step
        lda #<N_MAX
        sta iter_lo
        lda #>N_MAX
        sta iter_hi
        jsr scan_record
        jmp scan_done

scan_parallel:
        // Scan odds buffer
        lda #<C64_BUF
        sta buf_ptr_lo
        lda #>C64_BUF
        sta buf_ptr_hi
        lda #1
        sta cur_n_lo
        lda #0
        sta cur_n_hi
        lda #2
        sta n_step
        lda #<COUNT
        sta iter_lo
        lda #>COUNT
        sta iter_hi
        jsr scan_record

        // Scan evens buffer
        lda #<DRV_BUF
        sta buf_ptr_lo
        lda #>DRV_BUF
        sta buf_ptr_hi
        lda #2
        sta cur_n_lo
        lda #0
        sta cur_n_hi
        lda #2
        sta n_step
        lda #<COUNT
        sta iter_lo
        lda #>COUNT
        sta iter_hi
        jsr scan_record

scan_done:

        // ==============================
        // SEQUENCE VIEWER: paginated display
        // ==============================
        lda #0
        sta $c6                 // flush keyboard buffer
        sta page_num
        jsr sv_goto_page

sv_page_loop:
        jsr clear_screen

        // Header row 0 (mode-dependent)
        lda run_mode
        bne sv_solo_hdr
        lda #<str_seq_hdr
        ldy #>str_seq_hdr
        jmp sv_print_hdr
sv_solo_hdr:
        lda #<str_seq_hdr_solo
        ldy #>str_seq_hdr_solo
sv_print_hdr:
        ldx #0
        jsr print_at_row_inv

        // Record holder row 1
        lda row_tab_lo+1
        sta scr_lo
        lda row_tab_hi+1
        sta scr_hi
        lda #0
        sta pj_off
        ldx #0
sv_rh_lbl:
        lda str_rh_prefix,x
        beq sv_rh_lbl_done
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        inx
        bne sv_rh_lbl
sv_rh_lbl_done:
        lda max_n_lo
        sta pj_tmp
        lda max_n_hi
        sta pj_tmp+1
        lda #0
        sta pj_lead
        jsr print_u16_decimal
        ldx #0
sv_rh_sfx:
        lda str_rh_suffix,x
        beq sv_rh_sfx_done
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        inx
        bne sv_rh_sfx
sv_rh_sfx_done:
        lda max_steps
        sta pj_tmp
        lda #0
        sta pj_tmp+1
        sta pj_lead
        jsr print_u16_decimal

        // Draw up to ROWS_PER_PAGE rows
        lda #ROWS_PER_PAGE
        sta rows_left
        lda #2
        sta $16                 // reuse disp_ctr as current row

sv_row_loop:
        // Check if cur_n > N_MAX
        lda cur_n_hi
        cmp #>N_MAX
        bcc sv_row_ok
        bne sv_page_jmp
        lda cur_n_lo
        cmp #<N_MAX
        beq sv_row_ok
        bcc sv_row_ok
sv_page_jmp:
        jmp sv_page_done
sv_row_ok:
        // Position at current row
        ldx $16
        lda row_tab_lo,x
        sta scr_lo
        lda row_tab_hi,x
        sta scr_hi
        lda #0
        sta pj_off

        // Print "N="
        lda #$0e                // 'N' screencode
        ldy #0
        sta (scr_lo),y
        lda #$3d                // '=' screencode
        ldy #1
        sta (scr_lo),y
        lda #2
        sta pj_off

        // Print cur_n
        lda cur_n_lo
        sta pj_tmp
        lda cur_n_hi
        sta pj_tmp+1
        lda #0
        sta pj_lead
        jsr print_u16_decimal

        // Pad to column 8
        ldy pj_off
sv_pad: cpy #8
        bcs sv_pad_done
        lda #$20
        sta (scr_lo),y
        iny
        bne sv_pad
sv_pad_done:
        sty pj_off

        // Print "STEPS="
        lda #$13                // 'S'
        ldy pj_off
        sta (scr_lo),y
        iny
        lda #$14                // 'T'
        sta (scr_lo),y
        iny
        lda #$05                // 'E'
        sta (scr_lo),y
        iny
        lda #$10                // 'P'
        sta (scr_lo),y
        iny
        lda #$13                // 'S'
        sta (scr_lo),y
        iny
        lda #$3d                // '='
        sta (scr_lo),y
        iny
        sty pj_off

        // Get step count: mode-dependent buffer read
        lda run_mode
        bne sv_read_solo

        // Parallel: odd N from C64_BUF, even N from DRV_BUF
        lda cur_n_lo
        and #1
        bne sv_read_odd

sv_read_even:
        lda sv_even_lo
        sta buf_ptr_lo
        lda sv_even_hi
        sta buf_ptr_hi
        ldy #0
        lda (buf_ptr_lo),y
        pha
        inc sv_even_lo
        bne sv_even_ok
        inc sv_even_hi
sv_even_ok:
        jmp sv_print_steps

sv_read_odd:
        lda sv_odd_lo
        sta buf_ptr_lo
        lda sv_odd_hi
        sta buf_ptr_hi
        ldy #0
        lda (buf_ptr_lo),y
        pha
        inc sv_odd_lo
        bne sv_odd_ok
        inc sv_odd_hi
sv_odd_ok:
        jmp sv_print_steps

sv_read_solo:
        // Solo: contiguous buffer, read sequentially from sv_odd
        lda sv_odd_lo
        sta buf_ptr_lo
        lda sv_odd_hi
        sta buf_ptr_hi
        ldy #0
        lda (buf_ptr_lo),y
        pha
        inc sv_odd_lo
        bne sv_print_steps
        inc sv_odd_hi

sv_print_steps:
        pla
        sta pj_tmp
        lda #0
        sta pj_tmp+1
        sta pj_lead
        jsr print_u16_decimal

        // Print " CPU" or " DRV" label
        lda #$20
        ldy pj_off
        sta (scr_lo),y
        iny

        lda run_mode
        bne sv_label_cpu        // solo: always CPU

        lda cur_n_lo
        and #1
        beq sv_label_drv
sv_label_cpu:
        // Odd N = CPU (or all CPU in solo mode)
        lda #$03                // 'C'
        sta (scr_lo),y
        iny
        lda #$10                // 'P'
        sta (scr_lo),y
        iny
        lda #$15                // 'U'
        sta (scr_lo),y
        iny
        jmp sv_label_done
sv_label_drv:
        // Even N = DRV
        lda #$04                // 'D'
        sta (scr_lo),y
        iny
        lda #$12                // 'R'
        sta (scr_lo),y
        iny
        lda #$16                // 'V'
        sta (scr_lo),y
        iny
sv_label_done:
        sty pj_off

        // Advance cur_n
        inc cur_n_lo
        bne sv_no_inc_hi
        inc cur_n_hi
sv_no_inc_hi:

        inc $16                 // next row
        dec rows_left
        beq sv_page_done
        jmp sv_row_loop

sv_page_done:
        // Footer: "PAGE XX/137  PRESS KEY..."
        lda row_tab_lo+24
        sta scr_lo
        lda row_tab_hi+24
        sta scr_hi
        lda #0
        sta pj_off

        ldx #0
sv_pg_lbl:
        lda str_page_prefix,x
        beq sv_pg_lbl_done
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        inx
        bne sv_pg_lbl
sv_pg_lbl_done:

        // Page number (1-based)
        lda page_num
        clc
        adc #1
        sta pj_tmp
        lda #0
        adc #0
        sta pj_tmp+1
        sta pj_lead
        jsr print_u16_decimal

        lda #$2f                // '/'
        ldy pj_off
        sta (scr_lo),y
        inc pj_off

        lda #<TOTAL_PAGES
        sta pj_tmp
        lda #>TOTAL_PAGES
        sta pj_tmp+1
        lda #0
        sta pj_lead
        jsr print_u16_decimal

        ldx #0
sv_pr_lbl:
        lda str_page_suffix,x
        beq sv_pr_lbl_done
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        inx
        bne sv_pr_lbl
sv_pr_lbl_done:

        // Key press to advance page, Q to exit
        lda #0
        sta $c6                 // flush keyboard buffer
sv_wait_key:
        jsr $ffe4               // GETIN
        beq sv_wait_key         // no key, loop
        cmp #$03                // RUN/STOP = exit
        beq sv_escape
        cmp #$51                // 'Q' = exit
        beq sv_escape

        // -- Any other key = next page --
        // Check if all N_MAX shown
        lda cur_n_hi
        cmp #>N_MAX
        bcc sv_next_ok
        bne sv_wrap
        lda cur_n_lo
        cmp #<N_MAX
        beq sv_next_ok
        bcs sv_wrap
sv_next_ok:
        inc page_num
        jsr sv_goto_page
        jmp sv_page_loop

sv_wrap:
        // Wrap back to page 0
        lda #0
        sta page_num
        jsr sv_goto_page
        jmp sv_page_loop

sv_escape:
        // If parallel mode, reset drive before returning to menu
        lda run_mode
        bne sv_esc_go           // solo mode — no drive to reset
        lda #'Q'
        jsr senddriv
        lda #$03
        sta $dd00
sv_esc_go:
        jmp main


// ========================================================================
// ANALYSIS ROUTINES
// ========================================================================

scan_record:
sr_loop:
        ldy #0
        lda (buf_ptr_lo),y
        cmp max_steps
        bcc sr_not_max
        beq sr_not_max
        sta max_steps
        lda cur_n_lo
        sta max_n_lo
        lda cur_n_hi
        sta max_n_hi
sr_not_max:
        inc buf_ptr_lo
        bne sr_noinc
        inc buf_ptr_hi
sr_noinc:
        lda cur_n_lo
        clc
        adc n_step
        sta cur_n_lo
        bcc sr_next
        inc cur_n_hi
sr_next:
        lda iter_lo
        bne sr_dec
        dec iter_hi
sr_dec:
        dec iter_lo
        lda iter_lo
        ora iter_hi
        bne sr_loop
        rts


// ========================================================================
// COLLATZ COMPUTATION (C64 SIDE)
// ========================================================================

collatz_run:
colz_loop:
        lda colz_n_lo
        cmp #1
        bne colz_not_one
        lda colz_n_mid
        ora colz_n_hi
        beq colz_done
colz_not_one:

        lda colz_n_lo
        and #1
        bne colz_odd

colz_even:
        lsr colz_n_hi
        ror colz_n_mid
        ror colz_n_lo
        jmp colz_step

colz_odd:
        lda colz_n_lo
        sta colz_t_lo
        lda colz_n_mid
        sta colz_t_mid
        lda colz_n_hi
        sta colz_t_hi
        asl colz_n_lo
        rol colz_n_mid
        rol colz_n_hi
        lda colz_n_lo
        clc
        adc colz_t_lo
        sta colz_n_lo
        lda colz_n_mid
        adc colz_t_mid
        sta colz_n_mid
        lda colz_n_hi
        adc colz_t_hi
        sta colz_n_hi
        inc colz_n_lo
        bne colz_step
        inc colz_n_mid
        bne colz_step
        inc colz_n_hi

colz_step:
        inc colz_steps
        jmp colz_loop

colz_done:
        rts


// ========================================================================
// SERIAL COMMUNICATION (C64 SIDE)
// ========================================================================

senddriv:
        sei
        jsr senddriv_raw
        cli
        rts

senddriv_raw:
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        bit $dd00
        bvc *-3
        sec
sd_wait:
        lda $d012
        sbc #$32
        bcs sd_wait
        lda #$03
        sta $dd00
        lda tabkon,x
        sta $dd00
        lsr
        lsr
        and #$f7
        sta $dd00
        pla
        and #$0f
        tax
        lda tabkon,x
        sta $dd00
        lsr
        lsr
        and #$f7
        sta $dd00
        lda #$23
        nop
        nop
        nop
        sta $dd00
        rts

tabkon:
        .byte $07,$87,$27,$a7,$47,$c7
        .byte $67,$e7
        .byte $17,$97,$37,$b7,$57,$d7
        .byte $77,$f7

getdriv:
        sei
        bit $dd00
        bvc *-3
        sec
gd_rast:
        lda $d012
        sbc #$32
        bcc gd_ok
        and #$07
        beq gd_rast
gd_ok:
        lda #$03
        sta $dd00
        nop
        nop
        nop
        lda #$ff
        ldx #$23
        eor $dd00
        lsr
        lsr
        eor $dd00
        lsr
        lsr
        eor $dd00
        lsr
        lsr
        eor $dd00
        stx $dd00
        cli
        rts


// ========================================================================
// IEC BOOTSTRAP ROUTINES
// ========================================================================

drive_bootstrap:
        lda $ba
        cmp #$08
        bcs db_notdrv
        lda #$08
        sta $ba
db_notdrv:
        lda #<save
        sta db_ptr+1
        lda #>save
        sta db_ptr+2
        lda #0
        sta mwrt

        ldx #3
db_mw_loop:
        jsr listen
        bcc db_mw_ok
        lda #<str_no_drive
        ldy #>str_no_drive
        ldx #17
        jsr print_at_row
        jmp *
db_mw_ok:
        ldy #$05
db_mw_cmd:
        lda txmw,y
        jsr $ffa8               // CIOUT
        dey
        bpl db_mw_cmd

        ldy #$20                // 32 bytes
db_ptr: lda $ffff               // self-modified
        jsr $ffa8
        inc mwrt
        inc db_ptr+1
        bne !+
        inc db_ptr+2
!:      dey
        bne db_ptr
        jsr $ffae               // UNLSN
        dex
        bne db_mw_loop

        // M-E $0300
        jsr listen
        ldy #$04
db_me:  lda mex,y
        jsr $ffa8
        dey
        bpl db_me
        jsr $ffae               // UNLSN
        sei
        lda #$23
        sta $dd00

        bit $dd00
        bvs *-3

        // Fast-send all drive code pages
        ldy #0
        sty $fd
        lda #<save
        sta $fb
        lda #>save
        sta $fc

db_send:
        lda ($fb),y
        jsr senddriv_raw
        iny
        bne db_send
        inc $fc
        inc $fd
        lda $fd
        cmp #DRV_PAGES
        bne db_send

        cli
        rts

listen:
        lda #$00
        sta $90
        lda $ba
        jsr $ffb1               // LISTEN
        lda #$6f
        jsr $ff93               // SECOND
        lda $90
        bmi no_drive
        clc
        rts
no_drive:
        sec
        rts

txmw:
        .byte $20
        .byte 3
mwrt:   .byte 0
        .byte $57, $2D, $4D

mex:
        .byte 3
        .byte 0
        .byte $45, $2D, $4D


// ========================================================================
// DECIMAL PRINT ROUTINES
// ========================================================================

pj_val_hi:  .byte 0
pj_val_lo:  .byte 0
pj_row:     .byte 0
pj_col:     .byte 0

print_timer_at:
        ldx pj_row
        lda row_tab_lo,x
        clc
        adc pj_col
        sta scr_lo
        lda row_tab_hi,x
        adc #0
        sta scr_hi

        lda pj_val_hi
        sta pj_tmp+1
        lda pj_val_lo
        sta pj_tmp

        lda #0
        sta pj_off
        sta pj_lead

        jsr print_u16_decimal

        lda #$20
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        ldx #0
pj_str: lda str_unit,x
        beq pj_str_done
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        inx
        bne pj_str
pj_str_done:
        rts

// ----------------------------------------
// print_u16_decimal: print 16-bit value at scr_lo/hi
// ----------------------------------------
print_u16_decimal:
        ldx #0
pj_10k: lda pj_tmp
        sec
        sbc #<10000
        tay
        lda pj_tmp+1
        sbc #>10000
        bcc pj_10k_d
        sta pj_tmp+1
        sty pj_tmp
        inx
        bne pj_10k
pj_10k_d: txa
        jsr pj_digit

        ldx #0
pj_1k:  lda pj_tmp
        sec
        sbc #<1000
        tay
        lda pj_tmp+1
        sbc #>1000
        bcc pj_1k_d
        sta pj_tmp+1
        sty pj_tmp
        inx
        bne pj_1k
pj_1k_d: txa
        jsr pj_digit

        ldx #0
pj_100: lda pj_tmp
        sec
        sbc #100
        tay
        lda pj_tmp+1
        sbc #0
        bcc pj_100_d
        sta pj_tmp+1
        sty pj_tmp
        inx
        bne pj_100
pj_100_d: txa
        jsr pj_digit

        ldx #0
pj_10:  lda pj_tmp
        sec
        sbc #10
        bcc pj_10_d
        sta pj_tmp
        inx
        bne pj_10
pj_10_d: txa
        jsr pj_digit

        lda pj_tmp
        clc
        adc #$30
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        rts

pj_digit:
        tax
        ora pj_lead
        beq pj_skip
        lda #1
        sta pj_lead
        txa
        clc
        adc #$30
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        rts
pj_skip:
        lda #$20
        ldy pj_off
        sta (scr_lo),y
        inc pj_off
        rts

pj_tmp:  .byte 0, 0
pj_off:  .byte 0
pj_lead: .byte 0

str_unit: .text "JIFFIES"
          .byte 0


// ========================================================================
// SCREEN HELPERS
// ========================================================================

clear_screen:
        ldx #0
        lda #$20
cs_l:   sta SCREEN,x
        sta SCREEN+$100,x
        sta SCREEN+$200,x
        sta SCREEN+$2e8,x
        inx
        bne cs_l
        rts

set_all_colors:
        ldx #0
        lda #$01                // white
sc_l:   sta COLORRAM,x
        sta COLORRAM+$100,x
        sta COLORRAM+$200,x
        sta COLORRAM+$2e8,x
        inx
        bne sc_l
        rts

print_at_row:
        sta str_lo
        sty str_hi
        lda row_tab_lo,x
        sta scr_lo
        lda row_tab_hi,x
        sta scr_hi
        ldy #0
pr_l:   lda (str_lo),y
        beq pr_done
        sta (scr_lo),y
        iny
        cpy #40
        bne pr_l
pr_done: rts

print_at_row_inv:
        sta str_lo
        sty str_hi
        lda row_tab_lo,x
        sta scr_lo
        lda row_tab_hi,x
        sta scr_hi
        ldy #0
pri_l:  lda (str_lo),y
        beq pri_done
        ora #$80
        sta (scr_lo),y
        iny
        cpy #40
        bne pri_l
pri_done: rts

wait_key:
        lda #$00
        sta $dc00
wk_w:   lda $dc01
        cmp #$ff
        beq wk_w
wk_r:   lda $dc01
        cmp #$ff
        bne wk_r
        rts

// ---- Go to page (page_num) - recalculate pointers ----
sv_goto_page:
        // Calculate page_num * 22 using addition loop
        lda #0
        sta $fc                 // result lo
        sta $fd                 // result hi
        ldx page_num
        beq sv_gp_done
sv_gp_add:
        lda $fc
        clc
        adc #22
        sta $fc
        bcc sv_gp_noinc
        inc $fd
sv_gp_noinc:
        dex
        bne sv_gp_add
sv_gp_done:
        // cur_n = page_num * 22 + 1
        lda $fc
        clc
        adc #1
        sta cur_n_lo
        lda $fd
        adc #0
        sta cur_n_hi

        // Check mode for buffer pointer setup
        lda run_mode
        bne sv_gp_solo

        // Parallel: offset = page_num * 11 = (page_num * 22) / 2
        lda $fd
        lsr
        sta $fd
        lda $fc
        ror
        sta $fc
        // sv_odd = C64_BUF + offset
        clc
        adc #<C64_BUF
        sta sv_odd_lo
        lda $fd
        adc #>C64_BUF
        sta sv_odd_hi
        // sv_even = DRV_BUF + offset
        lda $fc
        clc
        adc #<DRV_BUF
        sta sv_even_lo
        lda $fd
        adc #>DRV_BUF
        sta sv_even_hi
        rts

sv_gp_solo:
        // Solo: offset = page_num * 22 (contiguous)
        // sv_odd = C64_BUF + (page_num * 22)
        lda $fc
        clc
        adc #<C64_BUF
        sta sv_odd_lo
        lda $fd
        adc #>C64_BUF
        sta sv_odd_hi
        rts

delay_frames:
        jsr wait_vblank
        dex
        bne delay_frames
        rts

wait_vblank:
        lda #$80
wv_w:   bit $d011
        bpl wv_w
wv_w2:  bit $d011
        bmi wv_w2
        rts


// ========================================================================
// ROW ADDRESS TABLES
// ========================================================================
row_tab_lo:
        .fill 25, <(SCREEN + i * 40)
row_tab_hi:
        .fill 25, >(SCREEN + i * 40)


// ========================================================================
// SEQUENCE VIEWER VARIABLES
// ========================================================================

sv_odd_lo:      .byte 0
sv_odd_hi:      .byte 0
sv_even_lo:     .byte 0
sv_even_hi:     .byte 0


// ========================================================================
// VARIABLES (non-ZP)
// ========================================================================

drv_recv_lo:    .byte 0
drv_recv_mid:   .byte 0
drv_recv_hi:    .byte 0


// ========================================================================
// STRING DATA
// ========================================================================

str_title:
        .text "PARALLEL COLLATZ"
        .byte 0

str_subtitle:
        .text "C64 + 1541 PARALLEL COMPUTING"
        .byte 0

str_explain1:
        .text "BOTH C64 AND 1541 HAVE A 6502 CPU"
        .byte 0

str_explain2:
        .text "WORKLOAD SPLIT:"
        .byte 0

str_explain3:
        .text " CPU: ODDS  1,3,5,...,2999"
        .byte 0

str_explain4:
        .text " DRV: EVENS 2,4,6,...,3000"
        .byte 0

str_init_drive:
        .text "UPLOADING CODE TO 1541..."
        .byte 0

str_rb_ready:
        .text "DRIVE READY. RAMBOARD DETECTED."
        .byte 0

str_no_ramboard:
        .text "ERROR: RAMBOARD NOT FOUND!"
        .byte 0

str_no_drive:
        .text "ERROR: DRIVE NOT FOUND - HALTED"
        .byte 0

str_press_start:
        .text "SELECT MODE:"
        .byte 0

str_mode_par:
        .text "1 = PARALLEL (C64 + 1541)"
        .byte 0

str_mode_solo:
        .text "2 = SOLO (C64 ONLY)"
        .byte 0

str_press_go:
        .text "PRESS KEY TO START..."
        .byte 0

str_computing_hdr:
        .text "PARALLEL COLLATZ N=1..3000"
        .byte 0

str_range_cpu:
        .text "CPU: ODDS  1,3,5,...,2999"
        .byte 0

str_range_drv:
        .text "DRV: EVENS 2,4,6,...,3000"
        .byte 0

str_status_run:
        .text "BOTH CPUS RUNNING..."
        .byte 0

str_solo_hdr:
        .text "SOLO COLLATZ N=1..3000"
        .byte 0

str_solo_range:
        .text "CPU: ALL N=1,2,3,...,3000"
        .byte 0

str_solo_status:
        .text "CPU RUNNING..."
        .byte 0

str_c64_done:
        .text "CPUS DONE."
        .byte 0

str_receiving:
        .text "RECEIVING 1500 RESULTS FROM DRIVE..."
        .byte 0

str_all_done:
        .text "ALL 3000 NUMBERS COMPLETE!"
        .byte 0

str_press_view:
        .text "PRESS KEY TO VIEW RESULTS..."
        .byte 0

// --- Sequence viewer ---
str_seq_hdr:
        .text "PARALLEL COLLATZ N=1..3000"
        .byte 0

str_seq_hdr_solo:
        .text "SOLO COLLATZ N=1..3000"
        .byte 0

str_rh_prefix:
        .text "HARDEST: N="
        .byte 0

str_rh_suffix:
        .text " STEPS="
        .byte 0

str_page_prefix:
        .text "PAGE "
        .byte 0

str_page_suffix:
        .text "  KEY:NEXT Q:EXIT"
        .byte 0


// ========================================================================
// DRIVE CODE
// ========================================================================
// Protocol:
//   'D' = RAMBOard detection (replies $01 or $00)
//   'C' = Compute Collatz + buffer + send results
//   'Q' = Quit (reset drive)
// ========================================================================

save:
.pseudopc $0300 {

// ----------------------------------------
// Drive bootstrap receiver
// ----------------------------------------
drv_starter:
        sei
        lda #$7a
        sta $1802               // VIA port B direction
        jsr drv_setline
        jsr $f5e9               // drive ROM delay
        ldx #DRV_PAGES
drv_getpages:
        jsr drv_readblok
        inc drv_addr
        dex
        bne drv_getpages
        jmp drv_main

// ----------------------------------------
// Receive block of 256 bytes from C64
// ----------------------------------------
drv_readone:
        ldy #$ff
        .byte $2c               // BIT abs - skip next
drv_readblok:
        ldy #$00
drv_readbt:
        lda #$00
        sta $1800
drv_wtr1:
        lda $1800
        bne *-3
        php
        lda $1800
        asl
        plp
        eor $1800
        asl
        asl
        asl
        nop
        nop
        nop
        eor $1800
        asl
        nop
        nop
        nop
        eor $1800
.label drv_addr = *+2
        sta $0300,y
        sta drv_lastget
        iny
        bne drv_wtr1
drv_setline:
        lda #$08
        sta $1800
.label drv_lastget = *+1
        lda #$00
        rts

// ----------------------------------------
// Send one byte to C64
// ----------------------------------------
drv_sendone:
        tay
        and #$0f
        tax
        tya
        lsr
        lsr
        lsr
        lsr
        tay
        sei
        lda #$00
        sta $1800
        lda drv_bin2ser,x
        ldx $1800
        bne *-3
        sta $1800
        asl
        and #$0a
        sta $1800
        lda drv_bin2ser,y
        sta $1800
        asl
        and #$0a
        sta $1800
        jmp drv_setline

drv_bin2ser:
        .byte $0f,$07,$0d,$05,$0b,$03
        .byte $09,$01
        .byte $0e,$06,$0c,$04,$0a,$02
        .byte $08,$00

// ----------------------------------------
// Drive main command loop
// ----------------------------------------
drv_main:
        jsr drv_readone
        lda drv_lastget

        cmp #'D'
        beq drv_detect_rb

        cmp #'C'
        beq drv_do_collatz

        cmp #'Q'
        beq drv_quit

        jmp drv_main

// ----------------------------------------
// RAMBOard detection (command 'D')
// ----------------------------------------
drv_detect_rb:
        lda #$55
        sta $8000
        lda $8000
        cmp #$55
        bne drv_no_rb
        lda #$aa
        sta $8000
        lda $8000
        cmp #$aa
        bne drv_no_rb
        lda #$01
        jmp drv_rb_send
drv_no_rb:
        lda #$00
drv_rb_send:
        jsr drv_sendone
        jmp drv_main

drv_quit:
        jmp ($fffc)

// ----------------------------------------
// Drive Collatz computation (RAMBOard enhanced)
// ----------------------------------------
drv_do_collatz:
        jsr drv_readone
        lda drv_lastget
        sta drv_start_lo

        jsr drv_readone
        lda drv_lastget
        sta drv_start_hi

        jsr drv_readone
        lda drv_lastget
        sta drv_count_lo

        jsr drv_readone
        lda drv_lastget
        sta drv_count_hi

        jsr drv_readone
        lda drv_lastget
        sta drv_step

        // Init current number
        lda drv_start_lo
        sta drv_cur_lo
        lda drv_start_hi
        sta drv_cur_hi

        // Init total
        lda #0
        sta drv_total_lo
        sta drv_total_mid
        sta drv_total_hi

        // Init iteration counter
        lda drv_count_lo
        sta drv_iter_lo
        lda drv_count_hi
        sta drv_iter_hi

        // Init RAMBOard buffer pointer
        lda #<$8000
        sta drv_buf_st+1
        lda #>$8000
        sta drv_buf_st+2

drv_outer:
        // Blink LED every 64 numbers
        lda drv_iter_lo
        and #$3f
        bne drv_no_blink
        lda $1c00
        eor #$08
        sta $1c00
drv_no_blink:

        lda drv_cur_lo
        sta drv_n_lo
        lda drv_cur_hi
        sta drv_n_mid
        lda #0
        sta drv_n_hi
        sta drv_steps

        jsr drv_collatz

        // Buffer step count to RAMBOard RAM
        lda drv_steps
drv_buf_st:
        sta $8000               // self-modified address
        inc drv_buf_st+1
        bne drv_buf_noinc
        inc drv_buf_st+2
drv_buf_noinc:

        // Accumulate total (24-bit)
        lda drv_steps
        clc
        adc drv_total_lo
        sta drv_total_lo
        bcc drv_acc_ok
        inc drv_total_mid
        bne drv_acc_ok
        inc drv_total_hi
drv_acc_ok:

        // Advance by step
        lda drv_cur_lo
        clc
        adc drv_step
        sta drv_cur_lo
        bcc drv_next
        inc drv_cur_hi
drv_next:

        // Decrement counter
        lda drv_iter_lo
        bne !+
        dec drv_iter_hi
!:      dec drv_iter_lo
        lda drv_iter_lo
        ora drv_iter_hi
        bne drv_outer

        // ---- Send 3-byte total ----
        lda drv_total_lo
        jsr drv_sendone
        lda drv_total_mid
        jsr drv_sendone
        lda drv_total_hi
        jsr drv_sendone

        // ---- Bulk-send 1500 step-count bytes from RAMBOard ----
        lda #>$8000
        sta drv_bs_hi
        lda #<COUNT
        sta drv_bs_cnt
        lda #>COUNT
        sta drv_bs_cnt+1
        ldy #0

drv_bs_loop:
.label drv_bs_hi = *+2
        lda $8000,y
        sty drv_bs_tmp          // save Y (drv_sendone clobbers it)
        jsr drv_sendone
        ldy drv_bs_tmp          // restore Y
        iny
        bne drv_bs_noinc
        inc drv_bs_hi
drv_bs_noinc:
        lda drv_bs_cnt
        bne drv_bs_dec
        dec drv_bs_cnt+1
drv_bs_dec:
        dec drv_bs_cnt
        lda drv_bs_cnt
        ora drv_bs_cnt+1
        bne drv_bs_loop

        jmp drv_main

// ----------------------------------------
// Drive Collatz inner loop (24-bit)
// ----------------------------------------
drv_collatz:
drv_cl:
        lda drv_n_lo
        cmp #1
        bne drv_not1
        lda drv_n_mid
        ora drv_n_hi
        beq drv_done
drv_not1:

        lda drv_n_lo
        and #1
        bne drv_odd

drv_even:
        lsr drv_n_hi
        ror drv_n_mid
        ror drv_n_lo
        jmp drv_cstep

drv_odd:
        lda drv_n_lo
        sta drv_t_lo
        lda drv_n_mid
        sta drv_t_mid
        lda drv_n_hi
        sta drv_t_hi
        asl drv_n_lo
        rol drv_n_mid
        rol drv_n_hi
        lda drv_n_lo
        clc
        adc drv_t_lo
        sta drv_n_lo
        lda drv_n_mid
        adc drv_t_mid
        sta drv_n_mid
        lda drv_n_hi
        adc drv_t_hi
        sta drv_n_hi
        inc drv_n_lo
        bne drv_cstep
        inc drv_n_mid
        bne drv_cstep
        inc drv_n_hi

drv_cstep:
        inc drv_steps
        jmp drv_cl

drv_done:
        rts

// ----------------------------------------
// Drive variables
// ----------------------------------------
drv_start_lo:   .byte 0
drv_start_hi:   .byte 0
drv_count_lo:   .byte 0
drv_count_hi:   .byte 0
drv_step:       .byte 0

drv_cur_lo:     .byte 0
drv_cur_hi:     .byte 0

drv_iter_lo:    .byte 0
drv_iter_hi:    .byte 0

drv_n_lo:       .byte 0
drv_n_mid:      .byte 0
drv_n_hi:       .byte 0

drv_t_lo:       .byte 0
drv_t_mid:      .byte 0
drv_t_hi:       .byte 0

drv_steps:      .byte 0

drv_total_lo:   .byte 0
drv_total_mid:  .byte 0
drv_total_hi:   .byte 0

drv_bs_cnt:     .byte 0, 0
drv_bs_tmp:     .byte 0

// ----------------------------------------
// Pad to exactly 3 pages ($0300-$05FF)
// ----------------------------------------
.print "Drive code ends at: " + toHexString(*)
.print "Drive code size: " + (* - $0300) + " bytes"
.print "Drive code free: " + ($0600 - *) + " bytes"

.if (* > $0600) {
    .error "Drive code exceeds 3 pages! Size: " + (* - $0300) + " bytes"
}

.fill $0600 - *, 0

}   // end .pseudopc $0300
