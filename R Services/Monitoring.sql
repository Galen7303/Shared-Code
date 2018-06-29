select * from sys.dm_external_script_requests
go

select o.name, o.description  
from sys.dm_xe_objects o  
join sys.dm_xe_packages p  
on o.package_guid = p.guid  
where o.object_type = 'event'  
and p.name = 'SQLSatellite'  
order by o.name;

execute sp_execute_external_script    
      @language = N'R'    
    , @script = N'    
    library(utils);    
    mymemory <- memory.limit();    
    OutputDataSet <- as.data.frame(mymemory);'    
    , @input_data_1 = N' ;'    
    with RESULT SETS (([Col1] int not null));
go  
 
