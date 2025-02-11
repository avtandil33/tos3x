#include "../common/hades.inc"

/* origin where this routines are actually executed */
#ifndef mach64_org
#define mach64_org $300000
#endif
#ifndef MACH64_PCI
#define MACH64_PCI 0
#endif

#if MACH64_PCI
#define vga_base pci_vga_base
#define vga_reg  pci_vga_reg
#else
#define vga_base isa_vga_base
#define vga_reg  isa_vga_reg+$10000
#endif


#define mach64_off mach64_org-mach64_isa_init

mach64_isa_init:
		suba.l     a0,a0
		bsr        x100f2
		lea.l      x117c6+mach64_off,a0
		clr.w      d0
		bsr.w      x10026
		lea.l      x117c9+mach64_off,a0
		moveq.l    #1,d0
		bsr.w      x10026
		lea.l      vga_base+$A0000,a0
		rts

x10026:
		move.b     d0,vga_reg+$5EEC
		clr.w      d0
		bra.s      x10026_1
x10026_2:
		addq.w     #1,d0
x10026_1:
		cmp.w      #1,d0
		blt.s      x10026_2
		move.b     (a0)+,vga_reg+$5EED
		clr.w      d0
		bra.s      x10026_3
x10026_4:
		addq.w     #1,d0
x10026_3:
		cmp.w      #1,d0
		blt.s      x10026_4
		move.b     (a0)+,vga_reg+$5EED
		clr.w      d0
		bra.s      x10026_5
x10026_6:
		addq.w     #1,d0
x10026_5:
		cmp.w      #1,d0
		blt.s      x10026_6
		move.b     (a0)+,vga_reg+$5EED
		rts

x10064:
		movem.l    d3-d6,-(a7)
		move.b     d1,d3
		bra.s      x10064_1
x10064_2:
		move.b     d3,0(a0,d0.w)
		move.b     (a1)+,1(a0,d0.w)
		addq.b     #1,d3
x10064_1:
		move.b     d3,d4
		ext.w      d4
		move.b     d1,d5
		ext.w      d5
		move.b     d2,d6
		ext.w      d6
		add.w      d6,d5
		cmp.w      d5,d4
		blt.s      x10064_2
		movem.l    (a7)+,d3-d6
		rts

x1008e:
		clr.b      $83C4(a0)
		move.b     #1,$83C5(a0)
		clr.b      $83C4(a0)
		move.b     #3,$83C5(a0)
		rts

x100a4:
		move.l     d4,-(a7)
		move.w     d0,d4
		move.w     d1,d0
		moveq.l    #8,d1
		rol.w      d1,d0
		movea.l    vga_reg_ptr+mach64_off,a0
		move.w     d0,0(a0,d4.w)
		move.l     (a7)+,d4
		rts

x100bc:
		moveq.l    #8,d1
		movea.l    vga_reg_ptr+mach64_off,a0
		move.w     0(a0,d0.w),d0
		rol.w      d1,d0
		rts

x100cc:
		movea.l    vga_reg_ptr+mach64_off,a0
		move.b     d1,0(a0,d0.w)
		rts

x100d8:
		movea.l    vga_reg_ptr+mach64_off,a0
		move.b     0(a0,d0.w),d0
		rts

x100e4:
		move.w     #$E2EE,d0
		bsr.w      x100d8
		and.b      #$07,d0
		rts

x100f2:
		move.l     a2,-(a7)
		move.l     a3,-(a7)
		movea.l    a0,a3
		move.w     x118ae+mach64_off,d0
		beq.w      x100f2_1
		suba.l     a0,a0
#if MACH64_PCI
/*
 * Note: logic here will find *last* card,
 * while logic in pcm64t finds *first* card.
 */
 		movea.l    a0,a1
		movea.l    #pci_conf1+2,a2
		cmpi.w     #$5847,(a2)
		bne.s      test_pci_2
		movea.l    #pci_conf1+4,a0
		movea.l    #pci_conf1+16,a1
test_pci_2:
		movea.l    #pci_conf2+2,a2
		cmpi.w     #$5847,(a2)
		bne.s      test_pci_3
		movea.l    #pci_conf2+4,a0
		movea.l    #pci_conf2+16,a1
test_pci_3:
		movea.l    #pci_conf3+2,a2
		cmpi.w     #$5847,(a2)
		bne.s      test_pci_4
		movea.l    #pci_conf3+4,a0
		movea.l    #pci_conf3+16,a1
test_pci_4:
		movea.l    #pci_conf4+2,a2
		cmpi.w     #$5847,(a2)
		bne.s      test_pci_5
		movea.l    #pci_conf4+4,a0
		movea.l    #pci_conf4+16,a1
test_pci_5:
		/* THO: BUG: a0/a1 are zero if no card found */
		move.b     #3,(a0)
		clr.l      (a1)
#endif
		move.l     #vga_reg+$8000,vga_reg_ptr+mach64_off
		bsr        x10b2e
		clr.b      d0
		bsr        x11224
		clr.w      x118ae+mach64_off
x100f2_1:
		move.l     a3,d0
		bne.s      x100f2_2
		lea.l      x117ce+mach64_off,a3
x100f2_2:
		movea.l    vga_reg_ptr+mach64_off,a1
		movea.l    a3,a0
		bsr        x11244
		bsr        x10a02
		movea.l    a3,a0
		movea.l    (a7)+,a3
		movea.l    (a7)+,a2
		rts

x10140:
		rts

x10142:
		move.l     d3,-(a7)
		move.l     a2,-(a7)
		move.b     #$F1,d1
		move.w     #$CEEC,d0
		bsr        x100cc
		moveq.l    #32,d1
		move.w     #$CEED,d0
		bsr        x100cc
		clr.w      d3
		lea.l      x118b0+mach64_off,a2
		bra.s      x10142_1
x10142_2:
		dc.w $3232,$3202		/* move.w     2(a2,d3.w*2),d1 68020+ only */
		dc.w $3032,$3200		/* move.w     0(a2,d3.w*2),d0 68020+ only */
		bsr        x100a4
		addq.w     #2,d3
x10142_1:
		dc.w $3032,$3200		/* move.w     0(a2,d3.w*2),d0 68020+ only */
		bne.s      x10142_2
		clr.b      d1
		move.w     #$9EEF,d0
		bsr        x100cc
		movea.l    (a7)+,a2
		move.l     (a7)+,d3
		rts

x1018a:
		move.w     #$DEEC,d0
		bsr        x100d8
		rts

x10194:
		move.l     d3,-(a7)
		move.w     #$9EEF,d0
		bsr        x100d8
		move.b     d0,d3
		moveq.l    #1,d1
		or.b       d0,d1
		move.w     #$9EEF,d0
		bsr        x100cc
		move.b     d3,d0
		move.l     (a7)+,d3
		rts

x101b2:
		move.l     d3,-(a7)
		move.b     d0,d3
		bsr.w      x1018a
		move.b     d3,d1
		move.w     #$9EEF,d0
		bsr        x100cc
		move.l     (a7)+,d3
		rts

x101c8:
		movem.l    d3-d5,-(a7)
		move.b     d0,d5
		move.w     d1,d3
		move.w     d1,d0
		bsr.w      x10238
		move.w     d0,d3
		clr.b      d1
		move.w     #$CAEC,d0
		bsr        x100cc
		bsr        x10304
		moveq.l    #1,d1
		move.w     #$CAEC,d0
		bsr        x100cc
		bsr        x10304
		moveq.l    #1,d0
		bsr        x10320
		clr.b      d0
		bsr        x10320
		clr.b      d0
		bsr        x10320
		clr.w      d4
		bra.s      x101c8_1
x101c8_2:
		moveq.l    #1,d0
		and.b      d5,d0
		bsr        x10320
		asr.b      #1,d5
		addq.w     #1,d4
x101c8_1:
		cmp.w      #5,d4
		bcs.s      x101c8_2
		clr.w      d4
		bra.s      x101c8_3
x101c8_4:
		moveq.l    #1,d0
		and.b      d3,d0
		bsr        x10320
		lsr.w      #1,d3
		addq.w     #1,d4
x101c8_3:
		cmp.w      #$000D,d4
		bcs.s      x101c8_4
		movem.l    (a7)+,d3-d5
		rts

x10238:
		move.l     d3,-(a7)
		lea.l      x119fe+mach64_off,a0
		cmp.w      (a0),d0
		bcc.s      x10238_1
		move.w     (a0),d0
x10238_1:
		cmp.w      x11a00-x119fe(a0),d0
		bls.s      x10238_2
		move.w     x11a00-x119fe(a0),d0
