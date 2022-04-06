-- Incremental changes from schema version 0.2 to 0.3.
--
-- [created.  -- rgr, 5-Apr-22.]
--

--- Rev 1:  Add a location.destination column.
alter table location
  add column
    destination varchar(100) NOT NULL default ''
  after description;

--- Rev 2:  Add a location.weight column.
alter table location
  add column
    weight decimal(5,1) NOT NULL default '0.0'
  after destination;
