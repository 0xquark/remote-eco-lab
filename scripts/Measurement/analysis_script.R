#Open Source Consumption Analysis and Reporting
#Copyright (C) Achim Guldner
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <https://www.gnu.org/licenses/>.

setwd(dirname("/Users/karanjotsingh/Downloads/Readings/"))

# Inputs:
scenarioMarkersFilename <- "log_sus.csv"
PowerScenarioFilename <- "pm_sus.csv"
performanceScenarioFilename <- "hw_sus.csv"
# set gpuScenarioFilename to NULL (or comment out) if no gpu data is available
gpuScenarioFilename <- NULL
# set modelHistoryFilename to NULL (or comment out) if no history is available
# !CAUTION! You need to handle the formatting yourself. It is done in lines 97ff and 520ff
modelHistoryFilename <- NULL

baselineMarkersFilename <- "log_baseline.csv"
PowerBaselineFilename <- "pm_bse.csv"
performanceBaselineFilename <- "hw_bse.csv"
gpuBaselineFilename <- NULL

markersTimestampFormat <- "%y-%m-%d %H:%M:%OS"
energyConsumptionTimestampFormat <- "%d.%m.%y %H:%M:%OS"
performanceTimestampFormat <- "%Y%m%d %H:%M:%OS"
gpuTimestampFormat <- "%Y/%m/%d %H:%M:%OS"

# Specify column names containing measurements for (in order): ram, networkReceived, networkSent, diskRead, diskWritten
performanceDataColumns <- c("MEM.Used", "NET.RxKBTot", "NET.TxKBTot", "DSK.ReadTot", "DSK.WriteTot")
performanceBaselineColumns <- c("MEM.Used", "NET.RxKBTot", "NET.TxKBTot", "DSK.ReadTot", "DSK.WriteTot")
# Specify column names containing measurements for (in order): gpu utilization, graphics memory utilization, free graphics memory, used graphics memory, total graphics memory, gpu power draw, sm clock speed, memory clock speed, gpu clock speed, gpu pstate
gpuDataColumns <- c("utilization.gpu....", "utilization.memory....", "memory.free..MiB.", "memory.used..MiB.", "memory.total..MiB.", "power.draw..W.", "clocks.current.sm..MHz.", "clocks.current.memory..MHz.", "clocks.current.graphics..MHz.", "pstate", "temperature.gpu", "pcie.link.gen.current")

reportTitle <- "Measurement analysis"
scenarioName <- "Scenario name"
measurementName <- "Measurement name"
SUT <- "Used SUT"

# Functions and Rmd:
rmdLocation <- "analysis_script_Report.Rmd"
functionsLocation <- "analysis_script_functions.R"

#Outputs:
dataSaveFileName <- "analysis_script_Data.RData"
outputFileName <- "Report.pdf"
graphicsFolder <- "graphics"

#----------------------------
# Libraries
library(psych)
library(rmarkdown)
library(rjson)
#----------------------------
# Options
op <- options(digits.secs = 3, OutDec = ".") # Make sure that fractions of seconds are included and use "." as standard decimal seperator

# Load measurement data
# Energy consumption data
energyConsumptionData <- read.table(file = PowerScenarioFilename, header = T, sep = ";", skip = 0, dec = ",", stringsAsFactors = F)
# Performance data
performanceData <- read.table(file = performanceScenarioFilename, header = T, sep = ";", quote = "\"", skip = 0, dec = ".", stringsAsFactors = F)
cols <- unlist(lapply(performanceDataColumns, grep, names(performanceData)))
perfcolnames <- c("ram", "networkReceived", "networkSent", "HDDRead", "HDDWritten")
names(performanceData)[cols] <- perfcolnames
performanceData$timestamp <- paste(performanceData$Date, performanceData$Time, sep = " ", collapse = NULL)
performanceData <- performanceData[c(ncol(performanceData), cols)]
# GPU data
evaluateGpuMeasurement <- FALSE
if(exists("gpuScenarioFilename")){
  if(!is.null(gpuScenarioFilename)){
    evaluateGpuMeasurement <- TRUE
  }
}
gpuBaseline <- NULL
gpuMeasurement <- NULL
gpuMeasurementActions <- NULL
allGpuMeasurements <- NULL
allGpuBaselines <- NULL
gpuData <- NULL
if(evaluateGpuMeasurement){
  gpuData <- read.table(file = gpuScenarioFilename, header = T, sep = ",", skip = 0, dec = ".", stringsAsFactors = F)
  cols <- unlist(lapply(gpuDataColumns, grep, names(gpuData)))
  gpucolnames <- c("utilization.gpu", "utilization.memory", "memory.free", "memory.used", "memory.total", "power.draw", "clocks.current.sm", "clocks.current.memory", "clocks.current.graphics", "pstate", "temperature.gpu", "pcie.link.gen.current")
  names(gpuData)[cols] <- gpucolnames
  gpuData <- gpuData[c(1, cols)]
}

# history (if any)
modelHistory <- NULL
if(exists("modelHistoryFilename")){
  if(!is.null(modelHistoryFilename)){
    modelHistory <- paste(scan(modelHistoryFilename, what = "character", sep=" ", quote = NULL), collapse=" ")
    modelHistory <- regmatches(modelHistory, gregexpr("\\{.*?\\}", modelHistory))[[1]]
    temp <- list()
    i <- 1
    for(element in modelHistory){
      temp[[i]] <- fromJSON(element)
      i <- i+1
    }
    modelHistory <- temp
    rm(temp)
  }
}
# Markers
markers <- read.table(file = scenarioMarkersFilename, header = F, sep = ";", fill = T, stringsAsFactors = F)
if(ncol(markers) == 3){
  names(markers) <- c("timestamp", "type", "text")
} else {
  names(markers) <- c("timestamp", "type")
}

