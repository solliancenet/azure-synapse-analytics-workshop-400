# Data Integration Part 1

- [Data Integration Part 1](#data-integration-part-1)
  - [Exercise 1: Explore source data in the Data Hub](#exercise-1-explore-source-data-in-the-data-hub)
  - [Exercise 2: Create linked services](#exercise-2-create-linked-services)
  - [Exercise 3: Create data pipeline to copy a month of customer data](#exercise-3-create-data-pipeline-to-copy-a-month-of-customer-data)
  - [Exercise 4: Create custom integration runtime](#exercise-4-create-custom-integration-runtime)
  - [Exercise 5: Update data pipeline with new integration runtime](#exercise-5-update-data-pipeline-with-new-integration-runtime)

```
Integrating Data Sources
Using Data Hub: Preview blob & DB data, T-SQL (On-Demand) and PySpark DataFrame
Orchestrate Hub: Connectors, Copy data

Studio - Manage Hub
Studio - Linked services
Studio - Integration runtimes
```

## Exercise 1: Explore source data in the Data Hub

Create a new Spark notebook to query the parquet files from Blob storage

Add a new Dataset for the Parquet files

Filter on quarter or a month to reduce the amount of data we explore in a notebook

## Exercise 2: Create linked services

Introduce the Cosmos DB data source - lab 2 goes into details with transforming the data

## Exercise 3: Create data pipeline to copy a month of customer data

## Exercise 4: Create custom integration runtime

Go to code view and set the timeToLive value to 60. Discuss what this means as far as cost, etc.

## Exercise 5: Update data pipeline with new integration runtime

Compare importing with PolyBase to importing with COPY command

Compare importing into a clustered table vs. a heap table, then use a select into command to move from the heap to clustered table