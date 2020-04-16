# Monitoring

```
Monitor Execution
Monitor Hub: Pipelines, SQL Pools, Spark apps
Troubleshooting 
Workload Management
```

## Task 1 - Workload Importance in Azure Synapse

1. Open Synapse Analytics Studio, and then navigate to the `Develop` hub. Then open `3 WorkLoad Importance` from the list of SQL Scripts. 

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

1. Open Synapse Analytics Studio, and then navigate to the `Develop` hub. Then open `4 Workload Isolation` from the list of SQL Scripts. 

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

8. Let's flood the system again and see what happens for `BusinessAnalystNYC`. To do this, we will run a Azure Synapse Pipeline which triggers queries. Select the `Orchestrate` Tab. **Run** `Execute BusinessAnalystNYC Script` Pipeline, which will run / trigger  `BusinessAnalystNYC` queries.

9. Let's see what happened to all of the `BusinessAnalystNYC` queries we just triggered as they flood the system. **select** the SQL Command between lines #77-83 and **run**.

![](media/ex05-check-system-flood-2.png)




