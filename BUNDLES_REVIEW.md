Combos & Bundles — backend active

The hood_combos_bundles migration was successfully applied through the normal Supabase migration flow. Read-only checks confirm the bundle table, save RPC, cart RPC and RLS are present; anonymous users cannot execute the admin save function. Do not rerun the migration.

Admin → Combos & Bundles: choose two or more published, priced, in-stock products, enter a name and fixed price, then publish. Customers choose each product colour and size and add an optional customisation note. Bundle selections appear in cart, checkout and admin order details. Component stock is checked and deducted atomically, with cancellation restocking. Updating a definition invalidates old cart choices. One set of choices per bundle is supported in each cart; remove the cart item before replacing its choices.

The bundle database tests cover admin authorization, selection validation, fixed-price COD and bank/advance checkout, saved notes and selections, component stock deduction, cancellation restocking, mixed-cart oversell rollback and stale-cart rejection. 64 tests and production build pass. No live test orders were created.
