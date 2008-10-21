/*
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include <unistd.h>
#include "error.h"
#include "buffer.h"
#include "bailout.h"
#include "fmt.h"

const char *flag_bailout_log_name;
const char *flag_bailout_fatal_string="fatal: ";
int flag_bailout_log_pid;
int flag_bailout_fatal_begin=256;
static int is_fatal;
buffer *bailout_buffer;

void
warning(int erno, const char *s1, const char *s2, const char *s3,
        const char *s4)
{
	if (!bailout_buffer) bailout_buffer=buffer_2;
#define Y(x) buffer_puts(bailout_buffer,x)
#define X(x) if (x) Y(x)
	if (flag_bailout_log_name) Y(flag_bailout_log_name);
	if (flag_bailout_log_pid) {
		char nb[FMT_ULONG];
		nb[fmt_ulong(nb,(unsigned long) getpid())]=0;
		Y("[");
		Y(nb);
		Y("]: ");
	} else if (flag_bailout_log_name)
		Y(": ");
	if (is_fatal) 
		Y(flag_bailout_fatal_string);
	X(s1);
	X(s2);
	X(s3);
	X(s4);
	if (erno) { Y(": "); s1=error_str(erno); X(s1); }
	Y("\n");
	buffer_flush(bailout_buffer);
}
#undef X
#undef Y
void
bailout(int erno, const char *s1, const char *s2, const char *s3,
	const char *s4)
{
	warning(erno,s1,s2,s3,s4);
	_exit(1);
}
void
xbailout(int ec, int erno, const char *s1, const char *s2, const char *s3,
	const char *s4)
{
	if (ec >= flag_bailout_fatal_begin)
		is_fatal=1;
	warning(erno,s1,s2,s3,s4);
	_exit(ec);
}
#undef oom
void oom(void)
{
	xbailout(111,0,"out of memory",0,0,0);
}
void bailout_exit(int ec) { _exit(ec); }

