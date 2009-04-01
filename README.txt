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
       alien make libc6-dev libxml-smart-perl libio-multiplex-perl  \
       libnet-server-perl  libxml-dom-perl libunicode-string-perl \
       libcrypt-des-perl libio-stringy-perl libdate-calc-perl libmime-perl \
       libdatetime-perl libdigest-sha1-perl libset-infinite-perl \
       libole-storage-lite-perl libnetaddr-ip-perl \
       libgd-gd2-perl libapache-dbi-perl \
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

     # W5Base
     export W5BASEINSTDIR=/opt/w5base
     export W5BASEDEVUSER=voglerh
     export W5BASESRVUSER=w5base
     export W5BASEDEVGROUP=w5base

     # DBD::Oracle
     export ORACLE_HOME=`echo /usr/lib/oracle/10.*/client`
     export TNS_ADMIN=/etc/oracle
     export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
     export NLS_LANG=German_Germany.WE8ISO8859P15
     export ORA_NLS33=${ORACLE_HOME}/ocommon/nls/admin/data

     # Internet-PROXY
     export ftp_proxy=http://localhost:3129
     export http_proxy=http://localhost:3129
     export FTP_PROXY=${ftp_proxy}
     export HTTP_PROXY=${http_proxy}
    
     
 
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

   Installing DBD::Oracle
   ----------------------
   Installing DBD::Oracle is a litle bit complicated.
   You have to add the following line (if the are not exists ) 
   to /etc/apt/sources.list ...

    deb http://ftp.de.debian.org/debian/ lenny main contrib non-free
    deb-src http://ftp.de.debian.org/debian/ lenny main contrib non-free
    deb http://oss.oracle.com/debian unstable main non-free
   
   ... then run "sudo aptidude update" to load the current depot index
   files from all depots.
   After this, you have to download the Oracle Instance Client from ...

    http://www.oracle.com/technology/software/tech/oci/instantclient/

   ... as rpm. You should use "Instant Client for Linux x86" in the
   rpm "oracle-instantclient-basic-10.2.0.4-1.i386.rpm". In Debian, you
   couldn't install rpms, soo you have to convert the rpm to an dep
   package.

    sudo alien oracle-instantclient-basic-10.2.0.4-1.i386.rpm

   After this convert process, you can install oracle instance client
   like a "normale" debian package.

    sudo dpkg -i ./oracle-instantclient-basic_10.2.0.4-2_i386.deb
   
   Now ensure, that your enviroment is refreshed with ...

    . /etc/profile.local

   ... to set ORACLE_HOME in current state. Ensure that only one oracle
   Version is installed on your system. In not, you maybee have to modify
   /etc/profile.local!

   Installing DBD::Oracle have to posibilities:

       Variant 1 (recommened):
       -----------------------
        aptitude install libdbd-oracle-perl
       
      
       Variant 2:
       ----------
        sudo bash -l
        perl -MCPAN -e 'install "DBD::Oracle";'

   Now ...

    perl -MDBD::Oracle 

   ... should produce no errors.
 
   Installing DTP Module
   ---------------------
   cd /usr/src
   svn co https://perl-dtp.svn.sourceforge.net/svnroot/perl-dtp perl-dtp 
   (umask 022; cd perl-dtp/dependence && 
               tar -xzvf PDFlib-Lite-*.tar.gz && \
               cd PDFlib-*[!.tar.gz] && \
               ./configure && \
               make && sudo make install)
       
   cl perl-dtp
   (umask 022; cd perl-dtp && \
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


