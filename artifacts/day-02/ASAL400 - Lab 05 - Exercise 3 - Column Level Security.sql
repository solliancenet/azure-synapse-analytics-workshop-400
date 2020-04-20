    /*  Column-level security feature in Azure Synapse simplifies the design and coding of security in application.
        It ensures column level security by restricting column access to protect sensitive data. */

    --Step 1: Let us see how this feature in Azure Synapse works. Before that let us have a look at the Campaign table.
    select  Top 100 * from wwi.CampaignAnalytics
    where City is not null and state is not null

    /*  Consider a scenario where there are two users.
        A CEO, who is an authorized  personnel with access to all the information in the database
        and a Data Analyst, to whom only required information should be presented.*/

    -- Step:2 We look for the names “CEO” and “DataAnalystMiami” present in the Datawarehouse.
    SELECT Name as [User1] FROM sys.sysusers WHERE name = N'CEO'
    SELECT Name as [User2] FROM sys.sysusers WHERE name = N'DataAnalystMiami'


    -- Step:3 Now let us enforcing column level security for the DataAnalystMiami.
    /*  Let us see how.
        The CampaignAnalytics table in the warehouse has information like Region, Country, ProductCategory, CampaignName, City,State,RevenueTarget , and Revenue.
        Of all the information, Revenue generated from every campaign is a classified one and should be hidden from DataAnalystMiami.
        To conceal this information, we execute the following query: */

    GRANT SELECT ON wwi.CampaignAnalytics([Region],[Country],[ProductCategory],[CampaignName],[RevenueTarget],
    [City],[State]) TO DataAnalystMiami;
    -- This provides DataAnalystMiami access to all the columns of the CampaignAnalytics table but Revenue.

    -- Step:4 Then, to check if the security has been enforced, we execute the following query with current User As 'DataAnalystMiami'
    EXECUTE AS USER ='DataAnalystMiami'
    select * from wwi.CampaignAnalytics
    ---
    EXECUTE AS USER ='DataAnalystMiami'
    select [Region],[Country],[ProductCategory],[CampaignName],[RevenueTarget],
    [City],[state] from wwi.CampaignAnalytics

    /*  And look at that, when the user logged in as DataAnalystMiami tries to view all the columns from the Campaign_Analytics table,
        he is prompted with a ‘permission denied error’ on Revenue column.*/

    -- Step:5 Whereas, the CEO of the company should be authorized with all the information present in the warehouse.To do so, we execute the following query.
    Revert;
    GRANT SELECT ON wwi.CampaignAnalytics TO CEO;  --Full access to all columns.

    -- Step:6 Let us check if our CEO user can see all the information that is present. Assign Current User As 'CEO' and the execute the query
    EXECUTE AS USER ='CEO'
    select * from wwi.CampaignAnalytics
    Revert;