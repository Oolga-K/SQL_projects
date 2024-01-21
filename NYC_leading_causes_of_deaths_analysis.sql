
/* 		Questions we aim to answer in this analysis:
1. In which year were the most deaths recorded, and in which year the least?
2. What is the trend in the number of deaths in NYC in recent years?
3. What is the most common cause of death?
4. What was the most common cause of death in the year with the highest number of deaths?
5. Women vs. men - which group recorded more deaths?
6. Which ethnic group had the highest percentage of registered deaths?
7. Differences in the number of registered deaths considering ethnic and gender affiliations.
*/

-- I am checking whether we have the same number of causes of death each year.
select date_year, count(distinct `leading cause`) as num_cause
from nyc_death_causes
group by 1
Order by date_year;
-- The dataset covers the years 2007 to 2014. The registered causes of death remain at a relatively constant level.

-- How did the number of deaths evolve in each year? Change in percentage terms.
SELECT date_year, deaths_year, (deaths_year-prev_year_deaths)/prev_year_deaths*100 as prct_diff_vs_previous_year
FROM (SELECT date_year, 
		deaths_year,
        lag(date_year) OVER (order by date_year) as prev_year,
        lag(deaths_year) OVER (order by date_year) as prev_year_deaths
FROM (SELECT date_year, 
		SUM(deaths) as deaths_year
FROM nyc_death_causes
GROUP BY 1) a) aa;
-- The highest number of deaths was recorded in 2008, and the lowest in 2012. The most significant relative change was observed in the years 2008/2009 - a decrease in the number of deaths by over 2%.

-- TOP 5 deaths causes in each year.
SELECT date_year, `leading cause`, deaths_per_year
FROM (SELECT date_year,`Leading Cause`, sum(deaths) as deaths_per_year, row_number() OVER(partition by date_year ORDER BY date_year, sum(deaths) desc) as rn
FROM nyc_death_causes
GROUP BY 1, 2) a
WHERE rn <=5;
-- If we exclude the category 'All other causes' each year, the top 3 will consistently be Diseases of Heart, Malignant Neoplasms, and Influenza and Pneumonia.

-- The percentage distribution of causes of death in the year 2008.
SELECT date_year, `Leading Cause`, num_deaths, 
	sum(num_deaths) OVER() as total_deaths,
    num_deaths*100/sum(num_deaths) OVER() as prct_of_total
FROM (SELECT date_year,`Leading Cause`, sum(deaths) as num_deaths
FROM nyc_death_causes
Where date_year = '2008-01-01'
GROUP BY 1, 2
ORDER BY num_deaths desc) a;
-- The leading cause of death was Heart Diseases, accounting for almost 40%, followed by cancer-related illnesses at nearly 25%.

-- The number of deaths for women and men in each year - presented as a percentage of the total for that year.
SELECT date_year, 
		female_deaths/(female_deaths+male_deaths)*100 as prct_of_female_deaths,
		male_deaths/(female_deaths+male_deaths)*100 as prct_of_male_deaths
FROM (SELECT date_year, 
		SUM(CASE WHEN sex = 'F' THEN deaths END) as female_deaths,
		SUM(CASE WHEN sex = 'M' THEN deaths END) as male_deaths
FROM nyc_death_causes
        GROUP BY 1
		ORDER by date_year) a;
-- Throughout the studied period, there were more deaths among women, though the differences are small.

-- What's was the aforementioned difference?
SELECT date_year, female_deaths, male_deaths, female_deaths-male_deaths as diff
FROM (SELECT date_year, 
		SUM(CASE WHEN sex = 'F' THEN deaths END) as female_deaths,
		SUM(CASE WHEN sex = 'M' THEN deaths END) as male_deaths
FROM nyc_death_causes
        GROUP BY 1
		ORDER by date_year) a;
-- The highest difference was recorded in 2008. Since 2011, the gap between the indicated groups has been decreasing.

