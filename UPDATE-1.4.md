# Supabase 1.4

- Admin can edit a player's course handicap and group, then tap Save Changes.
- When a player changes groups, existing score rows are moved to the new group too.
- Admin can delete a player with confirmation. Because scores reference players with ON DELETE CASCADE, that player's scores are deleted automatically.
- No SQL migration is needed if migration-1.1.sql was already run.
- Keep the working supabase-config.js already in GitHub.
