.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

H_STDOUT            equ -11
H_STDIN             equ -10
CP_OUT              equ 65001

MAX_HP              equ 100
TRAP_DMG            equ 30
MAX_LINE            equ 256

ITEM_MATCHES        equ 01h
ITEM_CANDLE         equ 02h
ITEM_COMPASS        equ 04h
ITEM_SEAL           equ 08h
ITEM_NOTE           equ 10h
ITEM_PASSWORD       equ 20h
ALL_KEYS            equ ITEM_CANDLE or ITEM_COMPASS or ITEM_SEAL

COLOR_DEFAULT       equ 07h
COLOR_RED           equ 0Ch
COLOR_GREEN         equ 0Ah
COLOR_YELLOW        equ 0Eh
COLOR_CYAN          equ 0Bh

TRANS_NONE          equ -1
TRANS_PUZZLE        equ 1000
TRANS_END_GOOD      equ 1001
TRANS_END_NEUTRAL   equ 1002
TRANS_END_BAD       equ 1003

LOC_MIRROR          equ 7
LOC_BASEMENT        equ 6
LOC_BLACK           equ 8
LOC_FINAL           equ 9

HP_GOOD_THRESHOLD   equ 70
TURNS_GOOD_LIMIT    equ 40

TLoc STRUCT
    desc_ptr  DWORD ?
    c1        DWORD ?
    c2        DWORD ?
    c3        DWORD ?
    c4        DWORD ?
    c5        DWORD ?
    t1        DWORD ?
    t2        DWORD ?
    t3        DWORD ?
    t4        DWORD ?
    t5        DWORD ?
    item      DWORD ?
    req_mask  DWORD ?
    on_enter  DWORD ?
TLoc ENDS

set_color           PROTO :DWORD
print_string        PROTO :DWORD
print_int           PROTO :DWORD
print_inventory     PROTO
read_input          PROTO
parse_int           PROTO
check_inventory     PROTO :DWORD
add_item            PROTO :DWORD, :DWORD
try_pickup          PROTO
show_location       PROTO
show_choices        PROTO
emit_choice         PROTO :DWORD
read_choice         PROTO
process_choice      PROTO :DWORD
do_archive_puzzle   PROTO
ending_read_book    PROTO
ending_escape       PROTO
ending_forget       PROTO
apply_enter_effects PROTO
game_loop           PROTO

.data
hOut       HANDLE 0
hIn        HANDLE 0
cur_loc    DWORD  0
inv        DWORD  0
hp         DWORD  MAX_HP
turns      DWORD  0
done       DWORD  0
nread      DWORD  0
choice_num DWORD  1
buf        BYTE   MAX_LINE dup(0)
pwd_ref    BYTE   "SVET",0

s_title   BYTE 13,10,"=== Just Quest ===",13,10,0
s_byline  BYTE "By the greast gasby (aka p1zdabolw)",13,10,13,10,0
s_start   BYTE "You come to your senses in an abandoned library.",13,10
          BYTE "In your hands is a yellowed note:",13,10
          BYTE "The one who reads the last book will remain in it forever.",13,10,0
s_press   BYTE 13,10,"Press ENTER to begin...",13,10,0
s_hp      BYTE 13,10,"HP: ",0
s_inv     BYTE "  Items: ",0
s_none    BYTE "(none)",0
s_sep     BYTE ", ",0
s_prompt  BYTE 13,10,"Your choice: ",0
s_invalid BYTE 13,10,"Invalid choice.",13,10,0
s_blocked BYTE 13,10,"The path is blocked. Something important is missing.",13,10,0
s_dmg     BYTE 13,10,"You lose ",0
s_dmg2    BYTE " HP!",13,10,0
s_dead    BYTE 13,10,"=== YOU DIED ===",13,10
          BYTE "The darkness of the library has swallowed you forever.",13,10,0
s_good    BYTE 13,10,"=== GOOD ENDING ===",13,10
          BYTE "You leave the library. It is morning. You are free.",13,10,0