-- The average for all years.
SELECT AVG(diff)
FROM (SELECT date_year, female_deaths, male_deaths, female_deaths-male_deaths as diff
FROM (SELECT date_year, 
		SUM(CASE WHEN sex = 'F' THEN deaths END) as female_deaths,
		SUM(CASE WHEN sex = 'M' THEN deaths END) as male_deaths
FROM nyc_death_causes
        GROUP BY 1
		ORDER by date_year) a)aa;

-- The percentage distribution of registered deaths based on ethnic affiliation.
SELECT a.date_year, 
		ROUND(black_non_hispanic_deaths/total_deaths*100,2) as black_non_hispanic_deaths,
		ROUND(hispanic_deaths/total_deaths*100,2) as hispanic_deaths,
		ROUND(asian_pacific_deaths/total_deaths*100,2) as asian_pacific_deaths,
		ROUND(white_non_hispanic_deaths/total_deaths*100,2) as white_non_hispanic_deaths
FROM (SELECT date_year, 
		SUM(CASE WHEN `race ethnicity` = 'Black Non-Hispanic' THEN deaths END) as black_non_hispanic_deaths,
		SUM(CASE WHEN `race ethnicity` = 'Hispanic' THEN deaths END) as hispanic_deaths,
		SUM(CASE WHEN `race ethnicity` = 'Asian and Pacific Islander' THEN deaths END) as asian_pacific_deaths,
		SUM(CASE WHEN `race ethnicity` = 'White Non-Hispanic' THEN deaths END) as white_non_hispanic_deaths
FROM nyc_death_causes
        GROUP BY 1
		ORDER by date_year) a
        JOIN (SELECT date_year, SUM(deaths) as total_deaths FROM nyc_death_causes GROUP BY 1) b
        ON a.date_year=b.date_year
        ;
-- The highest number of deaths were recorded among the White Non-Hispanic group, which is, of course, closely related to the predominant share of this group in the overall population residing in New York.

-- Female vs Male in each ethnic group.
SELECT date_year, `race ethnicity`,
		ROUND(female_deaths*100/(female_deaths+male_deaths),2) as prct_female_deaths,
		ROUND(male_deaths*100/(female_deaths+male_deaths),2) as prct_female_deaths
FROM (SELECT date_year, `race ethnicity`, 
		SUM(CASE WHEN sex = 'F' THEN deaths END) as female_deaths,
		SUM(CASE WHEN sex = 'M' THEN deaths END) as male_deaths
FROM nyc_death_causes
GROUP BY 1,2
ORDER by 2, 1) a;
-- The predominance of female deaths is not registered in all ethnic groups. These proportions are observed in the White Non-Hispanic and Black Non-Hispanic groups. The other two ethnic groups show a predominance of male deaths.

/*	 1. In which year were the most deaths recorded, and in which year the least?
The highest was in 2008, and the lowest was in 2012.
	2. What is the trend in the number of deaths in NYC in recent years?
There is no stable trend; changes oscillated between -2.3% and +1% in the examined years.
	3. What is the most common cause of death?
The most common cause of death is heart disease.
	4. What was the most common cause of death in the year with the highest number of deaths?
It was the year 2008, and the most common cause of death was heart disease (40%).
	5. Women vs men - which group recorded more deaths?
More female deaths were registered, averaging 1247 more deaths per year. The difference in deaths between women and men has been decreasing since 2011.
	6. Which ethnic group had the highest percentage of registered deaths?
The highest number of deaths was observed among the White Non-Hispanic group, which is naturally related to the predominant share of this group in the overall population residing in New York.
	7. Differences in the number of registered deaths considering ethnic and gender affiliations.
The predominance of female deaths is not recorded in all ethnic groups. These proportions are maintained in the White Non-Hispanic and Black Non-Hispanic groups. The other two ethnic groups (Asian and Pacific Islander, Hispanic) show a predominance of male deaths.
*/

