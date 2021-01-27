WITH RECURSIVE lineage(repository, "commit", parent_commit, has_lsif_data, direction) AS (
    -- seed result set with the target repository and commit marked
    -- with both ancestor and descendant directions
    SELECT l.* FROM (
        SELECT c.*, 'A' FROM commits_with_lsif_data_markers c WHERE l.repository = $1 AND l."commit" = $2 UNION
        SELECT c.*, 'D' FROM commits_with_lsif_data_markers c WHERE l.repository = $1 AND l."commit" = $2
    ) l
    
    UNION

    -- get the next commit in the ancestor or descendant direction
    SELECT * FROM (
        WITH l_inner AS (SELECT * FROM lineage)

        SELECT c.*, l.direction FROM lineage l
        JOIN commits_with_lsif_data_markers c ON (
            l.direction = 'A' AND c.repository = l.repository AND c."commit" = l.parent_commit
        )

        UNION

        SELECT c.*, l.direction FROM lineage l
        JOIN commits_with_lsif_data_markers c ON (
            l.direction = 'D' AND c.repository = l.repository AND c.parent_commit = l."commit"
        )
    )
)

-- lineage is ordered by distance to the target commit by
-- construction; get the nearest commit that has LSIF data
SELECT l."commit" FROM (SELECT * FROM lineage LIMIT $3) l WHERE l.has_lsif_data LIMIT 1;