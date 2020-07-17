# 1. Overview

This guide focuses on Azure Synapse Analytics performance tuning. The following major functional areas of Azure Synapse Analytics are covered:

- Pipelines and Data Flows
- SQL Pools
- Spark Pools

The **Pipelines and Data Flows** section focuses on performance tuning involving:

- Integration runtimes
- Linked services
- Integration units and parallelism

The section ends with a summary of best practices for optimizing the performance of pipelines and data flows.

The **SQL Pools** section focuses on performance tuning involving:

- SQL pool sizing and resource allocation (Data Warehouse Units)
- Table structure (improving with distribution and partitioning)
- Query performance (improving with approximate counting, materialized views, and result set caching)
- Manage statistics
- Manage indexes (crate and update indexes, use Ordered Columnstore Indexes)
- Monitor space usage
- Monitor column store storage
- Choose the right data types
- Avoid extensive logging

The section ends with a summary of best practices for optimizing the performance of SQL pools.

The **Spark Pools** section focuses on performance tuning involving:

- Spark pool sizing and resource allocation
- Notebooks and Spark sessions
- Distribution and parallelism in Spark notebooks

The section ends with a summary of best practices for optimizing the performance of Spark pools.