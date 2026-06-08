        .ORIG   x3000

MAIN    ; Initialize stack pointer and variables
        LD      R6, STACK_INIT  ; Set R6 to x4000 (Stack Pointer)
        AND     R2, R2, #0      ; SUM = 0
        ST      R2, SUM
        
        ; Call input subroutine
        JSR     INPUT_SUB
        
        ; Initialize MIN and MAX using first score
        LEA     R5, SCORE_ARRAY ; Load base address of array
        LDR     R0, R5, #0      ; Load SCORE_ARRAY[0]
        ST      R0, MIN         ; MIN = SCORE_ARRAY[0]
        ST      R0, MAX         ; MAX = SCORE_ARRAY[0]
        
        ; Call calculation subroutine
        JSR     CALC_SUB
        
        ; Call letter grade subroutine
        JSR     GRADE_SUB
        
        ; Call output subroutine
        JSR     OUTPUT_SUB
        
        HALT                    ; Stop program execution safely

;--- GLOBAL STORAGE / CONSTANTS ---
STACK_INIT  .FILL   x4000
SCORE_ARRAY .BLKW   5
SUM         .FILL   x0000
MIN         .FILL   x0000
MAX         .FILL   x0000
AVERAGE     .FILL   x0000
LETTER      .FILL   x0000
NEG_X30     .FILL   xFFD0       ; Two's complement of x30 (-48)
POS_X30     .FILL   x0030       ; ASCII offset for numbers (+48)

;===================================================================
; SUBROUTINE: INPUT_SUB
;===================================================================
;(This is the block that needed to be updated from the pseudocode/ original draft)
INPUT_SUB
        STR     R1, R6, #0      ; PUSH R1
        STR     R5, R6, #-1     ; PUSH R5
        STR     R7, R6, #-2     ; PUSH R7 (Safeguard return address from TRAPs)
        ADD     R6, R6, #-3     ; Move Stack Pointer down by 3

        AND     R1, R1, #0      ; INDEX = 0
        LEA     R5, SCORE_ARRAY ; Base array pointer
        
IN_LOOP ADD     R3, R1, #-5      ; Check if INDEX == 5
        BRzp    IN_DONE
        
        ; Prompt User
        LEA     R0, PROMPT
        TRAP    x22             ; PUTS
        
        ; Read multi-digit inputs (simplified sequence)
        TRAP    x20             ; GETC (Read first digit)
        TRAP    x21             ; OUT
        LD      R4, NEG_X30
        ADD     R0, R0, R4      ; Convert first digit to int
        
        ; Scale first digit by 10 (Iterative ADD)
        ADD     R3, R0, #0      ; Copy value
        AND     R4, R4, #0      ; Clear accumulator
        ADD     R4, R4, R3      ; 1
        ADD     R4, R4, R3      ; 2
        ADD     R4, R4, R3      ; 3
        ADD     R4, R4, R3      ; 4
        ADD     R4, R4, R3      ; 5
        ADD     R4, R4, R3      ; 6
        ADD     R4, R4, R3      ; 7
        ADD     R4, R4, R3      ; 8
        ADD     R4, R4, R3      ; 9
        ADD     R4, R4, R3      ; 10
        ADD     R3, R4, #0      ; R3 = (Digit 1 * 10)
        
        TRAP    x20             ; GETC (Read second digit)
        TRAP    x21             ; OUT
        LD      R4, NEG_X30
        ADD     R0, R0, R4      ; Convert second digit to int
        ADD     R0, R3, R0      ; TOTAL_SCORE = Tens + Units
        
        STR     R0, R5, #0      ; Store total into SCORE_ARRAY[INDEX]
        
        ; Newline formatting
        LEA     R0, NEWLINE
        TRAP    x22
        
        ADD     R5, R5, #1      ; Increment array address pointer
        ADD     R1, R1, #1      ; INDEX++
        BRnzp   IN_LOOP

IN_DONE ADD     R6, R6, #3      ; Move Stack Pointer back up
        LDR     R7, R6, #-2     ; POP R7
        LDR     R5, R6, #-1     ; POP R5
        LDR     R1, R6, #0      ; POP R1
        RET

PROMPT  .STRINGZ "\nEnter Test Score: "
NEWLINE .STRINGZ "\n"

;===================================================================
; SUBROUTINE: CALC_SUB
;===================================================================

CALC_SUB
        STR     R1, R6, #0      ; PUSH R1
        STR     R5, R6, #-1     ; PUSH R5
        ADD     R6, R6, #-2     ; Move Stack Pointer down by 2

        AND     R1, R1, #0      ; INDEX = 0
        LEA     R5, SCORE_ARRAY
        LD      R2, SUM         ; Load global sum tracking
        
CALC_LP ADD     R3, R1, #-5     ; Check if INDEX == 5
        BRzp    CALC_DN
        
        LDR     R0, R5, #0      ; CURRENT_SCORE = SCORE_ARRAY[INDEX]
        ADD     R2, R2, R0      ; SUM = SUM + CURRENT_SCORE
        
        ; Check for Maximum (CURRENT_SCORE > MAX)
        LD      R3, MAX
        NOT     R3, R3
        ADD     R3, R3, #1      ; Two's complement (-MAX)
        ADD     R3, R0, R3      ; CURRENT_SCORE - MAX
        BRnz    CHK_MIN         ; If not greater, skip to min
        ST      R0, MAX         ; MAX = CURRENT_SCORE
        
