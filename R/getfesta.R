rm(list=ls())
require(rjson)
library(lubridate)

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=festNamskeid&proftaflaID=34")
Ugla.fixed <- readLines(Ugla.Url,  warn = "F")
Ugla.raw <- fromJSON(Ugla.fixed)
ConData <- Ugla.raw$data
examslots<-as.POSIXct(c("2017-12-04 09:00:00", "2017-12-04 13:00:00",
                     "2017-12-05 09:00:00", "2017-12-05 13:00:00",
                     "2017-12-06 09:00:00", "2017-12-06 13:00:00",
                     "2017-12-07 09:00:00", "2017-12-07 13:00:00",
                     "2017-12-08 09:00:00", "2017-12-08 13:00:00",
                     "2017-12-11 09:00:00", "2017-12-11 13:00:00",
                     "2017-12-12 09:00:00", "2017-12-12 13:00:00",
                     "2017-12-13 09:00:00", "2017-12-13 13:00:00",
                     "2017-12-14 09:00:00", "2017-12-14 13:00:00",
                     "2017-12-15 09:00:00", "2017-12-15 13:00:00",
                     "2017-12-18 09:00:00", "2017-12-18 13:00:00"))
cat("", file="festa.dat",sep="\n")
for (i in c(1:length(ConData))) {
  cid <- ConData[[i]]$ke_stuttfagnumer
  fest <- ConData[[i]]$fest
  byrjar <- as.POSIXct(ConData[[i]]$byrjar)
  idx <-  which( (examslots<=byrjar) & (byrjar<=(examslots+hours(3))))
  if (length(idx) == 0) {
    idx <- 0 # ekki á venjulegu próftimabili !
    idx <-  which( (examslots<=byrjar) )
    idx <- -tail(idx, n = 1)
  }
  cid <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cid)
  cat(c("set festa[", cid, "] := "), file="festa.dat", append=TRUE)
  cat(c(" ",as.character(idx), ";"), file="festa.dat", append=TRUE)
  cat("\n", file="festa.dat", append=TRUE)
}

# cat("param SlotNames :=", file="default.dat",sep="\n")
# for (i in c(1:length(examslots))) {
#   cat(c(as.character(i), " ", as.character(examslots[i])), file="default.dat", append=TRUE)
#   cat("\n", file="default.dat", append=TRUE)
# }
# cat(";", file="default.dat",sep="\n")
