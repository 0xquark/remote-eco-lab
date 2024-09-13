# ========================================= #
# SCRIPT TO BE RUN WITH "analysis_script.R" #
# ========================================= #

# This script defines the Idle Mode specific information. When run
# together with "analysis_script.R" it provides a report for the
# Idle Mode scenario.

setwd("~/")

getwd()

# Inputs
scenarioMarkersFilename <- "log_sus.csv"
PowerScenarioFilename <- "pm_sus.csv"
performanceScenarioFilename <- "hw_sus.csv"

# Names
reportTitle <- "KEcoLab Measurement Analysis"
scenarioName <- "Standard Usage Scenario"
measurementName <- "Usage Scenario"
SUT <- "Standard Usage Scenario"

# Rmd for report
rmdLocation <- "sus_analysis_script_Report.Rmd"

#Outputs:
dataSaveFileName <- "sus_analysis_script_Data.RData"
outputFileName <- "~/SUS_Report.pdf"
graphicsFolder <- "sus_graphics"

# =============================== #
# Import "analysis_script.R" This #
# is the same for both Idle Mode  #
# and SUS scenarios.              #
# =============================== #

source(analysis_script.R)

# ========================= #
# Stop "analysis_script.R"  #
# ========================= #

#Generate the pdf using RMarkdown
render(input = rmdLocation, output_file = outputFileName, params = list(
  title = "Standard Usage Scenario Analysis",
  subtitle = "Measurement From KEcoLab",
  measurementName = "Standard Usage Scenario",
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
