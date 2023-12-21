--------------------------- Data Analysis of US Census Data using SQL  ------------------------------------------
--- Here we focus on knowing some of the statistics of the data using MySQL 
-- Some of the topics such as Cases, Rank has been utilised to display the major concerns regarding the US State census.

------------------- Creation of Database ------------------------------------
DROP DATABASE IF EXISTS census;
Create Database census;
------------------- Utlising the Database to Create the Table using python code -----------------
---- Here we are utlising the python tools and libraries to establish a local machine connection to the SQL data base in order to import the data into MySQL Table/schema.
--- This is shown in the 'csv_to_sql.py' file

use census;

------ Changing the table name using ALTER Table command-------------------
ALTER Table acs2017_census_tract_data Rename us_state_census;

---- Display The Records--------------
Select * from us_state_census;

--- Display Total Population of United Statess------

Select sum(TotalPop) as Total_Population  from us_state_census;

------------ Display total number of county -----------------------------
Select  Count(distinct(County)) as County_count
from us_state_census;

------------ Display total number of states in this data------------------------
Select  Count(distinct(State)) as State_count
from us_state_census;

------ Display top 5 states with maximum population-------

Select State,sum(TotalPop) as Total_population 
from us_state_census 
group by State 
order by Total_population Desc 
LIMIT 5; 

------- Display top 5 states which has highest  average selfemployeed rate -----------------

Select State,avg(SelfEmployed) as Average_Self_emp 
from us_state_census 
group by State 
order by Average_Self_emp DESc 
Limit 5;

------------  Display highest average unemployed ratio by states-----------------

Select State,avg(Unemployment) as Average_Unemployement
from us_state_census 
group by State 
order by Average_Unemployement DESc 
Limit 5;

  -------------- Display sex ratio -----------------
SELECT State,
       SUM(Men) AS total_males,
       SUM(Women) AS total_females,
       CASE
           WHEN SUM(Women) > 0 THEN ROUND(SUM(Men) / SUM(Women), 2)
           ELSE NULL -- To Avoid division by zero if there are no women counted
       END AS sex_ratio
FROM us_state_census
GROUP BY State;


------ Creating tables  top states Top 5 average poverty and bottom 5 states with average poverty using union-----------------

  -- Create temporary tables to store the top and bottom poverty states---------
  CREATE  TABLE top_poverty_states AS
  (SELECT State, avg(Poverty) as Average_Poverty
  FROM us_state_census
  Group by State
  ORDER BY Average_Poverty DESC
  LIMIT 5);

  CREATE  TABLE bottom_poverty_states AS
  (SELECT State, avg(Poverty) as Average_Poverty
  FROM us_state_census
  Group by State
  ORDER BY Average_Poverty ASC
  LIMIT 5);

--- Union operator to disply records--------- 
  SELECT * FROM top_poverty_states
  UNION ALL
  SELECT * FROM bottom_poverty_states;
  


-------------------- Display Ethnic Diversity Index by State-----------------
SELECT State,
       (1 - (ABS(SUM(White) / SUM(TotalPop) - 0.2) +
             ABS(SUM(Black) / SUM(TotalPop) - 0.2) +
             ABS(SUM(Native) / SUM(TotalPop) - 0.2) +
             ABS(SUM(Asian) / SUM(TotalPop) - 0.2) +
             ABS(SUM(Pacific) / SUM(TotalPop) - 0.2)
        ) / 5) AS Diversity_Index
FROM us_state_census
GROUP BY State;

----------- Income Disparity by Race in Each County--------------
SELECT 
    County,
    AVG(CASE WHEN White > 50 THEN IncomePerCap ELSE NULL END) AS AvgIncomePerCap_WhiteMajority,
    AVG(CASE WHEN Black > 50 THEN IncomePerCap ELSE NULL END) AS AvgIncomePerCap_BlackMajority,
    AVG(CASE WHEN Hispanic > 50 THEN IncomePerCap ELSE NULL END) AS AvgIncomePerCap_HispanicMajority,
    AVG(CASE WHEN Asian > 50 THEN IncomePerCap ELSE NULL END) AS AvgIncomePerCap_AsianMajority
FROM us_state_census
GROUP BY County;

------------ Correlation of Education Level with Unemployment Rate------------------
WITH CountyStats AS (
    SELECT 
        County,
        AVG((Professional / TotalPop) * 100) AS AvgProfessionalPercent,
        AVG(Unemployment) AS AvgUnemploymentRate
    FROM us_state_census
    GROUP BY County
)
SELECT 
    County,
    AvgProfessionalPercent,
    AvgUnemploymentRate,
    (AvgProfessionalPercent * AvgUnemploymentRate) / 100 AS EducationUnemploymentCorrelation
FROM CountyStats
ORDER BY EducationUnemploymentCorrelation;

---------- Ratio of Public vs. Private Sector Workers by County ------------------

SELECT 
    County,
    SUM(PublicWork) AS TotalPublicWork,
    SUM(PrivateWork) AS TotalPrivateWork,
    (SUM(PublicWork) * 1.0 / SUM(PrivateWork)) AS PublicPrivateRatio
FROM us_state_census
WHERE TotalPop > 0 AND PrivateWork > 0 -- To avoid division by zero
GROUP BY County
ORDER BY PublicPrivateRatio DESC;
--------------------------------------------- - ---------------------------------------------
------ Find the Counties with the Highest and Lowest Ratio of Income to Poverty and Show the Average Commute Time using queries and subqueries --------------
SELECT 
    MainQuery.County,
    MainQuery.AvgIncomePerCapPovertyRatio,
    MainQuery.AvgCommuteTime
FROM (
    SELECT 
        County,
        (AVG(IncomePerCap) / NULLIF(AVG(Poverty), 0)) AS AvgIncomePerCapPovertyRatio,
        AVG(MeanCommute) AS AvgCommuteTime
    FROM us_state_census
    GROUP BY County
) AS MainQuery
JOIN (
    SELECT MAX(AvgIncomePerCapPovertyRatio) AS MaxRatio, MIN(AvgIncomePerCapPovertyRatio) AS MinRatio
    FROM (
        SELECT 
            (AVG(IncomePerCap) / NULLIF(AVG(Poverty), 0)) AS AvgIncomePerCapPovertyRatio
        FROM us_state_census
        GROUP BY County
    ) AS SubQuery
) AS RatioQuery ON MainQuery.AvgIncomePerCapPovertyRatio IN (RatioQuery.MaxRatio, RatioQuery.MinRatio)
ORDER BY MainQuery.AvgIncomePerCapPovertyRatio DESC;

------------ Top 3 Counties by Unemployment Rate Within Each State using rank --------------------------
SELECT RankedCounties.* FROM (
  SELECT
    State,
    County,
    Unemployment,
    RANK() OVER (PARTITION BY State ORDER BY CAST(Unemployment AS DECIMAL(10, 2)) DESC) AS `Rank`
  FROM us_state_census
) AS RankedCounties
WHERE RankedCounties.`Rank` IN (1, 2, 3)
ORDER BY State, RankedCounties.`Rank`;

--------------------------------------------------------  - --------------------------------------------------------------------------------