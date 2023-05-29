# ------------------------------------------------------------------------------
# Practicum-2
# Contributor: Kartik Mohan, Raghav Sharma
# Course: Database Management Systems - Spring 2023
# Date: 04/20/2023
# ------------------------------------------------------------------------------

library(magrittr) 
library(dplyr)    
library(RMySQL)
library(RSQLite)

# Connect to database on MySQL
mydb <- dbConnect(MySQL(), user='root', dbname='testprac', password='dbms2023', host='localhost')

# Connect to sqlite database
dbfile = 'practicum2_1.sqlite'
dbcon <- dbConnect(RSQLite::SQLite(), dbfile)


#Fetching all data inserted in tables
#Journals <- dbReadTable(dbcon, "Journals")
#Authors <- dbReadTable(dbcon, "Authors")
#Articles <- dbReadTable(dbcon, "Articles")
#ArticleAuthor <- dbReadTable(dbcon, "ArticleAuthor")


# Create AuthorFact Table in MySQL
dbExecute(mydb, "DROP TABLE IF EXISTS authorfact")

t_authorfact <- "CREATE TABLE authorfact (
                      articleID INTEGER PRIMARY KEY NOT NULL,
                       publishDate DATE,
                       authorID TEXT NOT NULL,
                       year INTEGER,
                       month INTEGER,
                       quarter INTEGER
                      )"
dbExecute(mydb, t_authorfact)

ArticleAuthor <- dbGetQuery(dbcon, "SELECT * FROM ArticleAuthor;")

ArticleAuthor_merged <- dbGetQuery(dbcon, "SELECT a.articleID, a.publishDate, b.authorID 
                                                FROM Articles a
                                                JOIN ArticleAuthor b ON b.articleID = a.articleID;")

# Adding year of creation of article by author to ArticleAuthor_merged
ArticleAuthor_merged$year <- as.numeric(format(as.Date(ArticleAuthor_merged$publishDate, format="%Y"), "%Y"))

# Adding month of creation by author to ArticleAuthor_merged
ArticleAuthor_merged$month <- as.numeric(format(as.Date(ArticleAuthor_merged$publishDate, format="%Y-%m-%d"), "%m"))
# Adding quarter of publication to ArticleAuthor_merged
ArticleAuthor_merged <- ArticleAuthor_merged %>% mutate(quarter = round(as.numeric(ArticleAuthor_merged$month) / 3))

#Writing Table in the Database
dbWriteTable(mydb, name="authorfact", value=ArticleAuthor_merged, overwrite=T, row.names = F)


# Creating JouralFact table
dbExecute(mydb, "DROP TABLE IF EXISTS journalfact")

t_journalfact <- "CREATE TABLE journalfact (
                        articleID INT,
                        journalID INT,
                        journalTitle TEXT,
                        pubDate date,
                        YearlyArticles INTEGER,
                        QuaterlyArticles INTEGER,
                        MonthlyArticles INTEGER
                        )"
dbExecute(mydb, t_journalfact)

# Obtaining Journal Table Values 
journaltable <- dbGetQuery(dbcon, "SELECT * FROM Journals")

# Obtaining Article Table Values 
articletable <- dbGetQuery(dbcon, "SELECT * FROM Articles")


# Renaming 
colnames(journaltable)[2] <- "journalTitle"

# Issn, which serves as the primary key for the Journal table, is used to join the two tables.
jcombined <- dbGetQuery(dbcon, "SELECT Articles.articleId, Journals.issn, Journals.title AS journalTitle, Journals.publishDate 
                                  FROM Journals INNER JOIN Articles 
                                  ON Journals.journalID = Articles.journalID")

# Adding year, month and quarter of publication to jcombined
jcombined$year <- as.numeric(format(as.Date(jcombined$publishDate , format="%Y"), "%Y"))
jcombined$month <- as.numeric(format(as.Date(jcombined$publishDate , format="%Y-%m-%d"), "%m"))
jcombined <- jcombined %>% mutate(quarter = round(as.numeric(jcombined$month) / 3))

# Initially Set YearlyArticles, MonthlyArticles and QuaterlyArticles to 1 and add it to jcombined
journaltable_YearlyArticles <- cbind(jcombined, YearlyArticles=1)
jcombined <- transform(journaltable_YearlyArticles, YearlyArticles = ave(YearlyArticles, year, FUN=sum))

journaltable_MonthlyArticles <- cbind(jcombined, MonthlyArticles=1)
jcombined <- transform(journaltable_MonthlyArticles, MonthlyArticles = ave(MonthlyArticles, month, FUN=sum))

journaltable_QuaterlyArticles <- cbind(jcombined, QuaterlyArticles=1)
jcombined <- transform(journaltable_QuaterlyArticles, QuaterlyArticles = ave(QuaterlyArticles, quarter, FUN=sum))

# Add jcombined to the table JournalFact
dbWriteTable(mydb, name="journalfact", value=jcombined, overwrite=T, row.names = F)

test = dbGetQuery(mydb, "SELECT * FROM journalfact LIMIT 10")


# Queries

#Query 1 - What the are number of articles published in every journal in 2012 and 2013?
dbGetQuery(mydb, "SELECT year, COUNT(*) AS article_count
                    FROM journalfact
                    WHERE year IN (2012,2013)
                    GROUP BY year
                    ORDER BY year;")


#Query 2 - What is the number of articles published in every journal in each quarter of 2012 through 2015?
dbGetQuery(mydb, "SELECT CONCAT(year, '-', quarter) AS period,
                      COUNT(*) AS article_count
                      FROM journalfact
                      WHERE year IN (2012, 2015)
                      AND quarter IN (1, 2, 3, 4)
                      GROUP BY year, quarter
                      ORDER BY year, quarter;")


#Query 3 - How many articles were published each quarter (across all years)?
dbGetQuery(mydb, "SELECT CONCAT(year, '-', quarter) AS period, COUNT(*) AS article_count
                      FROM journalfact
                      WHERE quarter IN (1, 2, 3, 4)
                      GROUP BY year, quarter
                      ORDER BY year, quarter;")


#Query 4 - How many unique authors published articles in each year for which there is data?
dbGetQuery(mydb, "SELECT year, COUNT(DISTINCT authorID) as num_authors
                      FROM authorfact
                      GROUP BY year;")

dbDisconnect(dbcon)