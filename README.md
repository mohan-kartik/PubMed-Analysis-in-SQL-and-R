<P ALIGN='CENTER'><img src= 'https://github.com/mohan-kartik/PubMed-Analysis-in-SQL-and-R/assets/42971268/b4605c7e-e6b0-4d51-aeac-baaf80cd92f6'>
  
## Objectives:
Extract PubMed data from an XML document to store relationally in a SQLite database (transactional database) and create an "analytical" database using a star schema in MySQL for analysis.

- Extract XML document,
- realize the relational schema in MySQL, 
- load data into the database, 
- create star/snowflake schema,
- execute analytical SQL queries, 
- performed some visualization of the data

## Tasks
Part 1: Load [XML Data](https://s3.us-east-2.amazonaws.com/artificium.us/lessons/06.r/l-6-183-extractxml-data-in-r/pubmed-xml-tfm/pubmed22n0001-tf.xml) into Database (LoadXML2DB.Rmd)
  - Build an external DTD for the XML file 
  - Create the database schema in SQLite that contains the following entities/tables: Articles, Journals, Authors
  - Extract and transform the data from the XML file and load into the appropriate tables in the database

Part 2: Create Star/Snowflake Schema (LoadDataWarehouse.Rmd)
  - Create and populate a star schema for journal facts. 
  - Perform the analytical queries below:
  
    i) What the are number of articles published in every journal in 2012 and 2013?
  
    ii) What is the number of articles published in every journal in each quarter of 2012 through 2015?
  
    iii) How many articles were published each quarter (across all years)?
  
    iv) How many unique authors published articles in each year for which there is data?

Part 3: Explore and Mine Data (AnalyzeData.Rmd)
  - Top five journals with the most articles published in them for the time period. 
  - Number of articles per journal per year broken down by quarter. 

