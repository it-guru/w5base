
#include "libhttpd.h"

int is_w5bbrequest( httpd_conn* hc );
int process_w5bbrequest(int, httpd_conn* hc );


#define W5BBREQ_STATUS 1
#define W5BBREQ_PAGE   2
#define W5BBREQ_COMBO  4
#define W5BBREQ_DATA   8

#define W5BBDIR "w5bb"
