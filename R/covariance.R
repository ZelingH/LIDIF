target_M_elementwise_gradient <- function(y, h,
                                          current_est_list,int_lower_bound, int_upper_bound,
                                          fun_x,
                                          data_Z, data_X) {


  J <- ncol(as.matrix(data_Z))
  P <- ncol(as.matrix(data_X))

  gradient_all_items = lapply(1L:P, function(i) {

    M_i <- length(unique(stats::na.omit(data_X[,i])))
    est_i = current_est_list[[i]]

    alpha_i <- est_i[1L:(M_i-1L)]
    if(J > 1) {
      beta_i = est_i[M_i:(M_i+J-2L)]
    } else {
      beta_i = NULL
    }
    zeta_i <- est_i[(M_i+J-1L):(2L*J+M_i-2L)]

    Z_h <- data_Z[h,]
    g_i_h <- sapply(alpha_i, function(alpha) Z_h %*% c(alpha, beta_i) + (Z_h %*% zeta_i)*y)
    pi_i_h <- expit(g_i_h)

    if(M_i == 2) {
      data_X_i <- data_X[,i]
      x_i_h <- data_X_i[h]
      fun_y_h_given_x_h <- fun_x_h_y_h_joint(y = y, h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)/fun_x[h]
      c(
        c((x_i_h - pi_i_h)*fun_y_h_given_x_h) * Z_h,
        c((x_i_h-pi_i_h)*y*fun_y_h_given_x_h)* Z_h
      )
    } else {
      alpha_dd = rep(0L, M_i - 1L)
      m = data_X[h,i]
      fun_y_h_given_x_h <- fun_x_h_y_h_joint(y = y, h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)/fun_x[h]
      if(is.na(m)) {
        rep(NA, length(alpha_dd)+2*length(Z_h)-1)
      }else if(m == 1L) {
        alpha_dd[1] = 1L
        c(alpha_dd, Z_h[-1L],y*Z_h) * fun_y_h_given_x_h * (1L-pi_i_h[1L])
      } else if (m == M_i) {
        alpha_dd[M_i-1L] = 1L
        c(alpha_dd,Z_h[-1L],y*Z_h) * fun_y_h_given_x_h * -pi_i_h[M_i-1L]
      } else {
        alpha_dd[m-1L] = -1L/(pi_i_h[m] - pi_i_h[m-1L])*pi_i_h[m-1L]*(1L-pi_i_h[m-1L])
        alpha_dd[m] = 1L/(pi_i_h[m] - pi_i_h[m-1])*pi_i_h[m]*(1L-pi_i_h[m])
        c(alpha_dd, (1L-pi_i_h[m-1L] - pi_i_h[m])*Z_h[-1L], (1L-pi_i_h[m-1L] - pi_i_h[m])*y*Z_h)* fun_y_h_given_x_h
      }
    }
  })

  do.call(c, gradient_all_items)
}

score_square_x <- function(current_est_list, int_lower_bound = -5L, int_upper_bound = 5L,
                           data_Z, data_X, maxEval = 10) {

  J <- ncol(as.matrix(data_Z))
  P <- ncol(as.matrix(data_X))
  n <- nrow(data_X)

  M_t <- sum(apply(data_X, 2, function(x) length(unique(stats::na.omit(x)))))
  fun_x_vec <- sapply(1L:n, function(h) {
    cubature::adaptIntegrate(fun_x_h_y_h_joint, lower = int_lower_bound, upper = int_upper_bound,maxEval = maxEval,
                             h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)$integral
  })
  int_list = lapply(1L:n, function(h) {
    tmp = cubature::adaptIntegrate(target_M_elementwise_gradient,h = h, fDim = 2L*(J-1L)*P+M_t, maxEval = maxEval,
                                   current_est_list = current_est_list,lower = int_lower_bound, upper = int_upper_bound,
                                   int_lower_bound = int_lower_bound, int_upper_bound = int_upper_bound,
                                   fun_x = fun_x_vec,
                                   data_Z = data_Z, data_X = data_X)$integral
    tmp[is.na(tmp)] = 0L
    tmp%*%t(tmp)
  })
  int_mat = Reduce(`+`, int_list)
  return(int_mat)
}
