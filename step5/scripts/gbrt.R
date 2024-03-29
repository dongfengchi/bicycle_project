setwd("E:\\project\\bicycle_project\\step5\\scripts")

week_list = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
dat = read.csv("..//data//model_32.csv")

dat$weekday = as.factor(dat$weekday)
dat$sunny   = as.factor(dat$sunny)
dat$windy   = as.factor(dat$windy)

library(dplyr)

tbl_dat = tbl_df(dat)
class(tbl_dat)

res_tbl <-  tbl_dat %>%
  group_by(weekday, hour) %>%
  summarise(total = sum(count))

par(mfrow=c(3,3))
for (i in c(1:6, 0)) {
  plot(res_tbl[res_tbl$weekday == i, ]$hour, res_tbl[res_tbl$weekday == i, ]$total, type='l',
       main = paste("total count of ", week_list[i + 1]), xlab = "hours", ylab = "counts")
}

par(mfrow=c(1,1))
res_tbl_total <- tbl_dat %>%
  group_by(date, hour) %>%
  summarise(total = sum(count))

plot(y = res_tbl_total[res_tbl_total$hour == 7, ]$total, x = as.Date(as.character(res_tbl_total[res_tbl_total$hour == 7, ]$date), "%Y%m%d"), xlab = "day", ylab = "count", type = "l", main = "counts in hour 7")
plot(y = res_tbl_total[res_tbl_total$hour == 8, ]$total, x = as.Date(as.character(res_tbl_total[res_tbl_total$hour == 8, ]$date), "%Y%m%d"), xlab = "day", ylab = "count", type = "l", main = "counts in hour 8")
plot(y = res_tbl_total[res_tbl_total$hour == 9, ]$total, x = as.Date(as.character(res_tbl_total[res_tbl_total$hour == 9, ]$date), "%Y%m%d"), xlab = "day", ylab = "count", type = "l", main = "counts in hour 9")


dat$hour    = as.factor(dat$hour)

library(gbm)
x = model.matrix(count ~ . - date, data = dat)[, -1]
head(x)
dat_ = as.data.frame(cbind(dat$count, x))
head(dat_)
gbm_result = gbm(V1 ~ ., data = dat_, n.trees = 1000, shrinkage = 0.1, 
                 interaction.depth = 9, bag.fraction = 0.5, train.fraction = 0.5, 
                 n.minobsinnode = 10, 
                 cv.folds = 5)
best_iter = gbm.perf(gbm_result, method = "cv")
print(best_iter)
summary(gbm_result, best_iter)
plot.gbm(gbm_result, 4, best_iter)

library(caret)
set.seed(18)
fitControl <- trainControl(method = "cv", number = 10,returnResamp = "all")
model2 <- train(V1 ~ ., data=dat_,method='gbm',distribution='guassian',trControl = fitControl,verbose=F,tuneGrid = expand.grid(n.trees=1000,shrinkage= 0.1, interaction.depth=9,n.minobsinnode = 10))
model2
plot(model2)
plot.gbm(gbm_r, 8, best_iter)


pred = predict(model2, dat_[, -1])
MSE = mean((pred - dat$count) ^ 2)
final_df = data.frame(true = dat$count, pred = pred)
dat$pred = pred

plot(y = dat[(dat$hour %in% c( 8)),]$count,  x = as.Date(as.character(dat[(dat$hour %in% c( 8)),]$date), "%Y%m%d"), type="l", xlab = "date", ylab = "count", col = "red")
lines(y = dat[(dat$hour %in% c( 8)),]$pred,  x = as.Date(as.character(dat[(dat$hour %in% c( 8)),]$date), "%Y%m%d"), type="l", xlab = "date", ylab = "count", col = "blue")
write.table(dat, file = "res.csv", sep = ',', row.names = FALSE, col.names = TRUE)
