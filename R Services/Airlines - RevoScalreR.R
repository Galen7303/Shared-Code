# Step 1
# Redefine airlineCsv as a RxTextData object 
airlineCsv <- RxTextData(file.path(dataRead,"2007.csv"))

# Step 2
# Some open source R functions 
head(airlineCsv)
# Or MRS functions 
rxGetInfo(data = airlineCsv) 
rxGetVarInfo(data = airlineCsv) 
rxGetInfo(data = airlineCsv, getVarInfo = TRUE, computeInfo = TRUE,  numRows=5)


# Step 3
# We will import the data into XDF format
airlineXdf <- RxXdfData(file.path(dataWrite, "2007.xdf"))

# Import the data into xdf format for further exploratory analysis. 
# We will time this one of import process
system.time(rxImport(inData = airlineCsv, outFile = airlineXdf, overwrite = TRUE))

# Get some information about the file and data 
rxGetInfo(airlineXdf) 
# Get some information about the columns and data in the xdf 
rxGetVarInfo(data=airlineXdf)
object.size(airlineXdf) 
# Note: the data is not stored in memory. The airlineXdf is an object 
# (RxXdfData).
file.size(file.path(dataWrite, "2007.xdf")) 
file.size(file.path(dataWrite, "2007.csv"))

# Step 4
# Let's define a colinfo clause to define factors and some data types
airlineColInfo <- list( 
  Year = list(newName = "Year", type = "integer"), 
  Month = list(newName = "Month", type = "factor", 
               levels = as.character(1:12), 
               newLevels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", 
                             "Aug", "Sep", "Oct", "Nov", "Dec")), 
  DayOfWeek = list(newName = "DayOfWeek", type = "factor",
                   levels = as.character(1:7), 
                   newLevels = c("Mon", "Tues", "Wed", "Thur", "Fri", "Sat", "Sun")), 
  UniqueCarrier = list(newName = "UniqueCarrier", type = "factor"), 
  TailNum = list(newName = "TailNum", type = "factor"), 
  Origin = list(newName = "Origin", type = "factor"),
  Dest = list(newName = "Dest", type = "factor") )

airlineCsv <- RxTextData(file.path(dataRead, "2007.csv"), colInfo = airlineColInfo)
blockSize = 250000
# We can read a subset (first 100K) to see what the data looks like. 
system.time(rxImport(
  inData = airlineCsv, outFile = airlineXdf, 
  overwrite = TRUE, colInfo = airlineColInfo, 
  rowsPerRead = blockSize, 
  numRows = 100000))
# Get some information about the file and data 
rxGetInfo(airlineXdf) 
# Get some information about the columns and data in the xdf 
rxGetVarInfo(data=airlineXdf)


# Step 5
# We can also perform on the fly data transformations as we import and 
# calculate new features. For this we will create a helper functions 
ConvertToDecimalTime <- function( tm ){(tm %/% 100) + (tm %% 100)/60}
system.time(
  rxImport(inData = airlineCsv, outFile = airlineXdf, 
           overwrite = TRUE, colInfo = airlineColInfo, 
           transforms = list(
             FlightDate = as.Date(as.character((as.numeric(Year) * 10000) 
                                               +(as.numeric(Month) * 100) 
                                               +as.integer((
                                                 format(as.numeric(DayOfWeek), width = 2, flag = "0")))), 
                                  format = "%Y%m%d"), 
             CRSDepTime = ConvertToDecimalTimeFn(CRSDepTime),
             DepTime = ConvertToDecimalTimeFn(DepTime), 
             CRSArrTime = ConvertToDecimalTimeFn(CRSArrTime), 
             ArrTime = ConvertToDecimalTimeFn(ArrTime), 
             MonthsSince198710 = as.integer((as.numeric(Year) - 1987) * 12 + 
                                              as.numeric(Month) - 10), 
             DaysSince19871001 = as.integer(FlightDate - as.Date("1987-10-01", format = "%Y-%m-%d"))), 
           transformObjects = list(ConvertToDecimalTimeFn = ConvertToDecimalTime), 
           rowsPerRead = blockSize)) 
