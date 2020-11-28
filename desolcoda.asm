

CHEAT_SHOW_ROOM_NUMBER  EQU 0
CHEAT_ALL_ACCESS        EQU 0
CHEAT_ALL_INVENTORY     EQU 0
CHEAT_HAVE_WEAPON       EQU 0
CHEAT_HEALTH_999        EQU 0


  ORG $0300
Start:
  ld sp,$B300
; Draw DESOLATE title sign on top of the screen
  ld hl,LF4B5             ; Decode from - Main menu screen
  ld bc,12*3              ; need only 3 tile lines
  call LADF5              ; Decode screen to LDBF5
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

;  ld hl,$0000
;  ld de,$0116  ; 1 row, 24 cols
;  call ClearScreenBlock
;  ld hl,$7F00
;  ld de,$0116  ; 1 row, 24 cols
;  call ClearScreenBlock
;  call ShowShadowScreen

;  call ClearPenRowCol
;  ld hl,87
;  call DrawNumber5
;  call WaitAnyKey

;  xor a
;  ld (L86D7),a
;  ld hl,Tileset2+$0C*64
;  call DrawTileMasked  ;   A = penRow; L86D7 = penCol; HL = tile address

;  ld a,22
;  ld e,20
;  ld b,16
;  ld hl,Tileset3+15*32
;  call L9E5F    ; Put tile on the screen by XOR; E = row; A = X coord; B = height; HL = tile address

  call ShowShadowScreen
  di
  halt

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

ROM_BEEPER 		EQU $03B5   ; hl=pitch  de=duration

; Sound for "Look" or "Shoot" action
SoundLookShoot:
  ld hl,$0190
  ld de,$0004
  jp ROM_BEEPER

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

; Source: http://www.breakintoprogram.co.uk/computers/zx-spectrum/keyboard
; Returns: A=key code, $00 no key; Z=0 for key, Z=1 for no key
; Key codes: Down=$01, Left=$02, Right=$03, Up=$04, Look/shoot=$05
;            Inventory=$06, Escape=$07, Switch look/shoot=$08, Enter=$09, Menu=$0F
ReadKeyboard:
;   LD HL,ReadKeyboard_map  ; Point HL at the keyboard list
;   LD D,8                ; This is the number of ports (rows) to check
;   LD C,$FE              ; C is always FEh for reading keyboard ports
; ReadKeyboard_0:        
;   LD B,(HL)             ; Get the keyboard port address from table
;   INC HL                ; Increment to list of keys
;   IN A,(C)              ; Read the row of keys in
;   AND $1F               ; We are only interested in the first five bits
;   LD E,5                ; This is the number of keys in the row
; ReadKeyboard_1:        
;   SRL A                 ; Shift A right; bit 0 sets carry bit
;   JR NC,ReadKeyboard_2  ; If the bit is 0, we've found our key
;   INC HL                ; Go to next table address
;   DEC E                 ; Decrement key loop counter
;   JR NZ,ReadKeyboard_1  ; Loop around until this row finished
;   DEC D                 ; Decrement row loop counter
;   JR NZ,ReadKeyboard_0  ; Loop around until we are done
;   xor a                 ; Clear A (no key found)
;   RET
; ReadKeyboard_2:
;   LD A,(HL)             ; We've found a key at this point; fetch the character code!
;   or a
  xor a ;STUB
  RET
; Mapping:
;   QAOP/1234/6789 - arrows, Space/B/M/N/Z/0/5 - look/shoot
;   S/D - switch look/shoot, W/E - escape, U/I - inventory; G - menu, Enter=Enter
ReadKeyboard_map:
  DB $FE, $00,$05,$00,$00,$00   ; Shift,"Z","X","C","V"
  DB $FD, $01,$08,$08,$00,$0F   ;   "A","S","D","F","G"
  DB $FB, $04,$07,$07,$00,$00   ;   "Q","W","E","R","T"
  DB $F7, $02,$03,$01,$04,$05   ;   "1","2","3","4","5"
  DB $EF, $06,$04,$01,$03,$02   ;   "0","9","8","7","6"
  DB $DF, $03,$02,$06,$06,$00   ;   "P","O","I","U","Y"
  DB $BF, $09,$00,$00,$00,$00   ; Enter,"L","K","J","H"
  DB $7F, $05,$00,$05,$05,$05   ; Space,Sym,"M","N","B"

CpHLDE:
  ret ;STUB

