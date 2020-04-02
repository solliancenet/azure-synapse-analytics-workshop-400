# Challenge introduction

WWI is in the process of building a new analytics solution based on Azure Synapse Analytics. The old analytics solution was built using an older, on-premise version of SQL Server and was based on the relational engine only.

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
