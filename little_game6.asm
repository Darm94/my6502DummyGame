; ===== Pixel move U/D/L/R: one step per press =====
; Using Registers for:
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
    ; ---- check if some of U/D/L/R buttons are pressed ----
    LDA $4000
    AND #%00001111
    BEQ not_pressed    ; none pressed = jump to the end
    STA $00            ; save the input byte inside Page Zero index 0

    ; ---- Press detection: if Y!=0 then another button has been pressed ----
    CPY #$00
    BNE skip_move      ; stop any move and jump to skip_move label

    ; ---- Input check using the byte inside Page Zero index 0 ----
    LDA $00
    AND #%00000010     ; DOWN?
    BNE do_down
    LDA $00
    AND #%00000001     ; UP?
    BNE do_up
    LDA $00
    AND #%00001000     ; RIGHT?
    BNE do_right
    LDA $00
    AND #%00000100     ; LEFT?
    BNE do_left
    ; ---- This line close the loop,but it should be not possible to reach this point cause the initial input check ----
    JMP loop

do_down:
    LDA #$00           ; set A as parameter 0 = down
    JSR move
    JMP loop

do_up:
    LDA #$01           ; set A as parameter 1 = up
    JSR move
    JMP loop

do_right:
    LDA #$02           ; set A as parameter 2 = right
    JSR move
    JMP loop

do_left:
    LDA #$03           ; set A as parameter 3 = left
    JSR move
    JMP loop

not_pressed:
    LDY #$00           ; allow next press to trigger a move
    JMP loop

skip_move:
    LDY #$01           ; keep blocking until release
    JMP loop

; ==================== MOVE ROUTINE =====================================================================================    
; How it works: Clean old pixel, then it check on A as a function Parameter (i prefered to use it for a single parameter)
;   A parameter configuration :
;   A = $00 -> down (X = X + 16)
;   A = $01 -> up   (X = X - 16)
;   A = $02 -> right (X = X + 1, wrap on row)
;   A = $03 -> left  (X = X - 1, wrap on row)
move:
    ; ----- clear old pixel ------
    PHA
    LDA #$00
    STA $0200,X
    PLA

    ; ---- Direction Check from parameter in A register like a classic if_else three ----
    CMP #$00
    BEQ mv_down
    CMP #$01
    BEQ mv_up
    CMP #$02
    BEQ mv_right
    CMP #$03
    BEQ mv_left
    RTS

mv_down:              ;this part is X = X + 16  (using A as temp register for arithmetic, TXA e TAX for copy)
    TXA
    CLC
    ADC #$10          ; 10 is 16 in decimal
    TAX               ; saving result in X register
    JMP mv_done

mv_up:                ;this part is X = X - 16 (using A as temp register for arithmetic, TXA e TAX for copy)
    TXA
    SEC
    SBC #$10          ; 10 is 16 in decimal
    TAX               ; saving result in X register
    JMP mv_done

mv_right:              ; X = X + 1, wrap on same row
    INX                 
    TXA                ; if the pixel goes over 15 -> back to column 0 e and one row up
    AND #$0F           ; A = (X & 0x0F)=0 should  be like X%16=0 check
    BNE mv_done
    TXA
    SEC
    SBC #$10           ; X = X - 16 to stay on same row
    TAX                ; saving this "row fixing" operation result in X register
    JMP mv_done

mv_left:               ; X = X - 1, wrap on same row
    DEX
    TXA                ; if the pixel position goes under 0 -> back to column 15 e one wae down
    AND #$0F           ; A = (X & 0x0F)=15  should  be like X%16=15 check
    CMP #$0F
    BNE mv_done
    TXA
    CLC
    ADC #$10           ; X = X + 16 to stay on same row
    TAX                ; saving this "row fixing" operation result in X register
    
mv_done:
    LDA #$02           ; turn on new pixel
    STA $0200,X
    LDY #$01           ; lock until release
    RTS
;==============================================================================================================================
;----------- interruptions -------------------------------------------------
nmi:
    RTI
irq:
    RTI

.GOTO $FFFA
.DW nmi
.DW start
.DW irq

    



