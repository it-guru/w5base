Technical overview
==================
W5Base is a Application/Database Framework.
This Framework is basicly build on Apache, Mod_Perl2, MySQL.

W5Base is best used with Debian as server operation system. All
documentations are related to this linux distribution. Debian is
used, because most of needed packages are already included in
this distribution.

Debian documentations can be found at:
http://www.debian.org/
http://www.debian.org/releases/stable/installmanual


Installation of W5Base on Debian 5.0 (Lenny):
=============================================
total diskspace needed (incl. os) : 4GB
diskspace needed only for w5base  : ca. 600-650MB for the programmcode in /opt
total os memory recommended       : 1024MB (DBD::Oracle needs mutch space!)
min cpu speed recommended         : 1000MHz
min number of cores               : 1

 Step1: Install debian with no additional options.
 ======
 Just download netinstall iso image and install a nacked debian
 with no additional options (like "Workstation" or "Server" f.e.)


 Step2: add some packages stock debian
 ======
  sudo aptitude install openssh-server openssh-client \
       sudo subversion less sendmail \
       apache2-mpm-prefork apache2-prefork-dev \
       mysql-server mysql-client \
       alien make libc6-dev \
       perl-doc libxml-smart-perl libio-multiplex-perl  \
       libnet-server-perl  libxml-dom-perl libunicode-string-perl \
       libcrypt-des-perl libio-stringy-perl libdate-calc-perl libmime-perl \
       libdatetime-perl libdigest-sha1-perl libset-infinite-perl \
       libole-storage-lite-perl libnetaddr-ip-perl libarchive-zip-perl \
       libgd-gd2-perl libapache-dbi-perl libsoap-lite-perl \
       libnet-ldap-perl libnet-ssleay-perl libio-socket-ssl-perl \
       libapache2-mod-perl2 libapache2-mod-perl2-dev libapache2-mod-perl2-doc \
       libunicode-map8-perl


 Step3: setup webserver/basic auth for webserv and database enviroment 
 ======
   If you did not have already a /etc/profile.local file, this point is
   a good time to create it (f.e. with 0 bytes).

   Modifing apache envvars
   -----------------------
   # change /etc/apache2/envvars to
   export APACHE_RUN_GROUP=daemon
   test -s /etc/profile.local   && . /etc/profile.local

   Adding basic auth module to apache
   ----------------------------------
   W5Base only needs a apache module, which provides ...

       "HTTP Basic Authentication"

   ... There are no special requirements from W5Base system self. It is 
   recommented to use mod_auth_ae. 

   Installing apache-mod-ae
   ------------------------
   mod_auth_ae is a authentification "snapin" for apache and apache2.
   It allows to call external programms for authentification and the
   exit code of this external programm will be used as auth result.
   All auths will be cached, soo only evey max. 15min a call to the
   external programm will be done.
   
     # setup your svn env
     # add to ~/.subversion/servers (if necessary)
     [global]
     http-proxy-exceptions = *.yourintranet.de
     http-proxy-host = yourhost.de
     http-proxy-port = yourport
     http-compression = yes
 
     cd /usr/src
     #
     # checkout from repository and build the auth cache-server
     # programmcode (as root!)
     #
     svn co https://apache-mod-ae.svn.sourceforge.net/svnroot/apache-mod-ae\
            apache-mod-ae
     cd apache-mod-ae/src && make clean && make
     sudo install -m 750 -g root -o root acache /usr/sbin/acache
     sudo install -m 750 -g root -o root client /usr/sbin/acache-client
     cd ..
     #
     # install acache configuration files
     #
     cd contrib
     tar -xzvf startup.debian5.0.tgz
     sudo cp -av startup.debian5.0/aetools.conf \
                 startup.debian5.0/acache.conf /etc
     sudo cp -av startup.debian5.0/init.d/acache /etc/init.d
     sudo update-rc.d acache defaults
     cd ..
     #
     # add a default auth script
     #
     sudo install -m 0700 -o root -g root -d /usr/share/lib/acache
     sudo install -m 0500 -o root -g root authscripts/dummy.sh \
                                          /usr/share/lib/acache/dummy.sh
     #
     # build apache modul
     #
     cd apache2
     sudo make clean
     sudo make
     #
     # apache config
     #
     # ensure that file /etc/apache2/mods-available/mod_ae contains ...
     LoadModule ae_auth_module     /usr/lib/apache2/modules/ae_module.so

     # ensure that softlink exists, to enable module
     cd /etc/apache2/mods-enabled
     sudo ln -sf /etc/apache2/mods-available/mod_ae mod_auth_ae.load
     sudo rm auth_basic.load 


   Creating MySQL kernel database and service user account in database
   -------------------------------------------------------------------
   At first, you should set a root password for your mysql database.

    mysql mysql
      update user set password=password('XXXXXXX') where user='root';
      flush privileges;

   This password should be inserted in your ~/.my.cnf (rights to 0600!) 
   at block [client] like this

     [client]
     user           = root
     password       = XXXXXXX

   For the w5base system self, you should NOT use the user root as database
   account. Create a new user "w5base" in the database:

      INSERT INTO user (Host, User, Password) 
                  values ('localhost','w5base',password('MyW5BaseDBPass'));
      update user set Select_priv='Y',         Shutdown_priv='N',
                      Insert_priv='Y',         Process_priv='Y',
                      Update_priv='Y',         File_priv='Y',
                      Delete_priv='Y',         Grant_priv='Y',
                      Create_priv='Y',
                      Drop_priv='N',           References_priv='N',
                      Reload_priv='N',         Index_priv='Y',
                      Alter_priv='Y',          Show_db_priv='Y',
                      Super_priv='Y',          Create_tmp_table_priv='Y',
                      Lock_tables_priv='Y',    Execute_priv='Y',
                      Repl_slave_priv='N',     Repl_client_priv='N',
                      Create_view_priv='N',    Show_view_priv='Y',
                      Create_routine_priv='N', Alter_routine_priv='N',
                      Create_user_priv='N'
               where user='w5base';
      flush privileges;
       

   Create the database:

     mysqladmin create w5base
 
   
 Step4: add some enviroment in /etc/profile.local
 ======
   In /etc/profile.local there should be NOT terminal relevant commands, soo
   you should set only enviroment variables!
   Set W5BASEINSTDIR to directory, in which you checked
   out the repository.
   Set W5BASEDEVUSER to your account as which you want
   to develop or edit in the w5base source. Set W5BASEDEVGROUP in which
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
   umask 002  # special for working in team with outer developers
 
 
 Step5: checkout w5base from sourceforge and setup w5base /etc/w5base
 ======
   # as development user or user in which the webserver should run

   # setup your svn env
   # add to ~/.subversion/servers (if necessary)
   [global]
   http-proxy-exceptions = *.yourintranet.de
   http-proxy-host = yourhost.de
   http-proxy-port = yourport
   http-compression = yes
 
 
   # checkout w5base from SourceForge and setting up /etc/w5base
   sudo -i
   groupadd $W5BASEDEVGROUP                               # w5base dev group
   useradd -d $W5BASEINSTDIR -g $APACHE_RUN_GROUP $W5BASESRVUSER
   usermod -a -G $APACHE_RUN_GROUP $APACHE_RUN_USER
   usermod -a -G $APACHE_RUN_GROUP $W5BASEDEVUSER         
   usermod -a -G $W5BASEDEVGROUP   $W5BASEDEVUSER
   install -m 2770 -o $W5BASESRVUSER -g $APACHE_RUN_GROUP \
           -d /etc/w5base
   install -m 2770 -o $W5BASESRVUSER -g $APACHE_RUN_GROUP \
           -d /var/opt/w5base
   install -m 2770 -o $W5BASESRVUSER -g $APACHE_RUN_GROUP \
           -d /var/log/w5base
   install -m 2770 -o $W5BASESRVUSER -g $APACHE_RUN_GROUP \
           -d /var/opt/w5base/state
   install -m 2750 -o $W5BASESRVUSER -g $APACHE_RUN_GROUP -d /etc/w5base
   umask 022
   echo 'INCLUDE /etc/w5base/databases.conf'>>/etc/w5base/w5server.conf
   echo 'INCLUDE /etc/w5base/databases.conf'>>/etc/w5base/w5base.conf
   echo 'DATAOBJCONNECT[w5base]="dbi:mysql:w5base"'>>/etc/w5base/databases.conf
   echo 'DATAOBJUSER[w5base]="w5base"' >> /etc/w5base/databases.conf
   echo 'DATAOBJPASS[w5base]="MyW5BaseDBPass"' >> /etc/w5base/databases.conf
   install -m 2775 -o $W5BASEDEVUSER -g $W5BASEDEVGROUP -d $W5BASEINSTDIR
   #
   # in production enviroments, you should set W5BASEDEVGROUP to group
   # of which apache is running. In this case, you can use rights
   # 2770 for W5BASEINSTDIR . In development enviroments, 2775 rights
   # are ok.
   #
   su - $W5BASEDEVUSER
   cd $W5BASEINSTDIR/..
   svn co https://svn.code.sf.net/p/w5base/code/HEAD w5base
 
 
 Step6: add special packages from w5base repository
 ======
   cd $W5BASEINSTDIR/dependence/mandatory/IPC-Smart
   (umask 022;make clean; perl Makefile.PL && make && sudo make install)
   cd $W5BASEINSTDIR/dependence/mandatory/RPC-Smart
   (umask 022;make clean; perl Makefile.PL && make && sudo make install)
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
   You have to add the following line (if they are not exists ) 
   to /etc/apt/sources.list ...

    deb http://ftp.de.debian.org/debian/ lenny main contrib non-free
    deb-src http://ftp.de.debian.org/debian/ lenny main contrib non-free
    deb http://oss.oracle.com/debian unstable main non-free
   
   ... then run "sudo aptitude update" to load the current depot index
   files from all depots.
   After this, you have to download the Oracle Instance Client from ...

    http://www.oracle.com/technology/software/tech/oci/instantclient/

   ... as rpm. You should use "Instant Client for Linux x86" in the
   rpm "oracle-instantclient-basic-10.2.0.4-1.i386.rpm". 
   If you are using Debian Lenny of newer, you should use the oracle 11
   client!
   In Debian, you couldn't install rpms, soo you have to convert the rpm 
   to an dep package.

    sudo alien oracle-instantclient-basic-10.2.0.4-1.i386.rpm

   After this convert process, you can install oracle instance client
   like a "normale" debian package.

    sudo dpkg -i ./oracle-instantclient-basic_10.2.0.4-2_i386.deb

   In newer oracle-instantclient-basic versions, sometimes sqlplus is missing. 
   If this happens, you have to install oracle-instantclient-sqlplus
   and oracle-instantclient-devel as an additional packages from the 
   oracle site.
   
   Now ensure, that your enviroment is refreshed with ...

    . /etc/profile.local

   ... to set ORACLE_HOME in current state. Ensure that only one oracle
   Version is installed on your system. If not, you maybe have to modify
   /etc/profile.local!

   Installing DBD::Oracle have two posibilities:

       Variant 1 (recommened):
       -----------------------
        aptitude install libdbd-oracle-perl
       
      
       Variant 2:
       ----------
        sudo bash -l
        perl -MCPAN -e 'install "DBD::Oracle";'

   Now ...

    perl -MDBD::Oracle -e 'print "OK\n";'

   ... should produce no errors. To complete the installation, create
   /etc/oracle and the needed oracle connection files:

      install -m 2755 -o root -g root -d /etc/oracle

   Do not forget the files tnsnames.ora and sqlnet.ora!

   Installing ServiceCenter API
   ----------------------------
   The ServiceCenter API can remote control Peragren ServiceCenter via
   Perl. This Modul is very experimental - but it works :-)

      # setup your svn env
      # add to ~/.subversion/servers (if necessary)
      [global]
      http-proxy-exceptions = *.yourintranet.de
      http-proxy-host = yourhost.de
      http-proxy-port = yourport
      http-compression = yes


      cd /usr/src
      svn co https://sc-perl-api.svn.sourceforge.net/svnroot/sc-perl-api \
          sc-perl-api 
      cd sc-perl-api/ServiceCenter-API
      perl Makefile.PL && make && sudo make install


 
   Installing DTP Module
   ---------------------
   # setup your svn env
   # add to ~/.subversion/servers (if necessary)
   [global]
   http-proxy-exceptions = *.yourintranet.de
   http-proxy-host = yourhost.de
   http-proxy-port = yourport
   http-compression = yes

   cd /usr/src
   svn co https://perl-dtp.svn.sourceforge.net/svnroot/perl-dtp perl-dtp 
   (umask 022; cd perl-dtp/dependence && 
               tar -xzvf PDFlib-Lite-*.tar.gz && \
               cd PDFlib-*[!.tar.gz] && \
               ./configure && \
               make && sudo make install)
   (umask 022; cd perl-dtp && \
               perl Makefile.PL && make && sudo make install)
  
 
 Step7: modify the apache configuration
 ======
 Activate some modules in apache config ...
   
   sudo a2enmod proxy 
   sudo a2enmod rewrite 
  
 Modify your apache configuration in your way. A sample can be found
 at $W5BASEINSTDIR/etc/httpd

   #
   # copy default config to /etc/apache2 and include them
   #
   sudo cp /opt/w5base/etc/httpd/httpd2.conf /etc/apache2/w5base.conf
   #
   # ensure that /etc/apache2/w5base.conf is included in your 
   # default config at /etc/apache2/sites-available/default in the
   # default VirtualHost block.
   # like this ...
   #
      ...
      </Directory>
      Include /etc/apache2/w5base.conf
    </VirtualHost>
    ...

   Mod_Perl2 works better, if Apache::DBI is loaded, and as mutch as
   posible modules are preloaded. To configure this, ensure values
   in /etc/apache2/mods-enabled/perl.conf like this ...
 
   PerlModule Apache::DBI
   <Perl>
   $W5V2::INSTDIR="/opt/w5base";
   require $W5V2::INSTDIR.'/sbin/ApacheStartup.pl';
   </Perl>

   # don't forget to restart apache to activated the config changes!


   Installing Spreadsheet::ParseExcel
   ----------------------------------
   as root:
   perl -MCPAN -e 'install "Spreadsheet::ParseExcel";'



 Step8: configure W5MailGate
 ======
 add the following line to /etc/mail/aliases:

  admin:"/opt/w5base/sbin/W5MailGate -c w5base2 adminrequest>>/tmp/adm.log 2>&1"
 
 You can use alternate mail adreesses - if you want. After the modification
 don't forget to call "newaliases"



 Step9: check your installation
 ======
 In $W5BASEINSTDIR/sbin you will find a small tool called 
 W5InstallCheck. By calling $W5BASEINSTDIR/sbin/W5InstallCheck you can
 verify the integrity of your installation. With this tool most of
 mistakes can be checked.

  



