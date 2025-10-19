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

    ; edge detection: if Y!=0 then another button has been pressed  
    CPY #$00
    BNE skip_move      ; stop any move and jump to skip_move label

; -------- DOWN (bit1) --------  ;This operations call subroutines
    LDA $4000
    AND #%00000010
    BEQ chk_up
    JSR clear_pixel  
    JSR move_down
    JSR turn_on_pixel
    JMP loop

; -------- UP (bit0) --------
chk_up:
    LDA $4000
    AND #%00000001
    BEQ chk_right
    JSR clear_pixel
    JSR move_up
    JSR turn_on_pixel
    JMP loop

; -------- RIGHT (bit3) --------
chk_right:
    LDA $4000
    AND #%00001000
    BEQ chk_left
    JSR clear_pixel
    JSR move_right
    JSR turn_on_pixel
    JMP loop

; -------- LEFT (bit2) --------
chk_left:
    LDA $4000
    AND #%00000100
    BEQ skip_move
    JSR clear_pixel
    JSR move_left
    JSR turn_on_pixel
    JMP loop

; -------- no key pressed --------
not_pressed:
    LDY #$00              ; allow next press to trigger a move
    JMP loop

; -------- key still held --------
skip_move:
    LDY #$01              ; keep blocking until release
    JMP loop

; ==================== ROUTINES ==========================    

clear_pixel: ; turn off old pixel
    LDA #$00
    STA $0200,X
    RTS

move_down:              ;this part is X = X + 16  (using A as temp register for arithmetic, TXA e TAX for copy)
    TXA
    CLC
    ADC #$10            ; 10 is 16 in decimal
    TAX
    RTS

move_up:                ;this part is X = X - 16 (using A as temp register for arithmetic, TXA e TAX for copy)
    TXA
    SEC
    SBC #$10            ; 10 is 16 in decimal
    TAX
    RTS

move_right:             ; X = X + 1, wrap on same row 
    INX                 
    TXA                 ; if the pixel goes over 15 -> back to column 0 e and one row up
    AND #$0F            ; A = (X & 0x0F)=0 should  be like X%16=0 check
    BNE no_wrap_r       ;no right edge
    TXA
    SEC
    SBC #$10            ; X = X - 16 to stay on same row
    TAX
no_wrap_r:
    RTS

move_left:              ; X = X - 1, wrap on same row
    DEX
    TXA                 ; if the pixel position goes under 0 -> back to column 15 e one wae down
    AND #$0F            ; A = (X & 0x0F)=15  should  be like X%16=15 check
    CMP #$0F            
    BNE no_wrap_l       ; no left edge
    TXA
    CLC
    ADC #$10            ; X = X + 16 to stay on same row
    TAX
no_wrap_l:
    RTS

turn_on_pixel:          ; turn on new pixel
    LDA #$02
    STA $0200,X
    LDY #$01            ; lock until release
    RTS

;------- interrupts -------
nmi:
    RTI
irq:
    RTI

.GOTO $FFFA
.DW nmi
.DW start
.DW irq