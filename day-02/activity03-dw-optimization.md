# Activity 03: Data Warehouse Optimization

In this activity, you will work with your team to optimize the performance of a query to make it return results in the shortest time possible.

## Team Challenge

WWI wants you to prove your ability to optimize queries using their data. They have provided the following query:

``` SQL
SELECT
    FS.CustomerID
    ,MIN(FS.Quantity) as MinQuantity
    ,MAX(FS.Quantity) as MaxQuantity
    ,AVG(FS.Price) as AvgPrice
    ,AVG(FS.TotalAmount) as AvgTotalAmount
    ,AVG(FS.ProfitAmount) as AvgProfitAmount
    ,COUNT(DISTINCT FS.StoreId) as DistinctStores
FROM
    wwi_perf.Sale_Heap FS
GROUP BY
    FS.CustomerId
```

You are not allowed to modify this table (in fact, **you should not modify this table** as it may affect the other labs). However, they have asked if you can **create a new table** and optimize the query such that it runs much faster than the above one. Working with your team, just how fast can you make this query return results?

You must ***not* scale up the SQL Pool**! Make optimizations to improve query performance while remaining in the bounds of the current pool size. Scaling up the SQL Pool can cause resource problems in your region when running this lab with multiple participants.

Share your best query time with your learning adviser who will report it back for comparison with the results from other teams.

> NOTE: You can experiment in your individual environments, however when selecting the environment in which to produce your "official" results you should pick the one with the largest SQL Pool size among those available in your Table Group.

## Solution

```sql
-- TEACHING OBJECTIVES:
-- 1. Learn to check existing structures
-- 2. Create new, clean tables
-- 3. Count # of rows before partitioning
-- 4. Decide correctly on CCI

-- 1. Check initial execution time
​
-- VERY important!!!
-- the execution time in the UI is not relevant as the result set contains 1000000 customers
-- displaying this takes a lot of time
-- you should instruct students to look in the Monitoring hub, identify their query and check the execution time there
​
SELECT
    FS.CustomerID
    ,MIN(FS.Quantity) as MinQuantity
    ,MAX(FS.Quantity) as MaxQuantity
    ,AVG(FS.Price) as AvgPrice
    ,AVG(FS.TotalAmount) as AvgTotalAmount
    ,AVG(FS.ProfitAmount) as AvgProfitAmount
    ,COUNT(DISTINCT FS.StoreId) as DistinctStores
FROM
    wwi_perf.Sale_Heap FS
GROUP BY
    FS.CustomerId
​
-- takes about 8 minutes
​
-- 2. Understnad how many rows are in the table (339 millions)
​
SELECT COUNT(*) FROM wwi_perf.Sale_Heap
​
-- 3. Understand the time range (one year)
​
SELECT MIN(TransactionDateId), MAX(TransactionDateId) from wwi_perf.Sale_Heap 
​
-- 4. Script the CREATE TABLE to understand the existing structure of the table
​
CREATE TABLE [wwi_perf].[Sale_Heap]
( 
	[TransactionId] [uniqueidentifier]  NOT NULL,
	[CustomerId] [int]  NOT NULL,
	[ProductId] [smallint]  NOT NULL,
	[Quantity] [tinyint]  NOT NULL,
	[Price] [decimal](9,2)  NOT NULL,
	[TotalAmount] [decimal](9,2)  NOT NULL,
	[TransactionDateId] [int]  NOT NULL,
	[ProfitAmount] [decimal](9,2)  NOT NULL,
	[Hour] [tinyint]  NOT NULL,
	[Minute] [tinyint]  NOT NULL,
	[StoreId] [smallint]  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
​
-- 5. CTAS into a new structure
-- As we have ~300 mil rows, 4 partitions per distribution (quarters) is the optimum level
-- should take ~ 03:39 mins
​
CREATE TABLE [wwi_perf].[Sale1]
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	CLUSTERED COLUMNSTORE INDEX,
	PARTITION
	(
		[TransactionDateId] RANGE LEFT FOR VALUES ( 
			20190101, 20190401, 20190701, 20191001)
	)
)
AS
SELECT * from [wwi_perf].[Sale_Heap]
​
-- 6. Run the query on the new table as a high-performance SQL user assigned to staticrc80
​
EXECUTE AS USER = 'asa.sql.highperf'
SELECT
    FS.CustomerID
    ,MIN(FS.Quantity) as MinQuantity
    ,MAX(FS.Quantity) as MaxQuantity
    ,AVG(FS.Price) as AvgPrice
    ,AVG(FS.TotalAmount) as AvgTotalAmount
    ,AVG(FS.ProfitAmount) as AvgProfitAmount
    ,COUNT(DISTINCT FS.StoreId) as DistinctStores
FROM
    wwi_perf.Sale1 FS
GROUP BY
    FS.CustomerId
​
-- takes about 2 minutes
​
-- time permitting, feel free to explore with ORDERED CCI as well

```
