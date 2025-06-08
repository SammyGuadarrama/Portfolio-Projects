--  Create our table

DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    cast_members VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year int,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

-- Bulk insert the data to be analyzed

BULK INSERT netflix
FROM 'C:\Users\samtg\OneDrive\Desktop\Data Analyst Projects\netflix_titles.txt'
WITH (
    FIELDTERMINATOR = '\t',  
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Verify all 8807 rows of data were imported correctly

select * from netflix

select count(*) as total_content
from netflix

-- Look at distinct values in the type field, found that there are only 2: TV Show and Movie

select distinct type
from netflix

-- Count number of movies vs number of TV shows
-- This displays the total content for each type

select type, count(type) as total_content
from netflix
group by type

-- Find the most common rating for movies and most common rating for TV shows
-- Uses a window function to rank each rating within each type (movies and TV shows), then displays the #1 for each

select type, rating as most_common_rating
from
(
	select type, rating, count(*) as total_content, rank() over(partition by type order by count(*) desc) as ranking
	from netflix
	group by type, rating
) as rating_ranking
where ranking = 1

-- List all movies released in 2020

select *
from netflix
where type = 'movie' and release_year = 2020

-- Find the top 5 countries with the most content on Netflix
-- Some values in the country field atttributed multiple countries,
-- The below uses a CTE to count each instance that a country appears in the dataset and then display the top 5

with splitcountries as
(
SELECT show_id, value as countries
from netflix
cross apply string_split(replace(replace(country, '"', ''), ', ', ','), ',')
)
select top 5 countries, count(show_id) as total_content
from splitcountries
group by countries
order by total_content desc

-- Identify the longest movie

select top 1 title, cast(trim(' min' from duration) as int) as trimmed_duration
from netflix
where type = 'Movie'
order by trimmed_duration desc

-- Standardize the date_added column since the date appears in different formats

update netflix
set date_added = convert(date, (replace(date_added,'"','')))

-- Find content added in the last 5 years

SELECT *
FROM netflix
where date_added >= dateadd(year, -5, getdate())

-- Find all content for which Jon Favreau directed or acted

select *
from netflix
where cast_members like '%Jon Favreau%'
or director = 'Jon Favreau'

-- List all TV shows with more than 5 seasons

select *
from netflix
where cast(trim(' Seasons' from duration) as int) > 5
and type = 'TV Show'

-- Count the number of content items in each genre
-- Similar to the CTE above with countries, some values in the 'listed_in' (genre) field list multiple genres
-- The below counts each instance that a genre appears in the dataset and then displays the total content for each genre

with splitgenres as
(
SELECT show_id, value as genres
from netflix
cross apply string_split(replace(replace(listed_in, '"', ''), ', ', ','), ',')
)
select genres, count(show_id) as total_content
from splitgenres
group by genres

-- For each genre, show the year that the most content was added to Netflix for that genre
-- Innermost query is nearly the same as the above
-- Next query ranks all years for each genre according to how much content was added to Netflix for that genre in that year
-- Outermost query displays one line for each genre, the year with a rank of 1 for that genre, and how much content was added that year

select genres, year, total_content
from
(
	select genres, year, count(show_id) as total_content, rank() over(partition by genres order by count(show_id) desc) as ranking
	from
	(
		SELECT show_id, value as genres, year(date_added) as year
		from netflix
		cross apply string_split(replace(replace(listed_in, '"', ''), ', ', ','), ',')
	)
	as splitgenres
	group by genres, year
)
as rankofgenreyears
where ranking = 1

-- List all movies that are documentaries

select *
from netflix
where type = 'Movie'
and listed_in like '%Documentaries%'

-- List the movies on Netflix that actor 'Leonardo DiCaprio' appeared in and were releases in the 2010s

SELECT *
FROM netflix
where cast_members like '%Leonardo DiCaprio%'
and release_year between 2009 and 2021

-- Find the top 10 actors who have appeared in the highest number of content from the United States
-- Uses similar method as the CTEs with countries and genres, this one splits up the cast_members field

with splitcast as
(
SELECT show_id, value as casts
from netflix
cross apply string_split(replace(replace(cast_members, '"', ''), ', ', ','), ',')
where country like '%United States%'
)
select top 10 casts, count(show_id) as total_content
from splitcast
group by casts
order by total_content desc

-- List all content that might be appropriately categorized as "Children & Family Movies" or "Kids' TV"
-- The Where statement here filters for content with descriptions containing keywords related to family,
-- then filters for ratings appropriate for kids, then filters out content already categorized as for kids or families

SELECT *
from netflix
where (description like '%family%'
or description like '%brother%'
or description like '%sister%'
or description like '%mother%'
or description like '%father%')
and (rating = 'G'
or rating = 'TV-G')
and (listed_in not like '%Children & Family Movies%'
and listed_in not like '%Kids'' TV%')