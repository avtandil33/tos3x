/*
 * BIOS functions for hades that don't
 * fit as patches in the original routines
 */

#include "config.h"
#include "asmdefs.h"
#include "tosvars.inc"
#include "biosdefs.h"


#if HADES /* whole file */

/*
 * Dateiversion:		4.43
 * Erstellt am:		03.09.1994
 * letzte Aenderung vom :	27.03.1997
 *
 * .26 .28
 * Hier eine wichtige Aenderung !!!
 * wenn ein Programm so heftig abstuerzt, das es die memval
 * Variablen zerschiesst, konnte bei tos im ram (pmmu an)
 * ein derber Haenger passieren. Also hier schon ALLES AUS !!!
 * und Hardware nicht cachen.
 *
 * .29
 * Nach dem ERSTEN Einschalten reagiert auch die PMMU des 68040
 * allergisch auf einen PFLUSHA Befehl. Nachdem dieser hier erst
 * wieder rausgeflogen ist (passiert beim Cookie-Test sowieso
 * nochmal) ist auch dieser ominoese Einschalt-Haenger verschwunden.
 * Natuerlich steht auch zu diesem 'Problem' nix in der Motorola-Doku ...
 *
 * kein 68030,romport,mmu und scu
 * 68040 init -> mmu aus etc.
 * (fa_8.11.94):mmu cacr etc nur einmal setzen
 */


/* maschinen und tos id */
hadesid		equ $68616465 /* 'hade' */

/*
 * Yes, we assemble to the data segment here, so that the codes ends up at the end of the ROM image
 */
	data

/*  Der Anhaengsel hinter dem TOS wurde ein wenig weiter nach hinten verlegt */
/*  um auch noch Platz fuer groessere Resourcen (TOS-Patch) und Winx zu haben */
/*	org HADES_XBIOS */

serialno:
	.ascii "SN:E55G2030"
	.even

nullframe:	dc.l	0		/* statt $FF kann hier auch der Null-Frame hin */

/*  Hier erst mal der zweite Teil des Cookie-Setzers */

	xdef morecook
morecook:
/*  .24 .26 .27 .28 */
/*  Die naechste grosse Aenderung ist beim _FPU cookie passiert !!! */
/*  Hier wird jetzt nicht mehr nur einfach auf 8=68040 gesetzt, sondern */
/*  'ganz ordentlich' alles das was bei Atari so dokumentiert ist auch */
/*  geprueft. Dabei gibt es jedoch eine kleine Ausnahme - der 68060 ist */
/*  bei Atari noch nicht bekannt, hierfuer wird Bit 4 im Highword (16) */
/*  gesetzt. Das duerfte der weiteren Nomenklatur entsprechen ... */
/*  Da der _FPU-cookie nun geprueft wird, kann man wohl auch einen */
/*  68LC040 einsetzen - der meldet als _FPU dann eben 0 */

		move.l #$5F465055,(a0)+  /* '_FPU' */

/*  Nach Atari Dokumentation ist die Belegung wie folgt: */
/*  _FPU Cookie ist IMMER da !!! */
/*  Belegung im Highword: */
/*   0 = keine Hardware- FPU */
/*   1 = Atari Register FPU (memory mapped)  -> wird nicht getestet */
/*   2 = LineF FPU */
/*   3 = Atari Register FPU + LineF FPU */
/*   4 = mit Sicherheit 68881 LineF FPU */
/*   5 = Atari Register FPU + mit Sicherheit 68881 LineF FPU */
/*   6 = mit Sicherheit 68882 LineF FPU */
/*   7 = Atari Register FPU + mit Sicherheit 68882 LineF FPU */
/*   8 = 68040 internal LineF FPU */
/*   9 = Atari Register FPU + 68040 internal LineF FPU */
/*  16 = 68060 internal LineF FPU */

/*  Das Loword ist fuer eine spaetere eventuelle */
/*  softwaremaessige LineF- Emulation reserviert und derzeit immer 0 */

		moveq	#0,d1
noafpu:
		move.l	a3,sp
		move.l	a2,_buserror.w	/*  Busfehler zurueck */

/*  Test auf (Line F) */

		move.l	_lineftrap.w,a1		/*  LineF retten */
		lea	nolfpu(pc),a2			/*  bei LineF Trap gehts dahin */
		move.l	a2,_lineftrap.w

