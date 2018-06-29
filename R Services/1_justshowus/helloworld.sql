exec sp_execute_external_script  @language =N'R',    
@script=N'OutputDataSet<-InputDataSet',      
@input_data_1 =N'select 1 as hello_world'    
with result sets (([hello_world] int not null));    
go    
