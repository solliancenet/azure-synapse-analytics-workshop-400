# Activity 01: Data Lake Design & Security Considerations

Wide World Importers is ready to build a pipeline that copies their sales transactions from a table in an Oracle database to the data lake. 

**Requirements**

* The pipeline that copies data will run on a scheduled basis, once per day. 
* They would like to ingest this raw data applying the minimal amount of transformations to it.
* They want to ensure that their data lake always contains a copy of the original data, so that if their downstream processing has calculation or transormation errors, they can always re-compute from the original.
* Additionally, they want to avoid the file format prescribing what tools can be used to examine and process the data by making sure that the file format selected can be used by the broadest possible range of of industry standard tools.
* The folder structure needs to be performant for typical exploratory and analytic queries for this type of data.  

**Example of the data**

WWI has provided the following example of the data to you. You can assume they have hand selected rows that are *most* representitive of the data. 

|SaleKey|CityKey|CustomerKey|BillToCustomerKey|StockItemKey|DeliveryDateKey|SalespersonKey|WWIInvoiceID|Description|Package|Quantity|UnitPrice|TaxRate|TotalExcludingTax|TaxAmount|Profit|TotalIncludingTax|TotalDryItems|TotalChillerItems|LineageKey
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- 
|294018|98706|0|0|25|2012-01-04|156|57894|Black and orange, handle with care despatch tape  48mmx75m|Each|144|3.70|15.000|532.80|79.92|345.60|612.72|144|0|14
|294019|98706|0|0|216|2012-01-04|156|57894|USB, food flash drive - sushi roll|Each|5|32.00|15.000|160.00|24.00|100.00|184.00|5|0|14
|294020|98706|0|0|168|2012-01-04|156|57894|IT joke mug - keyboard not found � press F1 to continue (White)|Each|10|13.00|15.000|130.00|19.50|85.00|149.50|10|0|14
|294021|98706|0|0|100|2012-01-04|156|57894|Dinosaur battery-powered slippers (Green) L|Each|4|32.00|15.000|128.00|19.20|96.00|147.20|4|0|14

## Whiteboard
Open your whiteboard for the event, and in the area for Activity 1 provide your answers to the following challenges.

*The following challenges are already present within the whiteboard template provided.*

Challenges
1. What file format should they use for the raw data? Why did you recommend this file format, provide at least two reasons? 

    ANSWER: 
    * CSV files would be the closest file format to raw data. 
    * While some amount of transformation is required to convert the row set of data to a delimited format, it is the minimal amount and satifies the requirements that it, barring any mistakes in the transformation, accurately reflects the original. 
    * CSV is also the most widely supported file format.    

