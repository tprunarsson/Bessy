require(rjson)

UglaService <- Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Year <- Ugla.Raw$data$year
Season <- Ugla.Raw$data$season

UglaService <- Ugla.Url <- paste0("https://ugla.hi.is/service/toflugerd/?request=fidinfo&year=",Year,"&season=",Season)
Ugla.Url <- paste0("https://ugla.hi.is/service/toflugerd/?request=fidinfo&year=",Year,"&season=",Season)
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Data <- eval(parse(text=paste0("Ugla.Raw$data$'",Year,"'")))

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
        Url <- sprintf('https://ugla.hi.is/service/toflugerd/?request=cidinfodepend&year=%s&season=%s&scid=%s&did=%s&pid=%s&fid=%s',Year,Season,s,d,p,f)
        tmp <- readLines(Url,  warn = "F")
        tmp <- fromJSON(tmp)
	tmpdat <- eval(parse(text=paste0("tmp$data$'",Year,"'")))
        courselist <- tmpdat[[s]][[d]][[p]][[f]]
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
fname = paste0("fidinfo", Year, Season, ".Rdata")
save(list = ls(all.names = TRUE), file = fname, envir = .GlobalEnv)
