-- Run this entire file once in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.tournaments (
 id uuid primary key default gen_random_uuid(),
 admin_user_id uuid not null references auth.users(id) on delete cascade,
 name text not null,
 course text default '', date date, holes int not null check (holes in (9,18)),
 pars int[] not null, stroke_indexes int[] not null,
 handicap_skin_holes int[] not null default '{}', blind_skin_holes int[] not null default '{}',
 is_active boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.players (
 id uuid primary key default gen_random_uuid(), tournament_id uuid not null references public.tournaments(id) on delete cascade,
 name text not null, course_handicap int not null default 0, group_number int not null check(group_number between 1 and 6), created_at timestamptz not null default now()
);
create table if not exists public.scores (
 tournament_id uuid not null references public.tournaments(id) on delete cascade,
 player_id uuid not null references public.players(id) on delete cascade,
 group_number int not null check(group_number between 1 and 6), hole int not null check(hole between 1 and 18), gross int not null check(gross between 1 and 12),
 updated_by uuid not null references auth.users(id), updated_at timestamptz not null default now(), primary key(player_id,hole)
);
create table if not exists public.group_links (
 tournament_id uuid not null references public.tournaments(id) on delete cascade,
 group_number int not null check(group_number between 1 and 6), token text not null, updated_at timestamptz not null default now(), primary key(tournament_id,group_number)
);
create table if not exists public.group_sessions (
 user_id uuid not null references auth.users(id) on delete cascade,
 tournament_id uuid not null references public.tournaments(id) on delete cascade,
 group_number int not null check(group_number between 1 and 6), claimed_at timestamptz not null default now(), primary key(user_id,tournament_id)
);

alter table public.tournaments enable row level security;
alter table public.players enable row level security;
alter table public.scores enable row level security;
alter table public.group_links enable row level security;
alter table public.group_sessions enable row level security;

create or replace function public.is_tournament_admin(tid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.tournaments t where t.id=tid and t.admin_user_id=auth.uid()); $$;
create or replace function public.has_group_session(tid uuid, grp int) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.group_sessions s where s.user_id=auth.uid() and s.tournament_id=tid and s.group_number=grp); $$;
create or replace function public.can_read_tournament(tid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.tournaments t where t.id=tid and (t.is_active or t.admin_user_id=auth.uid() or exists(select 1 from public.group_sessions s where s.user_id=auth.uid() and s.tournament_id=t.id))); $$;
create or replace function public.claim_group_link(p_tournament uuid,p_group int,p_token text) returns boolean
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.group_links where tournament_id=p_tournament and group_number=p_group and token=p_token) then raise exception 'Invalid or expired group link'; end if;
 insert into public.group_sessions(user_id,tournament_id,group_number) values(auth.uid(),p_tournament,p_group)
 on conflict(user_id,tournament_id) do update set group_number=excluded.group_number,claimed_at=now();
 return true;
end $$;
grant execute on function public.claim_group_link(uuid,int,text) to authenticated;

create policy tournaments_select on public.tournaments for select to authenticated using(public.can_read_tournament(id));
create policy tournaments_insert on public.tournaments for insert to authenticated with check(admin_user_id=auth.uid() and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false));
create policy tournaments_update on public.tournaments for update to authenticated using(admin_user_id=auth.uid()) with check(admin_user_id=auth.uid());
create policy tournaments_delete on public.tournaments for delete to authenticated using(admin_user_id=auth.uid());

create policy players_select on public.players for select to authenticated using(public.can_read_tournament(tournament_id));
create policy players_admin_all on public.players for all to authenticated using(public.is_tournament_admin(tournament_id)) with check(public.is_tournament_admin(tournament_id));

create policy scores_select on public.scores for select to authenticated using(public.can_read_tournament(tournament_id));
create policy scores_insert on public.scores for insert to authenticated with check(
 public.is_tournament_admin(tournament_id) or
 (public.has_group_session(tournament_id,group_number) and exists(select 1 from public.players p where p.id=player_id and p.tournament_id=scores.tournament_id and p.group_number=scores.group_number))
);
create policy scores_update on public.scores for update to authenticated using(
 public.is_tournament_admin(tournament_id) or public.has_group_session(tournament_id,group_number)
) with check(
 public.is_tournament_admin(tournament_id) or
 (public.has_group_session(tournament_id,group_number) and exists(select 1 from public.players p where p.id=player_id and p.tournament_id=scores.tournament_id and p.group_number=scores.group_number))
);
create policy scores_delete on public.scores for delete to authenticated using(public.is_tournament_admin(tournament_id));

create policy links_admin_all on public.group_links for all to authenticated using(public.is_tournament_admin(tournament_id)) with check(public.is_tournament_admin(tournament_id));
create policy sessions_own_select on public.group_sessions for select to authenticated using(user_id=auth.uid());

-- Add scores and players to Realtime once. Ignore duplicate-member errors if rerun.
do $$ begin
 alter publication supabase_realtime add table public.scores;
exception when duplicate_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.players;
exception when duplicate_object then null; end $$;
