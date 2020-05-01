# Machine Learning

Azure Synapse Analytics provides a unified environment for both data science and data engineering. What this means in practice, is that your data scientists can train and deploy models using Azure Synapse Analytics and your data engineers can write T-SQL queries that use those models to make predictions against tabular data stored in a SQL Pool database table.

In this lab, you will create several machine learning models and use them to make predictions using the T-SQL `Predict` statement.

For context, the following are the high level steps taken to create a Spark ML based model and deploy it so it is ready for use from T-SQL.

![The process for registering and using a model](media/lab06-machine-learning-process.png "Review model registration process")

All of the steps are performed within your Azure Synapse Analytics Studio.

- Within a notebook, a data scientist will:

  a. Train a model using Spark ML, the machine learning library included with Apache Spark. Models can also be trained using other approaches, including by using Azure Machine Learning automated ML. The main requirement is that the model format must be supported by ONNX.

  b. Convert the model to the ONNX format using the `onnxml` tools.

  c. Save a hexadecimal encoded version of the ONNX model to a table in the SQL Pool database. This is an interim step while this feature is in preview.

- To use the model for making predictions, in a SQL Script a data engineer will:

  a. Read the model into a binary variable by querying it from the table in which it was stored.

  b. Execute a query using the `FROM PREDICT` statement as you would a table. This statement defines both the model to use and the query to execute that will provide the data used for prediction. You can then take these predictions and insert them into a table for use by downstream analytics applications.

> What is ONNX? [ONNX](https://onnx.ai/) is an acronym for the Open Neural Network eXchange and is an open format built to represent machine learning models, regardless of what frameworks were used to create the model. This enables model portability, as models in the ONNX format can be run using a wide variety of frameworks, tools, runtimes and platforms. Think of it like a universal file format for machine learning models.

## Exercise 1 - Training models

Open the `ASAL400 - Lab 06` notebook (located in the `Develop` hub, under `Notebooks` in Synapse Studio) and run it step by step to complete this exercise. Some of the most important tasks you will perform are:

- Exploratory data analysis (basic stats)
- Use PCA for dimensionality reduction
- Train ensemble of trees classifier (using XGBoost)
- Train classifier using Auto ML

Please note that each of these tasks will be addressed through several cells in the notebook.

## Exercise 2 - Registering and using models in Syanpse Analytics

### Task 1 - Registering the models with Azure Synapse Analytics

In this task, you will register the models in Azure Synapse Analytics so that they are availble for use from T-SQL. This task picks up where you left off, with the ONNX model being made available in Azure Storage. 

1.  One step that is not shown by the notebook is an offline step that converts the ONNX model to hexadecimal. The resulting hex encoded model is also upload to Azure Storage. This conversion is currently performed with [this PowerShell script](./../artifacts/day-03/lab-06-machine-learning/convert-to-hex.ps1), but could be automated using any scripting platform.

2. Open Synapse Analytics Studio, and then navigate to the `Data` hub.

3. Expand the Databases listing, right click your SQL Pool and then select `New SQL Script`, and then `Empty script`.

   ![Showing the context menu, selecting New SQL Script, Empty Script](media/lab06-new-sql-script.png "Create new script")

4. Replace the contents of this script with following. Be sure to replace the place holder values identified by the comments with the appropriate values from your environment.

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

-- Register the model by inserting it into the table.
-- Replace <Model description> with your user friendly description of the model.
INSERT INTO [wwi_ml].[MLModel]
SELECT Model, '<Model description>'
FROM [wwi_ml].[MLModelExt]

```

4. This script uses PolyBase to load the hex encoded model from Azure Storage into a table within the SQL Pool database. Once the model is inserted into the table in this way, it is available for use by the Predict statement as you will see next.


## Task 2 - Making predictions with the registered models

In this task, you will author a T-SQL query that uses the previously trained models to make predictions.

1. Open Synapse Analytics Studio, and then navigate to the `Data` hub.

2. Expand the Databases listing, right click your SQL Pool and then select `New SQL Script`, and then `Empty script`.

   ![Showing the context menu, selecting New SQL Script, Empty Script](media/lab06-new-sql-script.png "Create new script")


3. Replace the contents of this script with following:

   ```sql
   -- Retrieve the latest hex encoded ONNX model from the table
   DECLARE @model varbinary(max) = (SELECT Model FROM [wwi_ml].[MLModel] WHERE Id = (SELECT Top(1) max(ID) FROM [wwi_ml].[MLModel]));

   -- Run a prediction query
   SELECT d.*, p.*
   FROM PREDICT(MODEL = @model, DATA = [wwi_ml].[SampleData] AS d) WITH (prediction real) AS p;
   ```

4. Select **Run** from the menubar.

   ![The Run button](media/lab06-select-run.png "Select Run")

5. View the results, notice that the `Prediction` column is the model's prediction of how many items of the kind represented by `StockItemKey` that the customer identified by `CustomerKey` will purchase.

   ![Viewing the prediction results in the query result pane](media/lab06-view-prediction-results.png "View prediction results")

