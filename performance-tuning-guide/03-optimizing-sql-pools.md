# 3. Optimizing SQL Pools

## 3.1. Sizing and resource allocation (DWUs)

A Synapse SQL Pool Data Warehousing Unit (DWU) is a **high-level representation of usage** that consists of a combination of CPU, memory, and IO resources. To determine the number of DWUs to select is to strike a balance between price and performance. When creating or scaling a SQL Pool, you can select from a range of 100 cDWU (DW100c) up to 30,000 cDWU (DW30000c). (`cDWU` is defined as compute Data Warehouse Unit.)

The general guidance is to start small, monitor your workload, and adjust as needed. You can surface valuable performance metrics by leveraging the monitoring `Metrics` feature of the SQL Pool, as well as by taking advantage of a series of `Dynamic Management Views (DMVs)`. Using these tools will help you monitor your SQL workload and provide the insight necessary to make an educated decision on whether scaling your SQL Pool would be beneficial.

### 3.1.1. Memory Usage

Inadequate memory allocation is a common source of performance issues. You are able to compare current memory usage versus total memory available in the SQL Pool through the use of the `sys.dm_pdw_nodes_os_performance_counters` DMV. If you see the memory usage approaching the limit, it is time to scale up.

    ```sql
    -- Memory consumption
    SELECT
        pc1.cntr_value as Curr_Mem_KB,
        pc1.cntr_value/1024.0 as Curr_Mem_MB,
        (pc1.cntr_value/1048576.0) as Curr_Mem_GB,
        pc2.cntr_value as Max_Mem_KB,
        pc2.cntr_value/1024.0 as Max_Mem_MB,
        (pc2.cntr_value/1048576.0) as Max_Mem_GB,
        pc1.cntr_value * 100.0/pc2.cntr_value AS Memory_Utilization_Percentage,
        pc1.pdw_node_id
    FROM
        -- pc1: current memory
        sys.dm_pdw_nodes_os_performance_counters AS pc1
        -- pc2: total memory allowed for this SQL instance
        JOIN sys.dm_pdw_nodes_os_performance_counters AS pc2
            ON pc1.object_name = pc2.object_name AND pc1.pdw_node_id = pc2.pdw_node_id
    WHERE
        pc1.counter_name = 'Total Server Memory (KB)'
        AND pc2.counter_name = 'Total Server Memory (KB)'
    ```

### 3.1.2. Transaction log size

Another aspect that should be monitored is the size of the transaction log. If it is determined that a log file is reaching 160 GB in size, you should consider scaling up or reducing the transaction size of your workload. You can monitor the transaction log size through the `sys.dm_pdw_nodes_os_performance_counters` DMV.

    ```sql
    -- Transaction log size
    SELECT
        instance_name as distribution_db,
        cntr_value*1.0/1048576 as log_file_size_used_GB,
        pdw_node_id
    FROM 
        sys.dm_pdw_nodes_os_performance_counters
    WHERE
        instance_name like 'Distribution_%'
        AND counter_name = 'Log File(s) Used Size (KB)'
    ```

### 3.1.3. Tempdb usage

`Tempdb` is used to hold intermediate results during query execution. For each 100 cDWUs allocated in your pool, there is 399 GB of tempdb space available. By using several DMVs in conjunction with the `microsoft.vw_sql_requests` view you can determine if the workload you are running is trending toward capacity.

    ```sql
    -- Monitor tempdb
    SELECT
        sr.request_id,
        ssu.session_id,
        ssu.pdw_node_id,
        sr.command,
        sr.total_elapsed_time,
        es.login_name AS 'LoginName',
        DB_NAME(ssu.database_id) AS 'DatabaseName',
        (es.memory_usage * 8) AS 'MemoryUsage (in KB)',
        (ssu.user_objects_alloc_page_count * 8) AS 'Space Allocated For User Objects (in KB)',
        (ssu.user_objects_dealloc_page_count * 8) AS 'Space Deallocated For User Objects (in KB)',
        (ssu.internal_objects_alloc_page_count * 8) AS 'Space Allocated For Internal Objects (in KB)',
        (ssu.internal_objects_dealloc_page_count * 8) AS 'Space Deallocated For Internal Objects (in KB)',
        CASE es.is_user_process
        WHEN 1 THEN 'User Session'
        WHEN 0 THEN 'System Session'
        END AS 'SessionType',
        es.row_count AS 'RowCount'
    FROM sys.dm_pdw_nodes_db_session_space_usage AS ssu
        INNER JOIN sys.dm_pdw_nodes_exec_sessions AS es ON ssu.session_id = es.session_id AND ssu.pdw_node_id = es.pdw_node_id
        INNER JOIN sys.dm_pdw_nodes_exec_connections AS er ON ssu.session_id = er.session_id AND ssu.pdw_node_id = er.pdw_node_id
        INNER JOIN microsoft.vw_sql_requests AS sr ON ssu.session_id = sr.spid AND ssu.pdw_node_id = sr.pdw_node_id
    WHERE DB_NAME(ssu.database_id) = 'tempdb'
        AND es.session_id <> @@SPID
        AND es.login_name <> 'sa'
        ORDER BY sr.request_id;
    ```

### 3.1.4. Azure Synapse SQL pool metrics

As an alternative to using the DMVs, you can also access the `Metrics` feature of the SQL Pool to obtain insight into DWU, tempdb, and memory usage. Access the `Metrics` feature by navigating to your SQL Pool resource in the Azure Portal, then from the left menu beneath the `Monitoring` heading, you will find the `Metrics` item. Here, you are able to create your own dashboards and compose useful chart visualizations.

    ![The available metrics of the SQL Pool are displayed.](media/sqlpool_availablemetrics.png "Available SQL Pool Metrics")

    ![A sample performance metric chart is shown plotting DWU limit, DWU used (max) and memory used percentage.](media/sampleperformancemetricchart.png "Sample performance metric chart")

Scaling the size of your SQL Pool is definitely one way to improve the performance. It is critical, however, to also look into other root causes that may be affecting performance. Evaluating table structure, indexes, result set caching, etc. can also provide valuable insight into performance issues that may be solved without incurring the additional cost of scaling the pool.

## 3.2. Manage indexes

Synapse SQL pools provide the following index types `clustered columnstore`, `heap`, `clustered and nonclustered`.

The `clustered columnstore` index is the default index added to SQL pool tables when no other index is specified. This type of index yields the highest level of performance and compression on large tables. When unsure of which type of index to use, it is recommended to start with a clustered columnstore index. There exists scenarios where clustered columnstore indexes are not a good option, for instance:

    - clustered columnstore tables do not support varchar(max), nvarchar(max) and varbinary(max). If you require these types of columns, utilize heap or a clustered index instead.
    - clustered columnstore tables are ineffective for transient data. If requiring this use case, consider using a heap or temporary table.
    - when the total number of rows is less than 60 million, it is recommended to utilize heap tables.

Another flavor of the `clustered columnstore` index is the `ordered clustered columnstore` index. In a clustered columnstore index, data in each column is compressed into a separate CCI rowgroup segments. There's metadata on each segment's value range, so segments that are outside the bounds of the query predicate aren't read from disk during query execution. CCI offers the highest level of data compression and reduces the size of segments to read so queries can run faster. However, because the index builder doesn't sort data before compressing them into segments, segments with overlapping value ranges could occur, causing queries to read more segments from disk and take longer to finish.

When creating an ordered CCI, the Synapse SQL engine sorts the existing data in memory by the order key(s) before the index builder compresses them into index segments. With sorted data, segment overlapping is reduced allowing queries to have a more efficient segment elimination and thus faster performance because the number of segments to read from disk is smaller. If all data can be sorted in memory at once, then segment overlapping can be avoided. Due to large tables in data warehouses, this scenario doesn't happen often.

Queries with the following patterns typically run faster with ordered CCI:

    - The queries have equality, inequality, or range predicates
    - The predicate columns and the ordered CCI columns are the same.
    - The predicate columns are used in the same order as the column ordinal of ordered CCI columns.

`Heap` tables are widely used during data load operations as staging tables. This is because a heap table is faster to index and subsequent reads can take advantage of caching. When using a heap table as opposed to a clustered columnstore table because the total row count is less than 60 million rows, you will see greater performance with the heap index.

`Clustered and nonclustered indexes` may outperform the clustered columnstore index when a single row (or very few rows) are returned from a query. It is important to note that this type of index is only meaningful with a very selective filter using the clustered index column. Clustered index table performance can be improved by adding a secondary nonclustered index. In reality, you can add nonclustered indexes on multiple columns that may be used in a filter, but this doesn't come without a tradeoff. For every index added to a table, it increases both the space used by the table and the processing load times.

| Table Indexing | Recommended use |
|--------------|-------------|
| Clustered Columnstore | Recommended for tables with greater than 60 million rows, offers the highest data compression with best overall query performance. |
| Heap Tables | Smaller tables with less than 60 million rows, commonly used as a staging table prior to transformation. |
| Clustered Index | Large lookup tables (> 60 million rows) where querying will only result in a single row returned. |
| Clustered Index + nonclustered secondary index(es) | Large tables (> 60 million rows) when single (or very few) records are being returned in queries. |

### 3.2.1. Create and update indexes

To demonstrate the different types of indexing approaches, we will use a scenario-based demonstration. In this example, consider a Sale table that has approximately 340 million records. We will first establish the performance of a query when returning the sales for a specific customer.

First, let's compare the retrieval of sales data from a single customer from the table with a CCI (clustered column index), with that of a table with a clustered index.

CCI:

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[Sale_Hash]
    WHERE
        CustomerId = 500000
    ```

Clustered Index:

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[Sale_Index]
    WHERE
        CustomerId = 500000
    ```

The observed execution time of both queries is similar. Clustered columnstore indexes have no significant advantage over clustered indexes in this specific scenario of a highly selective query.

Let's test these table indexes further retrieving the sales of multiple customers from the table with CCI:

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[Sale_Hash]
    WHERE
        CustomerId between 400000 and 400100
    ```

The similar query on the clustered index table:

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[Sale_Index]
    WHERE
        CustomerId between 400000 and 400020
    ```

These queries were run multiple times until there was a stable execution time. It was observed that even with a relatively small number of customers, the CCI table starts yielding better performance than the clustered index table.

