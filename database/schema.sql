-- *** Bookworm Schema ***
--
-- [the next line is parsed by the DB uploader.  -- rgr, 29-Jan-11.]
-- Version: 0.2
--
-- Or upload manually with:
--
--    mysql -p -u bookworm test_bookworm < database/schema.sql
--

create table audit_event (
  event_id int(11) NOT NULL auto_increment,
  staff_id mediumint(6) unsigned zerofill default NULL,
  changed_table_name varchar(30) NOT NULL default '',
  changed_table_key varchar(20) NOT NULL default '',
  changed_column_name varchar(60) NOT NULL default '',
  old_value varchar(4000) NOT NULL default '',
  event_time datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (event_id),
  KEY index_changed_key (changed_table_key),
  KEY changed_table_key (changed_table_key, changed_table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
  category enum('fiction', 'biography', 'guidebook', 'history',
		'nonfiction', 'reference', 'satire', 'text'),
  date_read varchar(100) NOT NULL default '',
  notes varchar(4000) default '',
  location_id int(11) default NULL,
  primary key (book_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table book_author_map (
  authorship_id int(11) NOT NULL auto_increment,
  author_id int(11) NOT NULL,
  book_id int(11) NOT NULL,
  attribution_order int(3) NOT NULL default '1',
  role enum('author', 'with', 'editor', 'translator')
	NOT NULL default 'author',
  primary key (authorship_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table db_update (
  update_id int(11) NOT NULL auto_increment,
  major_version varchar(20) NOT NULL,
  minor_version varchar(20) NOT NULL,
  db_version varchar(20) NOT NULL,
  update_time datetime NOT NULL default '0000-00-00 00:00:00',
  staff_id mediumint(6) unsigned zerofill NOT NULL,
  primary key (update_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table location (
  location_id int(11) NOT NULL auto_increment,
  name varchar(100) NOT NULL default '',
  description varchar(4000) default '',
  bg_color enum('inherit', 'grey', 'yellow', 'orange', 'red',
		'purple', 'blue', 'aqua', 'green', 'chartreuse')
	   default 'inherit',
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

create table session (
  session_id int(11) NOT NULL auto_increment,
  session_token varchar(150) default '',
  staff_id mediumint(6) unsigned zerofill default NULL,
  ip_address varchar(50) default NULL,
  start_time datetime default NULL,
  finish_time datetime default NULL,
  logout_p int(10) NOT NULL default '0',
  PRIMARY KEY  (session_id),
  UNIQUE KEY session_token (session_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table staff (
  staff_id mediumint(6) unsigned zerofill NOT NULL auto_increment,
  last_name varchar(20) NOT NULL default '',
  first_name varchar(50) NOT NULL default '',
  mid_name varchar(50) NOT NULL default '',
  unix_name varchar(16) NOT NULL default '',
  status enum('active', 'inactive', 'internal') NOT NULL default 'active',
  password varchar(50) NOT NULL default '',
  alternate_password varchar(50) NOT NULL default '',
  email varchar(120) NOT NULL default '',
  phone varchar(24) NOT NULL default '',
  favorites_folder_id int(10),
  PRIMARY KEY  (staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--- Constant data.

insert into location (name, description, parent_location_id)
    values ('Somewhere', 'The root of all locations.', 0);
