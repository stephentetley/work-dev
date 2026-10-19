
-- Alternative to FTS using vector similarity search...
-- Uses the vss extension and the ai community extension along
-- with Ollama serving the embeddinggemma model.
-- runs with DuckDB v1.5.4 


load ai;
load vss;

set duckdb_ai_provider = 'ollama';
set duckdb_ai_model = 'embeddinggemma';

set hnsw_enable_experimental_persistence = true;

create or replace table s4_equi_with_vector as
select 
    equi_id,
    equi_name,
    ai_embed(equi_name)::float[768] as name_embbedding,
from 
    read_parquet(getvariable('equi_file'));

-- drop index hnsw_equi_name_index;
create index hnsw_equi_name_index on s4_equi_with_vector using HNSW (name_embbedding) with (metric = 'l2sq');


select
    equi_id, 
    equi_name,
    array_distance(name_embbedding, ai_embed('dist board')::float[768]) as distance_metric,
from s4_equi_with_vector
order by distance_metric
limit 15;

create or replace macro search(str varchar) as table (
select
    equi_id, 
    equi_name,
    array_distance(name_embbedding, ai_embed(str)::float[768]) as distance_metric,
from s4_equi_with_vector
order by distance_metric
limit 15);