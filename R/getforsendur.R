require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Proftafla_id <- Ugla.Raw$data$proftafla_id

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=forsendurMessy&proftaflaID=", Proftafla_id)
Ugla.forsendur <- readLines(Ugla.Url,  warn = "F")
cat("", file="forsendur.dat",sep="\n")
for (i in c(1:length(Ugla.forsendur))) {
  cat(Ugla.forsendur[[i]], file="forsendur.dat",append=TRUE)
  cat(c("\n"), file="forsendur.dat", append=TRUE)
}
