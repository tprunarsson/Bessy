rm(list=ls())
require(rjson)
UglaService <- Ugla.Url <- paste0("https://ugla.hi.is/service/toflugerd/?request=fidinfo&year=",2018,"&season=spring")
Ugla.Url <- paste0("https://ugla.hi.is/service/toflugerd/?request=fidinfo&year=",2018,"&season=spring")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Data <- Ugla.Raw$data$'2018'
scid <- names(Data)

REQ <- character(length=0)
ID <- numeric(length=0)
NAME <- character(length=0)
YEAR <- character(length=0)
SEASON <- character(length=0)
SCID <- numeric(length=0)
DID <- numeric(length=0)
PID <- numeric(length=0)
FID <- numeric(length=0)
i <- 0
for (s in scid) {
  did <- names(Data[[s]])
  for (d in did) {
    pid <- names(Data[[s]][[d]])
    for (p in pid) {
      fid <- names(Data[[s]][[d]][[p]])
      for (f in fid) {
        Url <- sprintf('https://ugla.hi.is/service/toflugerd/?request=cidinfodepend&year=2018&season=fall&scid=%s&did=%s&pid=%s&fid=%s',s,d,p,f)
        tmp <- readLines(Url,  warn = "F")
        tmp <- fromJSON(tmp)
        courselist <- tmp$data$`2018`[[s]][[d]][[p]][[f]]
        lna <- names(courselist)
        i <- i + 1
        for (l in lna) {
          NAME <- c(NAME, l)
          REQ <- c(REQ,courselist[[l]]$requirement)
          ID <- c(ID,i)
          YEAR <- c(YEAR,courselist[[l]]$year)
          SEASON <- c(SEASON,courselist[[l]]$season)
          SCID <- c(SCID,s)
          DID <- c(DID,d)
          PID <- c(PID,p)
          FID <- c(FID,f)
        }
      }
    }
  }
}

save(list = ls(all.names = TRUE), file = "fidinfo2018spring.Rdata", envir = .GlobalEnv)
