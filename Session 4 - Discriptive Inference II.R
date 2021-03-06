# TA: Patrick Chester
# Course: Text as Data
# Date: 2/14/2017
# Recitation 4: Descriptive Inference II

## Some Examples taken wholesale from Ken Benoit's NYU Dept. of Politics short course Fall 2014
## Avaliable on his website: www.kenbenoit.net

# Clear Global Environment
rm(list = ls())

# 1 Loading packages
library(quanteda)
library(boot)
library(dplyr)

# 2 Load in data: Irish budget proposals from 2008-2012
data(iebudgetsCorpus, package = "quantedaData")

df <- texts(iebudgetsCorpus)

# 3 Lexical diversity measures

# TTR 
tokens <- tokenize(df, removePunct=TRUE) 

tokenz <- lengths(tokens)

typez <- ntype(tokens)

ttr <- typez / tokenz

head(tokenz)

# Would you expect the budgets to become more or less complex over time
plot(ttr)

# Aggregating average TTR scores

aggregate(ttr, by = list(iebudgetsCorpus[["year"]]$year), FUN = mean)

aggregate(ttr, by = list(iebudgetsCorpus[["party"]]$party), FUN = mean)


# Another way:
textstat_lexdiv(dfm(iebudgetsCorpus, groups = "year", removePunct=TRUE, verbose = FALSE), measure = "TTR")

textstat_lexdiv(dfm(iebudgetsCorpus, groups = "party", removePunct=TRUE, verbose = FALSE), measure = "TTR")

# Thoughts on TTR


# Readability measure

# let's look at FRE
textstat_readability(iebudgetsCorpus, "Flesch")

textstat_readability(texts(iebudgetsCorpus, groups = "year"), "Flesch")

textstat_readability(texts(iebudgetsCorpus, groups = "party"), "Flesch")


# Dale-Chall measure

textstat_readability(iebudgetsCorpus, "Dale.Chall")

textstat_readability(texts(iebudgetsCorpus, groups = "year"), "Dale.Chall")

textstat_readability(texts(iebudgetsCorpus, groups = "party"), "Dale.Chall")

# let's compare each measure

cor(textstat_readability(iebudgetsCorpus, c("Flesch", "Dale.Chall", "SMOG", "Coleman.Liau", "Fucks")))


# 4 Bootstrapping

# A. First we try bootstrapping with the boot function

# remove smaller parties
iebudgetsCorpSub <- corpus_subset(iebudgetsCorpus, !(party %in% c("WUAG", "SOC", "PBPA" )))

bsReadabilityByGroup <- function(x, i, groups = NULL, measure = "Flesch")
  textstat_readability(texts(x[i], groups = groups), measure)
R <- 50

# by party
groups <- factor(iebudgetsCorpSub[["party"]]$party)
b <- boot(texts(iebudgetsCorpSub), bsReadabilityByGroup, strata = groups, R = R, groups = groups)
colnames(b$t) <- names(b$t0)
apply(b$t, 2, quantile, c(.025, .5, .975))

# by year
groups <- factor(iebudgetsCorpSub[["year"]]$year)
b <- boot(texts(iebudgetsCorpSub), bsReadabilityByGroup, strata = groups, R = R, groups = groups)
colnames(b$t) <- names(b$t0)
apply(b$t, 2, quantile, c(.025, .5, .975))

# FYI: you can get the SEs the same way, from b$t


# Next, we will use a loop to bootstrap the text and calculate standard errors

# initialize data frames
year_FRE <- data.frame(matrix(ncol = 5, nrow = 100))
party_FRE<-data.frame(matrix(ncol = 6, nrow = 100))

df <- data.frame(texts = iebudgetsCorpSub[["texts"]]$texts, 
                 party = iebudgetsCorpSub[["party"]]$party,
                 year = as.numeric(iebudgetsCorpSub[["year"]]$year),
                 stringsAsFactors = F)


# Let's filter out the parties with only one speech
df <- filter(df, party != "WUAG", party != "SOC", party != "PBPA" )

# run the bootstraps

for(i in 1:100){
  
  #sample 200 
  bootstrapped<-sample_n(df, 200, replace=TRUE)
  
  bootstrapped$read_FRE<-textstat_readability(bootstrapped$texts, "Flesch")
  
  #store results
  
  year_FRE[i,]<-aggregate(bootstrapped$read_FRE, by=list(bootstrapped$year), FUN=mean)[,2]
  
  party_FRE[i,]<-aggregate(bootstrapped$read_FRE, by=list(bootstrapped$party), FUN=mean)[,2]
  
}

# Name the data frames

colnames(year_FRE)<-names(table(df$year))
colnames(party_FRE)<-names(table(df$party))

# Define the standard error function
std <- function(x) sd(x)/sqrt(length(x))

# Calculate standard errors and point estimates

year_ses<-apply(year_FRE, 2, std)

year_means<-apply(year_FRE, 2, mean)


party_ses<-apply(party_FRE, 2, std)

party_means<-apply(party_FRE, 2, mean)


# Plot results--year

coefs<-year_means
ses<-year_ses

