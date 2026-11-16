# Instagram, bundle actions and logo repair
- Applied hood_instagram_column_repair to cloth-web and deployed dedicated hood-instagram-feed v1. Shared Instagram functions unchanged.
- Corrected HOOD column names, OAuth scope and callback parameter; removed inherited Bella account restriction. Admin actions remain authenticated and product links are scoped to HOOD.
- Account is not yet connected: feed settings disabled, username hood_pending, zero private connection rows. Set HOOD_META_APP_ID and HOOD_META_APP_SECRET on Supabase and configure the real account in admin; do not put secrets in frontend.
- Fresh database installs: run supabase/updates/hood_instagram_repair.sql after base setup.
- Bundle action buttons now wrap with clear spacing and mobile full width.
- Original logo traced to native SVG paths, without embedded bitmap or colour filters.
- Validation: 68 tests passed and Vite production build passed. Logo preview inspected; no browser session visual QA.
