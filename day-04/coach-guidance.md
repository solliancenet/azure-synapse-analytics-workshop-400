# Coach guidance

## What does a coach do

### Teams

* Facilitate collaboration​
* Set expectations​
* Ask leading questions, offer resources instead of answers​
* Encourage creativity​
* Problem solve: technical and interpersonal

### Manage sentiment

* Content will be challenging and **frustrating** at times​
* Let them be challenged but not blocked​
* Check in frequently and raise any issues or what is working well

## Some things to keep in mind

* No step-by-step instructions or "right" answer​
* Not all pain points are removed​
* Everyone should be learning and having fun. That includes YOU!​
* Keep Challenge Content and reference solutions private​

> Teams may not complete all challenges. However, if they are unable to import all data in the first challenge, they can safely move on to the remaining challenges.

## 1 - Configure the environment and raw import

### Happy path

The team starts out by exploring the source data **and** the existing data that's already been moved into the SQL pool tables. They may assume that the tables are already good to go, but they're not.

There are various issues with the source files, as outlined in the table below, under *things to watch out for*. Because of these issues, it will take varying levels of skill from the team members to overcome them and successfully complete this and the challenge that follows. Ideally, the team will divide and conquer this challenge by having some focus on the Parquet files and others focus on the CSV files, as each have their unique set of problems.

Create a permanent or temporary Heap table to more rapidly ingest data into the SQL pool, then insert into the existing table.

Since this is a "raw import", when they are ready, they will likely use T-SQL COPY statements to import into the staging (Heap) table, then insert that into the existing table. COPY is recommended since the CSV files have nonstandard line endings, which PolyBase cannot handle.

### Coach's notes

Have attendees show you the following before you sign off on this challenge:

* All source files (Parquet and CSV) have been successfully imported into the SQL pool.
  * The total record count in the SQL pool should be **TODO:** provide this number.

If you see the team try to initially import all the data at once, suggest to them that they should experiment with a subset of the data beforehand. That way, if they discover any unforeseen issues, they will not have wasted valuable time.

If the team is completely stuck and have spent more than 2 hours on this challenge, move them along to the third challenge, which is about optimizing existing business-critical queries and creating new queries and reports. Loading the remaining data is not a prerequisite for those challenges.

### Things to watch out for

There are some serious challenges with the source data, including:

| Name | Description |
| --- | --- |
| Poor initial table design | There is already some data in the SQL pool in several poorly designed fact tables. The following problems are "hidden" in the structure: <br>- Sub-optimal distribution strategy<br>- Sub-optimal partitioning strategy<br>- Incorrect indexing<br>- Incorrect data types used for several fields<br><br> The purpose is to mislead attendees in (wrongly) assuming the existing data is "good to go". When this assumption is made without corrective actions, all the subsequent tasks will be impacted. |
| Missing CR-LF in several CSV files | Some of the external CSV files are "corrupted". A misbehaving export tool has removed all CR-LF characters, literally leaving the files as huge, one-row files.<br><br>The purpose is to force advanced, high-scale data exploration and preparation. Should only work in a decent amount of time is Spark is used. |
| Separation issues in CSV files | The CSV files use `,` as separator. There are string columns that contain both `"` and `,` characters which makes processing the CSV files error prone.<br><br>The purpose is to force advanced, high-scale data exploration and preparation. Should only work in a decent amount of time is Spark is used. |
| Some inputs come in ZIP files | Forces the use of Spark. Level 1 - can you deal with a ZIP file? Level 2 - can you deal with a massive number of ZIP files? |
| The sheer volume of data | The sales data contains around 30 billion records. Any data processing will "suffer" performance-wise.<br><br>The purpose is to limit the number of trial-and-error cycles attendees can run. |

If the team does not take the time to evaluate the data before immediately importing it, they will fail. There are various skill levels involved in extracting, transforming, and loading this data.

## 2 - Optimize data load

### Happy path

### Coach's notes

### Things to watch out for

| Name | Description |
| --- | --- |
| Gotchas for data flows, pipelines | Predictable performance of pipelines, time cap on the execution time of pipelines. |

## 3 - Optimize performance of existing queries and create new queries

### Happy path

### Coach's notes

### Things to watch out for

| Name | Description |
| --- | --- |
| Sub-optimal structure of existing queries | The existing queries feature several T-SQL issues, most of them apparent.<br><br>The purpose is to lure attendees into a process of T-SQL code optimization and move them away from table structure optimization. |
| Delta lake approach | The purpose is to force attendees into thinking about the data quality/reliability vs speed of delivery compromise. |
| Gaps in the incoming stream of sales files | Every now and then, some files will simply not be available. This will have an impact on the quality of data at bronze and silver levels.<br><br>The purpose is to force attendees into dealing with presentation inconsistencies originating from delayed data. |

## 4 - Manage and monitor the solution

### Happy path

### Coach's notes

### Things to watch out for
