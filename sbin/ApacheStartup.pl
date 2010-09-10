#!/usr/bin/perl
BEGIN{
   foreach my $path ("$W5V2::INSTDIR/mod","$W5V2::INSTDIR/lib"){
      unshift(@INC,$path) if (!grep(/^$path$/,@INC));
   }
}
use strict;
use base::start;
use base::MyW5Base;
use base::workflow;
use base::grp;
use base::user;
use base::useraccount;
use base::userlogon;
use base::userbookmark;
use base::lnkcontact;
use base::lnkgrpuser;
use base::workflowkey;
use base::cistatus;
use base::load;
use base::filemgmt;
use base::w5stat;
use base::menu;
use base::qrule;
use base::joblog;
use base::mandator;
use base::userdefault;
use base::usermask;
return(1);