The next experiment will be adding an additional `StoreId` query filter to the query on the clustered index table.

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[Sale_Index]
    WHERE
        CustomerId between 400000 and 400020
        and StoreId between 2000 and 4000
    ```

We will now a add a secondary non-clustered index on the `StoreId` column.

    ```sql
    CREATE INDEX Store_Index on wwi_perf.Sale_Index (StoreId)
    ```

The creation of the index, as well as the indexing process takes a few minutes to complete. Now when the query is run, there is a considerable improvement in execution time, a direct result of adding the secondary nonclustered index.

### 3.2.2. Ordered Clustered Columnstore Indexes

We've already learned that in some circumstances, primarily surrounding filtering, that an order clustered columnstore index can provide better performance. In order to obtain optimal query performance, it's important to investigate the data segments created by the ordered clustered columnstore index to ensure that there is very little to no overlap. Having overlap in the data segments increases read times and adversely affects performance.

Returning to our scenario, let's look into the segment overlaps for the clustered columnstore index table, `Sale_Hash`.

        ```sql
        select
            OBJ.name as table_name
            ,COL.name as column_name
            ,NT.distribution_id
            ,NP.partition_id
            ,NP.rows as partition_rows
            ,NP.data_compression_desc
            ,NCSS.segment_id
            ,NCSS.version
            ,NCSS.min_data_id
            ,NCSS.max_data_id
            ,NCSS.row_count
        from 
            sys.objects OBJ
            JOIN sys.columns as COL ON
                OBJ.object_id = COL.object_id
            JOIN sys.pdw_table_mappings TM ON
                OBJ.object_id = TM.object_id
            JOIN sys.pdw_nodes_tables as NT on
                TM.physical_name = NT.name
            JOIN sys.pdw_nodes_partitions NP on
                NT.object_id = NP.object_id
                and NT.pdw_node_id = NP.pdw_node_id
                and substring(TM.physical_name, 40, 10) = NP.distribution_id
            JOIN sys.pdw_nodes_column_store_segments NCSS on
                NP.partition_id = NCSS.partition_id
                and NP.distribution_id = NCSS.distribution_id
                and COL.column_id = NCSS.column_id
        where
            OBJ.name = 'Sale_Hash'
            and COL.name = 'CustomerId'
            and TM.physical_name  not like '%HdTable%'
        order by
            NT.distribution_id
        ```

Here is an overview of the tables involved in this query:

    Table Name | Description
    ---|---
    sys.objects | All objects in the database. Filtered to match only the `Sale_Hash` table.
    sys.columns | All columns in the database. Filtered to match only the `CustomerId` column of the `Sale_Hash` table.
    sys.pdw_table_mappings | Maps each table to local tables on physical nodes and distributions.
    sys.pdw_nodes_tables | Contains information on each local table in each distribution.
    sys.pdw_nodes_partitions | Contains information on each local partition of each local table in each distribution.
    sys.pdw_nodes_column_store_segments | Contains information on each CCI segment for each partition and distribution column of each local table in each distribution. Filtered to match only the `CustomerId` column of the `Sale_Hash` table.

![CCI segment structure on each distribution](./media/lab3_ordered_cci.png)

The result of the query shows a significant overlap between segments. There is overlap in customer ids between every single pair of segments (`CustomerId` values in the data range from 1 to 1,000,000). The segment structure of this CCI is clearly inefficient and will result in a lot of unnecessary reads from storage.

Let's now compare the segment overlaps for the same table, but with an ordered clustered columnstore index (the `Sale_Hash_Ordered` table).

    ```sql
    select 
        OBJ.name as table_name
        ,COL.name as column_name
        ,NT.distribution_id
        ,NP.partition_id
        ,NP.rows as partition_rows
        ,NP.data_compression_desc
        ,NCSS.segment_id
        ,NCSS.version
        ,NCSS.min_data_id
        ,NCSS.max_data_id
        ,NCSS.row_count
    from 
        sys.objects OBJ
        JOIN sys.columns as COL ON
            OBJ.object_id = COL.object_id
        JOIN sys.pdw_table_mappings TM ON
            OBJ.object_id = TM.object_id
        JOIN sys.pdw_nodes_tables as NT on
            TM.physical_name = NT.name
        JOIN sys.pdw_nodes_partitions NP on
            NT.object_id = NP.object_id
            and NT.pdw_node_id = NP.pdw_node_id
            and substring(TM.physical_name, 40, 10) = NP.distribution_id
        JOIN sys.pdw_nodes_column_store_segments NCSS on
            NP.partition_id = NCSS.partition_id
            and NP.distribution_id = NCSS.distribution_id
            and COL.column_id = NCSS.column_id
    where
        OBJ.name = 'Sale_Hash_Ordered'
        and COL.name = 'CustomerId'
        and TM.physical_name  not like '%HdTable%'
    order by
        NT.distribution_id
    ```
The end result shows significantly less overlap between segments:

    ![CCI segment structure on each distribution with ordered CCI](./media/lab3_ordered_cci_2.png)

Let's dive into the creation of the `wwi_perf.Sale_Hash_Ordered` for a moment. The CTAS that was used to create the table was the following:

    ```sql
        CREATE TABLE [wwi_perf].[Sale_Hash_Ordered]
        WITH
        (
            DISTRIBUTION = HASH ( [CustomerId] ),
            CLUSTERED COLUMNSTORE INDEX ORDER( [CustomerId] )
        )
        AS
        SELECT
            *
        FROM
            [wwi_perf].[Sale_Heap]
        OPTION  (LABEL  = 'CTAS : Sale_Hash', MAXDOP 1)
    ```

Notice the ordered CCI was created with MAXDOP = 1. Each thread used for ordered CCI creation works on a subset of data and sorts it locally. There's no global sorting across data sorted by different threads. Using parallel threads can reduce the time to create an ordered CCI but will generate more overlapping segments than using a single thread. Currently, the MAXDOP option is only supported in creating an ordered CCI table using CREATE TABLE AS SELECT command. Creating an ordered CCI via CREATE INDEX or CREATE TABLE commands does not support the MAXDOP option.

## 3.3. Table structure

The structure of your tables plays a critical role in the overall performance of a data warehouse. Appropriate table distribution and partitioning are vital to performance.

A distributed table appears as a single table, but behind the scenes its rows are stored across 60 distributions. Factors that decide the best table distribution are its size and how often the data in the table changes. In Azure Synapse Analytics the options for distributed tables are Hash-distributed, round-robin, and replicated.

In a `hash-distributed` model, rows are distributed across distribution using a deterministic hash function applied on a specific column value. This means identical values will always be stored in the same distribution. Using this intrinsic knowledge, the SQL pool is able to minimize data movement and improve query performance. Hash-distributed tables are best for large fact tables that are greater than 2 GB in size and experiences frequent changes. When defining a hash-distributed table, choosing an appropriate distribution column is essential. Consider these factors when deciding on a distribution column:

    - choose a column whose data will distribute evenly and has many unique values. Remember these rows are being stored across 60 distributions, if the hash results in a large percentage of values being assigned to a single distribution, it will impact performance.
    - choose a column that has no or very few NULL values    
    - choose a column that is commonly used in JOIN, GROUP BY, DISTINCT, OVER and HAVING clauses
    - avoid columns **not** being used in WHERE clauses
    - avoid date columns (if many users are filtering by common date ranges it would negate the benefits of the distribution)

If none of the columns of the table seem to be an ideal candidate for a distribution column. Consider creating a new column that is a composite of two or more column values. If this is the approach taken, take care to include the composite column in JOIN queries to minimize data movement.

A `round-robin` distributed table has all of its rows evenly distributed across all 60 distributions. Identical values are not guaranteed to fall into the same distribution, and it is more common-place for data movement to occur in the process of executing a query, which may affect performance. Consider round-robin distribution when:

    - there is no obvious joining key, or the join is less significant
    - there isn't an adequate candidate column for hash-distribution
    - the table is a temporary staging table

A `replicated` table should be reserved for smaller, commonly used lookup tables that are less than 1.5 GB in size.

Proper table partitioning can also provide improved performance. A partition divides data into smaller groups. Partitioning is supported on all Synapse SQL pool table types and distributions. Partitions are defined by a single column which is most commonly a date column. When loading large amounts of data, leveraging partitions reduces the amount of transaction logging, thus improving performance. The same can be said when deleting large amounts of data. Deleting data by partition is substantially faster than deleting a large amount of data row-by-row. As for querying performance, using a partition column in query filters limits the scan to that single partition, avoiding costly full table scans.

As an example, we'll walk through the following example scenario to demonstrate how to investigate and identify performance issues.

Identifying there is a problem is the first step in rectifying it. For instance, consider the following query:

    ```sql
    SELECT  
        COUNT_BIG(*)
    FROM
        [wwi_perf].[Sale_Heap]
    ```

This simple query took about 30 seconds to execute and returned a count of approximately 340 million rows from the table. That isn't too bad, there doesn't seem to be a problem. However, this next query which is executed on the same table took a couple minutes to return:

    ```sql
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
    OPTION (LABEL = 'Lab03: Heap')
    ```

There is clearly something wrong with the `Sale_Heap` table that introduces a performance hit.

    > **Note**: the OPTION clause used in the statement. This comes in handy when you're looking to identify your query in the [sys.dm_pdw_exec_requests](https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-pdw-exec-requests-transact-sql) DMV.
    >
    >```sql
    >SELECT  *
    >FROM    sys.dm_pdw_exec_requests
    >WHERE   [label] = 'Lab03: Heap';
    >```

The `Sale_Heap` table was created as a `HEAP` table with a `ROUND_ROBIN` distribution.

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

    > **NOTE**: In this case, when we are looking for fast query response times, the heap structure is not a good choice as we will see in a moment. Still, there are cases where using a heap table can be beneficial to performance rather than hurting it. A beneficial application of a heap table is when we're looking to ingest large amounts of data into the SQL pool.

To gain further insight into the degradation of performance, we can issue the same query with the `EXPLAIN WITH_RECOMMENDATIONS` clause. The `EXPLAIN WITH_RECOMMENDATIONS` clause returns the query plan for an Azure Synapse Analytics SQL statement without actually running the statement. Use this query plan to preview which operations will require data movement and to view the estimated costs of the query operations. By default, you will get the execution plan in XML format, but you can also export to other formats like CSV or JSON.

    > **TIP**: Do not select `Query Plan` from the toolbar as it will try do download the query plan and open it in SQL Server Management Studio. 

If we run the longer executing script from our scenario, but this time with the `EXPLAIN WITH_RECOMMENDATIONS` clause:

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

The query will return:

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
        <source_statement>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT SUM([T2_1].[TotalAmount]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [SQLPool01].[wwi_perf].[Sale_Heap] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
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

Notice the details of the internal layout of the MPP system:

`<dsql_query number_nodes=""4"" number_distributions=""60"" number_distributions_per_node=""15"">`

This layout is given by the current Date Warehouse Units (DWU) setting. In the setup used for the example above, we were running at `DW2000c` which means that there are 4 physical nodes to service the 60 distributions, giving a number of 15 distributions per physical node. Depending on your own DWU settings, these numbers will vary.

The query plan indicates data movement is required. This is indicated by the `SHUFFLE_MOVE` distributed SQL operation. Data movement is an operation where parts of the distributed tables are moved to different nodes during query execution. This operation is required where the data is not available on the target node, most commonly when the tables do not share the distribution key. The most common data movement operation is shuffle. During shuffle, for each input row, Synapse computes a hash value using the join columns and then sends that row to the node that owns that hash value. Either one or both sides of join can participate in the shuffle. The diagram below displays shuffle to implement join between tables T1 and T2 where neither of the tables is distributed on the join column col2.

![Shuffle move conceptual representation](./media/lab3_shuffle_move.png)

Let's dive into the details provided by the query plan to understand some of the problems of our current approach. The following table contains the description of every operation mentioned in the query plan:

Operation | Operation Type | Description
---|---|---
1 | RND_ID | Identifies an object that will be created. In our case, it's the `TEMP_ID_76` internal table.
2 | ON | Specifies the location (nodes or distributions) where the operation will occur. `AllDistributions` means here the operation will be performed on each of the 60 distributions of the SQL pool. The operation will be a SQL operation (specified via `<sql_operations>`) that will create the  `TEMP_ID_76` table.
3 | SHUFFLE_MOVE | The list of shuffle columns contains only one column which is `CustomerId` (specified via `<shuffle_columns>`). The values will be distributed to the hash owning distributions and saved locally in the `TEMP_ID_76` tables. The operation will output an estimated number of 41265.25 rows (specified via `<operation_cost>`). According to the same section, the average resulting row size is 13 bytes.
4 | RETURN | Data resulting from the shuffle operation will be collected from all distributions (see `<location>`) by querying the internal temporary table `TEMP_ID_76`.
5 | ON | The `TEMP_ID_76` will be deleted from all distributions.

It becomes clear now what is the root cause of the performance problem: the inter-distribution data movements. This is actually one of the simplest examples given the small size of the data that needs to be shuffled. You can image how much worse things become when the shuffled row size becomes larger.

You can learn more about the structure of the query plan generated by the EXPLAIN statement [here](https://docs.microsoft.com/en-us/sql/t-sql/queries/explain-transact-sql?view=azure-sqldw-latest).

An alternative to the the `EXPLAIN` statement, is the `sys.dm_pdw_request_steps` DMV. As mentioned earlier, you can query the `sys.dm_pdw_exec_requests` DMV filtering on your query label to obtain its query id. You will use this query id to retrieve the query steps through the `sys.dm_pdw_request_steps` DMV. You can obtain the query id through the label from our scenario through this query:

    ```sql
    SELECT  
        *
    FROM    
        sys.dm_pdw_exec_requests
    WHERE   
        [label] = 'Lab03: Heap'
    ```

The result contains, among other things, the query id, the label, and the original SQL statement.

    ![Retrieving the query id](./media/lab3_query_id.png)

With the query id (`QID473552` in this case) you can now investigate the individual steps of the query using the `sys.dm_pdw_request_steps` DMV.

    ```sql
    SELECT
       *
    FROM
        sys.dm_pdw_request_steps
    WHERE
        request_id = 'QID473552'
    ORDER BY
       step_index
    ```

    ![Query execution steps](./media/lab3_shuffle_move_2.png)

The steps (indexed 0 to 3) are matching operations 2 to 5 from the query plan. Again, the culprit stands out: the step with index 1 describes the inter-partition data movement operation. By looking at the `TOTAL_ELAPSED_TIME` column you can clearly tell the largest impact on query performance is caused by this step.

To gain insight into the effects of the problematic step of the query on the entire SQL Pool distribution, we can take advantage of the `sys.dm_pdw_sql_requests` DMV, filtering on the query id and step index.

    ```sql
    SELECT
    *
    FROM
        sys.dm_pdw_sql_requests
    WHERE 
        request_id = 'QID473552'
        AND step_index = 1
    ```

    ![Query execution step details](./media/lab3_shuffle_move_3.png)

Lastly, you can use the the DMV `sys.dm_pdw_dms_workers` to investigate how data is being moved at each distribution. The `ROWS_PROCESSED` column is especially useful here to get an estimate of the magnitude of the data movement happening when the query is executed.

    ```sql
    SELECT
        *
    FROM
        sys.dm_pdw_dms_workers
    WHERE
        request_id = 'QID473552'
        AND step_index = 1
    ORDER BY
        distribution_id
    ```

    ![Query execution step data movement](./media/lab3_shuffle_move_4.png)

### 3.3.1. Improve table structure with distribution

Now that we've identified the root problem of our performance woes, we are better equipped to fixing it. We've observed that the Sale_Heap table has approximately 340 million records, which exceeds the recommended maximum size of a Heap table, which is 60 million. It is recommended that we move this data from a heap table to a clustered columnstore table. We can also identify that the CustomerId column identifies as an ideal hash column candidate. The CustomerId column would not contain nulls, and would be predominantly used in JOIN, GROUP BY, DISTINCT, OVER, HAVING  and WHERE clauses.

In this scenario, we already have the Sale_Hash CCI table. It was created using the existing heap table data using the following CTAS (Create Table As Select) statement:

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

The creation of this table took approximately 10 minutes to complete and index (on 340 million rows).

    > **Note**: CTAS is a more customizable version of the SELECT...INTO statement.
    >SELECT...INTO doesn't allow you to change either the distribution method or the index type as part of the operation. You create the new table by using the default distribution type of ROUND_ROBIN, and the default table structure of CLUSTERED COLUMNSTORE INDEX.
    >With CTAS, on the other hand, you can specify both the distribution of the table data as well as the table structure type.

When the original problematic query is run again, we can see a definite performance improvement.

    ```sql
    SELECT TOP 1000 * FROM
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

