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
