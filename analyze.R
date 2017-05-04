# clean-up
rm(list = ls())

# load required libraries
library(prophet)

# load preprocessed data
load("AI_buzzwords.RData")

# main function
summarize <- function(keywords) {
  # location of the slashdot scrape dump
  database <- "./archive"

  # get list of all files in the dump
  files <- list.files(database)

  # data frame to hold results
  res <- data.frame(ds = paste(substr(files, 1, 4), substr(files, 5, 6), substr(files, 7, 8),
                               sep = "-"))
  res[, keywords] <- NA

  i <- 0
  for (f in files) {
    i <- i + 1
    cat("Processing:", f, "...\n")
    lines <- readLines(file.path(database, f))
    articles <- lines[grepl("#article", lines, fixed = T)]
    if (length(articles) == 0)
      next
    res[i, keywords] <- 0
    for (key in keywords) {
      key_regex <- paste0("\\b", key, "\\b")
      hit <- sum(grepl(key_regex, articles))
      res[i, key] <- hit
    }
  }

  return(res)
}


# quantity of interest
dd <- res[, c("ds", "AI_buzzwords")]
names(dd)[2] <- "y"
makeMonthly = function(ts){
  # ts must be a timeSeries (see: "http://www.rmetrics.org/Rmetrics.R")
  ts=sort(ts)                         #sort
  dts=rownames(ts)                    #get dates
  months=substr(dts,6,7)              #read out month
  len=length(months)                  #get length of vector
  b=months[1:(len-1)]!=months[2:len]  #see where month is changing
  b=c(b,TRUE)                         #the last row we always take
  mts=ts[b,]                          #make monthly data and return result
}


# model
m <- prophet(dd)

# prediction
future <- make_future_dataframe(m, periods = 365)
forecast <- predict(m, future)
plot(m, forecast)
