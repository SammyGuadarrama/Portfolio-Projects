
-- Changing certain columns to Float data type to simplify queries later on

Alter Table [Covid-19 Project].dbo.CovidDeaths
Alter Column total_deaths float;

Alter Table [Covid-19 Project].dbo.CovidDeaths
Alter Column total_cases float;

Alter Table [Covid-19 Project].dbo.CovidDeaths
Alter Column new_cases float;

Alter Table [Covid-19 Project].dbo.CovidDeaths
Alter Column new_deaths float;

Alter Table [Covid-19 Project].dbo.CovidVaccinations
Alter Column new_vaccinations float;

Alter Table [Covid-19 Project].dbo.CovidDeaths
Alter Column population float;

-- Formatting Date column to Date format

Alter Table [Covid-19 Project].dbo.CovidDeaths
Alter Column date date;

-- Select data we will be using from the CovidDeaths table, ordering by location and date

select location, date, total_cases, new_cases, total_deaths, population
from [Covid-19 Project].dbo.CovidDeaths
order by 1,2

-- Looking at total cases vs total deaths by creating DeathPercentage field
-- To prevent error, changing total_cases to NULL if there are 0 cases or no data
-- Shows likelihood of dying if you contract Covid in the US, ordering by location and date

select location, date, total_cases, total_deaths, (total_deaths/nullif(total_cases,0))*100 as DeathPercentage
from [Covid-19 Project].dbo.CovidDeaths
where location = 'United States'
order by 1,2

-- Looking at total cases vs population by creating CasesbyPopPercentage field
-- Shows percentage of population that had Covid in the US, ordering by date

select location, date, population, total_cases, (total_cases/population)*100 as CasesbyPopPercentage
from [Covid-19 Project].dbo.CovidDeaths
where location = 'United States'
order by 2

-- Looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/nullif(population,0)))*100 as CasesbyPopPercentage
from [Covid-19 Project].dbo.CovidDeaths
group by location, population
order by CasesbyPopPercentage desc

-- Looking at countries with highest death count

select location, max(total_deaths) as TotalDeathCount
from [Covid-19 Project].dbo.CovidDeaths
where continent != ''
group by location
order by TotalDeathCount desc

-- Looking at continents with highest death count

select location, max(total_deaths) as TotalDeathCount
from [Covid-19 Project].dbo.CovidDeaths
where continent = ''
group by location
order by TotalDeathCount desc

-- TOTAL GLOBAL NUMBERS

select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, sum(new_deaths)/sum(nullif(new_cases,0))*100 as DeathPercentage
from [Covid-19 Project].dbo.CovidDeaths
where continent != ''
order by 1,2

-- Now joining the two tables in the database and looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from [Covid-19 Project]..CovidDeaths dea
join [Covid-19 Project]..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent != ''
order by 1,2,3

-- Using CTE to look at the above plus the percentage of people vaccinated

With PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinations)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from [Covid-19 Project]..CovidDeaths dea
join [Covid-19 Project]..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent != ''
)

select *, (RollingVaccinations/nullif(population,0))*100 as VaccinationPercentage
from PopvsVac
order by 1,2,3

-- Alternative to the above: using a temp table instead of a CTE

Drop Table if exists #PercentPopVaccinated
Create Table #PercentPopVaccinated
(
continent nvarchar(235),
location nvarchar(235),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinations numeric
)

insert into #PercentPopVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from [Covid-19 Project]..CovidDeaths dea
join [Covid-19 Project]..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent != ''

select *, (RollingVaccinations/nullif(population,0))*100 as VaccinationPercentage
from #PercentPopVaccinated
order by 1,2,3

-- VIEWS: Creating Views for later visualizations, select queries copied from above

create view PercentDeathsperCasesUS as
select location, date, total_cases, total_deaths, (total_deaths/nullif(total_cases,0))*100 as DeathPercentage
from [Covid-19 Project].dbo.CovidDeaths
where location = 'United States'

create view PercentCasesperPopbyCountry as
select location, date, population, total_cases, (total_cases/nullif(population,0))*100 as CasesbyPopPercentage
from [Covid-19 Project].dbo.CovidDeaths
where continent != ''

create view HighestDeathCountbyCountry as
select location, max(total_deaths) as TotalDeathCount
from [Covid-19 Project].dbo.CovidDeaths
where continent != ''
group by location

create view TotalGlobalNumbers as
select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, sum(new_deaths)/sum(nullif(new_cases,0))*100 as DeathPercentage
from [Covid-19 Project].dbo.CovidDeaths
where continent != ''

create view PercentVaccinationsperPopbyCountry as
With PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinations)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from [Covid-19 Project]..CovidDeaths dea
join [Covid-19 Project]..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent != ''
)

select *, (RollingVaccinations/nullif(population,0))*100 as VaccinationPercentage
from PopvsVac
