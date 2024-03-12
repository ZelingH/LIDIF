#' @export
fun_x_h_given_y_h <- function(y, h,
                              current_est_list, data_Z, data_X) {

  # number of items
  P <- ncol(as.matrix(data_X))
  # number of exogenous variables
  J <- ncol(as.matrix(data_Z))

  fun_x_h_given_y_h_elementwise <- lapply(1L:P, function(i) {

    Z_h <- data_Z[h,]
    M_i <- length(unique(stats::na.omit(data_X[,i])))
    est_i <-  current_est_list[[i]]

    # alpha
    alpha_i <- est_i[1L:(M_i-1L)]
    # beta
    if(J > 1) {
      beta_i = est_i[M_i:(M_i+J-2L)]
    } else {
      beta_i = NULL
    }
    # zeta
    zeta_i <- est_i[(M_i+J-1L):(2L*J+M_i-2L)]


    if(is.na(data_X[h,i])) {
      1L
    } else {

      if(M_i == 1) {
        stop(paste0("Item ", i, " only has one answer!"))
      } else if (M_i == 2) {
        # binary
        g_i_h = sapply(alpha_i, function(alpha) Z_h %*% c(alpha, beta_i) + (Z_h %*% zeta_i)*y)
        pi_i_h <- expit(g_i_h)
        one_pi_i_h <- exp(- g_i_h)/(1+exp(- g_i_h))
        one_pi_i_h*exp(data_X[h,i]*g_i_h)

      } else{
        # ordinal
        if(any(alpha_i[-1] - alpha_i[-(M_i-1)] < 0)) {
          # if the intercept violates orders
          NA
        } else {
          g_i_h = sapply(alpha_i, function(alpha) Z_h %*% c(alpha, beta_i) + (Z_h %*% zeta_i)*y)
          pi_i_h = sapply(g_i_h, expit)
          pi_i_h_diff = c(pi_i_h,1L) -c(0L, pi_i_h)
          pi_i_h_diff[data_X[h,i]]
        }
      }
    }



  })
  # take product
  do.call(prod, c(fun_x_h_given_y_h_elementwise))
}

#' @export
fun_x_h_y_h_joint <- function(y, h,
                              current_est_list,
                              data_Z, data_X) {

  fun_x_h_given_y_h(y = y, h = h,
                    current_est_list = current_est_list,
                    data_Z = data_Z, data_X = data_X)*exp(-y^2L/2)
}