x10238_2:
		moveq.l    #3,d1
		bra.s      x10238_3
x10238_4:
		add.w      d0,d0
		subq.w     #1,d1
x10238_3:
		move.w     (a0),d2
		lsl.w      #3,d2
		cmp.w      d2,d0
		bcs.s      x10238_4
		cmp.w      x11a00-x119fe(a0),d0
		bls.s      x10238_5
		move.w     x11a00-x119fe(a0),d0
x10238_5:
		moveq.l    #0,d2
		move.w     d0,d2
		move.l     d2,d0
		move.l     d0,d2
		move.w     x11a02-x119fe(a0),d3
		ext.l      d3
		dc.w $4c03,$2002		/* mulu.l     d3,d2 68020+ only */
		move.l     d2,d0
		move.w     x118a2+mach64_off,d2
		asr.w      #1,d2
		ext.l      d2
		add.l      d2,d0
		move.l     d0,d3
		move.w     x118a2+mach64_off,d2
		ext.l      d2
		dc.w $4c42,$3003		/* divul.l    d2,d3:d3 68020+ only */
		move.l     d3,d0
		cmp.w      x11a04-x119fe(a0),d0
		bls.s      x10238_6
		sub.w      x11a04-x119fe(a0),d0
		bra.s      x10238_7
x10238_6:
		clr.w      d0
x10238_7:
		and.w      #$00FF,d0
		move.w     d1,d2
		moveq.l    #9,d3
		lsl.w      d3,d2
		or.w       d2,d0
		or.w       #$1800,d0
		move.l     (a7)+,d3
		rts

x102bc:
		move.l     d3,-(a7)
		move.b     d0,d3
		move.w     #$CAEC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$FB,d1
		move.b     d3,d0
		lsl.b      #2,d0
		or.b       d0,d1
		move.w     #$CAEC,d0
		bsr        x100cc
		move.l     (a7)+,d3
		rts

x102e0:
		move.l     d3,-(a7)
		move.b     d0,d3
		move.w     #$CAEC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$F7,d1
		move.b     d3,d0
		lsl.b      #3,d0
		or.b       d0,d1
		move.w     #$CAEC,d0
		bsr        x100cc
		move.l     (a7)+,d3
		rts

x10304:
		bsr.w      x10378
		move.w     #$CAEC,d0
		bsr        x100d8
		move.b     d0,d1
		or.b       #$40,d1
		move.w     #$CAEC,d0
		bsr        x100cc
		rts

x10320:
		bsr.w      x102bc
		clr.b      d0
		bsr.w      x102e0
		bsr.w      x10304
		moveq.l    #1,d0
		bsr.w      x102e0
		bsr.w      x10304
		rts

x1033a:
		move.l     d3,-(a7)
		move.w     #$CAEC,d0
		bsr        x100d8
		move.b     d0,d3
		clr.b      d1
		move.w     #$CAEC,d0
		bsr        x100cc
		move.b     d3,d0
		move.l     (a7)+,d3
		rts

x10356:
		moveq.l    #64,d1
		or.b       d0,d1
		move.w     #$CAEC,d0
		bsr        x100cc
		rts

x10364:
		tst.w      d0
		beq.s      x10364_1
		mulu.w     #$07D0,d0
x10364_2:
		tst.b      $FFFFFC00
		subq.l     #1,d0
		bgt.s      x10364_2
x10364_1:
		rts

x10378:
		clr.w      d0
		bsr.w      x10364
		rts

x10380:
		moveq.l    #1,d0
		bsr.w      x10364
		rts

x10388:
		moveq.l    #15,d0
		bsr.w      x10364
		rts

x10390:
		movem.l    d3-d7/a2,-(a7)
		move.b     d0,d6
		move.w     d1,d5
		cmpi.w     #1,x11a0a+mach64_off
		bne.s      x10390_1
		bsr.w      x1033a
		move.b     d0,d3
		bsr        x10194
		move.b     d0,d4
		bsr.w      x10388
		move.w     d5,d1
		move.b     d6,d0
		bsr        x101c8
		bsr.w      x10380
		bra        x10390_2
x10390_1:
		cmpi.w     #3,x11a0a+mach64_off
		bne        x10390_3
		bsr        x1033a
		move.b     d0,d3
		bsr        x10194
		move.b     d0,d4
		moveq.l    #0,d1
		move.w     d5,d1
		divu.w     #$0064,d1
		move.w     d1,d5
		clr.w      d7
		lea.l      x118e8+mach64_off,a2
		bra.s      x10390_4
x10390_5:
		addq.w     #2,d7
x10390_4:
		dc.w $ba72,$7200			/* cmp.w      0(a2,d7.w*2),d5 68020+ only */
		bhi.s      x10390_5
		dc.w $3032,$7200			/* move.w     0(a2,d7.w*2),d0 68020+ only */
		sub.w      d5,d0
		move.w     d5,d1
		dc.w $9272,$72fc			/* sub.w      -4(a2,d7.w*2),d1 68020+ only */
		cmp.w      d1,d0
		bls.s      x10390_6
		subq.w     #2,d7
x10390_6:
		cmp.b      #$10,d6
		ble.s      x10390_7
		moveq.l    #16,d6
x10390_7:
		moveq.l    #1,d1
		move.w     #$E2EC,d0
		bsr        x100cc
		move.b     d6,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		dc.w $1232,$7203			/* move.b     3(a2,d7.w*2),d1 68020+ only */
		move.w     #$DEED,d0
		bsr        x100cc
		dc.w $3232,$7202			/* move.w     2(a2,d7.w*2),d1 68020+ only */
		lsr.w      #8,d1
		move.w     #$DEED,d0
		bsr        x100cc
		cmp.b      #$10,d6
		bge.s      x10390_8
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.b     #$80,d1
		or.b       d6,d1
		move.w     #$DEEC,d0
		bsr        x100cc
x10390_8:
		clr.b      d1
		move.w     #$E2EC,d0
		bsr        x100cc
x10390_2:
		move.b     d4,d0
		bsr        x101b2
		move.b     d3,d0
		bsr        x10356
x10390_3:
		movem.l    (a7)+,d3-d7/a2
		rts

x10496:
		movem.l    d3-d5,-(a7)
		move.b     d0,d5
		bsr        x1033a
		move.b     d0,d3
		bsr        x10194
		move.b     d0,d4
		moveq.l    #1,d1
		move.w     #$E2EC,d0
		bsr        x100cc
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEC,d0
		bsr        x100d8
		move.b     d5,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$E2EC,d0
		bsr        x100cc
		move.b     d4,d0
		bsr        x101b2
		move.b     d3,d0
		bsr        x10356
		movem.l    (a7)+,d3-d5
		rts

x10500:
		movem.l    d3-d5/a2,-(a7)
		lea.l      x11a06+mach64_off,a2
		move.w     #$0433,x119fe-x11a06(a2)
		move.w     #$4268,x11a00-x11a06(a2)
		move.w     #$0598,x118a2+mach64_off
		move.w     #$002E,x11a02-x11a06(a2)
		move.w     #$0101,x11a04-x11a06(a2)
		move.l     #x1197c+mach64_off,(a2)
		bsr        x1033a
		move.b     d0,d3
		bsr        x10194
		move.b     d0,d4
		bsr        x10388
		clr.w      d5
		bra.s      x10500_1
x10500_2:
		movea.l    (a2),a0
		dc.w $3230,$5200		/* move.w     0(a0,d5.w*2),d1 68020+ only */
		move.b     d5,d0
		bsr        x101c8
		addq.w     #1,d5
x10500_1:
		cmp.w      #$0010,d5
		blt.s      x10500_2
		movea.l    (a2),a0
		move.w     36(a0),d1
		moveq.l    #18,d0
		bsr        x101c8
		cmpi.b     #$05,x11a0e-x11a06(a2)
		bne.s      x10500_3
		move.w     #$1568,d1
		moveq.l    #19,d0
		bsr        x10390
		bra.s      x10500_4
x10500_3:
		move.w     #$125C,d1
		moveq.l    #19,d0
		bsr        x10390
x10500_4:
		move.b     d4,d0
		bsr        x101b2
		move.b     d3,d0
		bsr        x10356
		movem.l    (a7)+,d3-d5/a2
		rts

x10594:
		move.w     #$F2EC,d0
		bsr        x100d8
		clr.w      d1
		move.b     d0,d1
		move.w     d1,d0
		asr.w      #3,d0
		and.w      #3,d0
		cmp.w      #3,d0
		beq.s      x10594_1
		cmp.w      #1,d0
		bne.s      x10594_2
