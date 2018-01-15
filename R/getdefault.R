Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=defaultMessy&proftaflaID=37")
Ugla.default <- readLines(Ugla.Url,  warn = "F")
cat("", file="default.dat",sep="\n")
for (i in c(1:length(Ugla.default))) {
  cat(Ugla.default[[i]], file="default.dat",append=TRUE)
  cat(c("\n"), file="default.dat", append=TRUE)
}