# Load baseline
# Energy consumption data
energyConsumptionBaseline <- read.table(file = PowerBaselineFilename, header = T, sep = ";", skip = 0, dec = ",", stringsAsFactors = F)
# Performance data
performanceBaselineData <- read.table(file = performanceBaselineFilename, header = T, sep = ";", quote = "\"", skip = 0, dec = ".", stringsAsFactors = F)
names(performanceBaselineData)[c(11, 25, 55, 56, 65, 66)] <- c("processorTime", "ram", "networkReceived", "networkSent", "HDDRead", "HDDWritten")
performanceBaselineData$timestamp <- paste(performanceBaselineData$Date, performanceBaselineData$Time, sep = " ", collapse = NULL)
performanceBaselineData <- performanceBaselineData[c(71, 11, 25, 55, 56, 65, 66)]
# GPU data
if(evaluateGpuMeasurement){
  gpuBaselineData <- read.table(file = gpuBaselineFilename, header = T, sep = ",", skip = 0, dec = ".", stringsAsFactors = F)
  cols <- unlist(lapply(gpuDataColumns, grep, names(gpuBaselineData)))
  gpucolnames <- c("utilization.gpu", "utilization.memory", "memory.free", "memory.used", "memory.total", "power.draw", "clocks.current.sm", "clocks.current.memory", "clocks.current.graphics", "pstate", "temperature.gpu", "pcie.link.gen.current")
  names(gpuBaselineData)[cols] <- gpucolnames
  gpuBaselineData <- gpuBaselineData[c(1, cols)]
}
# Markers
baselineMarkers <- read.table(file = baselineMarkersFilename, header = F, sep = ";", fill = T, stringsAsFactors = F)
names(baselineMarkers) <- c("timestamp", "type")

# Convert timestamps to POSIXct
energyConsumptionData$Zeit <- as.POSIXct(strptime(energyConsumptionData$Zeit, energyConsumptionTimestampFormat))
energyConsumptionBaseline$Zeit <- as.POSIXct(strptime(energyConsumptionBaseline$Zeit, energyConsumptionTimestampFormat))
performanceData$timestamp <- as.POSIXct(strptime(performanceData$timestamp, performanceTimestampFormat))
performanceBaselineData$timestamp <- as.POSIXct(strptime(performanceBaselineData$timestamp, performanceTimestampFormat))
markers$timestamp <- as.POSIXct(strptime(markers$timestamp, markersTimestampFormat))
baselineMarkers$timestamp <- as.POSIXct(strptime(baselineMarkers$timestamp, markersTimestampFormat))
if(evaluateGpuMeasurement){
  gpuData$timestamp <- as.POSIXct(strptime(gpuData$timestamp, gpuTimestampFormat))
  gpuBaselineData$timestamp <- as.POSIXct(strptime(gpuBaselineData$timestamp, gpuTimestampFormat))
}

# Convert Strings to Numeric
if(evaluateGpuMeasurement){
  gpuData$utilization.gpu <- as.numeric(sub(" %", "", gpuData$utilization.gpu))
  gpuData$utilization.memory <- as.numeric(sub(" %", "", gpuData$utilization.memory))
  gpuData$memory.free <- as.numeric(sub(" MiB", "", gpuData$memory.free))
  gpuData$memory.used <- as.numeric(sub(" MiB", "", gpuData$memory.used))
  gpuData$memory.total <- as.numeric(sub(" MiB", "", gpuData$memory.total))
  gpuData$power.draw <- as.numeric(sub(" W", "", gpuData$power.draw))
  gpuData$clocks.current.sm <- as.numeric(sub(" MHz", "", gpuData$clocks.current.sm))
  gpuData$clocks.current.memory <- as.numeric(sub(" MHz", "", gpuData$clocks.current.memory))
  gpuData$clocks.current.graphics <- as.numeric(sub(" MHz", "", gpuData$clocks.current.graphics))
  gpuData$pstate <- as.numeric(sub(" P", "", gpuData$pstate))
  gpuBaselineData$utilization.gpu <- as.numeric(sub(" %", "", gpuBaselineData$utilization.gpu))
  gpuBaselineData$utilization.memory <- as.numeric(sub(" %", "", gpuBaselineData$utilization.memory))
  gpuBaselineData$memory.free <- as.numeric(sub(" MiB", "", gpuBaselineData$memory.free))
  gpuBaselineData$memory.used <- as.numeric(sub(" MiB", "", gpuBaselineData$memory.used))
  gpuBaselineData$memory.total <- as.numeric(sub(" MiB", "", gpuBaselineData$memory.total))
  gpuBaselineData$power.draw <- as.numeric(sub(" W", "", gpuBaselineData$power.draw))
  gpuBaselineData$clocks.current.sm <- as.numeric(sub(" MHz", "", gpuBaselineData$clocks.current.sm))
  gpuBaselineData$clocks.current.memory <- as.numeric(sub(" MHz", "", gpuBaselineData$clocks.current.memory))
  gpuBaselineData$clocks.current.graphics <- as.numeric(sub(" MHz", "", gpuBaselineData$clocks.current.graphics))
  gpuBaselineData$pstate <- as.numeric(sub(" P", "", gpuBaselineData$pstate))
}

# Calculate GRAM usage (seems like NVIDIA SMI is reporting incorrect percentage values in column "utilization.memory" --> https://forums.developer.nvidia.com/t/unified-memory-nvidia-smi-memory-usage-interpretation/177372/2)
if(evaluateGpuMeasurement){
  gpuData$utilization.memory <- (gpuData$memory.used / gpuData$memory.total) * 100
  gpuBaselineData$utilization.memory <- (gpuBaselineData$memory.used / gpuBaselineData$memory.total) * 100
}

# Calculate network traffic and hdd activity
performanceData$networkTraffic <- performanceData$networkReceived + performanceData$networkSent
performanceData$hddActivity <- performanceData$HDDRead + performanceData$HDDWritten

performanceBaselineData$networkTraffic <- performanceBaselineData$networkReceived + performanceBaselineData$networkSent
performanceBaselineData$hddActivity <- performanceBaselineData$HDDRead + performanceBaselineData$HDDWritten

# Select timestamps of the startTestrun markers
startmarkers <- markers[which(markers$type == "startTestrun"),]
endmarkers <- markers[which(markers$type == "stopTestrun"),]
## Fix end markers for actions "train cNN until 80 % val_accuracy"
paranthesesStopMarkers <- c()
for(i in 1:nrow(markers)){
  if((markers$type[i] == "stopAction") && (markers$type[i-1] == "stopAction")){
    paranthesesStopMarkers <- c(paranthesesStopMarkers, i)
  }
}
markersLength <- nrow(markers)
paranthesesStopMarkersSave <- markers[paranthesesStopMarkers,]
markers <- markers[-paranthesesStopMarkers,]
insertRow <- function(existingDF, newrow, r) {
  existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
  existingDF[r,] <- newrow
  existingDF
}
j <- 1
addedRows <- NULL
for(i in 1:markersLength){
  if(markers$text[i] == "train cNN until 80 % val_accuracy"){
    markers <- insertRow(markers, paranthesesStopMarkersSave[j,], i+1)
    addedRows <- c(addedRows, i)
    j <- j+1
  }
}
startActions <- markers[which(markers$type == "startAction"),]
stopActions <- markers[which(markers$type == "stopAction"),]
baselineStartmarkers <- baselineMarkers[which(baselineMarkers$type == "startTestrun"),]
baselineEndmarkers <- baselineMarkers[which(baselineMarkers$type == "stopTestrun"),]
#startmarkers <- startmarkers[with(startmarkers, order(timestamp)),]
#baselineStartmarkers <- baselineStartmarkers[with(baselineStartmarkers, order(timestamp)),]