# Get some information about the file and data 
rxGetInfo(airlineXdf)
# Get some information about the columns and data in the xdf 
rxGetVarInfo(data = airlineXdf) 
# Note: MRS pre-computes and stored the low/high values for numeric data # which can be useful in optimising other processing. Categorical data  # is stored as integer "levels" with metadata referencing the factor  
# values. MRS provides methods for the following functions for supported # data-sources 
head(airlineXdf) 
tail(airlineXdf) 
names(airlineXdf) 
dim(airlineXdf) 
dimnames(airlineXdf) 
nrow(airlineXdf) 
ncol(airlineXdf)
# Read and display some rows from the file 
rxReadXdf(airlineXdf, numRows=3)
# We can read from different points in the file 
startPoint <- nrow(airlineXdf) - 5 
rxReadXdf(airlineXdf, startRow = startPoint)
rxReadXdf(airlineXdf, startRow = 3983467, numRows = 3)

# Step 6
# Compute descriptive statistics using rxSummary() 
rxSummary( ~ ActualElapsedTime + AirTime + DepDelay + Distance, data = airlineXdf) 
# Note: MRS uses R's formula interface to enable a subset of columns 
# to be analysed. 
# For all numeric and factor columns you can use 
rxSummary( ~ ., airlineXdf, reportProgress = 1) 
# or MRS provides a method for summary that does the same thing 
summary(airlineXdf)
# Plot some histograms of the data 
rxHistogram(~DepDelay, data=airlineXdf, reportProgress = 1 )
# We can remove outliers by restricting the x Axis min and max 
rxHistogram( ~ DepDelay, data = airlineXdf, reportProgress = 1, 
             xAxisMinMax = c(-100, 400), numBreaks = 500, 
             xNumTicks = 10)
# We can see if the distribution is different by day of week 
rxHistogram( ~ DepDelay | DayOfWeek, data = airlineXdf, 
             reportProgress = 1, xAxisMinMax = c(-100, 400), numBreaks = 500, 
             xNumTicks = 10)



# Step 7
# Add a new feature (derived column) to the data 
# rxDataStep processes data in blocks and applies the transforms to each block 
rxDataStep(inData = airlineXdf, outFile = airlineXdf, 
           varsToKeep = c("AirTime", "Distance"), 
           transforms = list(AirSpeed = Distance / AirTime * 60), 
           append = "cols", overwrite = TRUE, reportProgress = 1)
# Check the new column is there. Couple of ways... 
rxGetInfo(data = airlineXdf, getVarInfo = TRUE) 
rxGetInfo(data = airlineXdf, getVarInfo = TRUE, varsToKeep = "AirSpeed")
# Get summary information and histogram for AirSpeed 
rxSummary( ~ AirSpeed, data = airlineXdf) 
rxHistogram( ~ AirSpeed, data = airlineXdf) 
# Clearly we have some outliers and caused by data quality issues
# Lets use the rowSelection argument to remove the obvious outliers! 
rxHistogram( ~ AirSpeed, data = airlineXdf, 
             rowSelection = (AirSpeed > 50) & (AirSpeed < 800), 
             numBreaks = 5000, xNumTicks = 20, reportProgress = 1)


# Step 8
# Is there an obvious correlation between arrival and departure delay and airspeed 
rxCor(formula=~DepDelay+ArrDelay+AirSpeed, data=airlineXdf)
# What if we remove the outliers ? 
blah <- rxCor(formula = ~DepDelay + ArrDelay + AirSpeed, 
              data = airlineXdf, 
              rowSelection = (AirSpeed > 50) & (AirSpeed < 800), reportProgress = 1) 
str(blah)



#Step 9 
# We can now create a linear model using the rxLinMod-function. 
# Note the difference between this and the standard lm function run previously
system.time({ airline.model <- rxLinMod(formula = AirSpeed ~ DepDelay, 
                                        data = airlineXdf, 
                                        rowSelection = (AirSpeed > 50) & (AirSpeed < 800),
                                        reportProgress = 1)
})
airline.model
summary(airline.model)
