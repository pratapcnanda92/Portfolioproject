--Selecting data from covid_deaths
select * from PortfolioProject.dbo.covid_deaths
where continent is not null 
and location like 'Austria'
ORDER BY 3,4

--Selecting data from covid_vaccinations
select * from PortfolioProject.dbo.covid_vaccinations
ORDER BY 3,4

--Total deaths vs total cases - shows likelihood of deaths in a country
select location, cast(date as date) as date, population, total_cases, total_deaths, 
CONVERT (VARCHAR(20),(convert(decimal(20,2),(cast(total_deaths as float)/total_cases)*100)))+'%' as DeathPercentage
from PortfolioProject.dbo.covid_deaths
where location like 'India'
and continent is not null
ORDER BY 1,2 desc

--Total cases vs total Population (datewise)
select location, cast(date as date) as date, population, total_cases, 
CONVERT (VARCHAR(20),(convert(decimal(20,10),(total_cases/population)*100)))+'%' as CasePercentage
from PortfolioProject.dbo.covid_deaths
where continent is not null
ORDER BY 1,2

--Total cases vs total Population and total death (last date)
select location, population, max(total_cases) as Highest_Infections, 
max(cast(total_deaths as float)) as Highest_Deaths,
convert(decimal(20,3),(max(total_cases)/population)*100) as CasePercentage,
convert(decimal(20,3),(max(cast(total_deaths as float))/max(total_cases))*100) as DeathCasePercentage
from PortfolioProject.dbo.covid_deaths
where continent is not null
GROUP BY location, population
ORDER BY 4 desc

--Continent wise death count
select location, population, max(total_cases) as Cases, max(cast(total_deaths as float)) as Deaths
from PortfolioProject.dbo.covid_deaths
where continent is null
GROUP BY location, population
ORDER BY 4 desc



 --Global data - date wise cases, deaths and percentage
select cast(date as date) as date, SUM(total_cases) as CasesTillDate,
sum(new_cases) as NewCasesOnDate, sum(cast(total_deaths as float)) as DeathsTillDate,
sum(cast(new_deaths as float)) as NewDeathsOnDate,
convert(decimal(20,3),(sum(cast(new_deaths as float))/sum(new_cases))*100) as DeathToCasePercentage
from PortfolioProject.dbo.covid_deaths
where continent is not null 
--and location like 'India'
GROUP BY date
ORDER BY 1


--Population vs Vaccinations - Joins and Windows Function to calculate rolling sum
select d.continent, d.location, cast(d.date as date) as Date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as float)) over (partition by d.location order by d.location, d.date) as TotalVaccinatedTillDate
from PortfolioProject.dbo.covid_deaths d
join PortfolioProject.dbo.covid_vaccinations v
on d.location = v.location and
d.date=v.date
where d.continent is not null
order by 2, 3

--Using CTE (With as clause) - Population vs Vaccinations 
with PopVsVac(continent, location, date, population, new_Vaccinations, TotalVaccinatedTillDate)
as
(
select d.continent, d.location, cast(d.date as date) as Date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as float)) over (partition by d.location order by d.location, d.date) as TotalVaccinatedTillDate
from PortfolioProject.dbo.covid_deaths d 
join PortfolioProject.dbo.covid_vaccinations v
	on d.location = v.location 
	and d.date=v.date
where d.continent is not null
)
select *, convert(decimal(20,5),(TotalVaccinatedTillDate/population)*100)
from PopVsVac 
--where location like 'India'

--Using Temp Table- Population vs Vaccinations 
Drop table if exists #PopVsVac
Create table #PopVsVac
(
continent nvarchar(255), 
location nvarchar(255),
date date, 
population float, 
new_Vaccinations float, 
TotalVaccinatedTillDate float
)
Insert into #PopVsVac 
select d.continent, d.location, cast(d.date as date) as Date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as float)) over (partition by d.location order by d.location, d.date) as TotalVaccinatedTillDate
from PortfolioProject.dbo.covid_deaths d 
join PortfolioProject.dbo.covid_vaccinations v
	on d.location = v.location 
	and d.date=v.date
where d.continent is not null

select *, convert(decimal(20,5),(TotalVaccinatedTillDate/population)*100)
from #PopVsVac 
--where location like 'India'

--Creating Views for visualisations
Create view  PopVsVacc as
select d.continent, d.location, cast(d.date as date) as Date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as float)) over (partition by d.location order by d.location, d.date) as TotalVaccinatedTillDate
from PortfolioProject.dbo.covid_deaths d 
join PortfolioProject.dbo.covid_vaccinations v
	on d.location = v.location 
	and d.date=v.date
where d.continent is not null