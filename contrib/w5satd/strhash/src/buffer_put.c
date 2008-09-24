/*
 * reimplementation of Daniel Bernstein's buffer library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "buffer.h"
#include "str.h"
#include "byte.h"
#include "error.h"

static int
do_op (buffer_op_t op, int fd, const char *cbuf, unsigned int len)
{
	union { const char *cc; char *c; } x;
	char *buf;
	x.cc=cbuf;
	buf=x.c;
	while (len) {
		int w;
		w = op (fd, buf, len);
		if (w == -1) {
			if (errno == error_intr) /* EAGAIN? */
				continue;
			return -1; /* the file may be corrupted. */
		}
		buf += w;
		len -= w;
	}
	return 0;
}

int
buffer_flush (buffer * b)
{
	int ret;
	if (!b->pos)
		return 0;
	ret=do_op (b->op, b->fd, b->buf, b->pos);
	b->pos=0;
	return ret;
}

/* buffer_putalign fills all available
   space with data before calling buffer_flush. 
 */

/* when there isn't enough space for new data, buffer_put calls buffer_flush
   before copying any data,
 */
int
buffer_put (buffer * b, const char *buf, unsigned int len)
{
	if (len > b->len - b->pos) {
		if (buffer_flush (b) == -1)
			return -1;
		while (len > b->len) {
			unsigned int n=len;
			if (n>BUFFER_OUTSIZE)
				n=BUFFER_OUTSIZE;
			if (do_op (b->op, b->fd, buf, n) == -1)
				return -1;
			buf+=n;
			len-=n;
		}
	}
	byte_copy (b->buf + b->pos, len, buf);
	b->pos += len;
	return 0;
}

/* buffer_putflush is similar to buffer_put followed by buffer_flush. */
/* which isn't how DJB implemented it (first flush, then write new data,
 * then flush again) */
int 
buffer_putflush(buffer *b,const char *buf,unsigned int len)
{
	if (-1==buffer_put(b,buf,len))
		return -1;
	return buffer_flush(b);
}

int 
buffer_puts(buffer *b,const char *buf)
{
	return buffer_put(b,buf,str_len(buf));
}

int buffer_putsflush(buffer *b,const char *buf)
{
	return buffer_putflush(b,buf,str_len(buf));
}

int
buffer_putalign (buffer * b, const char *buf, unsigned int len)
{
	unsigned int isfree=b->len - b->pos;

	if (len > isfree) {
		if (-1==buffer_put(b,buf,isfree))
			return -1;
		len-=isfree;
		buf+=isfree;
	}
	return buffer_put(b,buf,len);
}

int 
buffer_putsalign(buffer *b,const char *buf)
{
	return buffer_putalign(b,buf,str_len(buf));
}
