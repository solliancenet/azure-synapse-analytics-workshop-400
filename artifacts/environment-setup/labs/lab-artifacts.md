# Lab Artifacts Documentation

## Lab 01

Lab 01 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`asacosmosdbNNNNNN` | Cosmos DB account |
`CustomerProfile` | Cosmos DB database |
`OnlineUserProfile01` | Cosmos DB database collection | Contains 100000 documents.
`asadatalakeNNNNNN` | Linked service (ADLS Gen2) |
`wwi-02\sale-small` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\online-user-profiles-02` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\sale-small\Year=2016\Quarter=Q4\Month=12\Day=20161231\sale-small-20161231-snappy.parquet` | File path in `asadatalakeNNNNNN`
`wwi-02\sale-small\Year=2019` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\campaign-analytics\dailycounts.txt` | File path in `asadatalakeNNNNNN` |
`wwi-02\campaign-analytics\sale-20161230-snappy.parquet` | File path in `asadatalakeNNNNNN` |
`sqlpool_import01` | Linked service (Azure Synapse Analytics) | Uses the `asa.sql.import01` user.

Lab 01 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`asacosmosdb01` | Cosmos DB Linked service |
`asal400_customerprofile_cosmosdb` | Dataset (Cosmos DB) |
`asal400_sales_adlsgen2` | Dataset (ADLS Gen2, Parquet) |
`asal400_ecommerce_userprofiles_source` | Dataset (ADSL Gen2, JSON) |
`asal400_december_sales` | Dataset (ADLS Gen2, Parquet) |
`asal400_saleheap_asa` | Dataset (Azure Synapse Analytics) |
`wwi_staging` | SQL pool schema |
`wwi_external` | SQL Pool schema |
`wwi_staging.SaleHeap` | SQL pool table |
`wwi_staging.Sale` | SQL pool table |
`wwi_staging.DailySalesCounts` | SQL Pool table |
`wwi_external.Sales` | SQL Pool external table |
`wwi_external.DailySalesCounts` | SQL Pool external table |
`ABSS` | SQL pool external data source |
`ParquetFormat` | SQL pool external file format |
`csv_dailysales` | SQL pool external file format |
`BigDataLoad` | SQL pool workload group |
`HeavyLoader` | SQL pool workload classifier |
`ASAL400 - Copy December Sales` | Pipeline |

## Lab 02

Lab 02 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`wwi` | SQL pool schema |
`wwi-02\campaign-analytics\campaignanalytics.csv` | Filepath in `asadatalakeNNNNNN` |
`sqlpool01` | Linked service (Azure Synapse Analytics)
`wwi-02\online-user-profiles-02` | Folder path in `asadatalakeNNNNNN` |
`asadatalakeNNNNNN` | Linked service (ADLS Gen2) |

Lab 02 depends on the following artifacts created by previous labs:

Artifact Name | Artifact Type | Created by | Notes
--- | --- | --- | ---
`asal400_ecommerce_userprofiles_source` | Dataset (ADLS Gen2, JSON) | Lab 01 |
`asal400_customerprofile_cosmosdb` | Dataset (Cosmos DB) | Lab 01 |

Lab 02 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`AzureLargeComputeOptimizedIntegrationRuntime` | Integration runtime |
`wwi.CampaignAnalytics` | SQL pool table }
`wwi.Sale` | SQL pool table |
`wwi.UserProductReviews` | SQL pool table |
`wwi.UserTopProductPurchases` | SQL pool table |
`asal400_campaign_analytics_source` | Dataset (ADLS Gen2, Delimited text) |
`asal400_wwi_campaign_analytics_asa` | Dataset (Azure Synapse Analytics) |
`asal400_wwi_userproductreviews_asa` | Dataset (Azure Synapse Analytics) |
`asal400_wwi_usertopproductpurchases_asa` | Dataset (Azure Synapse Analytics) |
`ASAL400 - Lab 2 - Write Campaign Analytics to ASA` | Data flow |
`ASAL400 - Lab 2 - Write User Profile Data to ASA` | Data flow |
`ASAL400 - Lab 2 - Write Campaign Analytics to ASA` | Pipeline |
`ASAL400 - Lab 2 - Write User Profile Data to ASA` | Pipeline |

## Lab 03

Lab 03 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`wwi_perf` | SQL pool schema |
`wwi_perf.Sale_Heap` | SQL pool table | Contains N records.
`wwi_perf.Sale_Partition01` | SQL pool table | Contains N records.


Lab 03 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`wwi_perf.Sale_Hash` | SQL pool table |
`wwi_perf.mvCustomerSales` | SQL pool materialized view |
`RESULT_SET_CACHING ON` | SQL pool setting | Reset with `ALTER DATABASE [<sql_pool>] SET RESULT_SET_CACHING OFF`.
`Sale_Hash_Customer_Id` | SQL pool statistics on `wwi_perf.Sale_Hash (CustomerId)` | Reset with `DROP STATISTICS Sale_Hash_Customer_Id`.
`Store_Index` | SQL pool index on `

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
