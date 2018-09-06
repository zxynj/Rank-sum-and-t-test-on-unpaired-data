----part 1. extract qualified member visit from XXXX claims
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#qualified_member') IS NOT NULL DROP TABLE #qualified_member
IF OBJECT_ID('tempdb..#selected_exposure') IS NOT NULL DROP TABLE #selected_exposure
IF OBJECT_ID('tempdb..#current_month_visit') IS NOT NULL DROP TABLE #current_month_visit
IF OBJECT_ID('tempdb..#4month_coverage') IS NOT NULL DROP TABLE #4month_coverage
IF OBJECT_ID('tempdb..#qualified_member_visit_XXXX') IS NOT NULL DROP TABLE #qualified_member_visit_XXXX
IF OBJECT_ID('tempdb..#pcp_id_name_list') IS NOT NULL DROP TABLE #pcp_id_name_list
IF OBJECT_ID('tempdb..#diligence_coverage_XXXX') IS NOT NULL DROP TABLE #diligence_coverage_XXXX

--create a pcp id list link YYYY pcp id to XXXX pcp id
CREATE TABLE #pcp_id_name_list(pcp_name NVARCHAR(max),pcp_id_XXXX NVARCHAR(max),pcp_id_YYYY NVARCHAR(max)) 
insert into  #pcp_id_name_list values
	('AW','1568443333','406888')

--create table variable containing month 201210-201801. while loop will iterate over these months
DECLARE @month_table TABLE (ind int, value NVARCHAR(50))
INSERT INTO @month_table
	SELECT DISTINCT ROW_number() OVER (ORDER BY a.value) AS ind, a.value as value FROM (
		SELECT DISTINCT YearMonth as value FROM [PatientPanel].[dbo].[ExcelPanel_History_Formatted] where yearmonth>='201610' and yearmonth<='201801') a order by a.value
DECLARE @i AS INT = 4; -- starting it with 4 since we need 3 month prior data 
DECLARE @max AS INT -- break point for loop 
SELECT @max = max(ind) FROM @month_table -- set break point value 

DECLARE @month AS CHAR(6) -- declaring variable to use as new panel month year 
DECLARE @month_l1 AS CHAR(6)
DECLARE @month_l2 AS CHAR(6)
DECLARE @month_l3 AS CHAR(6)
DECLARE @qualified_member_visit TABLE (npi NVARCHAR(max), [month] NVARCHAR(6), qualified_member_count float, visit_count float, coverage_count float)

