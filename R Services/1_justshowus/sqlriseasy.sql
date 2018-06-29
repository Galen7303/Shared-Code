execute sp_execute_external_script    
 @language = N'R'    
 , @script = N'    
  x <- as.matrix(InputDataSet);    
  y <- array(dim1:dim2);    
  OutputDataSet <- as.data.frame(x %*% y);'    
 , @input_data_1 = N' SELECT [Col1] from MyData;'
 , @params = N'@dim1 int, @dim2 int'
 , @dim1 = 12, @dim2 = 15
WITH RESULT SETS (([Col1] int, [Col2] int, [Col3] int, Col4 int));
go