x10594_1:
		moveq.l    #1,d0
		rts
x10594_2:
		clr.w      d0
		rts

x105bc:
		movem.l    d3-d5,-(a7)
		move.w     d0,d4
		move.w     d1,d3
		move.w     #$D2EC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$F8,d1
		moveq.l    #7,d0
		and.b      d4,d0
		or.b       d0,d1
		move.w     #$D2EC,d0
		bsr        x100cc
		clr.w      d1
		move.w     #$C2EC,d0
		bsr        x100a4
		move.w     d3,d1
		move.w     #$C2EE,d0
		bsr        x100a4
		move.w     #$1234,d4
		move.w     d4,d1
		move.w     #$C6EC,d0
		bsr        x100a4
		move.w     #$E6EE,d0
		bsr        x100bc
		move.w     d0,d5
		and.w      #$FC8F,d5
		or.w       #$0310,d5
		move.w     d5,d1
		move.w     #$E6EE,d0
		bsr        x100a4
		clr.w      d1
		move.w     #$C2EC,d0
		bsr        x100a4
		move.w     d3,d1
		move.w     #$C2EE,d0
		bsr        x100a4
		move.w     #$E6EE,d0
		bsr        x100bc
		move.w     d0,d5
		and.w      #$FC8F,d5
		or.w       #$0210,d5
		move.w     d5,d1
		move.w     #$E6EE,d0
		bsr        x100a4
		move.w     #$C6EC,d0
		bsr        x100bc
		cmp.w      d0,d4
		beq.s      x105bc_1
		clr.w      d0
		bra.s      x105bc_2
x105bc_1:
		moveq.l    #1,d0
x105bc_2:
		movem.l    (a7)+,d3-d5
		rts

x10666:
		clr.w      d0
		movea.l    #vga_base+$400000,a0
		bra.s      x10666_1
x10666_2:
		move.b     #$55,(a0)+
		addq.w     #1,d0
x10666_1:
		cmp.w      #10,d0
		blt.s      x10666_2
		clr.w      d0
		movea.l    #vga_base+$400000,a0
		bra.s      x10666_3
x10666_5:
		cmpi.b     #$55,(a0)+
		bne.s      x10666_4
		addq.w     #1,d0
x10666_3:
		cmp.w      #10,d0
		blt.s      x10666_5
		clr.w      d0
		movea.l    #vga_base+$400000,a0
		bra.s      x10666_6
x10666_7:
		move.b     #$AA,(a0)+
		addq.w     #1,d0
x10666_6:
		cmp.w      #10,d0
		blt.s      x10666_7
		clr.w      d0
		movea.l    #vga_base+$400000,a0
		bra.s      x10666_8
x10666_10:
		cmpi.b     #$AA,(a0)+
		beq.s      x10666_9
x10666_4:
		clr.w      d0
		rts
x10666_9:
		addq.w     #1,d0
x10666_8:
		cmp.w      #10,d0
		blt.s      x10666_10
		moveq.l    #1,d0
		rts

x106ca:
		clr.w      d0
		movea.l    #vga_base+$600000,a0
		bra.s      x106ca_1
x106ca_2:
		move.b     #$55,(a0)+
		addq.w     #1,d0
x106ca_1:
		cmp.w      #10,d0
		blt.s      x106ca_2
		clr.w      d0
		movea.l    #vga_base+$600000,a0
		bra.s      x106ca_3
x106ca_5:
		cmpi.b     #$55,(a0)+
		bne.s      x106ca_4
		addq.w     #1,d0
x106ca_3:
		cmp.w      #10,d0
		blt.s      x106ca_5
		clr.w      d0
		movea.l    #vga_base+$600000,a0
		bra.s      x106ca_6
x106ca_7:
		move.b     #$AA,(a0)+
		addq.w     #1,d0
x106ca_6:
		cmp.w      #10,d0
		blt.s      x106ca_7
		clr.w      d0
		movea.l    #vga_base+$600000,a0
		bra.s      x106ca_8
x106ca_10:
		cmpi.b     #$AA,(a0)+
		beq.s      x106ca_9
x106ca_4:
		clr.w      d0
		rts
x106ca_9:
		addq.w     #1,d0
x106ca_8:
		cmp.w      #10,d0
		blt.s      x106ca_10
		moveq.l    #1,d0
		rts

x1072e:
		move.l     d3,-(a7)
		move.l     a2,-(a7)
		clr.w      d3
		moveq.l    #8,d1
		moveq.l    #5,d0
		bsr        x105bc
		move.w     d0,d3
		tst.w      d3
		bne.s      x1072e_1
		moveq.l    #6,d1
		moveq.l    #4,d0
		bsr        x105bc
		move.w     d0,d3
x1072e_1:
		tst.w      d3
		bne.s      x1072e_2
		bsr        x10594
		tst.w      d0
		bne.s      x1072e_2
		moveq.l    #4,d1
		moveq.l    #3,d0
		bsr        x105bc
		move.w     d0,d3
x1072e_2:
		tst.w      d3
		bne.s      x1072e_3
		moveq.l    #2,d1
		moveq.l    #2,d0
		bsr        x105bc
		move.w     d0,d3
x1072e_3:
		tst.w      d3
		bne.s      x1072e_4
		moveq.l    #1,d1
		moveq.l    #1,d0
		bsr        x105bc
		move.w     d0,d3
x1072e_4:
		move.w     #$E6EE,d0
		bsr        x100bc
		move.w     d0,d3
		and.w      #$FC8F,d3
		lea.l      x119fa+mach64_off,a2
		cmpi.b     #$05,x11a0e-x119fa(a2)
		bne.s      x1072e_5
		move.w     #$D2EC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$F8,d1
		or.b       #3,d1
		move.w     #$D2EC,d0
		bsr        x100cc
		move.l     #$00400000,(a2)
		bsr        x106ca
		tst.w      d0
		bne.s      x1072e_6
		move.w     #$D2EC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$F8,d1
		or.b       #2,d1
		move.w     #$D2EC,d0
		bsr        x100cc
		move.l     #$00200000,(a2)
		bra.s      x1072e_6
x1072e_5:
		move.w     #$D2EC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$F8,d1
		or.b       #2,d1
		move.w     #$D2EC,d0
		bsr        x100cc
		move.l     #$00200000,(a2)
		tst.w      d0
		bne.s      x1072e_7
		move.w     #$D2EC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$F8,d1
		or.b       #1,d1
		move.w     #$D2EC,d0
		bsr        x100cc
		move.l     #$00100000,(a2)
x1072e_7:
		ori.b      #$03,x11a11-x119fa(a2)
x1072e_6:
		move.w     d3,d1
		move.w     #$E6EE,d0
		bsr        x100a4
		clr.w      d1
		move.w     #$C2EC,d0
		bsr        x100a4
		clr.w      d1
		move.w     #$C2EE,d0
		bsr        x100a4
		clr.w      d1
		move.w     #$C6EC,d0
		bsr        x100a4
		clr.w      d1
		move.w     #$C6EE,d0
		bsr        x100a4
		movea.l    (a7)+,a2
		move.l     (a7)+,d3
		rts

x10866:
		moveq.l    #22,d1
		move.w     #$C6E8,d0
		bsr        x100cc
		moveq.l    #1,d1
		move.w     #$8102,d0
		bsr        x100cc
		moveq.l    #14,d1
		move.w     #$C6E8,d0
		bsr        x100cc
		rts

x10886:
		moveq.l    #80,d1
		move.w     #$83CE,d0
		bsr        x100cc
		move.b     #$CE,d1
		move.w     #$83CF,d0
		bsr        x100cc
		moveq.l    #81,d1
		move.w     #$83CE,d0
		bsr        x100cc
		move.b     #$81,d1
		move.w     #$83CF,d0
		bsr        x100cc
		rts

x108b4:
		moveq.l    #1,d1
		move.w     #$83C4,d0
		bsr        x100cc
		moveq.l    #32,d1
		move.w     #$83C5,d0
		bsr        x100cc
		rts

