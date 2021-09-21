
--Covid 19 Data Exploration 

--Select data by sorting by location and earliest date

Select *
From portfolio..covid_death
Where continent is not null 
order by location, date

-- Unique attributes have been selected

Select location, date, total_cases, new_cases, total_deaths
From portfolio..covid_death
Where continent is not null 
order by location, date

-- select unique attributes and create 
-- a new attribute as percentage of deaths 
---based on the attributes contained in the database in the area of Poland

Select  location, date, total_cases, new_cases, total_deaths, 
(convert(decimal(15,3),total_deaths)/convert(decimal(15,3),total_cases))*100 as death_percentage
From portfolio..covid_death
Where location like '%Poland%'
and continent is not null 
order by  location, date

-- Select the percentage of the tested population in Poland
Select Location, date, Population, total_tests,  (convert(decimal(15,3),total_tests)/population)*100 as PercentPopulationTested
From portfolio..covid_vaccionated
Where location like '%Poland%'
order by  location, date

-- Countries with Highest Test Rate compared to Population

Select Location, Population, MAX(total_tests) as HighestTestedCount, 
Max((convert(decimal(15,3),total_tests)/population)*100 ) as PercentPopulationTested
From portfolio..covid_vaccionated
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationTested desc


-- Countries with Highest Death Count 

Select Location, MAX(cast(Total_deaths as decimal)) as TotalDeathCount
From portfolio..covid_death
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- Contintents with the highest death count

Select continent, MAX(cast(Total_deaths as decimal)) as Total_Death_Count
From portfolio..covid_death
Where continent is not null 
Group by continent
order by Total_Death_Count desc

-- global summary by country


Select continent, SUM(cast(new_cases as decimal)) as total_cases, 
SUM(cast(new_deaths as decimal)) as total_deaths,
SUM(cast(new_deaths as decimal))/SUM(cast(New_Cases as decimal))*100 as DeathPercentage
From portfolio..covid_death
--Where location like '%states%'
where continent is not null 
Group By continent


-- Percentage of population with the highest Covid vaccination rate in Europe 
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PeopleVaccinated,
 (SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)/vac.population)*100 as PeopleVaccinatedPerPopulation
From portfolio..covid_death dea
Join portfolio..covid_vaccionated vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null and dea.continent like '%Europe%'
order by dea.date desc


--Use the previous query and create a new data set

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, PeopleVaccinated, PeopleVaccinatedPerPopulation)
as
(
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PeopleVaccinated,
 (SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)/vac.population)*100 as PeopleVaccinatedPerPopulation
From portfolio..covid_death dea
Join portfolio..covid_vaccionated vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null and dea.continent like '%Europe%'

)
Select *, (PeopleVaccinated/Population)*100
From PopvsVac

-- check if it exists and create a temporary table to perform calculations on the partition
-- virtual table does not store own data but rather displays data that is stored in other tables.

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PeopleVaccinated numeric
)

--add data to temporary table


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PeopleVaccinated
From portfolio..covid_death dea
Join portfolio..covid_vaccionated vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null 
and dea.continent like '%Europe%'

--show temporary table

Select *, (PeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PeopleVaccinated
From portfolio..covid_death dea
Join portfolio..covid_vaccionated vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null 
and dea.continent like '%Europe%'


