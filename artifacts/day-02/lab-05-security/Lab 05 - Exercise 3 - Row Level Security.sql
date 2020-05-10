/*	Row level Security (RLS) in Azure Synapse enables us to use group membership to control access to rows in a table.
	Azure Synapse applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security in Azure Synapse.*/

----------------------------------Row-Level Security (RLS), 1: Filter predicates------------------------------------------------------------------
-- Step:1 The Sale table has two Analyst values: DataAnalystMiami and DataAnalystSanDiego. 
--     Each analyst has jurisdiction across a specific Region. DataAnalystMiami on the South East Region
--      and DataAnalystSanDiego on the Far West region.
SELECT DISTINCT Analyst, Region FROM wwi_security.Sale order by Analyst ;

/* Scenario: WWI requires that an Analyst only see the data for their own data from their own region. The CEO should see ALL data.
    In the Sale table, there is an Analyst column that we can use to filter data to a specific Analyst value. */

/* We will define this filter using what is called a Security Predicate. This is an inline table-valued function that allows
    us to evaluate additional logic, in this case determining if the Analyst executing the query is the same as the Analyst
    specified in the Analyst column in the row. The function returns 1 (will return the row) when a row in the Analyst column is the same as the 
    user executing the query (@Analyst = USER_NAME()) or if the user executing the query is the CEO user (USER_NAME() = 'CEO')
    whom has access to all data.
*/

-- Review any existing security predicates in the database
SELECT * FROM sys.security_predicates

--Step:2 Create a new Schema to hold the security predicate, then define the predicate function. It returns 1 (or True) when
--  a row should be returned in the parent query.
GO

CREATE FUNCTION wwi_security.fn_securitypredicate(@Analyst AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result
    WHERE @Analyst = USER_NAME() OR USER_NAME() = 'CEO'
GO
-- Now we define security policy that adds the filter predicate to the Sale table. This will filter rows based on their login name.
CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE wwi_security.fn_securitypredicate(Analyst)
ON wwi_security.Sale
WITH (STATE = ON);

------ Allow SELECT permissions to the Sale Table.------
GRANT SELECT ON wwi_security.Sale TO CEO, DataAnalystMiami, DataAnalystSanDiego;

-- Step:3 Let us now test the filtering predicate, by selecting data from the Sale table as 'DataAnalystMiami' user.
EXECUTE AS USER = 'DataAnalystMiami' 
SELECT * FROM wwi_security.Sale;
revert;
-- As we can see, the query has returned rows here Login name is DataAnalystMiami

-- Step:4 Let us test the same for  'DataAnalystSanDiego' user.
EXECUTE AS USER = 'DataAnalystSanDiego';
SELECT * FROM wwi_security.Sale;
revert;
-- RLS is working indeed.

-- Step:5 The CEO should be able to see all rows in the table.
EXECUTE AS USER = 'CEO';  
SELECT * FROM wwi_security.Sale;
revert;
-- And he can.

--Step:6 To disable the security policy we just created above, we execute the following.
ALTER SECURITY POLICY SalesFilter  
WITH (STATE = OFF);

DROP SECURITY POLICY SalesFilter;
DROP FUNCTION wwi_security.fn_securitypredicate;