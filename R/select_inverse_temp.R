#' @title Select inverse temperatures in RMC3 and RTMC3
#'
#'
#' @param pdf_component The marginal distribution of the iid product component target distribution
#' @param minbeta the minimum cut off of inverse temperature we allow in RMC3 or RTMC3 (default is 0.05)
#' @param L_iter The number of sub-iterations required to fix each iterate of the inverse temperatures
#' @param method The method used to simulate from the marginal pdf component. Choices include TMCMC and RWMH.
#'
#' @description The function selects the inverse temperatures using a Stochastic approximation
#' algorithm for RMC3 or RTMC3 chains.
#'
#' @author  Kushal K Dey
#'
#' @export
#'


select_inverse_temp <- function(pdf_component, minbeta=0.05, L_iter =50,
                                sim_method=c("RWMH","TMCMC"),
                                inv_temp_scheme = c("randomized","fixed"))
{
  beta_array <- 1;
  counter <- 1
  current_beta = 1;
  while(current_beta > minbeta)
  {
    rho <- 0;
    for (l in 1:L_iter)
    {
      temp_beta <- current_beta * (1/(1 + exp(rho)));
      pdf_1 <- function(x, current_beta = current_beta) { return(pdf_component(x)*current_beta)};
      pdf_2 <- function(x, temp_beta=temp_beta) { return(pdf_component(x)*temp_beta)};

      x_curr <- .rand_generate(pdf_1, method=method);
      x_temp <- .rand_generate(pdf_2, method=method);

      B <- -(temp_beta - current_beta)* (pdf_2(x_temp,temp_beta) - pdf1(x_curr, current_beta));
      alpha <- min(1, exp(B));
      if(inv_temp_scheme=="randomized")
        rho <- rho + (1/l) * (alpha - 0.44);
      if(inv_temp_scheme=="fixed")
        rho <- rho + (1/l) * (alpha - 0.234);
    }

    current_beta <- current_beta * (1/(1 + exp(rho)));
    paste("The inverse temperature selected:", counter);
    beta_array <- c(beta_array, current_beta);
    counter <- counter + 1;
  }
  return(rev(beta_array))
}