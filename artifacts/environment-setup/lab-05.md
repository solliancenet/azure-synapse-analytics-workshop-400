# Lab 5 Environment Setup

## Active Directory

### Azure Security User, Groups and Membership

- USER: will need a new AAD User created (walking through adding aad user to sql)

| Group                           | Members                                                                                |
|---------------------------------|----------------------------------------------------------------------------------------|
| Synapse_`Workspace`_Users       | Synapse_`Workspace`_Admins, Synapse_`Workspace`_SQLAdmins, Synapse_`Workspace`_SparkAdmins |
| Synapse_`Workspace`_SparkAdmins | Synapse_`Workspace`_Admins                                                               |
| Synapse_`Workspace`_SQLAdmins   | Synapse_`Workspace`_Admins                                                               |
| wwi-2020-writers           | wwi-current-writers                                                               |
| wwi-current-writers        | wwi-readers                                                                            |
| wwi-history-owners         | |
| wwi-readers                | |

### RBAC Permissions

- The Synapse_`Workspace`_Users group needs **Storage Blob Data Contributor** on the `DefaultFileSystem` container.

- The Synapse `Workspace` MSI needs **Storage Blob Data Contributor** on the `DefaultFileSystem` container.

- The **wwi-readers** will need **Storage Blob Data Reader** on the **wwi** file system (located in `PrimaryStorage`).

- The **wwi-history-owners** need **Storage Blob Data Contributor** on the **wwi** file system (located in `PrimaryStorage`).

## Azure Resources

- `PrimaryStorage` account with the **wwi** -> **factsale-csv** and child folders

## Azure Synapse Workspace

- The Synapse_`Workspace`_SQLAdmins security group needs to be set as the SQL Active Directory Admin within the Synapse workspace.

### SQL Scripts (located in artifacts/day-02 folder)

- ASAL400 - Lab 05 - Exercise 3 - Column Level Security.sql

- ASAL400 - Lab 05 - Exercise 3 - Dynamic Data Masking.sql

- ASAL400 - Lab 05 - Exercise 3 - Row Level Security.sql

### SQL Pool Users

- DataAnalystMiami

- DataAnalystSanDiego

- CEO

### SQL Pool Schema [wwi_security]

Tables Used:

- wwi_security.Sale
  
- wwi_security.CustomerInfo
