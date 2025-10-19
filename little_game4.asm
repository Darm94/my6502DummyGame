; ===== Pixel move U/D/L/R: one step per press =====
; X = current offset on page $0200
; Y = prevPressed flag (0 = no, 1 = yes)
; Joypad bits: Up=bit0, Down=bit1, Left=bit2, Right=bit3

.ORG $8000

start:
    CLI
    LDX #$00          ; green pixel start at offset 0
    LDY #$00          ; prevPressed = 0
    LDA #$02
    STA $0200,X       ; light first pixel at 200+0

loop:
    ; check if some of U/D/L/R buttons are pressed
    LDA $4000
    AND #%00001111
    BEQ not_pressed    ; none pressed = jump to the end

    ; edge detection: if Y!=0 then another button its been pressed  
    CPY #$00
    BNE skip_move      ; stop any move and jump to skip_move label

    ; -------- DOWN (bit1) --------
    LDA $4000
    AND #%00000010
    BEQ chk_up

    ; turn off old pixel
    LDA #$00
    STA $0200,X

    ;this part is X = X + 16  (using A as temp register for arithmetic, TXA e TAX for copy)
    TXA
    CLC
    ADC #$10 ; 10 is 16 in decimal
    TAX

    ; turn on new pixel
    LDA #$02
    STA $0200,X

    LDY #$01            ; mark as pressed         
    JMP loop

; -------- UP (bit0) --------
chk_up:
    LDA $4000
    AND #%00000001
    BEQ chk_right

    ; turn off old pixel
    LDA #$00
    STA $0200,X

    ;this part is X = X - 16 (using A as temp register for arithmetic, TXA e TAX for copy)
    TXA
    SEC
    SBC #$10 ; 10 is 16 in decimal
    TAX

    ; turn on new pixel
    LDA #$02
    STA $0200,X

    LDY #$01
    JMP loop

; -------- RIGHT (bit3) --------
chk_right:
    LDA $4000
    AND #%00001000
    BEQ chk_left

    ; turn off old pixel
    LDA #$00
    STA $0200,X

    INX                 ; this set X = X + 1
 
    ; se abbiamo sforato la colonna 15 -> colonna torna 0 e "risale" di una riga
    TXA
    AND #$0F            ; A = (X & 0x0F)
    BNE right_done      ; se != 0, nessuno sforo a destra

    ; sforo a destra: X = X - 32 (0x20)
    TXA                 ; riprendi X intero in A
    SEC
    SBC #$10
    TAX

right_done:

    ; turn on new pixel
    LDA #$02
    STA $0200,X

    LDY #$01
    JMP loop

; -------- LEFT (bit2) --------
chk_left:
    LDA $4000
    AND #%00000100
    BEQ skip_move

    LDA #$00
    STA $0200,X

    DEX                 ; this set position X = X - 1

    ; se abbiamo sforato la colonna 0 -> colonna diventa 15 e "scende" di una riga
    TXA
    AND #$0F            ; A = (X & 0x0F)
    CMP #$0F
    BNE left_done       ; se != 0x0F, nessuno sforo a sinistra

    ; sforo a sinistra: X = X + 32 (0x20)
    TXA                 ; riprendi X intero in A
    CLC
    ADC #$10
    TAX

left_done:

    ; turn on new pixel
    LDA #$02
    STA $0200,X

    LDY #$01
    JMP loop

; -------- no key pressed --------
not_pressed:
    LDY #$00              ; reset y to 0 cause it allow next press to trigger a move
    JMP loop

; -------- key still held --------
skip_move:
    LDY #$01              ; keep blocking until release
    JMP loop



;------- interruptions -------
nmi:
    RTI
break:
    RTI


.GOTO $FFFA     ; crea il vettore di interrupt
.DW nmi
.DW start
.DW break  