We can further examine the execution of this query by repeating the EXPLAIN statement to retrieve the query plan:

    ```sql
    EXPLAIN
    SELECT TOP 1000 * FROM
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

The resulting query plan is much better than the previous one, as there is no more inter-distribution data movement involved!

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="5" number_distributions="60" number_distributions_per_node="12">
    <sql>SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Hash] S
        GROUP BY
            S.CustomerId
    ) T</sql>
    <dsql_operations total_cost="0" total_number_operations="1">
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT TOP (CAST ((1000) AS BIGINT)) SUM([T2_1].[TotalAmount]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [SQLPool01].[wwi_perf].[Sale_Hash] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
    OPTION (MAXDOP 6)</select>
        </dsql_operation>
    </dsql_operations>
    </dsql_query>
    ```

### 3.3.2. Improve table structure with partitioning

We've already learned that Date columns make good candidates for partitioning tables at the distributions level. In the case of our Sale data, the `TransactionDateId` column is an ideal choice for partitioning.

Back to our scenario, we have established two tables, Sale_Partition01 and Sale_Partition02 each populated with the 340 million rows of data. The first partitioning scheme is month-based and the second is quarter-based. The following queries show the CTAS statements used to create each table.

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Partition01]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX,
        PARTITION
        (
            [TransactionDateId] RANGE RIGHT FOR VALUES (
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

You will note the `RANGE RIGHT` terminology, this is used for time partitions, whereas using a `RANGE LEFT` is for number partitions. When running queries against these two tables, you'll realize the partitioning by quarter is better performing.

## 3.4. Query performance

### 3.4.1. Improve query performance with approximate count

COUNT queries tend to be expensive performance-wise. If you don't need an exact count and an approximate count will suffice, you can greatly improve performance by utilizing `APPROX_COUNT_DISTINCT`.

In our scenario, we can retrieve an exact count of distinct customers using the following query:

    ```sql
    SELECT COUNT( DISTINCT CustomerId) from wwi_perf.Sale_Heap
    ```

 This query takes up to 30 seconds to execute. That is expected, since distinct counts are difficult to optimize. With `APPROX_COUNT_DISTINCT`, the approximate result is returned in half the time.

    ```sql
    SELECT APPROX_COUNT_DISTINCT(CustomerId) from wwi_perf.Sale_Heap 
    ```

### 3.4.2. Improve query performance with materialized views

As opposed to a standard view, a materialized view pre-computes, stores, and maintains its data in a Synapse SQL pool just like a table with a clustered columnstore index. When a materialized view is read, it scans the index and applies changes from the delta store (where changes from the underlying tables are recorded). Here is a basic comparison between standard and materialized views:

| Comparison                     | View                                         | Materialized View
|:-------------------------------|:---------------------------------------------|:--------------------------------------------------------------|
|View definition                 | Stored in Azure data warehouse.              | Stored in Azure data warehouse. |
|View content                    | Generated each time when the view is used.   | Pre-processed and stored in Azure data warehouse during view creation.Updated as data is added to the underlying tables.|
|Data refresh                    | Always updated                               | Always updated|
|Speed to retrieve view data from complex queries     | Slow                                         | Fast  |
|Extra storage                   | No                                           | Yes |
|Syntax                          | CREATE VIEW                                  | CREATE MATERIALIZED VIEW AS SELECT |

Some benefits of a materialized view include increased performance on complex queries, especially those that have a high computational cost but return relatively small resulting data set.  The SQL pool optimizer will improve query performance transparently, including the materialized view for faster performance, even if there is no direct reference to the materialized view in the query itself. Materialized views are also low maintenance, any underlying base table data changes are automatically and synchronously updated. Beneath the surface, the materialized view stores its data in two places, a CCI table, and a delta store which tracks base data changes. A background process called a tuple mover, migrates data regularly from the delta store to the CCI. A materialized view can also be distributed differently than the underlying base tables. Materialized views support both hash and round-robin distributions, depending on the desired query, having a different distribution strategy than the underlying base tables can yield better overall performance.

In our scenario, we're going to use the quarterly partitioned table `Sale_Partition02` to compare the performance of retrieving the total amount and total profit with that of retrieving the same data leveraging a materialized view. The original queries to retrieve this information are:

    ```sql
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Quarter
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Partition02] S
            join [wwi].[Date] D on
                S.TransactionDateId = D.DateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Quarter
    ) T

    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Month
            ,SUM(S.ProfitAmount) as TotalProfit
        FROM
            [wwi_perf].[Sale_Partition02] S
            join [wwi].[Date] D on
                S.TransactionDateId = D.DateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Month
    ) T
    ```
Here is the materialized view that has been created to support both of the original queries.

    ```sql
    CREATE MATERIALIZED VIEW
        wwi_perf.mvCustomerSales
    WITH
    (
        DISTRIBUTION = HASH( CustomerId )
    )
    AS
    SELECT
        S.CustomerId
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,SUM(S.TotalAmount) as TotalAmount
        ,SUM(S.ProfitAmount) as TotalProfit
    FROM
        [wwi_perf].[Sale_Partition02] S
        join [wwi].[Date] D on
            S.TransactionDateId = D.DateId
    GROUP BY
        S.CustomerId
        ,D.Year
        ,D.Quarter
        ,D.Month
    ```

Let's take the first query and retrieve its execution plan.

    ```sql
    EXPLAIN
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Quarter
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Partition02] S
            join [wwi].[Date] D on
                S.TransactionDateId = D.DateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Quarter
    ) T
    ```

The resulting execution plan shows how the newly created materialized view is used to optimize the execution. Note the `FROM [SQLPool01].[wwi_perf].[mvCustomerSales]` in the `<dsql_operations>` element.

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="5" number_distributions="60" number_distributions_per_node="12">
    <sql>SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Quarter
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Partition02] S
            join [wwi].[Date] D on
                S.TransactionDateId = D.DateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Quarter
    ) T</sql>
    <dsql_operations total_cost="0" total_number_operations="1">
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[Year] AS [Year], [T1_1].[Quarter] AS [Quarter], [T1_1].[col] AS [col] FROM (SELECT TOP (CAST ((1000) AS BIGINT)) [T2_1].[CustomerId] AS [CustomerId], [T2_1].[Year] AS [Year], [T2_1].[Quarter] AS [Quarter], [T2_1].[col1] AS [col] FROM (SELECT ISNULL([T3_1].[col1], CONVERT (BIGINT, 0, 0)) AS [col], [T3_1].[CustomerId] AS [CustomerId], [T3_1].[Year] AS [Year], [T3_1].[Quarter] AS [Quarter], [T3_1].[col] AS [col1] FROM (SELECT SUM([T4_1].[TotalAmount]) AS [col], SUM([T4_1].[cb]) AS [col1], [T4_1].[CustomerId] AS [CustomerId], [T4_1].[Year] AS [Year], [T4_1].[Quarter] AS [Quarter] FROM (SELECT [T5_1].[CustomerId] AS [CustomerId], [T5_1].[TotalAmount] AS [TotalAmount], [T5_1].[cb] AS [cb], [T5_1].[Quarter] AS [Quarter], [T5_1].[Year] AS [Year] FROM [SQLPool01].[wwi_perf].[mvCustomerSales] AS T5_1) AS T4_1 GROUP BY [T4_1].[CustomerId], [T4_1].[Year], [T4_1].[Quarter]) AS T3_1) AS T2_1 WHERE ([T2_1].[col] != CAST ((0) AS BIGINT))) AS T1_1
    OPTION (MAXDOP 6)</select>
        </dsql_operation>
    </dsql_operations>
    </dsql_query>
    ```

The same materialized view is also used to optimize the second query.

    ```sql
    EXPLAIN
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Month
            ,SUM(S.ProfitAmount) as TotalProfit
        FROM
            [wwi_perf].[Sale_Partition02] S
            join [wwi].[Date] D on
                S.TransactionDateId = D.DateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Month
    ) T
    ```

The resulting execution plan shows the use of the same materialized view to optimize execution:

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="5" number_distributions="60" number_distributions_per_node="12">
    <sql>SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Month
            ,SUM(S.ProfitAmount) as TotalProfit
        FROM
            [wwi_perf].[Sale_Partition02] S
            join [wwi].[Date] D on
                S.TransactionDateId = D.DateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Month
    ) T</sql>
    <dsql_operations total_cost="0" total_number_operations="1">
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[Year] AS [Year], [T1_1].[Month] AS [Month], [T1_1].[col] AS [col] FROM (SELECT TOP (CAST ((1000) AS BIGINT)) [T2_1].[CustomerId] AS [CustomerId], [T2_1].[Year] AS [Year], [T2_1].[Month] AS [Month], [T2_1].[col1] AS [col] FROM (SELECT ISNULL([T3_1].[col1], CONVERT (BIGINT, 0, 0)) AS [col], [T3_1].[CustomerId] AS [CustomerId], [T3_1].[Year] AS [Year], [T3_1].[Month] AS [Month], [T3_1].[col] AS [col1] FROM (SELECT SUM([T4_1].[TotalProfit]) AS [col], SUM([T4_1].[cb]) AS [col1], [T4_1].[CustomerId] AS [CustomerId], [T4_1].[Year] AS [Year], [T4_1].[Month] AS [Month] FROM (SELECT [T5_1].[CustomerId] AS [CustomerId], [T5_1].[TotalProfit] AS [TotalProfit], [T5_1].[cb] AS [cb], [T5_1].[Month] AS [Month], [T5_1].[Year] AS [Year] FROM [SQLPool01].[wwi_perf].[mvCustomerSales] AS T5_1) AS T4_1 GROUP BY [T4_1].[CustomerId], [T4_1].[Year], [T4_1].[Month]) AS T3_1) AS T2_1 WHERE ([T2_1].[col] != CAST ((0) AS BIGINT))) AS T1_1
    OPTION (MAXDOP 6)</select>
        </dsql_operation>
    </dsql_operations>
    </dsql_query>
    ```

    > **Note**: Even if the two queries have different aggregation levels, the query optimizer is able to infer the use of the materialized view. This happens because the materialized view covers both aggregation levels (`Quarter` and `Month`) as well as both aggregation measures (`TotalAmount` and `ProfitAmount`).

