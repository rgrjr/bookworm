-- ### SQL Recipes.

-- (setq sql-product 'mysql)

-- Swap locations 1 and 5 so that "Somewhere" can get ID 1.
update location
   set parent_location_id = case parent_location_id when 1 then 5 else 1 end
   where parent_location_id = 1 or parent_location_id = 5;

-- Find non-digits in book.publication_year.
select * from book
   where publication_year regexp '[^0-9]';

-- Count books by category.
select category, count(*) as n_books
    from book
    group by category;

-- Delete a book (it was a duplicate).
delete from book_author_map
    where book_id = 1438;
delete from book
    where book_id = 1438;

-- Update all book boxes so that they have suitable destinations.
update location
    set destination = 'Bob''s office'
    where name like '%book box%';
update location
    set destination = 'Bob''s office'
    where parent_location_id = 92;
update location
    set destination = 'garage'
    where parent_location_id = 92 and name like 'henge%';
update location
    set parent_location_id = 35
    where parent_location_id = 92;

-- Summarize box weights by destination.
-- The home page does this, but not using "group by".
select destination, sum(weight) as total_weight, count(1) as boxes
    from location
    where weight > 0
    group by destination;

-- Move all locations from basement to pod #1.
update location as loc, location as p1, location as p2
    set loc.parent_location_id = p2.location_id
    where p1.name = 'basement' and p2.name = 'Pod #1'
	  and loc.parent_location_id = p1.location_id;