Known Problems on Debian 5.0:
=============================
 - using Net::LDAP and DBD::Oracle in the same prozess enviroment
   may result in segmentation faults. This problem ist already
   comunicated to the related developers.




Running W5Base and operating hints
==================================
- With the documented default configuration, the W5Base Main-Menu is
  located at http://myservername/w5base/auth/base/menu/root. If there
  are no changes done in /etc/aetools.conf, the default user is
  dummy/admin with password acache.
  To allow the default admin in the W5Base Application, add the param
  MASTERADMIN="dummy/admin" in /etc/w5base/w5base.conf.

- W5Base Web-Frontend needs a running sbin/W5Server . This Prozess-Server
  can be started in Debug-Mode with "sbin/W5Server -d". Running W5Server
  in Debug Mode is recomented for developers. 

- If you use mod_auth_ae, you must ensure, that acache process is running

- A good debugging command for apache (hard restart) is f.e.:
  > sudo killall -HUP apache2; sudo tail -f /var/log/apache2/error.log

- W5Base makes sometimes very long querys direct over the network. This
  can produce the error "Lost connection to MySQL server during query"
  In this case modify the /etc/mysql/my.cnf as follows:
  [mysqld]
  net_read_timeout=3600
  net_write_timeout=3600
  wait_timeout=345600





