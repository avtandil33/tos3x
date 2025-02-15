/*
 * BIOS functions for hades that don't
 * fit as patches in the original routines
 */

#include "config.h"
#include "asmdefs.h"
#include "tosvars.inc"
#include "biosdefs.h"

#if MEDUSA /* whole file */

/*
 * Yes, we assemble to the data segment here, so that the code ends up at the end of the ROM image
 */
	data

medusa_xbios: ds.b 0
    /* fill up space between end of resource and $e3e000 */
#if TOSVERSION == 0x206
	dcb.b $e3e000-$e3dfca,-1
#endif

	xdef medusa_exception
medusa_exception:
                move.l  2(sp),_proc_enum.w /* pc merken */
                movem.l d0-d7/a0-a7,_proc_dregs.w /* die Register merken */
                move    usp,a0
                move.l  a0,_proc_usp.w  /* den USP merken */
                move.l  sp,a1
                moveq   #0,d1
                move.w  6(sp),d1        /* formatword holen */
                andi.w  #$0FFF,d1       /* format weg=offset */
                asr.w   #2,d1           /* /4 ergibt vector */
exception4:
                lea     (SUPSIZ*2+_supstk).w,sp /* den Stack initialisieren */
                tst.b   STEFlag.w       /* STE vorhanden? */
                bne.s   exception3      /* Nein! => */
                clr.b   $FFFF820D.w     /* low-Byte setzen (STE) */
                clr.w   $FFFF820E.w     /* Offset to next line loeschen */
                clr.w   $FFFF8264.w     /* Horizontal Bit-wize Scroll loeschen */
                clr.w   $FFFF8900.w     /* Digi-Sound stoppen */
exception3:
                moveq   #15,d0
                lea     _proc_stk.w,a0
exception2:
                move.w  (a1)+,(a0)+     /* 16 Worte vom SSP merken */
                dbra    d0,exception2
                move.l  #$12345678,_proc_lives.w /* Daten fuer gueltig erklaeren */

bombs:
                lea     tb1(pc),a0      /* zeiger auf starttext */
                bsr     string_out      /* ausgeben */
                cmpi.w  #56,d1          /* vector =56? */
                blt.s   bomb_fa4        /* nein kleiner-> */
                lea     tbuv(pc),a0     /* zeiger auf text */
                bsr     string_out      /* text ausgeben */
                move.w  d1,d2           /* vector nummer nach d2 */
                ror.l   #8,d2           /* an richtige stelle bringen */
                moveq   #1,d0           /* 2 Stellen */
                bsr     reg_aus1        /* ausgeben */
                bra.s   bomb_fa5
bomb_fa4:
                lea     tbev(pc),a0     /* zeiger auf exception text */
                subq.w  #1,d1           /* mit bus error beginnen */
bomb_fa1:
                subq.w  #1,d1
                beq.s   bomb_fa2        /* ok->weg */
bomb_fa3:
                move.b  (a0)+,d6        /* naechstes zeichen */
                beq.s   bomb_fa1        /* ende zeichenkette-> */
                bra.s   bomb_fa3        /* nein next */
bomb_fa2:
                bsr     string_out      /* text ausgeben */
bomb_fa5:
                lea     tb2(pc),a0      /* zeiger auf text */
                bsr     string_out      /* text ausgeben PC= */
                move.l  _proc_enum.w,d2    /* pc wert holen */
                bsr     reg_aus         /* ausgeben */
                bsr     string_out      /* sr= */
                move.w  _proc_stk.w,d2  /* sr holen */
                swap    d2              /* an richtige position bringen */
                moveq   #3,d0           /* nur 4 stellen */
                bsr     reg_aus1        /* ausgeben */
                bsr     string_out      /* usp= */
                move.l  _proc_usp.w,d2  /* usp wert holen */
                bsr     reg_aus         /* und ausgeben */
                bsr     string_out      /* formatword= */
                move.w  (_proc_stk+6).w,d2 /* formatword holen */
                swap    d2              /* an richtige position bringen */
                moveq   #3,d0           /* nur 4 stellen */
                bsr.s   reg_aus1        /* und ausgeben */
                bsr     string_out      /* (PC-4)= */
                move.l  _buserror.w,a4  /* buserrorvektor sichern */
                move.l  #bomb_fa6,_buserror.w   /* buserrorvektor setzen */
                move.l  sp,a5           /* stack sichern */
                move.l  _proc_enum.w,a6 /* pc laden */
                move.l  -4(a6),d2       /* werte vor pc stand */
                bsr.s   reg_aus
                move.l  (a6),d2         /* werte bei pc stand */
                bsr.s   reg_aus
bomb_fa6:
                move.l  a4,_buserror.w  /* alter buserrorvektor */
                move.l  a5,sp           /* alter stack */
                lea     tb3(pc),a0      /* zeiger auf text */
                lea     _proc_dregs.w,a1  /* zeiger auf registerwerte */
                moveq   #2,d4           /* daten,adressregister und stack */
bomb_fa8:
                bsr.s   string_out      /* text ausgeben */
                moveq   #7,d3           /* 8 register */
