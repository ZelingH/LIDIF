expit <- function(v) {
  rv <- 1L/(1L+exp(-v))
  return(rv)
}