y.axis <- c(1:5)
min <- min(coefs - 2*ses)
max <- max(coefs + 2*ses)
var.names <- colnames(year_FRE)
adjust <- 0
par(mar=c(2,8,2,2))

plot(coefs, y.axis, type = "p", axes = F, xlab = "", ylab = "", pch = 19, cex = .8, 
     xlim=c(min,max),ylim = c(.5,6.5), main = "")
rect(min,.5,max,1.5, col = c("grey97"), border="grey90", lty = 2)
rect(min,1.5,max,2.5, col = c("grey95"), border="grey90", lty = 2)
rect(min,2.5,max,3.5, col = c("grey97"), border="grey90", lty = 2)
rect(min,3.5,max,4.5, col = c("grey95"), border="grey90", lty = 2)
rect(min,4.5,max,5.5, col = c("grey97"), border="grey90", lty = 2)
#rect(min,5.5,max,6.5, col = c("grey97"), border="grey90", lty = 2)

axis(1, at = seq(min,max,(max-min)/10), 
     labels = c(round(min+0*((max-min)/10),3),
                round(min+1*((max-min)/10),3),
                round(min+2*((max-min)/10),3),
                round(min+3*((max-min)/10),3),
                round(min+4*((max-min)/10),3),
                round(min+5*((max-min)/10),3),
                round(min+6*((max-min)/10),3),
                round(min+7*((max-min)/10),3),
                round(min+8*((max-min)/10),3),
                round(min+9*((max-min)/10),3),
                round(max,3)),tick = T,cex.axis = .75, mgp = c(2,.7,0))
axis(2, at = y.axis, label = var.names, las = 1, tick = FALSE, cex.axis =.8)
abline(h = y.axis, lty = 2, lwd = .5, col = "white")
segments(coefs-qnorm(.975)*ses, y.axis+2*adjust, coefs+qnorm(.975)*ses, y.axis+2*adjust, lwd =  1)

segments(coefs-qnorm(.95)*ses, y.axis+2*adjust-.035, coefs-qnorm(.95)*ses, y.axis+2*adjust+.035, lwd = .9)
segments(coefs+qnorm(.95)*ses, y.axis+2*adjust-.035, coefs+qnorm(.95)*ses, y.axis+2*adjust+.035, lwd = .9)
points(coefs, y.axis+2*adjust,pch=21,cex=.8, bg="white")

# Now let's compute the Flesch statistic directly for years
table(df$year)
df$read_FRE<-textstat_readability(df$texts, "Flesch")
observed<-aggregate(df$read_FRE, by=list(df$year), FUN=mean)

# How well did we do?


# Plot results--party

coefs<-party_means
ses<-party_ses

y.axis <- c(1:6)
min <- min(coefs - 2*ses)
max <- max(coefs + 2*ses)
var.names <- colnames(party_FRE)
adjust <- 0
par(mar=c(2,8,2,2))

plot(coefs, y.axis, type = "p", axes = F, xlab = "", ylab = "", pch = 19, cex = .8, 
     xlim=c(min,max),ylim = c(.5,6.5), main = "")
rect(min,.5,max,1.5, col = c("grey97"), border="grey90", lty = 2)
rect(min,1.5,max,2.5, col = c("grey95"), border="grey90", lty = 2)
rect(min,2.5,max,3.5, col = c("grey97"), border="grey90", lty = 2)
rect(min,3.5,max,4.5, col = c("grey95"), border="grey90", lty = 2)
rect(min,4.5,max,5.5, col = c("grey97"), border="grey90", lty = 2)
rect(min,5.5,max,6.5, col = c("grey97"), border="grey90", lty = 2)

axis(1, at = seq(min,max,(max-min)/10), 
     labels = c(round(min+0*((max-min)/10),3),
                round(min+1*((max-min)/10),3),
                round(min+2*((max-min)/10),3),
                round(min+3*((max-min)/10),3),
                round(min+4*((max-min)/10),3),
                round(min+5*((max-min)/10),3),
                round(min+6*((max-min)/10),3),
                round(min+7*((max-min)/10),3),
                round(min+8*((max-min)/10),3),
                round(min+9*((max-min)/10),3),
                round(max,3)),tick = T,cex.axis = .75, mgp = c(2,.7,0))
axis(2, at = y.axis, label = var.names, las = 1, tick = FALSE, cex.axis =.8)
abline(h = y.axis, lty = 2, lwd = .5, col = "white")
segments(coefs-qnorm(.975)*ses, y.axis+2*adjust, coefs+qnorm(.975)*ses, y.axis+2*adjust, lwd =  1)

segments(coefs-qnorm(.95)*ses, y.axis+2*adjust-.035, coefs-qnorm(.95)*ses, y.axis+2*adjust+.035, lwd = .9)
segments(coefs+qnorm(.95)*ses, y.axis+2*adjust-.035, coefs+qnorm(.95)*ses, y.axis+2*adjust+.035, lwd = .9)
points(coefs, y.axis+2*adjust,pch=21,cex=.8, bg="white")

# Directly calculating the Flesch statistic by party
aggregate(df$read_FRE, by=list(df$party), FUN=mean)

# How well did we do?