# Rank-sum-and-t-test-on-unpaired-data

## Objectives:
We would like to study the how the target value changes before and after the treatment.

## Remarks:
The data contains two measures for each doctor before and after the change.

## Methods:
1. I first extract data using SQL. Since the data we have is medical claims data, it has innate seasonality. Therefore, I removed it and named the cleaned up dataset as "R Input.xlsx"

2. Assuming that the data comes from normal dsitribution, I can use t-test on the data. Leven's test of equal variance is used to see if equal variance t-test or not equal variance t-test should be used or not.

3. Since the data might not come from normal distribution. Rank sum test is also performed.

4. Calculate target value change for those have H0 rejected in above tests.

## Improvements:
1. I could try to use Anderson Darling test and Shapiro Wilk test or look at QQ plot to conclude if the data is normal or not
2. Even Leven's test is more robust since it doesn't require normality assumption, F test can still be used here to see if matches Leven's test's result.
