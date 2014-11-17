# TODO: Add comment
# 
# Author: solomon
###############################################################################


library("dplyr")
setwd("~/sftp/out-for-justice/")
setwd("~/Documents/workspace/BayesImpact/")
#dat <- read.csv("data/SFPD_Incidents_-_Previous_Three_Months.csv")
#dat <- read.csv("data/sfpd_service_calls.csv")

# scp /Users/solomon/Documents/workspace/BayesImpact/data/incidents.csv solomon@dev1706.prn1.facebook.com:/home/solomon/sftp/out-for-justice/data/incidents.csv


dat <- read.csv("data/incidents.csv")

dat$Year <- substr(dat$DATETIME,1,4)
dat <- subset(dat, Year == "2013" | Year == "2014")

dat$COORDINATES <- as.character(dat$COORDINATES)
dat$X <- substr(dat$COORDINATES, 2, regexpr(",", dat$COORDINATES)-1)
dat$Y <- substr(dat$COORDINATES, regexpr(",", dat$COORDINATES)+1, 
    nchar(dat$COORDINATES)-2)
dat$X <- as.numeric(dat$X)
dat$Y <- as.numeric(dat$Y)
dat$hour <- substr(dat$DATETIME, 12, 14)
dat$date <- as.Date(dat$DATETIME)
dat$day <- weekdays(dat$date)

dat$crimetype <- "DROP"

dat$crimetype[dat$CATEGORY == "DRUG/NARCOTIC"] <- "INTOX"
dat$crimetype[dat$CATEGORY == "DRUNKENNESS"] <- "INTOX"

dat$crimetype[dat$CATEGORY == "VEHICLE THEFT"] <- "PROPERTY"
dat$crimetype[dat$CATEGORY == "VANDALISM"] <- "PROPERTY"
dat$crimetype[dat$CATEGORY == "LARCENY/THEFT"] <- "PROPERTY"
dat$crimetype[dat$CATEGORY == "BURGLARY"] <- "PROPERTY"

dat$crimetype[dat$CATEGORY == "ARSON"] <- "VIOLENT"
dat$crimetype[dat$CATEGORY == "ASSAULT"] <- "VIOLENT"
dat$crimetype[dat$CATEGORY == "SEX OFFENSES, FORCIBLE"] <- "VIOLENT"

#library("lubridate")
#dat$ldate <- ymd_hms(dat$DATETIME)
#dat$wday <- wday(dat$ldate)
#dat$cycle <- hour(dat$ldate) + 24*(wday(dat$ldate)-1) + 2
#dat$hour <- dat$cycle %% 24
#dat$day <- dat$cycle %% 7
#dat[sample(1:length(dat$cycle), 30), c("ldate", "wday", "day", "hour")]
#