/*  .29 */
/*  wenn schon die FPU getestet wird, koeenen wir sie zur Sicherheit */
/*  vor dem Test auch noch in einen definierten Zustand bringen - dazu */
/*  einfach den NULL-Frame eingefuegt ... */

		lea	nullframe(pc),a2	/*  NULL-Frame fuer FPU-Reset */
		dc.w	$f352			/*  frestore (a2) */
		move.l	sp,a2

/*  .28 */
/*  Diese Stelle war eine der Trickreichsten !!! */
/*  Beim 68881 und 68882 reicht ein schlichtes FNOP um beim */
/*  naechsten FSAVE statt eines NULL-Frame (habe noch nichts getan) */
/*  einen IDLE-Frame (habe schon was getan, aber gerade nix mehr zu tun) */
/*  zu erhalten, der dann auch ein Version Byte enthaelt. Das dieses Version */
/*  Byte beim 68040 und 68060 an anderer Stelle zu finden ist, konnte man */
/*  ja noch so halbwegs der Doku entnehmen, dass der 68040 ein FNOP aber */
/*  schlichtweg wegoptimiert und danach immer noch einen NULL-Frame liefert */
/*  allerdings nicht (Puh, DAS zu finden hat mich 2 Tage und ich weiss nicht */
/*  wie viele gebrannte Eproms gekostet (wann bekommt die Medusa endlich */
/*  Static-Rams statt EPROMs ...), denn wenn ich's als externes */
/*  Programm probiert habe, hatte die FPU ja schon was getan und antwortete */
/*  auch auf ein FNOP mit dem erwarteten IDLE-Frame. Beim Booten stand im */
/*  FPU-cookie aber natuerlich immer nur 2 (LineF-FPU Typ unbekannt)). Jetzt */
/*  wird statt FNOP einfach ein FTST.X FP0 verwendet - und siehe da - es geht ... */

/* (fa_10.11.94)(1_12_94):einigie aenderungen */

		dc.l	$F2004000		/*  fmove.l d0,fp0 */
		dc.w	$F327			/*  fsave	-(sp) */
		move.l	(sp),d2 		/*  Version Bytes ($18=881,$38=882,... */
		move.l	a2,sp			/*  Stack korrigieren */
		move.l	d2,d0

		cmp.w	#60,_longframe.w		/*  mc68060 */
		bne.s	no060			/*  ja-> */
		cmpi.w	#$6000,d2		/*  68060 internal FPU ? */
		beq.s	is060	       	/*  ja-> */

no060:
		rol.l	#8,d0
		cmpi.b	#$41,d0			/*  68040 internal FPU ? */
		beq.s	is040
		cmpi.b	#$40,d0			/*  68040 internal FPU ? */
		beq.s	is040
		move.l	d2,d0
		ror.l	#8,d0
		ror.l	#8,d0
		cmpi.b	#$18,d0			/*  68881 ? */
		beq.s	is881
		cmpi.b	#$38,d0			/*  68882 ? */
		beq.s	is882           /*  ja -> */
        bne.s   nolfpu          /*  sonst linef */

is060:
		addq.w	#8,d1			/* 16: 68060 */
is040:
		addq.w	#2,d1			/*  8: 68040 */
is882:
		addq.w	#2,d1			/*  6: 68882 */
is881:
		addq.w	#2,d1			/*  4: 68881 */
linef_emu:
		addq.w 	#2,d1			/*  2: LineF- FPU */
nolfpu:			    			/*  keine LineF FPU */
		move.l	a3,sp			/*  Stack korrigieren */
		move.l	a1,_lineftrap.w	/*  LineF Error zurueck */
		swap	d1
		move.l	d1,(a0)+

/*  .28 */
/*  im _MCH cookie wird jetzt TT eingetragen. */

		moveq	#6,d0                   /*  scsi und vme immer */
		move.l	#"_MCH",(a0)+
		move.l	#$20000,(a0)+		/*  machine type auf TT */

/*  Test auf Atari DMA */
		move.l	a7,a2
		move.l	_buserror.w,a1
		move.l	#no_atari_dma,_buserror.w      /* buserrorvector setzen */
		moveq	#6,d0                   /* vme und scsi immer */
		tst.w	DMA_DATA
		bset	#3,d0			/*  merken */
no_atari_dma:
		move.l	a2,a7
		move.l	a1,_buserror.w

/*  .24 .25 .30 */
/*  *** Der 'id'-Cookie: */
/*  Hier kann man nun die im Hades vorhandene Zusatzhardware */
/*  abfragen bzw. eintragen. */
/*  16 Bits duerften erst einmal eine Weile reichen */

