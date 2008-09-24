/*
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef attributes_h
#define attributes_h

#ifdef __GNUC__
# ifdef __GNUC_MINOR__
#   define GNUC_MINIMUM(maj, min) \
   ((__GNUC__ > (maj)) || (__GNUC__ == (maj) && __GNUC_MINOR__ >= (min)))
# endif
#endif
#ifndef GNUC_MINIMUM
# define GNUC_MINIMUM(maj, min) 0
#endif                                         

	/* gcc.info sagt, noreturn wäre ab 2.5 verfügbar. HPUX-gcc 2.5.8
	 * kann es noch nicht - what's this?
	 */
#if GNUC_MINIMUM(2,6)
# define attribute_noreturn  __attribute__((__noreturn__))
#else
# define attribute_noreturn
#endif

#if GNUC_MINIMUM(2,96)
# define attribute_pure  __attribute__((__pure__))
#else
# define attribute_pure
#endif

#if GNUC_MINIMUM(2,5)
#  define attribute_const  __attribute__((__const__))
#else
# define attribute_const
#endif
	/* 
	 * checked Formatstring (Argument Nr. "formatnr"). Der erste 
	 * Parameter des Formatstrings ist Argument Nr. "firstargnr".
	 * für vprintf und co, wo das nicht möglich ist, ist firstargnr
	 * auf 0 zu setzen -> nur Formatstring wird geprüft.
	 */
#if GNUC_MINIMUM(2,6) 
# define attribute_printf(formatnr,firstargnr)  \
	__attribute__((__format__ (printf,formatnr,firstargnr)))
#else
# define attribute_printf(x,y)
#endif

/* die beiden folgenden werden nur definiert, wenn die Funktionalität
 * verfügbar ist. "#define dies [leer]" macht hier keinen Sinn, weil 
 * der entsprechende Code nie ausgeführt würde. 
 * Also: Mit Vorsicht benutzen.
 */
#if GNUC_MINIMUM(2,5)
#  define attribute_constructor  __attribute__((__constructor__))
#  define attribute_destructor  __attribute__((__destructor__))
#endif

#if GNUC_MINIMUM(2,7)
# define attribute_unused __attribute__((__unused__))
#else
# define attribute_unused
#endif

#if GNUC_MINIMUM(2,95)
# define attribute_malloc __attribute__((__malloc__))
#else
# define attribute_malloc
#endif

#define attribute_inline __inline__

#if GNUC_MINIMUM(2,7) /* doesn't work reliable before, IIRC */
# define attribute_regparm(x) __attribute__((__regparm__((x))))
#else
# define attribute_regparm(x)
#endif
#if GNUC_MINIMUM(2,7)
# define attribute_stdcall __attribute__((__stdcall__))
#else
# define attribute_stdcall
#endif

#if GNUC_MINIMUM(3,0) 
#else
# define __builtin_expect(x,y) (x)
#endif
#define attribute_expect(x,y) __builtin_expect((x),(y))
#define EXPECT(x,y)           attribute_expect((x),(y))

#endif
