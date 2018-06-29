select o.name, o.description  
from sys.dm_xe_objects o  
join sys.dm_xe_packages p  
on o.package_guid = p.guid  
where o.object_type = 'event'  
and p.name = 'SQLSatellite'  
order by o.name;