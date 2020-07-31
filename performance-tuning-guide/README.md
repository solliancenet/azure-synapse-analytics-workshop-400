# Azure Synapse Analytics Performance Tuning Guide

1. [Overview](./01-overview.md)

2. [Optimizing pipelines and data flows](./02-optimizing-pipelines-and-data-flows.md)

    2.1. Integration runtimes

    2.2. Linked services

    2.3. Integration units and parallelism

    2.4. Best practices

3. [Optimizing SQL Pools](./03-optimizing-sql-pools.md)

    3.1. Sizing and resource allocation (DWUs)

    3.2. Table structure

    + 3.2.1. Improve table structure with distribution

    + 3.2.2. Improve table structure with partitioning
  
    3.3. Query performance

    + 3.3.1. Improve query performance with approximate count

    + 3.3.2. Improve query performance with materialized views

    + 3.3.3. Improve query performance with result set caching

    3.4. Manage statistics

    3.5. Manage indexes

    + 3.5.1. Create and update indexes

    + 3.5.2. Ordered Clustered Columnstore Indexes

    3.6. Monitor space usage

    3.7. Monitor column store storage

    3.8. Choose the right data types

    3.9. Avoid extensive logging

    3.10. Best practices

4. [Optimizing Spark Pools](./04-optimizing-spark-pools.md)

    4.1. Sizing and resource allocation

    4.2. Notebooks and Spark session

    4.3. Distribution and parallelism in Spark notebooks

    4.4. Best practices

5. [Optimizing Power BI](./05-optimizing-power-bi.md)
