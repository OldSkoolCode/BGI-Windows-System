NAME    CRC_XMOD
PAGE    66,132
TITLE   CRC_XMOD.ASM
SUBTTL  Calculates CRC as used in XMODEM protocol

COMMENT |

Author: BF GAVIN, CompuServe 70137,3244
Intent: Calculates CRC value of XMODEM data string

Origin: 19OCT1986  Version 1.00
Update:


At entry:
  CX  length of data string
  SI  points at data string

Registers used:
  AL  data byte work reg
  AH  data byte saved in reg for increased speed
  BL  Crc_Lo byte work reg
  BX  CRC word register
  CX  8 bit shift count
  CX  length of data string
  DX  CRC word saved in reg for increased speed
  SI  data string pointer
  DI  CRC xor value held in reg for increased speed

CRC type:
  X16 + X12 + X5 + 1  (SDLC polynomial)

CRC bits:
  LSB 1...16 MSB (reversed bit pattern)

Data bits:
  MSB 8...1 LSB

Xor value:
  1021h = SDLC polynomial, reversed bit-wise from 8408h

XMODEM procedure:
  1) Only the 128 data bytes are CRC checked. SOH, and BLKs are not checked
  2) Xmodem CRC is calculated on data MSB first ... to LSB
  3) CRC is initialized to zero prior to calculation
  4) CRC is not 1's complemented prior to transmission as is SDLC
  5) Transmission order after data, is CRC_HI then CRC_LO
  6) CRC of (128 data bytes + CRC_HI + CRC_LO) always results in CRC of 0000h

Testing:
  Accurately calculates CRC transmitted by MITE Xmodem-CRC protocol on IBM PC,
  to receiving computer via null modem cable.
  CRC calculation time is approx 26 msec per Xmodem block on a standard PC

References:
  BYTE         - September 1986
  Tech Journal - April 1985

  |



                PAGE
CODE            SEGMENT PARA    PUBLIC  'CODE'

                ORG     100h                    ; Start at PSP + 100h
                Assume  CS:CODE
                Assume  DS:CODE
                Assume  ES:Nothing



MAIN            PROC    NEAR

        JMP     TEST_PROCEDURE                  ; Main line code



Crc_Xor         DW      1021h                   ; Xor value
Crc_Word        DW      0                       ; Calculated CRC of string
Data            DB      98 dup(0)               ; 98 leading zeros in block
                DB      'THE,QUICK,BROWN,FOX,'  ; Test data borrowed from
                DB      '0123456789'            ; example in BYTE magazine
                DB      04h,98h                 ; CRC of above data
Data_Len        DW      $ - Data                ; Data string total length



                PAGE
CRC_CALC        PROC    NEAR

        Mov     BX,0                            ; Xmodem inits Crc_Word to 0
        Mov     DI,Crc_Xor                      ; CRC xor value

  CRC_BYTE_LOOP:
        Push    CX                              ; Save the data string length
        Lodsb                                   ; Move data byte at [SI] to AL
        Mov     CX,8                            ; Loop 8 bits of each data byte

    CRC_BIT_LOOP:
        Mov     AH,AL                           ; Move data byte to work reg
        And     AH,80H                          ; Isolate Data(8) MSB bit
        Mov     DX,BX                           ; Save CRC word
        Shl     DX,1                            ; Left shift the CRC word
        And     BH,80H                          ; Isolate CRC(1) LSB bit
        Xor     BH,AH                           ; Flag = Data(8) Xor CRC(1)
        Mov     BX,DX                           ; Restore CRC word
        Jz      NEXT_BIT                        ; ZFlag is set if Flag = 0
        Xor     BX,DI                           ; CRC bits 16,12,5 Xor 1

    NEXT_BIT:
        Shl     AL,1                            ; Shift thru each data bit
        Loop    CRC_BIT_LOOP                    ; Loop 8 times thru data byte

        Pop     CX                              ; Restore data string length
        Loop    CRC_BYTE_LOOP                   ; Loop thru data string

        Mov     Crc_Word,BX                     ; Store the final CRC word
        Ret                                     ; To caller of CRC_CALC

CRC_CALC        ENDP



                PAGE
TEST_PROCEDURE  PROC    NEAR

  ZERO_TIMER:
        Mov     AH,2Dh                          ; Set time function
        Mov     CX,0                            ; Set hours/minutes to 0
        Mov     DX,0                            ; Set seconds/hundredths to 0
        Int     21h                             ; Call DOS
        Mov     CX,8000                         ; Count loops approx 4 minutes

  TEST_LOOP:
        Push    CX                              ; Save iteration count
        Mov     SI,Offset Data                  ; Point at data string
        Mov     CX,Data_Len                     ; Length of data string
        Call    CRC_CALC                        ; Get the CRC of data string
        Pop     CX                              ; Restore iteration count
        Loop    TEST_LOOP                       ; 26.8825 msec/iteration

  READ_TIMER:
        Mov     AH,2Ch                          ; Get time function
        Int     21h                             ; Call DOS
        Nop                                     ; Breakpoint here to see regs
        Int     20H                             ; Exit to DOS

TEST_PROCEDURE  ENDP




MAIN            ENDP

CODE            ENDS                            ; End of code segment

END             MAIN                            ; Entry point for linker