# get Action Names
actionNames <- unique(startActions$text)

# Select the power measurements according to the markers
powerMeasurement <- list()
for(i in 1:nrow(startmarkers)){
  element <- length(powerMeasurement)+1
  #DEBUG:
  # cat("Pass ", i, ": ", length(which((energyConsumptionData$Zeit >= startmarkers$timestamp[i])&(energyConsumptionData$Zeit <= endmarkers$timestamp[i]))), "\n", sep="")
  powerMeasurement[[element]] <- energyConsumptionData[which((energyConsumptionData$Zeit >= startmarkers$timestamp[i])&(energyConsumptionData$Zeit <= endmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  powerMeasurement[[element]]$second <- powerMeasurement[[element]]$Zeit-powerMeasurement[[element]]$Zeit[1]
}

# Select the power measurements according to the actions
powerMeasurementActions <- list()
for(i in 1:nrow(startActions)){
  element <- length(powerMeasurementActions)+1
  #DEBUG:
  #cat("Pass ", i, ": ", length(which((energyConsumptionData$Zeit >= startActions$timestamp[i])&(energyConsumptionData$Zeit <= stopActions$timestamp[i]))), "\n", sep="")
  powerMeasurementActions[[element]] <- energyConsumptionData[which((energyConsumptionData$Zeit >= startActions$timestamp[i])&(energyConsumptionData$Zeit <= stopActions$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  powerMeasurementActions[[element]]$second <- powerMeasurementActions[[element]]$Zeit-powerMeasurementActions[[element]]$Zeit[1]
}

# And the same for the baselines
powerBaseline <- list()
for(i in 1:nrow(baselineStartmarkers)){
  element <- length(powerBaseline)+1
  powerBaseline[[element]] <- energyConsumptionBaseline[which((energyConsumptionBaseline$Zeit >= baselineStartmarkers$timestamp[i])&(energyConsumptionBaseline$Zeit <= baselineEndmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  powerBaseline[[element]]$second <- powerBaseline[[element]]$Zeit-powerBaseline[[element]]$Zeit[1]
}

# Select the performance measurements according to the markers
performanceMeasurement <- list()
for(i in 1:nrow(startmarkers)){
  element <- length(performanceMeasurement)+1
  #DEBUG:
  #cat("Pass ", i, ": ", length(which((performanceData$timestamp >= startmarkers$timestamp[i])&(performanceData$timestamp <= endmarkers$timestamp[i]))), "\n", sep="")
  performanceMeasurement[[element]] <- performanceData[which((performanceData$timestamp >= startmarkers$timestamp[i])&(performanceData$timestamp <= endmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  performanceMeasurement[[element]]$second <- round(performanceMeasurement[[element]]$timestamp-performanceMeasurement[[element]]$timestamp[1])
}

# Select the performance measurements according to the actions
performanceMeasurementActions <- list()
for(i in 1:nrow(startActions)){
  element <- length(performanceMeasurementActions)+1
  #DEBUG:
  #cat("Pass ", i, ": ", length(which((performanceData$timestamp >= startActions$timestamp[i])&(performanceData$timestamp <= stopActions$timestamp[i]))), "\n", sep="")
  performanceMeasurementActions[[element]] <- performanceData[which((performanceData$timestamp >= startActions$timestamp[i])&(performanceData$timestamp <= stopActions$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  performanceMeasurementActions[[element]]$second <- round(performanceMeasurementActions[[element]]$timestamp-performanceMeasurementActions[[element]]$timestamp[1])
}

# And the same for the baselines
performanceBaseline <- list()
for(i in 1:nrow(baselineStartmarkers)){
  element <- length(performanceBaseline)+1
  performanceBaseline[[element]] <- performanceBaselineData[which((performanceBaselineData$timestamp >= baselineStartmarkers$timestamp[i])&(performanceBaselineData$timestamp <= baselineEndmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  performanceBaseline[[element]]$second <- performanceBaseline[[element]]$timestamp-performanceBaseline[[element]]$timestamp[1]
}

# Select the gpu measurements according to the markers
if(evaluateGpuMeasurement){
  gpuMeasurement <- list()
  for(i in 1:nrow(startmarkers)){
    element <- length(gpuMeasurement)+1
    #DEBUG:
    #cat("Pass ", i, ": ", length(which((gpuData$timestamp >= startmarkers$timestamp[i])&(gpuData$timestamp <= endmarkers$timestamp[i]))), "\n", sep="")
    gpuMeasurement[[element]] <- gpuData[which((gpuData$timestamp >= startmarkers$timestamp[i])&(gpuData$timestamp <= endmarkers$timestamp[i])),]
    # Convert timestamp into a time differences in seconds
    gpuMeasurement[[element]]$second <- round(gpuMeasurement[[element]]$timestamp-gpuMeasurement[[element]]$timestamp[1])
  }

### With the gpu measurements it may occur, that seconds are skipped, because of how nvidia-smi saves the data in the .csv file. It is possible to find those seconds, eg. by comparing them with the power Measurement timestamps:
### which(!(as.character(powerMeasurement[[1]]$Zeit) %in% gsub("\\..*","",as.character(gpuMeasurement[[1]]$timestamp))))
### dito for the actions- and baseline-lists. For the analysis results this should make no difference, however, because all measurement data is averaged and only 5.1333 seconds are "missing" in 1634 second measurements (both averaged).

# Select the gpu measurements according to the actions
gpuMeasurementActions <- list()
for(i in 1:nrow(startActions)){
  element <- length(gpuMeasurementActions)+1
  #DEBUG:
  #cat("Pass ", i, ": ", length(which((gpuData$timestamp >= startActions$timestamp[i])&(gpuData$timestamp <= stopActions$timestamp[i]))), "\n", sep="")
  gpuMeasurementActions[[element]] <- gpuData[which((gpuData$timestamp >= startActions$timestamp[i])&(gpuData$timestamp <= stopActions$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  gpuMeasurementActions[[element]]$second <- round(gpuMeasurementActions[[element]]$timestamp-gpuMeasurementActions[[element]]$timestamp[1])
}

# And the same for the baselines
gpuBaseline <- list()
for(i in 1:nrow(baselineStartmarkers)){
  element <- length(gpuBaseline)+1
  gpuBaseline[[element]] <- gpuBaselineData[which((gpuBaselineData$timestamp >= baselineStartmarkers$timestamp[i])&(gpuBaselineData$timestamp <= baselineEndmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  gpuBaseline[[element]]$second <- gpuBaseline[[element]]$timestamp-gpuBaseline[[element]]$timestamp[1]
}

source(functionsLocation)

# Generate summary statistics for the powerMeasurement
allPowerMeasurements <- generateMeasurementTable(powerMeasurement)
allPerformanceMeasurements <- generateMeasurementTable(performanceMeasurement)
allPowerBaselines <- generateMeasurementTable(powerBaseline)
allPerformanceBaselines <- generateMeasurementTable(performanceBaseline)
if(evaluateGpuMeasurement){
  allGpuMeasurements <- generateMeasurementTable(gpuMeasurement)
  allGpuBaselines <- generateMeasurementTable(gpuBaseline)
}

# DEBUG
#printSummary(allPowerMeasurements, "Wert.1.avg.W.")
#printSummary(allPerformanceMeasurements, "processorTime")
#printSummary(allGpuMeasurements, "utilization.gpu....")

#calculate measurement duration
shortestTestrun <- 1
shortestTestrunCount <- nrow(powerMeasurement[[1]])
longestTestrun <- 1
longestTestrunCount <- nrow(powerMeasurement[[1]])
for(i in 2:length(powerMeasurement)){
  if(shortestTestrunCount > nrow(powerMeasurement[[i]])){
    shortestTestrunCount <- nrow(powerMeasurement[[i]])
    shortestTestrun <- i
  }
  if(longestTestrunCount < nrow(powerMeasurement[[i]])){
    longestTestrunCount <- nrow(powerMeasurement[[i]])
    longestTestrun <- i
  }
}


# generate results and plots for the testruns
if(!dir.exists(graphicsFolder)){
  dir.create(graphicsFolder)
}
saveWd <- getwd()
setwd(graphicsFolder)

# Plot power
plotAllMeasurementsAndMean(measurements = powerMeasurement, "Wert.1.avg.W.", main = "Plot of power measurement", xlab = "Time [s]", ylab="Power [W]\n", plotFilename = "power.png", markers = markers)

# Plot performance
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "ram", main = "Plot of RAM usage", xlab = "Time [s]", ylab="RAM usage [KB]\n", plotFilename = "ram_usage.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "networkTraffic", main = "Plot of network traffic (sending + receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "hddActivity", main = "Plot of HDD activity (reading + writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "processorTime", main = "Plot of CPU usage", xlab = "Time [s]", ylab="CPU usage [%]\n", plotFilename = "cpu_usage.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "networkSent", main = "Plot of network traffic (sending)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_sent.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "networkReceived", main = "Plot of network traffic (receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_received.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "HDDRead", main = "Plot of HDD activity (reading)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_read.png", markers = markers)
plotAllMeasurementsAndMean(measurements = performanceMeasurement, "HDDWritten", main = "Plot of HDD activity (writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_written.png", markers = markers)

# Plot gpu
if(evaluateGpuMeasurement){
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "temperature.gpu", main = "Plot of GPU temperature", xlab = "Time [s]", ylab="GPU temperature [°C]\n", plotFilename = "gpu_temperature.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "pstate", main = "Plot of GPU pstates", xlab = "Time [s]", ylab="GPU pstate\n", plotFilename = "gpu_pstate.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "pcie.link.gen.current", main = "Plot of PCI-E link generation", xlab = "Time [s]", ylab="PCI-E link generation\n", plotFilename = "gpu_pcie_link_gen.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "utilization.gpu", main = "Plot of GPU utilization", xlab = "Time [s]", ylab="GPU utilization [%]\n", plotFilename = "gpu_utilization.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "utilization.memory", main = "Plot of GPU memory utilization", xlab = "Time [s]", ylab="GPU memory [%]\n", plotFilename = "gpu_memory.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "memory.used", main = "Plot of GPU memory used", xlab = "Time [s]", ylab="GPU memory [MiB]\n", plotFilename = "gpu_memory_mib.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "power.draw", main = "Plot of GPU power draw", xlab = "Time [s]", ylab="GPU power draw [W]\n", plotFilename = "gpu_power.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "clocks.current.sm", main = "Plot of SM (Streaming Multiprocessor) clock speed", xlab = "Time [s]", ylab="GPU SM clock speed [MHz]\n", plotFilename = "gpu_sm_clock.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "clocks.current.memory", main = "Plot of GPU memory clock", xlab = "Time [s]", ylab="GPU memory clock [MHz]\n", plotFilename = "gpu_memory_clock.png", markers = markers)
  plotAllMeasurementsAndMean(measurements = gpuMeasurement, "clocks.current.graphics", main = "Plot of GPU graphics clock", xlab = "Time [s]", ylab="GPU graphics clock [MHz]\n", plotFilename = "gpu_graphics_clock.png", markers = markers)
}

# Plot mean power
mean_power <- plotAllMeasurementsAndMean(measurements = powerMeasurement, "Wert.1.avg.W.", main = "Plot of power measurement", xlab = "Time [s]", ylab="Power [W]\n", plotFilename = "power_mean.png", markers = markers, meansOnly = T)

# Plot mean performance
mean_ram <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "ram", main = "Plot of RAM usage", xlab = "Time [s]", ylab="RAM usage [KB]\n", plotFilename = "ram_usage_mean.png", markers = markers, meansOnly = T)
mean_networkTraffic <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "networkTraffic", main = "Plot of network traffic (sending + receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_mean.png", markers = markers, meansOnly = T)
mean_hddActivity <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "hddActivity", main = "Plot of HDD activity (reading + writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_mean.png", markers = markers, meansOnly = T)
mean_processorTime <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "processorTime", main = "Plot of CPU usage", xlab = "Time [s]", ylab="CPU usage [%]\n", plotFilename = "cpu_usage_mean.png", markers = markers, meansOnly = T)
mean_networkSent <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "networkSent", main = "Plot of network traffic (sending)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_sent_mean.png", markers = markers, meansOnly = T)
mean_networkReceived <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "networkReceived", main = "Plot of network traffic (receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_received_mean.png", markers = markers, meansOnly = T)
mean_HDDRead <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "HDDRead", main = "Plot of HDD activity (reading)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_read_mean.png", markers = markers, meansOnly = T)
mean_HDDWritten <- plotAllMeasurementsAndMean(measurements = performanceMeasurement, "HDDWritten", main = "Plot of HDD activity (writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_written_mean.png", markers = markers, meansOnly = T)

# Plot mean gpu
if(evaluateGpuMeasurement){
  mean_gpu_temp <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "temperature.gpu", main = "Plot of GPU temperature", xlab = "Time [s]", ylab="GPU temperature [°C]\n", plotFilename = "gpu_temperature_mean.png", markers = markers, meansOnly = T)
  mean_gpu_pstate <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "pstate", main = "Plot of GPU pstates", xlab = "Time [s]", ylab="GPU pstate\n", plotFilename = "gpu_pstate_mean.png", markers = markers, meansOnly = T)
  mean_gpu_pcie_link_gen <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "pcie.link.gen.current", main = "Plot of PCI-E link generation", xlab = "Time [s]", ylab="PCI-E link generation\n", plotFilename = "gpu_pcie_link_gen_mean.png", markers = markers, meansOnly = T)
  mean_gpu_utilization <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "utilization.gpu", main = "Plot of GPU utilization", xlab = "Time [s]", ylab="GPU utilization [%]\n", plotFilename = "gpu_utilization_mean.png", markers = markers, meansOnly = T)
  mean_gpu_memory_utilization <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "utilization.memory", main = "Plot of GPU memory utilization", xlab = "Time [s]", ylab="GPU memory [%]\n", plotFilename = "gpu_memory_mean.png", markers = markers, meansOnly = T)
  mean_gpu_memory_used <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "memory.used", main = "Plot of GPU memory used", xlab = "Time [s]", ylab="GPU memory [MiB]\n", plotFilename = "gpu_memory_mib_mean.png", markers = markers, meansOnly = T)
  mean_gpu_power <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "power.draw", main = "Plot of GPU power draw", xlab = "Time [s]", ylab="GPU power draw [W]\n", plotFilename = "gpu_power_mean.png", markers = markers, meansOnly = T)
  mean_gpu_clock_sm <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "clocks.current.sm", main = "Plot of SM (Streaming Multiprocessor) clock speed", xlab = "Time [s]", ylab="GPU SM clock speed [MHz]\n", plotFilename = "gpu_sm_clock_mean.png", markers = markers, meansOnly = T)
  mean_gpu_clock_memory <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "clocks.current.memory", main = "Plot of GPU memory clock", xlab = "Time [s]", ylab="GPU memory clock [MHz]\n", plotFilename = "gpu_memory_clock_mean.png", markers = markers, meansOnly = T)
  mean_gpu_clock_graphics <- plotAllMeasurementsAndMean(measurements = gpuMeasurement, "clocks.current.graphics", main = "Plot of GPU graphics clock", xlab = "Time [s]", ylab="GPU graphics clock [MHz]\n", plotFilename = "gpu_graphics_clock_mean.png", markers = markers, meansOnly = T)
}

# Plot power baseline
plotAllMeasurementsAndMean(measurements = powerBaseline, "Wert.1.avg.W.", main = "Plot of power baseline", xlab = "Time [s]", ylab="Power [W]\n", plotFilename = "power_baseline.png")

# Plot performance baseline
plotAllMeasurementsAndMean(measurements = performanceBaseline, "ram", main = "Plot of RAM usage baseline", xlab = "Time [s]", ylab="RAM usage [KB]\n", plotFilename = "ram_usage_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "networkTraffic", main = "Plot of network traffic baseline (sending + receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "hddActivity", main = "Plot of HDD activity baseline (reading + writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "processorTime", main = "Plot of CPU usage baseline", xlab = "Time [s]", ylab="CPU usage [%]\n", plotFilename = "cpu_usage_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "networkSent", main = "Plot of network traffic baseline (sending)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_sent_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "networkReceived", main = "Plot of network traffic baseline (receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_received_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "HDDRead", main = "Plot of HDD activity baseline (reading)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_read_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "HDDWritten", main = "Plot of HDD activity baseline (writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_written_baseline.png")

# Plot gpu baseline
if(evaluateGpuMeasurement){
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "temperature.gpu", main = "Plot of GPU temperature baseline", xlab = "Time [s]", ylab="GPU temperature [°C]\n", plotFilename = "gpu_temperature_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "pstate", main = "Plot of GPU pstates baseline", xlab = "Time [s]", ylab="GPU pstate\n", plotFilename = "gpu_pstate_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "pcie.link.gen.current", main = "Plot of PCI-E link generation baseline", xlab = "Time [s]", ylab="PCI-E link generation\n", plotFilename = "gpu_pcie_link_gen_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "utilization.gpu", main = "Plot of GPU utilization baseline", xlab = "Time [s]", ylab="GPU utilization [%]\n", plotFilename = "gpu_utilization_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "utilization.memory", main = "Plot of GPU memory utilization baseline", xlab = "Time [s]", ylab="GPU memory [%]\n", plotFilename = "gpu_memory_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "memory.used", main = "Plot of GPU memory used baseline", xlab = "Time [s]", ylab="GPU memory [MiB]\n", plotFilename = "gpu_memory_mib_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "power.draw", main = "Plot of GPU power draw baseline", xlab = "Time [s]", ylab="GPU power draw [W]\n", plotFilename = "gpu_power_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "clocks.current.sm", main = "Plot of SM (Streaming Multiprocessor) clock speed baseline", xlab = "Time [s]", ylab="GPU SM clock speed [MHz]\n", plotFilename = "gpu_sm_clock_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "clocks.current.memory", main = "Plot of GPU memory clock baseline", xlab = "Time [s]", ylab="GPU memory clock [MHz]\n", plotFilename = "gpu_memory_clock_baseline.png")
  plotAllMeasurementsAndMean(measurements = gpuBaseline, "clocks.current.graphics", main = "Plot of GPU graphics clock baseline", xlab = "Time [s]", ylab="GPU graphics clock [MHz]\n", plotFilename = "gpu_graphics_clock_baseline.png")
}

# Plot mean power baseline
mean_power_baseline <- plotAllMeasurementsAndMean(measurements = powerBaseline, "Wert.1.avg.W.", main = "Plot of power baseline", xlab = "Time [s]", ylab="Power [W]\n", plotFilename = "power_baseline_mean.png", meansOnly = T)

#Plot mean performance baseline
mean_ram_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "ram", main = "Plot of RAM usage baseline", xlab = "Time [s]", ylab="RAM usage [KB]\n", plotFilename = "ram_usage_baseline_mean.png", meansOnly = T)
mean_networkTraffic_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "networkTraffic", main = "Plot of network traffic baseline (sending + receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_baseline_mean.png", meansOnly = T)
mean_hddActivity_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "hddActivity", main = "Plot of HDD activity baseline (reading + writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_baseline_mean.png", meansOnly = T)
mean_processorTime_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "processorTime", main = "Plot of CPU usage baseline", xlab = "Time [s]", ylab="CPU usage [%]\n", plotFilename = "cpu_usage_baseline_mean.png", meansOnly = T)
mean_networkSent_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "networkSent", main = "Plot of network traffic baseline (sending)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_sent_baseline_mean.png", meansOnly = T)
mean_networkReceived_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "networkReceived", main = "Plot of network traffic baseline (receiving)", xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = "network_traffic_received_baseline_mean.png", meansOnly = T)
mean_HDDRead_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "HDDRead", main = "Plot of HDD activity baseline (reading)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_read_baseline_mean.png", meansOnly = T)
mean_HDDWritten_baseline <- plotAllMeasurementsAndMean(measurements = performanceBaseline, "HDDWritten", main = "Plot of HDD activity baseline (writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_written_baseline_mean.png", meansOnly = T)

#Plot mean gpu baseline
if(evaluateGpuMeasurement){
  mean_gpu_temp <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "temperature.gpu", main = "Plot of GPU temperature", xlab = "Time [s]", ylab="GPU temperature [°C]\n", plotFilename = "gpu_temperature_baseline_mean.png", meansOnly = T)
  mean_gpu_pstate <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "pstate", main = "Plot of GPU pstates", xlab = "Time [s]", ylab="GPU pstate\n", plotFilename = "gpu_pstate_baseline_mean.png", meansOnly = T)
  mean_gpu_pcie_link_gen <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "pcie.link.gen.current", main = "Plot of PCI-E link generation", xlab = "Time [s]", ylab="PCI-E link generation\n", plotFilename = "gpu_pcie_link_gen_baseline_mean.png", meansOnly = T)
  mean_gpu_utilization <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "utilization.gpu", main = "Plot of GPU utilization", xlab = "Time [s]", ylab="GPU utilization [%]\n", plotFilename = "gpu_utilization_baseline_mean.png", meansOnly = T)
  mean_gpu_memory_utilization <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "utilization.memory", main = "Plot of GPU memory utilization", xlab = "Time [s]", ylab="GPU memory [%]\n", plotFilename = "gpu_memory_baseline_mean.png", meansOnly = T)
  mean_gpu_memory_used <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "memory.used", main = "Plot of GPU memory used", xlab = "Time [s]", ylab="GPU memory [MiB]\n", plotFilename = "gpu_memory_mib_baseline_mean.png", meansOnly = T)
  mean_gpu_power <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "power.draw", main = "Plot of GPU power draw", xlab = "Time [s]", ylab="GPU power draw [W]\n", plotFilename = "gpu_power_baseline_mean.png", meansOnly = T)
  mean_gpu_clock_sm <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "clocks.current.sm", main = "Plot of SM (Streaming Multiprocessor) clock speed", xlab = "Time [s]", ylab="GPU SM clock speed [MHz]\n", plotFilename = "gpu_sm_clock_baseline_mean.png", meansOnly = T)
  mean_gpu_clock_memory <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "clocks.current.memory", main = "Plot of GPU memory clock", xlab = "Time [s]", ylab="GPU memory clock [MHz]\n", plotFilename = "gpu_memory_clock_baseline_mean.png", meansOnly = T)
  mean_gpu_clock_graphics <- plotAllMeasurementsAndMean(measurements = gpuBaseline, "clocks.current.graphics", main = "Plot of GPU graphics clock", xlab = "Time [s]", ylab="GPU graphics clock [MHz]\n", plotFilename = "gpu_graphics_clock_baseline_mean.png", meansOnly = T)
}


