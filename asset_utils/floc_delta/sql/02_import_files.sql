

-- Preliminary: 
-- The variable `ztable_flocdes` is set in DuckDb (i.e. not an env var)

CREATE OR REPLACE TABLE floc_delta_config.ztable_flocdes AS
SELECT 
    t."Object Type" AS object_type,
    t."Standard FLoc Description" AS standard_floc_description,
FROM read_xlsx(
    getvariable('ztable_flocdes'),
    all_varchar=true, 
    sheet='Data'
) AS t;



-- Preliminary: 
-- The variable `floc_delta_worklist` is set in DuckDb (i.e. not an env var)


-- Set the variable `floc_delta_worklist` before running this file

CREATE OR REPLACE TABLE floc_delta_landing.worklist AS
SELECT 
    t."Requested Floc" AS requested_floc,
    t."Name" AS floc_name,
    t."Object Type" AS object_type,
    t."Level 5 Class Type" AS class_type,
    t."Asset Status" AS asset_status,
    t."Level 5 System Type Name" AS level5_system_type,
    t."AIB Reference" AS aib_reference,
    t."Solution ID" AS solution_id,
    t."Grid Ref" AS grid_ref
FROM read_xlsx(
    getvariable('floc_delta_worklist'),
    all_varchar=true, 
    sheet='Flocs'
) AS t;




