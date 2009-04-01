Installation on Debian 5.0 (Lenny):
===================================
total diskspace needed (incl. os) : 2GB
diskspace needed only for w5base  : ca. 100-150MB for the programmcode in /opt
total os memory recommended       : 512MB (DBD::Oracle needs mutch space!)
min cpu speed recommended         : 800MHz
min number of cores               : 1

 Step1: Install debian with no additional options.
 ======
 Just download netinstall iso image and install a nacked debian
 with no additional options (like "Workstation" or "Server" f.e.)


 Step2: add some packages stock debian
 ======
  sudo aptitude install openssh-server openssh-client sudo subversion \
       apache2-mpm-prefork mysql-server mysql-client \
       make libc6-dev libxml-smart-perl libio-multiplex-perl  \
       libnet-server-perl  libxml-dom-perl libunicode-string-perl \
       libcrypt-des-perl libio-stringy-perl libdate-calc-perl libmime-perl \
       libdatetime-perl libdigest-sha1-perl libset-infinite-perl \
       libole-storage-lite-perl libnetaddr-ip-perl \
       libapache-dbi-perl \
       libapache2-mod-perl2 libapache2-mod-perl2-dev libapache2-mod-perl2-doc \


 Step6: setup webserver/basic auth for webserv and database enviroment 
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
 
 
 Step3: checkout w5base from sourceforge and setup w5base /etc/w5base
 ======
   # as development user or user in witch the webserver should run
 
   # setup your svn env
   # add to ~/.subversion/servers
   [global]
   http-proxy-exceptions = *.yourintranet.de
   http-proxy-host = yourhost.de
   http-proxy-port = yourport
   http-compression = yes
 
   # checkout w5base from sf and setting up /etc/w5base
   sudo bash -l
   groupadd $W5BASEDEVGROUP                               # w5base dev group
   useradd -d $W5BASEINSTDIR -g $APACHE_RUN_GROUP w5base  # w5base service user
   usermod -a -G $APACHE_RUN_GROUP $W5BASEDEVUSER         
   usermod -a -G $W5BASEDEVGROUP $W5BASEDEVUSER
   install -m 2750 -o $W5BASESRVUSER -g $APACHE_RUN_GROUP -d /etc/w5base
   echo 'include /etc/w5base/databases.conf' >> /etc/w5base/w5server.conf
   echo 'include /etc/w5base/databases.conf' >> /etc/w5base/w5base.conf
   echo 'DATAOBJCONNECT[w5base]="dbi:mysql:w5base"' >> /etc/w5base/database.conf
   echo 'DATAOBJUSER[w5base]="w5base"' >> /etc/w5base/database.conf
   echo 'DATAOBJPASS[w5base]="MyW5BaseDBPass"' >> /etc/w5base/database.conf
   install -m 2770 -o $W5BASEDEVUSER -g $W5BASEDEVGROUP -d $W5BASEINSTDIR
   su - $W5BASEDEVUSER
   cd $W5BASEINSTDIR/..
   svn co https://w5base.svn.sourceforge.net/svnroot/w5base/HEAD w5base
 
 
 Step5: add special packages from w5base repository
 ======
   cd $W5BASEINSTDIR/dependence/mandatory/IPC-Smart
   (umask 022; perl Makefile.PL && make && sudo make install)
   cd $W5BASEINSTDIR/dependence/mandatory/RPC-Smart
   (umask 022; perl Makefile.PL && make && sudo make install)
   cd $W5BASEINSTDIR/dependence/mandatory
   (umask 022; tar -xzvf DateTime-Set-*.tar.gz && \
               cd DateTime-Set-*[!.tar.gz] && \
               perl Makefile.PL && make && sudo make install)
   (umask 022; tar -xzvf Data-HexDump-*.tar.gz && \
               cd Data-HexDump-*[!.tar.gz] && \
               perl Makefile.PL && make && sudo make install)
   (umask 022; tar -xzvf Spreadsheet-WriteExcel-*.tar.gz && \
               cd Spreadsheet-WriteExcel-*[!.tar.gz] && \
               perl Makefile.PL && make && sudo make install)
   (umask 022; tar -xzvf Env-C-*.tar.gz && \
               cd Env-C-*[!.tar.gz] && \
               perl Makefile.PL && make && sudo make install)
 
 
 Step7: check your installation
 ======
 In $W5BASEINSTDIR/sbin you will find a small tool called 
 W5InstallCheck. By calling $W5BASEINSTDIR/sbin/W5InstallCheck you can
 verify the integrity of your installation. With this tool most of
 mitakes can be checked.
  


Known Problems on Debian 5.0:
=============================
 - using Net::LDAP and DBD::Oracle in the same prozess enviroment
   may result in segmentation faults. This problem ist already
   comunicated to the related developers.


Development:
============

 filesystem layout:
 ------------------
 /etc/w5base                contains all configruation files
 $W5BASEINSTDIR/mod         all modules
 $W5BASEINSTDIR/lib         librarys - this and mod/base is w5base kernel
 $W5BASEINSTDIR/skin        the frontend layout and language files
 $W5BASEINSTDIR/sbin        files needed for admin and W5Server     
 $W5BASEINSTDIR/bin         initial app dir for cgi web interface
 $W5BASEINSTDIR/etc/httpd   sample web server config file
 $W5BASEINSTDIR/etc/w5base  default config of w5base application

 $W5BASEINSTDIR/etc/w5base/default.conf is the config deliverd by the
 W5Base development. In this file als default values for config variables
 are defined. There is no need to modify these files by W5Base operating!