baselineTimes <- as.numeric(difftime(time1 = baselineEndmarkers$timestamp, time2 = baselineStartmarkers$timestamp, units = "secs"))
measurementTimes <- as.numeric(difftime(endmarkers$timestamp, startmarkers$timestamp, units = "secs"))
png(filename = "durations_boxplot.png", width = 700, height = 500)
boxplot(list("baseline durations" = baselineTimes, "testrun durations" = measurementTimes), main = "Boxplots of the baseline and testrun durations")
dev.off()

# generate results and plots for the actions
if(!dir.exists("actions")){
  dir.create("actions")
}
setwd("actions")
for(action in actionNames){
  actionFileName <- action
  if(action == "train cNN until 80 % val_accuracy"){
    actionFileName <- sub(" %", "", actionFileName)
  }
  plotAllMeasurementsAndMean(measurements = powerMeasurementActions[which(startActions$text == action)], "Wert.1.avg.W.", main = paste("Plot of power measurement for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="Power [W]\n", plotFilename = paste("power_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = powerMeasurementActions[which(startActions$text == action)], "Wert.1.avg.W.", main = paste("Plot of power measurement for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="Power [W]\n", plotFilename = paste("power_mean_", actionFileName, ".png", sep = ""), meansOnly = T)
  
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "ram", main = paste("Plot of RAM usage for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="RAM usage [%]\n", plotFilename = paste("ram_usage_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "networkTraffic", main = paste("Plot of network traffic (sending + receiving) for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = paste("network_traffic_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "hddActivity", main = paste("Plot of HDD activity (reading + writing) for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = paste("hdd_activity_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "processorTime", main = paste("Plot of CPU usage for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="CPU usage [%]\n", plotFilename = paste("cpu_usage_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "networkSent", main = paste("Plot of network traffic (sending) for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = paste("network_traffic_sent_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "networkReceived", main = paste("Plot of network traffic (receiving) for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="Network traffic [KB]\n", plotFilename = paste("network_traffic_received_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "HDDRead", main = paste("Plot of HDD activity (reading) for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = paste("hdd_activity_read_", actionFileName, ".png", sep = ""))
  plotAllMeasurementsAndMean(measurements = performanceMeasurementActions[which(startActions$text == action)], "HDDWritten", main = paste("Plot of HDD activity (writing) for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = paste("hdd_activity_written_", actionFileName, ".png", sep = ""))
  
  if(evaluateGpuMeasurement){
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "temperature.gpu", main = paste("Plot of GPU temperature for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU temperature [°C]\n", plotFilename = paste("gpu_temperature_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "pstate", main = paste("Plot of GPU pstates for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU pstate\n", plotFilename = paste("gpu_pstate_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "pcie.link.gen.current", main = paste("Plot of PCI-E link generation for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="PCI-E link generation\n", plotFilename = paste("gpu_pcie_link_gen_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "utilization.gpu", main = paste("Plot of GPU utilization for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU utilization [%]\n", plotFilename = paste("gpu_utilization_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "utilization.memory", main = paste("Plot of GPU memory utilization for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU memory [%]\n", plotFilename = paste("gpu_memory_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "memory.used", main = paste("Plot of GPU memory used for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU memory [MiB]\n", plotFilename = paste("gpu_memory_mib_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "power.draw", main = paste("Plot of GPU power draw for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU power draw [W]\n", plotFilename = paste("gpu_power_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "clocks.current.sm", main = paste("Plot of SM (Streaming Multiprocessor) clock speed for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU SM clock speed [MHz]\n", plotFilename = paste("gpu_sm_clock_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "clocks.current.memory", main = paste("Plot of GPU memory clock for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU memory clock [MHz]\n", plotFilename = paste("gpu_memory_clock_", actionFileName, ".png", sep = ""))
      plotAllMeasurementsAndMean(measurements = gpuMeasurementActions[which(startActions$text == action)], "clocks.current.graphics", main = paste("Plot of GPU graphics clock for \"", action, "\"", sep=""), xlab = "Time [s]", ylab="GPU graphics clock [MHz]\n", plotFilename = paste("gpu_graphics_clock_", actionFileName, ".png", sep = ""))
    }
}

setwd(saveWd)

# generate plots for the model history (if it exists)
if(!is.null(modelHistory)){
  historyDir <- paste(graphicsFolder, "model_history", sep="/")
  #create plot directory
  if(!dir.exists(historyDir)){
    dir.create(historyDir)
  }
  setwd(historyDir)
  numEpochsPerTestrun <- unlist(lapply(modelHistory, function(x) length(x[[1]])))
  historyMeans <- as.data.frame(list("testrun" = c(1:length(modelHistory)), "loss" = rep(NA, length(modelHistory)), "val_loss" = rep(NA, length(modelHistory)), "accuracy" = rep(NA, length(modelHistory)), "val_accuracy" = rep(NA, length(modelHistory))))
  allEpochsMeans <- as.data.frame(list("epoch" = c(0:max(numEpochsPerTestrun-1)), "loss" = rep(NA, 1, max(numEpochsPerTestrun)), "val_loss" = rep(NA, 1, max(numEpochsPerTestrun)), "accuracy" = rep(NA, 1, max(numEpochsPerTestrun)), "val_accuracy" = rep(NA, 1, max(numEpochsPerTestrun))))
  allEpochsLoss <- as.data.frame(list("epoch" = c(0:max(numEpochsPerTestrun-1))))
  allEpochsAccuracy <- as.data.frame(list("epoch" = c(0:max(numEpochsPerTestrun-1))))
  allEpochsValLoss <- as.data.frame(list("epoch" = c(0:max(numEpochsPerTestrun-1))))
  allEpochsValAccuracy <- as.data.frame(list("epoch" = c(0:max(numEpochsPerTestrun-1))))
  overallMinY <- min(modelHistory[[1]]$loss, modelHistory[[1]]$accuracy, modelHistory[[1]]$val_loss, modelHistory[[1]]$val_accuracy)
  overallMaxY <- max(modelHistory[[1]]$loss, modelHistory[[1]]$accuracy, modelHistory[[1]]$val_loss, modelHistory[[1]]$val_accuracy)
  for(i in 1:length(modelHistory)){
    # calculate means and plots for all testruns
    minY <- min(modelHistory[[i]]$loss, modelHistory[[i]]$accuracy, modelHistory[[i]]$val_loss, modelHistory[[i]]$val_accuracy)
    maxY <- max(modelHistory[[i]]$loss, modelHistory[[i]]$accuracy, modelHistory[[i]]$val_loss, modelHistory[[i]]$val_accuracy)
    overallMinY <- min(overallMinY, minY)
    overallMaxY <- max(overallMaxY, maxY)
    png(filename = paste0("model_history_", sprintf('%02d', i), ".png"), width = 1000, height = 500)
    par(mfrow=c(1, 2), "mar" = c(5.1, 2.1, 4.1, 5.1), "cex.axis" = 1.2, "cex.main" = 1.2, "cex.lab" = 1.5)
    plot(modelHistory[[i]]$loss, type = "l", col = "darkorange2", ylim = c(minY, maxY), main = "Model loss", xlab = "Epoch", ylab = "")
    lines(modelHistory[[1]]$val_loss, type = "l", lty = 2, col = "blue4")
    legend(x = "topright", legend = c("training", "validation"), col=c("darkorange2", "blue4"), lty=1:2, cex=0.8)
    plot(modelHistory[[i]]$accuracy, type = "l", col = "darkorange2", ylim = c(0, 1), main = "Model accuracy", xlab = "Epoch", ylab = "")
    lines(modelHistory[[1]]$val_accuracy, type = "l", lty = 2, col = "blue4")
    legend(x = "topright", legend = c("training", "validation"), col=c("darkorange2", "blue4"), lty=1:2, cex=0.8)
    dev.off()
    allEpochsLoss <- cbind(allEpochsLoss, c(modelHistory[[i]]$loss, rep(NA, max(numEpochsPerTestrun) - length(modelHistory[[i]]$loss))))
    names(allEpochsLoss)[i+1] <- paste("testrun", i)
    allEpochsAccuracy <- cbind(allEpochsAccuracy, c(modelHistory[[i]]$accuracy, rep(NA, max(numEpochsPerTestrun) - length(modelHistory[[i]]$accuracy))))
    names(allEpochsAccuracy)[i+1] <- paste("testrun", i)
    allEpochsValLoss <- cbind(allEpochsValLoss, c(modelHistory[[i]]$val_loss, rep(NA, max(numEpochsPerTestrun) - length(modelHistory[[i]]$val_loss))))
    names(allEpochsValLoss)[i+1] <- paste("testrun", i)
    allEpochsValAccuracy <- cbind(allEpochsValAccuracy, c(modelHistory[[i]]$val_accuracy, rep(NA, max(numEpochsPerTestrun) - length(modelHistory[[i]]$val_accuracy))))
    names(allEpochsValAccuracy)[i+1] <- paste("testrun", i)
    historyMeans[i, 2:5] <- c(mean(modelHistory[[i]]$loss), mean(modelHistory[[i]]$val_loss), mean(modelHistory[[i]]$accuracy), mean(modelHistory[[i]]$val_accuracy))
  }
  for(epoch in 1:nrow(allEpochsMeans)){
    # calculate means for all epochs
    allEpochsMeans$loss[epoch] <- mean(as.numeric(allEpochsLoss[epoch,2:ncol(allEpochsLoss)]), na.rm = T)
    allEpochsMeans$accuracy[epoch] <- mean(as.numeric(allEpochsAccuracy[epoch,2:ncol(allEpochsAccuracy)]), na.rm = T)
    allEpochsMeans$val_loss[epoch] <- mean(as.numeric(allEpochsValLoss[epoch,2:ncol(allEpochsValLoss)]), na.rm = T)
    allEpochsMeans$val_accuracy[epoch] <- mean(as.numeric(allEpochsValAccuracy[epoch,2:ncol(allEpochsValAccuracy)]), na.rm = T)
  }
  # overview plots
  png(filename = "model_history_mean.png", width = 1000, height = 500)
  par(mfrow=c(1, 2), "mar" = c(5.1, 2.1, 4.1, 5.1), "cex.axis" = 1.2, "cex.main" = 1.2, "cex.lab" = 1.5)
  plot(allEpochsMeans$loss, type = "l", col = "darkorange2", ylim = c(overallMinY, overallMaxY), main = "Model loss (averaged over all testruns)", xlab = "Epoch", ylab = "")
  lines(allEpochsMeans$val_loss, type = "l", lty = 2, col = "blue4")
  legend(x = "topright", legend = c("training", "validation"), col=c("darkorange2", "blue4"), lty=1:2, cex=0.8)
  plot(allEpochsMeans$accuracy, type = "l", col = "darkorange2", ylim = c(0, 1), main = "Model accuracy (averaged over all testruns)", xlab = "Epoch", ylab = "")
  lines(allEpochsMeans$val_accuracy, type = "l", lty = 2, col = "blue4")
  legend(x = "topright", legend = c("training", "validation"), col=c("darkorange2", "blue4"), lty=1:2, cex=0.8)
  dev.off()
  png(filename = "model_loss_mean.png", width = 1000, height = 460)
  par(mfrow=c(1, 2), "mar" = c(5.1, 2.1, 4.1, 5.1), "cex.axis" = 1.2, "cex.main" = 1.2, "cex.lab" = 1.5)
  plot(allEpochsLoss$`testrun 1`, type="l", col="lightgrey", ylim = c(overallMinY, overallMaxY), main = "Training loss (all testruns and mean)", xlab = "Epoch", ylab = "")
  if(ncol(allEpochsLoss) > 1){
    for(i in 2:ncol(allEpochsLoss)){
      lines(allEpochsLoss[, i], type = "l", col = "lightgrey")
    }
  }
  lines(allEpochsMeans$loss, col = "red")
  plot(allEpochsValLoss$`testrun 1`, type="l", col="lightgrey", ylim = c(overallMinY, overallMaxY), main = "Validation loss (all testruns and mean)", xlab = "Epoch", ylab = "")
  if(ncol(allEpochsValLoss) > 1){
    for(i in 2:ncol(allEpochsValLoss)){
      lines(allEpochsValLoss[, i], type = "l", col = "lightgrey")
    }
  }
  lines(allEpochsMeans$val_loss, col = "red")
  dev.off()
  png(filename = "model_accuracy_mean.png", width = 1000, height = 460)
  par(mfrow=c(1, 2), "mar" = c(5.1, 2.1, 4.1, 5.1), "cex.axis" = 1.2, "cex.main" = 1.2, "cex.lab" = 1.5)
  plot(allEpochsAccuracy$`testrun 1`, type="l", col="lightgrey", ylim = c(0, 1), main = "Training accuracy (all testruns and mean)", xlab = "Epoch", ylab = "")
  if(ncol(allEpochsAccuracy) > 1){
    for(i in 2:ncol(allEpochsAccuracy)){
      lines(allEpochsAccuracy[, i], type = "l", col = "lightgrey")
    }
  }
  lines(allEpochsMeans$accuracy, col = "red")
  plot(allEpochsValAccuracy$`testrun 1`, type="l", col="lightgrey", ylim = c(0, 1), main = "Validation accuracy (all testruns and mean)", xlab = "Epoch", ylab = "")
  if(ncol(allEpochsValAccuracy) > 1){
    for(i in 2:ncol(allEpochsValAccuracy)){
      lines(allEpochsValAccuracy[, i], type = "l", col = "lightgrey")
    }
  }
  lines(allEpochsMeans$val_accuracy, col = "red")
  dev.off()
}
setwd(saveWd)

#Generate the pdf using RMarkdown
render(input = rmdLocation, output_file = outputFileName, params = list(
  title = "Measurement analysis",
  subtitle = "cNN Scenario",
  measurementName = "cNN Scenario",
  SUT = SUT,
  startmarkers = startmarkers,
  endmarkers = endmarkers,
  baselineStartmarkers = baselineStartmarkers,
  baselineEndmarkers = baselineEndmarkers,
  startActions = startActions,
  stopActions = stopActions,
  measurementCount = nrow(startmarkers),
  shortestTestrun = shortestTestrun,
  longestTestrun = longestTestrun,
  actionNames = actionNames,
  baselineCount = nrow(baselineStartmarkers),
  performanceBaseline = performanceBaseline,
  performanceMeasurement = performanceMeasurement,
  performanceMeasurementActions = performanceMeasurementActions,
  allPerformanceMeasurements = allPerformanceMeasurements,
  allPerformanceBaselines = allPerformanceBaselines,
  powerBaseline = powerBaseline,
  powerMeasurement = powerMeasurement,
  powerMeasurementActions = powerMeasurementActions,
  allPowerMeasurements = allPowerMeasurements,
  allPowerBaselines = allPowerBaselines,
  evaluateGpuMeasurement = evaluateGpuMeasurement,
  gpuBaseline = gpuBaseline,
  gpuMeasurement = gpuMeasurement,
  gpuMeasurementActions = gpuMeasurementActions,
  allGpuMeasurements = allGpuMeasurements,
  allGpuBaselines = allGpuBaselines,
  modelHistory = modelHistory,
  allEpochsMeans = allEpochsMeans,
  historyMeans = historyMeans,
  graphicsFolder = graphicsFolder
))

#restore options
options(op)

#save data
save.image(dataSaveFileName)

