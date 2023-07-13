#Measuring and Assessing the Resource- and Energy Efficiency of AIoT-Devices and Algorithms - Replication package
#Copyright (C) 2022 Achim Guldner
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

library(psych)
library(rmarkdown)
knitr::opts_chunk$set(echo = TRUE, fig.pos = 'H')
options("OutDec" = ",")

# +------------------------+
# | Standard plot function |
# +------------------------+
plotAllMeasurementsAndMean <- function(measurements, value, main, xlab, ylab, useShortestTestrun = FALSE, markers = NULL, plotFilename = NULL, meansOnly = FALSE){
  # Plot all the measurements in one graph
  #DEBUG
  #cat("call plotAllMeasurementsAndMean",file="debug.txt",sep="\n")
  #save(measurements, value, main, xlab, ylab, markers, plotFilename, file = paste("plotAllMeasurementsAndMean", value, ".RData", sep=""))
  
  if(!is.null(plotFilename)){
    png(file = plotFilename, width = 2000, height = 1000)
  }
  # Get min and max values and the shortest and longest testrun
  min <- min(as.numeric(measurements[[1]][[value]]))
  max <- max(as.numeric(measurements[[1]][[value]]))
  shortestTestrun <- 1
  shortestTestrunCount <- nrow(measurements[[1]])
  longestTestrun <- 1
  longestTestrunCount <- nrow(measurements[[1]])
  if(length(measurements) > 1){
    for(i in 2:length(measurements)){
      potentialMax <- 0
      potentialMin <- min(as.numeric(measurements[[i]][[value]]))
      potentialMax <- max(as.numeric(measurements[[i]][[value]]))
      if((!is.na(min))&&(!is.na(potentialMin)))
        if(min > potentialMin)
          min <- potentialMin
      if((!is.na(max))&&(!is.na(potentialMax)))
        if(max < potentialMax)
          max <- potentialMax
      if(shortestTestrunCount > nrow(measurements[[i]])){
        shortestTestrunCount <- nrow(measurements[[i]])
        shortestTestrun <- i
      }
      if(longestTestrunCount < nrow(measurements[[i]])){
        longestTestrunCount <- nrow(measurements[[i]])
        longestTestrun <- i
      }
    }
  }
  #DEBUG
  #print(shortestTestrunCount)
  #print(shortestTestrun)
  #print(longestTestrunCount)
  #print(longestTestrun)
  
  # Plot individual measurements
  par("mar" = par("mar")+5, "cex.axis" = 2.2, "cex.main" = 2.5, "cex.lab" = 2.5)
  plot(as.numeric(measurements[[longestTestrun]][[value]]), type = "n", main = main, xlab = xlab, ylab = ylab, ylim = c(min, max))
  if(!meansOnly){
    for(i in 1:length(measurements)){
      points(as.numeric(measurements[[i]][[value]]), type = "S", col="dimgray")
    }
  }
  # add a mean line
  testrunToUse <- longestTestrun
  testrunToUseCount <- longestTestrunCount
  if(useShortestTestrun){
    testrunToUse <- shortestTestrun
    testrunToUseCount <- shortestTestrunCount
  }
  meanOfAllMeasurementValues <- rep(0,testrunToUseCount)
  x <- as.data.frame(rep(0, nrow(measurements[[testrunToUse]])))
  for(i in 1:length(measurements)){
    m <- measurements[[i]][[value]]
    length(m) <- testrunToUseCount
    x <- cbind(x, m)
  }
  x <- x[,-1]
  if(class(x) == "data.frame"){
    for(i in 1:nrow(x)){
      meanOfAllMeasurementValues[i] <- mean(as.numeric(x[i,]), na.rm = TRUE)
    }
  } else {
    meanOfAllMeasurementValues <- x
  }
  points(meanOfAllMeasurementValues, type = "S", col="red", lwd=2)
  
  if(!is.null(markers) && nrow(markers) != 0){
    # Add hlines for the markers
    longestTestrunStopTimestamp <- markers[which(markers$type == "stopTestrun"),][testrunToUse,1]
    longestTestrunStartTimestamp <- markers[which(markers$type == "startTestrun"),][testrunToUse,1]
    markerLongestMeasurement <- markers[which((markers$type == "startAction")&(markers$timestamp > longestTestrunStartTimestamp)&(markers$timestamp < longestTestrunStopTimestamp)),]
    markerLongestMeasurement$second <- markerLongestMeasurement$timestamp - longestTestrunStartTimestamp
    rug(markerLongestMeasurement$second, col="blue", lwd = 2, side = 3)
    #abline(v=markerLongestMeasurement$second, col = "blue", lwd = 2)
  }
  
  
  
  if(!is.null(plotFilename)){
    dev.off()
  }
  return(meanOfAllMeasurementValues)
}

plotAllMeasurementsAndMeanTwoValuesInOne <- function(measurements, value1, value2, main1, xlab1, ylab1, main2, xlab2, ylab2, markers, plotFilename){
  # Plot all the meassurements for two different values in one graph
  png(filename = plotFilename, width = 2000, height = 2000)
  opar <- par(mfrow=c(2, 1))
  plotAllMeasurementsAndMean(measurements, value1, main1, xlab1, ylab1, markers)
  plotAllMeasurementsAndMean(measurements, value2, main2, xlab2, ylab2, markers)
  par(opar)
  dev.off()
}

# +-------------------------------+
# | Standard statistics functions |
# +-------------------------------+
generateMeasurementTable <- function(measurements){
  # Generate summary statistics
  allMeasurements <- NULL
  for(i in 1:length(measurements)){
    m <- cbind(measurements[[i]], i)
    names(m)[ncol(m)]<-"testrunNumber"
    allMeasurements <- rbind(allMeasurements, m)
  }
  return(allMeasurements)
}

printSummary <- function(measurement, value){
  cat("Summary Statistics for ", deparse(substitute(measurement)), "$", value, ":\n", sep = "")
  desc <- describe(as.numeric(measurement[[value]]), IQR = T)
  rownames(desc) <- ""
  print(desc[,c("n", "mean", "sd", "median", "min", "max", "range", "IQR")])
}

calculateIndividualMeans <- function(measurements, value){
  #Calculate individual Mean values for all measurements
  allMeans <- NULL
  for(i in 1:length(measurements)){
    allMeans[i] <- mean(as.numeric(measurements[[i]][[value]]))
  }
  cat("Summary Statistics for all individual measurement mean values in ", deparse(substitute(measurements)), "$", value, ":\n", sep = "")
  desc <- describe(allMeans, IQR = T)
  rownames(desc) <- ""
  print(desc[,c("n", "mean", "sd", "median", "min", "max", "range", "IQR")])
  return(allMeans)
}

# normalize values of a vector to 0:1
range01 <- function(x){
  (x - min(x)) / (max(x) - min(x))
}
