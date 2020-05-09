# Lab Artifacts Documentation

## Lab 01

Lab 01 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`asacosmosdbNNNNNN` | Cosmos DB account |
`CustomerProfile` | Cosmos DB database |
`OnlineUserProfile01` | Cosmos DB database collection |
`asadatalakeNNNNNN` | Linked service (ADLS Gen2) |
`wwi-02\sale-small` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\online-user-profiles-02` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\sale-small\Year=2016\Quarter=Q4\Month=12\Day=20161231\sale-small-20161231-snappy.parquet` | File path in `asadatalakeNNNNNN`
`wwi-02\sale-small\Year=2019` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\campaign-analytics\dailycounts.txt` | File path in `asadatalakeNNNNNN` |

Lab 01 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`asacosmosdb01` | Cosmos DB Linked service
`asal400_customerprofile_cosmosdb` | Dataset (Cosmos DB)
`asal400_sales_adlsgen2` | Dataset (ADLS Gen2, Parquet)
`asal400_ecommerce_userprofiles_source` | Dataset (ADSL Gen2, JSON)
`wwi_staging` | SQL pool schema
`wwi_staging.SaleHeap` | SQL pool table
`wwi_staging.Sale` | SQL pool table
`wwi_staging.DailySalesCounts` | SQL Pool table |
`ABSS` | SQL pool external data source
`ParquetFormat` | SQL pool external file format
`csv_dailysales` | SQL pool external file format




## Lab 02

Lab 02 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 02 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----

## Lab 03

Lab 03 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 03 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----

## Lab 04

Lab 04 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 04 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----

## Lab 05

Lab 05 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 05 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----

## Lab 06

Lab 06 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 06 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----

## Lab 07

Lab 07 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 07 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----

## Lab 08

Lab 08 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---

Lab 08 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
