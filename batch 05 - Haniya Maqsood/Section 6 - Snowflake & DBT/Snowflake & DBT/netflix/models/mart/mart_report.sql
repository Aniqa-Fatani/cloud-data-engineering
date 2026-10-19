-- models/mart/movie_report.sql
{{ config(materialized='view') }}

SELECT *
FROM {{ ref('dim_movies_with_tags') }}
WHERE relevance_score > 0.8