dat$hour <- as.numeric(substr(dat$DATETIME, 12, 13))
dat$daytime <- "6PM-2AM"
dat$daytime[dat$hour > 1.99 & dat$hour < 10.01] <- "2AM-10AM"
dat$daytime[dat$hour > 9.99 & dat$hour < 18.01] <- "10AM-6PM"
dat$date <- as.Date(dat$DATETIME)
dat$day <- weekdays(dat$date)
dat$day_n <- 0
dat$day_n[dat$day=="Monday"] <- 1
dat$day_n[dat$day=="Tuesday"] <- 2
dat$day_n[dat$day=="Wednesday"] <- 3
dat$day_n[dat$day=="Thursday"] <- 4
dat$day_n[dat$day=="Friday"] <- 5
dat$day_n[dat$day=="Saturday"] <- 6
dat$cycle <- dat$hour + dat$day_n*24
dat$superday <- dat$day
dat$superday[dat$day == "Tuesday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Monday"
dat$superday[dat$day == "Wednesday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Tuesday"
dat$superday[dat$day == "Thursday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Wednesday"
dat$superday[dat$day == "Friday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Thursday"
dat$superday[dat$day == "Saturday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Friday"
dat$superday[dat$day == "Sunday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Saturday"
dat$superday[dat$day == "Monday" & dat$daytime == "6PM-2AM" 
        & dat$hour < 3] <- "Sunday"

##############################
# Set grid size, snap to grid

gridsize <- 50 + 1
dat$Xcut <- cut(dat$X, seq(from = min(dat$X), to = max(dat$X), length.out = gridsize))
dat$Ycut <- cut(dat$Y, seq(from = min(dat$Y), to = max(dat$Y), length.out = gridsize))

cut_to_mean <- function(labs){
  apply(
      cbind(lower = as.numeric( sub("\\((.+),.*", "\\1", labs) ),
      upper = as.numeric( sub("[^,]*,([^]]*)\\]", "\\1", labs) )), 
  1,
  mean)  
}

dat$daytime <- as.factor(dat$daytime)
dat$superday <- as.factor(dat$superday)

tiledat <- expand.grid(
    Xcut = levels(dat$Xcut),
    Ycut = levels(dat$Ycut),
    crimetype = "VIOLENT",
    daytime = levels(dat$daytime),
    superday = levels(dat$superday))

# Now summarize, counting crimes:
VIOLENTs <- dat %>% 
    filter(crimetype == "VIOLENT") %>%
    group_by(Xcut, Ycut, crimetype, daytime, superday) %>% 
    summarise(sum_crime = n())


levels(VIOLENTs$crimetype)
levels(tiledat$crimetype)
levels(tiled_VIOLENTs$daytime)
#tiledat$crimetype <- as.character(tiledat$crimetype)

tiled_VIOLENTs <- left_join(tiledat, VIOLENTs)
summary(tiled_VIOLENTs$sum_crime)


#tiled_VIOLENTs$sum_crime_q <- ecdf(tiled_VIOLENTs$sum_crime)(tiled_VIOLENTs$sum_crime)
tiled_VIOLENTs$X <- cut_to_mean(tiled_VIOLENTs$Xcut)
tiled_VIOLENTs$Y <- cut_to_mean(tiled_VIOLENTs$Ycut)

####################################
# Now fit GBRTs
#install.packages('dismo')
library('dismo')

# Set missing values to zero
tiled_VIOLENTs$sum_crime[is.na(tiled_VIOLENTs$sum_crime)] <- 0
#tiled_VIOLENTs$crimetype = as.factor(tiled_VIOLENTs$crimetype)
#tiled_VIOLENTs$daytime = as.factor(tiled_VIOLENTs$daytime)
#tiled_VIOLENTs$superday = as.factor(tiled_VIOLENTs$superday)

summary(tiled_VIOLENTs$sum_crime)

tiled_VIOLENTs[sample(nrow(tiled_VIOLENTs), 30),]


#m1 <- gbm.step(
#    data=tiled_VIOLENTs, 
#    gbm.x = c(4:5, 7:8),
#    gbm.y = 6,
#    family = "poisson", 
#    n.folds = 5,
#    n.trees = 20,
#    learning.rate = 0.01,
#    tree.complexity = 3,
#    bag.fraction = 0.75)
#save(m1, file = "violentModelSF.Rda")
load(file = "models/violentModelSF.Rda")

#install.packages("ROCR")
evaluateROCR(m1,a=tiled_VIOLENTs$sum_crime)
    
#ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
#    Y = cut_to_mean(levels(dat$Ycut)), 
#    crimetype = "VIOLENT",
#    daytime = levels(tiled_VIOLENTs$daytime),
#    superday = levels(tiled_VIOLENTs$superday))
ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
    Y = cut_to_mean(levels(dat$Ycut)), 
    crimetype = "VIOLENT",
    daytime = "6PM-2AM",
    superday = "Saturday")
ndat$preds <- predict(m1, 
    newdata = ndat,
    n.trees = 7620,
    type = "response")

summary(ndat$preds)


#tiled_ALL_CRIMESs$fitted <- m1$fitted
#
#tiled_ALL_CRIMESs$resid <- tiled_ALL_CRIMESs$fitted - 


#gbm.plot.fits(m1)
#length(m1$fitted)
#m1$cv.statistics


###########################
## Now plot results

#install.packages("ggmap")
library("ggmap")
library("ggplot2")
g <- qmap("San Francisco", zoom = 12)  
g +  geom_point(data=ndat[ndat$preds>0.5,], 
        aes(x = X, y = Y, alpha = preds, size = preds)) +
    geom_point(aes(y= 37.775271, x = -122.398685, color = "red", size=8)) +
    annotate("text", label = "BayesImpact\nHackSite", 
        y= 37.775271 - .005, x = -122.398685 + .02,
        colour = "red") +
    ggtitle("Predicted Violent Crimes\n(Poisson GBRT)") + 
    theme_bw() 
ggsave("bla.pdf")


##############################
## PROPERTY CRIME

tiledat <- expand.grid(
    Xcut = levels(dat$Xcut),
    Ycut = levels(dat$Ycut),
    crimetype = "PROPERTY",
    daytime = levels(dat$daytime),
    superday = levels(dat$superday))

# Now summarize, counting crimes:
PROPERTYs <- dat %>% 
    filter(crimetype == "PROPERTY") %>%
    group_by(Xcut, Ycut, crimetype, daytime, superday) %>% 
    summarise(sum_crime = n())


levels(PROPERTYs$crimetype)
levels(tiledat$crimetype)
levels(tiled_PROPERTYs$daytime)
#tiledat$crimetype <- as.character(tiledat$crimetype)

tiled_PROPERTYs <- left_join(tiledat, PROPERTYs)
summary(tiled_PROPERTYs$sum_crime)


#tiled_PROPERTYs$sum_crime_q <- ecdf(tiled_PROPERTYs$sum_crime)(tiled_PROPERTYs$sum_crime)
tiled_PROPERTYs$X <- cut_to_mean(tiled_PROPERTYs$Xcut)
tiled_PROPERTYs$Y <- cut_to_mean(tiled_PROPERTYs$Ycut)

####################################
# Now fit GBRTs
#install.packages('dismo')
library('dismo')

# Set missing values to zero
tiled_PROPERTYs$sum_crime[is.na(tiled_PROPERTYs$sum_crime)] <- 0
#tiled_PROPERTYs$crimetype = as.factor(tiled_PROPERTYs$crimetype)
#tiled_PROPERTYs$daytime = as.factor(tiled_PROPERTYs$daytime)
#tiled_PROPERTYs$superday = as.factor(tiled_PROPERTYs$superday)


head(tiled_PROPERTYs)

m2 <- gbm.step(
    data=tiled_PROPERTYs, 
    gbm.x = c(4:5, 7:8),
    gbm.y = 6,
    family = "poisson", 
    n.folds = 5,
    n.trees = 20,
    learning.rate = 0.01,
    tree.complexity = 3,
    bag.fraction = 0.75)
save(m2, file = "propertyModelSF.Rda")



#ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
#    Y = cut_to_mean(levels(dat$Ycut)), 
#    crimetype = "PROPERTY",
#    daytime = levels(tiled_PROPERTYs$daytime),
#    superday = levels(tiled_PROPERTYs$superday))
ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
    Y = cut_to_mean(levels(dat$Ycut)), 
    crimetype = "PROPERTY",
    daytime = "6PM-2AM",
    superday = "Saturday")
ndat$preds <- predict(m2, 
    newdata = ndat,
    n.trees = 7620,
    type = "response")

summary(ndat$preds)


#tiled_ALL_CRIMESs$fitted <- m1$fitted
#
#tiled_ALL_CRIMESs$resid <- tiled_ALL_CRIMESs$fitted - 


#gbm.plot.fits(m1)
#length(m1$fitted)
#m1$cv.statistics


###########################
## Now plot results

#install.packages("ggmap")
library("ggmap")
library("ggplot2")
g <- qmap("San Francisco", zoom = 12)  
g +  geom_point(data=ndat[ndat$preds>0.5,], 
        aes(x = X, y = Y, alpha = preds, size = preds)) +
    geom_point(aes(y= 37.775271, x = -122.398685, color = "red", size=8)) +
    annotate("text", label = "BayesImpact\nHackSite", 
        y= 37.775271 - .005, x = -122.398685 + .02,
        colour = "red") +
    ggtitle("Predicted Property Crimes\n(Poisson GBRT)") + 
    theme_bw() 
ggsave("bla.pdf")


##############################
## INTOX

tiledat <- expand.grid(
    Xcut = levels(dat$Xcut),
    Ycut = levels(dat$Ycut),
    crimetype = "INTOX",
    daytime = levels(dat$daytime),
    superday = levels(dat$superday))

# Now summarize, counting crimes:
INTOXs <- dat %>% 
    filter(crimetype == "INTOX") %>%
    group_by(Xcut, Ycut, crimetype, daytime, superday) %>% 
    summarise(sum_crime = n())

INTOXs$crimetype <- as.factor(INTOXs$crimetype)
levels(INTOXs$crimetype)
levels(tiledat$crimetype)
levels(tiled_INTOXs$daytime)
#tiledat$crimetype <- as.character(tiledat$crimetype)

tiled_INTOXs <- left_join(tiledat, INTOXs)
summary(tiled_INTOXs$sum_crime)


#tiled_INTOXs$sum_crime_q <- ecdf(tiled_INTOXs$sum_crime)(tiled_INTOXs$sum_crime)
tiled_INTOXs$X <- cut_to_mean(tiled_INTOXs$Xcut)
tiled_INTOXs$Y <- cut_to_mean(tiled_INTOXs$Ycut)

####################################
# Now fit GBRTs
#install.packages('dismo')
library('dismo')

# Set missing values to zero
tiled_INTOXs$sum_crime[is.na(tiled_INTOXs$sum_crime)] <- 0
#tiled_INTOXs$crimetype = as.factor(tiled_INTOXs$crimetype)
#tiled_INTOXs$daytime = as.factor(tiled_INTOXs$daytime)
#tiled_INTOXs$superday = as.factor(tiled_INTOXs$superday)


head(tiled_INTOXs)

m3 <- gbm.step(
    data=tiled_INTOXs, 
    gbm.x = c(4:5, 7:8),
    gbm.y = 6,
    family = "poisson", 
    n.folds = 5,
    n.trees = 20,
    learning.rate = 0.01,
    tree.complexity = 3,
    bag.fraction = 0.75)
#save(m3, file = "models/intoxModelSF.Rda")
# scp solomon@dev1706.prn1.facebook.com:/home/solomon/sftp/out-for-justice/intoxModelSF.Rda /Users/solomon/Documents/workspace/out-for-justice/intoxModelSF.Rda

load(file = "~/Documents/workspace/out-for-justice/models/intoxModelSF.Rda")

#ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
#    Y = cut_to_mean(levels(dat$Ycut)), 
#    crimetype = "INTOX",
#    daytime = levels(tiled_INTOXs$daytime),
#    superday = levels(tiled_INTOXs$superday))
ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
    Y = cut_to_mean(levels(dat$Ycut)), 
    crimetype = "INTOX",
    daytime = "6PM-2AM",
    superday = "Saturday")
ndat$preds <- predict(m3, 
    newdata = ndat,
    n.trees = 7620,
    type = "response")

summary(ndat$preds)


#tiled_ALL_CRIMESs$fitted <- m1$fitted
#
#tiled_ALL_CRIMESs$resid <- tiled_ALL_CRIMESs$fitted - 


#gbm.plot.fits(m1)
#length(m1$fitted)
#m1$cv.statistics


###########################
## Now plot results

#install.packages("ggmap")
library("ggmap")
library("ggplot2")
#g <- qmap("San Francisco", zoom = 12)  
g +  geom_point(data=ndat[ndat$preds>0.05,], 
        aes(x = X, y = Y, alpha = preds, size = preds)) +
    geom_point(aes(y= 37.775271, x = -122.398685, color = "red", size=8)) +
    annotate("text", label = "BayesImpact\nHackSite", 
        y= 37.775271 - .005, x = -122.398685 + .02,
        colour = "red") +
    ggtitle("Predicted Intoxication Reports\n(Poisson GBRT)") + 
    theme_bw() 
ggsave("bla.pdf")



sfnodes <- read.csv("~/Documents/workspace/out-for-justice/data/sf_points.csv")
ep <- function(x) eval(parse(text = x))


sfnodesdt <- cbind(sfnodes[rep(1:nrow(sfnodes), 
            each=length(levels(dat$daytime))),], 
    daytime = levels(dat$daytime))

sfnodesdt <- cbind(sfnodesdt[rep(1:nrow(sfnodesdt), 
            each=length(levels(dat$superday))),], 
    superday = levels(dat$superday))

head(sfnodesdt)
names(sfnodesdt)[2:3] <- c("Y", "X")

# VIOLENT CRIMES
sfnodesdt$preds <- predict(m1, 
    newdata = sfnodesdt,
    n.trees = 7620,
    type = "response")

write.csv(sfnodesdt, "data/sfnodesdtVIOLENTCRIME.csv", row.names = FALSE)


g + geom_point(data=sfnodesdt[sfnodesdt$preds>0.25 & 
                sfnodesdt$superday %in% c("Saturday") & 
                sfnodesdt$daytime %in% c("6PM-2AM"),], 
        aes(x = X, y = Y, alpha = preds/4, size = preds/10, col = "black")) +
    ggtitle("Predicted Violent Crimes\n(Poisson GBRT)") + 
    theme_bw() + theme(legend.position="none")
ggsave("ViolentCrimesForecastNow.pdf")

levels(sfnodesdt$daytime)
sfnodesdt$daytime <- factor(sfnodesdt$daytime, 
    levels = c("6PM-2AM", "2AM-10AM", "10AM-6PM"))

g + geom_point(data=sfnodesdt[sfnodesdt$preds>0.15 & 
                sfnodesdt$superday %in% c("Saturday"),], 
        aes(x = X, y = Y, alpha = preds, size = preds/5)) +
    facet_grid(.~daytime) + 
#    geom_point(aes(y= 37.775271, x = -122.398685, color = "red", size=8)) +
#    annotate("text", label = "BayesImpact\nHackSite", 
#        y= 37.775271 - .005, x = -122.398685 + .02,
#        colour = "red") +
    ggtitle("Predicted Violent Crimes\n(Poisson GBRT)") + 
    theme_bw() + theme(legend.position="none")
    
ggsave("ViolentCrimesSaturdaybyDaytime.pdf")


sfnodesdt$superday <- factor(sfnodesdt$superday, 
    levels = c("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"))
g + geom_point(data=sfnodesdt[sfnodesdt$preds>0.15 & 
                sfnodesdt$superday %in% c("Saturday", "Sunday") & 
                sfnodesdt$daytime %in% c("6PM-2AM"),], 
        aes(x = X, y = Y, alpha = preds, size = preds/5)) +
    facet_grid(.~superday) + 
#    geom_point(aes(y= 37.775271, x = -122.398685, color = "red", size=8)) +
#    annotate("text", label = "BayesImpact\nHackSite", 
#        y= 37.775271 - .005, x = -122.398685 + .02,
#        colour = "red") +
    ggtitle("Predicted Violent Crimes\n(Poisson GBRT)") + 
    theme_bw() + theme(legend.position="none")
    
ggsave("ViolentCrimes6PM-2AMbyDay.pdf")

# PROPERTY CRIMES
sfnodesdt$preds <- predict(m2, 
    newdata = sfnodesdt,
    n.trees = 7620,
    type = "response")

write.csv(sfnodesdt, "data/sfnodesdtPROPERTYCRIME.csv", row.names = FALSE)


# INTOXICATION CRIMES
sfnodesdt$preds <- predict(m2, 
    newdata = sfnodesdt,
    n.trees = 7620,
    type = "response")

write.csv(sfnodesdt, "data/sfnodesdtINTOXICATIONCRIME.csv", row.names = FALSE)



