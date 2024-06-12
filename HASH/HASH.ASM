;Fast hashing algorithm that returns an evenly distributed
;hash code out of strings. Range 0-1023.

;released to public domain by Marc Perkel, no rights reserved
;Computer Tyme
;216 South Glenstone
;Springfield MO. 65802
;417-866-1222
;CIS 76505,1120

;June 10, 1990

CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE
        PUBLIC  Hash

;Function Hash (var St : String) : Word;

Hash            PROC FAR

        PUSH    DS
        MOV     BX,SP
        CLD                                     ;go forward
        LDS     SI,SS:[BX+6]                    ;DS:SI => St
        LODSB                                   ;AL = Length(St)
        MOV     CL,AL                           ;CX = Length(St)
        MOV     BL,AL                           ;BX to contain Hash
        JCXZ    Done                            ;Done if CX is 0
        XOR     AH,AH                           ;Zero AH
        MOV     CH,AH
        MOV     BH,AH
Next:
        LODSB                                   ;Next char into AL
        XOR     BH,AL                           ;hash high byte
        MOV     DL,CL                           ;save CL
        AND     CL,3                            ;random SHL 0-3
        SHL     AX,CL                           ;shift left
        ADD     BX,AX                           ;add to hash
        MOV     CL,DL                           ;restore count in CL
NextL:  LOOP    Next                            ;repeat
Done:
        POP     DS                              ;Restore DS
        MOV     AX,BX                           ;Return in AX
        AND     AX,1023                         ;limit result 0-1023
        RET     4                               ;remove parameter and return

Hash            ENDP


CODE    ENDS

        END
