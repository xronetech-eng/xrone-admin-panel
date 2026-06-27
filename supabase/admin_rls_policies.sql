-- Admin panel RLS policies.
-- Apply from Supabase SQL editor or migrations using an owner/service context.
-- Do not run from the Flutter client.

alter table public.admin_users enable row level security;
alter table public.request_bookings enable row level security;
alter table public."user" enable row level security;
alter table public.location_details enable row level security;
alter table public.transaction_details_user enable row level security;
alter table public.user_offers enable row level security;
alter table public.offers enable row level security;
alter table public.pilot_location_tracker enable row level security;

drop policy if exists "admin_users_select_own_admin_row" on public.admin_users;
create policy "admin_users_select_own_admin_row"
on public.admin_users
for select
to authenticated
using (
  user_id = auth.uid()
  and role = 'admin'
);

drop policy if exists "admins_select_request_bookings" on public.request_bookings;
create policy "admins_select_request_bookings"
on public.request_bookings
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);

drop policy if exists "admins_select_user" on public."user";
create policy "admins_select_user"
on public."user"
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);

drop policy if exists "admins_select_location_details" on public.location_details;
create policy "admins_select_location_details"
on public.location_details
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);

drop policy if exists "admins_select_transaction_details_user" on public.transaction_details_user;
create policy "admins_select_transaction_details_user"
on public.transaction_details_user
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);

drop policy if exists "admins_select_offers" on public.offers;
drop policy if exists "admins_select_user_offers" on public.user_offers;
create policy "admins_select_user_offers"
on public.user_offers
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);

create policy "admins_select_offers"
on public.offers
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);

drop policy if exists "admins_select_pilot_location_tracker" on public.pilot_location_tracker;
create policy "admins_select_pilot_location_tracker"
on public.pilot_location_tracker
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users admin
    where admin.user_id = auth.uid()
      and admin.role = 'admin'
  )
);
