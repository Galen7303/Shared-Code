use contosoretaildw20
go
execute sp_execute_external_script    
 @language = N'R'    
 , @script = N'OutputDataSet <- InputDataSet;'    
 , @input_data_1 = N'select count(*) from FactSales'
WITH RESULT SETS (([count] int));
go