# Challenge introduction

WWI is in the process of building a new, modern analytics solution. The old analytics solution was built using an older, on-premise version of SQL Server and was based on the relational engine only.

The core objective of this PoC challenge is to prove that Azure Synapse Analytics is the right platform to be used by the new solution.

The current situation is the following:

- Sales data is currently being inserted into the SQL pool. About 30% of the data is already in the internal tables of the SQL Pool. This roughly covers Jan 2012 to April 2012.
- The remainder of the data is in external files, CSV and Parquet.
- Around August 2012 the sales export procedures have been changed, resulting in a shift from CSV files to Parquet files.
- Consequently, the CSV external files cover May - August 2012 and the Parquet external files cover September - December 2012.
- WWI has several business-critical queries that are performing poorly. They need to be significantly optimized to meet the latest business needs.
- The CISO of WWI is driving a company-wide security initiative that covers, among many other projects, the new analytics solution project as well. Consequently, the solution is expected to meet several key security requirements including securing the end-to-end data processes (from external files to the serving layer).
- One of the current major pain points of WWI's CIO is the limited capabilities of insights into various data processes. The CIO expects the new solution to significantly increase the visibility into all the data processes develops as part of the new analytical solution.

In this challenge, you are expected to achieve the following major goals:

1. Import the remainder of the data captured in the external files
2. Design and implement a repeatable process for the import at 1. The goal of this process is to meet another key goal - a measurable RTO for the full rebuild of the warehouse (the maximum expected RTO is 60 minutes)
3. Improve the performance of the business critical queries. They must run in under 5 minutes per query.
4. Implement and demonstrate end-to-end security measures for the data warehouse rebuild process.
5. Monitor all data processes and react to potential problems that might occur.

## Challenge pitfalls

The following table describes the pitfalls hidden in the challenge:

Name | Description
--- | ---
Poor initial table design | There is already some data in the SQL pool in several poorly designed fact tables. The following problems are "hidden" in the structure: <br>- Sub-optimal distribution strategy<br>- Sub-optimal partitioning strategy<br>- Incorrect indexing<br>- Incorrect data types used for several fields<br><br> The purpose is to mislead attendees in (wrongly) assuming the existing data is "good to go". When this assumption is made without corrective actions, all the subsequent tasks will be impacted.
Missing CR-LF in several CSV files | Some of the external CSV files are "corrupted". A misbehaving export tool has removed all CR-LF characters, literally leaving the files as huge, one-row files.<br><br>The purspose is to force advanced, high-scale data exploration and preparation. Should only work in a decent amount of time is Spark is used.
Separation issues in CSV files | The CSV files use `,` as separator. There are string columns that contain both `"` and `,` characters which makes processing the CSV files error prone.<br><br>The purspose is to force advanced, high-scale data exploration and preparation. Should only work in a decent amount of time is Spark is used.
Some inputs come in ZIP files | Forces the use of Spark. Level 1 - can you deal with a ZIP file? Level 2 - can you deal with a massive number of ZIP files?
The sheer volume of data | The sales data contains around 30 billion records. Any data processing will "suffer" performance-wise.<br><br>The purpose is to limit the number of trial-and-error cycles attendees can run.
Sub-optimal structure of existing queries | The existing queries feature several T-SQL issues, most of them apparent.<br><br>The purpose is to lure attendees into a process of T-SQL code optimization and move them away from table structure optimization.
Gotchas for data flows, pipelines | Predictable performance of pipelines, time cap on the execution time of pipelines.
Delta lake approach | Introduce requirement about a delta lake approach. TBD
Security | TBD
Monitoring | TBD
