
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

	.EXPORT KeyLineEx, KeyLine0, KeyLine1, KeyLine5, KeyLine6, KeyLine7
	.EXPORT BorderColor
	.EXPORT CpHLDE, SoundLookShoot

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

; Move encoded block from Start to C000h
	lxi	d,Start		; source addr
	lxi	b,0C000h	; destination addr
Init_1:
	ldax	d
	inx	d
	stax	b
	inr	c
	jnz	Init_1
	inr	b
	jnz	Init_1

; Decompress the encoded block from C000h to Start
	lxi	d,0C000h
	lxi	b,Start
	call	dzx0

; Clear memory from C000h to FFFFh
	lxi	b,0C000h	; destination addr
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
	lda	BorderColor
	ani	0Fh
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

; Short sound on look/shoot action
SoundLookShoot:
	MVI  H, 00Ah	; Counter 1
	XRA  A
SoundLookShoot_1:
	MVI  L, 080h	; Counter 2
SoundLookShoot_2:
	DCR  L
	JNZ     SoundLookShoot_2  ; delay
	XRI     001h	; inverse bit 0
	OUT     000h
	DCR  H
	JNZ     SoundLookShoot_1  ; Loop 30 times
	ret

; ZX0 decompressor code by Ivan Gorodetsky
; https://github.com/ivagorRetrocomp/DeZX/blob/main/ZX0/8080/OLD_V1/dzx0_CLASSIC.asm
; input: 	de=compressed data start
;			bc=uncompressed destination start

#ifdef BACKWARD
#define NEXT_HL dcx h
#define NEXT_DE dcx d
#define NEXT_BC dcx b
#else
#define NEXT_HL inx h
#define NEXT_DE inx d
#define NEXT_BC inx b
#endif

dzx0:
#ifdef BACKWARD
		lxi h,1
		push h
		dcr l
#else
		lxi h,0FFFFh
		push h
		inx h
#endif
		mvi a,080h
dzx0_literals:
		call dzx0_elias
		call dzx0_ldir
		jc dzx0_new_offset
		call dzx0_elias
dzx0_copy:
		xchg
		xthl
		push h
		dad b
		xchg
		call dzx0_ldir
		xchg
		pop h
		xthl
		xchg
		jnc dzx0_literals
dzx0_new_offset:
		call dzx0_elias
#ifdef BACKWARD
		inx sp
		inx sp
		dcr h
		rz
		dcr l
		push psw
		mov a,l
#else
		mov h,a
		pop psw
		xra a
		sub l
		rz
		push h
#endif
		rar\ mov h,a
		ldax d
		rar\ mov l,a
		NEXT_DE
#ifdef BACKWARD
		inx h
#endif
		xthl
		mov a,h
		lxi h,1
#ifdef BACKWARD
		cc dzx0_elias_backtrack
#else
		cnc dzx0_elias_backtrack
#endif
		inx h
		jmp dzx0_copy
dzx0_elias:
		inr l
dzx0_elias_loop:	
		add a
		jnz dzx0_elias_skip
		ldax d
		NEXT_DE
		ral
dzx0_elias_skip:
#ifdef BACKWARD
		rnc
#else
		rc
#endif
dzx0_elias_backtrack:
		dad h
		add a
		jnc dzx0_elias_loop
		jmp dzx0_elias

dzx0_ldir:
		push psw
dzx0_ldir1:
		ldax d
		stax b
		NEXT_DE
		NEXT_BC
		dcx h
		mov a,h
		ora l
		jnz dzx0_ldir1
		pop psw
		add a
		ret 

;----------------------------------------------------------------------------

; Filler
	.org	Start-1
	.db 0

	.end

;----------------------------------------------------------------------------