s_neutral BYTE 13,10,"=== NEUTRAL ENDING ===",13,10
          BYTE "The doors open, but you no longer remember who you are.",13,10,0
s_bad     BYTE 13,10,"=== BAD ENDING ===",13,10
          BYTE "You remain in the book forever...",13,10,0
s_puz_intro BYTE 13,10,"Riddle: When darkness thickens, seek the light.",13,10
            BYTE "Enter the password (4 Latin letters): ",0
s_puz_ok    BYTE 13,10,"The lock clicks. You receive the Compass.",13,10,0
s_puz_fail  BYTE 13,10,"The password is incorrect.",13,10,0
s_got_item  BYTE 13,10,"Obtained: ",0
s_cant_take BYTE 13,10,"You cannot take this yet.",13,10,0
s_already   BYTE 13,10,"(already taken)",13,10,0
s_nl        BYTE 13,10,0
s_dot       BYTE ". ",0

i_matches BYTE "Matches",0
i_candle  BYTE "Candle",0
i_compass BYTE "Compass",0
i_seal    BYTE "Seal",0
i_note    BYTE "Note",0

d0 BYTE "Main hall of the library. Tall shelves disappear into the darkness.",13,10
   BYTE "It smells of dust and old wax. The outer doors are locked from the inside.",13,10,0
d1 BYTE "Reading room. On the table is a candlestick with a candle.",13,10
   BYTE "On the wall is a faded painting depicting a flame.",13,10,0
d2 BYTE "Kitchen. A cold stove, a shelf with vials.",13,10
   BYTE "On the table lie a box of matches and a note.",13,10,0
d3 BYTE "Archive. Endless card catalogs. In the center is a lectern with a cipher.",13,10,0
d4 BYTE "Spiral staircase to the second floor.",13,10
   BYTE "Cold air drifts from above. Below is a heavy door to the basement.",13,10,0
d5 BYTE "Caretaker's office. A desk, a locked drawer, on the table is an imprint of the Seal.",13,10,0
d6 BYTE "Basement. It smells of earth and old paper.",13,10
   BYTE "On the lectern lies a book in a black binding.",13,10,0
d7 BYTE "Dead end. On the wall is an old mirror. From the mirror someone very similar",13,10
   BYTE "to you looks at you... but not you.",13,10,0
d8 BYTE "Back entrance. A narrow corridor leading deep into the walls.",13,10,0
d9 BYTE "Final room. The book is open. Everything around is frozen.",13,10,0

ch_reading BYTE "Go to the reading room",0
ch_kitchen BYTE "Go to the kitchen",0
ch_archive BYTE "Go down to the archive",0
ch_stairs  BYTE "Go up the stairs",0
ch_black   BYTE "Examine the shelves by the east wall",0
ch_back    BYTE "Return to the main hall",0
ch_back_st BYTE "Return to the stairs",0
ch_puzzle  BYTE "Try to solve the cipher",0
ch_office  BYTE "Enter the caretaker's office",0
ch_basem   BYTE "Go down to the basement",0
ch_mirror  BYTE "Enter the dead end with the mirror",0
ch_final   BYTE "Enter the final room",0
ch_rdbook  BYTE "Read the book to the end",0
ch_escape  BYTE "Step into the light",0
ch_forget  BYTE "Close the book and leave",0

