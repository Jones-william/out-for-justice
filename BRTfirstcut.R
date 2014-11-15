# TODO: Add comment
# 
# Author: solomon
###############################################################################


library("dplyr")
setwd("~/Documents/workspace/BayesImpact/")
#dat <- read.csv("data/SFPD_Incidents_-_Previous_Three_Months.csv")
#dat <- read.csv("data/sfpd_service_calls.csv")

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

tiledat <- expand.grid(
    Xcut = levels(dat$Xcut),
    Ycut = levels(dat$Ycut)) 

# Now summarize, counting crimes:
ALL_CRIMESs <- dat %>% 
    filter(crimetype != "DROP") %>%
    group_by(Xcut, Ycut, crimetype, daytime, superday) %>% 
    summarise(sum_crime = n()
    )

tiled_ALL_CRIMESs <- left_join(tiledat, ALL_CRIMESs)

#tiled_ALL_CRIMESs$sum_crime_q <- ecdf(tiled_ALL_CRIMESs$sum_crime)(tiled_ALL_CRIMESs$sum_crime)
tiled_ALL_CRIMESs$X <- cut_to_mean(tiled_ALL_CRIMESs$Xcut)
tiled_ALL_CRIMESs$Y <- cut_to_mean(tiled_ALL_CRIMESs$Ycut)

####################################
# Now fit GBRTs
library('dismo')

# Set missing values to zero
tiled_ALL_CRIMESs$sum_crime[is.na(tiled_ALL_CRIMESs$sum_crime)] <- 0
tiled_ALL_CRIMESs$crimetype = as.factor(tiled_ALL_CRIMESs$crimetype)
tiled_ALL_CRIMESs$daytime = as.factor(tiled_ALL_CRIMESs$daytime)
tiled_ALL_CRIMESs$superday = as.factor(tiled_ALL_CRIMESs$superday)

m1 <- gbm.step(
    data=tiled_ALL_CRIMESs, 
    gbm.x = c(3:5, 7:8),
    gbm.y = 6,
    family = "poisson", 
    n.folds = 5,
    n.trees = 20,
    tree.complexity = 2,
    bag.fraction = 0.75)




#ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
#    Y = cut_to_mean(levels(dat$Ycut)), 
#    crimetype = "VIOLENT",
#    daytime = levels(tiled_ALL_CRIMESs$daytime),
#    superday = levels(tiled_ALL_CRIMESs$superday))
ndat <- expand.grid(X = cut_to_mean(levels(dat$Xcut)), 
    Y = cut_to_mean(levels(dat$Ycut)), 
    crimetype = "VIOLENT",
    daytime = "2AM-10AM",
    superday = "Saturday")
ndat$preds <- predict(m1, 
    newdata = ndat,
    n.trees = 2060,
    type = "response")
ndat$preds <- preds

summary(ndat$preds)

#gbm.plot.fits(m1)
#length(m1$fitted)
#m1$cv.statistics


###########################
## Now plot results

#install.packages("ggmap")
library("ggmap")
library("ggplot2")
g <- qmap("San Francisco", zoom = 12)  
g +  geom_point(data=ndat[ndat$preds>2,], 
        aes(x = X, y = Y, alpha = preds)) + 
    theme_bw() 
ggsave("bla.pdf")