When executing a query that uses a materialized view, the process includes querying the view's CCI index, and applying any changes from the delta store. The more data that is present in the delta store, the slower the performance of the query. Depending on the size of the data in the delta store, will dictate whether or not the materialized view is beneficial. To avoid performance degradation, it's important to keep track of the `material view overhead`. This overhead is calculated as a ratio. The `overhead_ratio` = total_rows/base_view_rows. If this ratio becomes too high, consider rebuilding the materialized views so all rows currently in the delta store are moved to the CCI.

You can obtain the materialized view overhead ratio through the use of `DBCC PDW_SHOWMATERIALIZEDVIEWOVERHEAD`:

    ```sql
    DBCC PDW_SHOWMATERIALIZEDVIEWOVERHEAD ( 'wwi_perf.mvCustomerSales' )
    ```

In our scenario, the results show that `BASE_VIEW_ROWS` are equal to `TOTAL_ROWS` (and hence `OVERHEAD_RATIO` is 1). The materialized view is perfectly aligned with the base view. This situation is expected to change once the underlying data starts to change.

Suppose we update the original base table data:

    ```sql
    UPDATE
        [wwi_perf].[Sale_Partition02]
    SET
        TotalAmount = TotalAmount * 1.01
        ,ProfitAmount = ProfitAmount * 1.01
    WHERE
        CustomerId BETWEEN 100 and 200
    ```

When we check the materialized view overhead again, we can observe there is now a delta stored by the materialized view which results in `TOTAL_ROWS` being greater than `BASE_VIEW_ROWS` and the `OVERHEAD_RATIO` being greater than 1.

    ```sql
    DBCC PDW_SHOWMATERIALIZEDVIEWOVERHEAD ( 'wwi_perf.mvCustomerSales' )
    ```

    ![Materialized view overhead after update](./media/lab3_materialized_view_updated.png)

The next query will demonstrate the rebuilding the materialized view. Performing the overhead ratio check once more will reset the view and have the overhead ratio return to 1:

    ```sql
    ALTER MATERIALIZED VIEW [wwi_perf].[mvCustomerSales] REBUILD

    DBCC PDW_SHOWMATERIALIZEDVIEWOVERHEAD ( 'wwi_perf.mvCustomerSales' )
    ```

    ![Materialized view overhead after rebuild](./media/lab3_materialized_view_rebuilt.png)

To further investigate the impact of material views, we will once again analyze the execution plan of a query. We will use the scenario that we need to determine the of customers in each bucket of per-customer transaction items counts. Here is the general query:

    ```sql
    SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (count(*) - 184) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket
    ```

We can improve this query by adding support to calculate the lower margin of the first per-customer transactions items count bucket:

    ```sql
    SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (
                    COUNT(*) -
                    (
                        SELECT
                            MIN(TransactionItemsCount)
                        FROM
                        (
                            SELECT
                                COUNT(*) as TransactionItemsCount
                            FROM
                                [wwi_perf].[Sale_Hash]
                            GROUP BY
                                CustomerId
                        ) X
                    )
                ) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket
    ```

Running the improved query with the `EXPLAIN WITH_RECOMMENDATIONS` to obtain the execution plan.

    ```sql
    EXPLAIN WITH_RECOMMENDATIONS
    SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (
                    COUNT(*) - 
                    (
                        SELECT 
                            MIN(TransactionItemsCount)
                        FROM 
                        (
                            SELECT 
                                COUNT(*) as TransactionItemsCount
                            FROM 
                                [wwi_perf].[Sale_Hash] 
                            GROUP BY 
                                CustomerId 
                        ) X 
                    )
                ) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket
    ```

