# Lab 8 Environment Setup

A SQL Pool named `SQLPool01` with a database name `SQLPool01`

## Tables
`wwi.SaleSmall` with an integer `CustomerId` column

## SQL Pool Logins
* asa.sql.workload01
* asa.sql.workload02

## Key Vault Secrets
* SQL-USER-ASA-SQL-WORKLOAD (stores the password for `asa.sql.workload01` and `asa.sql.workload02`, used by the below linked services)

## Linked Services
* sqlpool01_workload01
* sqlpool01_workload02

## Datasets
* asal400_wwi_salesmall_workload1_asa
* asal400_wwi_salesmall_workload2_asa

## Pipelines
* ASAL400 - Lab 8 - ExecuteDataAnalystAndCEOQueries
* ASAL400 - Lab 8 - ExecuteBusinessAnalystQueries

## SQL Scripts
* ASAL400 - Lab 08 - Exercise 1 - WorkLoad Importance
* ASAL400 - Lab 08 - Exercise 2 - Workload Isolatation
* ASAL400 - Lab 08 - Exercise 3 - Monitor Workload
