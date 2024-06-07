# clear environment
rm(list = ls())

# load package
library(tidyverse)
library(readr)
library(lubridate) # for dates/times
#library(anytime) # for dates/times
#library(magrittr)
options(scipen=999) # turn off scientific notation

# set wd
getwd()
paste(dirname("/builds/teams/eco//remote-eco-lab//"), '/', sep = '')
setwd(dirname("/builds/teams/eco//remote-eco-lab//"))
getwd()

#################
## power meter ##
#################

# load power meter data
raw_pm_bse <- read_delim('testreadings2.csv', delim = ' ', col_names = F) %>% 
  rename(nanoseconds = X1, watts = X2)
raw_pm_idl <- read_delim('testreadings3.csv', delim = ' ', col_names = F) %>% 
  rename(nanoseconds = X1, watts = X2)
raw_pm_sus <- read_delim('testreadings1.csv', delim = ' ', col_names = F) %>% 
  rename(nanoseconds = X1, watts = X2)

# Convert for datetime column
# NB For OSCAR datetime column must be named "Zeit"
op <- options(digits.secs = 6) 

pm_bse_full <- raw_pm_bse %>% mutate(
  datetime_fracs = as.POSIXct(nanoseconds/1000000, origin = '1970-01-01', tz = 'Europe/Berlin'), ## nanoseconds/1000000 for milliseconds
  Zeit = floor_date(ymd_hms(datetime_fracs, tz = 'Europe/Berlin'), unit='seconds')
)

pm_idl_full <- raw_pm_idl %>% mutate(
  datetime_fracs = as.POSIXct(nanoseconds/1000000, origin = '1970-01-01', tz = 'Europe/Berlin'), ## nanoseconds/1000000 for milliseconds
  Zeit = floor_date(ymd_hms(datetime_fracs, tz = 'Europe/Berlin'), unit='seconds')
)

pm_sus_full <- raw_pm_sus %>% mutate(
  datetime_fracs = as.POSIXct(nanoseconds/1000000, origin = '1970-01-01', tz = 'Europe/Berlin'), ## nanoseconds/1000000 for milliseconds
  Zeit = floor_date(ymd_hms(datetime_fracs, tz = 'Europe/Berlin'), unit='seconds')
)

# check timezones
attr(pm_bse_full$datetime_fracs, 'tzone')
attr(pm_bse_full$Zeit, 'tzone')

attr(pm_idl_full$datetime_fracs, 'tzone')
attr(pm_idl_full$Zeit, 'tzone')

attr(pm_sus_full$datetime_fracs, 'tzone')
attr(pm_sus_full$Zeit, 'tzone')

# average measurement output for 1-second intervals
pm_bse <- pm_bse_full %>% group_by(Zeit) %>% 
  summarize(
    n = n(),
    'Wert 1-avg[W]' = mean(watts, na.rm = T)
  )

pm_idl <- pm_idl_full %>% group_by(Zeit) %>% 
  summarize(
    n = n(),
    'Wert 1-avg[W]' = mean(watts, na.rm = T)
  )

pm_sus <- pm_sus_full %>% group_by(Zeit) %>% 
  summarize(
    n = n(),
    'Wert 1-avg[W]' = mean(watts, na.rm = T)
  )

# For OSCAR, convert Zeit to format 'DD.MM.YY, HH:MM:SS'
pm_bse <- pm_bse %>% mutate(Zeit = format(Zeit, format = "%d.%m.%y, %H:%M:%S"))
pm_idl <- pm_idl %>% mutate(Zeit = format(Zeit, format = "%d.%m.%y, %H:%M:%S"))
pm_sus <- pm_sus %>% mutate(Zeit = format(Zeit, format = "%d.%m.%y, %H:%M:%S"))

# select relevant columns
pm_bse <- pm_bse %>% select(Zeit, 'Wert 1-avg[W]')
pm_idl <- pm_idl %>% select(Zeit, 'Wert 1-avg[W]')
pm_sus <- pm_sus %>% select(Zeit, 'Wert 1-avg[W]')