bomb_fa7:
                move.l  (a1)+,d2        /* wert holen */
                bsr.s   reg_aus         /* und ausgeben */
                dbra    d3,bomb_fa7     /*  */
                subq.l  #1,d4           /* -1 */
                bgt.s   bomb_fa8        /* >0 wiederholen */
                lea     _proc_stk.w,a1  /* zeiger auf stackwert */
                beq.s   bomb_fa8        /* =0->wiederholen */
                lea     tb4(pc),a0      /* zeiger auf text */
                bsr.s   string_out      /* text ausgeben */
                move    #$2300,sr       /* Interrupts erlauben */
                move.w  #2,-(sp)        /* tastatur */
                move.w  #2,-(sp)
                trap    #13             /* auf tastendruck warten */
                addq.l  #4,sp           /* stack korrigieren */
exitcrash:
                move.l  #$093A,$04A2.w  /* BIOS-Stackpointer zuruecksetzen */
                move.l  #$4CFFFF,-(sp)  /*  */
                trap    #1              /* Pterm(-1) versuchen */
                jmp     coldboot        /* RESET, wenn misslungen */

reg_aus:
                moveq   #7,d0
reg_aus1:
                rol.l   #4,d2           /* next hex zahl */
                move.b  d2,d6
                andi.b  #$0F,d6         /* nur 4 bits werden gebraucht */
                addi.b  #'0',d6         /* + ascii 0 */
                cmpi.b  #'9',d6         /* <=9? */
                ble.s   reg_aus2        /* ja,ok-> */
                addi.b  #'A'-'9'-1,d6   /* sonst differenz zuaddieren */
reg_aus2:
                bsr.s   zei_out         /* ausgeben */
                dbra    d0,reg_aus1     /* wiederholen bis fertig */
                moveq   #32,d6
                bra.s   zei_out         /* ein leerschlag */

string_out:
                move.b  (a0)+,d6        /* zeichen holen */
                bne.s   str_out1        /* fertig? nein-> */
                rts                     /* zurueck */
str_out1:
                bsr.s   zei_out         /* zeichen out */
                bra.s   string_out      /* und von vorn */

zei_out:
                movem.l d0-d4/a0-a1,-(sp) /* register sichern */
                andi.w  #$FF,d6         /* nur bytwert */
                move.w  d6,-(sp)        /* zeichen */
                move.w  #2,-(sp)        /* bildschirm */
                move.w  #3,-(sp)
                trap    #13             /* zeichen ausgeben */
                addq.l  #6,sp
                movem.l (sp)+,d0-d4/a0-a1 /* register zurueck */
                rts

tb1:            DC.B 27,'H',10,10,10,10,10,10,27,'p',27,'KException ausgel',$94,'st durch: ',0
tb2:            DC.B 10,13,27,'K',10,13,27,'KPC=',0,' SR=',0,' USP=',0,' Formatword=',0,' (PC-4)=',0
tb3:            DC.B 10,13,27,'KD0-D7=',0,10,13,27,'KA0-A7=',0,10,13,27,'KStack=',0
tb4:            DC.B 10,13,27,'K',10,13,27,'K**--> Dr',$81,'cke Taste!',27,'q',0
tbuv:           DC.B 'Vector Nummer $',0
tbev:           DC.B 'Acess Fault!',0 /* THO: typo */
                DC.B 'Adress Error!',0 /* THO: typo */
                DC.B 'Illegal Instruction!',0
                DC.B 'Integer Divide by Zero!',0
                DC.B 'CHK, CHK2 Instruction!',0
                DC.B 'FTRAPcc, TRAPcc, TRAPV Instruction!',0
                DC.B 'Privileg Violation!',0
                DC.B 'Trace!',0
                DC.B 'Line A!',0
                DC.B 'Line F!',0
                DC.B 'Unassigned!',0
                DC.B 'Coprocessor Protocol Violation!',0
                DC.B 'Format Error!',0
                DC.B 'Uninitialized Interrupt!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Unassigned, Reserved!',0
                DC.B 'Spurious Interrupt!',0
                DC.B 'Level 1 Interrupt Autovektor!',0
                DC.B 'Level 2 Interrupt Autovektor!',0
                DC.B 'Level 3 Interrupt Autovektor!',0
                DC.B 'Level 4 Interrupt Autovektor!',0
                DC.B 'Level 5 Interrupt Autovektor!',0
                DC.B 'Level 6 Interrupt Autovektor!',0
                DC.B 'Level 7 Interrupt Autovektor!',0
                DC.B 'Trap #0 Instruction Vector!',0
                DC.B 'Trap #1 Instruction Vector!',0
                DC.B 'Trap #2 Instruction Vector!',0
                DC.B 'Trap #3 Instruction Vector!',0
                DC.B 'Trap #4 Instruction Vector!',0
                DC.B 'Trap #5 Instruction Vector!',0
                DC.B 'Trap #6 Instruction Vector!',0
                DC.B 'Trap #7 Instruction Vector!',0
                DC.B 'Trap #8 Instruction Vector!',0
                DC.B 'Trap #9 Instruction Vector!',0
                DC.B 'Trap #10 Instruction Vector!',0
                DC.B 'Trap #11 Instruction Vector!',0
                DC.B 'Trap #12 Instruction Vector!',0
                DC.B 'Trap #13 Instruction Vector!',0
                DC.B 'Trap #14 Instruction Vector!',0
                DC.B 'Trap #15 Instruction Vector!',0
                DC.B 'FP Branch or Set on Unordered Condition!',0
                DC.B 'FP Inexact Result!',0
                DC.B 'FP Divide by Zero!',0
                DC.B 'FP Underflow!',0
                DC.B 'FP Operand Error!',0
                DC.B 'FP Overflow!',0
                DC.B 'FP Signaling NAN!',0
                DC.B 'FP Unimplemented Data Typ!',0

#endif