Development overview:
=====================

 filesystem layout:
 ------------------
 /etc/w5base                contains all configruation files
 $W5BASEINSTDIR/bin         initial app dir for cgi web interface
 $W5BASEINSTDIR/sbin        files needed for admin and W5Server     
 $W5BASEINSTDIR/lib         librarys - this and mod/base is w5base kernel
 $W5BASEINSTDIR/static      static HTML pages distributed by W5Base code
 $W5BASEINSTDIR/skin        the frontend layout and language files
 $W5BASEINSTDIR/mod/MODUL   all modules programmcode directorys
 $W5BASEINSTDIR/sql/MODUL   module dependes sql scripts for tableversion chk
 $W5BASEINSTDIR/etc/httpd   sample web server config file
 $W5BASEINSTDIR/etc/w5base  default config of w5base application
 $W5BASEINSTDIR/contrib     sample scripts and contributed programms
 $W5BASEINSTDIR/dependence  directory to distribute perl modules 

 $W5BASEINSTDIR/etc/w5base/default.conf is the config deliverd by the
 W5Base development. In this file als default values for config variables
 are defined. There is no need to modify these files by W5Base operating!

 All web transactions are started from $W5BASEINSTDIR/bin/app.pl trow
 the apache rewrite engine. As process server, a W5Server process must
 be started and accessable.

 Rules of Development:
 ---------------------
 Rule 1: The intend of loops will be done in spaces with a count of 3