# check dfs
head(pm_bse)
head(pm_idl)
head(pm_sus)

# save files
write.table(pm_bse, '~/pm_bse.csv', sep = ";", row.names = TRUE, quote = FALSE, col.names = TRUE, append = FALSE, eol = ";\n")
write.table(pm_idl, '~/pm_idl.csv', sep = ";", row.names = TRUE, quote = FALSE, col.names = TRUE, append = FALSE, eol = ";\n")
write.table(pm_sus, '~/pm_sus.csv', sep = ";", row.names = TRUE, quote = FALSE, col.names = TRUE, append = FALSE, eol = ";\n")

##########################
## hardware performance ##
##########################

# Retrieve command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of arguments is provided
if (length(args) != 3) {
  stop("Please provide three filenames as command-line arguments.")
}

# Extract the filenames from command-line arguments
filename1 <- args[1]
filename2 <- args[2]
filename3 <- args[3]

# Load hw performance data
raw_hw_sus <- read_delim(filename1, delim = ';', col_names = T, skip = 15)
raw_hw_bse <- read_delim(filename2, delim = ';', col_names = T, skip = 15)
raw_hw_idl <- read_delim(filename3, delim = ';', col_names = T, skip = 15)

# Extract the date from the file names
file_date_sus <- sub('.*-(\\d+)\\.tab', '\\1', filename1)
file_date_bse <- sub('.*-(\\d+)\\.tab', '\\1', filename2)
file_date_idl <- sub('.*-(\\d+)\\.tab', '\\1', filename3)

# Format date as DD.MM.YYYY
formatted_date_bse <- format(as.Date(file_date_bse, format = "%Y%m%d"), "%d.%m.%Y")
formatted_date_idl <- format(as.Date(file_date_idl, format = "%Y%m%d"), "%d.%m.%Y")
formatted_date_sus <- format(as.Date(file_date_sus, format = "%Y%m%d"), "%d.%m.%Y")


# Unite date and time in column 'Date Time' with space separator
hw_bse <- raw_hw_bse %>% 
  mutate('#Date' = formatted_date_bse) %>%
  unite('Date Time', c('#Date', 'Time'), sep = ' ')

hw_idl <- raw_hw_idl %>% 
  mutate('#Date' = formatted_date_idl) %>%
  unite('Date Time', c('#Date', 'Time'), sep = ' ')

hw_sus <- raw_hw_sus %>% 
  mutate('#Date' = formatted_date_sus) %>%
  unite('Date Time', c('#Date', 'Time'), sep = ' ')

# Check dfs
head(hw_bse)
head(hw_idl)
head(hw_sus)

# Save files 
write.csv2(hw_bse, '~/hw_bse.csv', row.names = FALSE, quote = FALSE)
write.csv2(hw_idl, '~/hw_idl.csv', row.names = FALSE, quote = FALSE)
write.csv2(hw_sus, '~/hw_sus.csv', row.names = FALSE, quote = FALSE)

# Preprocessing log files

preprocess_csv_file <- function(input_filename, output_filename) {
  lines <- readLines(input_filename)
  for (i in seq_along(lines)) {
    lines[i] <- gsub("iteration \\d+;", "", lines[i])
  }
  writeLines(lines, output_filename)
}

# Define input and output file paths
input_files <- c("/builds/teams/eco/remote-eco-lab/log_sus.csv", "/builds/teams/eco/remote-eco-lab/log_baseline.csv", "/builds/teams/eco/remote-eco-lab/log_idle.csv")
output_files <- c("~/log_sus.csv", "~/log_baseline.csv", "~/log_idle.csv")

# Process each input file and save to the corresponding output file
for (i in seq_along(input_files)) {
  preprocess_csv_file(input_files[i], output_files[i])
}

