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