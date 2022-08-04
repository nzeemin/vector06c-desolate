
; Import declarations from desolcod0.asm
  INCLUDE "desolcod0.inc"

; Turn on/off cheat codes
CHEAT_SHOW_ROOM_NUMBER  EQU 0
CHEAT_ALL_ACCESS        EQU 0
CHEAT_ALL_INVENTORY     EQU 0
CHEAT_HAVE_WEAPON       EQU 0
CHEAT_HEALTH_999        EQU 0

MirrorTab        EQU 0B100h

;----------------------------------------------------------------------------

  ORG $0280
Start:
;  ld sp,$B2E0
  ld sp,MirrorTab
  
  ld de,MirrorTab
GenMirrorTab:
  ld h,e
  add hl,hl
  rra       ; 0
  add hl,hl
  rra       ; 1
  add hl,hl
  rra       ; 2
  add hl,hl
  rra       ; 3
  add hl,hl
  rra       ; 4
  add hl,hl
  rra       ; 5
  add hl,hl
  rra       ; 6
  add hl,hl
  rra       ; 7
  ld (de),a
  inc e
  jp nz,GenMirrorTab
  
;
; Draw DESOLATE title sign on top of the screen
; LDBF5 buffer already pre-filled with 3 lines of the title screen with the big DESOLATE sign
  LD HL,LDBF5
  call LB177              ; Display screen from tiles with Tileset2
  call CopyTitleSign
  call ClearShadowScreen

  call LBA07  ; Show titles and go to Menu

; Cheat code to get all door access codes
  IF CHEAT_ALL_ACCESS = 1
  LD HL,LDCA2
  LD B,$48
start_1:
  LD (HL),$01
  INC HL
  dec b
  jp NZ,start_1
  ENDIF

; Cheat code to have all inventory items
  IF CHEAT_ALL_INVENTORY = 1
  LD HL,LDB9C
  LD B,26
start_2:
  LD (HL),$01
  INC HL
  dec b
  jp NZ,start_2
  ENDIF

; Cheat code to have the weapon
  IF CHEAT_HAVE_WEAPON = 1
  ld a,$01
  ld (LDCF7),a
  ENDIF

  IF CHEAT_HEALTH_999 = 1
  ld hl,999
  ld (LDB7A),hl
  ENDIF

;  call LB0A2  ; Inventory
;  call LBBEC  ; Info menu item, show Controls
;  call LBADE  ; New game
;  call LBB7E  ; Game start
;  call LB9A2  ; Player is dead
;  call LBD85  ; Final
;  call LBF6F  ; The End

;  call ShowShadowScreen
;  di
;  halt

;  call WaitAnyKey
;  call ClearShadowScreen
;  call ShowShadowScreen

  jp Start

;----------------------------------------------------------------------------

DesolateStrsBeg:
  INCLUDE "desolstrs.asm"

DesolateFontBeg:
  INCLUDE "desolfont.asm"

DesolateDataBeg:
  INCLUDE "desoldata.asm"

;----------------------------------------------------------------------------
DesolateCodeBeg:

; Wait for any key
WaitAnyKey:
  call ReadKeyboard
  or a
  jp nz,WaitAnyKey	; Wait for unpress
WaitAnyKey_1:
  call ReadKeyboard
  or a
  jp z,WaitAnyKey_1	; Wait for press
  ret

; Wait until no key pressed - to put after ReadKeyboard calls to prevent double-reads of the same key
WaitKeyUp:
  call ReadKeyboard
  or a
  jp nz,WaitKeyUp	; Wait for unpress
  ret

; Returns: A=key code, $00 no key; Z=0 for key, Z=1 for no key
; Key codes: Down=$01, Left=$02, Right=$03, Up=$04, Look/shoot=$05
;            Inventory=$06, Escape=$07, Switch look/shoot=$08, Enter=$09, Menu=$0F
ReadKeyboard:
  ld hl,ReadKeyboard_map  ; Point HL at the keyboard list
  ld b,6                  ; number of rows to check
ReadKeyboard_0:        
  ld e,(hl)               ; get address low
  inc hl
  ld d,(hl)               ; get address high
  inc hl
  ld a,(de)               ; get bits for keys
  ld c,8                  ; number of keys in a row
