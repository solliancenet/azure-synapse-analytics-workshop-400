# Activity 03: Data Warehouse Optimization

In this activity, you will work with your team to optimize the peformance of a query to make it return results in the shortest time possible. 

# Team Challenge 

WWI wants you to prove your ability to optimize queries using their data. They have provided the following query:

``` SQL
SELECT
    FS.CustomerKey
    ,MIN(FS.Quantity) as MinQuantity
    ,MAX(FS.Quantity) as MaxQuantity
    ,AVG(FS.TaxRate) as AvgTaxRate
    ,AVG(FS.TaxAmount) as AvgTaxAmount
    ,AVG(FS.TotalExcludingTax) as AverageSaleWithoutTax
    ,AVG(FS.TotalIncludingTax) as AverageSaleWithTax
    ,COUNT(DISTINCT FS.StockItemKey) as DistinctStockItems
    ,COUNT(DISTINCT DC.Country) as DistinctCountries
FROM
    wwi_perf.FactSale_Slow FS
    join wwi.DimCity DC ON
        DC.CityKey = FS.CityKey
GROUP BY
    FS.CustomerKey

```

They know from experience that they can optimize this query so that it runs much faster than the 15 or so seconds the above one takes. Working with your team, just how fast can you make this query return results?

## Submit your team results!

When you have achieved your best result, follow these steps to submit your solution the leaderboard:

1. Open the Develop hub.
2. Select Notebooks and open `ASAL400 - Activity3 - Submit Results.ipynb`.
3. Follow the instructions within the notebook to submit your results.





