#' @export
target_M_step_i <- function(i, est_i, y,
                            current_est_list,int_lower_bound, int_upper_bound,
                            fun_x,
                            data_Z, data_X) {
  J <- ncol(as.matrix(data_Z))
  n <- nrow(data_X)
  M_i <- length(unique(stats::na.omit(data_X[,i])))

  alpha_i <- est_i[1L:(M_i-1L)]
  if(J > 1) {
    beta_i = est_i[M_i:(M_i+J-2L)]
  } else {
    beta_i = NULL
  }
  zeta_i <- est_i[(M_i+J-1L):(2L*J+M_i-2L)]

  if(any(alpha_i[-1] - alpha_i[-(M_i-1)] < 0)) {
    ans = NA
  } else {
    if(M_i == 2) {
      target_M_step_i_elementwise <- lapply(1:n, function(h) {
        if(is.na(data_X[h,i])) {
          0
        } else {
          Z_h <- data_Z[h,]
          data_X_i <- data_X[,i]
          g_i_h = sapply(alpha_i, function(alpha) Z_h %*% c(alpha, beta_i) + (Z_h %*% zeta_i)*y)
          pi_i_h <- expit(g_i_h)
          one_pi_i_h <- exp(- g_i_h)/(1+exp(- g_i_h))
          fun_y_h_given_x_h <- fun_x_h_y_h_joint(y = y, h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)/fun_x[h]
          (log(one_pi_i_h) + data_X_i[h]*(zeta_i %*%Z_h)*y)*fun_y_h_given_x_h
        }
      })
      ans = do.call(sum, c(target_M_step_i_elementwise))
    } else {
      target_M_step_i_elementwise <- lapply(1L:n, function(h) {

        if(is.na(data_X[h,i])) {
          0
        } else {
          Z_h <- data_Z[h,]
          g_i_h = sapply(alpha_i, function(alpha) Z_h %*% c(alpha, beta_i) + (Z_h %*% zeta_i)*y)
          pi_i_h = expit(g_i_h)
          pi_diff = c(pi_i_h,1L) - c(0L, pi_i_h)
          fun_y_h_given_x_h <- fun_x_h_y_h_joint(y = y, h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)/fun_x[h]
          ((log(pi_diff))[data_X[h,i]])*fun_y_h_given_x_h
        }
      })
      ans = do.call(sum, c(target_M_step_i_elementwise))
    }
  }
  return(ans)

}

#' @export
target_M_step_i_int <- function(i, est_i, fun_x,
                                current_est_list, int_lower_bound = -5L, int_upper_bound = 5L,
                                data_Z, data_X, maxEval = 10L) {
  int <- cubature::adaptIntegrate(target_M_step_i, maxEval = maxEval, i = i, est_i = est_i,
                                  current_est_list = current_est_list,lower = int_lower_bound, upper = int_upper_bound,
                                  int_lower_bound = int_lower_bound, int_upper_bound = int_upper_bound,
                                  fun_x = fun_x,
                                  data_Z = data_Z, data_X = data_X)$integral

  M_i <- length(unique(stats::na.omit(data_X[,i])))
  if(M_i == 2) {
    J <- ncol(as.matrix(data_Z))

    beta_i <- est_i[1:J]
    zeta_i <- est_i[(J+1):(2*J)]
    data_X_i <- data_X[,i]
    -(int + sum(data_Z %*% beta_i * data_X_i, na.rm = TRUE))
  }
  else {
    -int
  }
}
