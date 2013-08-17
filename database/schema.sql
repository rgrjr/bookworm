-- *** Bookworm Schema ***
--
-- [the next line is parsed by the DB uploader.  -- rgr, 29-Jan-11.]
-- Version: 0.1
--
-- Or upload manually with:
--
--    mysql -p -u bookworm test_bookworm < database/schema.sql
--
-- $Id: modest-schema.sql 7036 2011-01-29 22:49:31Z rogers $
--

create table author (
  author_id int(11) NOT NULL auto_increment,
  first_name varchar(50) NOT NULL default '',
  mid_name varchar(50) NOT NULL default '',
  last_name varchar(50) NOT NULL default '',
  notes varchar(4000) default '',
  primary key (author_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table book (
  book_id int(11) NOT NULL auto_increment,
  title varchar(200) default '',
  publisher_id int(11) default null,
  publication_year varchar(4),
  category enum('fiction', 'sf', 'history', 'biography', 'text', 'nonfiction'),
  date_read varchar(100) NOT NULL default '',
  notes varchar(4000) default '',
  location_id int(11) default NULL,
  primary key (book_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table book_author_map (
  author_id int(11) NOT NULL,
  book_id int(11) NOT NULL,
  primary key (author_id, book_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table location (
  location_id int(11) NOT NULL auto_increment,
  name varchar(100) NOT NULL default '',
  description varchar(4000) default '',
  parent_location_id int(11) default NULL,
  PRIMARY KEY (location_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table publisher (
  publisher_id int(11) NOT NULL auto_increment,
  publisher_name varchar(200) not null default '',
  publisher_city varchar(200) not null default '',
  primary key (publisher_id),
  unique key (publisher_name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--- Constant data.

insert into location (name, description)
    values ('home', '50 Foster St.');