loc_table TLoc <offset d0, offset ch_reading, offset ch_kitchen, offset ch_archive, offset ch_stairs, 0,            1, 2, 3, 4, TRANS_NONE, 0, 0, 0>
          TLoc <offset d1, offset ch_back,    0,              0,              0,              0,            0, TRANS_NONE, TRANS_NONE, TRANS_NONE, TRANS_NONE, ITEM_CANDLE, ITEM_MATCHES, 0>
          TLoc <offset d2, offset ch_back,    0,              0,              0,              0,            0, TRANS_NONE, TRANS_NONE, TRANS_NONE, TRANS_NONE, ITEM_MATCHES or ITEM_NOTE, 0, 0>
          TLoc <offset d3, offset ch_back,    offset ch_puzzle, 0,            0,              0,            0, TRANS_PUZZLE, TRANS_NONE, TRANS_NONE, TRANS_NONE, 0, 0, 0>
          TLoc <offset d4, offset ch_back,    offset ch_office, offset ch_basem, offset ch_mirror, offset ch_black, 0, 5, 6, 7, 8, 0, 0, 0>
          TLoc <offset d5, offset ch_back_st, 0,              0,              0,              0,            4, TRANS_NONE, TRANS_NONE, TRANS_NONE, TRANS_NONE, ITEM_SEAL, ITEM_PASSWORD, 0>
          TLoc <offset d6, offset ch_back_st, offset ch_final, 0,             0,              0,            4, 9, TRANS_NONE, TRANS_NONE, TRANS_NONE, 0, 0, 0>
          TLoc <offset d7, offset ch_back_st, 0,              0,              0,              0,            4, TRANS_NONE, TRANS_NONE, TRANS_NONE, TRANS_NONE, 0, 0, 1>
          TLoc <offset d8, offset ch_back_st, offset ch_final, 0,             0,              0,            4, 9, TRANS_NONE, TRANS_NONE, TRANS_NONE, 0, 0, 0>
          TLoc <offset d9, offset ch_rdbook,  offset ch_escape, offset ch_forget, 0,            0,            TRANS_END_GOOD, TRANS_END_NEUTRAL, TRANS_END_BAD, TRANS_NONE, TRANS_NONE, 0, 0, 0>

.code

;--------------------------------------------------------------
set_color proc attr:DWORD
    invoke SetConsoleTextAttribute, hOut, attr
    ret
set_color endp

;--------------------------------------------------------------
print_string proc pStr:DWORD
    push esi
    mov esi, pStr
    test esi, esi
    jz ps_out
    xor eax, eax
ps_len:
    cmp byte ptr [esi+eax], 0
    je ps_do
    inc eax
    jmp ps_len
ps_do:
    test eax, eax
    jz ps_out
    invoke WriteConsoleA, hOut, esi, eax, offset nread, 0
ps_out:
    pop esi
    ret
print_string endp

;--------------------------------------------------------------
print_int proc n:DWORD
    local tb[16]:BYTE
    push esi
    lea esi, tb
    add esi, 15
    mov byte ptr [esi], 0
    mov eax, n
    mov ecx, 10
    test eax, eax
    jnz pi_loop
    dec esi
    mov byte ptr [esi], '0'
    jmp pi_print
pi_loop:
    test eax, eax
    jz pi_print
    xor edx, edx
    div ecx
    add dl, '0'
    dec esi
    mov [esi], dl
    jmp pi_loop
pi_print:
    invoke print_string, esi
    pop esi
    ret
print_int endp

;--------------------------------------------------------------
read_input proc
    invoke ReadConsoleA, hIn, offset buf, MAX_LINE-1, offset nread, 0
    mov ecx, nread
    test ecx, ecx
    jz ri_term
ri_trim:
    mov al, buf[ecx-1]
    cmp al, 13
    je ri_cut
    cmp al, 10
    je ri_cut
    jmp ri_term
ri_cut:
    dec ecx
    jnz ri_trim
ri_term:
    mov byte ptr buf[ecx], 0
    ret
read_input endp

;--------------------------------------------------------------
parse_int proc
    lea esi, buf
    xor eax, eax
pi_skip:
    mov cl, [esi]
    cmp cl, ' '
    jne pi_go
    inc esi
    jmp pi_skip
pi_go:
    mov cl, [esi]
    cmp cl, '0'
    jb pi_end
    cmp cl, '9'
    ja pi_end
    imul eax, eax, 10
    sub cl, '0'
    movzx ecx, cl
    add eax, ecx
    inc esi
    jmp pi_go
pi_end:
    ret
parse_int endp

;--------------------------------------------------------------
check_inventory proc itm:DWORD
    mov eax, inv
    and eax, itm
    ret