Because the `WITH_RECOMMENDATIONS` option was used, observe the `<materialized_view_candidates>` section of the execution plan. This section suggests possible materialized views you can create to help improve the performance of the query.

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="5" number_distributions="60" number_distributions_per_node="12">
    <sql>SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (
                    COUNT(*) -
                    (
                        SELECT
                            MIN(TransactionItemsCount)
                        FROM
                        (
                            SELECT
                                COUNT(*) as TransactionItemsCount
                            FROM
                                [wwi_perf].[Sale_Hash]
                            GROUP BY
                                CustomerId
                        ) X
                    )
                ) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket</sql>
    <materialized_view_candidates>
        <materialized_view_candidates with_constants="False">CREATE MATERIALIZED VIEW View1 WITH (DISTRIBUTION = HASH([Expr0])) AS
    SELECT [SQLPool01].[wwi_perf].[Sale_Hash].[CustomerId] AS [Expr0],
        COUNT(*) AS [Expr1]
    FROM [wwi_perf].[Sale_Hash]
    GROUP BY [SQLPool01].[wwi_perf].[Sale_Hash].[CustomerId]</materialized_view_candidates>
    </materialized_view_candidates>
    <dsql_operations total_cost="0.0242811172881356" total_number_operations="9">
        <dsql_operation operation_type="RND_ID">
        <identifier>TEMP_ID_99</identifier>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllComputeNodes" />
        <sql_operations>
            <sql_operation type="statement">CREATE TABLE [qtabledb].[dbo].[TEMP_ID_99] ([col] INT ) WITH(DISTRIBUTED_MOVE_FILE='');</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="BROADCAST_MOVE">
        <operation_cost cost="0.00096" accumulative_cost="0.00096" average_rowsize="4" output_rows="1" GroupNumber="69" />
        <source_statement>SELECT [T1_1].[col] AS [col] FROM (SELECT MIN([T2_1].[col]) AS [col] FROM (SELECT COUNT(CAST ((0) AS INT)) AS [col], 0 AS [col1] FROM [SQLPool01].[wwi_perf].[Sale_Hash] AS T3_1 GROUP BY [T3_1].[CustomerId]) AS T2_1 GROUP BY [T2_1].[col1]) AS T1_1
    OPTION (MAXDOP 6, MIN_GRANT_PERCENT = [MIN_GRANT], DISTRIBUTED_MOVE(N''))</source_statement>
        <destination_table>[TEMP_ID_99]</destination_table>
        </dsql_operation>
        <dsql_operation operation_type="RND_ID">
        <identifier>TEMP_ID_100</identifier>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllDistributions" />
        <sql_operations>
            <sql_operation type="statement">CREATE TABLE [qtabledb].[dbo].[TEMP_ID_100] ([col] INT, [col1] BIGINT ) WITH(DISTRIBUTED_MOVE_FILE='');</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="SHUFFLE_MOVE">
        <operation_cost cost="0.0233211172881356" accumulative_cost="0.0242811172881356" average_rowsize="12" output_rows="95.5518" GroupNumber="75" />
        <source_statement>SELECT [T1_1].[col1] AS [col], [T1_1].[col] AS [col1] FROM (SELECT COUNT_BIG(CAST ((0) AS INT)) AS [col], [T2_1].[col] AS [col1] FROM (SELECT (([T3_2].[col] - [T3_1].[col]) / CAST ((100) AS INT)) AS [col] FROM (SELECT MIN([T4_1].[col]) AS [col] FROM [qtabledb].[dbo].[TEMP_ID_99] AS T4_1) AS T3_1 INNER JOIN
    (SELECT COUNT(CAST ((0) AS INT)) AS [col] FROM [SQLPool01].[wwi_perf].[Sale_Hash] AS T4_1 GROUP BY [T4_1].[CustomerId]) AS T3_2
    ON (0 = 0)) AS T2_1 GROUP BY [T2_1].[col]) AS T1_1
    OPTION (MAXDOP 6, MIN_GRANT_PERCENT = [MIN_GRANT], DISTRIBUTED_MOVE(N''))</source_statement>
        <destination_table>[TEMP_ID_100]</destination_table>
        <shuffle_columns>col;</shuffle_columns>
        </dsql_operation>
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[col1] AS [col], [T1_1].[col] AS [col1] FROM (SELECT CONVERT (INT, [T2_1].[col], 0) AS [col], [T2_1].[col1] AS [col1] FROM (SELECT ISNULL([T3_1].[col], CONVERT (BIGINT, 0, 0)) AS [col], [T3_1].[col1] AS [col1] FROM (SELECT SUM([T4_1].[col1]) AS [col], [T4_1].[col] AS [col1] FROM [qtabledb].[dbo].[TEMP_ID_100] AS T4_1 GROUP BY [T4_1].[col]) AS T3_1) AS T2_1) AS T1_1 ORDER BY [T1_1].[col1] ASC
    OPTION (MAXDOP 6, MIN_GRANT_PERCENT = [MIN_GRANT])</select>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllDistributions" />
        <sql_operations>
            <sql_operation type="statement">DROP TABLE [qtabledb].[dbo].[TEMP_ID_100]</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllComputeNodes" />
        <sql_operations>
            <sql_operation type="statement">DROP TABLE [qtabledb].[dbo].[TEMP_ID_99]</sql_operation>
        </sql_operations>
        </dsql_operation>
    </dsql_operations>
    </dsql_query>
    ```

We'll now create the suggested materialized view and re-query for the execution plan.

    ```sql
    CREATE MATERIALIZED VIEW
        mvTransactionItemsCounts
    WITH
    (
        DISTRIBUTION = HASH([CustomerId])
    )
    AS
    SELECT
        CustomerId
        ,COUNT(*) AS ItemsCount
    FROM
        [wwi_perf].[Sale_Hash]
    GROUP BY
        CustomerId
    ```

    ```sql
    EXPLAIN WITH_RECOMMENDATIONS
    SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (
                    COUNT(*) - 
                    (
                        SELECT 
                            MIN(TransactionItemsCount)
                        FROM 
                        (
                            SELECT 
                                COUNT(*) as TransactionItemsCount
                            FROM 
                                [wwi_perf].[Sale_Hash] 
                            GROUP BY 
                                CustomerId 
                        ) X 
                    )
                ) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket
    ```

The resulting execution plan indicates now the use of the `mvTransactionItemsCounts` (the `BROADCAST_MOVE` distributed SQL operation) materialized view which provides improvements to the query execution time:

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="5" number_distributions="60" number_distributions_per_node="12">
    <sql>SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (
                    COUNT(*) -
                    (
                        SELECT
                            MIN(TransactionItemsCount)
                        FROM
                        (
                            SELECT
                                COUNT(*) as TransactionItemsCount
                            FROM
                                [wwi_perf].[Sale_Hash]
                            GROUP BY
                                CustomerId
                        ) X
                    )
                ) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket</sql>
    <materialized_view_candidates>
        <materialized_view_candidates with_constants="False">CREATE MATERIALIZED VIEW View1 WITH (DISTRIBUTION = HASH([Expr0])) AS
    SELECT [SQLPool01].[wwi_perf].[Sale_Hash].[CustomerId] AS [Expr0],
        COUNT(*) AS [Expr1]
    FROM [wwi_perf].[Sale_Hash]
    GROUP BY [SQLPool01].[wwi_perf].[Sale_Hash].[CustomerId]</materialized_view_candidates>
    </materialized_view_candidates>
    <dsql_operations total_cost="0.0242811172881356" total_number_operations="9">
        <dsql_operation operation_type="RND_ID">
        <identifier>TEMP_ID_111</identifier>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllComputeNodes" />
        <sql_operations>
            <sql_operation type="statement">CREATE TABLE [qtabledb].[dbo].[TEMP_ID_111] ([col] INT ) WITH(DISTRIBUTED_MOVE_FILE='');</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="BROADCAST_MOVE">
        <operation_cost cost="0.00096" accumulative_cost="0.00096" average_rowsize="4" output_rows="1" GroupNumber="134" />
        <source_statement>SELECT [T1_1].[col] AS [col] FROM (SELECT MIN([T2_1].[col]) AS [col] FROM (SELECT CONVERT (INT, [T3_1].[col], 0) AS [col], 0 AS [col1] FROM (SELECT ISNULL([T4_1].[col], CONVERT (BIGINT, 0, 0)) AS [col] FROM (SELECT SUM([T5_1].[ItemsCount]) AS [col] FROM (SELECT [T6_1].[CustomerId] AS [CustomerId], [T6_1].[ItemsCount] AS [ItemsCount] FROM [SQLPool01].[dbo].[mvTransactionItemsCounts] AS T6_1) AS T5_1 GROUP BY [T5_1].[CustomerId]) AS T4_1) AS T3_1 WHERE ([T3_1].[col] != CAST ((0) AS BIGINT))) AS T2_1 GROUP BY [T2_1].[col1]) AS T1_1
    OPTION (MAXDOP 6, MIN_GRANT_PERCENT = [MIN_GRANT], DISTRIBUTED_MOVE(N''))</source_statement>
        <destination_table>[TEMP_ID_111]</destination_table>
        </dsql_operation>
        <dsql_operation operation_type="RND_ID">
        <identifier>TEMP_ID_112</identifier>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllDistributions" />
        <sql_operations>
            <sql_operation type="statement">CREATE TABLE [qtabledb].[dbo].[TEMP_ID_112] ([col] INT, [col1] BIGINT ) WITH(DISTRIBUTED_MOVE_FILE='');</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="SHUFFLE_MOVE">
        <operation_cost cost="0.0233211172881356" accumulative_cost="0.0242811172881356" average_rowsize="12" output_rows="95.5518" GroupNumber="140" />
        <source_statement>SELECT [T1_1].[col1] AS [col], [T1_1].[col] AS [col1] FROM (SELECT COUNT_BIG(CAST ((0) AS INT)) AS [col], [T2_1].[col] AS [col1] FROM (SELECT (([T3_2].[col] - [T3_1].[col]) / CAST ((100) AS INT)) AS [col] FROM (SELECT MIN([T4_1].[col]) AS [col] FROM [qtabledb].[dbo].[TEMP_ID_111] AS T4_1) AS T3_1 INNER JOIN
    (SELECT CONVERT (INT, [T4_1].[col], 0) AS [col] FROM (SELECT ISNULL([T5_1].[col], CONVERT (BIGINT, 0, 0)) AS [col] FROM (SELECT SUM([T6_1].[ItemsCount]) AS [col] FROM (SELECT [T7_1].[CustomerId] AS [CustomerId], [T7_1].[ItemsCount] AS [ItemsCount] FROM [SQLPool01].[dbo].[mvTransactionItemsCounts] AS T7_1) AS T6_1 GROUP BY [T6_1].[CustomerId]) AS T5_1) AS T4_1 WHERE ([T4_1].[col] != CAST ((0) AS BIGINT))) AS T3_2
    ON (0 = 0)) AS T2_1 GROUP BY [T2_1].[col]) AS T1_1
    OPTION (MAXDOP 6, MIN_GRANT_PERCENT = [MIN_GRANT], DISTRIBUTED_MOVE(N''))</source_statement>
        <destination_table>[TEMP_ID_112]</destination_table>
        <shuffle_columns>col;</shuffle_columns>
        </dsql_operation>
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[col1] AS [col], [T1_1].[col] AS [col1] FROM (SELECT CONVERT (INT, [T2_1].[col], 0) AS [col], [T2_1].[col1] AS [col1] FROM (SELECT ISNULL([T3_1].[col], CONVERT (BIGINT, 0, 0)) AS [col], [T3_1].[col1] AS [col1] FROM (SELECT SUM([T4_1].[col1]) AS [col], [T4_1].[col] AS [col1] FROM [qtabledb].[dbo].[TEMP_ID_112] AS T4_1 GROUP BY [T4_1].[col]) AS T3_1) AS T2_1) AS T1_1 ORDER BY [T1_1].[col1] ASC
    OPTION (MAXDOP 6, MIN_GRANT_PERCENT = [MIN_GRANT])</select>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllDistributions" />
        <sql_operations>
            <sql_operation type="statement">DROP TABLE [qtabledb].[dbo].[TEMP_ID_112]</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllComputeNodes" />
        <sql_operations>
            <sql_operation type="statement">DROP TABLE [qtabledb].[dbo].[TEMP_ID_111]</sql_operation>
        </sql_operations>
        </dsql_operation>
    </dsql_operations>
    </dsql_query>
    ```

### 3.4.3. Improve query performance with result set caching

Result set caching is used for achieving high concurrency and fast response times from repetitive queries against static data. Result set caching is a feature of the SQl pool, and you can determine if it's been enabled by querying the `is_result_set_caching_on` column in the sys.databases table.

    ```sql
    SELECT
        name
        ,is_result_set_caching_on
    FROM 
        sys.databases
    ```

    ![Check result set caching settings at the database level](./media/lab3_result_set_caching_db.png)

