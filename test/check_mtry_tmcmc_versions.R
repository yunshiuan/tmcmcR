library(devtools)
#install_github('kkdey/tmcmcR')
library(tmcmcR)
library(mcmc)
d=30;  ##  dimension of the simulated variable
L=30; ###   the number of replications we use for finding KS statistic
nsamples <- 1000;
Mult_Mattingly=array(0,c(2,L,nsamples,d));


mu_target=rep(0,d);
Sigma_target = 0.01*diag(1/(1:(d))*d);

L=30; ###   the number of replications we use for finding KS statistic

Mult_Mattingly=array(0,c(2,L,nsamples,d));


Mattingly_matrix <- 100*(diag(1-0.7,d)+0.7*rep(1,d)%*%t(rep(1,d)));

library(mvtnorm)

pdf = function(x)
{
  return (dmvnorm(x,mu_target,Sigma_target,log=TRUE)-t(x)%*%Mattingly_matrix%*%x)
}

base=rnorm(d,0,1);

for ( l in 1:L)
{
  Mult_Mattingly[1,l,,] <- tmcmcR:::mt_tmcmc_metrop(pdf, base=base, scale=1,nmove_size=5, nmove=50, revgen=TRUE, nsamples=1000,burn_in = NULL)$chain;
  Mult_Mattingly[2,l,,] <- tmcmcR:::mt_tmcmc_metrop(pdf, base=base, scale=1,nmove_size=5, nmove=50, revgen=FALSE, nsamples=1000,burn_in = NULL)$chain;
  cat("We are at iter:",l, "\n")
}


KSval_mtry_TMCMC_v1=array(0,nsamples);
KSval_mtry_TMCMC_v2=array(0,nsamples);

for(d in 1:30)
{
  for(n in 1:nsamples)
  {
    simulate.vec <- rnorm(L,mu_target[d],Sigma_target[d,d]/(sqrt(2*Sigma_target[d,d]^2+1)));
    KSval_mtry_TMCMC_v1[n]=ks.test(Mult_Mattingly[1,,n,d],simulate.vec)$statistic;
    KSval_mtry_TMCMC_v2[n]=ks.test(Mult_Mattingly[2,,n,d],simulate.vec)$statistic;

  }

  plot(1:nsamples,KSval_mtry_TMCMC_v1,col="red",type="l",lwd=1,pch=2,xlab="",ylab="")
  lines(1:nsamples,KSval_mtry_TMCMC_v2,col="blue",lwd=1,pch=3)
  title(xlab="Time step of run");
  title(ylab="KS test distance");
  title(main="KS plot comparison");
  legend("topright",c("mtry_TMCMC_V1","mtry_TMCMC_V2"),fill=c("red","blue"),border="black");
}


