#' Plotting the Item Characteristics Curve (ICC) based on LIDIF results
#'
#' The function plots the ICC curve by items and is especially helpful if you want to visualize uniform/non-uniform DIF effects found in LIDIF modeling.
#'
#' @param coefs_list The list of DIF effects. Should be of the same format as the `coefficients` value in `LIDIF` output.
#' @param cov_mat The covariate matrix. DIF effects can be visualized by specifying different values for one of the covariates.
#' @param compare_var The name of covariate you would to visualize the DIF effect.
#' @param type_list A vector of characters containing the types of items (`binary`,`ordinal`). If the length of vector is 1, then the same type would apply to all items.
#' @param title Title of the plot. The defualt value is `NULL`.
#' @param latent_name Name of the latent variable (showing in the x-axises). The default is `latent`.
#' @param xrange  the seqeunce of the latent variable to be plotted from. The default setting is from -3 to 3 and seperated by 0.01.
#'
#' @returns The plot combining ICC curves of all items.
#'
#' @export
#'
#' @examples
#'  \dontrun{
#' ## load the sample data (see `?LIDIF::binsurvs` for details)
#' binsurvs = LIDIF::binsurvs # The exogenous variables are age and sex.
#'
#'
#' ## prepare for model fitting
#' dat.list = prepare_data(binsurvs$X, binsurvs$Z)
#'
#' ## LIDIF fitting
#' # The parameter specified is set to reduce the running time.
#' # In your analysis, please refer to the default value.
#' library(LIDIF)
#' res = LIDIF(dat.list = dat.list,
#'             cl_num = 5, # before running, please check if you have 5 cores
#'             type_list = "binary",
#'             maxit = 2,
#'             random_per = 0.5,
#'             init_nums = 2,
#'             init_maxit = 2)
#'
#' ## Plot the DIF effects for sex using ICC curves
#' # specify the covariate matrix
#' tt = cbind("age" = c(mean(dat.list$Z[,"age"]), mean(dat.list$Z[,"age"])),
#'            "sex" = c(0,1))
#'getICC(res$coefficients,
#'       cov_mat = tt,
#'       compare_var = "sex",
#'       type_list = "binary")
#' }
#'
#' @import ggplot2

getICC = function(coefs_list, # list of coefficients, should be of the same format as LIDIF output
                  cov_mat, # the value assigned to the covariates, the order should be the same as that in the output of prepare_data function
                  compare_var,
                  type_list,
                  title = NULL, # title of the ICC plot.
                  latent_name = "latent",
                  xrange = seq(-3,3,0.01)) {
  yvec = xrange

  cvn = which(colnames(cov_mat) == compare_var)

  tb = lapply(1:length(coefs_list), function(idx) {
    par = coefs_list[[idx]]
    intt = stringr::str_detect(names(par), "Intercept")

    re = lapply(1:nrow(cov_mat), function(i) {
      cv = cov_mat[i,]
      tmp = cbind.data.frame(yvec, sapply(1:sum(intt), function(j) {
        par1 = c(par[intt][j], par[!intt])
        expit(cbind(rep(1, length(yvec)) %*% t(c(1,cv)), yvec %*% t(c(1,cv))) %*% par1)
      }))
      colnames(tmp) = c("y", paste0("Level ", 1:(ncol(tmp)-1)))
      tmp$group = paste(names(cv)[cvn], "=", cv[cvn])
      tmp
    })

    re_long = lapply(re, function(item) {
      reshape2::melt(item, id.vars = c("y","group"), variable.name = "levels")
    })
    re_long = do.call(rbind, re_long)
    re_long$item = names(coefs_list)[[idx]]
    re_long
  })

  tb = do.call(rbind, tb)

  if(type_list == "binary") {
    pp = ggplot2::ggplot(tb, aes_string(x = "y", y = "value")) +
      geom_line(aes_string(color = "group")) + labs( x= latent_name, y = "Probability of endorsing yes", title = title) +
      theme_bw() +
      theme(axis.line = element_line(colour = "black"),
            legend.position = "bottom",
            legend.justification = "left")  + facet_wrap(~item)
  }

  else if(type_list == "ordinal") {
    pp = ggplot2::ggplot(tb, aes_string(x = "y", y = "value")) +
      geom_line(aes_string(linetype= "levels", color = "group")) + labs( x= latent_name, y = "Probability of endorsing greater or equal to", title = title) +
      theme_bw() +
      theme(axis.line = element_line(colour = "black"),
            legend.position = "bottom",
            legend.justification = "left")  + facet_wrap(~item)
  }

  print(pp)
}
