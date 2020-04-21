# DW Optimization Part 1

```
Optimizing Warehouse Performance
Optimizing a set of slow queries
Diagnosing with explain
Reviewing and recommending changes to partitioning, distribution and indexing
Improving JSON query performance
Improving count performance
Materialized view vs Result-set caching

```

`<TBA>`
Explicit instructions on scaling up to DW1500 before the lab and scaling back after Lab 04 is completed.
`</TBA>`

## Exercise 1 - Explore query performance and improve table structure

### Task 1 - Identify performance issues related to tables

1. In `Synapse Studio`, open a new SQL script and run the following statement:

    ```sql
    SELECT  
        COUNT_BIG(*)
    FROM
        [wwi_perf].[Sale_Heap]
    ```

    The script takes up to 30 seconds to execute and returns a count of 2.89 billion rows in the table.

2. Run the following (more complex) statement:

    ```sql
    SELECT TOP 100 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Heap] S
        GROUP BY
            S.CustomerId
    ) T

    ```
    The script takes up to a minute to execute and returns the result. There is clearly something wrong with the `Sale_Heap` table that induces the performance hit.

3. Check the structure of the `Sale_Heap` table, by right clicking on it in the `Data` bub and selecting `New SQL script` and then `CREATE`. Take a look at the script used to create the table:

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Heap]
    ( 
        [TransactionId] [uniqueidentifier]  NOT NULL,
        [CustomerId] [int]  NOT NULL,
        [ProductId] [smallint]  NOT NULL,
        [Quantity] [smallint]  NOT NULL,
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
    ```
    You can immediately spot at least two reasons for the performance hit:
    - The `ROUND_ROBIN` distribution
    - The `HEAP` structure of the table

    `<TBA>`
    Note explaining the use of HEAP tables as targets for data import.
    `</TBA>`

4. Run the same script as the one you've run at step 2, but this time with the `EXPLAIN WITH_RECOMMENDATIONS` line before it:

    ```sql
    EXPLAIN WITH_RECOMMENDATIONS
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Heap] S
        GROUP BY
            S.CustomerId
    ) T
    ```
    The `EXPLAIN WITH_RECOMMENDATIONS` clause eturns the query plan for an Azure Synapse Analytics SQL statement without running the statement. Use EXPLAIN to preview which operations will require data movement and to view the estimated costs of the query operations. Your query should return something similar to:

    ```xml
    <?xml version=""1.0"" encoding=""utf-8""?>
    <dsql_query number_nodes=""4"" number_distributions=""60"" number_distributions_per_node=""15"">
    <sql>SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Heap] S
        GROUP BY
            S.CustomerId
    ) T</sql>
    <materialized_view_candidates>
        <materialized_view_candidates with_constants=""False"">CREATE MATERIALIZED VIEW View1 WITH (DISTRIBUTION = HASH([Expr0])) AS
    SELECT [S].[CustomerId] AS [Expr0],
        SUM([S].[TotalAmount]) AS [Expr1]
    FROM [wwi_perf].[Sale_Heap]
    GROUP BY [S].[CustomerId]</materialized_view_candidates>
    </materialized_view_candidates>
    <dsql_operations total_cost=""8.583172"" total_number_operations=""5"">
        <dsql_operation operation_type=""RND_ID"">
        <identifier>TEMP_ID_76</identifier>
        </dsql_operation>
        <dsql_operation operation_type=""ON"">
        <location permanent=""false"" distribution=""AllDistributions"" />
        <sql_operations>
            <sql_operation type=""statement"">CREATE TABLE [qtabledb].[dbo].[TEMP_ID_76] ([CustomerId] INT NOT NULL, [col] DECIMAL(38, 2) NOT NULL ) WITH(DISTRIBUTED_MOVE_FILE='');</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type=""SHUFFLE_MOVE"">
        <operation_cost cost=""8.583172"" accumulative_cost=""8.583172"" average_rowsize=""13"" output_rows=""41265.25"" GroupNumber=""11"" />
        <source_statement>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT SUM([T2_1].[TotalAmount]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [SQLPool02].[wwi_perf].[Sale_Heap] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
    OPTION (MAXDOP 4, MIN_GRANT_PERCENT = [MIN_GRANT], DISTRIBUTED_MOVE(N''))</source_statement>
        <destination_table>[TEMP_ID_76]</destination_table>
        <shuffle_columns>CustomerId;</shuffle_columns>
        </dsql_operation>
        <dsql_operation operation_type=""RETURN"">
        <location distribution=""AllDistributions"" />
        <select>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT TOP (CAST ((1000) AS BIGINT)) SUM([T2_1].[col]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [qtabledb].[dbo].[TEMP_ID_76] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
    OPTION (MAXDOP 4, MIN_GRANT_PERCENT = [MIN_GRANT])</select>
        </dsql_operation>
        <dsql_operation operation_type=""ON"">
        <location permanent=""false"" distribution=""AllDistributions"" />
        <sql_operations>
            <sql_operation type=""statement"">DROP TABLE [qtabledb].[dbo].[TEMP_ID_76]</sql_operation>
        </sql_operations>
        </dsql_operation>
    </dsql_operations>
    </dsql_query>
    ```

    The query plan indicates data movement is required.
    `<TBA>`
    Note explaining the query plan structure.
    `</TBA>`


### Task 2 - Improve table structure with hash distribution and columnstore index

1. Create an improved version of the table using CTAS:

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Hash]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX
    )
    AS
    SELECT
        *
    FROM	
        [wwi_perf].[Sale_Heap]
    ```
    The query will take about 10 minutes to complete.

2. Run the query again to see the performance improvements:

    ```sql
    SELECT TOP 100 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Hash] S
        GROUP BY
            S.CustomerId
    ) T
    ```

3. Increase the complexity of the query and run it again:

    ```sql
    SELECT TOP 100 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Month
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Hash] S
            join [wwi].[Date] D on 
                D.DateId = S.TransactionDateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Month
    ) T
    ```

### Task 3 - Improve further the structure of the table with partitioning

1. Use CTAS to create an improved copy of the table:

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Hash]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX
    )
    AS
    SELECT
        *
    FROM	
        [wwi_perf].[Sale_Heap]
    OPTION  (LABEL  = 'CTAS : Sale_Hash')

    CREATE TABLE [wwi_perf].[Sale_Partition01]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX,
        PARTITION
        (
            [TransactionDateId] RANGE RIGHT FOR VALUES (
                20100101, 20100201, 20100301, 20100401, 20100501, 20100601, 20100701, 20100801, 20100901, 20101001, 20101101, 20101201, 
                20110101, 20110201, 20110301, 20110401, 20110501, 20110601, 20110701, 20110801, 20110901, 20111001, 20111101, 20111201, 
                20120101, 20120201, 20120301, 20120401, 20120501, 20120601, 20120701, 20120801, 20120901, 20121001, 20121101, 20121201, 
                20130101, 20130201, 20130301, 20130401, 20130501, 20130601, 20130701, 20130801, 20130901, 20131001, 20131101, 20131201, 
                20140101, 20140201, 20140301, 20140401, 20140501, 20140601, 20140701, 20140801, 20140901, 20141001, 20141101, 20141201, 
                20150101, 20150201, 20150301, 20150401, 20150501, 20150601, 20150701, 20150801, 20150901, 20151001, 20151101, 20151201, 
                20160101, 20160201, 20160301, 20160401, 20160501, 20160601, 20160701, 20160801, 20160901, 20161001, 20161101, 20161201, 
                20170101, 20170201, 20170301, 20170401, 20170501, 20170601, 20170701, 20170801, 20170901, 20171001, 20171101, 20171201, 
                20180101, 20180201, 20180301, 20180401, 20180501, 20180601, 20180701, 20180801, 20180901, 20181001, 20181101, 20181201, 
                20190101, 20190201, 20190301, 20190401, 20190501, 20190601, 20190701, 20190801, 20190901, 20191001, 20191101, 20191201)
        )
    )
    AS
    SELECT
        *
    FROM	
        [wwi_perf].[Sale_Heap]
    OPTION  (LABEL  = 'CTAS : Sale_Partition01')

    CREATE TABLE [wwi_perf].[Sale_Partition02]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX,
        PARTITION
        (
            [TransactionDateId] RANGE RIGHT FOR VALUES (
                20100101, 20100401, 20100701, 20101001, 
                20110101, 20110401, 20110701, 20111001, 
                20120101, 20120401, 20120701, 20121001, 
                20130101, 20130401, 20130701, 20131001, 
                20140101, 20140401, 20140701, 20141001, 
                20150101, 20150401, 20150701, 20151001, 
                20160101, 20160401, 20160701, 20161001, 
                20170101, 20170401, 20170701, 20171001, 
                20180101, 20180401, 20180701, 20181001, 
                20190101, 20190401, 20190701, 20191001)
        )
    )
    AS
    SELECT
        *
    FROM	
        [wwi_perf].[Sale_Heap]
    OPTION  (LABEL  = 'CTAS : Sale_Partition02')
    ```

2. Notice the two partitioning strategies we've used here. You will explore in Lab 04 the subtle differences between these and understand why one of them helps performance and the other one actually hurts it.

## Exercise 2 - Improve query perofrmance

### Task 1 - Improve JSON query performance

`<TBA>`
Improve JSON query performance
`</TBA>`


### Task 2 -  Improve COUNT performance

1. Count the distinct customer values in `Sale_Heap`:

    ```sql
    SELECT COUNT( DISTINCT CustomerId) from wwi_perf.Sale_Heap
    ```

    Query takes about 20 seconds to execute.

2. Run the HyperLogLog approach:

    ```sql
    SELECT APPROX_COUNT_DISTINCT(CustomerId) from wwi_perf.Sale_Heap 
    ```

    Query takes about half the time to execute.

### Task 3 - Use materialized views

### Task 4 - Use result set caching

### Task 5 - Use ordered CCI

### Task 6 - Create and update statistics

### Task 7 - Create and update indexes