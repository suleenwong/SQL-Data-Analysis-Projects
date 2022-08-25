-- Create baby_names table
CREATE TABLE baby_names (
  year INT,
  first_name VARCHAR(64),
  sex VARCHAR(64),
  num INT
);

-- Import data from .csv file
copy baby_names 
FROM 'usa_baby_names.csv' 
DELIMITER ',' 
CSV HEADER;

-- Check data
SELECT *
FROM baby_names