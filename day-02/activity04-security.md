# Activity 04: Security

Wide World Importers is hosting in their data warehouse a plethora of data coming from many disparate sources. The idea of bringing all of their data together into Azure Synapse Analytics for them to query, gain insights, and consume in ways they have never done before is exhilarating! As much as it is an exciting game-changer for this business, it opens up a large surface area for potential attack. Security must be established at the forefront at the time of design of this solution.

With your help they have already secured the data in the data lake. In this activity, you will help design a solution for securing the data available within the SQL tables that make up their data warehouse. 

**Requirements**

* Want to make sure that the connection information to the data warehouse is always securely maintained, by the components that need it to access the data. 
* Want to ensure that Azure Synapse is secured in depth at the network level.
* Will need the flexibility to assign users to groups who should have access to the workspace, as well those that might have elevated permissions, such as those who can administer the entire Synapse Workspace, or manage just the Spark or SQL Pools or use Pipelines. 
* Want to maintain exclusive control over the keys to used to encrypt the data warehouse data at rest. They do not want Microsoft or any other entity to provide or have access to these keys.



## Whiteboard
Open your whiteboard for the event, and in the area for Activity 4 provide your answers to the following challenges.

*The following challenges are already present within the whiteboard template provided.*

Challenges
1. The Synapse Pipelines that WWI is creating will need to access both the data in the data lake and in the data warehouse. Diagram and document the steps they should, and the Azure services they should use, to secure pipelines and pipeline runs.

    ANSWER: 
    * Linked Services used by the Synapse Pipelines should use Azure Key Vault to store the sensitive connection information used to access any data source or destination.
    * 1. Provision and configure Key Vault: They would need to provision Azure Key Vault with the following configuration:
          * Add an access policy allowing Get and List secret permissions for the Managed Service Identity of the Synapse workspace (it is named the same as the Synapse workspace).
          * Under networking, set the connectivity method to Private endpoint and add new private endpoint that points to the Managed VNET deployed with the Azure Synapse Analytics workspace.
    * 2. Add the existing Key Vault as a linked service to Azure Synapse Analytics. 
    * 3. Add any required connection strings as secrets within the Key Vault.
    * 3. When creating new linked services, use Azure Key Vault and refer to the desired secret by name instead of specifying a connection string.
    * 4. To allow run pipelines that include datasets or activities referencing a SQL Pool, they will need to grant the Managed Service Identity of the workspace access to the SQL Pool (by granding it control on the SQL Pool database in T-SQL). 

2. Building upon the architecture you provided for the previous challenge, how would you address WWI's requirement to maintain exclusive control over the keys to used to encrypt the data warehouse data at rest?

    ANSWER: 
    * Enable Transparent Data Encryption (TDE) for the SQL Pool. 


3. WWI would like to understand how they will manage access control to the Synapse workspace with your proposed design. What four security groups should they create and what is the purpose of each group? How would you structure the group inheritance? Complete the following diagram and add your justifications.

    ANSWER: 
    * Create the following security groups in Azure Active Directory:
        | Group                             | Description                                                                        |
        |-----------------------------------|------------------------------------------------------------------------------------|
        | Synapse_Workspace_Users         | All workspace users.                                                               |
        | Synapse_Workspace_Admins        | Workspace administrators, for users that need complete control over the workspace. |
        | Synapse_Workspace_SQLAdmins     | For users that need complete control over the SQL aspects of the workspace.        |
        | Synapse_Workspace_SparkAdmins   | For users that need complete control over the Spark aspects of the workspace.      |
    * The group inheritence should be structured as follows:
        | Group                           | Members                                                                                |
        |---------------------------------|----------------------------------------------------------------------------------------|
        | Synapse_Workspace_Users       | Synapse_Workspace_Admins, Synapse_Workspace_SQLAdmins, Synapse_Workspace_SparkAdmins |
        | Synapse_Workspace_SparkAdmins | Synapse_Workspace_Admins                                                               |
        | Synapse_Workspace_SQLAdmins   | Synapse_Workspace_Admins                                                               |
    * The Synapse_Workspace_SQLAdmins security group needs to be set as the SQL Active Directory Admin within the Synapse workspace.
    * The AAD security groups should be added to the Synapse roles as follows:
        | Synapse Analytics Role | Azure Active Directory Group      |
        |------------------------|-----------------------------------|
        | Workspace admin        | Synapse_Workspace_Admins      |
        | Apache Spark admin     | Synapse_Workspace_SparkAdmins |
        | SQL admin              | Synapse_Workspace_SQLAdmins   |
    *  To add AAD user or group security principals to a specific Synapse Serverless or SQL Pool they would run a T-SQL Script that does the following in order:
       *  1. Create a login for that user or group.
       *  2. In the context of the SQL Serverless endpoint or SQL Pool, create a user from that login.
       *  3. Add that user to the desired role (e.g., db_owner, db_datareader, db_datawriter) within that database.

4. Diagram how you would recommend WWI secure the network boundary around Azure Synapse Analytics? If they wanted to ensure that access to Synapse Studio is only possible from a VM on the approved virtual network (or from a computer connected to that virtual network using VPN), how would they configure that? How would they monitor for suspicious traffic against the storage account and receive alerts to the same?

    ANSWER: 
    * Add IP firewall rules to disallow any remote access to the SQL Pools SQL serverless endpoints within the Synapse workspace. 
    * Leverage a Managed VNET with private endpoints to enable secure communication between applications, servers, data sources and Azure Synapse itself.
    * They should enable Advanced Threat Protection on the Storage Account.

5. Complete the following diagram to illustrate how they would secure access to data in the data warehouse. They have the following scenarios in mind:
   1. Hide specific columns from view: The CEO, who is an authorized personnel with access to all the information in the `Sale` table. However, a Data Analyst, only should never be able to see the Revenue column. 
   2. Hide certain rows from view: The CEO has access to all the information in the `Sale` table, but a data analyst is restricted to only seeing the rows for the region she supports.
   3. Hide details of specific fields from view: All users should default to seeing only partial credit card numbers and emails in the `CustomerInfo` table.

    ANSWER: 
    * Hide specific columns from view -> use Column Level Security
    * Hide certain rows from view -> use Row Level Security
    * Hide details of specific fields from view -> use Dynamic Data Masking