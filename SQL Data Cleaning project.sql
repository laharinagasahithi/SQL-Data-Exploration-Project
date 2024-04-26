--Data Cleaning

--raw table
select * from job_layoffs;


--creating dublicate table
create table layoffs_staging(
company varchar(50),
location varchar(50),
industry varchar(50),
total_laid_off numeric,
percentage_laid_off decimal,
date_noted varchar(15),
stage varchar(50),
country varchar(50),
funds_raised_millions numeric)

--inserting rows into dublicate table
insert into layoffs_staging
(select * from job_layoffs)

select * from layoffs_staging;

--Finding duplicates 
SELECT COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE_NOTED, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS,
ROW_NUMBER() over(partition by company,location, industry, total_laid_off, percentage_laid_off, date_noted,stage, country, funds_raised_millions
ORDER BY DATE_NOTED) as row_num
from layoffs_staging;


--creating cte
with duplicate_cte as
(
SELECT COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE_NOTED, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS,
ROW_NUMBER() over(partition by company,location, industry, total_laid_off, percentage_laid_off, date_noted, stage, country, funds_raised_millions
ORDER BY DATE_NOTED) as row_num
from layoffs_staging
)
select *
from  duplicate_cte where row_num > 1;

--checking duplicate rows
select * from layoffs_staging where company = 'Casper';


--create another duplicate table
create table layoffs_staging2(
company varchar(50),
location varchar(50),
industry varchar(50),
total_laid_off numeric,
percentage_laid_off decimal,
date_noted varchar(20),
stage varchar(50),
country varchar(50),
funds_raised_millions numeric,
row_num int)

insert into layoffs_staging2
(
SELECT COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE_NOTED, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS,
ROW_NUMBER() over(partition by company,location, industry, total_laid_off, percentage_laid_off, date_noted, stage, country, funds_raised_millions
ORDER BY DATE_NOTED) as row_num
from layoffs_staging
);

select * from layoffs_staging2;

select * from layoffs_staging2
where row_num > 1;

-- delecting dublicate rows
delete from layoffs_staging2 
where row_num >1;


--Standarding table

--formating company
select distinct(trim(company)) from layoffs_staging2;

select company,trim(company) from layoffs_staging2;

update layoffs_staging2
set company = trim(company);


--formating industry
select distinct(industry) from layoffs_staging2 
order by industry;

select * from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';


select distinct(location) from layoffs_staging2
order by location;

--formating country
select distinct(country) from layoffs_staging2
order by country;

select distinct(country), trim(trailing '.' from country)
from layoffs_staging2;

update layoffs_staging2
set country =  trim(trailing '.' from country)
where country like 'United States%';

--formating Date

select date_noted from layoffs_staging2;

ALTER TABLE layoffs_staging2 ADD (new_date DATE);

UPDATE layoffs_staging2 SET new_date=TO_DATE(date_noted,'MM/DD/YYYY'); 
 
select new_date from layoffs_staging2;

update layoffs_staging2 SET
date_noted = new_date;

select * from layoffs_staging2;



-- checking null values
select * from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;


select * from layoffs_staging2
where industry is null or
industry = ' ';

select * from layoffs_staging2
where company ='Airbnb';


select t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
and t1.location = t2.location
where (t1.industry is null or t1.industry = ' ')
and t2.industry is not null;


--update layoffs_staging2 t1 
--join layoffs_staging2 t2
  -- on t1.company = t2.company
--set t1.industry = t2.industry
--where t1.industry is null
--and t2.industry is not null;


--update layoffs_staging t1
--set t1.industry = (select t2.industry from layoffs_staging2 t2 )
--where t2.industry = t1.industry 
--and t2.industry is not null
--and t1.industry is null;


--throws error 
update layoffs_staging2 t1
set t1.industry = (select t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
and t1.location = t2.location
where t1.industry is null
and t2.industry is not null);



UPDATE layoffs_staging2 t1
SET t1.industry = (
    SELECT t2.industry
    FROM layoffs_staging2 t2
    WHERE t1.company = t2.company
)
WHERE exists (
    SELECT 1
    FROM layoffs_staging2 t2
    WHERE t1.company = t2.company
        and t1.industry is null
        and t2.industry is not null
);

MERGE INTO layoffs_staging2 t1
USING (
    SELECT 
        company,
        industry
    FROM 
        layoffs_staging2
) s
ON (t1.company = s.company)
WHEN MATCHED THEN
    UPDATE SET t1.industry = s.industry
    where t1.industry is null
        and t2.industry is not null;

--drop of column is not possible beacuse cannot drop column from table owned by SYS
alter table layoffs_staging2
drop column row_num;