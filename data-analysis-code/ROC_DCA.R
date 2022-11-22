
rm(list = ls())#��ջ�������
setwd("C:/Users/21332/Desktop/ALTN")

library(ggplot2);
library(Hmisc);
library(MASS)
library(rms);
library(generalhoslem);
library(pROC)
library(grid); 
library(lattice);
library(Formula);
library(ResourceSelection)
library(readxl)

data<-read_excel("C:/Users/21332/Desktop/ALTN/ce_train.xlsx", sheet=1,col_names = TRUE)
data$name=NULL
attach(data)

#�鿴���ݲ�����ģ��

head(data)
mod <- glm(grade~RAD+gender+age+smoke+ECOG+meta+meta_brain+meta_liver+meta_bone+pathologic+treatment_line+best_response
          , data = data, family=binomial())
summary(mod)

#ΪŵĪͼ�����ض��Ļ���
dd=datadist(data)
options(datadist="dd") 
ddist <- datadist(data)
options(datadist='ddist')
# generalhoslem



#1.����ģ��
logistic.lrm <- lrm(grade~RAD+age+smoke+best_response, data = data)
summary(logistic.lrm )



#2. Nomogram
nom.full <- nomogram(logistic.lrm, fun=plogis,lp=F, funlabel="Likelihood of SF (%)")
plot(nom.full)

#��ѧģ�ͣ�ѵ�������ⲿ��֤��
rm(list = ls())#��ջ�������
train<-read_excel("C:/Users/21332/Desktop/ALTN/ce_train.xlsx", sheet=1,col_names = TRUE)
#train$grade<-as.factor(train$grade)#grade�������������
test<-read_excel("C:/Users/21332/Desktop/ALTN/ce_test.xlsx", sheet=1,col_names = TRUE)
#test$grade<-as.factor(test$grade)
vadiation<-read_excel("C:/Users/21332/Desktop/ALTN/ce_val.xlsx", sheet=1,col_names = TRUE)
#vadiation$grade<-as.factor(test$grade)
#����ѵ��������ģ�Ͳ�Ԥ��

mod1 <- glm(grade~RAD, data = train, 
            family=binomial())
#summary(mod1)
predict1 <- predict(mod1,train,type = c("response"))
predict2 <- predict(mod1,test,type = c("response"))
predict3 <- predict(mod1,vadiation,type = c("response"))
#���logistic���ݱ���
#write.csv(predict1,'predict1.csv')
print(predict3)
#write.csv(predict2,'predict2.csv')


#����AUCֵ
roccurve1 <- roc(mod1$y ~ predict1)
auc(roccurve1)
roccurve2 <- roc(test$grade ~ predict2)
auc(roccurve2)
roccurve3 <- roc(vadiation$grade~ predict3)
auc(roccurve3)

#����ROC���ߣ���95%CI��
thr1.obj <- ci.thresholds(roccurve1)
roc4 <- plot.roc(mod1$y ~ predict1,
     ci=TRUE,print.auc=TRUE,
     print.auc.x=0.4,print.auc.y=0.4,
     auc.polygon=TRUE,
     auc.polygon.col="white",
     print.thres=TRUE,main="NCE-RAD-clinical",col="blue",
     legacy.axes=TRUE)
#grid���Ը�ͼ�����ӱ��ߣ�����Ҫ�Ļ�����ֱ�Ӽ���������
#grid=c(0.5,0.2)   grid.col=c("black","black"),

thr2.obj <- ci.thresholds(roccurve2)
plot.roc(test$grade ~ predict2,add=TRUE,col="red",
         ci=TRUE,print.thres = FALSE,print.auc = TRUE,
         print.auc.x=0.4,print.auc.y = 0.35)

thr3.obj <- ci.thresholds(roccurve3)
plot.roc(vadiation$grade ~ predict3,add=TRUE,col="orange",
         ci=TRUE,print.thres = FALSE,print.auc = TRUE,
         print.auc.x=0.4,print.auc.y = 0.3)
#4.DCA���߻���,�õ��ǹ㷺����ģ��

#install.packages("rmda")
library(rmda)

simple<- decision_curve(grade~RAD+age+smoke+best_response,data= train,
                        #family = binomial(link ='logit'),
                        thresholds= seq(0,1, by = 0.01),
                        confidence.intervals = 0.95,
                        study.design = 'case-control', population.prevalence = 0.7)

complex<- decision_curve(grade~RAD+age+smoke+best_response,data= test,
                         #family = binomial(link ='logit'),
                         thresholds= seq(0,1, by = 0.01),
                         confidence.intervals = 0.95,
                         study.design = 'case-control', population.prevalence = 0.7)

complex1<- decision_curve(grade~RAD+age+smoke+best_response,data= vadiation,
                         #family = binomial(link ='logit'),
                         thresholds= seq(0,1, by = 0.01),
                         confidence.intervals = 0.95,
                         study.design = 'case-control', population.prevalence = 0.7)
#���軭������DCA��List<- list(simple,complex)�����ֻ��һ�����ߣ�ֱ�Ӱ�List�滻��simple��complex���ɡ�#curve.names�ǳ�ͼʱ��ͼ����ÿ�����ߵ����֣���д˳��Ҫ������ϳ�listʱһ�¡�
#cost.benefit.axis�����⸽�ӵ�һ���������ᣬ��ʧ����ȣ�Ĭ��ֵ��TRUE�����ڲ���ҪʱҪ�ǵ���ΪFALSE��col������ɫ��confidence.intervals�����Ƿ񻭳����ߵ��������䣬standardize�����Ƿ�Ծ������ʣ�NB��ʹ�û����ʽ���У������

#ѵ����DCA
plot_decision_curve(simple,curve.names=c('Training set'),
                    cost.benefit.axis =FALSE,col= '#0066CC',
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")
#�ڲ���֤��DCA
plot_decision_curve(complex,curve.names=c('Internal Validation set'),
                    cost.benefit.axis =FALSE,col= '#FF0000',
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")
#�ⲿ��֤��DCA
plot_decision_curve(complex1,curve.names=c('External Validation set'),
                    cost.benefit.axis =FALSE,col= "orange",
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")
#ѵ����+��֤����ͬһ��ͼ��
model_all <- list(simple,complex,complex1)
plot_decision_curve(model_all,curve.names=c('Training set','Internal Training set','External Validation set'),
                    cost.benefit.axis =FALSE,col=c("blue","red","orange"),
                    confidence.intervals=FALSE,
                    standardize = FALSE,
                    xlab="Threshold probability")

#ModEvA��ʹ��
library(modEvA)
plotGLM(model = mod1)
AUC(model = mod1)
THRE1<-threshMeasures(model = mod1, thresh = 0.5,col= '#FF0000')
THREP<-threshMeasures(model = mod1, thresh = "preval",col= '#FF0000')
optiT<-optiThresh(model = mod1, measures = c("CCR", "Sensitivity", "kappa", "TSS"), 
                  ylim = c(0, 1))
OPTI<-optiPair(model = mod1, measures = c("Sensitivity", "Specificity"))