WHILE @i <= @max -- Loop Begins 
BEGIN
	SELECT @month = value FROM @month_table WHERE ind = @i
	SELECT @month_l1 = value FROM @month_table WHERE ind = @i-1
	SELECT @month_l2 = value FROM @month_table WHERE ind = @i-2
	SELECT @month_l3 = value FROM @month_table WHERE ind = @i-3
		
	--find qualified member:members who are with the doctor for at least 4 months
	select a.cur_pcp_npi, a.memberid into #qualified_member from
	(select distinct cur_pcp_npi, memberid from [PatientPanel].[dbo].[ExcelPanel_History_Formatted] where yearmonth=@month and hpcode='bcmc') a
	inner join
	(select cur_pcp_npi, memberid from [PatientPanel].[dbo].[ExcelPanel_History_Formatted] where yearmonth in (@month,@month_l1,@month_l2,@month_l3) and hpcode='bcmc' group by cur_pcp_npi, memberid having count(memberid)>=4) b
	on a.cur_pcp_npi=b.cur_pcp_npi and a.memberid=b.memberid

	--calculate total qualified member per pcp
	select cur_pcp_npi, count(memberid) as qualified_member_count into #selected_exposure from #qualified_member group by cur_pcp_npi

	--calculate total visit in current month
	select b.cur_pcp_npi, count(distinct(cfr_cmid)) as visit_count into #current_month_visit from
	(select distinct cfr_cmid, cfr_mmid, cfr_pos, CFR_PVID from claims..ExcelClaims_Formatted where cfr_lob = 'bcmc' and cfr_mos=@month) a
	inner join
	#qualified_member b
	on a.cfr_mmid=b.memberid
	where cfr_pos = '11' AND a.CFR_PVID = b.cur_pcp_npi
	group by b.cur_pcp_npi

	--calculate total coverged member for the 4 months
	select b.cur_pcp_npi, count(distinct(memberid)) as coverage_count into #4month_coverage from
	(select distinct cfr_mmid, cfr_pos, CFR_PVID from claims..ExcelClaims_Formatted where cfr_lob = 'bcmc' and cfr_mos>=@month_l3 and cfr_mos<=@month) a
	inner join
	#qualified_member b
	on a.cfr_mmid=b.memberid
	where cfr_pos = '11' AND a.CFR_PVID = b.cur_pcp_npi
	group by b.cur_pcp_npi

	--join all 3 tables
	insert into @qualified_member_visit
		select a.cur_pcp_npi, @month, a.qualified_member_count, ISNULL(b.visit_count, 0) as visit_count, ISNULL(c.coverage_count, 0) as coverage_count from (
			#selected_exposure a
			full outer join
			#current_month_visit b
			on a.cur_pcp_npi=b.cur_pcp_npi
			full outer join
			#4month_coverage c
			on a.cur_pcp_npi=c.cur_pcp_npi) 
	
	IF OBJECT_ID('tempdb..#qualified_member') IS NOT NULL DROP TABLE #qualified_member
	IF OBJECT_ID('tempdb..#selected_exposure') IS NOT NULL DROP TABLE #selected_exposure
	IF OBJECT_ID('tempdb..#current_month_visit') IS NOT NULL DROP TABLE #current_month_visit
	IF OBJECT_ID('tempdb..#4month_coverage') IS NOT NULL DROP TABLE #4month_coverage

	SET @i = @i + 1 -- increment in variable for the loop 
END -- Loop ends 

select * from @qualified_member_visit


select b.pcp_name as [PCP Name], a.npi as NPI, a.[month] as [Month], a.qualified_member_count as [Unique Patient in 4 Months], a.visit_count as [Total Visits in Current Month], a.coverage_count as [Unique Patients Covered in 4 Months] into #qualified_member_visit_XXXX from
@qualified_member_visit a
left join
#pcp_id_name_list b
on a.npi=b.pcp_id_XXXX 

select [PCP Name], [NPI], [Month] as [Year Month], right([Month],2) as [Month], [Unique Patient in 4 Months], [Total Visits in Current Month]/[Unique Patient in 4 Months] as Diligence,[Unique Patients Covered in 4 Months]/[Unique Patient in 4 Months] as Coverage
	into #diligence_coverage_XXXX from #qualified_member_visit_XXXX order by [pcp name],[month]
go

----part 2. extract qualified member visit from YYYY claims
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#qualified_member') IS NOT NULL DROP TABLE #qualified_member
IF OBJECT_ID('tempdb..#selected_exposure') IS NOT NULL DROP TABLE #selected_exposure
IF OBJECT_ID('tempdb..#current_month_visit') IS NOT NULL DROP TABLE #current_month_visit
IF OBJECT_ID('tempdb..#4month_coverage') IS NOT NULL DROP TABLE #4month_coverage
IF OBJECT_ID('tempdb..#qualified_member_visit_YYYY') IS NOT NULL DROP TABLE #qualified_member_visit_YYYY
IF OBJECT_ID('tempdb..#diligence_coverage_YYYY') IS NOT NULL DROP TABLE #diligence_coverage_YYYY

--create table variable containing month 201210-201801. while loop will iterate over these months
DECLARE @month_table TABLE (ind int, value NVARCHAR(50))
INSERT INTO @month_table
	SELECT DISTINCT ROW_number() OVER (ORDER BY a.value) AS ind, a.value as value FROM (
		SELECT DISTINCT left(replace(cast(paneldate as varchar(255)),'-',''),6) as value FROM PatientPanel.[dbo].[YYYYRaw] where paneldate>='2013-01-01' and paneldate<='2016-07-01') a order by a.value

