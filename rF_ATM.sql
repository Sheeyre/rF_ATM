CREATE TABLE `rdatabase`.`transactions` ( `player` TEXT NOT NULL , `reason` TEXT NOT NULL , `amount` INT(14) NOT NULL , `date` TEXT NOT NULL ) ENGINE = InnoDB;
CREATE TABLE `rdatabase`.`users` ( `identifier` VARCHAR(20) NOT NULL , `name` TEXT NOT NULL , `cash` INT(14) NOT NULL , `bank` INT(14) NOT NULL, PRIMARY KEY (identifier)) ENGINE = InnoDB;
