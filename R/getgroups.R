# TODO:
rm(list=ls())
load('fidinfo2018spring.Rdata')
CidAssign <- readLines('namskeid.txt')

# find unique program IDs
ue <- unique(PID)
Strict <- matrix(rep(0,length(CidAssign)*length(CidAssign)),nrow=length(CidAssign))

write(NULL, file="groups.dat")
write("/*\n", file = "groups.dat", append = T)
count <- 1
for (i in c(1:length(ue))) {
  pos <- grep(ue[i],PID)
  # We will only grab the mandetory courses in the same year or '-'
  name <- NAME[pos]
  year <- YEAR[pos]
  req <- REQ[pos]
  uyear <- unique(year)
  for (j in c(1:length(uyear))) {
    str <- c("")
    if (uyear[j] != '-') {
      pos <- grep(uyear[j],year)
      str <- character(length=0)
      for (k in c(1:length(pos))) {
        if (req[pos[k]] == 'M') {
          namestring <- substr(name[pos[k]],5,11)
          namestring <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), namestring)
          if (length(grep(namestring, CidAssign)) > 0) {
            str <- c(str, namestring)
          }
        }
      }
    }
    if (length(str)>1) {
      str <- unique(str)
      strcat <- sprintf('set Group[%d] := ', count)
      if (length(str) > 1) {
        for (i in c(1:length(str))) {
          strcat <- sprintf('%s %s', strcat, str[i])
        }
        strcat <- sprintf('%s;', strcat)
        strcat <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), strcat)
        write(strcat, file = "groups.dat", append = T)
        count <- count + 1
        for (i in c(1:length(str))) {
          for (j in c(1:length(str))) {
            if (j != i) {
              posi <- which(str[i]==CidAssign)
              posj <- which(str[j]==CidAssign)
              Strict[posi,posj] <- 1
            }
          }
        }

      }
    }
  }
}
write("*/\n", file = "groups.dat", append = T)

if (FALSE) {
extrastr = list()
extrastr[[1]] = c("VID401G", "VID402G", "VID403G", "VID404G", "VID405G", "VID415G")
#extrastr[[2]] = c("VID202G", "VID204G", "VID205G", "VID258G", "VID263G")
#extrastr[[3]] = c("VID209F", "VID211F", "VID212F")
#extrastr[[4]] = c("FRA429G", "FRA417M", "FRA429M")
#extrastr[[5]] = c("HAG207F", "HAG212F", "VID207F")

for (i in c(1:length(extrastr))) {
  strcat <- sprintf('set Group[%d] := ', count)
  str <- extrastr[[i]]
  if (length(str) > 1) {
    for (i in c(1:length(str))) {
      strcat <- sprintf('%s %s', strcat, str[i])
    }
    strcat <- sprintf('%s;', strcat)
    strcat <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), strcat)
    write(strcat, file = "groups.dat", append = T)
    count <- count + 1
    for (i in c(1:length(str))) {
      for (j in c(1:length(str))) {
        if (j != i) {
          posi <- which(str[i]==CidAssign)
          posj <- which(str[j]==CidAssign)
          Strict[posi,posj] <- 1
        }
      }
    }
  }
}
}

require(Matrix)
image(as(Strict, "sparseMatrix"))

write("\nparam CidCommonGroupStudents := ", file = "groups.dat", append = T)
for (i in c(1:length(CidAssign))) {
  for (j in c(i:length(CidAssign))) {
    if (Strict[i,j] == 1) {
      strcat <- sprintf('%s %s 1', CidAssign[i], CidAssign[j])
      write(strcat, file = "groups.dat", append = T)
    }
  }
}
write(";\n", file = "groups.dat", append = T)
