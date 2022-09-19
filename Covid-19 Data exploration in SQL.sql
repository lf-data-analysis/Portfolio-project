/*
Skills used: Joins, creating views, converting data types
*/

SELECT *
FROM [Portfolio Project]..CovidDeaths$
ORDER BY 3,4

SELECT *
FROM [Portfolio Project]..CovidVaccinations$
ORDER BY 3,4

--This query creates a new field from two other fields to find the percentage of deaths per case for the United Kingdom
SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths$
WHERE location like 'United Kingdom'
ORDER BY 1,2

--New field for percentage of population that has been infected.
SELECT Location, date, total_cases, Population, (total_cases/Population)*100 as PopulationInfectionRate
FROM [Portfolio Project]..CovidDeaths$
WHERE location like 'United Kingdom'
ORDER BY 1,2

--Use of MAX function to filter the highest number of cases. GROUP BY is then used to find highest cases for each location.
--ORDER BY 4 DESC sorts countries from highest number of cases to lowest.
SELECT Location, Population, MAX(total_cases) as HighestCases, Max((total_cases/Population))*100 as PopulationInfectionRate
FROM [Portfolio Project]..CovidDeaths$
GROUP BY Location, population
ORDER BY 4 DESC

--Similar to last query but for death rate of populations.
--WHERE clause filters out any locations which aren't countries.
SELECT Location, Population, MAX(total_deaths) AS HighestTotalDeaths, MAX((total_deaths/Population))*100 as PopulationDeathRate
FROM [Portfolio Project]..CovidDeaths$ WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY 3 DESC

--Countries with highest death count
--
SELECT Location, MAX(Cast(total_deaths AS int)) AS DeathCount
FROM [Portfolio Project]..CovidDeaths$ WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY DeathCount DESC

---Continent with highest death rate per capita
SELECT continent, MAX((CAST(total_deaths AS INT)) as TotalDeaths, Population, Max((total_deaths/Population))*100 as PopulationDeathRate
FROM [Portfolio Project]..CovidDeaths$
GROUP BY Continent, Population
ORDER BY 4 DESC

--Sorts out data that data for anything but continents, finds max death count then orders from highest death count to lowest.
SELECT Location, MAX(Cast(total_deaths AS int)) AS DeathCount
FROM [Portfolio Project]..CovidDeaths$
WHERE Continent IS NULL 
AND population IS NOT NULL 
AND location NOT IN ('World', 'Low income', 'Lower middle Income', 'High Income', 'European Union')
GROUP BY Location
ORDER BY DeathCount DESC


--Global data for death rate sorted by date
SELECT date, SUM(CAST(total_cases as int)) as TotalCases , SUM(CAST(total_deaths as int)) as Totaldeaths, 
(SUM(CAST(total_deaths as float))/SUM(CAST(total_cases as float)))*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1 asc

--Joining tables to access both vaccine and death data
SELECT *
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date

--Global New Vaccines  
SELECT dea.date, dea.continent, dea.location, vac.new_vaccinations
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date
WHERE dea.location = 'world'
ORDER BY date

---Global Total Vaccines
SELECT dea.date, dea.location, vac.total_vaccinations
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date
WHERE dea.location = 'world'
ORDER BY date

--Using data from two joined tables. One provides data on population and the other on number of vaccinations. 
--Using data from both tables, I create a new field for percentage of the population who has been vaccinated.
SELECT dea.date, dea.location, vac.people_vaccinated , dea.population ,(vac.people_vaccinated/dea.population)*100 AS VaccinatedPercentage
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date
WHERE dea.location = 'world'
ORDER BY date

--Rolling count of vaccines by country.
set ansi_warnings off
SELECT dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations, vac.people_vaccinated, 
SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinations,
(vac.people_vaccinated/dea.population)*100 AS VaccinationRate
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date
WHERE dea.location LIKE 'United Kingdom'
ORDER BY dea.location, dea.date


--Another method for rolling count.
WITH popvsvac(Continent, Date, Location, Population, New_vaccinations, TotalVacs)
AS
(
SELECT dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVacs
--(TotalVacs/dea.population)*100 AS VacRate
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date
WHERE dea.location LIKE 'United Kingdom'
)
SELECT *, (totalvacs/population) AS VacsPerCapita
FROM popvsvac


--Creating a temperary table.
DROP TABLE IF EXISTS #percentagePopVac
CREATE TABLE #PercentagePopVac
(
Continent nvarchar(255)
,Location nvarchar(255)
,Date Datetime
,Population numeric
,NewVaccinations numeric
,RollingVaccinations numeric
)
INSERT INTO #PercentagePopVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinations
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
      ON dea.location = vac.location
	  AND dea.date =vac.date
WHERE dea.location LIKE 'United Kingdom'

SELECT *, (RollingVaccinations/Population) AS VacsPerCapita
FROM #PercentagePopVac

--Creating View
CREATE VIEW DeathRateByContinent as
SELECT Location, MAX(Cast(total_deaths AS int)) AS DeathCount
FROM [Portfolio Project]..CovidDeaths$
WHERE Continent IS NULL 
AND population IS NOT NULL 
AND location NOT LIKE ('%income', '%union', 'world')
GROUP BY Location
