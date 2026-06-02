-- FLORESTi Custo Real - Supabase storage
-- Execute this file in Supabase SQL Editor.
-- Change 'troque-este-token' to a strong shared token before running.

create extension if not exists pgcrypto;

create table if not exists public.custo_real_app_state (
  key text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.custo_real_app_config (
  key text primary key,
  value text not null
);

insert into public.custo_real_app_config (key, value)
values ('sync_token_sha256', encode(digest('troque-este-token', 'sha256'), 'hex'))
on conflict (key) do update set value = excluded.value;

insert into public.custo_real_app_state (key, data)
values (
  'default',
  '{
    "version": "2.1.0",
    "estoque_inicial": {
      "m3_bruto_pool": 0,
      "m3_2a_linha": 0,
      "m3_refilo": 0,
      "taxa_kg_m3_padrao": 0.25,
      "espessura_lamela_mm": 30.07,
      "r_m3_bruto": 0,
      "r_kg_adesivo": 0
    },
    "compras": [],
    "pedidos": [],
    "apontamentos_mensais": [],
    "leituras_tambor": []
  }'::jsonb
)
on conflict (key) do nothing;

alter table public.custo_real_app_state enable row level security;
alter table public.custo_real_app_config enable row level security;

revoke all on public.custo_real_app_state from anon, authenticated;
revoke all on public.custo_real_app_config from anon, authenticated;

create or replace function public.check_custo_real_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  expected text;
begin
  select value into expected
  from public.custo_real_app_config
  where key = 'sync_token_sha256';

  if expected is null or encode(digest(coalesce(p_token, ''), 'sha256'), 'hex') <> expected then
    raise exception 'Invalid sync token' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.get_custo_real_state(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  perform public.check_custo_real_token(p_token);

  select data into result
  from public.custo_real_app_state
  where key = 'default';

  return coalesce(result, '{}'::jsonb);
end;
$$;

create or replace function public.save_custo_real_state(p_token text, p_data jsonb)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  saved_at timestamptz := now();
begin
  perform public.check_custo_real_token(p_token);

  insert into public.custo_real_app_state (key, data, updated_at)
  values ('default', coalesce(p_data, '{}'::jsonb), saved_at)
  on conflict (key) do update
    set data = excluded.data,
        updated_at = excluded.updated_at;

  return saved_at;
end;
$$;

grant execute on function public.get_custo_real_state(text) to anon, authenticated;
grant execute on function public.save_custo_real_state(text, jsonb) to anon, authenticated;