If `False` is returned for your SQL pool, it may be activated using an `ALTER DATABASE` statement as follows (you need to run it on the `master` database and replace `<sql_pool> with the name of your SQL pool).

    ```sql
    ALTER DATABASE [<sql_pool>]
    SET RESULT_SET_CACHING ON
    ```

    >**Important**: The operation to create result set cache and retrieve data from the cache happen on the control node of a Synapse SQL pool instance. When result set caching is turned ON, running queries that return a large result set (for example, >1GB) can cause high throttling on the control node and slow down the overall query response on the instance. Those queries are commonly used during data exploration or ETL operations. To avoid stressing the control node and cause performance issue, users should turn OFF result set caching on the database before running those types of queries.

You can determine if there has been a cache hit by leveraging `result_cache_hit` column in the `dm_pdw_exec_requests` DMV. For our scenario, if we were to execute the following query for the first time will, understandably, result in a cache miss.

    ```sql
    SELECT
        D.Year
        ,D.Quarter
        ,D.Month
        ,SUM(S.TotalAmount) as TotalAmount
        ,SUM(S.ProfitAmount) as TotalProfit
    FROM
        [wwi_perf].[Sale_Partition02] S
        join [wwi].[Date] D on
            S.TransactionDateId = D.DateId
    GROUP BY
        D.Year
        ,D.Quarter
        ,D.Month
    OPTION (LABEL = 'Result set caching')

    SELECT 
        result_cache_hit
    FROM 
        sys.dm_pdw_exec_requests
    WHERE 
        request_id = 
        (
            SELECT TOP 1 
                request_id 
            FROM 
                sys.dm_pdw_exec_requests
            WHERE   
                [label] = 'Result set caching'
            ORDER BY
                start_time desc
        )
    ```

As expected, the result would be `False`. Still, you can identify that, while running the query, Synapse has also cached the result set. Run the following query to get the execution steps:

    ```sql
    SELECT 
        step_index
        ,operation_type
        ,location_type
        ,status
        ,total_elapsed_time
        ,command
    FROM 
        sys.dm_pdw_request_steps
    WHERE 
        request_id =
        (
            SELECT TOP 1 
                request_id 
            FROM 
                sys.dm_pdw_exec_requests
            WHERE   
                [label] = 'Lab03: Result set caching'
            ORDER BY
                start_time desc
        )
    ```

The execution plan reveals the building of the result set cache:

    ![The building of the result set cache](./media/lab3_result_set_cache_build.png)

You can control at the user session level the use of the result set cache. The following query shows how to deactivate and activate the result cache:

    ```sql  
    SET RESULT_SET_CACHING OFF

    SELECT
        D.Year
        ,D.Quarter
        ,D.Month
        ,SUM(S.TotalAmount) as TotalAmount
        ,SUM(S.ProfitAmount) as TotalProfit
    FROM
        [wwi_perf].[Sale_Partition02] S
        join [wwi].[Date] D on
            S.TransactionDateId = D.DateId
    GROUP BY
        D.Year
        ,D.Quarter
        ,D.Month
    OPTION (LABEL = 'Lab03: Result set caching off')

    SET RESULT_SET_CACHING ON

    SELECT
        D.Year
        ,D.Quarter
        ,D.Month
        ,SUM(S.TotalAmount) as TotalAmount
        ,SUM(S.ProfitAmount) as TotalProfit
    FROM
        [wwi_perf].[Sale_Partition02] S
        join [wwi].[Date] D on
            S.TransactionDateId = D.DateId
    GROUP BY
        D.Year
        ,D.Quarter
        ,D.Month
    OPTION (LABEL = 'Lab03: Result set caching on')

    SELECT TOP 2
        request_id
        ,[label]
        ,result_cache_hit
    FROM 
        sys.dm_pdw_exec_requests
    WHERE   
        [label] in ('Lab03: Result set caching off', 'Lab03: Result set caching on')
    ORDER BY
        start_time desc
    ```

The result of `SET RESULT_SET_CACHING OFF` is visible in the cache hit test results (`RESULT_CACHE_HIT` contains a `NULL` value):

    ![Result cache on and off](./media/lab3_result_set_cache_off.png)

It's important to keep track of the amount of space used by results cache. You can retrieve this information using the `DBCC SHOWRESULTCACHESPACEUSED` statement.

    ```sql
    DBCC SHOWRESULTCACHESPACEUSED
    ```

    ![Check the size of the result set cache](./media/lab3_result_set_cache_size.png)

To clear the result set cache, you can leverage the `DBCC DROPRESULTSETCACHE` statement.

    ```sql
    DBCC DROPRESULTSETCACHE
    ```

To disable result set caching on the database use an `ALTER DATABASE` statement as follows (you need to run it on the `master` database and replace `<sql_pool> with the name of your SQL pool).

    ```sql
    ALTER DATABASE [<sql_pool>]
    SET RESULT_SET_CACHING OFF
    ```

    >**Note**: The maximum size of result set cache is 1 TB per database. The cached results are automatically invalidated when the underlying query data changes. The cache eviction is managed by SQL Analytics automatically following this schedule:
    >   - Every 48 hours if the result set hasn't been used or has been invalidated.
    >   - When the result set cache approaches the maximum size.
    >
    >Users can manually empty the entire result set cache by using one of these options:
    >   - Turn OFF the result set cache feature for the database
    >   - Run DBCC DROPRESULTSETCACHE while connected to the database
    >
    >Pausing a database won't empty cached result set.

## 3.5. Manage statistics

The more the SQL pool resource knows about your data, the faster it can execute queries. After loading data into SQL pool, collecting statistics on your data is one of the most important things you can do for query optimization.

The SQL pool query optimizer is a cost-based optimizer. It compares the cost of various query plans, and then chooses the plan with the lowest cost. In most cases, it chooses the plan that will execute the fastest.

For example, if the optimizer estimates that the date your query is filtering on will return one row it will choose one plan. If it estimates that the selected date will return 1 million rows, it will return a different plan.

To determine if statistics are set to be automatically created in the database, you would query the `is_auto_create_stats_on` column from the sys.databases table.

```sql
SELECT name, is_auto_create_stats_on
FROM sys.databases
```

To retrieve a listing of statistics that have been automatically created, use the `sys.dm_pdw_exec_requests` DMV.

```sql
SELECT
    *
FROM 
    sys.dm_pdw_exec_requests
WHERE 
    Command like 'CREATE STATISTICS%'
```

Notice the special name pattern used for automatically created statistics:

![View automatically created statistics](./media/lab3_statistics_automated.png)

To determine if there are any statistics created for a specific column, you can leverage `DBCC SHOW_STATISTICS`. In our scenario, let's determine the statistics set on the `CustomerId` column from the `wwi_perf.Sale_Hash` table.

```sql
DBCC SHOW_STATISTICS ('wwi_perf.Sale_Hash', CustomerId) WITH HISTOGRAM
```

If there is no statistics for `CustomerId`, an error will occur. To create statistics for the `CustomerId` table, use the `CREATE STATISTICS` statement.

```sql
CREATE STATISTICS Sale_Hash_CustomerId ON wwi_perf.Sale_Hash (CustomerId)
```

An example of statistics retrieved using `DBCC SHOW_STATISTICS` is as follows. The `Chart` option has been selected to see the visual.

![Statistics created for CustomerId](./media/lab3_statistics_customerid.png)

> **Important**: The more SQL pool knows about your data, the faster it can execute queries against it. After loading data into SQL pool, collecting statistics on your data is one of the most important things you can do to optimize your queries.
>
>The SQL pool query optimizer is a cost-based optimizer. It evaluates the cost of multiple query plans, and then chooses the plan with the lowest cost. In most cases, it chooses the plan that will execute the fastest.
>
>For example, if the optimizer estimates that the date your query is filtering on will return one row it will choose one plan. If it estimates that the selected date will return 1 million rows, it will return a different plan.

## 3.6. Monitor space usage

It's important to monitor the physical space used by your tables. This will allow you to potentially restructure certain tables to attain optimal performance when certain thresholds are met, for instance, when a replicated table bypasses 1.5 GB in size. Data skew is defined as how evenly data is distributed. It is also important to keep a heart beat on the skewness of the data as it plays an important role in overall query performance.

### 3.6.1. Analyze space used by tables

We can obtain the space used by a table using the `DBCC PDW_SHOWSPACEUSED` command, this command also reports on the number of rows in each distribution to denote the skewness of the data. With respect to skewness, those numbers should be as even as possible. You can see from the results of the following command, that rows are equally distributed across distributions.

    ```sql
    DBCC PDW_SHOWSPACEUSED('wwi_perf.Sale_Hash');
    ```

    ![Show table space usage and data skewness.](./media/lab3_table_space_usage.png)

As an example of demonstrating the aspect of data skew, we can provide further analysis using the following scenario. Consider the following query to get customers with the most sale transaction items:

    ```sql
    SELECT TOP 1000 
        CustomerId,
        count(*) as TransactionItemsCount
    FROM
        [wwi_perf].[Sale_Hash]
    GROUP BY
        CustomerId
    ORDER BY
        count(*) DESC
    ```

    ![Customers with most sale transaction items](./media/lab4_data_skew_1.png)

Consider as well as this query, to find the customers with the least sale transaction items:

    ```sql
    SELECT TOP 1000 
        CustomerId,
        count(*) as TransactionItemsCount
    FROM
        [wwi_perf].[Sale_Hash]
    GROUP BY
        CustomerId
    ORDER BY
        count(*) ASC
    ```

    ![Customers with most sale transaction items](./media/lab4_data_skew_2.png)

We can see the overall range (skew) of the data at the the surface level to have the largest number of transaction items being 9465 and the smallest being 184.

We can obtain the distribution of per-customer transaction item counts by using the following query:

    ```sql
    SELECT
        T.TransactionItemsCountBucket
        ,count(*) as CustomersCount
    FROM
        (
            SELECT
                CustomerId,
                (count(*) - 184) / 100 as TransactionItemsCountBucket
            FROM
                [wwi_perf].[Sale_Hash]
            GROUP BY
                CustomerId
        ) T
    GROUP BY
        T.TransactionItemsCountBucket
    ORDER BY
        T.TransactionItemsCountBucket
    ```

In the `Results` pane, we've switched to the `Chart` view to render a useful visualization (note the visualization options set on the right side).

    ![Distribution of per-customer transaction item counts](./media/lab4_transaction_items_count_distribution.png)

Without diving too much into the mathematical and statistical details, this histogram represents the fact there is no skew in the data distribution of the `Sale_Hash` table. This is due to the quasi-normalized distribution of the per-customer transaction item counts.

### 3.6.2. Advanced space usage analysis

