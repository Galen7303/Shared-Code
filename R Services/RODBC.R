library(RODBC);
dbhandle <- odbcDriverConnect("driver={SQL Server};server=MININT-435D8DN\\SQL2014INST1;database=AdventureWorks2014;trusted_connection=true")
OutputDataSet <- sqlQuery(dbhandle, "SELECT AddressID, AddressLine1, AddressLine2, City, StateProvinceID, PostalCode, rowguid, ModifiedDate from Person.Address");
OutputDataSet
close(dbhandle)