Setting W5Base in READONLY mode
===============================
Readonly mode should be used, if you want to access a stand-by mirror
of mysql. To ensure, that no write operations can be done, you should
modify the user permissions to:

      update user set Select_priv='Y',         Shutdown_priv='N',
                      Insert_priv='N',         Process_priv='Y',
                      Update_priv='N',         File_priv='Y',
                      Delete_priv='N',         Grant_priv='Y',
                      Create_priv='N',
                      Drop_priv='Y',           References_priv='N',
                      Reload_priv='N',         Index_priv='Y',
                      Alter_priv='N',          Show_db_priv='Y',
                      Super_priv='N',          Create_tmp_table_priv='N',
                      Lock_tables_priv='Y',    Execute_priv='Y',
                      Repl_slave_priv='N',     Repl_client_priv='N',
                      Create_view_priv='N',    Show_view_priv='Y',
                      Create_routine_priv='N', Alter_routine_priv='N',
                      Create_user_priv='N'
               where user='w5base';
      flush privileges;

And the change the W5BaseOperationMode to "readonly" in the W5Base config.
Ensure, that the W5BaseOperationMode is set for W5Server AND Userfrontend!

Setting W5Base in BASESLAVE mode
================================
In "baseslave" W5BaseOperationMode you can use all main tables as readonly.
In this mode, no tableversion control is done.
You can disable submodules (f.e. like base/W5Server/Cleanup.pm) by touch
on the file by extension (f.e. touch base/W5Server/Cleanup.pm.DISABLED).
If you want to disable or set readonly on dataobj modules, you have to
add configvar MODULE[base::user]="READONLY" or MODULE[base::user]="DISABLED"
