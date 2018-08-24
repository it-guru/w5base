Config-Parameters of W5Base
===========================

Alle config parameter names are handled case insensiv, soo you can write
them in the config files in a case whoever you want.
Most of the config parameters have default values. You can find these
default values at $W5BASEINSTDIR/etc/w5base/default.conf .


HTTP_PROXY                 f.e.: "http://F4DE8PSA010.blf.telekom.de:8080"
----------
Some modules uses access to internet sites. If you are not
directly connected to the internet, you have die specify
your Internet-Proxy in this variable.


MimeTypes                  f.e.: "/etc/mime.types"
---------
Defines the path to the mime.types table. This parameter is needed 
specialy by the base::filemgmt module.

Logging                    f.e.: "sqlwrite,-sqlread"
-------
You can specified the logging in different contextes. If you set a "-" in
front of the metric, this logging will be deactivated. If you not specified
a metric, the default handling for this metric will be used. In W5Server
operations is this logging to STDERR and in Apache operations, this is
writing to the apache error.log file.
Posible values are:

 soap               requests handled by SOAP operations
 sqlwrite           nativ sql write operations
 w5server_sqlwrite  nativ sql write operatons from w5server
 w5server_sqlread   nativ sql read operations from w5server
 sqlread            nativ sql read operations
 viewreq            field constellation of user view requests
 query              informations about the query parameters
 trigger            informations from trigger event handlers

If you put a w5server_ in front of a metric, you can sepcify a special
handling in w5server context for this metric.

CleanupJobLog     (Default = "<now-84d")  based on 'mdate'
CleanupInfoAbo    (Default = "<now-56d")  based on 'expiration'
CleanupInline     (Default = "<now-84d")  based on 'viewlast'
CleanupUserLogon  (Default = "<now-365d") based on 'logondate'
CleanupHistory    (Default = "<now-730d") based on 'cdate'
---------------------------------------------------------------
These parameters modifies the cleanup handling. The daily cleanup job
deletes all records with the specified timing parameters.

W5BaseMailAllow
---------------
By default, nobody gets mails from the application in test and development
operation mode. If you specify a list auf mail adresses (semicolon seperated)
in this config variable, these persons will get mails.
All other mail adresses will be redirected to @null.com domain.
If you do changes in this config-var, you have to restart the W5Server 
process.



Draft (German):
===============
Die Konfigurationsdatei, die W5Base/Darwin verwendet, wird bei Web-Requests aus der URL abgeleitet.

Wird z.B. auf W5Base/Darwin über die URL https://darwin.telekom.de/*configname*/auth/base/menu/root zugegriffen, so wird im Verzeichnis /etc/w5base nach einer Konfigurationsdatei "configname.conf" gesucht. Der Name der Konfig-Datei ist also immer die erste Ebene oberhalb der Web-Name-Space "auth" oder "public".

In der Konfigurationsdatei können dann INCLUDE Anweisungen verwendet werden. Dies macht es dann relativ einfach, teilweise unterschiedliche Site-Konfigurationen auf einem Web-Server effizient zu verwalten.

Bei Serverkomandos (z.B. W5Event, W5Server, W5Replicate ...) wird die Konfigurationsdatei mit der Option -c and die Kommandos übergeben.

*  DATAOBJCONNECT
  DBI Connect String

* DATAOBJUSER
  Username, mit dem sich auf das Datenbackend verbunden werden soll

* DATAOBJPASS
  Passwort, mit dem sich auf das Datenbackend verbunden werden soll.

* MASTERADMIN
  REMOTE_USER Name des Admins, falls die User-Verwaltung noch nicht 
  initialisiert ist. Dieser User-Account ist IMMER Admin - egal ob
  er in der eigentlichen Gruppe "admin" als Member eingetragen ist
  oder nicht.

* MIMETYPES
  Pfad zur Mimetypes Tabelle

* SITENAME
  Klartext-Name der Applikation (NICHT der DNS Name!)

* SKIN
  Oberflächen Skin name

* AutoLoadMenuPath
  Allows to define a MenuPath, which should be loaded if no MenuPath is
  selected (f.e. in case of start w5base application in webfrontend)

* WEBSERVICEPROXY
  Bei Webservice Verbindungen wird in dieser Variabel die PROXY (nicht Web-Proxy!) URL abgespeichert.

* WEBSERVICEUSER
  Bei Webservice Verbindungen der Username, mit dem der Web-Service authentifiziert werden soll.

* WEBSERVICEPASS
  Bei Webservice Verbindungen das Passwort, mit dem der Web-Service authentifiziert werden soll.

* W5BaseOperationMode
  Der Betriebsmodus der Anwendung

* W5ServerHost
  Der W5Server Host (IP-Adresse), auf den sich verbunden werden soll

* EventJobBaseUrl
  Die URL, die beim Versand von Mails über Event-Scripts als Basis-Adresse verwendet werden muß.

* QualityCheckDuration
  Die Dauer (in Sekdunden), wie lange in den tgl. Nachläufen der QualityCheck laufen darf.

* MAILBOUNCEHANDLER
  Mailadresse, an die die Bouce-Mails adressiert werden sollen.

* SMSInterfaceScript
  Pfad zum Interface-Script, dass das versenden der SMS Nachrichten übernimmt.

* W5BaseMailAllow
  An diese Mailadressen darf (im Test und Entwicklungsmodus) eine Mail versandt werden. Allen anderen Mailadressen werden hinter dem @ mit null.com ersetzt.

* W5ServerPort
  Option für den W5Server. Auf diesem Port wird der Listener des W5Server gestartet.

* W5ServerState
  Option für den W5Server. Status Verzeichnis des W5Servers.



