CREATE EXTERNAL TABLE [wwi_ml].[MLModelExt]
(
[Model] [varbinary](max) NULL
)
WITH
(
LOCATION='/ml/onnx-hex' ,
DATA_SOURCE = ModelStorage ,
FILE_FORMAT = csv ,
REJECT_TYPE = VALUE ,
REJECT_VALUE = 0
)
GO