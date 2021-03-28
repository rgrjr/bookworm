-- Incremental changes from schema version 0.1 to 0.2.
--
-- [created.  -- rgr, 27-Mar-21.]
--

--- Rev 1:  Add "satire" to the book.category enum, and drop "sf".
alter table book
    change category
	category enum('fiction', 'history', 'biography', 'satire',
		      'text', 'guidebook', 'nonfiction');
