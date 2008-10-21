/*
 * reimplementation of Daniel Bernstein's buffer library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "buffer.h"
#include "byte.h"
#include "error.h"

#define READPOS(b) ((b)->buf+(b)->len)

static int
do_op (buffer_op_t op, int fd, char *buf, unsigned int len)
{
	while (1) {
		int r;
		r = op (fd, buf, len);
		if (r == -1)
			if (errno == error_intr)
				continue;
		/* EAGAIN? */
		return r;
	}
}

static int
copy2user (buffer * b, char *buf, unsigned int len)
{
	if (len > b->pos)
		len = b->pos;
	b->pos -= len;
	byte_copy (buf, len, READPOS(b));
	b->len += len;
	return len;
}

int
buffer_feed (buffer * b)
{
	int r;

/* If the string is nonempty, buffer_feed returns the length of the
 * string. */
	if (b->pos)
		return b->pos;

/* If the string is empty, buffer_feed uses the read operation to
 * feed data into the string; it then returns the new length of the 
 * string, or 0 for end of input, or -1 for error. */
	r = do_op (b->op, b->fd, b->buf, b->len);
	if (r <= 0)
		return r;
	b->pos = r;
	b->len -= r;
/* Note: this strange construction is needed because DJB didn't 
 * include the buffer size in struct buffer */
	if (b->len > 0)
		byte_copyr (READPOS(b), r, b->buf);
	return r;
}

char *
buffer_peek (buffer * b)
{
	return READPOS(b);
}

/* "skip this many bytes" */
void 
buffer_seek(buffer *b,unsigned int len)
{
  b->len += len;
  b->pos -= len;
}

int
buffer_get (buffer * b, char *buf, unsigned int len)
{
	int ret;
/* Normally buffer_get copies data to x[0], x[1], ..., x[len-1] from the
 * beginning of a string stored in preallocated space; removes these len
 * bytes from the string; and returns len.
 * If, however, the string has fewer than len (but more than 0) bytes,
 * buffer_get copies only that many bytes, and returns that number.
 * If the string is empty, buffer_get first uses a read operation to feed
 * data into the string. The read operation may indicate end of input, in
 * which case buffer_get returns 0; or a read error, in which case
 * buffer_get returns -1, setting errno approporiately. */

	/* fewer than len, but more than 0 */
	if (b->pos)
		return copy2user (b, buf, len);
	/* buffer too small, read directly */
	if (b->len <= len)
		return do_op (b->op, b->fd, buf, len);
	/* "read operation" to feed data into the string */
	ret = buffer_feed (b);
	if (ret <= 0)
		return ret;
	return copy2user (b, buf, len);
}

/* undocumented interface: like _get, but reads one block max. */
int
buffer_bget (buffer * b, char *buf, unsigned int len)
{
	int ret;

	if (b->pos > 0)
		return copy2user (b, buf, len);
	if (b->len <= len)
		return do_op (b->op, b->fd, buf, b->len);
	ret = buffer_feed (b);
	if (ret <= 0)
		return ret;
	return copy2user (b, buf, len);
}
