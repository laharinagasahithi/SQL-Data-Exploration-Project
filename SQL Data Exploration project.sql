select * from coviddeaths;

select location,date_noted,population,total_cases,new_cases,total_deaths from coviddeaths;

--total deaths vs total cases
select location,date_noted,total_cases,total_deaths, (total_deaths/total_cases)*100 as death_percentage from coviddeaths
order by 1,2;

--total death vs population
select location,date_noted,population,total_deaths,(total_deaths/population)*100 as  population_infected from coviddeaths
order by 1,2;

--hightest infected locations
select location,population,max(total_cases),max((total_cases/population))*100 as  population_infected from coviddeaths
group by location,population
order by population_infected desc;

--hightest death count by location
select location, max(total_deaths) as count_of_deaths from coviddeaths
where continent is not null
group by location
order by count_of_deaths desc;

select location, max(total_deaths) as count_of_deaths from coviddeaths
where continent is null
group by location
order by count_of_deaths desc;


--hightest death count by continent
select continent, max(total_deaths) as count_of_deaths from coviddeaths
where continent is not null
group by continent
order by count_of_deaths desc;


--deaths count globally
select date_noted, sum(new_cases), sum(cast(new_deaths as int)) from coviddeaths
where continent is not null
group by date_noted
order by 1,2;

--vaccination table
select * from vaccinations;

--joins
select * from coviddeaths inner join vaccinations
on coviddeaths.location = vaccinations.location
and coviddeaths.date_noted = vaccinations.date_noted;

--total populations vs vaccinations
select dea.location, dea.continent, dea.date_noted, dea.population, vac.new_vaccinations from
coviddeaths dea inner join vaccinations vac
on dea.location = vac.location
and dea.date_noted = vac.date_noted
order by 1,2

--rolling count of people vaccinated partition by location
select dea.location, dea.continent, dea.date_noted, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date_noted) as rolling_count from
coviddeaths dea inner join vaccinations vac
on dea.location = vac.location
and dea.date_noted = vac.date_noted
order by 1,2



--with ctc
with popvac(location, continent, date_noted, population, new_vaccinations,rolling_count)
as
(
select dea.location, dea.continent, dea.date_noted, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date_noted) as rolling_count 
from
coviddeaths dea inner join vaccinations vac
on dea.location = vac.location
and dea.date_noted = vac.date_noted
where dea.continent is not null
)
select location, continent, date_noted, population, new_vaccinations,rolling_count,(rolling_count/population)*100  as vac_percentage
from popvac;



--with temp table
drop table if exists people_vaccinated
create GLOBAL TEMPORARY table people_vaccinated
(
location varchar(30), 
continent varchar(30), 
date_noted date,
population numeric,
new_vaccinations numeric,
rolling_count numeric
)
insert into people_vaccinated
select dea.location, dea.continent, dea.date_noted, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date_noted) as rolling_count 
from
coviddeaths dea inner join vaccinations vac
on dea.location = vac.location
and dea.date_noted = vac.date_noted
where dea.continent is not null

select location, continent, date_noted, population, new_vaccinations,rolling_count,(rolling_count/population)*100 as vac_percentage
from people_vaccinated;


--views
create view vaccinated_people as
select dea.location, dea.continent, dea.date_noted, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date_noted) as rolling_count 
from
coviddeaths dea inner join vaccinations vac
on dea.location = vac.location
and dea.date_noted = vac.date_noted
where dea.continent is not null
order by 2,3

select * from vaccinated_people