ReadKeyboard_1:
  rla                     ; shift A left; bit 0 sets carry bit
  jp nc,ReadKeyboard_2    ; if the bit is 0, we've found our key
  inc hl                  ; next table address
  dec c
  jp nz,ReadKeyboard_1    ; continue the loop by bits
  dec b
  jp nz,ReadKeyboard_0    ; continue the loop by lines
  xor a                   ; clear A, no key found
  ret
ReadKeyboard_2:
  ld a,(hl)               ; We've found a key, fetch the character code
  or a
  ret
; Mapping: Arrows; US/Space - look/shoot, Tab/RusLat - switch look/shoot,
;          AR2/ZB/PS - escape, I/M - inventory; P/R - menu, Enter=Enter
ReadKeyboard_map:
  DW KeyLineEx
  DB $08,$00,$05,$00,$00,$00,$00,$00  ; R/L SS  US
  DW KeyLine0
  DB $01,$03,$04,$02,$07,$09,$07,$08  ; Dn  Rt  Up  Lt  ZB  VK  PS  Tab
  DW KeyLine1
  DB $00,$00,$00,$00,$00,$07,$00,$00  ; F5  F4  F3  F2  F1  AR2 Str  ^\
  DW KeyLine5
  DB $00,$00,$06,$00,$00,$00,$06,$00  ;  O   N   M   L   K   J   I   H
  DW KeyLine6
  DB $00,$00,$00,$00,$00,$0F,$00,$0F  ;  W   V   U   T   S   R   Q   P
  DW KeyLine7
  DB $05,$00,$00,$00,$00,$00,$00,$00  ; Spc  ^   ]   \   [   Z   Y   X

; Get shadow screen address using penCol in L86D7
;   A = row 0..137
;   (L86D7) = penCol 0..191
; Returns HL = address
; Clock timing: (208-228 on v06c)
GetScreenAddr:
  push de
  ld l,a
  ld h,$00      ; now HL = A
  add hl,hl     ; now HL = A * 2
  ld e,l
  ld d,h        ; now DE = A * 2
  add hl,hl     ; now HL = A * 4
  add hl,de     ; now HL = A * 6
  add hl,hl     ; now HL = A * 12
  add hl,hl     ; now HL = A * 24
  ld de,ShadowScreen
  add hl,de
  ld a,(L86D7)  ; get penCol
  rrca
  rrca
  rrca
  and 00011111b
                ; now A = 8px column
  pop de
    add a,l     
    ld l,a      ; now HL = line address + column
  ret nc
  inc h
  ret

; Draw tile with mask 16x16 -> 16x16 on shadow screen - for Tileset2 tiles
;   A = penRow; L86D7 = penCol; HL = tile address
DrawTileMasked:
  ld (SetSP7+1),hl
  ex de,hl      ; now DE = tile address
 	ld hl,0
	add hl,sp
	ld (SetSP8+1),hl
  call GetScreenAddr	; now HL = screen addr
  ld bc,24-1    ; increment to the next line
	di
SetSP7:
	ld sp,0
	
	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	add hl,bc

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a
	inc hl

	pop de
	ld a,(hl)
	and e
	or d
	ld (hl),a

SetSP8:
	ld sp,0
	ei
  ret

; Draw string  on shadow screen using FontProto
;   HL = string addr
DrawString:
  ld a,(hl)
  inc hl
  or a
  ret z
  push hl
  call DrawChar
  pop hl
  jp DrawString

; Draw character on the screen using FontProto
;   A = character to show: $00-$1F space with A width; $20 space
DrawChar:
  push hl
  push bc
  cp $20        ; $00-$1F ?
  jp c,DrawChar_00  ; yes => set char width and process like space char
  jp nz,DrawChar_0  ; not space char => jump
  ld a,$03      ; space char gap size
DrawChar_00:
  ld (DrawChar_width),a
  jp DrawChar_fin
DrawChar_0:
  cp $27        ; char less than apostroph?
  jp nc,DrawChar_1
  add a,$3A     ; for '!', quotes, '#' '$' '%' '&'
  jp DrawChar_2
DrawChar_1:
  cp $2A        ; char less than '*'?
  jp nc,DrawChar_2
  add a,$15     ; for apostroph, '(' ')' chars
DrawChar_2:
  sub $2C       ; font starts from ','
  ld e,a        ; calculating the symbol address
  ld l,a        ;
  ld h,$00      ;
  ld d,h        ;
  add hl,hl     ; now hl = a * 2
  add hl,hl     ; now hl = a * 4
  add hl,de     ; now hl = a * 5
  add hl,hl     ; now hl = a * 10
  add hl,de     ; now hl = a * 11
  ld de,FontProto
  add hl,de     ; now hl = addr of the symbol
  ex de,hl      ; now de=symbol addr
  ld a,(L86D8)  ; get penRow
  ld (DrawChar_row),a
  ld a,(de)     ; get flag/width byte
  inc de
  or a          ; test for bit 7
;  bit 7,a       ; lowered symbol?
  jp p,DrawChar_3  ; not lowered symbol => skip
  ld hl,DrawChar_row
  inc (hl)      ; start on the next line
DrawChar_3:
  and $0f       ; keep width 1..8
  add a,$02     ; gap 2px after the symbol
  ld (DrawChar_width),a
  ld a,(DrawChar_row)
  call GetScreenAddr
  push hl       ; store addr on the screen
  push de       ; store symbol data addr
  ld a,(L86D7)	; get penCol
  and $07       ; shift 0..7
  inc a
  ld c,a
  ld b,10       ; 10 lines
DrawChar_4:     ; loop by lines
  push bc       ; save counter
  ld a,(de)
  inc de
DrawChar_5:     ; loop for shift
  dec c
  jp z, DrawChar_6
  or a
  rra           ; shift right
  jp DrawChar_5
DrawChar_6:
  or (hl)
  ld (hl),a     ; put on the screen
  ld a,(DrawChar_row)
  inc a
  ld (DrawChar_row),a
  call GetScreenAddr
  pop bc        ; restore counter and shift
  dec b
  jp nz,DrawChar_4
  pop de        ; restore symbol data addr
  pop hl        ; restore addr on the screen
  ld a,(L86D7)  ; get penCol
  and $7        ; shift 0..7
  ld b,a
  ld a,(DrawChar_width)
  add a,b
  cp $08        ; shift + width <= 8 ?
  jp c,DrawChar_fin	; yes => no need for 2nd pass
; Second pass
  ld a,(L86D7)  ; get penCol
  and $07       ; shift 1..7
  ld c,a
  ld a,$09
  sub c         ; a = 9 - shift; result is 2..8
  ld c,a
  ld a,(DrawChar_row)
  add a,-10
  ld (DrawChar_row),a
  inc hl
  ld b,10       ; 10 lines
DrawChar_8:     ; loop by lines
  push bc       ; save counter
  ld a,(de)
  inc de
DrawChar_9:     ; loop for shift
  dec c
  jp z, DrawChar_A
  or a
  rla           ; shift left
  jp DrawChar_9
DrawChar_A:
  or (hl)
  ld (hl),a     ; put on the screen
  ld a,(DrawChar_row)
  inc a
  ld (DrawChar_row),a
  call GetScreenAddr
  inc hl
  pop bc        ; restore counter
  dec b
  jp nz,DrawChar_8
; All done, finalizing
DrawChar_fin:
  ld hl,L86D7   ; penCol address
  ld a,(DrawChar_width)
  add a,(hl)
  ld (hl),a     ; updating penCol
  pop bc
  pop hl
  ret
DrawChar_width:   DB 0    ; Saved symbol width
DrawChar_row0:    DB 0    ; Saved first row number
DrawChar_row:     DB 0    ; Saved current row number

; Draw decimal number HL in 5 digits
DrawNumber5:
	ld	bc,-10000
	call	DrawNumber_1
	ld	bc,-1000
	call	DrawNumber_1
; Draw decimal number HL in 3 digits
DrawNumber3:
	ld	bc,-100
	call	DrawNumber_1
	ld	c,-10
	call	DrawNumber_1
	ld	c,-1
DrawNumber_1:
	ld	a,'0'-1
DrawNumber_2:
	inc	a
  ld (DrawNumber_3+1),hl
	add	hl,bc
	jp	c,DrawNumber_2
DrawNumber_3:
	ld	hl,$0000
	call DrawChar
	ret 

;
ScreenThemeNite:
  xor a
  jp ScreenTheme_0
;
ScreenThemeLite:
  ld a,$FF
ScreenTheme_0:
  ld hl,$C3C8             ; Vector screen addresses, top-left
  ld b,128+16             ; lines count
ScreenTheme_1:
  ld c,13                 ; number of column pairs, 26 columns
  push hl                 ; save screen address
ScreenTheme_2:
  ld (hl),a
  inc h
  ld (hl),a
  inc h
  dec c
  jp nz,ScreenTheme_2
  pop hl                  ; restore screen address
  dec l
  dec b
  jp nz,ScreenTheme_1
  ret

; Copy DEDSOLATE title from Main Menu shadow screen to Vector screen
CopyTitleSign:
  di
  ld hl,0
  add hl,sp
  ld (SetSP1+1),hl
  ld hl,$C4F2                   ; Vector screen addresses, top-left
  ld sp,ShadowScreen+24*8            ; shadow screen address
  ld a,30                      ; 30 lines
  jp ShowShadowScreen_1
;
; Copy shadow screen 24*128=3072 bytes to Vector screen
ShowShadowScreen:
  di
  ld hl,0
  add hl,sp
  ld (SetSP1+1),hl
  ld hl,$E4C0                   ; Vector screen addresses, top-left
  ld sp,ShadowScreen            ; shadow screen address
  ld a,128                      ; 128 lines
ShowShadowScreen_1:             ; loop by A
	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b
	inc h

	pop bc
	ld (hl),c
	inc h
	ld (hl),b

	ld bc,0E8FFh
	add hl,bc

  dec a                         ; loop counter for line pairs
  jp nz,ShowShadowScreen_1      ; continue the loop
SetSP1:
	ld sp,0
	ei
  ret

; Clear block on the shadow screen
;   HL=row/col, DE=rows/cols
;   columns are 8px wide; rows=1..128, row=0..127; col=0..23, cols=1..24
ClearScreenBlock:
  push bc
  ld a,l    ; column
  ld c,h    ; row
  ld l,h    ; row
  ld h,$00
  ld b,h
  add hl,hl               ; now HL = row * 2
  add hl,bc               ; now HL = row * 3
  add hl,hl
  add hl,hl
  add hl,hl               ; now HL = row * 24
  ld c,a
  add hl,bc               ; now HL = row * 24 + col
  ld bc,ShadowScreen
  add hl,bc               ; now HL = start address
  ld c,24                 ; line width in columns
  xor a
;  ld a,$01   ;DEBUG
ClearScreenBlock_1        ; loop by rows
  push hl
  ld b,e    ; cols
ClearScreenBlock_2:       ; loop by columns
  ld (hl),a
  inc hl
  dec b
  jp nz,ClearScreenBlock_2
  pop hl
  add hl,bc               ; next line
  dec d     ; rows
  jp nz,ClearScreenBlock_1
  pop bc
  ret

;Inputs:
;   (seed1) contains a 16-bit seed value
;   (seed2) contains a NON-ZERO 16-bit seed value
;Outputs:
;   HL is the result
;   BC is the result of the LCG, so not that great of quality
;   DE is preserved
;Destroys:
;   AF
;cycle: 4,294,901,760 (almost 4.3 billion)
; https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random#Combined_LFSR.2FLCG.2C_16-bit_seeds
Random16:
    ld hl,(Random16_seed1)
    ld b,h
    ld c,l
    add hl,hl
    add hl,hl
    inc l
    add hl,bc
    ld (Random16_seed1),hl
    ld hl,(Random16_seed2)
    add hl,hl
    sbc a,a
    and %00101101
    xor l
    ld l,a
    ld (Random16_seed2),hl
    add hl,bc
    ret
Random16_seed1: dw 12345
Random16_seed2: dw 54321

GetRandomByte:
  push bc
  call Random16
  pop bc
  ld a,h
  xor l
  ret
;
; Get random number 0..7
GetRandom8:
  call GetRandomByte
  rra
  rra
  and $07
  ret
;
; Get random number 0..10 for door access codes
; value 10 is for '-' char and we made its probability lower by 1/3
GetRandom11:
  call GetRandomByte
  rra
  and $1F                 ; 0..31
GetRandom11_1:
  cp 11                   ; less than 11?
  ret c                   ; yes => return 0..10
  sub 11                  ; 0..20, then 0..9
  jp GetRandom11_1

;----------------------------------------------------------------------------

  INCLUDE "desolcodb.asm"

;----------------------------------------------------------------------------
DesolateCodeEnd:

; Shadow screen, 192 x 140 pixels
;   12*2*(64*2+12) = 3360 bytes
ShadowScreen EQU $B2E0

  IF DesolateCodeEnd > MirrorTab
  .ERROR DesolateCodeEnd overlaps MirrorTab
  ENDIF

;----------------------------------------------------------------------------

END
