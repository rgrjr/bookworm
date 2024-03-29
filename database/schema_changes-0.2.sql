-- Incremental changes from schema version 0.1 to 0.2.
--
-- [created.  -- rgr, 27-Mar-21.]
--

--- Rev 1:  Add "satire" to the book.category enum, and drop "sf".
alter table book
    change category
	category enum('fiction', 'history', 'biography', 'satire',
		      'text', 'guidebook', 'nonfiction');

--- Rev 2:  Add "reference" to the book.category enum.
alter table book
    change category
	category enum('fiction', 'biography', 'guidebook', 'history',
	 	      'nonfiction', 'reference', 'satire', 'text');

--- Rev 3:  Add a location.bg_color column.
alter table location
  add column
    bg_color enum('inherit', 'grey', 'yellow', 'orange', 'red',
    	          'purple', 'blue', 'aqua', 'green', 'chartreuse')
	     default 'inherit'
  after description;
