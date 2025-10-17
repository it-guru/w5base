use w5base;
#
alter table appl add ictoid varchar(20), add key(ictoid), add ictono varchar(20),add key(ictono);
alter table appl add acinmassignmentgroupid bigint(20), add scapprgroupid bigint(20), add scapprgroupid2 bigint(20);
alter table swinstance add acinmassignmentgroupid bigint(20), add scapprgroupid bigint(20);
alter table system add acinmassignmentgroupid bigint(20), add scapprgroupid bigint(20);
alter table asset add acinmassignmentgroupid bigint(20), add scapprgroupid bigint(20);
alter table campus add acinmassignmentgroupid bigint(20);
alter table itclust add acinmassignmentgroupid bigint(20);
alter table appl add ciamapplid varchar(40);
