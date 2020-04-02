# Spark ML

```
Spark ML
Microsoft ML for Spark
Train a model with Spark ML/MML Spark
Create Synapse Pipeline to re-train model on demand
```

In this lab, you will...

## Task 1 - Training models with Spark ML and MML Spark

In this task, you will train a model using Spark ML and MML Spark.

1. Open Synapse Analytics Studio, and then navigate to the `Develop` hub.

**TODO: Create MML Spark based notebook:**

2. Under **Notebooks**, select the notebook called `TBD - Model Training`.

3. This notebook handles training the model, converting the model to ONNX and uploading the ONNX model to Azure Storage.

4. Read thru the notebook and execute the cells as instructed in the notebook. When you have finished in the notebook, return to the next task.

## Task 2 - Model registration process

In this task, you will register the model in Azure Synapse Analytics so that it is availble for use from T-SQL. This task picks up where you left off, with the ONNX model being made available in Azure Storage. 

**TODO: Replace this step with a notebook approach:**

1.  One step that is not shown by the notebook is an offline step that converts the ONNX model to hexadecimal. The resulting hex encoded model is also upload to Azure Storage. This conversion is currently performed with [this PowerShell script](./artifacts/00/ml/convert-to-hex.ps1), but could be automated using any scripting platform.

2. Open Synapse Analytics Studio, and then navigate to the `Data` hub.

3. Expand the Databases listing, right click your SQL Pool and then select `New SQL Script`, and then `Empty script`.

   ![Showing the context menu, selecting New SQL Script, Empty Script](media/ex05-new-sql-script.png "Create new script")

3. Replace the contents of this script with following. Be sure to replace the place holder values identified by the comments with the appropriate values from your environment. You only need to add these statements if you have not completed the previous lab.

``` sql
-- Use polybase to load model into the model table
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'fQv2fKq#FN7ra'

-- Create a database scoped credential with Azure storage account key (not a Shared Access Signature) as the secret. 
-- Replace <blob_storage_account_key> with your storage account key.
CREATE DATABASE SCOPED CREDENTIAL StorageCredential
WITH
IDENTITY = 'SHARED ACCESS SIGNATURE'
, SECRET = '<blob_storage_account_key>'
;

-- Create an external data source with CREDENTIAL option.
-- Replace <blob_storage> with the name of your Azure Storage Account.
CREATE EXTERNAL DATA SOURCE ModelStorage
WITH
( LOCATION = 'wasbs://models@<blob_storage>.blob.core.windows.net'
, CREDENTIAL = StorageCredential
, TYPE = HADOOP
)
;
CREATE EXTERNAL FILE FORMAT csv
WITH (
FORMAT_TYPE = DELIMITEDTEXT,
FORMAT_OPTIONS (
FIELD_TERMINATOR = ',',
STRING_DELIMITER = '',
DATE_FORMAT = '',
USE_TYPE_DEFAULT = False
)
);

CREATE EXTERNAL TABLE [wwi_ml].[MLModelExt]
(
[Model] [varbinary](max) NULL
)
WITH
(
LOCATION='/hex' ,
DATA_SOURCE = ModelStorage ,
FILE_FORMAT = csv ,
REJECT_TYPE = VALUE ,
REJECT_VALUE = 0
)
GO

CREATE TABLE [wwi_ml].[MLModel]
(
[Id] [int] IDENTITY(1,1) NOT NULL,
[Model] [varbinary](max) NULL,
[Description] [varchar](200) NULL
)
WITH
(
DISTRIBUTION = REPLICATE,
heap
)
GO
```

4. Add the following to bottom of your SQL script. Be sure to replace the place holder values identified by the comments with the appropriate values from your environment. Run the script. 
``` sql
-- Register the model by inserting it into the table.
-- Replace <Model description> with your user friendly description of the model.
INSERT INTO [wwi_ml].[MLModel]
SELECT Model, '<Model description>'
FROM [wwi_ml].[MLModelExt]

```

5. This script uses PolyBase to load the hex encoded model from Azure Storage into a table within the SQL Pool database. Once the model is inserted into the table in this way, it is available for use by the Predict statement as you will see next.


## Task 3 - Making predictions with a registered Spark ML model

In this task, you will author a T-SQL query that uses the previously trained model to make predictions.

1. Open Synapse Analytics Studio, and then navigate to the `Data` hub.

2. Expand the Databases listing, right click your SQL Pool and then select `New SQL Script`, and then `Empty script`.

   ![Showing the context menu, selecting New SQL Script, Empty Script](media/ex05-new-sql-script.png "Create new script")

**TODO: Update this script with scoring for new model.**

3. Replace the contents of this script with following:

   ```sql
   -- Retrieve the latest hex encoded ONNX model from the table
   DECLARE @model varbinary(max) = (SELECT Model FROM [wwi_ml].[MLModel] WHERE Id = (SELECT Top(1) max(ID) FROM [wwi_ml].[MLModel]));

   -- Run a prediction query
   SELECT d.*, p.*
   FROM PREDICT(MODEL = @model, DATA = [wwi_ml].[SampleData] AS d) WITH (prediction real) AS p;
   ```

4. Select **Run** from the menubar.

   ![The Run button](media/ex05-select-run.png "Select Run")

5. View the results, notice that the `Prediction` column is the model's prediction of how many items of the kind represented by `StockItemKey` that the customer identified by `CustomerKey` will purchase.

   ![Viewing the prediction results in the query result pane](media/ex05-view-prediction-results.png "View prediction results")


## Task 4 - Creating a Synapse Pipeline to re-train model on demand

**TODO: Add steps to create pipling that executes notebook for re-training and T-SQL for registration**