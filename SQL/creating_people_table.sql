-- Creating the "people" table
DROP TABLE IF EXISTS datalearn.people;
CREATE TABLE datalearn.people(
   person VARCHAR(17) NOT NULL PRIMARY KEY
  ,region VARCHAR(7) NOT NULL
);

-- Inserting data into the table
INSERT INTO datalearn.people(person,region) VALUES ('Anna Andreadi','West');
INSERT INTO datalearn.people(person,region) VALUES ('Chuck Magee','East');
INSERT INTO datalearn.people(person,region) VALUES ('Kelly Williams','Central');
INSERT INTO datalearn.people(person,region) VALUES ('Cassandra Brandow','South');