x108ca:
		moveq.l    #4,d1
		move.w     #$83C2,d0
		bsr        x100cc
		move.w     #$83DA,d0
		bsr        x100d8
		move.w     #$83BA,d0
		bsr        x100d8
		clr.b      d1
		move.w     #$83C0,d0
		bsr        x100cc
		bsr.w      x108b4
		move.b     #$A0,d1
		move.w     #$81CE,d0
		bsr        x100cc
		moveq.l    #72,d1
		move.w     #$81CF,d0
		bsr        x100cc
		moveq.l    #29,d1
		move.w     #$83C6,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$83C7,d0
		bsr        x100cc
		moveq.l    #2,d1
		move.w     #$83C8,d0
		bsr        x100cc
		move.b     #$A0,d1
		move.w     #$81CE,d0
		bsr        x100cc
		moveq.l    #104,d1
		move.w     #$81CF,d0
		bsr        x100cc
		moveq.l    #97,d1
		move.w     #$83C8,d0
		bsr        x100cc
		move.b     #$A0,d1
		move.w     #$81CE,d0
		bsr        x100cc
		moveq.l    #8,d1
		move.w     #$81CF,d0
		bsr        x100cc
		moveq.l    #1,d1
		move.w     #$9EEF,d0
		bsr        x100cc
		moveq.l    #3,d1
		move.w     #$E2EC,d0
		bsr        x100cc
		moveq.l    #97,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		moveq.l    #2,d1
		move.w     #$E2EC,d0
		bsr        x100cc
		moveq.l    #29,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		move.b     #$80,d1
		move.w     #$DEEF,d0
		bsr        x100cc
		moveq.l    #2,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		moveq.l    #3,d1
		move.w     #$E2EC,d0
		bsr        x100cc
		moveq.l    #101,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$E2EC,d0
		bsr        x100cc
		moveq.l    #32,d1
		move.w     #$E2ED,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$9EEF,d0
		bsr        x100cc
		moveq.l    #77,d1
		move.w     #$CAEC,d0
		bsr        x100cc
		move.b     #$FF,d1
		move.w     #$83C6,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$83C8,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$83C9,d0
		bsr        x100cc
		rts

x10a02:
		move.l     a2,-(a7)
		movea.l    #vga_base+$BFC00,a2
		move.w     #$CEEC,d0
		bsr        x100bc
		move.w     d0,d1
		or.w       #$00A0,d1
		move.w     #$CEEC,d0
		bsr        x100a4
		clr.b      d1
		move.w     #$E6ED,d0
		bsr        x100cc
		moveq.l    #1,d1
		move.w     #$E6ED,d0
		bsr        x100cc
		move.l     #$FFFFFFFF,712(a2)
		clr.l      776(a2)
		movea.l    (a7)+,a2
		rts

x10a44:
		movem.l    d3-d4/a2,-(a7)
		lea.l      x11a0e+mach64_off,a2
		bsr        x100e4
		move.b     d0,(a2)
		subq.b     #7,d0
		bne.s      x10a44_1
		bsr        x1033a
		move.b     d0,d3
		bsr        x10194
		move.b     d0,d4
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		cmp.b      #$C0,d0
		bne.s      x10a44_2
		clr.b      (a2)
x10a44_2:
		move.b     d4,d0
		bsr        x101b2
		move.b     d3,d0
		bsr        x10356
x10a44_1:
		cmpi.b     #05,(a2)
		bne        x10a44_3
		bsr        x10194
		move.b     d0,d4
		moveq.l    #1,d0
		bsr        x10ba2
		clr.b      d1
		move.w     #$DEEC,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$DEED,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$DEED,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$DEED,d0
		bsr        x100cc
		move.b     #$FF,d1
		move.w     #$DEED,d0
		bsr        x100cc
		move.b     #$FF,d1
		move.w     #$DEED,d0
		bsr        x100cc
		move.b     #$FF,d1
		move.w     #$DEED,d0
		bsr        x100cc
		moveq.l    #2,d0
		bsr        x10ba2
		move.b     #$80,d1
		move.w     #$DEED,d0
		bsr        x100cc
		moveq.l    #2,d0
		bsr        x10ba2
		move.b     #$EC,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		clr.b      d0
		bsr        x10ba2
		move.b     d4,d0
		bsr        x101b2
x10a44_3:
		movem.l    (a7)+,d3-d4/a2
		rts

x10b2e:
		bsr        x10866
		bsr        x10142
		bsr        x10a44
		bsr        x10886
		move.b     #$B9,d1
		move.w     #$81CE,d0
		bsr        x100cc
		moveq.l    #64,d1
		move.w     #$81CF,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$CAE8,d0
		bsr        x100cc
		bsr        x10866
		bsr        x108ca
		move.w     #1,x11a0a+mach64_off
		bsr        x10500
		bsr        x1072e
		bsr        x10140
		cmpi.b     #7,x11a0e+mach64_off
		bne.s      x10b2e_1
		bsr        x11564
		move.b     d0,x11a12+mach64_off
		rts
x10b2e_1:
		move.b     x11a0e+mach64_off,d0
		bne.s      x10b2e_2
		move.w     #3,x11a0a+mach64_off
x10b2e_2:
		rts

x10ba2:
		move.l     d3,-(a7)
		move.b     d0,d3
		move.w     #$E2EC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$FC,d1
		or.b       d3,d1
		move.w     #$E2EC,d0
		bsr        x100cc
		move.l     (a7)+,d3
		rts

x10bc2:
		move.w     #$D2EC,d0
		bsr        x100d8
		and.b      #$07,d0
		rts

x10bd0:
		movem.l    d3-d4/a2,-(a7)
		move.b     d1,d3
		lea.l      x119a4+mach64_off,a0
		clr.w      d1
		move.b     d0,d1
		dc.w $45f0,$1200			/* lea.l      0(a0,d1.w*2),a2 68020+ only */
		move.b     #$80,d0
		and.b      d3,d0
		beq.s      x10bd0_1
		lea.l      x119b2-x119a4(a0),a2
x10bd0_1:
		moveq.l    #3,d0
		bsr.w      x10ba2
		move.w     #$DEEC,d0
		bsr        x100d8
		move.b     d0,d1
		and.b      #$FD,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		moveq.l    #2,d0
		bsr.w      x10ba2
		moveq.l    #29,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		move.b     (a2),d4
		moveq.l    #96,d0
		and.b      d4,d0
		beq.s      x10bd0_2
		moveq.l    #16,d1
		and.b      d3,d1
		beq.s      x10bd0_2
		or.b       #$10,d4
x10bd0_2:
		move.b     d4,d1
		move.w     #$DEEF,d0
		bsr        x100cc
		moveq.l    #2,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		moveq.l    #3,d0
		bsr        x10ba2
		bsr        x10bc2
		clr.w      d1
		move.b     d0,d1
		move.w     d1,d0
		cmp.w      #1,d0
		bge.s      x10bd0_3
		moveq.l    #4,d1
		bra.s      x10bd0_4
x10bd0_3:
		cmp.w      #1,d0
		bne.s      x10bd0_5
		moveq.l    #8,d1
		bra.s      x10bd0_4
x10bd0_5:
		moveq.l    #12,d1
x10bd0_4:
		move.b     1(a2),d4
		moveq.l    #16,d0
		and.b      d3,d0
		beq.s      x10bd0_6
		and.b      #$FE,d4
x10bd0_6:
		move.w     #$DEEC,d0
		bsr        x100d8
		move.b     #$EC,d1
		move.w     #$DEEC,d0
		bsr        x100cc
		clr.b      d0
		bsr        x10ba2
		movem.l    (a7)+,d3-d4/a2
		rts

x10c96:
		move.w     #$DEEC,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		move.w     #$DEEE,d0
		bsr        x100d8
		rts

x10cc0:
		movem.l    d3/a2-a3,-(a7)
		move.b     d1,d3
		movea.l    a0,a2
		moveq.l    #0,d2
		move.b     d0,d2
		lea.l      0(a2,d2.l),a3
		cmpi.b     #$FF,(a3)
		bne.s      x10cc0_1
		bsr.w      x10c96
		moveq.l    #25,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		bra        x10cc0_2
x10cc0_1:
		moveq.l    #32,d0
		and.b      d3,d0
		beq.s      x10cc0_3
		lea.l      7(a2),a3
x10cc0_3:
		bsr.w      x10c96
		moveq.l    #16,d0
		and.b      d3,d0
		beq.s      x10cc0_4
		moveq.l    #26,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		bra.s      x10cc0_5
x10cc0_4:
		moveq.l    #24,d1
		move.w     #$DEEE,d0
		bsr        x100cc
x10cc0_5:
		bsr.w      x10c96
		move.w     #$DEEE,d0
		bsr        x100d8
		moveq.l    #3,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		clr.b      d1
		move.w     #$DEEE,d0
		bsr        x100cc
		move.b     (a3),d1
		move.w     #$DEEE,d0
		bsr        x100cc
		move.b     (a3),d1
		move.w     #$DEEE,d0
		bsr        x100cc
		cmpi.b     #$05,(a3)
		bne.s      x10cc0_6
		moveq.l    #2,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		bra.s      x10cc0_2
