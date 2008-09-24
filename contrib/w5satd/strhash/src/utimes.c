/*
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include <sys/types.h>
#include <sys/time.h>
#include <utime.h>

int
utimes(char *fname, struct timeval *t)
{
	struct utimbuf u;
	/* we lose tv_usec here. oh well. */

	u.actime =  t[0].tv_sec; /* long -> time_t. */
	u.modtime = t[1].tv_sec;
	return (utime(fname, &u));
}
