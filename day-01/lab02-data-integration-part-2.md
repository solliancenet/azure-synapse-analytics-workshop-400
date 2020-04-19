# Data Integration Part 2

- [Data Integration Part 2](#data-integration-part-2)
  - [Exercise 1: Create data flow to import poorly formatted CSV](#exercise-1-create-data-flow-to-import-poorly-formatted-csv)
  - [Exercise 2: Create data flow to join disparate data sources](#exercise-2-create-data-flow-to-join-disparate-data-sources)
  - [Exercise 3: Create pipeline trigger window to import remaining Parquet data](#exercise-3-create-pipeline-trigger-window-to-import-remaining-parquet-data)
  - [Exercise 4: Create Synapse Spark notebook to find top products](#exercise-4-create-synapse-spark-notebook-to-find-top-products)

```
Create e2e pipeline for initial load & update
Data Prep: Handle bad data, file formats, join disparate sources
Troubleshoot: pipeline/activity failure (something beyond simply looking at the portal)
Optimize: trigger window, exec time

Triggering Pipelines
Creating schedule, tumbling window, event (blob vs ADLS)
Other cases: trigger via Function
    - Native and non-standard ways to trigger a pipeline
    - Set up change feed-triggered function (CSharp script via portal). Edit a document in Cosmos DB (maybe a pipeline parameter), which triggers the function
    - Maybe trigger the pipeline via REST call and shown here: https://github.com/solliancenet/azure-synapse-analytics/blob/master/infrastructure/asaexp/setup/ASAExp%20-%20Import%20SQL%20Pool%20Tables.ps1#L114

Spark notebook to connect to the wwi.UserTopProductPurchases Synapse database table.
    - Have user right-click the table, choose notebook, then new Spark notebook
    - Execute code to find the top 5 products for each user, based on which ones are both preferred and top, and have the most purchases in past 12 months
    - Top 5 products overall

```

## Exercise 1: Create data flow to import poorly formatted CSV

## Exercise 2: Create data flow to join disparate data sources

## Exercise 3: Create pipeline trigger window to import remaining Parquet data

## Exercise 4: Create Synapse Spark notebook to find top products