use w5base;
create table interface_tscape_v_darwin_export(
    icto_nummer varchar(40) not null,
    internal_key varchar(40) not null,
    name varchar(255),
    status varchar(20),
    kurzbezeichnung varchar(255),
    beschreibung longtext,
    geplantes_retirement_datum datetime,
    startdatum datetime,
    endedatum datetime,
    organisation varchar(80),
    unique key(icto_nummer)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