/* Bit 0..15:  im Hades gefundene Hardware */
/* 	     (ist das jeweilige Bit Null ist diese Hardware nicht vorhanden). */
/*  Bit	0	ROM-Port */
/*  Bit	1	VME-Bus */
/*  Bit	2	SCSI-Karte */
/*  Bit   3       Atari DMA */
/*  Bit 3-11	reserviert */
/*  Bit 12-15	reserviert fuer Video Hardware */
/* 		Bit 12 = ET4000 am ISA Bus */
/* 		Bit 13 = Videokarte am VME Bus */
/* 		Bit 14 = PCI-Bus Graphikkarte */
/*  Bit 16-31     Maschinenversion (derzeit 0) */

		move.l	#hadesid,(a0)+
	    move.l	_v_bas_ad.w,d1	/*  adresse bildspeicher */
	    cmpi.l	#pci_base,d1	/* pci */
	    bcc.s	nopcigk			/* nein-> */
		bset	#14,d0			/* pci grafikkarte eintragen */
		bra.s	gkset
nopcigk:
		cmpi.l	#$ff000000,d1	/* vme? */
		bcc.s	novmegk         /* nein-> */
		bset	#13,d0          /* set vme grafikkarte */
		bra.s	gkset
novmegk:
		bset	#12,d0			/* sonst isa bus grafikkarte eintragen */
gkset:
		move.l	d0,(a0)+		/* Hade setzen */

		move.l	#"_SND",(a0)+

/*  _SND Cookie. normaler st sound eintragen */
		moveq	#1,d0			/*  d0 initialisieren (kein DMA Sound) */
		move.l	d0,(a0)+

		move.b	#8,dsb.w		/* select HD density for drive A */
		move.l	#"_FDC",(a0)+

/*  .24 */
/*  als Benutzerkennung wird im _FDC jetzt 'id' eingetragen... */
/*  (Ordnung muss sein .-))) */
/* THO: not quite right. Highest byte should be max. density allowed */

		move.l	#hadesid,(a0)+	/* hades floppy */

/*  .23 .24 .25 */
/*  fuer MultiTOS Anwender tragen wir auch gleich noch den _AKP und */
/*  _IDT cookie ein, das spart schon wieder ein Autoordnerprogramm */

		move.l	#'_AKP',(a0)+
		move.l	_sysbase.w,a2		/* sysbase nach a0 */
		move.l	8(a2),a2
		move.w	28(a2),d0		/* laenderkennung */
		asr.w	#1,d0			/* Syncmode ausblenden */
		move.w	d0,d1			/* merken */
		asl.w	#8,d1			/* in High-Bit */
		or.w	d1,d0			/* und einkopieren */
		move.l	d0,(a0)+

/*  .23 .24 .25 */
**** Der "_IDT"-Cookie:
/* Bit 0..7:   Trennzeichen fuer Datumsangaben */
/* 	     (Null steht als Default fuer '/'). */
/* Bit 8..11:  Datumsformat, */
/* 	     (0: MM-TT-JJ, 1: TT-MM-JJ, */
/* 	      2: JJ-MM-TT, 3: JJ-TT-MM.) */
/* Bit 12..15: Zeitformat */
/* 	     (0: am/pm, 1: 24 Stunden) */
/* Bit 16..31: reserviert */

	      move.l	#'_IDT',(a0)+
	      moveq		#0,d1
	      cmpi.b	#CTRY_DE,d0		/* FRG */
	      beq.s		isger
	      cmpi.b	#CTRY_SG,d0		/* SWG */
	      bne.s		noswg
isger:
	      move.w	#$112e,d1
	      bra.s		instidt
noswg:
	      cmpi.b	#CTRY_UK,d0		/* UK */
#if BINEXACT
	      bne.s		instidt
#else
/* THO: BUG: this is missing */
	      beq.s		iseng
	      cmpi.b	#CTRY_US,d0		/* USA */
	      bne.s		instidt
#endif
iseng:
	      move.w	#$1000,d1
instidt:
	      move.l	d1,(a0)+	/* und eintragen */
	      jmp		cook_wei	/* weiter in der normalen cookie installation */


***********************************************************************************************
/* fa 1.1.96:pseudo dma fuer scsi */
/*  a0=basis adresse register */
/*  a1=dma adresse */
/*  a2=alter stackwert/adresse letztes zu uebertragendes long (restdaten!!) */
/*  a3=sprungadresse/write back 3 adresse */
/*  a4=endadresse */
/*  d0=divers */
/*  d1=anzahl byts resp. restbyts des letzten sectors -1 */
/*  d2=dma start adresse */
/*  d3=dtt0 alt */
/*  d4=10000-anzahl buserrors */
/*  d5=anzahl sectoren-1 */

	xdef int_scsi
