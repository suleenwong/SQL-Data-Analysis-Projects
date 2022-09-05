/*
Queries used for Tableau Project
*/



-- 1. 

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) AS total_deaths, 
	SUM(new_deaths::numeric)/SUM(new_cases)*100 as DeathPercentage
FROM deaths
WHERE continent IS NOT NULL
--Group By date
ORDER BY 1,2

-- Just a double check based off the data provided
-- -- numbers are extremely close so we will keep them - The Second includes "International"  Location

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
FROM deaths
--Where location like '%states%'
WHERE location = 'World'
--Group By date
order by 1,2


-- -- 2. 

-- -- We take these out as they are not inluded in the above queries and want to stay consistent
-- -- European Union is part of Europe

Select location, SUM(new_deaths) as TotalDeathCount
From deaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
AND location NOT LIKE '%income'
Group by location
order by TotalDeathCount desc


-- 3.
SELECT location, population, COALESCE(MAX(total_cases),0) as HighestInfectionCount,  
	COALESCE((MAX(total_cases)/population::numeric)*100,0) as PercentPopulationInfected
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- 4.
SELECT location, population, date, COALESCE(MAX(total_cases),0) as HighestInfectionCount,  
COALESCE((MAX(total_cases)/population::numeric)*100,0) as PercentPopulationInfected
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC


