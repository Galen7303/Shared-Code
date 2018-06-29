# Configure Data and Working Directories
projectDir <- getwd()
if (dir.exists(file.path(projectDir, "data")) == FALSE) 
{dir.create(file.path(projectDir, "data"))}
dataRead <- file.path(projectDir, "data") 
dataWrite <- dataRead

## define data file to read 
list.files(dataRead)
airlineCsv <- file.path(dataRead, "2007.csv")

## define a colInfo vector
myColInfo = rep("NULL", 29)
myColInfo[c(12, 14, 15, 16, 19)] <- "numeric"

# Build a data frame in memory for analysis
airlineDF <- read.table(file = airlineCsv, header = TRUE, sep = ",", colClasses = myColInfo)

# How big is it ?
object.size(airlineDF)

# Note: The dataframe for 2007 year and a subset of columns is ~300MB. 
# There is total of 25+ years available and 30+ columns in the total dataset.
# How many rows and what is the structure 
dim(airlineDF) 
str(airlineDF)

# Summarize the data 
summary(airlineDF)
# Create a new feature for airspeed 
airlineDF$airSpeed <- airlineDF$Distance / airlineDF$AirTime * 60 
head(airlineDF)
# Plot 
hist(airlineDF$airSpeed,breaks = 100)

#Build a dataframe with the outliers removed 
airlineDF2 <- airlineDF[(airlineDF$airSpeed > 50) & (airlineDF$airSpeed < 800),] 
dim(airlineDF2)
# make some room. With open-source R if we leave objects in our workspace # we will take 
# up valuable memory for us and anyone else sharing the machine (e.g. 
# shared R server) 
rm(airlineDF) 
gc() 
# The histogram looks better with the outliers removed 
hist(airlineDF2$airSpeed,breaks = 100)

system.time(reg3 <- lm(formula = airSpeed ~ DepDelay, data = airlineDF2))
summary(reg3)