int_scsi:
		movem.l d0-d7/a0-a4,-(sp)
		move.b  auu.w,d2
		lsl.l	#8,d2
		move.b  amu.w,d2
		lsl.l   #8,d2
		move.b  aml.w,d2
		lsl.l   #8,d2
		move.b  all.w,d2
		move.b  cuu.w,d1
		lsl.l	#8,d1
		move.b  cmu.w,d1
		lsl.l   #8,d1
		move.b  cml.w,d1
		lsl.l	#8,d1
		move.b  cll.w,d1
/* 		tst.l	d1 */
/* 		beq	scsiendx */
		move.l	_buserror.w,-(sp)		/* alter buserrorvector sichern */
		bclr	#1,sctr1.w		/* dma off -> int 2 off */
        and.b	#$fc,sctr2.w		/* eop, bus error off */
		move.l  #scsibuserror,_buserror.w 	/* neuen setzen */
		DTT0_Dn(3)			/* dtt0 nach d3 */
		ITT0_Dn(6)       /* itt0 nach d6 */
		CACR_D7          /* cacr nach d7 */
		move.l	#$7fc020,d0		/* ram und eprom copy back */
		D0_DTT0					/* copy back setzen */
		D0_ITT0
		move.l	#$A0808000,d0
		D0_CACR              	/* cache on */
		CPUSHA_BC
		nop
		move.w  #$2400,sr
		move.l	a7,a2			/* alter stack */
		move.w	#10000,d4		/* 10000 versuche = ca. 40ms (1 buserror ist 4us(=min. transferrate=250kb/sec)) -> min. 1500U/min */
		lea	psdm.w,a0
		move.l  d2,a1           	/* dma adresse */
		move.l	d2,a4			/* startadresse */
		add.l	d1,a4			/* +laenge=endadresse */
scsijmp:
		subq.l	#1,d1
		move.l	d1,d5			/* anzahl byts-1 */
		lsr.l	#8,d5                   /* /512 */
		lsr.l	#1,d5			/* =anzahl ganze sectoren */
		andi.l  #$1ff,d1		/* anzahl byts -1 im naechsten sector */
		lea     scsiwrlb,a3		/* sonst tabelle read nach a3 */
		btst	#0,sctr1.w              /* write? */
		bne.s	scsibs			/* ja-> */
		lea     scsirdlb,a3		/* sonst tabelle read nach a3 */
scsibs:
		sub.l   d1,a3			/* x2 weil jeder befehl wordlaenge hat */
		sub.l	d1,a3			/* - = aktuelle einsprungadresse */
		jmp	(a3)			/* verzweigen */
scsiwrloop:
		/* REPT 511 */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
        move.b  (a1)+,(a0)      /* byt verschieben */
scsiwrlb:
		subq.l  #1,d5
		bmi.s	scsiwrdone
        move.b  (a1)+,(a0)      /* byt verschieben */
		bra     scsiwrloop   /* wiederholen bis fertig */
scsiwrdone:
		bset	#0,sctr2.w	/* sonst count0/eop on */
		move.b	(a1)+,(a0)	/* dummy byt nachschieben */
		bra	scsiweiter
scsirdloop:
		/* REPT 511 */
        move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
		move.b  (a0),(a1)+		/* byt verschieben */
scsirdlb:
		subq.l  #1,d5
		bmi.s 	scsirddone
		move.b  (a0),(a1)+		/* byt verschieben */
		bra		scsirdloop		/* wiederholen bis fertig */
scsirddone:
		bset	#0,sctr2.w		/* count0 on */
		move.b	(a0),(a1)+		/* dummy byt nachschieben */
		move.l  a1,d2
		andi.b	#$fc,d2			/* letztes long */
		move.l  d2,a0
		move.l  (a0),residue.w	/* restdaten nach register */
scsiweiter:
		moveq	#0,d1			/* fertig */