In regards to the further analysis of table space usage, we can create a helpful view that will surface useful table space usage data. We've created the `vTableSizes` view as follows:

    ```sql
    CREATE VIEW [wwi_perf].[vTableSizes]
    AS
    WITH base
    AS
    (
    SELECT
        GETDATE()                                                              AS  [execution_time]
        , DB_NAME()                                                            AS  [database_name]
        , s.name                                                               AS  [schema_name]
        , t.name                                                               AS  [table_name]
        , QUOTENAME(s.name)+'.'+QUOTENAME(t.name)                              AS  [two_part_name]
        , nt.[name]                                                            AS  [node_table_name]
        , ROW_NUMBER() OVER(PARTITION BY nt.[name] ORDER BY (SELECT NULL))     AS  [node_table_name_seq]
        , tp.[distribution_policy_desc]                                        AS  [distribution_policy_name]
        , c.[name]                                                             AS  [distribution_column]
        , nt.[distribution_id]                                                 AS  [distribution_id]
        , i.[type]                                                             AS  [index_type]
        , i.[type_desc]                                                        AS  [index_type_desc]
        , nt.[pdw_node_id]                                                     AS  [pdw_node_id]
        , pn.[type]                                                            AS  [pdw_node_type]
        , pn.[name]                                                            AS  [pdw_node_name]
        , di.name                                                              AS  [dist_name]
        , di.position                                                          AS  [dist_position]
        , nps.[partition_number]                                               AS  [partition_nmbr]
        , nps.[reserved_page_count]                                            AS  [reserved_space_page_count]
        , nps.[reserved_page_count] - nps.[used_page_count]                    AS  [unused_space_page_count]
        , nps.[in_row_data_page_count]
            + nps.[row_overflow_used_page_count]
            + nps.[lob_used_page_count]                                        AS  [data_space_page_count]
        , nps.[reserved_page_count]
        - (nps.[reserved_page_count] - nps.[used_page_count])
        - ([in_row_data_page_count]
                + [row_overflow_used_page_count]+[lob_used_page_count])        AS  [index_space_page_count]
        , nps.[row_count]                                                      AS  [row_count]
    FROM
        sys.schemas s
    INNER JOIN sys.tables t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.indexes i
        ON  t.[object_id] = i.[object_id]
        AND i.[index_id] <= 1
    INNER JOIN sys.pdw_table_distribution_properties tp
        ON t.[object_id] = tp.[object_id]
    INNER JOIN sys.pdw_table_mappings tm
        ON t.[object_id] = tm.[object_id]
    INNER JOIN sys.pdw_nodes_tables nt
        ON tm.[physical_name] = nt.[name]
    INNER JOIN sys.dm_pdw_nodes pn
        ON  nt.[pdw_node_id] = pn.[pdw_node_id]
    INNER JOIN sys.pdw_distributions di
        ON  nt.[distribution_id] = di.[distribution_id]
    INNER JOIN sys.dm_pdw_nodes_db_partition_stats nps
        ON nt.[object_id] = nps.[object_id]
        AND nt.[pdw_node_id] = nps.[pdw_node_id]
        AND nt.[distribution_id] = nps.[distribution_id]
    LEFT OUTER JOIN (select * from sys.pdw_column_distribution_properties where distribution_ordinal = 1) cdp
        ON t.[object_id] = cdp.[object_id]
    LEFT OUTER JOIN sys.columns c
        ON cdp.[object_id] = c.[object_id]
        AND cdp.[column_id] = c.[column_id]
    WHERE pn.[type] = 'COMPUTE'
    )
    , size
    AS
    (
    SELECT
    [execution_time]
    ,  [database_name]
    ,  [schema_name]
    ,  [table_name]
    ,  [two_part_name]
    ,  [node_table_name]
    ,  [node_table_name_seq]
    ,  [distribution_policy_name]
    ,  [distribution_column]
    ,  [distribution_id]
    ,  [index_type]
    ,  [index_type_desc]
    ,  [pdw_node_id]
    ,  [pdw_node_type]
    ,  [pdw_node_name]
    ,  [dist_name]
    ,  [dist_position]
    ,  [partition_nmbr]
    ,  [reserved_space_page_count]
    ,  [unused_space_page_count]
    ,  [data_space_page_count]
    ,  [index_space_page_count]
    ,  [row_count]
    ,  ([reserved_space_page_count] * 8.0)                                 AS [reserved_space_KB]
    ,  ([reserved_space_page_count] * 8.0)/1000                            AS [reserved_space_MB]
    ,  ([reserved_space_page_count] * 8.0)/1000000                         AS [reserved_space_GB]
    ,  ([reserved_space_page_count] * 8.0)/1000000000                      AS [reserved_space_TB]
    ,  ([unused_space_page_count]   * 8.0)                                 AS [unused_space_KB]
    ,  ([unused_space_page_count]   * 8.0)/1000                            AS [unused_space_MB]
    ,  ([unused_space_page_count]   * 8.0)/1000000                         AS [unused_space_GB]
    ,  ([unused_space_page_count]   * 8.0)/1000000000                      AS [unused_space_TB]
    ,  ([data_space_page_count]     * 8.0)                                 AS [data_space_KB]
    ,  ([data_space_page_count]     * 8.0)/1000                            AS [data_space_MB]
    ,  ([data_space_page_count]     * 8.0)/1000000                         AS [data_space_GB]
    ,  ([data_space_page_count]     * 8.0)/1000000000                      AS [data_space_TB]
    ,  ([index_space_page_count]  * 8.0)                                   AS [index_space_KB]
    ,  ([index_space_page_count]  * 8.0)/1000                              AS [index_space_MB]
    ,  ([index_space_page_count]  * 8.0)/1000000                           AS [index_space_GB]
    ,  ([index_space_page_count]  * 8.0)/1000000000                        AS [index_space_TB]
    FROM base
    )
    SELECT *
    FROM size
    ```

Introspecting the above view definition, you can see multiple tables are leveraged to obtain the space usage data. Here is a short description of the tables and DMVs involved in this view:

    Table Name | Description
    ---|---
    sys.schemas | All schemas in the database.
    sys.tables | All tables in the database.
    sys.indexes | All indexes in the database.
    sys.columns | All columns in the database.
    sys.pdw_table_mappings | Maps each table to local tables on physical nodes and distributions.
    sys.pdw_nodes_tables | Contains information on each local table in each distribution.
    sys.pdw_table_distribution_properties | Holds distribution information for tables (the type of distribution tables have).
    sys.pdw_column_distribution_properties | Holds distribution information for columns. Filtered to include only columns used to distribute their parent tables (`distribution_ordinal` = 1).
    sys.pdw_distributions |  Holds information about the distributions from the SQL pool.
    sys.dm_pdw_nodes | Holds information about the nodes from the SQL pool. Filtered to include only compute nodes (`type` = `COMPUTE`).
    sys.dm_pdw_nodes_db_partition_stats | Returns page and row-count information for every partition in the current database.

We can now leverage the `vTableSizes` view to surface advanced details about the structure of the tables. Consider this sample query that leverages this view to obtain storage details on every table in the `wwi_perf` schema:

    ```sql
    SELECT
        database_name
    ,    schema_name
    ,    table_name
    ,    distribution_policy_name
    ,      distribution_column
    ,    index_type_desc
    ,    COUNT(distinct partition_nmbr) as nbr_partitions
    ,    SUM(row_count)                 as table_row_count
    ,    SUM(reserved_space_GB)         as table_reserved_space_GB
    ,    SUM(data_space_GB)             as table_data_space_GB
    ,    SUM(index_space_GB)            as table_index_space_GB
    ,    SUM(unused_space_GB)           as table_unused_space_GB
    FROM
        [wwi_perf].[vTableSizes]
    WHERE
        schema_name = 'wwi_perf'
    GROUP BY
        database_name
    ,    schema_name
    ,    table_name
    ,    distribution_policy_name
    ,      distribution_column
    ,    index_type_desc
    ORDER BY
        table_reserved_space_GB desc
    ```

    ![Detailed table space usage](./media/lab4_table_space.png)

Upon further analysis of this query, we can observe the significant difference between the space used by `CLUSTERED COLUMNSTORE` and `HEAP` or `CLUSTERED` tables. This provides a clear indication on the significant advantages columnstore indexes have. You can also observe the slight increase of storage space for the ordered CCI table (`Sale_Hash_Ordered`).

## 3.7. Monitor column store storage

We can create another view, `vColumnStoreRowGroupStats`, to analyze column store row group statistics. This view was created with the following definition.

    ```sql
    create view [wwi_perf].[vColumnStoreRowGroupStats]
    as
    with cte
    as
    (
    select   tb.[name]                    AS [logical_table_name]
    ,        rg.[row_group_id]            AS [row_group_id]
    ,        rg.[state]                   AS [state]
    ,        rg.[state_desc]              AS [state_desc]
    ,        rg.[total_rows]              AS [total_rows]
    ,        rg.[trim_reason_desc]        AS trim_reason_desc
    ,        mp.[physical_name]           AS physical_name
    FROM    sys.[schemas] sm
    JOIN    sys.[tables] tb               ON  sm.[schema_id]          = tb.[schema_id]
    JOIN    sys.[pdw_table_mappings] mp   ON  tb.[object_id]          = mp.[object_id]
    JOIN    sys.[pdw_nodes_tables] nt     ON  nt.[name]               = mp.[physical_name]
    JOIN    sys.[dm_pdw_nodes_db_column_store_row_group_physical_stats] rg      ON  rg.[object_id]     = nt.[object_id]
                                                                                AND rg.[pdw_node_id]   = nt.[pdw_node_id]
                                            AND rg.[distribution_id]    = nt.[distribution_id]
    )
    select *
    from cte;
    ```

In this view we are using the `sys.dm_pdw_nodes_db_column_store_row_group_physical_stats` DMV which provides current rowgroup-level information about all of the columnstore indexes in the current database.

The `state_desc` column provides useful information on the state of a row group:

    Name | Description
    ---|---
    `INVISIBLE` | A rowgroup which is being compressed.
    `OPEN` | A deltastore rowgroup that is accepting new rows. It is important to remember that an open rowgroup is still in rowstore format and has not been compressed to columnstore format.
    `CLOSED` | A deltastore rowgroup that contains the maximum number of rows, and is waiting for the tuple mover process to compress it to the columnstore.
    `COMPRESSED` | A row group that is compressed with columnstore compression and stored in the columnstore.
    `TOMBSTONE` | A row group that was formerly in the deltastore and is no longer used.

The `trim_reason_desc` column describes the reason that triggered the `COMPRESSED` rowgroup to have less than the maximum number of rows:

    Name | Description
    ---|---
    `UNKNOWN_UPGRADED_FROM_PREVIOUS_VERSION` | Occurred when upgrading from the previous version of SQL Server.
    `NO_TRIM` | The row group was not trimmed. The row group was compressed with the maximum of 1,048,476 rows. The number of rows could be less if a subset of rows was deleted after delta rowgroup was closed.
    `BULKLOAD` | The bulk-load batch size limited the number of rows. This is what you should be looking for when optimizing data loading, as it is an indicator of resource starvation during the loading process.
    `REORG` | Forced compression as part of REORG command.
    `DICTIONARY_SIZE` | Dictionary size grew too large to compress all of the rows together.
    `MEMORY_LIMITATION` | Not enough available memory to compress all the rows together.
    `RESIDUAL_ROW_GROUP` | Closed as part of last row group with rows < 1 million during index build operation.

