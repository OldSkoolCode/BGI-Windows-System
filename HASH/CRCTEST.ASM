Comment |
Name    CRCTEST
Page    51,132
Title   CRCTEST.ASM

Author  (C) BF Gavin, Online Reference BBS.  All rights reserved.
Format  Standard .EXE file format. Supports Turbo Debug.
Intent  Demonstrate use of CRC32 lookup table function.

19APR92 v1.00 - Origin
              - Update

Remark  TASM  CrcTest
        TLINK CrcTest

        The initial 32 bit CRC value must be pre-condition to FFFFFFFFh.
        The final value must be inverted, as NOT AX, NOT DX.
        CRCs can be cross referenced with PKZIP and ARJ.  These archivers
        store the original file CRC value which can be displayed with the
        verbose display options of these programs.
        |

                .SEQ                            ; Assemble in source file order
                MASM                            ; Use regular MASM mode
                LOCALS  __                      ; Dbl underscore = locals

                Assume  CS:Code_Segment
                Assume  DS:Nothing
                Assume  ES:Nothing
                Assume  SS:Stack_Segment


Code_Segment    Segment Para    Public


Include         Crc32.100                       ; Include the CRC32 source


Buffer          Db      'The quick brown fox jumped over the lazy dog',13,10
BfrLen          Dw      $-Buffer                ; CRC32 = 142EF208h


Main_Line       Proc    Near
        Mov     AX,CS                           ; Buffer is located here
        Mov     DS,AX                           ; Address the buffer segment

  ;Must precondition initial CRC = FFFFFFFFh
        Mov     AX,0FFFFh
        Mov     DX,AX

  ;Set buffer length and pointer
        Mov     CX,BfrLen                       ; Set buffer length for call
        Lea     SI,Buffer                       ; Set buffer pointer for call
        Call    CRC32                           ; DX:AX are pre-conditioned

  ;Post-condition returned CRC
        Not     AX                              ; Invert AX
        Not     DX                              ; Invert DX

  ;Exit
        Mov     AX,4C00h                        ; Return code = 0
        Int     21h                             ; Call DOS to exit
Main_Line       Endp
Code_Segment    Ends                            ; End of code Segment


Stack_Segment   Segment Para    Stack   'Stack'
        Dw      512 dup (?)                     ; 1024 BYTES of stack space
Stack_Segment   Ends


End             Main_Line                       ; Program entry point