CHK_MIN ; Check for Minimum (CURRENT_SCORE < MIN)
        LD      R3, MIN
        NOT     R3, R3
        ADD     R3, R3, #1      ; Two's complement (-MIN)
        ADD     R3, R0, R3      ; CURRENT_SCORE - MIN
        BRzp    NEXT_EL         ; If not lower, skip
        ST      R0, MIN         ; MIN = CURRENT_SCORE

NEXT_EL ADD     R5, R5, #1      ; Advance array pointer
        ADD     R1, R1, #1      ; INDEX++
        BRnzp   CALC_LP

CALC_DN ST      R2, SUM         ; Save updated sum
        
        ; Calculate Average (SUM / 5) using subtraction loops
        AND     R3, R3, #0      ; Clear quotient register (AVERAGE)
AVG_LP  ADD     R2, R2, #-5     ; Subtract 5
        BRn     AVG_DN          ; If negative, division is complete
        ADD     R3, R3, #1      ; Increment average count
        BRnzp   AVG_LP
AVG_DN  ST      R3, AVERAGE     ; Store calculated average

        ADD     R6, R6, #2      ; Move Stack Pointer back up
        LDR     R5, R6, #-1     ; POP R5
        LDR     R1, R6, #0      ; POP R1
        RET

;===================================================================
; SUBROUTINE: GRADE_SUB
;===================================================================

GRADE_SUB
        STR     R0, R6, #0      ; PUSH R0
        STR     R1, R6, #-1     ; PUSH R1
        STR     R7, R6, #-2     ; PUSH R7 
        ADD     R6, R6, #-3     ; Move Stack Pointer down by 3

        LD      R0, AVERAGE     ; Load score to analyze
        
        ; Check >= 90
        ADD     R1, R0, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-10    ; Complete subtraction of 90
        BRn     CHK_80          
        LD      R1, CHAR_A
        BRnzp   GR_STORE

CHK_80  ;Check >= 80
        ADD     R1, R0, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16    ; Complete subtraction of 80
        BRn     CHK_70          
        LD      R1, CHAR_B
        BRnzp   GR_STORE

CHK_70  ;Check >= 70
        ADD     R1, R0, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-6     ; Complete subtraction of 70
        BRn     CHK_60          
        LD      R1, CHAR_C
        BRnzp   GR_STORE

CHK_60  ;Check >= 60
        ADD     R1, R0, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-16
        ADD     R1, R1, #-12    ; Complete subtraction of 60
        BRn     GET_F           
        LD      R1, CHAR_D
        BRnzp   GR_STORE

GET_F   LD      R1, CHAR_F

GR_STORE ST     R1, LETTER      ; Save assigned letter character

        ADD     R6, R6, #3      ; Move Stack Pointer back up
        LDR     R7, R6, #-2     ; POP R7
        LDR     R1, R6, #-1     ; POP R1
        LDR     R0, R6, #0      ; POP R0
        RET

CHAR_A  .FILL   x0041           ; 'A'
CHAR_B  .FILL   x0042           ; 'B'
CHAR_C  .FILL   x0043           ; 'C'
CHAR_D  .FILL   x0044           ; 'D'
CHAR_F  .FILL   x0046           ; 'F'

;===================================================================
; SUBROUTINE: OUTPUT_SUB
;===================================================================

OUTPUT_SUB
        STR     R0, R6, #0      ; PUSH R0
        STR     R7, R6, #-1     ; PUSH R7 (Safeguard across nested helper JSR)
        ADD     R6, R6, #-2     ; Move Stack Pointer down by 2

        ; Print Minimum
        LEA     R0, OUT_MIN
        TRAP    x22
        LD      R0, MIN
        JSR     PRINT_NUM
        
        ; Print Maximum
        LEA     R0, OUT_MAX
        TRAP    x22
        LD      R0, MAX
        JSR     PRINT_NUM

        ; Print Average
        LEA     R0, OUT_AVG
        TRAP    x22
        LD      R0, AVERAGE
        JSR     PRINT_NUM

        ; Print Letter Grade
        LEA     R0, OUT_LET
        TRAP    x22
        LD      R0, LETTER
        TRAP    x21             ; Direct single char print
        LEA     R0, NEWLINE
        TRAP    x22

        ADD     R6, R6, #2      ; Move Stack Pointer back up
        LDR     R7, R6, #-1     ; POP R7
        LDR     R0, R6, #0      ; POP R0
        RET

OUT_MIN .STRINGZ "Minimum Score = "
OUT_MAX .STRINGZ "Maximum Score = "
OUT_AVG .STRINGZ "Average Score = "
OUT_LET .STRINGZ "Letter Grade  = "

;--- Helper Routine: Convert value to multi-character ASCII output ---

PRINT_NUM
        STR     R1, R6, #0
        STR     R2, R6, #-1
        STR     R7, R6, #-2     ; Nested call safeguard
        ADD     R6, R6, #-3

        AND     R1, R1, #0      ; Tens column counter
        ADD     R2, R0, #0      ; Working value copy
        
P_LOOP  ADD     R2, R2, #-10
        BRn     P_REM
        ADD     R1, R1, #1
        BRnzp   P_LOOP
        
P_REM   ADD     R2, R2, #10     ; Restore leftover remainder units
        LD      R4, POS_X30
        
        ADD     R0, R1, R4      ; Format tens digit to ASCII
        TRAP    x21
        ADD     R0, R2, R4      ; Format units digit to ASCII
        TRAP    x21
        
        LEA     R0, NEWLINE
        TRAP    x22

        ADD     R6, R6, #3
        LDR     R7, R6, #-2     ; Restore components
        LDR     R2, R6, #-1
        LDR     R1, R6, #0
        RET
        .END
