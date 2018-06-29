use contosoretaildw20
go
execute sp_execute_external_script    
 @language = N'R'    
 , @script = N'    
lmmodel <-rxLinMod(OnHandQuantity ~ OnOrderQuantity, InputDataSet, covCoef = TRUE, covData = TRUE);   
rxCovCoef(lmmodel);'    
, @input_data_1 = N'SELECT OnHandQuantity, OnOrderQuantity FROM dbo.FactInventory;'
WITH RESULT SETS ((col1 float, col2 float));
go