#' @title Simulate a MC3/RMC3 algorithm (Rcpp sped up version)
#' @description The function simulates a MC3/RMC3 chain of length nsamples using the scale, base and burn in taken optimally as default or specified by user.
#'  beta_set is the set of inverse temperatures chosen using select_inverse_temp() function,
#'  either under fixed scheme (MC3) or under randomized scheme (RMC3)
#'
#' @param target_pdf The log target density function from which the user wants to generate samples.
#' @param beta_set The vector of inverse temperatures used (see select_inverse_temp() function to choose this vector appropriately).
#' @param scale The proposal density scaling parameter. An approximation of the optimal scaling given the target_pdf is performed by OptimalScaling().
#'              The default scale is this estimated optimal scaling
#' @param base The starting value of the chain
#' @param nsamples The number of samples to be drawn.
#' @param cycle The number of iterations of RWMH chaining that is followed by a swap, or gap between consecutive
#'        swaps.Default is nsamples *0.01, rounded to next integer
#' @param swap_adjacent logical parameter, whether we allow for swaps between only consecutive inverse temperatures or any
#'        randomly chosen inverse temperatures pair. Default is TRUE.
#' @param burn_in The number of samples assigned as burn-in period. The default burn-in is taken to be one-third of nsamples.
#' @param verb logical parameter, if TRUE the function prints the progress of simulation.
#'
#' @return Returns a list containing the following items
#' \item{chain_set}{A list of chains at different underlying inverse temperatures produced by the MC3/RMC3 algorithm.}
#' \item{post.mean}{The estimated posterior mean for the principal chain (inverse temp=1) adjusting for burn-in.}
#
#'  @author  Kushal K Dey
#'
#'  @useDynLib tmcmcR
#'  @export
#'



rmc3 <- function(target_pdf, beta_set, scale, base, nsamples, cycle, verb=TRUE,
                 swap_adjacent=TRUE, burn_in=NULL)
{
  if(is.null(burn_in)) burn_in <- nsamples/3;
  if(is.null(scale)) stop("scale value not provided")
  if(is.null(beta_set)) stop("set of inverse temperatures not provided")

  rmc3_chains <- vector("list", length(beta_set));
  num = 1
  while(num <= nsamples){
    if(.Platform$OS.type == "unix"){
    chain_set <- parallel::mclapply(1:length(beta_set),
                             function(k){
                               if(num==1){
                                 chain <- t(as.matrix(base, nrow=1));
                                 out <- chain;
                               }
                               if(num > 1)
                               {
                                 temp_chain <- rmc3_chains[[k]][(num-1),];
                                 eps <- rnorm(length(temp_chain),0,scale);
                                 temp_chain <- rwmhUpdate(temp_chain,eps,function(x) return(beta_set[k]*target_pdf(x)))$chain;
                                 out <- rbind(rmc3_chains[[k]],as.vector(temp_chain));
                               }
                               return(out)
                             }, mc.cores=parallel::detectCores()
    )
    }
    else{
      chain_set <- mclapply.hack(1:length(beta_set),
                                      function(k){
                                        if(num==1){
                                          chain <- t(as.matrix(base, nrow=1));
                                          out <- chain;
                                        }
                                        if(num > 1)
                                        {
                                          temp_chain <- rmc3_chains[[k]][(num-1),];
                                          eps <- rnorm(length(temp_chain),0,scale);
                                          temp_chain <- rwmhUpdate(temp_chain,eps,function(x) return(beta_set[k]*target_pdf(x)))$chain;
                                          out <- rbind(rmc3_chains[[k]],as.vector(temp_chain));
                                        }
                                        return(out)
                                      }
      )
    }

    rmc3_chains <- chain_set;

    if(num %% cycle ==0)
    {
      if(swap_adjacent)
      {
        index_select <- sample(2:length(beta_set), 1);
        indices <- c(index_select-1, index_select);
      }
      if(!swap_adjacent)
      {
        indices <- sample(1:length(beta_set), 2);
      }
      chain1 <- rmc3_chains[[indices[1]]][num,];
      chain2 <- rmc3_chains[[indices[2]]][num,];
      swap_rate <- min(1, exp((beta_set[indices[2]] - beta_set[indices[1]])*(target_pdf(chain2)-target_pdf(chain1))));
      w <- runif(1,0,1)
      if(w < swap_rate){
        rmc3_chains[[indices[1]]][num,] <- chain2;
        rmc3_chains[[indices[2]]][num,] <- chain1;
      }
    }

    if(num %% 500 ==0){
      if(verb){
        cat("The chain is at iteration:",num,"\n");
      }
    }
    num <- num + 1;
  }
  if(length(base) > 1)
  posterior_mean <- apply(rmc3_chains[[1]][round(burn_in):nsamples,], 2, mean);
  if(length(base)==1)
  posterior_mean <- mean(rmc3_chains[[1]][round(burn_in):nsamples,]);
  ll <- list("chain_set"=rmc3_chains,"post.mean"=posterior_mean);
  return(ll)
}
