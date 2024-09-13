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

# ======================================= #
# The beginning of the script is specific #
# for Idle Mode or SUS scenario.          #
# ======================================= #

# ========================================================== #
# CODE BELOW IS THE SAME FOR BOTH SUS AND IDLE MODE SCENARIO #
# ========================================================== #

# set gpuScenarioFilename to NULL (or comment out) if no gpu data is available
gpuScenarioFilename <- NULL
# set modelHistoryFilename to NULL (or comment out) if no history is available
# !CAUTION! You need to handle the formatting yourself. It is done in lines 97ff and 520ff
modelHistoryFilename <- NULL

baselineMarkersFilename <- "log_baseline.csv"
PowerBaselineFilename <- "pm_bse.csv"
performanceBaselineFilename <- "hw_bse.csv"
gpuBaselineFilename <- NULL

markersTimestampFormat <- "%Y-%m-%d %H:%M:%OS"
energyConsumptionTimestampFormat <- "%d.%m.%y, %H:%M:%OS"
performanceTimestampFormat <- "%d.%m.%Y %H:%M:%OS"
gpuTimestampFormat <- "%Y/%m/%d %H:%M:%OS"

# Specify column names containing measurements for (in order): cpu, ram, networkReceived, networkSent, diskRead, diskWritten
performanceDataColumns <- c("CPU.Totl", "MEM.Used", "NET.RxKBTot", "NET.TxKBTot", "DSK.ReadTot", "DSK.WriteTot")
performanceBaselineColumns <- c("CPU.Totl", "MEM.Used", "NET.RxKBTot", "NET.TxKBTot", "DSK.ReadTot", "DSK.WriteTot")

# Functions
functionsLocation <- "analysis_script_functions.R"

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
energyConsumptionData <- read.table(file = PowerIdleFilename, header = T, sep = ";", skip = 0, dec = ",", stringsAsFactors = F)
# Performance data
performanceData <- read.table(file = performanceIdleFilename, header = T, sep = ";", quote = "\"", skip = 0, dec = ".", stringsAsFactors = F)
cols <- unlist(lapply(performanceDataColumns, grep, names(performanceData)))
perfcolnames <- c("processorTime", "ram", "networkReceived", "networkSent", "HDDRead", "HDDWritten")
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


# Markers
markers <- read.csv(file = idleMarkersFilename, header = F, sep = ";", fill = T, stringsAsFactors = F)
if(ncol(markers) == 3){
  names(markers) <- c("timestamp", "type", "text")
} else {
  names(markers) <- c("timestamp", "type")
}

# Load baseline
# Energy consumption data
energyConsumptionBaseline <- read.table(file = PowerBaselineFilename, header = T, sep = ";", skip = 0, dec = ",", stringsAsFactors = F)
performanceBaselineData <- read.table(file = performanceBaselineFilename, header = T, sep = ";", quote = "\"", skip = 0, dec = ".", stringsAsFactors = F)
cols <- unlist(lapply(performanceBaselineColumns, grep, names(performanceBaselineData)))
perfcolnames <- c("processorTime", "ram", "networkReceived", "networkSent", "HDDRead", "HDDWritten")
names(performanceBaselineData)[cols] <- perfcolnames
performanceBaselineData$timestamp <- paste(performanceBaselineData$Date, performanceBaselineData$Time, sep = " ", collapse = NULL)
performanceBaselineData <- performanceBaselineData[c(ncol(performanceBaselineData), cols)]

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


# Calculate network traffic and hdd activity
performanceData$networkTraffic <- performanceData$networkReceived + performanceData$networkSent
performanceData$hddActivity <- performanceData$HDDRead + performanceData$HDDWritten

performanceBaselineData$networkTraffic <- performanceBaselineData$networkReceived + performanceBaselineData$networkSent
performanceBaselineData$hddActivity <- performanceBaselineData$HDDRead + performanceBaselineData$HDDWritten

# Select timestamps of the startTestrun markers
startmarkers <- markers[which(markers$type == "startTestrun"),]
endmarkers <- markers[which(markers$type == "stopTestrun"),]

paranthesesStopMarkers <- c()
for(i in 1:nrow(markers)){
  if((markers$type[i] == "stopAction") && (markers$type[i-1] == "stopAction")){
    paranthesesStopMarkers <- c(paranthesesStopMarkers, i)
  }
}
markersLength <- nrow(markers)

