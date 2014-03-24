Native Software-Installationen:

select * from adm.agent,adm.inst_native_sw,adm.native_sw 
where adm.agent.id=adm.inst_native_sw.agent_id 
      and adm.native_sw.id=adm.inst_native_sw.native_id
      and adm.agent.hostname='Q8NWP';

