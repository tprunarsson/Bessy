require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
nedrimork = Ugla.Raw$data$nedrimork_nemenda
efrimork = Ugla.Raw$data$efrimork_nemenda

cat("", file="params.dat",sep="")
cat(paste("param maxStudentSeats := ", efrimork, ";\n"), file = "params.dat", append=TRUE)
cat(paste("param minStudentSeats := ", nedrimork, ";\n"), file = "params.dat", append=TRUE)
