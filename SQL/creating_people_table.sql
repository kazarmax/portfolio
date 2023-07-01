-- Creating the "people" table
DROP TABLE IF EXISTS stg.people;
CREATE TABLE stg.people(
   person VARCHAR(17) NOT NULL PRIMARY KEY
  ,region VARCHAR(7) NOT NULL
);

-- Inserting data into the table
INSERT INTO stg.people(person,region) VALUES ('Anna Andreadi','West');
INSERT INTO stg.people(person,region) VALUES ('Chuck Magee','East');
INSERT INTO stg.people(person,region) VALUES ('Kelly Williams','Central');
INSERT INTO stg.people(person,region) VALUES ('Cassandra Brandow','South');