create view adm_computer
       (computer_sys_id,computer_alias,os_name,computer_model,sys_ser_num,
        create_time,update_time) as
select 'tad4dp-'||adm_computer.computer_sys_id computer_sys_id,
       adm_computer.computer_alias             computer_alias,
       adm_computer.os_name                    os_name,
       adm_computer.computer_model             computer_model,
       adm_computer.sys_ser_num                sys_ser_num,
       adm_computer.create_time                create_time,
       adm_computer.update_time                update_time
from adm.computer adm_computer;


create view adm_agent
       (agent_id,agent_node_id,enviroment,agent_custom_data1,agent_version,
        agent_ip_address,agent_hostname,agent_statusid,status,agent_osname,
        agent_osversion,agent_active,scan_time,catalog_version,full_hwscan_time,
        deleted_time) as
select 'tad4dp-'||adm_agent.id                 agent_id,
       'tad4dp-'||adm_agent.node_id            agent_node_id,
       'prod'                                  enviroment,
       adm_agent.custom_data1                  agent_custom_data1,
       adm_agent.version                       agent_version,
       adm_agent.ip_address                    agent_ip_address,
       adm_agent.hostname                      agent_hostname,
       adm_agent.status                        agent_statusid,
       adm_agent.status                        status,
       adm_agent.os_name                       agent_osname,
       adm_agent.os_version                    agent_osversion,
       adm_agent.active                        agent_active,
       adm_agent.scan_time,
       adm_agent.catalog_version,
       adm_agent.full_hwscan_time,
       adm_agent.deleted_time
from custom.agent_v adm_agent;


create view adm_instnativesw (native_id,agent_id) as
select 'tad4dp-'||adm_inst_native_sw.native_id  native_id,
       'tad4dp-'||adm_inst_native_sw.agent_id   agent_id
from adm.inst_native_sw adm_inst_native_sw;

create view adm_swproduct 
       (swproduct_id,vendor_id,swproduct_name,
        swproduct_version,is_pvu,is_rvu,is_sub_cap) as
select 'tad4dp-'||adm_swproduct.id          swproduct_id,
       'tad4dp-'||adm_swproduct.vendor_id   vendor_id,
       adm_swproduct.name                   swproduct_name,
       adm_swproduct.version                swproduct_version,
       adm_swproduct.is_pvu                 is_pvu,
       adm_swproduct.is_rvu                 is_rvu,
       adm_swproduct.is_sub_cap             is_sub_cap
from adm.swproduct  adm_swproduct;

create view adm_component
       (component_id,is_free_only,component_name) as
select 'tad4dp-'||adm_component.id   component_id,
       adm_component.is_free_only    is_free_only,
       adm_component.name            component_name
from adm.component     adm_component;

create view adm_prod_inv
       (prod_inv_id,agent_id,product_id,branch_id,component_id,prod_inv_scope,
        start_time,end_time,prod_inv_is_remote,prod_inv_confidence_level,
        stype,is_free_only) as
select 'tad4dp-'||adm_prod_inv.id              prod_inv_id,
       'tad4dp-'||adm_prod_inv.agent_id        agent_id,
       'tad4dp-'||adm_prod_inv.product_id      product_id,
       'tad4dp-'||adm_prod_inv.branch_id       branch_id,
       'tad4dp-'||adm_prod_inv.component_id    component_id,
       adm_prod_inv.scope                      prod_inv_scope,
       adm_prod_inv.start_time                 start_time,
       adm_prod_inv.end_time                   end_time,
       adm_prod_inv.is_remote                  prod_inv_is_remote,
       adm_prod_inv.confidence_level           prod_inv_confidence_level,
       swcat_branch.type                       stype,
       adm_component.is_free_only              is_free_only
       
from adm.prod_inv   adm_prod_inv
     join swcat.branch   swcat_branch
          on adm_prod_inv.branch_id=swcat_branch.id
     join adm.component adm_component
        on adm_prod_inv.component_id=adm_component.id

    

-- create view swcat_branch
--        (branch_id,stype) as
-- select 'tad4dp-'||swcat_branch.id              branch_id,
--        swcat_branch.type                       stype
-- from swcat.branch   swcat_branch;

create view adm_vendor
       (vendor_id,vendor_name) as 
select 'tad4dp-'||adm_vendor.id      vendor_id,
       adm_vendor.name               vendor_name
from adm.vendor     adm_vendor;


