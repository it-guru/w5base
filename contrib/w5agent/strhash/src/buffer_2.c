/*
 * reimplementation of Daniel Bernstein's buffer library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "readwrite.h"
#include "buffer.h"

static char buffer_2_space[256];

static buffer buffer_2_buf =
       BUFFER_INIT ((buffer_op_t) write, 2, buffer_2_space, 
	                                        sizeof buffer_2_space);

buffer *buffer_2 = &buffer_2_buf;
