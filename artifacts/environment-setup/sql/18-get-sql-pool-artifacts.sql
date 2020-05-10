SELECT
    S.name + '.' + T.name as ObjectName
    ,'table' as ObjectType
FROM
    sys.tables T
    join sys.schemas S on
            T.schema_id = S.schema_id
UNION ALL
SELECT
    name as ObjectName
    ,'schema' as ObjectType
FROM
    sys.schemas
UNION ALL
SELECT
    name as ObjectName
    ,'externaldatasource' as ObjectType
FROM
    sys.external_data_sources
UNION ALL
SELECT
    name as ObjectName
    ,'externalfileformat' as ObjectType
FROM
    sys.external_file_formats
UNION ALL
SELECT
    name as ObjectName
    ,'workloadgroup' as ObjectType
FROM
    sys.workload_management_workload_groups
UNION ALL
SELECT
    name as ObjectName
    ,'workloadclassifier' as ObjectType
FROM
    sys.workload_management_workload_classifiers
UNION ALL
SELECT
    name as ObjectName
    ,'view' as ObjectType
FROM
    sys.views
UNION ALL
SELECT
    name as ObjectName
    ,'statistic' as ObjectType
FROM
    sys.stats
UNION ALL
SELECT
    name as ObjectName
    ,'index' as ObjectType
FROM
    sys.indexes
WHERE
    [name] is not NULL
UNION ALL
SELECT
    name as ObjectName
    ,'function' as ObjectType
FROM
    sys.sql_modules M 
    join sys.objects O ON
        M.object_id = O.object_id
WHERE
    O.type = 'IF'
UNION ALL
SELECT
    name as ObjectName
    ,'function' as ObjectType
FROM
    sys.security_policies