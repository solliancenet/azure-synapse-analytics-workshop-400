# Monitoring

Running mixed workloads can pose resource challenges on busy systems. Solution Architects seek ways to separate classic data warehousing activities (such as loading, transforming and querying data) to ensure that enough resources exist to hit SLAs.

Synapse SQL pool workload management in Azure Synapse consists of three high-level concepts: Workload Classification, Workload Importance and Workload Isolation. These capabilities give you more control over how your workload utilizes system resources.

Workload importance influences the order in which a request gets access to resources. On a busy system, a request with higher importance has first access to resources. Importance can also ensure ordered access to locks.

Workload isolation reserves resources for a workload group. Resources reserved in a workload group are held exclusively for that workload group to ensure execution. Workload groups also allow you to define the amount of resources that are assigned per request, much like resource classes do. Workload groups give you the ability to reserve or cap the amount of resources a set of requests can consume. Finally, workload groups are a mechanism to apply rules, such as query timeout, to requests.

## Task 1 - Workload Importance in Azure Synapse

Often in a data warehouse scenario you have users who need their queries to run quickly. The user could be executives of the company who need to run reports or the user could be an analyst running an adhoc query. 

Setting importance in Synapse SQL for Azure Synapse allows you to influence the scheduling of queries. Queries with higher importance will be scheduled to run before queries with lower importance. To assign importance to queries, you need to create a workload classifier.

1. Open Synapse Analytics Studio, and then navigate to the `Develop` hub. Then open `Lab 08 - Exercise 1 - WorkLoad Importance` from the list of SQL Scripts. 

2. Select `AzureSynapseDW` under `Connect To` and highlight the first SQL Command shown below. Select `Run` to confirm that there are no queries currently being run by users logged in as `CEONYC` or `AnalystNYC`.

![](media/ex05-confirm-no-queries.png)

3. You will flood the system with queries and see what happens for `CEONYC` and `AnalystNYC`. To do this, we'll run a Azure Synapse Pipeline which triggers queries. Select the `Orchestrate` Tab. **Run** `ExecuteDataAnalystAndCEOQueries` Pipeline, which will run / trigger the `AnalystNYC` and > `CEONYC` queries.

4. Let's see what happened to all the queries we just triggered as they flood the system. **Select** the SQL Command between lines #20-23 and run the query.

![](media/ex05-observe-flood.png)

5. We will give our `CEONYC` queries priority by implementing the **Workload Importance** feature. In order to do that, **select** the SQL Command between lines #26-29 and run the query.

![](media/ex05-workload-importance.png)

6. Let's flood the system again with queries and see what happens this time for `CEONYC` and `AnalystNYC` queries. To do this, we'll run a Azure Synapse Pipeline which triggers queries. **Select** the `Orchestrate` Tab, **run** `ExecuteDataAnalystAndCEOQueries` Pipeline, which will run / trigger the `AnalystNYC` and `CEONYC` queries. 

7. Run the SQL Command between lines #39-42 to see what happens to the `CEONYC` queries this time.

![](media/ex05-workload-importance-2.png)

## Task 2 - Workload Isolation

Workload isolation means resources are reserved, exclusively, for a workload group. Workload groups are containers for a set of requests and are the basis for how workload management, including workload isolation, is configured on a system. A simple workload management configuration can manage data loads and user queries. 

In the absence of workload isolation, requests operate in the shared pool of resources. Access to resources in the shared pool is not guaranteed and is assigned on an importance basis.

Configuring workload isolation should be done with caution as the resources are allocated to the workload group even if there are no active requests in the workload group. Over-configuring isolation can lead to diminished overall system utilization.

Users should avoid a workload management solution that configures 100% workload isolation: 100% isolation is achieved when the sum of `min_percentage_resource` configured across all workload groups equals 100%. This type of configuration is overly restrictive and rigid, leaving little room for resource requests that are accidentally mis-classified. There is a provision to allow one request to execute from workload groups not configured for isolation.

1. Open Synapse Analytics Studio, and then navigate to the `Develop` hub. Then open `Lab 08 - Exercise 2 - Workload Isolation` from the list of SQL Scripts. 

2. Select `AzureSynapseDW` under `Connect To` and highlight the first SQL Command shown below. 

![](media/ex05-workload-isolation.png)

The code creates a workload group called `CEODemo` to reserve resources exclusively for the workload group. In this example, a workload group with a `MIN_PERCENTAGE_RESOURCE` set to 50% and `REQUEST_MIN_RESOURCE_GRANT_PERCENT` set to 25% is guaranteed 2 concurrency.

3. **select** the SQL Command between lines #17-21 and **run** the query to create a workload Classifier called `CEODreamDemo` that would assigning a workload group and importance to incoming requests.

![](media/ex05-workload-classifier.png)

4. Let's confirm that there are no active queries being run by `BusinessAnalystNYC`.  **select** the SQL Command between lines #25-31 and **run**.

![](media/ex05-workload-isolation-confirm.png)

5. Let's flood the system with queries and see what happens for `BusinessAnalystNYC`. To do this, we will run a Azure Synapse Pipeline which triggers queries. Select the `Orchestrate` Tab. **Run** `Execute BusinessAnalystNYC Script` Pipeline, which will run / trigger  `BusinessAnalystNYC` queries.

6. Let us see what happened to all the `BusinessAnalystNYC` queries we just triggered as they flood the system. **select** the SQL Command between lines #44-50 and **run**.

![](media/ex05-check-system-flood.png)

7. In this step, we will set 3.25% minimum resources per request. **select** the SQL Command between lines #53-66 and **run**.

![](media/ex05-minimum-resources-per-request.png)

> **Note**: Configuring workload containment implicitly defines a maximum level of concurrency. With a CAP_PERCENTAGE_RESOURCE set to 60% and a REQUEST_MIN_RESOURCE_GRANT_PERCENT set to 1%, up to a 60-concurrency level is allowed for the workload group. Consider the method included below for determining the maximum concurrency:
> 
> [Max Concurrency] = [CAP_PERCENTAGE_RESOURCE] / [REQUEST_MIN_RESOURCE_GRANT_PERCENT]

8. Let's flood the system again and see what happens for `BusinessAnalystNYC`. To do this, we will run a Azure Synapse Pipeline which triggers queries. Select the `Orchestrate` Tab. **Run** `Execute BusinessAnalystNYC Script` Pipeline, which will run / trigger  `BusinessAnalystNYC` queries.

9. Let's see what happened to all of the `BusinessAnalystNYC` queries we just triggered as they flood the system. **select** the SQL Command between lines #77-83 and **run**.

![](media/ex05-check-system-flood-2.png)

## Resources

- [Workload Group Isolation (Preview)](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-workload-isolation)
- [Workload Isolation](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-workload-isolation)
- [Workload Importance](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-workload-importance)
- [Workload Classification](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-workload-classification)