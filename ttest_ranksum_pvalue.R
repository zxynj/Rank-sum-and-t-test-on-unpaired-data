library(coin)
library(car)
library(xlsx)

data = read.xlsx("R Input.xlsx",sheetName="Sheet1")
attach(data)

Cap.Payment.Indicator=factor(Cap.Payment.Indicator)
PCP.Name=as.character(PCP.Name)

npi_list=matrix(rep(0, length(unique(NPI))))
pcp_name_list=matrix(rep("0", length(unique(NPI))))
avg_qualified_member_in_4_months=matrix(rep(0, length(unique(NPI))))

dili_neq_var_t_test_pvalue=matrix(rep(0, length(unique(NPI))))
dili_eq_var_t_test_pvalue=matrix(rep(0, length(unique(NPI))))
dili_lev_test_pvalue=matrix(rep(0, length(unique(NPI))))
dili_ranksum_test_pvalue=matrix(rep(0, length(unique(NPI))))

cov_neq_var_t_test_pvalue=matrix(rep(0, length(unique(NPI))))
cov_eq_var_t_test_pvalue=matrix(rep(0, length(unique(NPI))))
cov_lev_test_pvalue=matrix(rep(0, length(unique(NPI))))
cov_ranksum_test_pvalue=matrix(rep(0, length(unique(NPI))))

a=1
for (i in unique(NPI)){
  print(i)
  pcp_name_list[a]=PCP.Name[NPI==i][1]
  npi_list[a]=i
  avg_qualified_member_in_4_months[a]=mean(Unique.Patient.in.4.Months[NPI==i])
  
  dili_neq_var_t_test=t.test(Diligence.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i], alt="greater", var.eq=FALSE, paired=F)
  dili_eq_var_t_test=t.test(Diligence.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i], alt="greater", var.eq=TRUE, paired=F)
  dili_lev_test=leveneTest(Diligence.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i],options(warn=1))
  dili_neq_var_t_test_pvalue[a]=dili_neq_var_t_test$p.value
  dili_eq_var_t_test_pvalue[a]=dili_eq_var_t_test$p.value
  dili_lev_test_pvalue[a]=dili_lev_test$`Pr(>F)`[1]
  dili_ranksum_test=wilcox_test(Diligence.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i],alt="greater",paired = FALSE,options(warn=1))
  dili_ranksum_test_pvalue[a]=pvalue(dili_ranksum_test)
  
  cov_neq_var_t_test=t.test(Coverage.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i], alt="greater", var.eq=FALSE, paired=F)
  cov_eq_var_t_test=t.test(Coverage.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i], alt="greater", var.eq=TRUE, paired=F)
  cov_lev_test=leveneTest(Coverage.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i],options(warn=1))
  cov_neq_var_t_test_pvalue[a]=cov_neq_var_t_test$p.value
  cov_eq_var_t_test_pvalue[a]=cov_eq_var_t_test$p.value
  cov_lev_test_pvalue[a]=cov_lev_test$`Pr(>F)`[1]
  cov_ranksum_test=wilcox_test(Coverage.Seasonality.Removed[NPI==i]~Cap.Payment.Indicator[NPI==i],alt="greater",paired = FALSE,options(warn=1))
  cov_ranksum_test_pvalue[a]=pvalue(cov_ranksum_test)
  
  a=a+1
}

pvalue_result=cbind.data.frame(pcp_name_list,npi_list,avg_qualified_member_in_4_months,dili_neq_var_t_test_pvalue,dili_eq_var_t_test_pvalue,dili_lev_test_pvalue,dili_ranksum_test_pvalue,cov_neq_var_t_test_pvalue,cov_eq_var_t_test_pvalue,cov_lev_test_pvalue,cov_ranksum_test_pvalue)

write.xlsx(pvalue_result, "pvalue_result.xlsx")



