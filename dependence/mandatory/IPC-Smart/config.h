/*
 * This file was produced by running the config_h.SH script, which
 * gets its values from config.sh, which is generally produced by
 * running Configure.
 *
 * Feel free to modify any of this as the need arises.  Note, however,
 * that running config_h.SH again will wipe out any changes you've made.
 * For a more permanent change edit config.sh and rerun config_h.SH.
 *
 * $Id: config_h.SH,v 1.1.1.1 2000/04/14 09:23:54 maurice Exp $
 */

/*
 * Package name      : IPC-ShareLite
 * Source directory  : .
 * Configuration time: Fri Jan 22 15:44:39 CET 2010
 * Configured by     : voglerh
 * Target system     : linux e8npnu08 2.6.18-xen #1 smp fri jun 1 15:01:20 bst 2007 i686 gnulinux 
 */

#ifndef _config_h_
#define _config_h_

/* VOIDFLAGS:
 *	This symbol indicates how much support of the void type is given by this
 *	compiler.  What various bits mean:
 *
 *	    1 = supports declaration of void
 *	    2 = supports arrays of pointers to functions returning void
 *	    4 = supports comparisons between pointers to void functions and
 *		    addresses of void functions
 *	    8 = suports declaration of generic void pointers
 *
 *	The package designer should define VOIDUSED to indicate the requirements
 *	of the package.  This can be done either by #defining VOIDUSED before
 *	including config.h, or by defining defvoidused in Myinit.U.  If the
 *	latter approach is taken, only those flags will be tested.  If the
 *	level of void support necessary is not present, defines void to int.
 */
#ifndef VOIDUSED
#define VOIDUSED 15
#endif
#define VOIDFLAGS 15
#if (VOIDFLAGS & VOIDUSED) != VOIDUSED
#define void int		/* is void to be avoided? */
#define M_VOID			/* Xenix strikes again */
#endif

/* HAS_UNION_SEMUN:
 *	This symbol, if defined, indicates that the union semun is
 *	defined by including <sys/sem.h>.  If not, the user code
 *	probably needs to define it as:
 *	union semun {
 *	    int val;
 *	    struct semid_ds *buf;
 *	    unsigned short *array;
 *	}
 */
/*#define HAS_UNION_SEMUN	/ **/

#endif
