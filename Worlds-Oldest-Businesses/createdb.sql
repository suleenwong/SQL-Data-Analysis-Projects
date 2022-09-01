CREATE TABLE business.categories (
  category_code VARCHAR(5) PRIMARY KEY,
  category VARCHAR(50)
);

CREATE TABLE business.countries (
  country_code CHAR(3) PRIMARY KEY,
  country VARCHAR(50),
  continent VARCHAR(20)
);

CREATE TABLE business.businesses (
  business VARCHAR(64) PRIMARY KEY,
  year_founded INT,
  category_code VARCHAR(5),
  country_code CHAR(3)
);

copy business.categories FROM 'categories.csv' DELIMITER ',' CSV HEADER;
copy business.countries FROM 'countries.csv' DELIMITER ',' CSV HEADER;
copy business.businesses FROM 'businesses.csv' DELIMITER ',' CSV HEADER;

