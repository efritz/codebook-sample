WITH RECURSIVE lineage(repository, "commit", parent_commit, has_lsif_data, distance, direction) AS (
    -- seed result set with the target repository and commit marked
    -- with both ancestor and descendant directions
    SELECT l.* FROM (
        SELECT c.*, 0, 'A' FROM commits_with_lsif_data_markers c UNION
        SELECT c.*, 0, 'D' FROM commits_with_lsif_data_markers c
    ) l
    WHERE l.repository = $1 AND l."commit" = $2

    UNION

    -- get the next commit in the ancestor or descendant direction
    SELECT c.*, l.distance + 1, l.direction FROM lineage l
    JOIN commits_with_lsif_data_markers c ON (
        (l.direction = 'A' AND c.repository = l.repository AND c."commit" = l.parent_commit) or
        (l.direction = 'D' AND c.repository = l.repository AND c.parent_commit = l."commit")
    )
    -- limit traversal distance
    WHERE l.distance < $3
)

-- lineage is ordered by distance to the target commit by
-- construction; get the nearest commit that has LSIF data
SELECT l."commit" FROM lineage l WHERE l.has_lsif_data LIMIT 1;