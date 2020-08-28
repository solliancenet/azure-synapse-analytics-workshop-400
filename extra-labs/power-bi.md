# Power BI in Synapse Analytics

## Resource naming throughout this lab

For the remainder of this guide, the following terms will be used for various ASA-related resources (make sure you replace them with actual names and values):

| Azure Synapse Analytics Resource  | To be referred to |
| --- | --- |
| Workspace resource group | `WorkspaceResourceGroup` |
| Workspace / workspace name | `Workspace` |
| Primary Storage Account | `PrimaryStorage` |
| Default file system container | `DefaultFileSystem` |
| SQL Pool | `SqlPool01` |

## Exercise 1 - Power BI and Synapse workspace integration

### Task 1 - Explore the Power BI workspace in Synapse Studio

Synapse studio
- power bi linked service


- power bi workspace connection
  
Power BI portal
-explore workspace

Architectural diagram of integration

### Task 2 - Create a new datasource with Power BI Desktop

1. In **Azure Synapse Studio** (<https://web.azuresynapse.net/>), select **Develop** from the left menu.

2. Beneath **Power BI**, select **Power BI datasets**.

3. Select **New Power BI dataset** from the top navigation menu.

![Select New Power BI dataset](media/01-%20NewPBIDataset.png)

4. Select **Start** and make sure you have Power BI desktop installed on your environment machine.

![Start publishing the datasource to be used in Power BI desktop](media/02%20-%20NewPBIDataset.png)

5. Next, select **SQLPool01** as the data source for your Power BI report. You'll be able to select tables from this pool when creating your dataset.

![Select SQLPool01 as the datasource of your reports](media/03%20-%20NewPBIDataset.png)

6. Select **Download** to save the **01SQLPool01.pbids** file on your local drive and then select **Continue**.
 
![Download the .pbids file on your local drive ](media/04%20-%20NewPBIDataset.png)

7. Select **Close and refresh** to close the publishing dialog.

![Close the datasource publish dialog](media/05%20-%20NewPBIDataset.png)

### Task 3 - Create a new Power BI report in Synapse Studio

1. Open the .pbids file **Power BI desktop**.



## Exercise 2 - Optimizing integration with Power BI

### Task 1 - Explore Power BI optimization options
- diagram in slide deck
  
- In-memory
- Dual table
- DirectQuery


### Task 2 - Improve performance with materialized views
-use report from exercise 1 with direct query
- take note of execution time and query plan
- create materialized view
- take note of improved execution time and query plan
  (lab 3 or 4 to check)

### Task 3 - Improve performance with result-set caching

-use report from exercise 1 with direct query
- take note of execution time and query plan
- activate result-set caching
- take note of improved execution time and query plan
  (lab 3 or 4 to check)