if (length(paranthesesStopMarkers) > 0) {
  markersLength <- nrow(markers)
  paranthesesStopMarkersSave <- markers[paranthesesStopMarkers,]
  markers <- markers[-paranthesesStopMarkers,]
  insertRow <- function(existingDF, newrow, r) {
    existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
    existingDF[r,] <- newrow
    existingDF
  }
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

startActions <- markers[which(trimws(markers$type) == "startAction"),]
stopActions <- markers[which(trimws(markers$type) == "stopAction"),]
baselineStartmarkers <- baselineMarkers[which(trimws(baselineMarkers$type) == "startTestrun"),]
baselineEndmarkers <- baselineMarkers[which(trimws(baselineMarkers$type) == "stopTestrun"),]
#startmarkers <- startmarkers[with(startmarkers, order(timestamp)),]
#baselineStartmarkers <- baselineStartmarkers[with(baselineStartmarkers, order(timestamp)),]


# get Action Names
actionNames <- unique(startActions$text)

# Select the power measurements according to the markers
powerMeasurement <- list()
for(i in 1:nrow(startmarkers)){
  element <- length(powerMeasurement)+1
  #DEBUG:
  cat("Pass ", i, ": ", length(which((energyConsumptionData$Zeit >= startmarkers$timestamp[i])&(energyConsumptionData$Zeit <= endmarkers$timestamp[i]))), "\n", sep="")
  powerMeasurement[[element]] <- energyConsumptionData[which((energyConsumptionData$Zeit >= startmarkers$timestamp[i])&(energyConsumptionData$Zeit <= endmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  powerMeasurement[[element]]$second <- powerMeasurement[[element]]$Zeit-powerMeasurement[[element]]$Zeit[1]
}

# Select the power measurements according to the actions
powerMeasurementActions <- list()
for(i in 1:nrow(startActions)){
  element <- length(powerMeasurementActions)+1
  #DEBUG:
  cat("Pass ", i, ": ", length(which((energyConsumptionData$Zeit >= startActions$timestamp[i])&(energyConsumptionData$Zeit <= stopActions$timestamp[i]))), "\n", sep="")
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
  cat("Pass ", i, ": ", length(which((performanceData$timestamp >= startmarkers$timestamp[i])&(performanceData$timestamp <= endmarkers$timestamp[i]))), "\n", sep="")
  performanceMeasurement[[element]] <- performanceData[which((performanceData$timestamp >= startmarkers$timestamp[i])&(performanceData$timestamp <= endmarkers$timestamp[i])),]
  # Convert timestamp into a time differences in seconds
  performanceMeasurement[[element]]$second <- round(performanceMeasurement[[element]]$timestamp-performanceMeasurement[[element]]$timestamp[1])
}

# Select the performance measurements according to the actions
performanceMeasurementActions <- list()
for(i in 1:nrow(startActions)){
  element <- length(performanceMeasurementActions)+1
  #DEBUG:
  cat("Pass ", i, ": ", length(which((performanceData$timestamp >= startActions$timestamp[i])&(performanceData$timestamp <= stopActions$timestamp[i]))), "\n", sep="")
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


### With the gpu measurements it may occur, that seconds are skipped, because of how nvidia-smi saves the data in the .csv file. It is possible to find those seconds, eg. by comparing them with the power Measurement timestamps:
### which(!(as.character(powerMeasurement[[1]]$Zeit) %in% gsub("\\..*","",as.character(gpuMeasurement[[1]]$timestamp))))
### dito for the actions- and baseline-lists. For the analysis results this should make no difference, however, because all measurement data is averaged and only 5.1333 seconds are "missing" in 1634 second measurements (both averaged).


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
printSummary(allPowerMeasurements, "Wert.1.avg.W.")
printSummary(allPerformanceMeasurements, "processorTime")
printSummary(allGpuMeasurements, "utilization.gpu....")

#calculate measurement duration
shortestTestrun <- 1
shortestTestrunCount <- nrow(powerMeasurement[[1]])
longestTestrun <- 1
longestTestrunCount <- nrow(powerMeasurement[[1]])


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
if(evaluateGpuMeasurement){c
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
plotAllMeasurementsAndMean(measurements = performanceBaseline, "processorTime", main = "Plot of CPU usage baseline", xlab = "Time [s]", ylab="CPU usage [%]\n", plotFilename = "cpu_usage_baseline.png")
plotAllMeasurementsAndMean(measurements = performanceBaseline, "hddActivity", main = "Plot of HDD activity baseline (reading + writing)", xlab = "Time [s]", ylab="HDD activity [KB]\n", plotFilename = "hdd_activity_baseline.png")
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
  
}

setwd(saveWd)

# generate plots for the model history (if it exists)

setwd(saveWd)

# ================================== #
# The rest of the script is specific #
# for Idle Mode or SUS scenario.     #
# ================================== #
