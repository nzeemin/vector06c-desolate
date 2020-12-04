
ColorNone .equ 00000000b
ColorC000 .equ 11111111b    ; Color for data on C000-DFFF
ColorE000 .equ 11111110b    ; Color for data on E000-FFFF - game screen
ColorBoth .equ 00000000b    ; Color for '1' bit in both spaces
; Palette colors
Col0000	.equ	ColorNone	;0
Col0001	.equ	ColorE000	;1
Col0010	.equ	ColorC000	;2
Col0011	.equ	ColorBoth	;3
Col0100	.equ	ColorNone	;4
Col0101	.equ	ColorE000	;5
Col0110	.equ	ColorC000	;6
Col0111	.equ	ColorBoth	;7
Col1000	.equ	ColorNone	;8
Col1001	.equ	ColorE000	;9
Col1010	.equ	ColorC000	;10
Col1011	.equ	ColorBoth	;11
Col1100	.equ	ColorNone	;12
Col1101	.equ	ColorE000	;13
Col1110	.equ	ColorC000	;14
Col1111	.equ	ColorBoth	;15

;----------------------------------------------------------------------------

Start	.equ	280h

	.EXPORT CpHLDE
	.EXPORT KeyLineEx, KeyLine0, KeyLine1, KeyLine5, KeyLine6, KeyLine7

;----------------------------------------------------------------------------

	.org	100h

	di
	xra	a
	out	10h
	lxi	sp,100h
	lxi	h,0C3F3h
	shld	0
	mov	a,h
	lxi	h,Restart
	shld	2
	sta	38h
	lxi	h,KEYINT
	shld	38h+1

; Move encoded block from Start to A000h
	xra	a
	lxi	d,Start		; source addr
	lxi	b,0A000h	; destination addr
Init_1:
	ldax	d
	inx	d
	stax	b
	inr	c
	jnz	Init_1
	inr	b
	jnz	Init_1

; Decompress the encoded block from A000h to Start
	lxi	h,0A000h
	lxi	d,Start
	call	unlzsa1

; Clear memory from A000h to FFFFh
	xra	a
	lxi	b,0A000h	; destination addr
Init_2:
	stax	b
	inr	c
	jnz	Init_2
	inr	b
	jnz	Init_2

	ei
	hlt

; Programming the Palette
	lxi	d, 100Fh
	lxi	h, Palette+15
PaletLoop:
	mov	a, e
	out	2
	mov	a, m
	out	0Ch
	out	0Ch
	out	0Ch
	out	0Ch
	out	0Ch
	dcx	h
	out	0Ch
	dcr	e
	out	0Ch
	dcr	d
	out	0Ch
	jnz	PaletLoop

Restart:
	lxi	sp,100h
	mvi	a, 88h
	out	4		; initialize R-Sound 2

	ei
	jp Start

KEYINT:
	push	psw
	mvi	a, 8Ah
	out	0
; Keyboard scan
	in	1
	ori	00011111b
	sta	KeyLineEx
	mvi	a, 0FEh
	out	3
	in	2
	sta	KeyLine0
	mvi	a, 0FDh
	out	3
	in	2
	sta	KeyLine1
	mvi	a, 0DFh
	out	3
	in	2
	sta	KeyLine5
	mvi	a, 0BFh
	out	3
	in	2
	sta	KeyLine6
	mvi	a, 07Fh
	out	3
	in	2
	sta	KeyLine7
; Scrolling, screen mode, border
	mvi	a, 88h
	out	0
	mvi	a, 2
	out	1
	mvi	a, 23
	out	3		; scrolling
	mvi	a, 00000000b
	out	2		; screen mode and border
;
	pop	psw
	ei
	ret

KeyLineEx:	.db 11111111b
KeyLine0:	.db 11111111b
KeyLine1:	.db 11111111b
KeyLine5:	.db 11111111b
KeyLine6:	.db 11111111b
KeyLine7:	.db 11111111b

BorderColor:	.db 0		; border color number 0..15

Palette:
	.db Col0000,Col0001,Col0010,Col0011
	.db Col0100,Col0101,Col0110,Col0111
	.db Col1000,Col1001,Col1010,Col1011
	.db Col1100,Col1101,Col1110,Col1111

; Compare HL and DE
CpHLDE:
	push h
	mov	a, l	  ;
	sbb	e	  ;
	mov	l, a	  ;
	mov	a, h	  ;
	sbb	d	  ;
	mov	h, a	  ;
	jc	$+7	  ;
	ora	l	  ;
	jmp	$+5	  ;
	ora	l	  ;
	stc	 	  ;
	pop h
	ret

; LZSA1 decompressor code by Ivan Gorodetsky
; https://gitlab.com/ivagor/lzsa8080/-/blob/master/LZSA1/unlzsa1_small.asm
; input: 	hl=compressed data start
;		de=uncompressed destination start

.DEFINE NEXT_HL inx h
.DEFINE ADD_OFFSET xchg\ dad d
.DEFINE NEXT_DE inx d

unlzsa1:
	mvi b,0
ReadToken:
	mov a,m
	push psw
	NEXT_HL
	ani 70h
	jz NoLiterals 
	rrc\ rrc\ rrc\ rrc
	cpi 7
	cz ReadLongBA
	mov c,a
	call BLOCKCOPY
NoLiterals:
	pop psw
	push d
	mov e,m
	NEXT_HL
	mvi d,0FFh
	ora a
	jp ShortOffset
LongOffset:
	mov d,m
	NEXT_HL
ShortOffset:
	ani 0Fh
	adi 3
	cpi 15+3
	cz ReadLongBA
	mov c,a
	xthl
	ADD_OFFSET
	call BLOCKCOPY
	pop h
	jmp ReadToken
ReadLongBA:
	add m
	NEXT_HL
	rnc
	mov b,a\ mov a,m\ NEXT_HL\ rnz
	mov c,a\ mov b,m\ NEXT_HL
	ora b
	mov a,c
	rnz
	pop d
	pop d
	ret
BLOCKCOPY:
	mov a,m
	stax d
	NEXT_HL
	NEXT_DE
	dcx b
	mov a,b
	ora c
	jnz $-7
	ret

; Filler
	.org	Start-1
	.db 0

	.end

;----------------------------------------------------------------------------
