/*
 * resource set indices for deskru
 *
 * created by ORCS 2.14
 */

/*
 * Number of Strings:        420
 * Number of Bitblks:        1
 * Number of Iconblks:       14
 * Number of Color Iconblks: 0
 * Number of Color Icons:    0
 * Number of Tedinfos:       46
 * Number of Free Strings:   52
 * Number of Free Images:    0
 * Number of Objects:        443
 * Number of Trees:          24
 * Number of Userblks:       0
 * Number of Images:         29
 * Total file size:          25236
 */

#undef RSC_NAME
#define RSC_NAME "deskru"
#undef RSC_ID
#ifdef deskru
#define RSC_ID deskru
#else
#define RSC_ID 0
#endif

#if !defined(RSC_STATIC_FILE) || !RSC_STATIC_FILE
#define NUM_STRINGS 420
#define NUM_FRSTR 52
#define NUM_UD 0
#define NUM_IMAGES 29
#define NUM_BB 1
#define NUM_FRIMG 0
#define NUM_IB 14
#define NUM_CIB 0
#define NUM_TI 46
#define NUM_OBS 443
#define NUM_TREE 24
#endif



#define MENU1              0 /* menu */

#define FORM2              1 /* form/dialog */

#define FORM3              2 /* form/dialog */

#define FORM4              3 /* form/dialog */

#define FORM5              4 /* form/dialog */

#define FORM6              5 /* form/dialog */

#define FORM7              6 /* form/dialog */

#define FORM8              7 /* form/dialog */

#define FORM9              8 /* form/dialog */

#define FORM10             9 /* form/dialog */

#define FORM11            10 /* form/dialog */

#define FORM12            11 /* form/dialog */

#define FORM13            12 /* form/dialog */

#define FORM14            13 /* form/dialog */

#define FORM15            14 /* form/dialog */

#define FORM16            15 /* form/dialog */

#define FORM17            16 /* form/dialog */

#define FORM18            17 /* form/dialog */

#define FORM19            18 /* form/dialog */

#define FORM20            19 /* form/dialog */

#define FORM21            20 /* form/dialog */

#define FORM22            21 /* form/dialog */

#define FORM23            22 /* form/dialog */

#define FORM24            23 /* form/dialog */

#define ALERT1             0 /* Alert string */

#define ALERT2             1 /* Alert string */

#define ALERT3             2 /* Alert string */

#define ALERT4             3 /* Alert string */

#define ALERT5             4 /* Alert string */

#define ALERT6             5 /* Alert string */

#define ALERT7             6 /* Alert string */

#define ALERT8             7 /* Alert string */

#define ALERT9             8 /* Alert string */

#define ALERT10            9 /* Alert string */

#define ALERT11           10 /* Alert string */

#define ALERT12           11 /* Alert string */

#define ALERT13           12 /* Alert string */

#define ALERT14           13 /* Alert string */

#define ALERT15           14 /* Alert string */

#define ALERT16           15 /* Alert string */

#define ALERT17           16 /* Alert string */

#define ALERT18           17 /* Alert string */

#define ALERT19           18 /* Alert string */

#define ALERT20           19 /* Alert string */

#define ALERT21           20 /* Alert string */

#define ALERT22           21 /* Alert string */

#define ALERT23           22 /* Alert string */

#define ALERT24           23 /* Alert string */

#define ALERT25           24 /* Alert string */

#define ALERT26           25 /* Alert string */

#define ALERT27           26 /* Alert string */

#define ALERT28           27 /* Alert string */

#define ALERT29           28 /* Alert string */

#define ALERT30           29 /* Alert string */

#define ALERT31           30 /* Alert string */

#define ALERT32           31 /* Alert string */

#define ALERT33           32 /* Alert string */

#define ALERT34           33 /* Alert string */

#define ALERT35           34 /* Alert string */

#define ALERT36           35 /* Alert string */

#define ALERT37           36 /* Alert string */

#define ALERT38           37 /* Alert string */

#define ALERT39           38 /* Alert string */

#define ALERT40           39 /* Alert string */

#define ALERT41           40 /* Alert string */

#define ALERT42           41 /* Alert string */

#define ALERT43           42 /* Alert string */

#define ALERT44           43 /* Alert string */

#define ALERT45           44 /* Alert string */

#define ALERT46           45 /* Alert string */

#define ALERT47           46 /* Alert string */

#define ALERT48           47 /* Alert string */

#define ALERT49           48 /* Alert string */

#define ALERT50           49 /* Alert string */

#define ALERT51           50 /* Alert string */

#define ALERT52           51 /* Alert string */




#ifdef __STDC__
#ifndef _WORD
#  ifdef WORD
#    define _WORD WORD
#  else
#    define _WORD short
#  endif
#endif
extern _WORD deskru_rsc_load(void);
extern _WORD deskru_rsc_gaddr(_WORD type, _WORD idx, void *gaddr);
extern _WORD deskru_rsc_free(void);
#endif
