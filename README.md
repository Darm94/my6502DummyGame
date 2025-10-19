# NES-Style Pixel Movement in 6502 Assembly

Un piccolo esercizio didattico in Assembly MOS 6502 che mostra come muovere un “pixel” (una cella di memoria) usando il joypad.

Include: movimento Up/Down/Left/Right, edge-detection (una sola mossa per pressione) e effetto Pac-Man orizzontale (wrap sulla stessa riga).

---

## Struttura generale

| Sezione | Descrizione |
|----------|-------------|
| `.ORG $8000` | punto di partenza del programma |
| `start:` | inizializza i registri e accende il primo pixel |
| `loop:` | ciclo principale: legge il joypad e decide se muovere |
| `chk_up/down/left/right:` | controllano ogni direzione |
| `nmi`, `break` | routine vuote per gli interrupt |
| vettori a `$FFFA` | indirizzi di NMI / RESET / IRQ |

---

## Logica di movimento

- **X**: posizione corrente del pixel (offset dentro la page `$0200`)
- **Y**: flag di edge detection  
  - `0`: nessun tasto era premuto, permetti movimento  
  - `1`: tasto già premuto, blocca finché non rilasci
- **$4000**: byte con lo stato dei pulsanti  
  - bit0 = Up  
  - bit1 = Down  
  - bit2 = Left  
  - bit3 = Right  

Ogni volta che premi un tasto:
1. spegne il pixel nella posizione attuale  
2. aggiorna X (incrementa/decrementa di 1 o di 16)  
3. accende il pixel nella nuova posizione  
4. imposta `Y=1` per bloccare ripetizioni finché non rilasci  

---

## Istruzioni principali del 6502 utilizzate

| Istruzione | Significato | Esempio d’uso |
|-------------|--------------|----------------|
| `LDA` | Load Accumulator | carica un valore in A |
| `STA` | Store Accumulator | salva A in memoria |
| `AND` | AND logico (bitmask) | `AND #%00000010` isola il bit Down |
| `BEQ` / `BNE` | salta se Zero=1 / Zero=0 | usato dopo AND o CPY |
| `CPY` | confronta Y con valore | per controllare il flag di pressione |
| `INX` / `DEX` | incrementa/decrementa X | spostamento orizzontale |
| `TXA` / `TAX` | trasferisce X↔A | serve per fare operazioni aritmetiche su X |
| `CLC` / `SEC` | clear/set carry | prepara ADC o SBC |
| `ADC` / `SBC` | somma/sottrai con carry | movimento verticale (±16) |
| `RTI` | ritorna da interrupt | routine vuote per NMI/IRQ |

---

## Effetto Pac-Man orizzontale

Quando X supera la 16ª colonna (o torna sotto 0):

- Destra: se `(X & $0F) == 0` allora `X = X - 16`
- Sinistra: se `(X & $0F) == 15` allora `X = X + 16`

Questo mantiene il pixel sulla stessa riga, simulando il wrap laterale.

---

--------------------------------------------------------------
   Riassunto del comportamento
   ---------------------------

   Avvio:              primo pixel acceso in $0200
   Premi un tasto:     spostamento di 1 (Left/Right) o 16 (Up/Down)
   Rilascio:           puoi muoverti di nuovo
   Bordi orizzontali:  il pixel riappare dall’altro lato della stessa riga

   Compilazione (necroassembler):
   python -m necroassembler.cpu.mos6502 main.asm main.bin

Compilazione con necroassembler:
python -m necroassembler.cpu.mos6502 main.asm main.bin

Progetto puramente didattico per comprendere i registri, le operazioni logiche e i vettori del processore MOS 6502.
