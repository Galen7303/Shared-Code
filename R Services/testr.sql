execute sp_execute_external_script    
      @language = N'R'    
    , @script = N'    
    library(utils);    
    mymemory <- memory.limit();    
    OutputDataSet <- as.data.frame(mymemory);'    
    , @input_data_1 = N' ;'    
    with RESULT SETS (([Col1] int not null));
go  
 
