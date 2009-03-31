At this point in the near future i hoppe there
will be a README file.

Installation on Debian 5.0 (Lenny):
===================================
total diskspace needed (incl. os) : 2GB
diskspace needed only for w5base  : ca. 100-150MB for the programmcode in /opt
total os memory recommended       : 512MB (DBD::Oracle needs mutch space!)
min cpu speed recommended         : 800MHz
min number of cores               : 1

Step1: Install with no additional options.
======


Step2: add some packages stock debian
======
  aptitude install openssh-server openssh-client sudo subversion
  aptitude install apache2-mpm-prefork mysql-server mysql-client


Step6: setup w5base /etc enviroment as webserver user
======
  # change /etc/apache2/envvars to
  export APACHE_RUN_GROUP=daemon
  test -s /etc/profile.local   && . /etc/profile.local

  
Step4: add some enviroment in /etc/profile.local
======
  In /etc/profile.local there should be NOT terminal relevant commands, soo
  you should set only enviroment variables!
  Set W5BASEINSTDIR to directory, in witch you checked
  out the repository.
  Set W5BASEDEVUSER to your account as witch you want
  to develop or edit in the w5base source. Set W5BASEDEVGROUP in witch
  other developers are. 
  # f.e. /etc/profile.local additional variables
  export W5BASEINSTDIR=/opt/w5base
  export W5BASEDEVUSER=voglerh
  export W5BASESRVUSER=w5base
  export W5BASEDEVGROUP=w5base

  Ensure that /etc/profile.local is sourced from your
  current shell and the default /etc/profile!
  # add add ent of /etc/profile
  test -s /etc/profile.local   && . /etc/profile.local
  test -s /etc/apache2/envvars && . /etc/apache2/envvars
  umask 007  # special for working in team with outer developers


Step3: checkout the current respository of w5base from sourceforge
======
  # as development user / or user in witch the webserver should run

  # setup your svn env
  # add to ~/.subversion/servers
  [global]
  http-proxy-exceptions = *.yourintranet.de
  http-proxy-host = yourhost.de
  http-proxy-port = yourport
  http-compression = yes

  # checkout w5base from sf
  sudo bash -l
  groupadd $W5BASEDEVGROUP
  usermod -a -G daemon $W5BASEDEVUSER
  usermod -a -G $W5BASEDEVGROUP $W5BASEDEVUSER
  install -o root -g daemon -d $W5BASEINSTDIR
  install -m 2770 -o $W5BASEDEVUSER -g $W5BASEDEVGROUP -d $W5BASEINSTDIR
  su - $W5BASEDEVUSER
  cd $W5BASEINSTDIR/..
  svn co https://w5base.svn.sourceforge.net/svnroot/w5base/HEAD w5base


Step5: add special packages from w5base repository
======
  cd $W5BASEINSTDIR/dependence/mandatory/IPC-Smart
  perl Makefile.PL
  make
  sudo make install
  cd $W5BASEINSTDIR/dependence/mandatory/RPC-Smart
  perl Makefile.PL && make && sudo make install


Step6: setup w5base /etc enviroment as webserver user
======
  
