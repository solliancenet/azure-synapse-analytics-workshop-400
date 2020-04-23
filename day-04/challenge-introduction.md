# Challenge introduction

WWI is in the process of building a new, modern analytics solution. The old analytics solution was built using an older, on-premises version of SQL Server and was based on the relational engine only. WWI's top management expects the new solution to support the strategic move towards near-real-time data analysis.

The core objective of this PoC challenge is to prove that Azure Synapse Analytics is the right platform to be used by the new solution.

The current situation is the following:

- Sales data is currently being inserted into the SQL pool. About 30% of the data is already in the internal tables of the SQL Pool. This roughly covers Jan 2012 to April 2012.
- The remainder of the data is in external files, CSV and Parquet.
- Around August 2012 the sales export procedures have been changed, resulting in a shift from CSV files to Parquet files.
- Consequently, the CSV external files cover May - August 2012 and the Parquet external files cover September - December 2012.
- WWI has several business-critical queries that are performing poorly. They need to be significantly optimized to meet the latest business needs.
- On a more general note, top management is demanding more and more a departure from the traditional "analyze today yesterday's data". The goal is to significantly reduce the gap between the moment data is generated and the moment it ends up in dashboards.
- The CISO of WWI is driving a company-wide security initiative that covers, among many other projects, the new analytics solution project as well. Consequently, the solution is expected to meet several key security requirements including securing the end-to-end data processes (from external files to the serving layer).
- One of the current major pain points of WWI's CIO is the limited capabilities of insights into various data processes. The CIO expects the new solution to significantly increase the visibility into all the data processes developed as part of the new analytical solution.

In this challenge, you are expected to achieve the following major goals:

1. Import the remainder of the data captured in the external files
2. Design and implement a repeatable process for the import at 1. The goal of this process is to meet another key goal - a measurable RTO for the full rebuild of the warehouse (the maximum expected RTO is 60 minutes)
3. Improve the performance of the business critical queries. They must run in under 5 minutes per query.
4. Data post 2012 is now coming in as a continuous stream of Parquet files. Propose and implement a delta lake architecture where top management can get data various compromises between speed of delivery and accuracy/completeness. Provide a bronze level where freshly collected sales data is analyzed using Synapse SQL Serverless and exposed into dashboards. Provide a bronze level where data quality has been increased via data engineering. Finally, provide the gold level where top-quality data has been persisted in a Synapse SQL Pool.
5. Implement and demonstrate end-to-end security measures for the data warehouse rebuild process.
6. Monitor all data processes and react to potential problems that might occur.

## Challenge split

**TBD: What is the approach we want to take: one day-long challenge vs. 4 individual challenges?**

| Title | Overview | Challenges |
| ---| --- | --- |
| [1 - Configure the environment and raw import](challenges.md#1---configure-the-environment-and-raw-import) | Review the files that you need to import into Synapse Analytics, configure your solution accordingly, and complete the full import. | 1 |
| [2 - Optimize data load](challenges.md#2---optimize-data-load) | Create a data loading pipeline that provides a repeatable import process and meets the RTO requirements of a 60-minute full rebuild of the warehouse. | 2 |
| [3 - Optimize performance of existing queries and create new queries](challenges.md#3---optimize-performance-of-existing-queries-and-create-new-queries) | Uncover query performance issues and craft queries that help WWI unlock new insights into both historical and new data. | 3 |
| [4 - Manage and monitor the solution](challenges.md#4---manage-and-monitor-the-solution) | Protect WWI's data with an end-to-end security configuration for the data warehouse. Address the CIO's concerns about WWI's ability to monitor the data pipeline by providing visibility into each process and configuring alerts as needed. | 5 & 6 |

## Challenge pitfalls

The following table describes the pitfalls hidden in the challenge:

| Name | Description |
| --- | --- |
| Poor initial table design | There is already some data in the SQL pool in several poorly designed fact tables. The following problems are "hidden" in the structure: <br>- Sub-optimal distribution strategy<br>- Sub-optimal partitioning strategy<br>- Incorrect indexing<br>- Incorrect data types used for several fields<br><br> The purpose is to mislead attendees in (wrongly) assuming the existing data is "good to go". When this assumption is made without corrective actions, all the subsequent tasks will be impacted. |
| Missing CR-LF in several CSV files | Some of the external CSV files are "corrupted". A misbehaving export tool has removed all CR-LF characters, literally leaving the files as huge, one-row files.<br><br>The purpose is to force advanced, high-scale data exploration and preparation. Should only work in a decent amount of time is Spark is used. |
| Separation issues in CSV files | The CSV files use `,` as separator. There are string columns that contain both `"` and `,` characters which makes processing the CSV files error prone.<br><br>The purpose is to force advanced, high-scale data exploration and preparation. Should only work in a decent amount of time is Spark is used. |
| Some inputs come in ZIP files | Forces the use of Spark. Level 1 - can you deal with a ZIP file? Level 2 - can you deal with a massive number of ZIP files? |
| The sheer volume of data | The sales data contains around 30 billion records. Any data processing will "suffer" performance-wise.<br><br>The purpose is to limit the number of trial-and-error cycles attendees can run. |
| Sub-optimal structure of existing queries | The existing queries feature several T-SQL issues, most of them apparent.<br><br>The purpose is to lure attendees into a process of T-SQL code optimization and move them away from table structure optimization. |
| Gotchas for data flows, pipelines | Predictable performance of pipelines, time cap on the execution time of pipelines. |
| Delta lake approach | The purpose is to force attendees into thinking about the data quality/reliability vs speed of delivery compromise. |
| Gaps in the incoming stream of sales files | Every now and then, some files will simply not be available. This will have an impact on the quality of data at bronze and silver levels.<br><br>The purpose is to force attendees into dealing with presentation inconsistencies originating from delayed data. |
| Security | TBD |
| Monitoring | TBD |

## Links

- [Team challenges](challenges.md)
- [Coach guidance](coach-guidance.md)