check_inventory endp

;--------------------------------------------------------------
add_item proc itm:DWORD, name_ptr:DWORD
    mov eax, itm
    test inv, eax
    jnz ai_done
    or inv, eax
    invoke set_color, COLOR_GREEN
    invoke print_string, offset s_got_item
    invoke print_string, name_ptr
    invoke print_string, offset s_nl
    invoke set_color, COLOR_DEFAULT
ai_done:
    ret
add_item endp

;--------------------------------------------------------------
print_inventory proc
    invoke set_color, COLOR_CYAN
    invoke print_string, offset s_inv
    mov eax, inv
    test eax, eax
    jnz pi_has
    invoke print_string, offset s_none
    jmp pi_end
pi_has:
    xor ebx, ebx
    test eax, ITEM_MATCHES
    jz @1
    invoke print_string, offset i_matches
    inc ebx
@1: test eax, ITEM_CANDLE
    jz @2
    test ebx, ebx
    jz @1b
    invoke print_string, offset s_sep
@1b:
    invoke print_string, offset i_candle
    inc ebx
@2: test eax, ITEM_COMPASS
    jz @3
    test ebx, ebx
    jz @2b
    invoke print_string, offset s_sep
@2b:
    invoke print_string, offset i_compass
    inc ebx
@3: test eax, ITEM_SEAL
    jz @4
    test ebx, ebx
    jz @3b
    invoke print_string, offset s_sep
@3b:
    invoke print_string, offset i_seal
    inc ebx
@4: test eax, ITEM_NOTE
    jz pi_end
    test ebx, ebx
    jz @4b
    invoke print_string, offset s_sep
@4b:
    invoke print_string, offset i_note
pi_end:
    invoke set_color, COLOR_DEFAULT
    ret
print_inventory endp

;--------------------------------------------------------------
print_status proc
    invoke set_color, COLOR_YELLOW
    invoke print_string, offset s_hp
    invoke print_int, hp
    invoke print_inventory
    invoke print_string, offset s_nl
    invoke set_color, COLOR_DEFAULT
    ret
print_status endp

;--------------------------------------------------------------
try_pickup proc
    mov eax, cur_loc
    imul eax, eax, SIZEOF TLoc
    lea esi, loc_table
    add esi, eax
    assume esi:ptr TLoc
    mov eax, [esi].item
    mov ecx, [esi].req_mask
    assume esi:nothing
    test eax, eax
    jz tp_done
    mov ebx, inv
    and ebx, eax
    jnz tp_done
    test ecx, ecx
    jz tp_give
    mov edx, inv
    and edx, ecx
    cmp edx, ecx
    jne tp_blocked
tp_give:
    mov ebx, eax
    test ebx, ITEM_MATCHES
    jz @m1
    invoke add_item, ITEM_MATCHES, offset i_matches
@m1:test ebx, ITEM_CANDLE
    jz @m2
    invoke add_item, ITEM_CANDLE, offset i_candle
@m2:test ebx, ITEM_COMPASS
    jz @m3
    invoke add_item, ITEM_COMPASS, offset i_compass
@m3:test ebx, ITEM_SEAL
    jz @m4
    invoke add_item, ITEM_SEAL, offset i_seal
@m4:test ebx, ITEM_NOTE
    jz tp_done
    invoke add_item, ITEM_NOTE, offset i_note
tp_done:
    ret
tp_blocked:
    invoke set_color, COLOR_RED
    invoke print_string, offset s_cant_take
    invoke set_color, COLOR_DEFAULT
    ret
try_pickup endp

;--------------------------------------------------------------
show_location proc
    mov eax, cur_loc
    imul eax, eax, SIZEOF TLoc
    lea esi, loc_table
    add esi, eax
    assume esi:ptr TLoc
    invoke print_string, [esi].desc_ptr
    assume esi:nothing
    ret
show_location endp