DECLARE @i AS INT = 4; -- starting it with 4 since we need 3 month prior data 
DECLARE @max AS INT -- break point for loop 
SELECT @max = max(ind) FROM @month_table -- set break point value 

DECLARE @month AS CHAR(6) -- declaring variable to use as new panel month year 
DECLARE @month_l1 AS CHAR(6)
DECLARE @month_l2 AS CHAR(6)
DECLARE @month_l3 AS CHAR(6)
DECLARE @qualified_member_visit TABLE (pcp_id_YYYY NVARCHAR(max), [month] NVARCHAR(6), qualified_member_count float, visit_count float, coverage_count float)

WHILE @i <= @max -- Loop Begins 
BEGIN
	SELECT @month = value FROM @month_table WHERE ind = @i
	SELECT @month_l1 = value FROM @month_table WHERE ind = @i-1
	SELECT @month_l2 = value FROM @month_table WHERE ind = @i-2
	SELECT @month_l3 = value FROM @month_table WHERE ind = @i-3
		
	--find qualified member:members who are with the doctor for at least 4 months
	select b.cur_pcp, b.member_id as memberid into #qualified_member from
	(select pcp_id_YYYY from #pcp_id_name_list) a
	inner join
	(select distinct cur_pcp, member_id from PatientPanel.[dbo].[YYYYRaw] where left(replace(cast(paneldate as varchar(255)),'-',''),6)=@month and lob in ('250','251','253')) b
	on a.pcp_id_YYYY=b.cur_pcp
	inner join
	(select cur_pcp, member_id from PatientPanel.[dbo].[YYYYRaw] where left(replace(cast(paneldate as varchar(255)),'-',''),6) in (@month,@month_l1,@month_l2,@month_l3) and lob in ('250','251','253') group by cur_pcp, member_id having count(member_id)>=4) c
	on a.pcp_id_YYYY=c.cur_pcp and b.member_id=c.member_id

	--calculate total qualified member per pcp
	select cur_pcp, count(memberid) as qualified_member_count into #selected_exposure from #qualified_member group by cur_pcp

	--calculate total visit in current month
	select b.cur_pcp, count(distinct(cfr_cmid)) as visit_count into #current_month_visit from
	
	(select distinct cfr_cmid, cfr_mmid, cfr_pos, CFR_PVID from claims.[dbo].[YYYYClaims] where cfr_lob in ('250','251','253') and cfr_mos=@month and cfr_cmid not like 'r%') a
	inner join
	#qualified_member b
	on a.cfr_mmid=b.memberid
	where cfr_pos = '11' AND a.CFR_PVID = b.cur_pcp
	group by b.cur_pcp

	--calculate total coverged member for the 4 months
	select b.cur_pcp, count(distinct(memberid)) as coverage_count into #4month_coverage from
	(select distinct cfr_mmid, cfr_pos, CFR_PVID from claims.[dbo].[YYYYClaims] where cfr_lob in ('250','251','253') and cfr_mos>=@month_l3 and cfr_mos<=@month) a
	inner join
	#qualified_member b
	on a.cfr_mmid=b.memberid
	where cfr_pos = '11' AND a.CFR_PVID = b.cur_pcp
	group by b.cur_pcp

	--join all 3 tables
	insert into @qualified_member_visit
		select a.cur_pcp, @month, a.qualified_member_count, ISNULL(b.visit_count, 0) as visit_count, ISNULL(c.coverage_count, 0) as coverage_count from (
			#selected_exposure a
			full outer join
			#current_month_visit b
			on a.cur_pcp=b.cur_pcp
			full outer join
			#4month_coverage c
			on a.cur_pcp=c.cur_pcp)
	
	IF OBJECT_ID('tempdb..#qualified_member') IS NOT NULL DROP TABLE #qualified_member
	IF OBJECT_ID('tempdb..#selected_exposure') IS NOT NULL DROP TABLE #selected_exposure
	IF OBJECT_ID('tempdb..#current_month_visit') IS NOT NULL DROP TABLE #current_month_visit
	IF OBJECT_ID('tempdb..#4month_coverage') IS NOT NULL DROP TABLE #4month_coverage

	SET @i = @i + 1 -- increment in variable for the loop 
END -- Loop ends 

select b.pcp_name as [PCP Name], b.pcp_id_XXXX as NPI, a.[month] as [Month], a.qualified_member_count as [Unique Patient in 4 Months], a.visit_count as [Total Visits in Current Month], a.coverage_count as [Unique Patients Covered in 4 Months] into #qualified_member_visit_YYYY from
@qualified_member_visit a
left join
#pcp_id_name_list b
on a.pcp_id_YYYY=b.pcp_id_YYYY

select [PCP Name], [NPI], [Month] as [Year Month], right([Month],2) as [Month], [Total Visits in Current Month]/[Unique Patient in 4 Months] as Diligence, [Unique Patients Covered in 4 Months]/[Unique Patient in 4 Months] as Coverage
	into #diligence_coverage_YYYY from #qualified_member_visit_YYYY order by [pcp name],[month]
go

----part 3. remove seaonality from XXXX diligence and coverage
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#qualified_member_visit_seasonality_removed_XXXX') IS NOT NULL DROP TABLE #qualified_member_visit_seasonality_removed_XXXX

select a.[PCP Name], a.NPI, a.[Year Month], a.[Month], a.[Unique Patient in 4 Months], a.Diligence, a.Coverage, b.average_diligence as [Diligence Seasonality], b.average_coverage as [Coverage Seasonality], a.Diligence-a.Diligence as [Diligence Seasonality Removed], a.Coverage-a.Coverage as [Coverage Seasonality Removed] into #qualified_member_visit_seasonality_removed_XXXX from
	#diligence_coverage_XXXX a
	left join
	(select npi, [month], avg(diligence) as average_diligence, avg(coverage) as average_coverage from #diligence_coverage_YYYY group by npi, [month]) b
	on a.npi=b.npi and a.[month]=b.[month]

--replace null diligence seasonality with average seasonality
update #qualified_member_visit_seasonality_removed_XXXX
	set #qualified_member_visit_seasonality_removed_XXXX.[Diligence Seasonality]=b.average_diligence
	from (select [month], avg(diligence) as average_diligence, avg(coverage) as average_coverage from #diligence_coverage_YYYY group by [month]) b
	where #qualified_member_visit_seasonality_removed_XXXX.[Diligence Seasonality] is null and #qualified_member_visit_seasonality_removed_XXXX.[Month]=b.[month]

--replace null coverage seasonality with average seasonality
update #qualified_member_visit_seasonality_removed_XXXX
	set #qualified_member_visit_seasonality_removed_XXXX.[Coverage Seasonality]=b.average_coverage
	from (select [month], avg(diligence) as average_diligence, avg(coverage) as average_coverage from #diligence_coverage_YYYY group by [month]) b
	where #qualified_member_visit_seasonality_removed_XXXX.[Coverage Seasonality] is null and #qualified_member_visit_seasonality_removed_XXXX.[Month]=b.[month]

update #qualified_member_visit_seasonality_removed_XXXX set [Diligence Seasonality Removed]=[Diligence]-[Diligence Seasonality]
update #qualified_member_visit_seasonality_removed_XXXX set [Coverage Seasonality Removed]=[Coverage]-[Coverage Seasonality]
go

----part 4. modify for r input
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#r_input') IS NOT NULL DROP TABLE #r_input

select [PCP Name], NPI, [Year Month], [Unique Patient in 4 Months], [Diligence Seasonality Removed], [Coverage Seasonality Removed],
	CASE 
		WHEN [Year Month]<='201709' THEN 0
		ELSE 1 
	END as [Cap Payment Indicator] into #r_input
from #qualified_member_visit_seasonality_removed_XXXX where [Year Month]!='201709'

select c.* from
(select npi from #r_input where [Cap Payment Indicator]=0 group by npi having count(npi)>1) a
inner join
(select npi from #r_input where [Cap Payment Indicator]=1 group by npi having count(npi)>1) b
on a.npi=b.npi
inner join
#r_input c
on a.npi=c.npi
order by [pcp name],[year month]
go


