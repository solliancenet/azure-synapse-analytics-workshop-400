# Activity 03: Data Warehouse Optimization

In this activity, you will work with your team to optimize the peformance of a query to make it return results in the shortest time possible. 

# Team Challenge 

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

Share your best query time with your learning adviser who will report it back for comparison with the results from other teams.

> NOTE: You can experiment in your individual environments, however when selecting the environment in which to produce your "official" results you should pick the one with the largest SQL Pool size among those available in your Table Group. 