;--------------------------------------------------------------
emit_choice proc pText:DWORD
    cmp pText, 0
    je ec_ret
    invoke print_int, choice_num
    invoke print_string, offset s_dot
    invoke print_string, pText
    invoke print_string, offset s_nl
    inc choice_num
ec_ret:
    ret
emit_choice endp

;--------------------------------------------------------------
show_choices proc
    mov choice_num, 1
    mov eax, cur_loc
    imul eax, eax, SIZEOF TLoc
    lea esi, loc_table
    add esi, eax
    assume esi:ptr TLoc
    invoke emit_choice, [esi].c1
    invoke emit_choice, [esi].c2
    invoke emit_choice, [esi].c3
    invoke emit_choice, [esi].c4
    mov edx, [esi].t5
    cmp edx, TRANS_NONE
    je sc_done
    cmp edx, LOC_BLACK
    jne sc_show5
    test inv, ITEM_NOTE
    jz sc_done
sc_show5:
    invoke emit_choice, [esi].c5
sc_done:
    assume esi:nothing
    ret
show_choices endp

;--------------------------------------------------------------
read_choice proc
    invoke print_string, offset s_prompt
    invoke read_input
    invoke parse_int
    ret
read_choice endp

;--------------------------------------------------------------
do_archive_puzzle proc
    invoke check_inventory, ITEM_COMPASS
    test eax, eax
    jz @nocompass
    invoke print_string, offset s_already
    ret
@nocompass:
    invoke set_color, COLOR_YELLOW
    invoke print_string, offset s_puz_intro
    invoke set_color, COLOR_DEFAULT
    invoke read_input
    lea esi, buf
    lea edi, pwd_ref
    mov ecx, 4
    cld
    repe cmpsb
    jne @fail
    cmp byte ptr [buf+4], 0
    jne @fail
    invoke set_color, COLOR_GREEN
    invoke print_string, offset s_puz_ok
    invoke set_color, COLOR_DEFAULT
    or inv, ITEM_COMPASS or ITEM_PASSWORD
    ret
@fail:
    invoke set_color, COLOR_RED
    invoke print_string, offset s_puz_fail
    invoke set_color, COLOR_DEFAULT
    ret
do_archive_puzzle endp

;--------------------------------------------------------------
ending_read_book proc
    mov eax, inv
    and eax, ALL_KEYS
    cmp eax, ALL_KEYS
    jne @neutral
    cmp hp, HP_GOOD_THRESHOLD
    jl @neutral
    cmp turns, TURNS_GOOD_LIMIT
    ja @neutral
    invoke set_color, COLOR_GREEN
    invoke print_string, offset s_good
    invoke set_color, COLOR_DEFAULT
    mov done, 1
    ret
@neutral:
    invoke set_color, COLOR_YELLOW
    invoke print_string, offset s_neutral
    invoke set_color, COLOR_DEFAULT
    mov done, 1
    ret
ending_read_book endp

;--------------------------------------------------------------
ending_escape proc
    mov eax, inv
    and eax, ALL_KEYS
    cmp eax, ALL_KEYS
    jne @bad
    invoke set_color, COLOR_GREEN
    invoke print_string, offset s_good
    invoke set_color, COLOR_DEFAULT
    mov done, 1
    ret
@bad:
    invoke set_color, COLOR_RED
    invoke print_string, offset s_bad
    invoke set_color, COLOR_DEFAULT
    mov done, 1
    ret
ending_escape endp

;--------------------------------------------------------------
ending_forget proc
    invoke set_color, COLOR_YELLOW
    invoke print_string, offset s_neutral
    invoke set_color, COLOR_DEFAULT
    mov done, 1
    ret
ending_forget endp

;--------------------------------------------------------------
apply_enter_effects proc
    cmp cur_loc, LOC_MIRROR
    jne ae_done
    invoke set_color, COLOR_RED
    invoke print_string, offset s_dmg
    invoke print_int, TRAP_DMG
    invoke print_string, offset s_dmg2
    invoke set_color, COLOR_DEFAULT
    mov eax, hp
    sub eax, TRAP_DMG
    mov hp, eax
