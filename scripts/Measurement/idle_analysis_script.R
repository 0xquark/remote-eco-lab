# ========================================= #
# SCRIPT TO BE RUN WITH "analysis_script.R" #
# ========================================= #

# This script defines the Idle Mode specific information. When run
# together with "analysis_script.R" it provides a report for the
# Idle Mode scenario.

setwd("~/")

getwd()

# Inputs
scenarioMarkersFilename <- "log_idle.csv"
PowerScenarioFilename <- "pm_idl.csv"
performanceScenarioFilename <- "hw_idl.csv"

# Names
reportTitle <- "KEcoLab Measurement Analysis"
scenarioName <- "Idle Mode Scenario"
measurementName <- "Idle Mode Scenario"
SUT <- "Idle Mode Scenario"

# Rmd for report
rmdLocation <- "idle_analysis_script_Report.Rmd"

#Outputs:
dataSaveFileName <- "idle_analysis_script_Data.RData"
outputFileName <- "~/Idle_Report.pdf"
graphicsFolder <- "idle_graphics"

# =============================== #
# Import "analysis_script.R" This #
# is the same for both Idle Mode  #
# and SUS scenarios.              #
# =============================== #

source("analysis_script.R")

# ========================= #
# Stop "analysis_script.R"  #
# ========================= #

#Generate the pdf using RMarkdown
render(input = rmdLocation, output_file = outputFileName, params = list(
  title = "Idle Mode Scenario Analysis",
  subtitle = "Measurement From KEcoLab",
  measurementName = "Idle Mode Scenario",
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
  graphicsFolder = graphicsFolder
))

#restore options
options(op)

#save data
save.image(dataSaveFileName)