scsiend:
        bset	#1,sctr1.w		/* dma on = ein int 7 scharf */
        Dn_DTT0(3)				/* dtt0 zurueck */
		Dn_ITT0(6)				/* itt0 zurueck */
		D7_CACR					/* cacr zurueck */
		CPUSHA_BC
		nop
		move.b  d1,cll.w 		/* byt zaehler zurueck */
        lsr.l	#8,d1
        move.b  d1,cml.w
        lsr.l	#8,d1
        move.b  d1,cmu.w
        lsr.l   #8,d1
        move.b  d1,cuu.w
        move.l  a1,d1			/* neue dma adresse */
		move.b  d1,all.w
		lsr.l	#8,d1
		move.b  d1,aml.w
		lsr.l   #8,d1
		move.b  d1,amu.w
		lsr.l   #8,d1
		move.b  d1,auu.w
		move.l  (sp)+,_buserror.w		/* alter buserrorvector wieder herstellen */
		movem.l (sp)+,d0-d7/a0-a4
		rte
/* ----------------------------------------------- scsi buserror */
scsibuserror:
		cmp.w	#40,_longframe.w		/* mc68040? */
		bne.s	scsibuer60              /* nein-> mc68060 */
		btst	#0,sctr1.w		/* read? */
		beq.s	scbueread40		/* ja-> */
		move.b	15(a7),d0		/* wb3s? */
		bpl.s   scb2			/* nein */
        cmp.l	24(a7),a0		/* scsiadresse */
        bne.s	scb2x			/* nein */
		subq.l	#1,a1			/* -1 wegen prefecht (a1)+,(a0) */
scb2:
		tst.b	17(a7)			/* wb2s? */
		bpl.s   scb1			/* nein */
        cmp.l	32(a7),a0		/* scsiadresse */
        bne.s	scb1x			/* nein-> */
		subq.l	#1,a1			/* -1 wegen prefecht (a1)+,(a0) */
scb1:
		tst.b	19(a7)			/* wb1s? */
		bpl.s   scbuer40w		/* nein-> */
		cmp.l	40(a7),a0       /* scsiadresse */
		bne.s	scbuer40w		/* nein-> */
		subq.l	#1,a1			/* -1 wegen prefecht (a1)+,(a0) */
		bra.s	scbuer40w
scbueread40:
		move.b	15(a7),d0		/* wb3s */
		bpl.s	scbuer40w       /* nein-> */
		move.l	24(a7),a3		/* adresse */
		move.l	28(a7),d1		/* daten */
        bsr.s	savewb
scbuer40w:
		cmp.l	20(a7),a0		/* scsidaten bereich? */
		beq.s	scsitimeout	     	/* ja -> timout */
scsibuerer:
		bset	#1,sctr1.w		/* dma on = ein, int 7 scharf */
        move.l	a2,a7           /* alter stack */
        Dn_DTT0(3)				/* dtt0 zurueck */
        Dn_ITT0(6)				/* itt0 zurueck */
        D7_CACR					/* cacr zurueck */
        CPUSHA_BC
        nop
		ori.b	#$03,sctr2.w  		/* buserror- und eop-bit setzen */
		move.l  (sp)+,_buserror.w		/* alter buserrorvector wieder herstellen */
		movem.l (sp)+,d0-d7/a0-a4
		rte
scsibuer60:
		cmp.l   8(a7),a0		/* scsidaten bereich? */
        bne.s	scsibuerer              /* nein-> bus error */
scsitimeout:
	    move.l	a2,a7			/* alter stack */
		move.l	a4,d1			/* enadresse */
		sub.l	a1,d1			/* -aktelle adresse=restbyt */
		subq.w	#1,d4			/* -1 versuch */
		bpl	scsijmp			/* abgelaufen? nein->wiedereinstieg */
		bra	scsiend
scb2x:
		move.l	24(a7),a3
		move.l	28(a7),d1
		bsr.s	savewb
		bra.w	scb2
scb1x:
		move.l	32(a7),a3
		move.l	36(a7),d1
		bsr.s	savewb
		bra	scb1
/* ------------------------------------------------------------------------------------------------------------------- */
savewb:
		move.l	#savewbber,_buserror.w		/* neuer buserrorvector */
		andi.b	#$60,d0			/* relevante bits */
		bne.s	nolong                  /* ist nicht long-> */
		move.l	d1,(a3)                 /* sonst long schreiben */
		nop
		rts
nolong:
		cmpi.b	#$20,d0			/* byt? */
		beq.s	ibyt                    /* ja-> */
nolong2:
		move.w	d1,(a3)                 /* sonst word speichern */
		nop
		rts
ibyt:
		move.b	d1,(a3)                 /* byt speichern */
		nop
		rts
savewbber:
		move.l	#scsibuserror,_buserror.w
		rte
********************************************************************************************************************


#endif
