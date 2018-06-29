sqlConnString <- "Driver={SQL Server};Server=.;Database=ContosoRetaildw20;Trusted_Connection=true;"
sqlCompute <- RxInSqlServer(connectionString = sqlConnString, wait = TRUE, consoleOutput = TRUE)
rxSetComputeContext("sqlCompute")
dsSqlServerData <- RxSqlServerData(sqlQuery = "SELECT OnHandQuantity, OnOrderQuantity FROM dbo.FactInventory", connectionString = sqlConnString)
lmmodel <- rxLinMod(OnHandQuantity ~ OnOrderQuantity, dsSqlServerData, covCoef = TRUE, covData = TRUE)
rxCovCoef(lmmodel)