x10cc0_6:
		cmpi.b     #$09,(a3)
		bne.s      x10cc0_2
		moveq.l    #1,d3
		cmpi.w     #$0C80,x11a0c+mach64_off
		blt.s      x10cc0_7
		add.w      d3,d3
		cmpi.w     #$1900,x11a0c+mach64_off
		blt.s      x10cc0_7
		addq.w     #1,d3
x10cc0_7:
		move.b     d3,d1
		move.w     #$DEEE,d0
		bsr        x100cc
x10cc0_2:
		movem.l    (a7)+,d3/a2-a3
		rts

x10d88:
		movem.l    d3-d4/a2,-(a7)
		move.b     d1,d3
		moveq.l    #0,d2
		move.b     d0,d2
		lea.l      0(a0,d2.l),a2
		moveq.l    #32,d0
		and.b      d1,d0
		beq.s      x10d88_1
		lea.l      7(a0),a2
x10d88_1:
		bsr        x10c96
		move.b     (a2),d4
		moveq.l    #16,d0
		and.b      d3,d0
		beq.s      x10d88_2
		or.b       #2,d4
x10d88_2:
		move.b     d4,d1
		move.w     #$DEEE,d0
		bsr        x100cc
		movem.l    (a7)+,d3-d4/a2
		rts

x10dc0:
		movem.l    d3-d4/a2,-(a7)
		move.b     d0,d3
		move.b     d1,d4
		subq.b     #6,d0
		bne.s      x10dc0_1
		moveq.l    #5,d3
x10dc0_1:
		lea.l      x119c4+mach64_off,a2
		cmpi.b     #7,x11a0e+mach64_off
		beq.s      x10dc0_2
		movea.l    a2,a0
		move.b     d4,d1
		move.b     d3,d0
		bsr.w      x10d88
		bra.s      x10dc0_3
x10dc0_2:
		cmpi.b     #2,x11a12+mach64_off
		bne.s      x10dc0_4
		lea.l      x119bc-x119c4(a2),a0
		move.b     d4,d1
		move.b     d3,d0
		bsr.w      x10d88
		bra.s      x10dc0_3
x10dc0_4:
		lea.l      x119b4-x119c4(a2),a0
		move.b     d4,d1
		move.b     d3,d0
		bsr        x10cc0
x10dc0_3:
		movem.l    (a7)+,d3-d4/a2
		rts

x10e14:
		movem.l    d3-d6,-(a7)
		move.b     d0,d6
		move.b     d1,d3
		moveq.l    #1,d2
		and.b      d1,d2
		beq.s      x10e14_1
		move.w     #$9EEC,d0
		bsr        x100d8
		move.b     d0,d4
		and.b      #$DF,d4
		move.b     d4,d1
		move.w     #$9EEC,d0
		bsr        x100cc
		moveq.l    #3,d1
		move.w     #$9EEF,d0
		bsr        x100cc
		bra.s      x10e14_2
x10e14_1:
		clr.b      d1
		move.w     #$9EEF,d0
		bsr        x100cc
x10e14_2:
		bsr        x10194
		move.b     d0,d5
		cmpi.b     #5,x11a0e+mach64_off
		bne.s      x10e14_3
		move.b     d3,d1
		move.b     d6,d0
		bsr        x10bd0
		bra.s      x10e14_4
x10e14_3:
		move.b     d3,d1
		move.b     d6,d0
		bsr        x10dc0
x10e14_4:
		move.b     d5,d0
		bsr        x101b2
		moveq.l    #1,d0
		and.b      d3,d0
		beq.s      x10e14_5
		move.w     #$9EEC,d0
		bsr        x100d8
		move.b     d0,d4
		and.b      #$9F,d4
		moveq.l    #32,d0
		and.b      d3,d0
		beq.s      x10e14_6
		or.b       #$20,d4
x10e14_6:
		move.b     d4,d1
		move.w     #$9EEC,d0
		bsr        x100cc
x10e14_5:
		movem.l    (a7)+,d3-d6
		rts

x10ea6:
		movem.l    d3/a2-a3,-(a7)
		movea.l    a0,a2
		movea.l    a1,a3
		move.w     52(a2),d0
		bsr        x11746
		move.w     d0,20(a3)
		clr.w      22(a3)
		moveq.l    #64,d0
		and.b      56(a2),d0
		bne.s      x10ea6_1
		ori.w      #1,22(a3)
x10ea6_1:
		move.b     #$80,d0
		and.b      56(a2),d0
		bne.s      x10ea6_2
		ori.w      #2,22(a3)
x10ea6_2:
		move.b     #$80,d0
		and.b      84(a2),d0
		beq.s      x10ea6_3
		ori.w      #4,22(a3)
x10ea6_3:
		move.b     #$80,d0
		and.b      66(a2),d0
		beq.s      x10ea6_4
		ori.w      #8,22(a3)
