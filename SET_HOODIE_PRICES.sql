-- Run once after RUN_BACKEND_SETUP.sql. Only THE HOOD.PK products are affected.
UPDATE public.products SET price_cents=100000,sale_price_cents=NULL,enquiry_only=false WHERE storefront='hood' AND status='published';
