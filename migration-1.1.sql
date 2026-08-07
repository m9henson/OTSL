-- Ozark Travel Stein League Supabase 1.1 migration
-- Safe to run after the original schema.

-- Tournament policies: direct ownership checks.
drop policy if exists tournaments_select on public.tournaments;
drop policy if exists tournaments_insert on public.tournaments;
create policy tournaments_select on public.tournaments
for select to authenticated
using (
  admin_user_id = auth.uid()
  or is_active = true
  or exists (
    select 1 from public.group_sessions gs
    where gs.user_id = auth.uid() and gs.tournament_id = tournaments.id
  )
);
create policy tournaments_insert on public.tournaments
for insert to authenticated
with check (admin_user_id = auth.uid());

-- Player policies: admin can insert/update/delete; tournament readers can select.
drop policy if exists players_select on public.players;
drop policy if exists players_admin_all on public.players;
drop policy if exists players_insert on public.players;
drop policy if exists players_update on public.players;
drop policy if exists players_delete on public.players;
create policy players_select on public.players
for select to authenticated
using (
  exists (
    select 1 from public.tournaments t
    where t.id = players.tournament_id
      and (
        t.admin_user_id = auth.uid()
        or t.is_active = true
        or exists (
          select 1 from public.group_sessions gs
          where gs.user_id = auth.uid() and gs.tournament_id = t.id
        )
      )
  )
);
create policy players_insert on public.players
for insert to authenticated
with check (
  exists (select 1 from public.tournaments t where t.id = players.tournament_id and t.admin_user_id = auth.uid())
);
create policy players_update on public.players
for update to authenticated
using (
  exists (select 1 from public.tournaments t where t.id = players.tournament_id and t.admin_user_id = auth.uid())
)
with check (
  exists (select 1 from public.tournaments t where t.id = players.tournament_id and t.admin_user_id = auth.uid())
);
create policy players_delete on public.players
for delete to authenticated
using (
  exists (select 1 from public.tournaments t where t.id = players.tournament_id and t.admin_user_id = auth.uid())
);

-- Ensure expected tournament arrays exist on older partial schemas.
alter table public.tournaments add column if not exists pars int[] not null default array[4,4,3,5,4,4,3,5,4,4,4,3,5,4,4,3,5,4];
alter table public.tournaments add column if not exists stroke_indexes int[] not null default array[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18];