x10ea6_4:
		move.b     35(a2),d0
		ext.w      d0
		move.w     d0,18(a3)
		move.w     38(a2),16(a3)
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #8,d1
		clr.w      d0
		move.b     57(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.b     55(a2),d1
		ext.w      d1
		and.w      #4,d1
		lsl.w      #6,d1
		add.w      d1,d0
		addq.w     #5,d0
		move.w     d0,(a3)
		moveq.l    #1,d1
		and.b      34(a2),d1
		beq.s      x10ea6_5
		addi.w     #$0200,(a3)
x10ea6_5:
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #8,d1
		clr.w      d0
		move.b     58(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.b     55(a2),d1
		ext.w      d1
		and.w      #8,d1
		lsl.w      #5,d1
		add.w      d1,d0
		addq.w     #1,d0
		move.w     d0,2(a3)
		moveq.l    #2,d1
		and.b      34(a2),d1
		beq.s      x10ea6_6
		addi.w     #$0200,2(a3)
x10ea6_6:
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #8,d1
		clr.w      d0
		move.b     61(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.b     55(a2),d1
		ext.w      d1
		and.w      #$0020,d1
		lsl.w      #3,d1
		add.w      d1,d0
		move.w     d0,4(a3)
		moveq.l    #4,d1
		and.b      34(a2),d1
		beq.s      x10ea6_7
		addi.w     #$0200,4(a3)
x10ea6_7:
		move.w     4(a3),d0
		move.w     2(a3),d1
		ext.l      d1
		divs.w     #2,d1
		cmp.w      d1,d0
		bge.s      x10ea6_8
		addi.w     #$0100,4(a3)
x10ea6_8:
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #5,d1
		clr.w      d0
		move.b     62(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.w     d0,d1
		moveq.l    #63,d2
		and.w      4(a3),d2
		sub.w      d2,d1
		move.w     d1,6(a3)
		tst.w      d1
		bpl.s      x10ea6_9
		addi.w     #$0040,6(a3)
x10ea6_9:
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #8,d1
		clr.w      d0
		move.b     63(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.w     d0,-(a7)
		moveq.l    #8,d0
		move.b     d0,-(a7)
		clr.b      d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     64(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,-(a7)
		moveq.l    #9,d0
		move.b     d0,-(a7)
		moveq.l    #5,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     64(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,-(a7)
		moveq.l    #10,d0
		move.b     d0,-(a7)
		moveq.l    #1,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     84(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		addq.w     #2,d0
		move.w     d0,8(a3)
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #8,d1
		clr.w      d0
		move.b     75(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.w     d0,-(a7)
		moveq.l    #8,d0
		move.b     d0,-(a7)
		moveq.l    #1,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     64(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,-(a7)
		moveq.l    #9,d0
		move.b     d0,-(a7)
		moveq.l    #6,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     64(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,-(a7)
		moveq.l    #10,d0
		move.b     d0,-(a7)
		moveq.l    #2,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     84(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		addq.w     #1,d0
		move.w     d0,10(a3)
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #8,d1
		clr.w      d0
		move.b     73(a2),d0
		bsr        x11444
		addq.w     #4,a7
		move.w     d0,-(a7)
		moveq.l    #8,d0
		move.b     d0,-(a7)
		moveq.l    #2,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     64(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,-(a7)
		moveq.l    #9,d0
		move.b     d0,-(a7)
		moveq.l    #7,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     64(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,-(a7)
		moveq.l    #10,d0
		move.b     d0,-(a7)
		moveq.l    #3,d2
		moveq.l    #1,d1
		clr.w      d0
		move.b     84(a2),d0
		bsr        x11444
		addq.w     #2,a7
		or.w       (a7)+,d0
		move.w     d0,12(a3)
		subq.w     #2,a7
		clr.b      -(a7)
		clr.b      d2
		moveq.l    #4,d1
		clr.w      d0
		move.b     74(a2),d0
		bsr        x11444
		addq.w     #4,a7
		cmpi.w     #4,38(a2)
		bgt.s      x10ea6_10
		moveq.l    #1,d2
		add.w      44(a2),d2
		asr.w      #3,d2
		move.w     d2,36(a2)
		asr.w      #1,d2
		move.b     d2,76(a2)
		bra        x10ea6_11
x10ea6_10:
		move.w     38(a2),d1
		ext.l      d1
		divs.w     #8,d1
		cmpi.w     #32,38(a2)
		bge.s      x10ea6_12
		move.w     (a3),d2
		ext.l      d2
		divs.w     d1,d2
		move.w     d2,(a3)
		move.w     2(a3),d2
		ext.l      d2
		divs.w     d1,d2
		move.w     d2,2(a3)
		move.w     4(a3),d2
		ext.l      d2
		divs.w     d1,d2
		move.w     d2,4(a3)
		move.w     6(a3),d2
		ext.l      d2
		divs.w     d1,d2
		move.w     d2,6(a3)
x10ea6_12:
		cmpi.w     #$0018,38(a2)
		bgt.s      x10ea6_13
		move.w     #$0080,d2
		add.w      44(a2),d2
		asr.w      #3,d2
		and.w      #$FFF0,d2
		move.w     d2,24(a3)
		mulu.w     38(a2),d2
		move.w     d2,36(a2)
		ext.l      d2
		moveq.l    #1,d3
		add.w      46(a2),d3
		ext.l      d3
		dc.w $4c03,$2802		/* muls.l     d3,d2 68020+ only */
		cmp.l      x119fa+mach64_off,d2
		bls.s      x10ea6_11
x10ea6_13:
		moveq.l    #1,d2
		add.w      44(a2),d2
		muls.w     d1,d2
		move.w     d2,36(a2)
		moveq.l    #1,d3
		add.w      44(a2),d3
		asr.w      #3,d3
		move.w     d3,24(a3)
x10ea6_11:
		moveq.l    #8,d2
		and.w      22(a3),d2
		beq.s      x10ea6_14
		asr.w      8(a3)
		asr.w      10(a3)
		asr.w      12(a3)
		asr.w      #1,d0
x10ea6_14:
		moveq.l    #15,d1
		and.w      12(a3),d1
		sub.w      d1,d0
		tst.w      d0
		bpl.s      x10ea6_15
		add.w      #$0010,d0
x10ea6_15:
		move.w     d0,14(a3)
		subq.w     #1,(a3)
		subq.w     #1,2(a3)
		subq.w     #1,4(a3)
		subq.w     #1,8(a3)
		subq.w     #1,10(a3)
		subq.w     #1,12(a3)
		cmpi.w     #$001F,6(a3)
		ble.s      x10ea6_16
		move.w     #$001F,6(a3)
x10ea6_16:
		movem.l    (a7)+,d3/a2-a3
		rts

x11224:
		lea.l      vga_reg_ptr+mach64_off,a0
		movea.l    (a0),a1
		clr.b      $deec(a1)
		clr.w      d1
		bra.s      x11224_1
x11224_2:
		movea.l    (a0),a1
		move.b     d0,$deed(a1)
		addq.w     #1,d1
x11224_1:
		cmp.w      #$0300,d1
		blt.s      x11224_2
		rts

x11244:
		movem.l    a2-a4,-(a7)
		lea.l      -28(a7),a7
		movea.l    a0,a2
		movea.l    a1,a3
		lea.l      (a7),a1
		bsr        x10ea6
		cmpi.b     #5,x11a0e+mach64_off
		bne.s      x11244_1
		move.w     #$1518,d1
		moveq.l    #19,d0
		bsr        x10390
		bra.s      x11244_2
x11244_1:
		move.w     #$125C,d1
		moveq.l    #19,d0
		bsr        x10390
x11244_2:
		moveq.l    #17,d1
		move.w     #$EAEC,d0
		bsr        x100a4
		moveq.l    #1,d1
		moveq.l    #2,d0
		bsr        x10e14
		move.w     52(a2),d1
		move.w     d1,d0
		add.w      d0,d0
		add.w      d1,d0
		lsl.w      #3,d0
		add.w      d1,d0
		lsl.w      #2,d0
		move.w     d0,x11a0c+mach64_off
		moveq.l    #5,d0
		move.w     x11a0c+mach64_off,d1
		bsr        x10390
		move.w     #5,20(a7)
		moveq.l    #2,d1
		move.w     #$9EEF,d0
		bsr        x100cc
		bsr        x10866
		move.b     #1,$83C3(a3)
		bsr        x10886
		clr.b      70(a2)
		clr.b      69(a2)
		lea.l      x11824+mach64_off,a4
		cmpi.w     #1,38(a2)
		bne.s      x11244_3
		move.b     #1,x11825-x11824(a4)
		move.b     #1,x11845-x11824(a4)
		bra.s      x11244_4
x11244_3:
		move.b     #$0F,x11825-x11824(a4)
		move.b     #$0F,x11845-x11824(a4)
x11244_4:
		andi.b     #$F7,x11827-x11824(a4)
		andi.b     #$BF,x1182f-x11824(a4)
		andi.b     #$F7,(a4)
		moveq.l    #1,d0
		and.b      55(a2),d0
		beq.s      x11244_5
		ori.b      #$08,(a4)
x11244_5:
		andi.b     #$4F,x11849-x11824(a4)
		andi.b     #$BE,x11829-x11824(a4)
		move.b     #$FF,x11844-x11824(a4)
		movea.l    a3,a0
		bsr        x1008e
		moveq.l    #4,d2
		moveq.l    #1,d1
		movea.l    a4,a1
		move.w     #$83C4,d0
		movea.l    a3,a0
		bsr        x10064
		move.b     56(a2),$83C2(a3)
		move.b     #$11,$83D4(a3)
		andi.b     #$7F,$83D5(a3)
		ori.b      #$10,64(a2)
		moveq.l    #25,d2
		clr.b      d1
		lea.l      57(a2),a1
		move.w     #$83D4,d0
		movea.l    a3,a0
		bsr        x10064
		move.b     #$86,$81CE(a3)
		move.b     #$7A,$81CF(a3)
		move.b     #$A3,$81CE(a3)
		clr.b      $81CF(a3)
		move.b     #$AD,$81CE(a3)
		clr.b      $81CF(a3)
		move.b     #$AE,$81CE(a3)
		clr.b      $81CF(a3)
		move.b     #$B0,$81CE(a3)
		move.b     #$08,$81CF(a3)
		move.b     #$B1,d0
		bra.s      x11244_6
x11244_7:
		move.b     d0,$81CE(a3)
		clr.b      $81CF(a3)
		addq.b     #1,d0
x11244_6:
		cmp.b      #$B5,d0
		bls.s      x11244_7
		move.b     #$B6,$81CE(a3)
		move.b     #1,$81CF(a3)
		move.b     #$B8,$81CE(a3)
		clr.b      $81CF(a3)
		move.b     #$BD,$81CE(a3)
		move.b     #$04,$81CF(a3)
		move.b     #$BE,$81CE(a3)
		moveq.l    #4,d0
		and.w      22(a7),d0
		beq.s      x11244_8
		move.b     #$0A,$81CF(a3)
		bra.s      x11244_9
x11244_8:
		move.b     #$08,$81CF(a3)
x11244_9:
		move.b     #$BF,$81CE(a3)
		move.b     #1,$81CF(a3)
		moveq.l    #9,d2
		clr.b      d1
		lea.l      x1182a-x11824(a4),a1
		move.w     #$83CE,d0
		movea.l    a3,a0
		bsr        x10064
		movea.l    a3,a0
		bsr.w      x11472
		move.b     #$FF,$deee(a3)
		clr.w      d1
		move.b     85(a2),d1
		and.w      #$0080,d1
		move.w     20(a7),d0
		bsr.w      x11498
		move.b     x11a0e+mach64_off,d0
		bne.s      x11244_10
		moveq.l    #5,d0
		bsr        x10496
x11244_10:
		lea.l      28(a7),a7
		movem.l    (a7)+,a2-a4
		rts

x11444:
		move.l     d3,-(a7)
		move.l     d4,-(a7)
		move.b     12(a7),d3
		cmp.b      d2,d3
		blt.s      x11444_1
		move.b     d3,d4
		sub.b      d2,d4
		lsl.w      d4,d0
		bra.s      x11444_2
x11444_1:
		move.b     d2,d4
		sub.b      d3,d4
		lsr.w      d4,d0
x11444_2:
		clr.w      d2
		dc.w $1430,$11b0		/* move.b     (x118a4+mach64_off,d1.w),d2 68020+ only */
		dc.l x118a4+mach64_off
		lsl.w      d3,d2
		and.w      d2,d0
		move.l     (a7)+,d4
		move.l     (a7)+,d3
		rts

x11472:
		lea.l      x11833+mach64_off,a1
		move.b     $83DA(a0),d0
		clr.b      d0
		bra.s      x11472_1
x11472_2:
		move.b     d0,$83C0(a0)
		move.b     (a1)+,$83C0(a0)
		addq.b     #1,d0
x11472_1:
		cmp.b      #$14,d0
		ble.s      x11472_2
		move.b     #$20,$83C0(a0)
		rts

x11498:
		move.l     a2,-(a7)
		move.w     d0,d2
		add.w      d2,d2
		add.w      d0,d2
		addq.w     #2,d2
		move.w     d2,d0
		lea.l      vga_reg_ptr+mach64_off,a0
		movea.l    (a0),a1
		clr.b      $83C4(a1)
		movea.l    (a0),a1
		move.b     #1,$83C5(a1)
		movea.l    (a0),a1
		move.b     #$B9,$81CE(a1)
		lea.l      x1184e+mach64_off,a1
		moveq.l    #4,d2
		dc.w $c471,$0200			/* and.w      0(a1,d0.w*2),d2 68020+ only */
		asr.w      #1,d2
		or.b       #$40,d2
		movea.l    (a0),a2
		move.b     d2,$81CF(a2)
		movea.l    (a0),a2
		move.b     #$B8,$81CE(a2)
		moveq.l    #16,d2
		dc.w $c431,$0201			/* and.b      1(a1,d0.w*2),d2 68020+ only */
		lsl.b      #2,d2
		movea.l    (a0),a2
		move.b     d2,$81CF(a2)
		movea.l    (a0),a2
		move.b     #$BE,$81CE(a2)
		moveq.l    #8,d2
		dc.w $c431,$0201 			/* and.b      1(a1,d0.w*2),d2 68020+ only */
		add.b      d2,d2
		move.b     d2,-(a7)
		tst.w      d1
		beq.s      x11498_1
		moveq.l    #1,d2
		bra.s      x11498_2
x11498_1:
		clr.w      d2
x11498_2:
		add.b      d2,d2
		or.b       (a7)+,d2
		movea.l    (a0),a2
		move.b     d2,$81CF(a2)
		movea.l    (a0),a2
		move.b     $83CC(a2),d1
		and.b      #$F3,d1
		moveq.l    #3,d2
		dc.w $c431,$0201			/* and.b      1(a1,d0.w*2),d2 68020+ only */
		lsl.b      #2,d2
		or.b       d2,d1
		move.b     d1,$83C2(a2)
		movea.l    (a0),a1
		clr.b      $83C4(a1)
		movea.l    (a0),a1
		move.b     #$03,$83C5(a1)
		movea.l    (a7)+,a2
		rts

x1153e:
		move.b     $deec(a0),d0
		rts

x11544:
		clr.b      d0
		bra.s      x11544_1
x11544_4:
		clr.w      d1
		bra.s      x11544_2
x11544_3:
		addq.w     #1,d1
x11544_2:
		cmp.w      #$03E8,d1
		blt.s      x11544_3
		move.b     $deee(a0),d2
		addq.b     #1,d0
x11544_1:
		cmp.b      #$04,d0
		bcs.s      x11544_4
		move.b     d2,d0
		rts

x11564:
		movem.l    d3-d7/a2,-(a7)
		subq.w     #4,a7
		clr.w      (a7)
		movea.l    #vga_reg+$8000,a2
		movea.l    a2,a0
		bsr        x116bc
		move.b     d0,d4
		move.b     $deee(a2),d5
		move.b     d4,d6
		not.b      d6
		move.b     d6,$deee(a2)
		movea.l    a2,a0
		bsr        x116aa
		move.b     $deee(a2),d7
		clr.b      d3
		cmp.b      d7,d6
		bne.s      x11564_1
		movea.l    a2,a0
		bsr.w      x1153e
		bra        x11564_2
x11564_1:
		move.b     #$E0,d0
		movea.l    a2,a0
		bsr        x116d8
		movea.l    a2,a0
		bsr        x116aa
		move.b     $deee(a2),d7
		and.b      #$E0,d7
		moveq.l    #1,d3
		cmp.b      #$E0,d7
		bne        x11564_3
		moveq.l    #96,d0
		movea.l    a2,a0
		bsr        x116d8
		movea.l    a2,a0
		bsr        x116aa
		move.b     $deee(a2),d7
		and.b      #$E0,d7
		moveq.l    #3,d3
		move.b     d4,d0
		movea.l    a2,a0
		bsr        x116d8
		tst.b      d7
		beq        x11564_2
		movea.l    a2,a0
		bsr        x116aa
		move.b     $deee(a2),d7
		move.b     $deee(a2),d7
		cmp.b      d7,d6
		bne.s      x11564_4
		move.b     #$FF,d0
		movea.l    a2,a0
		bsr        x116d8
		movea.l    a2,a0
		bsr        x116aa
		move.b     $deee(a2),d7
		moveq.l    #4,d3
		move.b     d7,d0
		and.b      #$F0,d0
		beq.s      x11564_5
		moveq.l    #3,d3
x11564_5:
		move.b     d7,d0
		movea.l    a2,a0
		bsr        x116d8
		bra.s      x11564_2
x11564_4:
		movea.l    a2,a0
		bsr        x11544
		move.b     d0,d7
		moveq.l    #6,d3
		cmp.b      d0,d6
		beq.s      x11564_3
		movea.l    a2,a0
		bsr        x1153e
		move.b     #$FF,$deee(a2)
		movea.l    a2,a0
		bsr        x11544
		move.b     d0,d7
		moveq.l    #7,d3
		cmp.b      #$8E,d0
		beq.s      x11564_3
		moveq.l    #8,d3
		cmp.b      #$82,d0
		beq.s      x11564_3
		cmp.b      #$44,d0
		beq.s      x11564_3
		move.b     d4,d2
		move.b     d5,d1
		movea.l    a2,a0
		move.b     #$EF,d0
		bsr        x116f4
		move.w     d0,d7
		moveq.l    #5,d3
		tst.b      d7
		bne.s      x11564_3
		move.b     d4,d2
		move.b     d5,d1
		move.b     #$FB,d0
		movea.l    a2,a0
		bsr.w      x116f4
		move.w     d0,d7
		moveq.l    #9,d3
		tst.b      d7
		bne.s      x11564_3
		moveq.l    #2,d3
x11564_3:
		move.b     d4,d0
		movea.l    a2,a0
		bsr.w      x116d8
x11564_2:
		move.b     d7,$deee(a2)
		clr.w      d0
		move.b     d3,d0
		move.w     d0,(a7)
		move.b     #$FF,$deee(a2)
		addq.w     #4,a7
		movem.l    (a7)+,d3-d7/a2
		rts

x116aa:
		move.l     a2,-(a7)
		movea.l    a0,a2
		bsr        x1153e
		movea.l    a2,a0
		bsr        x11544
		movea.l    (a7)+,a2
		rts

x116bc:
		move.l     d3,-(a7)
		move.l     a2,-(a7)
		movea.l    a0,a2
		bsr.w      x116aa
		move.b     $deee(a2),d3
		movea.l    a2,a0
		bsr        x1153e
		move.b     d3,d0
		movea.l    (a7)+,a2
		move.l     (a7)+,d3
		rts

x116d8:
		move.l     d3,-(a7)
		move.l     a2,-(a7)
		movea.l    a0,a2
		move.b     d0,d3
		bsr.w      x116aa
		move.b     d3,$deee(a2)
		movea.l    a2,a0
		bsr        x1153e
		movea.l    (a7)+,a2
		move.l     (a7)+,d3
		rts

x116f4:
		movem.l    d3-d5/a2,-(a7)
		movea.l    a0,a2
		move.b     d0,d4
		move.b     d1,d3
		move.b     d2,d5
		bsr        x1153e
		move.b     d4,d0
		and.b      d3,d0
		move.b     d0,$deee(a2)
		movea.l    a2,a0
		bsr.w      x116aa
		move.b     d4,d0
		not.b      d0
		or.b       d5,d0
		move.b     d0,$deee(a2)
		move.b     d0,d0
		move.b     d4,d1
		and.b      d0,d1
		move.b     d1,$deee(a2)
		tst.b      d4
		bne.s      x116f4_1
		moveq.l    #1,d2
		bra.s      x116f4_2
x116f4_1:
		clr.w      d2
x116f4_2:
		clr.w      d1
		move.b     d0,d1
		and.w      d1,d2
		beq.s      x116f4_3
		moveq.l    #1,d3
		bra.s      x116f4_4
x116f4_3:
		clr.w      d3
x116f4_4:
		move.w     d3,d0
		movem.l    (a7)+,d3-d5/a2
		rts

x11746:
		move.l     d3,-(a7)
		move.l     d4,-(a7)
		move.w     #$270F,d1
		clr.w      d2
		lea.l      x1184e+mach64_off,a0
		bra.s      x11746_1
x11746_7:
		move.w     d2,d4
		add.w      d4,d4
		add.w      d2,d4
		add.w      d4,d4
		move.w     0(a0,d4.w),d4
		sub.w      d0,d4
		bpl.s      x11746_2
		move.w     d2,d4
		add.w      d4,d4
		add.w      d2,d4
		add.w      d4,d4
		move.w     0(a0,d4.w),d4
		neg.w      d4
		sub.w      d0,d4
		bra.s      x11746_3
x11746_2:
		move.w     d2,d4
		add.w      d4,d4
		add.w      d2,d4
		add.w      d4,d4
		move.w     0(a0,d4.w),d4
		sub.w      d0,d4
x11746_3:
		cmp.w      d4,d1
		ble.s      x11746_4
		move.w     d2,d1
		add.w      d1,d1
		add.w      d2,d1
		add.w      d1,d1
		move.w     0(a0,d1.w),d4
		sub.w      d0,d4
		bpl.s      x11746_5
		move.w     0(a0,d1.w),d1
		neg.w      d1
		sub.w      d0,d1
		bra.s      x11746_6
x11746_5:
		move.w     d2,d4
		add.w      d4,d4
		add.w      d2,d4
		add.w      d4,d4
		move.w     0(a0,d4.w),d1
		sub.w      d0,d1
x11746_6:
		move.w     d2,d3
x11746_4:
		addq.w     #1,d2
x11746_1:
		cmp.w      #$000E,d2
		blt.s      x11746_7
		move.w     d3,d0
		move.l     (a7)+,d4
		move.l     (a7)+,d3
		rts

/* .data */

x117c6:
	dc.b $ff,$ff,$ff
x117c9:
	dc.b $00,$00,$00,$ff,$ff
x117ce:
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0000
			dc.w $0001
			dc.w $0050
			dc.w $0001
			dc.w $0002
			dc.w $0001
			dc.w $027f
			dc.w $018f
			dc.w $027f
			dc.w $018f
			dc.w $0019
			dc.w $8000
			dc.w $635f
			dc.w $4f50
			dc.w $8254
			dc.w $80bf
			dc.w $1f00
			dc.w $4000
			dc.w $0000
			dc.w $0000
			dc.w $009c
			dc.w $0e8f
			dc.w $2800
			dc.w $e704
			dc.w $c3ff
			dc.w $0000
			dc.w $0000

x11824: dc.b $01
x11825: dc.b $0f
x11826: dc.b $00
x11827: dc.b $06
        dc.b $00
x11829: dc.b $b4
x1182a: dc.b $00,$00
		dc.b $00,$00
		dc.b 0
x1182f: dc.b 0
        dc.b $01,$0f
        dc.b $ff

x11833: dc.b $00
        dc.b $01,$02
		dc.b $03,$04
		dc.b $05,$06
		dc.b $07,$08
		dc.b $09,$0a
		dc.b $0b,$0c
		dc.b $0d,$0e
		dc.b $0f,$01
x11844: dc.b $ff
x11845:	dc.b $0f
		dc.b $10,$00
		dc.b $05
x11849:	dc.b $00
		dc.b $ff,$ff
		dc.b $ff,$00

		even
x1184e:		dc.w $0019
			dc.w $0000
			dc.w $0010
			dc.w $001c
			dc.w $0000
			dc.w $0011
			dc.w $0020
			dc.w $0000
			dc.w $0012
			dc.w $0024
			dc.w $0000
			dc.w $0013
			dc.w $0028
			dc.w $0000
			dc.w $0004
			dc.w $002d
			dc.w $0000
			dc.w $0005
			dc.w $0032
			dc.w $0000
			dc.w $0007
			dc.w $0039
			dc.w $0000
			dc.w $0001
			dc.w $0041
			dc.w $0000
			dc.w $000f
			dc.w $004b
			dc.w $0000
			dc.w $000e
			dc.w $0050
			dc.w $0000
			dc.w $000d
			dc.w $006e
			dc.w $0000
			dc.w $000a
			dc.w $007e
			dc.w $0000
			dc.w $000a
			dc.w $0087
			dc.w $0000
			dc.w $000b
x118a2: 	dc.w $0598
x118a4:		dc.w $0001
			dc.w $0307
			dc.w $0f1f
			dc.w $3f7f
			dc.w $ff00
x118ae: 	dc.w $0001
x118b0: 	dc.w $ceee,$890e
			dc.w $9aec,$0000
			dc.w $9eec,$0200
			dc.w $e6ec,$0000
			dc.w $e6ee,$0000
			dc.w $d2ec,$01f0
			dc.w $d2ee,$0000
			dc.w $c2ec,$0000
			dc.w $c2ee,$0000
			dc.w $c6ec,$0000
			dc.w $c6ee,$0000
			dc.w $e2ec,$0000
			dc.w $eaec,$0011
			dc.w $0000,$0000

x118e8:		dc.w $000e,$c848
			dc.w $0019,$831b
			dc.w $001b,$873d
			dc.w $001c,$8847
			dc.w $001e,$8322
			dc.w $0020,$8850
			dc.w $0022,$853a
			dc.w $0024,$4311
			dc.w $0026,$4622
			dc.w $0028,$4830
			dc.w $002c,$4523
			dc.w $002f,$462c
			dc.w $0030,$4319
			dc.w $0032,$431b
			dc.w $0034,$4632
			dc.w $0037,$473d
			dc.w $0039,$4847
			dc.w $003c,$4322
			dc.w $003f,$4850
			dc.w $0041,$4853
			dc.w $0044,$453a
			dc.w $0048,$0311
			dc.w $004b,$0622
			dc.w $004d,$0623
			dc.w $0050,$0830
			dc.w $0058,$0523
			dc.w $005a,$062a
			dc.w $005f,$0319
			dc.w $0064,$0422
			dc.w $0069,$073a
			dc.w $006c,$073c
			dc.w $006e,$073d
			dc.w $0076,$0219
			dc.w $0078,$0322
			dc.w $0083,$0538
			dc.w $0087,$0526
			dc.w $03e7,$0000

x1197c:		dc.w $13ab
			dc.w $1620
			dc.w $189c
			dc.w $1c20
			dc.w $0fa0
			dc.w $118a
			dc.w $1356
			dc.w $1388
			dc.w $0000
			dc.w $2af8
			dc.w $3138
			dc.w $34bc
			dc.w $0000
			dc.w $1f40
			dc.w $1d4c
			dc.w $1964
			dc.w $157c
			dc.w $157c
			dc.w $157c
			dc.w $157c

x119a4:		dc.w $0163
			dc.w $8261
			dc.w $8361
			dc.w $b060
			dc.w $b160
			dc.w $d060
			dc.w $f360

x119b2:		dc.w $8061
x119b4:		dc.w $ff00
			dc.w $0002
			dc.w $0309
			dc.w $0005
x119bc:		dc.w $0c04
			dc.w $0416
			dc.w $36e6
			dc.w $e624
x119c4:		dc.w $0c04
			dc.w $0416
			dc.w $36b6
			dc.w $b624
			dc.w $0006
			dc.w $0006
			dc.w $000c
			dc.w $000c
			dc.w $000c
			dc.w $000c
			dc.w $000c
			dc.w $000c
			dc.w $020c
			dc.w $0206
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e
			dc.w $020e

/* .bss */

x119fa: ds.l 1
x119fe: ds.w 1
x11a00: ds.w 1
x11a02: ds.w 1
x11a04: ds.w 1
x11a06: ds.l 1
x11a0a: ds.w 1
x11a0c: ds.w 1
x11a0e: ds.b 1
        even
x11a10: ds.b 1 /* unused? */
x11a11: ds.b 1
x11a12: ds.b 1
        even
vga_reg_ptr: ds.l 1
x11a18: ds.b 28 /* unused? */