2. What specific settings should WWI use in configuring the way the dataset is serialized to disk (pay particular attention to the `Description` field? Why did you suggest these?

    ANSWER:
    * Field delimiter: To delimit fields, they should use the pipe delimiter as the comma character is used within the description field. Using pipe instead of a comman will make it easier for downstream tools to properly load the data and will help guard against mistakes where the description field is loaded as several columns.  
    * Row delimiter: Rows are seperated by standard (carriage return) CR and LF (line feed) character pairs. 
    * Character endcoding: UTF-8 should allow for properly representing the range ofcharacters displayed.

3. Diagram the folder structure you would recommend they use in the hierarchical filesystem. Be sure to indicate filesystem, folders and files and describe how each layer (filesystem, folder and file) derives its name. 

    ANSWER:
    * **prod**   (filesystem, one for dev/test and one for production)
        * **raw** (folder)
        * **sales**   (folder)
            * **2012**   (folder, name set from year extracted from DeliveryDateKey)
            * **Q1**   (folder, quarter inferred from DelieryDateKey)
                * **InvoiceDateKey=2012-01-01**   (folder, name formatted to support filtering derived from InvoiceDateKey)
                * **part-00007-c4fc4c0c-fb33-435b-865a-6dc61ea44d28.c000.csv**   (GUID name, splitting files over a certain size into several files, CSV extension)
            * ... additional years, quarters, days and files structured as above

4. How does your folder structure support query performance for typical exploratory and analytic queries for this type of data?

    ANSWER:
    * Most analytic queries for sales data will be usefully be constrained by date. 
    * Irrespective of the query engine used, if files not needed to address the query do not need to be read from disk, then a query performance improvement is the result. 
    * The folder structure suggested allows this type of pruning at the year, quarter and even day levels. 
    * The format used to name the day level of folder is specifically supported by most data processing tools, enabling control over the maximum size of any individual CSV file while allowing an unlimited amount of transaction data to be written per day.  


5. WWI consider this data confidential, because if it were to fall into the hands of the competition it would cause irreperable harm. Diagram how you would deploy the data lake and secure access to the data lake endpoint? Be sure to illustrate how data flows between your Azure Synapse Analytics Workspace and the data lake and explain why this addresses WWI's requirements. Use the icons provided in the palette to diagram your solution.

    ANSWER:
    * Deploy a Managed workspace VNet within Azure Synapse Analytics. This can only be done when you create the Azure Synapse workspace. When you create your Azure Synapse workspace, you can choose to associate it to a VNet. The VNet associated with your workspace is managed by Azure Synapse. This VNet is called a `Managed workspace VNet`.
    * Deploy Azure Storage Account with Hierarchical namespace enabled.
    * Create a new Managed private endpoint in Azure Synapse Studio that points at the Storage Account.
    * The private endpoint establishes a private link between your Azure Synapse Analytics workspace and ADLS where traffic between your VNet and workspace traverses entirely over the Microsoft backbone network. All outbound traffic from the Managed workspace VNet will be blocked in the future. It's recommended that you connect to all your data sources using Managed private endpoints.
    * This architecture prevents data exfiltration, which WWI is concerned about.

6. WWI wants to enforce that any kind of modifications to sales data can happen in the current year only, while allowing all authorized users to query the entirety of data. Regarding the folder structure you previously recommended to WWI, how would accomplish this using RBAC and ACLs? Explain what actions would need to be taken at the start and end of the year 2020. Diagram your security groups, built-in roles and access permissions using the provided palette. 

    ANSWER:
    * WWI should create a security group in AAD, for example called `wwi-history-owners`, with the intent that all users who belong to this group will have permissions to modify data from previous years. 
    * The `wwi-history-owners` security group needs to be assigned to the Azure Storage built-in RBAC role `Storage Blob Data Owner` for the Azure Storage account containing the data lake. This allows AAD user and service principals that are added to this role to have the ability to modify all data.
    * They need to add the user security principals who will have have permissions to modify all historical data to the `wwi-history-owners` security group. 
    * WWI should create another security group in AAD, for example called `wwi-readers`, with the intent that all users who belong to this group will have permissions to read all contents of the file system (`prod` in this case), including all historical data.
    * The `wwi-readers` security group needs to be assigned to the Azure Storage built-in RBAC role `Storage Blob Data Reader` for the Azure Storage account containing the data lake. This allows AAD user and service principals that are added to this security group to have the ability to read all data in the file system, but not to modify it.
    * WWI should create another security group in AAD, for example called `wwi-2020-writers`, with the intent that all users who belong to this group will have permissions to modify data only from the year 2020.
    *  WWI would create a another security group, for example called `wwi-current-writers`, with the intent that only security groups would be added to this group. This group will have permissions to modify data only from the current year, set using ACLs.
    * They need to add the `wwi-readers` security group to the `wwi-current-writers` security group. 
    * At the start of the year 2020, WWI would add `wwi-current-writers` to the `wwi-2020-writers` security group.
    * At the start of the year 2020, on the `2020` folder, WWI would set the read, write and execute ACL permissions for the `wwi-2020-writers` security group.   
    *  At the start of the year 2021, to revoke write access to the 2020 data they would remove the `wwi-current-writers` security group from the `wwi-2020-writers`. Members of `wwi-readers` would continue to be able to read the contents of the file system because they have been granted read and execute (list) permissions not by the ACLs but by the RBAC built in role at the level of the file system. 
    *  This approach takes into account that currently changes to ACL's do not inherit, so removing the write permission would require writing code that that traverses all of its content removing the permission at each folder and file object.
    *  This approach is relatively fast. RBAC role assignments may take up to five minutes to propagate, regardless of the volume of data being secured.




     