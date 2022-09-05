-- Select data for analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM deaths

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Germany
SELECT location, date, total_cases, total_deaths, 
	   (total_deaths::numeric/total_cases::numeric)*100 AS DeathPercentage
FROM deaths
WHERE location = 'Germany'
ORDER BY date;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, date, population, total_cases, 
	   (total_cases::numeric/population::numeric)*100 AS PercentPopulationInfected
FROM deaths
WHERE location = 'Germany'
ORDER BY date;

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
	   MAX((total_cases::numeric/population::numeric))*100 as PercentPopulationInfected
FROM deaths
WHERE population IS NOT NULL
	AND total_cases IS NOT NULL
	AND continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM deaths
WHERE continent IS NOT NULL
	AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM deaths
WHERE continent IS NULL
	OR location NOT LIKE '%income'
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
	SUM(total_deaths)/SUM(new_cases::numeric) AS DeathPercentage
FROM deaths
WHERE (date <> '2020-01-22'
	AND total_cases IS NOT NULL)
	AND continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT d.continent, d.location, d.date, d.population, COALESCE(v.new_vaccinations,0) AS new_vaccinations, 
	SUM(COALESCE(v.new_vaccinations,0)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM deaths AS d
JOIN vaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.location = 'Germany'
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT d.continent, d.location, d.date, d.population, COALESCE(v.new_vaccinations,0) AS new_vaccinations, 
	SUM(COALESCE(v.new_vaccinations,0)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_total_vaccinations
FROM deaths AS d
JOIN vaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (total_vaccinations::numeric/population::numeric)*100 AS vac_perc_population
FROM PopvsVac


-- Using TEMP TABLE to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS PopulationVacPerc
CREATE TEMP TABLE PopulationVacPerc(
continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population NUMERIC,
new_vaccinations NUMERIC,
rolling_total_vaccinations NUMERIC
)

INSERT INTO PopulationVacPerc
SELECT d.continent, d.location, d.date, d.population, COALESCE(v.new_vaccinations,0) AS new_vaccinations, 
	SUM(COALESCE(v.new_vaccinations,0)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_total_vaccinations
FROM deaths AS d
JOIN vaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (rolling_total_vaccinations/population)*100 AS vac_perc_population
FROM PopulationVacPerc

-- Creating VIEW to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT d.continent, d.location, d.date, d.population, COALESCE(v.new_vaccinations,0) AS new_vaccinations, 
	SUM(COALESCE(v.new_vaccinations,0)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_total_vaccinations
FROM deaths AS d
JOIN vaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3