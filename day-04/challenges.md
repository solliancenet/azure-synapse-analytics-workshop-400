# Team challenges
- [Team challenges](#team-challenges)
  - [Introduction](#introduction)
  - [Completing the challenges](#completing-the-challenges)
  - [1 - Configure the environment and raw import](#1---configure-the-environment-and-raw-import)
    - [Background story](#background-story)
    - [Technical details](#technical-details)
    - [Success criteria](#success-criteria)
    - [Resources](#resources)
  - [2 - Optimize data load](#2---optimize-data-load)
  - [3 - Optimize performance of existing queries and create new queries](#3---optimize-performance-of-existing-queries-and-create-new-queries)
  - [4 - Manage and monitor the solution](#4---manage-and-monitor-the-solution)

## Introduction

Wide World Importers is in the process of building a new, modern analytics solution. The old analytics solution was built using an older, on-premises version of SQL Server and was based on the relational engine only. WWI's top management expects the new solution to support the strategic move towards near-real-time data analysis.

The core objective of this PoC challenge is to prove that Azure Synapse Analytics is the right platform to be used by the new solution.

## Completing the challenges

Work as a team to complete the challenges listed below. Pay attention to the background story for each challenge, as they contain insights into the customer's pain points and what they want to solve. Successful teams collaborate on understanding each challenge, then divide and conquer to work in parallel as much as possible.

You have the freedom to choose the solution your team believes will best fit WWI's needs. However, you must be able to explain the thought process behind the decisions to your coach.

## 1 - Configure the environment and raw import

### Background story

WWI began an internal initiative to modernize their outdated, on-premises data and analytics platform by migrating a year of historical data to Azure Synapse Analytics. They were sold on the promise of a highly-scalable, thoroughly modern, unified data warehouse and analytics system that can store their old data and capture and process new data as it arrives. Not only that, but they would be able to unlock new insights by integrating non-relational data and be prepared to delve into machine learning when they are ready to tackle that challenge.

However, that promise never came. After importing each month's-worth of sales data, the data engineering team would execute queries over the data set in the SQL pool. After a few iterations of this process, the queries began to be painfully slow to execute. Each iteration of the data import took longer because they truncated the tables and re-imported all of the data up to the next month. Finally, the team gave up on the process and decided to seek outside help.

Wide World Importers wants your help proving that Synapse Analytics is the right platform for their needs. They have invested a fair amount of resources to this project already, and have gotten the go-ahead from leadership and the board to fully migrate to a new solution over the next eight to twelve months.

### Technical details

Sales data is currently being inserted into the SQL pool. About 30% of the data is already in the internal tables of the SQL Pool. This roughly covers Jan 2012 to April 2012. The remainder of the data is in external CSV and Parquet files.

One of WWI's large LOB systems switched how they export sales data around August 2012. This is why there is a mix of CSV and Parquet files. The CSV external files cover May - August 2012, and the Parquet external files cover September - December 2012.

### Success criteria

Bulleted list of criteria.

### Resources

Reference links

## 2 - Optimize data load

## 3 - Optimize performance of existing queries and create new queries

## 4 - Manage and monitor the solution