CREATE TABLE [wwi_ml].[AMLModel]
( 
	[ID] [nvarchar](1024)  NOT NULL,
	[name] [nvarchar](1024)  NOT NULL,
	[description] [nvarchar](1024)  NULL,
	[version] [int]  NULL,
	[created_time] [datetime2](7)  NULL,
	[created_by] [nvarchar](128)  NULL,
	[framework] [nvarchar](64)  NULL,
	[model] [varbinary](max)  NULL,
	[inputs_schema] [nvarchar](max)  NULL,
	[outputs_schema] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	HEAP
)
GO
