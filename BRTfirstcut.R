# TODO: Add comment
# 
# Author: solomon
###############################################################################


library("dplyr")
setwd("~/Documents/workspace/BayesImpact/")
dat <- read.csv("data/SFPD_Incidents_-_Previous_Three_Months.csv")

summary(dat$Category)

gridsize <- 25 + 1
dat$Xcut <- cut(dat$X, seq(from = min(dat$X), to = max(dat$X), length.out = gridsize))
dat$Ycut <- cut(dat$Y, seq(from = min(dat$Y), to = max(dat$Y), length.out = gridsize))
head(dat$Xcut)


cut_to_mean <- function(labs){
  apply(
      cbind(lower = as.numeric( sub("\\((.+),.*", "\\1", labs) ),
      upper = as.numeric( sub("[^,]*,([^]]*)\\]", "\\1", labs) )), 
  1,
  mean)  
}


tiledat <- expand.grid(
    Xcut = levels(dat$Xcut),
    Ycut = levels(dat$Ycut)) 

ASSAULTs <- dat %>% 
    filter(Category == "ASSAULT") %>%
    group_by(Xcut, Ycut) %>% 
    summarise(sum_crime = n()
    )

tiled_ASSAULTs <- left_join(tiledat, ASSAULTs)

hist(tiled_ASSAULTs$sum_crime)

tiled_ASSAULTs$sum_crime_q <- ecdf(tiled_ASSAULTs$sum_crime)(tiled_ASSAULTs$sum_crime)
tiled_ASSAULTs$sum_crime_01 <- !is.na(tiled_ASSAULTs$sum_crime)
summary(tiled_ASSAULTs$sum_crime_01)
library(ggplot2)


tiled_ASSAULTs$X <- cut_to_mean(tiled_ASSAULTs$Xcut)
tiled_ASSAULTs$Y <- cut_to_mean(tiled_ASSAULTs$Ycut)

#head(tiled_ASSAULTs[!is.na(tiled_ASSAULTs$sum_crime),])
ggplot(tiled_ASSAULTs,
        aes(x = X, y = Y )) + 
    geom_tile(aes(fill = sum_crime_q)) + 
    scale_fill_gradient(low = "white", high = "steelblue") + theme_bw() 
ggsave("bla.pdf")

#install.packages("ggmap")
library("ggmap")
g <- qmap("San Francisco", zoom = 12)  
g +  geom_point(data=tiled_ASSAULTs, 
        aes(x = X, y = Y, alpha = sum_crime_q)) + 
     theme_bw() 
ggsave("bla.pdf")
scale_fill_gradient(low = "white", high = "steelblue") 

tiled_ASSAULTs$sum_crime[is.na(tiled_ASSAULTs$sum_crime)] <- 0

m1 <- gbm.step(
    data=tiled_ASSAULTs, 
    gbm.x = 6:7,
    gbm.y = 3,
    family = "poisson", 
    n.folds = 5,
    n.trees = 20,
    tree.complexity = 2,
    bag.fraction = 0.75)

length(m1$fitted)
m1$cv.statistics

gbm.plot.fits(m1)

tiled_ASSAULTs$fitted <- m1$fitted

summary(log(tiled_ASSAULTs$sum_crime+1))


library("ggmap")
g <- qmap("San Francisco", zoom = 12)  
g +  geom_point(data=tiled_ASSAULTs, 
        aes(x = X, y = Y, alpha = log(sum_crime+1))) + 
    theme_bw() 
g +  geom_point(data=tiled_ASSAULTs, 
        aes(x = X, y = Y, alpha = fitted)) + 
    theme_bw() 
ggsave("bla.pdf")




