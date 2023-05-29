
# ------------------------------------------------------------------------------

# HEADER 

# Contributor: Kartik Mohan, Raghav Sharma
# Course: Database Management Systems - Spring 2023
# Date: 20th April 2023

# ------------------------------------------------------------------------------


# Loads the libraries 
library(XML)
library(methods)
library(RSQLite)
library(dplyr)
library(DBI)

# connecting sqlite db
dbfile = 'practicum2_1.sqlite'
dbcon <- dbConnect(RSQLite::SQLite(), dbfile)

# Load (with validation of the DTD) the XML file into R
xmlData <- xmlParse(file = "pubmed-tfm-xml/pubmed22n0001-tf.xml", validate=T)
root <- xmlRoot(xmlData)
xmlLength <- xmlSize(root)

# Create a normalized relational schema that contains the following entities/tables: Articles, Journals, Authors
  
# Journals Table in SQLite
JournalTable <- "
  CREATE TABLE IF NOT EXISTS Journal(
  journalID number PRIMARY KEY,
  issn text,
  title text,
  volume number,
  issue number,
  publishDate date
  )"
dbExecute(dbcon, JournalTable)


#Article table in SQLite 
ArticleTable <- "
  CREATE TABLE IF NOT EXISTS Article(
  articleID number PRIMARY KEY,
  journalID number REFERENCES Journal(journalID),
  articleTitle text,
  publishDate date
  )"
dbExecute(dbcon, ArticleTable)


# Author table in SQLite 
AuthorTable <- "
  CREATE TABLE IF NOT EXISTS Author(
  authorID number PRIMARY KEY,
  lastName text,
  firstName text,
  initials text
  )"
dbExecute(dbcon, AuthorTable)


# ArticleAuthor table in SQLite
ArticleAuthorTable <- "
  CREATE TABLE IF NOT EXISTS ArticleAuthor(
  articleID number,
  authorID number,
  PRIMARY KEY (articleID, authorID)
  FOREIGN KEY (articleID) REFERENCES Article(articleID),
  FOREIGN KEY (authorID) REFERENCES Author(authorID)
  )"


# Create dataframe for storing
journaldf <- data.frame(
      journalID = numeric(),
      issn = numeric(),
      title = character(),
      volume = numeric(),
      issue = numeric(),
      publishDate = character()
    )
  
articledf <- data.frame(
      articleID = numeric(),
      journalID = numeric(),
      articleTitle = character(),
      publishDate = character()
    )

articleAuthordf <- data.frame(
      articleID = numeric(),
      authorID = numeric()
    )
  
authordf <- data.frame(authorID = numeric(),
                    lastName = character(),
                    firstName = character(),
                    initials = character()
                    )
  
# index value
journalIndex = 0
authorIndex = 0

# Parsing the XML with the root 
for(i in 1:xmlSize(root)){
  
  node <- root[[i]]
  articleID <- xmlAttrs(node)[[1]]

  pubDetails <- node[[1]]                  # PubDetails node
  journal <- pubDetails[[1]]               # Journal node
  journalSize <- xmlSize(journal)
  
  # set values
  issn <- ""
  volume <- "0"
  issue <- "0"
  year <- "1800"
  month <- "Jan"
  day <- "1"
  journalTitle <- ""
  
  # Fetching Journal Details from XML by looping through tags contained in it.
  for(je in 1:xmlSize(journal)){
    
    # ISSN
    if(xmlName(journal[[je]]) == "ISSN"){
      issn <- xmlValue(journal[[je]])
    }
    
    # Journal Title
    else if(xmlName(journal[[je]]) == "Title"){
      journalTitle <- xmlValue(journal[[je]])
    }
    
    # JournalIssue
    else if(xmlName(journal[[je]]) == "JournalIssue"){
      journalIssue <- journal[[je]]
      
      for(ji in 1:xmlSize(journalIssue)){
          if(xmlName(journalIssue[[ji]]) == "Volume"){
            volume <- xmlValue(journalIssue[[ji]])
          }
  
          else if(xmlName(journalIssue[[ji]]) == "Issue"){
            issue <- xmlValue(journalIssue[[ji]])
          }
          
          else if(xmlName(journalIssue[[ji]]) == "PubDate"){
            pubDate <- journalIssue[[ji]]

                # PubDate
                for(pe in 1:xmlSize(pubDate)){
                  
                  if(xmlName(pubDate[[pe]]) == "Year"){
                    year <- xmlValue(pubDate[[pe]])
                  }
                  
                  else if(xmlName(pubDate[[pe]]) == "Month"){
                    month <- xmlValue(pubDate[[pe]])
                  }
          
                  else if(xmlName(pubDate[[pe]]) == "Day"){
                    day <- xmlValue(pubDate[[pe]])
                  }
                }
             }
        }
    }
  }

  publishDate <- paste0(month,"/",day,"/",year)
  
  #articleTitle <- xmlValue(root[[i]][[1]][[2]])
  articleTitle <- xmlValue(pubDetails[[2]])
  
  
  if(any(journaldf$issn == issn)){
    journalID <- journaldf$journalID[which(journaldf$issn == issn)]
  }
  else{
    journalIndex = journalIndex + 1
    journalID <- journalIndex
    journaldf[nrow(journaldf)+1,] <- c(journalID, issn, journalTitle, volume, issue, publishDate)
  }
  
  articledf[i,] <- c(articleID, journalID, articleTitle, publishDate)
  
  # Fetching Author details from XML
  #authors <- root[[i]][[1]][[3]]
  authors <- pubDetails[[3]]
  
  for(j in 1:xmlSize(authors)){
    
    if(xmlSize(authors[[j]]) == 1){
      lastName = xmlValue(authors[[j]][[1]])
      firstName = ""
      initials = ""
    
    }else{
      lastName = xmlValue(authors[[j]][[1]])
      firstName = xmlValue(authors[[j]][[2]])
      initials = xmlValue(authors[[j]][[3]])
    }
    
    if(is.na(lastName)){
      lastName = ""
    }
    
    if(any(authordf$lastName == lastName)){
      authorID <- authordf$authorID[which(authordf$lastName == lastName)]
    
    }else{
      authorIndex = authorIndex + 1
      authorID <- authorIndex
      authordf[nrow(authordf)+1,] <- c(authorID, lastName, firstName, initials)
    }
    
    #articleAuthor dataframe
    articleAuthordf[nrow(articleAuthordf)+1,] <- c(articleID, authorID)
    
  }
}


# convert to date and char 
journaldf$publishDate <- as.Date(journaldf$publishDate, format = "%b/%d/%Y")
journaldf$publishDate <- as.character(journaldf$publishDate)

articledf$publishDate <- as.Date(articledf$publishDate, format = "%b/%d/%Y")
articledf$publishDate <- as.character(articledf$publishDate)

# write to SQL Table from data frame
dbWriteTable(dbcon, "Authors", authordf, overwrite = T)
dbWriteTable(dbcon, "Articles", articledf, overwrite = T)
dbWriteTable(dbcon, "Journals", journaldf, overwrite = T)
dbWriteTable(dbcon, "ArticleAuthor", articleAuthordf, overwrite = T)

# Disconnect from SQLite database
dbDisconnect(dbcon)







