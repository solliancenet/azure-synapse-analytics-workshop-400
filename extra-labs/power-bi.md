# Power BI in Synapse Analytics

## Resource naming throughout this lab

For the remainder of this guide, the following terms will be used for various ASA-related resources (make sure you replace them with actual names and values):

| Azure Synapse Analytics Resource  | To be referred to |
| --- | --- |
| Workspace resource group | `WorkspaceResourceGroup` |
| Workspace / workspace name | `Workspace` |
| Power BI workspace name | `PowerBIWorkspace` |
| Primary Storage Account | `PrimaryStorage` |
| Default file system container | `DefaultFileSystem` |
| SQL Pool | `SqlPool01` |

## Exercise 1 - Power BI and Synapse workspace integration

### Task 1 - Explore the Power BI linked service in Synapse Studio

1. Start from  [**Azure Synapse Studio**](<https://web.azuresynapse.net/>) and open the **Manage** hub from the left menu.
![Manage Azure Synapse Workspace](media/001-LinkWorkspace.png)

2. Beneath **External Connections**, select **Linked Services**, observe that a Linked Service pointing to a precreated Power BI workspace has already been configured in the environment.

![Power BI linked service in Azure Synapse Workspace](media/002-PowerBILinkedService.png)

Once your Azure Synapse and Power BI workspaces are linked, you can browse your Power BI datasets, edit/create new Power BI Reports directly from the Synapse Studio.

3. In  [**Azure Synapse Studio**](<https://web.azuresynapse.net/>) and navigate to the **Develop** hub using the left menu option.
   
![Develop option in Azure Synapse Workspace](media/003%20-%20PowerBIWorkspace.png)

4. Under **Power BI**, select the linked workspace (**Synapse 01** in the picture bellow) and observe that you have now access to your Power BI datasets and reports, directly from the Synapse Studio.

![Explore the linked Power BI workspace in Azure Synapse Studio](media/004%20-%20PowerBIWorkspaceNode.png)

New reports can be created by selecting **+** at the top of the **Develop** tab. Existing reports can be edited by selecting the report name. Any saved changes will be written back to the Power BI workspace.
Next, let's explore the linked workspace in Power BI Portal

5. Sign in to the  [**Power BI Portal**](<https://app.powerbi.com/>) and select **Workspaces** from the left menu to check the existence of the Power BI workspace you have configured in the Synapse portal.

![Check Power BI workspace in the Power BI portal](media/005%20-%20SynapseWorkspaceInPowerBI.png)

TODO: Architectural diagram of integration

### Task 4 - Create a new datasource with Power BI Desktop

1. In **Azure Synapse Studio** (<https://web.azuresynapse.net/>), select **Develop** from the left menu.

2. Beneath **Power BI**, select **Power BI datasets**.

3. Select **New Power BI dataset** from the top navigation menu.

![Select the New Power BI dataset option](media/011-NewPBIDataset.png)

4. Select **Start** and make sure you have Power BI desktop installed on your environment machine.

![Start publishing the datasource to be used in Power BI desktop](media/012%20-%20NewPBIDataset.png)

5. Next, select **SQLPool01** as the data source for your Power BI report. You'll be able to select tables from this pool when creating your dataset.

![Select SQLPool01 as the datasource of your reports](media/013%20-%20NewPBIDataset.png)

6. Select **Download** to save the **01SQLPool01.pbids** file on your local drive and then select **Continue**.
 
![Download the .pbids file on your local drive ](media/014%20-%20NewPBIDataset.png)

7. Select **Close and refresh** to close the publishing dialog.

![Close the datasource publish dialog](media/015%20-%20NewPBIDataset.png)

### Task 5 - Create a new Power BI report in Synapse Studio

1. In [**Azure Synapse Studio**](<https://web.azuresynapse.net/>), select **Develop** from the left menu. Select **+** to create a new SQL Script. Execute the following query to get an approximation of its execution time:
   
```sql
SELECT count(*) FROM
(
    SELECT
    FS.CustomerID
    ,P.Seasonality
    ,D.Year
    ,D.Quarter
    ,D.Month
    ,FS.StoreId
    ,avg(FS.TotalAmount) as AvgTotalAmount
    ,avg(FS.ProfitAmount) as AvgProfitAmount
    ,sum(FS.TotalAmount) as TotalAmount
    ,sum(FS.ProfitAmount) as ProfitAmount
FROM
        wwi_pbi.SaleSmall FS
        JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
        JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
    GROUP BY
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,FS.StoreId
) T
 ```

2. Open the downloaded .pbids file from Task 4 in Power BI Desktop. Select **Microsoft account** and sign in with the provided credentials.

3. Cancel the navigator dialog.


## Exercise 2 - Optimizing integration with Power BI

### Task 1 - Explore Power BI optimization options
- diagram in slide deck
  
- In-memory
- Dual table
- DirectQuery


### Task 2 - Improve performance with materialized views

1. In [**Azure Synapse Studio**](<https://web.azuresynapse.net/>), select **Develop** from the left menu. Select **+** to create a new SQL Script. Execute the following query to get an approximation of its execution time:

2. Run the following query to get an estimated execution plan and observe the total cost and number of operations.

```sql
EXPLAIN
SELECT * FROM
(
    SELECT
    FS.CustomerID
    ,P.Seasonality
    ,D.Year
    ,D.Quarter
    ,D.Month
    ,FS.StoreId
    ,avg(FS.TotalAmount) as AvgTotalAmount
    ,avg(FS.ProfitAmount) as AvgProfitAmount
    ,sum(FS.TotalAmount) as TotalAmount
    ,sum(FS.ProfitAmount) as ProfitAmount
FROM
        wwi_pbi.SaleSmall FS
        JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
        JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
    GROUP BY
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,FS.StoreId
) T
```

The results should look like this:

```xml
 <?xml version="1.0" encoding="utf-8"?>
<dsql_query number_nodes="1" number_distributions="60" number_distributions_per_node="60">
  <sql>SELECT count(*) FROM
(
    SELECT
    FS.CustomerID
    ,P.Seasonality
    ,D.Year
    ,D.Quarter
    ,D.Month
    ,FS.StoreId
    ,avg(FS.TotalAmount) as AvgTotalAmount
    ,avg(FS.ProfitAmount) as AvgProfitAmount
    ,sum(FS.TotalAmount) as TotalAmount
    ,sum(FS.ProfitAmount) as ProfitAmount
FROM
        wwi_pbi.SaleSmall FS
        JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
        JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
    GROUP BY
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,FS.StoreId
) T</sql>
  <dsql_operations total_cost="10.61376" total_number_operations="12">
```

3. Create a materialized view that can support the above query:

    ```sql
    CREATE MATERIALIZED VIEW
    wwi_pbi.mvCustomerSales
    WITH
    (
        DISTRIBUTION = HASH( CustomerId )
    )
    AS
    SELECT
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,FS.StoreId
        ,sum(FS.TotalAmount) as TotalAmount
        ,sum(FS.ProfitAmount) as ProfitAmount
    FROM
        wwi_pbi.SaleSmall FS
        JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
        JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
    GROUP BY
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,FS.StoreId
    ```

4. Run the following query to get an estimated execution plan:

```sql
EXPLAIN
SELECT * FROM
(
  SELECT
  FS.CustomerID
  ,P.Seasonality
  ,D.Year
  ,D.Quarter
  ,D.Month
  ,FS.StoreId
  ,avg(FS.TotalAmount) as AvgTotalAmount
  ,avg(FS.ProfitAmount) as AvgProfitAmount
  ,sum(FS.TotalAmount) as TotalAmount
  ,sum(FS.ProfitAmount) as ProfitAmount
  FROM
      wwi_pbi.SaleSmall FS
      JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
      JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
  GROUP BY
      FS.CustomerID
      ,P.Seasonality
      ,D.Year
      ,D.Quarter
      ,D.Month
      ,FS.StoreId
  ) T

```



### Task 3 - Improve performance with result-set caching

-use report from exercise 1 with direct query
- take note of execution time and query plan
- activate result-set caching
- take note of improved execution time and query plan
  (lab 3 or 4 to check)