ae_done:
    ret
apply_enter_effects endp

;--------------------------------------------------------------
process_choice proc num:DWORD
    mov ecx, num
    test ecx, ecx
    jz pc_bad
    cmp ecx, 5
    ja pc_bad

    mov eax, cur_loc
    imul eax, eax, SIZEOF TLoc
    lea esi, loc_table
    add esi, eax
    assume esi:ptr TLoc

    cmp ecx, 1
    jne @c2
    mov eax, [esi].t1
    jmp pc_do
@c2:
    cmp ecx, 2
    jne @c3
    mov eax, [esi].t2
    jmp pc_do
@c3:
    cmp ecx, 3
    jne @c4
    mov eax, [esi].t3
    jmp pc_do
@c4:
    cmp ecx, 4
    jne @c5
    mov eax, [esi].t4
    jmp pc_do
@c5:
    mov eax, [esi].t5
pc_do:
    assume esi:nothing
    cmp eax, TRANS_NONE
    je pc_bad

    cmp eax, TRANS_PUZZLE
    jne @p1
    call do_archive_puzzle
    mov eax, 1
    ret
@p1:
    cmp eax, TRANS_END_GOOD
    jne @p2
    call ending_read_book
    mov eax, 1
    ret
@p2:
    cmp eax, TRANS_END_NEUTRAL
    jne @p3
    call ending_forget
    mov eax, 1
    ret
@p3:
    cmp eax, TRANS_END_BAD
    jne @p4
    call ending_escape
    mov eax, 1
    ret
@p4:
    cmp eax, LOC_BASEMENT
    jne @p5
    mov edx, inv
    and edx, ALL_KEYS
    cmp edx, ALL_KEYS
    jne pc_blocked
@p5:
    cmp eax, LOC_BLACK
    jne @p6
    mov edx, inv
    test edx, ITEM_NOTE
    jz pc_blocked
@p6:
    cmp eax, LOC_FINAL
    jne @p7
    mov edx, inv
    and edx, ALL_KEYS
    cmp edx, ALL_KEYS
    jne pc_blocked
@p7:
    mov cur_loc, eax
    call apply_enter_effects
    mov eax, 1
    ret
pc_blocked:
    invoke set_color, COLOR_RED
    invoke print_string, offset s_blocked
    invoke set_color, COLOR_DEFAULT
    xor eax, eax
    ret
pc_bad:
    invoke print_string, offset s_invalid
    xor eax, eax
    ret
process_choice endp

;--------------------------------------------------------------
game_loop proc
gl_top:
    cmp done, 1
    je gl_end
    cmp hp, 0
    jle gl_dead

    inc turns
    call print_status
    call show_location
    call show_choices
    call read_choice
    invoke process_choice, eax
    test eax, eax
    jz gl_top
    cmp hp, 0
    jle gl_dead
    call try_pickup
    jmp gl_top

gl_dead:
    invoke set_color, COLOR_RED
    invoke print_string, offset s_dead
    invoke set_color, COLOR_DEFAULT
gl_end:
    ret
game_loop endp

;--------------------------------------------------------------
mainCRTStartup proc
    invoke GetStdHandle, H_STDOUT
    test eax, eax
    jz m_fail
    mov hOut, eax

    invoke GetStdHandle, H_STDIN
    test eax, eax
    jz m_fail
    mov hIn, eax

    invoke SetConsoleOutputCP, CP_OUT
    invoke SetConsoleCP, CP_OUT

    invoke set_color, COLOR_CYAN
    invoke print_string, offset s_title
    invoke print_string, offset s_byline
    invoke set_color, COLOR_DEFAULT
    invoke print_string, offset s_start
    invoke print_string, offset s_press
    call read_input

    call game_loop

    invoke set_color, COLOR_DEFAULT
    invoke ExitProcess, 0
m_fail:
    invoke ExitProcess, 1
mainCRTStartup endp

end mainCRTStartup
