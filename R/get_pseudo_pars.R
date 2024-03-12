#' @export
get_pseudo_pars <- function(random_per,
                            dat.list,
                            type_list,
                            replace
) {

  Y_sim <- stats::rnorm(n = nrow(dat.list$X), mean = 0L, sd = 1L)
  P = ncol(dat.list$X)

  if(length(type_list) >1 & length(type_list) < P) {
    stop("Please either specify a uniform item type or a vector of length = total number of items!")
  } else if (length(type_list) == 1) {
    tp = rep(type_list, P)
  } else {tp = type_list}

  initial_list <- lapply(1:P, function(i) {
    if(tp[i] == "ordinal") {
      dat_r <- cbind.data.frame(factor(dat.list$X[,i], ordered =  TRUE),
                                "Y" = Y_sim,
                                dat.list$Z)
      colnames(dat_r)[1] = colnames(dat.list$X)[i]
      nn = colnames(dat_r)
      if(length(nn) > 3) {
        exp_nn = paste0(colnames(dat_r)[1]," ~", paste(nn[-(1L:3L)], collapse = "+"), "+Y+", paste(paste0(nn[-(1L:3L)], ":Y"), collapse = "+"))
      } else {
        exp_nn = paste0(colnames(dat_r)[1], "~Y")
      }
      dat_rr = dat_r[sample(1L:nrow(dat_r), size = round(nrow(dat_r)*random_per, 0),replace = replace),]
      while(length(unique(dat_rr[,1])) != length(unique(dat_r[,1]))) {
        dat_rr = dat_r[sample(1L:nrow(dat_r), size = round(nrow(dat_r)*random_per, 0),replace = replace),]
      }
      mod = VGAM::vglm(stats::as.formula(exp_nn) , family = VGAM::cumulative(parallel = TRUE, reverse = FALSE),  data = dat_rr)
      coefs  = stats::coefficients(mod)
    } else if(tp[i] == "binary") {
      dat_r <- cbind.data.frame(dat.list$X[,i],
                                "Y" = Y_sim,
                                dat.list$Z)
      colnames(dat_r)[1] = colnames(dat.list$X)[i]
      nn = colnames(dat_r)
      if(length(nn) > 3) {
        exp_nn = paste0(colnames(dat_r)[1]," ~", paste(nn[-(1L:3L)], collapse = "+"), "+Y+", paste(paste0(nn[-(1L:3L)], ":Y"), collapse = "+"))
      } else {
        exp_nn = paste0(colnames(dat_r)[1], "~Y")
      }
      coefs = summary(stats::glm(stats::as.formula(exp_nn), data = dat_r[sample(1:nrow(dat_r), size = round(nrow(dat_r)*random_per, 0),replace = replace),], family = stats::binomial))$coefficients[,1]
    }
    coefs
  })
  names(initial_list) = colnames(dat.list$X)
  return(initial_list)
}