We can now leverage this view to statistics of the columnstore for the `Sale_Partition02` table. Make note of the `COMPRESSED` and `OPEN` states of some of the row groups.

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[vColumnStoreRowGroupStats]
    WHERE
        Logical_Table_Name = 'Sale_Partition02'
    ```

    ![Column store row group statistics for Sale_Partition02](./media/lab4_column_store_row_groups.png)

We will repeat this query, but this time exploring the statistics of the columnstore for the `Sale_Hash_Ordered` table. You will notice that there is a significant difference in the rowgroup statistics from the previous one. This highlights one of the potential advantages of ordered CCIs.

    ```sql
    SELECT
        *
    FROM
        [wwi_perf].[vColumnStoreRowGroupStats]
    WHERE
        Logical_Table_Name = 'Sale_Hash_Ordered'
    ```

    ![Column store row group statistics for Sale_Hash_Ordered](./media/lab4_column_store_row_groups_2.png)

## 3.8. Choose the right data types

The column types and sizes that you use to define data warehouse tables can have a significant impact on space allocation and performance. It is a good practice to use the minimum size to fit your data. Smaller data types shortens the row length which yields better overall query performance. For instance, some guidance for character columns includes:

    - if your largest value is 25 characters, then defeine your column as VARCHAR(25)
    - avoid using NVARCHAR, when all you need is VARCHAR
    - avoid using VARCHAR(MAX), use VARCHAR(8000) instead

To further demonstrate this concept, we'll look into a scenario using numeric fields. We've used the following DDL to create two tables (`Sale_Hash_Projection` and `Sale_Hash_Projection2`) which contain a subset of the columns from the `Sale_Heap` table.

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Hash_Projection]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        HEAP
    )
    AS
    SELECT
        [CustomerId]
        ,[ProductId]
        ,[Quantity]
    FROM
        [wwi_perf].[Sale_Heap]

    CREATE TABLE [wwi_perf].[Sale_Hash_Projection2]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX
    )
    AS
    SELECT
        [CustomerId]
        ,[ProductId]
        ,[Quantity]
    FROM
        [wwi_perf].[Sale_Heap]
    ```

We'll now define two additional tables (`Sale_Hash_Projection_Big` and `Sale_Hash_Projection_Big2`) that have the same columns, but with different (sub_optimal) data types. We'll use `bigint` as it is larger than what we need in our scenario.

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Hash_Projection_Big]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        HEAP
    )
    AS
    SELECT
        [CustomerId]
        ,CAST([ProductId] as bigint) as [ProductId]
        ,CAST([Quantity] as bigint) as [Quantity]
    FROM
        [wwi_perf].[Sale_Heap]

    CREATE TABLE [wwi_perf].[Sale_Hash_Projection_Big2]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX
    )
    AS
    SELECT
        [CustomerId]
        ,CAST([ProductId] as bigint) as [ProductId]
        ,CAST([Quantity] as bigint) as [Quantity]
    FROM
        [wwi_perf].[Sale_Heap]
    ```

It is important to note that all four tables have the exact same number of rows. We will run a query against our `vTableSizes` view to look at the storage being used by all four tables.

    ```sql
    SELECT
        database_name
    ,    schema_name
    ,    table_name
    ,    distribution_policy_name
    ,      distribution_column
    ,    index_type_desc
    ,    COUNT(distinct partition_nmbr) as nbr_partitions
    ,    SUM(row_count)                 as table_row_count
    ,    SUM(reserved_space_GB)         as table_reserved_space_GB
    ,    SUM(data_space_GB)             as table_data_space_GB
    ,    SUM(index_space_GB)            as table_index_space_GB
    ,    SUM(unused_space_GB)           as table_unused_space_GB
    FROM
        [wwi_perf].[vTableSizes]
    WHERE
        schema_name = 'wwi_perf'
        and table_name in ('Sale_Hash_Projection', 'Sale_Hash_Projection2',
            'Sale_Hash_Projection_Big', 'Sale_Hash_Projection_Big2')
    GROUP BY
        database_name
    ,    schema_name
    ,    table_name
    ,    distribution_policy_name
    ,      distribution_column
    ,    index_type_desc
    ORDER BY
        table_reserved_space_GB desc
    ```

    ![Data type selection impact on table storage](./media/lab4_data_type_selection.png)

There are two important conclusions to draw here:
    - In the case of `HEAP` tables, the storage impact of using `BIGINT` instead of `SMALLINT`(for `ProductId`) and `TINYINT` (for `QUANTITY`) is almost 1 GB (0.8941 GB). We're talking here about only two columns and a moderate number of rows (2.9 billion).
    - Even in the case of `CLUSTERED COLUMNSTORE` tables, where compression will offset some of the differences, there is still a difference of 12.7 MB.

>**Note**: If you are using PolyBase external tables to load your SQL pool tables, the defined length of the table row cannot exceed 1 MB. When a row with variable-length data exceeds 1 MB, you can load the row with BCP, but not with PolyBase.

## 3.9. Avoid extensive logging

SQL Pools commit changes through the use of transaction logs, this guarantees that the write operation of the data to the source but also introduces overhead in the system. This impact can be minimized by writing transactionally efficient code. One way to approach this issue is by using minimally logged operations. The difference is, fully logged operations utilize the transaction log for every single row affected, whereas minimally logged operations keep track of extent allocations and meta-data changes only. This translates to minimal logging tracks only the information necessary to roll back a transaction after a rollback. This results in less information tracked in the tranaction log, better performance, and less space consumption.

The following operations are capable of being minimally logged:

- CREATE TABLE AS SELECT (CTAS)
- INSERT..SELECT
- CREATE INDEX
- ALTER INDEX REBUILD
- DROP INDEX
- TRUNCATE TABLE
- DROP TABLE
- ALTER TABLE SWITCH PARTITION

When dealing with bulk load situations such as with CTAS and INSERT...SELECT, both are influenced by the target table definition and depend on the load scenario. The following table explains when bulk operations are fully or minimally logged:  

| Primary Index | Load Scenario | Logging Mode |
| --- | --- | --- |
| Heap |Any |**Minimal** |
| Clustered Index |Empty target table |**Minimal** |
| Clustered Index |Loaded rows do not overlap with existing pages in target |**Minimal** |
| Clustered Index |Loaded rows overlap with existing pages in target |Full |
| Clustered Columnstore Index |Batch size >= 102,400 per partition aligned distribution |**Minimal** |
| Clustered Columnstore Index |Batch size < 102,400 per partition aligned distribution |Full |

It is worth noting that any writes to update secondary or non-clustered indexes will always be fully logged operations.

> **IMPORTANT**: A Synapse Analytics SQL pool has 60 distributions. Therefore, assuming all rows are evenly distributed and landing in a single partition, your batch will need to contain 6,144,000 rows or larger to be minimally logged when writing to a Clustered Columnstore Index. If the table is partitioned and the rows being inserted span partition boundaries, then you will need 6,144,000 rows per partition boundary assuming even data distribution. Each partition in each distribution must independently exceed the 102,400 row threshold for the insert to be minimally logged into the distribution.

Loading data into a non-empty table with a clustered index can often contain a mixture of fully logged and minimally logged rows. A clustered index is a balanced tree (b-tree) of pages. If the page being written to already contains rows from another transaction, then these writes will be fully logged. However, if the page is empty then the write to that page will be minimally logged.

DELETE operations are fully logged operations. To improve the performance of large delete operions in a table or partition, it makes sense to SELECT the data you wish to keep, which is a minimally logged operation. Essentially what is recommended is to create a new table using CTAS with the data you want to keep, then after it is created use RENAME to fully replace the old table with the new one.

To illustrate this concept, consider the following scenario. We wish to keep data for customers that have an id of greater than 900000. To implement a minimal logging approach to delete transaction items for customers with ids lower than 900000. We can use the following CTAS query to isolate the transaction items that should be kept:

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Hash_v2]
    WITH
    (
        DISTRIBUTION = ROUND_ROBIN,
        HEAP
    )
    AS
    SELECT
        *
    FROM
        [wwi_perf].[Sale_Hash]
    WHERE
        CustomerId >= 900000
    ```

Once complete, the next step would be to delete the `Sale_Heap` table and rename `Sale_Heap_v2` to `Sale_Heap`. If we were to compare this CTAS operation with a classical delete, you'd observe the query running for a time far exeeding the CTAS query.

## 3.10. Best practices

In this section, we've covered a variety of tools at your disposal that can help investigate potential performance issues. We've talked about scaling, table structure, indexing and partitioning. You've learned how to avoid the overhead of logging using minimally logged operations, and how to take advantage of materialized views. Here are some key take aways regarding the best practices surrounding getting the best performance out of your SQL Pool.

- Maintain Statistics - we recommend enabling `AUTO_CREATE_STATISTICS` to keep statistics updated daily or after each load to ensure they are always up to date.
  
- Use DMVs to monitor and optimize queries, label your queries to assist in identifying them.
  
- Use minimally logged operations wherever possible.
  
- Use PolyBase to load and export data quickly. PolyBase has been designed to take advantage of the MPP (Massively Parallel Processing) architecture and can load data in a fraction of the time it takes other tools, remember to use CTAS to minimize transaction logging.

- Load then query external tables. When reading a large number of files, the SQL Pool must manually read the entire file and store it in tempdb in order to query the data. If this data is routinely needed, it is more efficient to load this data into a local table and query it directly.

- Hash distribute large tables. When tables exceed 60 million rows, it is recommended to select a column to be utilized as a hash that will will evenly distribute across all 60 distributions.

- Do not over-partition. If partitions have fewer than 1 million rows, the effectiveness of the CCI is reduced. Keep in mind that if you create a table with 100 partitions, it is distributing across 60 databases and therefore yields 6000 partitions. When experimenting with partitions in your workload, it's best to start with weekly or monthly partitions versus daily partitions.

- Minimize transaction sizes. The larger the transaction, the larger the transaction log overhead, and the longer it will take for the query to complete, and any rollbacks will take an equal amount of time. It is beneficial to split larger transactions into smaller ones, for instance, split a large insert method that takes an hour to complete, into four smaller ones that take 15 minutes. Consider if it's beneficial to use minimally logged operations in its place, such as the use of CTAS to write to a table the data you want to keep and swap out the table, instead of using an expensive DELETE query and deleting row by row.
  
- Reduce the query result sizes. Avoid client-side issues by adding `TOP N` syntax to your queries. You can also CTAS the query result to a temporary table then use PolyBase export for downlevel processing.

- Use the smallest possible column size. Reducing the size of the columns, reduces the size of the rows, and reduces the size of the table on disk. Each of these improves overall query performance.

- Optimize clustered columnstore indexes. Through using the investigational tools and techniques described in this section, check for segment overlaps, data skew, and consider using ordered clustered columnstore indexes where it is beneficial.