; Get shadow screen address using penCol in L86D7
;   A = row 0..137
;   (L86D7) = penCol 0..191
; Returns HL = address
; Clock timing: 175
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
  or a
  rra           ; shift right
  or a
  rra           ;
  or a
  rra           ; now A = 8px column
  ld e,a
  ld d,$00
  add hl,de     ; now HL = line address + column
  pop de
  ret

; Draw tile with mask 16x16 -> 16x16 on shadow screen - for Tileset2 tiles
;   A = penRow; L86D7 = penCol; HL = tile address
DrawTileMasked:
  ex de,hl      ; now DE = tile address
  call GetScreenAddr	; now HL = screen addr
  ld b,8        ; 8 row pairs = 16 rows
DrawTileMasked_1:
  push bc
  ld bc,24-1    ; increment to the next line
; Draw 1st line
  ld a,(de)     ; get mask
  inc de
  and (hl)
  ex de,hl      ; now DE = screen addr, HL = tile addr
  or (hl)
  ex de,hl      ; now DE = tile addr, HL = screen addr
  ld (hl),a     ; write 1st byte
  inc de
  inc hl
  ld a,(de)     ; get mask
  inc de
  and (hl)
  ex de,hl      ; now DE = screen addr, HL = tile addr
  or (hl)
  ex de,hl      ; now DE = tile addr, HL = screen addr
  ld (hl),a     ; write 2nd byte
  inc de
  add hl,bc     ; to the 2nd line
; Draw 2nd line
  ld a,(de)     ; get mask
  inc de
  and (hl)
  ex de,hl      ; now DE = screen addr, HL = tile addr
  or (hl)
  ex de,hl      ; now DE = tile addr, HL = screen addr
  ld (hl),a     ; write 1st byte
  inc de
  inc hl
  ld a,(de)     ; get mask
  inc de
  and (hl)
  ex de,hl      ; now DE = screen addr, HL = tile addr
  or (hl)
  ex de,hl      ; now DE = tile addr, HL = screen addr
  ld (hl),a     ; write 2nd byte
  inc de
  add hl,bc     ; to the next line
  pop bc
  dec b
  jp nz,DrawTileMasked_1
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
;TODO:  bit 7,a       ; lowered symbol?
;  jp z,DrawChar_3
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

; Copy DEDSOLATE title from Main Menu shadow screen to Vector screen
CopyTitleSign:
  ld de,$C4F0                   ; Vector screen addresses
  ld hl,ShadowScreen+24*8       ; shadow screen address
  ld b,30                       ; lines to copy
  jp ShowShadowScreen_1
;
; Copy shadow screen 24*128=3072 bytes to Vector screen
ShowShadowScreen:
  ld de,$E4C0                   ; Vector screen addresses
  ld hl,ShadowScreen            ; shadow screen address
  ld b,128                      ; 128 lines
ShowShadowScreen_1:             ; loop by A
  push de
  ld a,(hl)                     ; byte 0
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 1
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 2
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 3
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 4
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 5
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 6
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 7
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 8
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 9
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 10
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 11
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 12
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 13
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 14
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 15
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 16
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 17
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 18
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 19
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 20
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 21
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 22
  ld (de),a
  inc hl
  inc d
  ld a,(hl)                     ; byte 23
  ld (de),a
  inc hl
;  inc d
; Continue the loop
  pop de
  dec e                         ; next line
  dec b                         ; loop counter for line pairs
  jp nz,ShowShadowScreen_1      ; continue the loop
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
;  xor a
  ld a,$01   ;DEBUG
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

; 8-bit random number generator using Refresh Register (R)
; See http://www.cpcwiki.eu/index.php/Programming:Random_Number_Generator
GetRandomByte:
  ld hl,(GetRandomByte_seed)
  ld a,r
  ld d,a
  ld e,a
  add hl,de
  xor l
  add a,a
  xor h
  ld l,a
  ld (GetRandomByte_seed),hl
  ret
GetRandomByte_seed: DEFW 12345
;
; Get random number 0..7
GetRandom8:
  call GetRandomByte
  and $07
  ret
;
; Get random number 0..10 for door access codes
; value 10 is for '-' char and we made its probability lower by 1/3
GetRandom11:
  call GetRandomByte
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

; Shadow screen, 192 x 138 pixels
;   12*2*(64*2+10) = 3312 bytes
ShadowScreen EQU $B300

  IF DesolateCodeEnd > ShadowScreen
  .ERROR DesolateCodeEnd overlaps ShadowScreen
  ENDIF

;----------------------------------------------------------------------------

END
