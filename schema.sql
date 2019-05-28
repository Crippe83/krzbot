create database krzbot;
use krzbot;
create table `pokemon` (
`monkey` varchar(64) NOT NULL, -- you know, like mon-key :D
`expire` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table `pokemon`
 add primary key (`monkey`);
create table `raids` (
`raidkey` varchar(64) NOT NULL,
`expire` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table `raids`
 add primary key (`raidkey`);

