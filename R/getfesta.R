rm(list=ls())
require(rjson)
library(lubridate)

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=festNamskeid&proftaflaID=30")
Ugla.fixed <- readLines(Ugla.Url,  warn = "F")
Ugla.raw <- fromJSON(Ugla.fixed)
ConData <- Ugla.raw$data
examslots<-as.POSIXct(c("2017-04-25 09:00:00", "2017-04-25 13:00:00",
                     "2017-04-26 09:00:00", "2017-04-26 13:00:00",
                     "2017-04-27 09:00:00", "2017-04-27 13:00:00",
                     "2017-04-28 09:00:00", "2017-04-28 13:00:00",
                     "2017-05-02 09:00:00", "2017-05-02 13:00:00",
                     "2017-05-03 09:00:00", "2017-05-03 13:00:00",
                     "2017-05-04 09:00:00", "2017-05-04 13:00:00",
                     "2017-05-05 09:00:00", "2017-05-05 13:00:00",
                     "2017-05-08 09:00:00", "2017-05-08 13:00:00",
                     "2017-05-09 09:00:00", "2017-05-09 13:00:00",
                     "2017-05-10 09:00:00", "2017-05-10 13:00:00"))
cat("", file="festa.dat",sep="\n")
for (i in c(1:length(ConData))) {
  cid <- ConData[[i]]$ke_stuttfagnumer
  fest <- ConData[[i]]$fest
  byrjar <- as.POSIXct(ConData[[i]]$byrjar)
  idx <-  which( (examslots<=byrjar) & (byrjar<=(examslots+hours(3))))
  if (length(idx) == 0) {
    idx <- 0 # ekki á venjulegu próftimabili !
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
