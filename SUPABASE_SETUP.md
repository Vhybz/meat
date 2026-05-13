# Supabase Setup Guide

This project is prepared to use Supabase. Follow these steps to set up your database.

## 1. Clean Database Setup (SQL)

Run the following SQL in your Supabase SQL Editor. This will reset your database and create all required tables with the correct permissions.

**WARNING: This will delete all existing data in the public schema.**

```sql
-- =====================================================
-- DROP EVERYTHING / CLEAN DATABASE RESET
-- =====================================================

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- Restore schema permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- Enable UUID support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- BRANCHES
-- =====================================================

CREATE TABLE branches (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  admin_id UUID,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- USERS
-- =====================================================

CREATE TABLE users (
  id UUID PRIMARY KEY,

  first_name TEXT NOT NULL,
  surname TEXT NOT NULL,

  email TEXT UNIQUE NOT NULL,
  phone TEXT,

  gender TEXT,
  dob DATE,

  role TEXT NOT NULL,

  branch_code TEXT REFERENCES branches(code),

  secondary_roles TEXT[] DEFAULT '{}',

  shop_location TEXT,

  status TEXT NOT NULL DEFAULT 'approved',

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  is_deleted BOOLEAN DEFAULT false,

  temporary_role TEXT,
  temp_role_start TIMESTAMPTZ,
  temp_role_end TIMESTAMPTZ,

  enabled_permissions TEXT[]
    DEFAULT '{"/settings"}',

  newly_added_permissions TEXT[]
    DEFAULT '{}'
);

-- =====================================================
-- PRODUCTS
-- =====================================================

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  name TEXT NOT NULL,

  retail_price DECIMAL(10,2) NOT NULL,
  wholesale_price DECIMAL(10,2) NOT NULL,

  image_url TEXT,

  category TEXT NOT NULL,

  stock_quantity DECIMAL(10,2) DEFAULT 0,

  unit TEXT DEFAULT 'kg',

  discount_percentage DECIMAL(10,2) DEFAULT 0,

  promo_start TIMESTAMPTZ,
  promo_end TIMESTAMPTZ,

  promo_target TEXT DEFAULT 'both',

  promo_customer_target TEXT DEFAULT 'all',

  is_deleted BOOLEAN DEFAULT false
);

-- =====================================================
-- SALES
-- =====================================================

CREATE TABLE sales (
  id TEXT PRIMARY KEY,

  branch_code TEXT REFERENCES branches(code),

  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL,

  cashier_id UUID REFERENCES users(id),

  cashier_name TEXT NOT NULL,

  total_amount DECIMAL(10,2) NOT NULL,

  total_discount DECIMAL(10,2) DEFAULT 0,

  applied_promo TEXT,

  customer_name TEXT,
  customer_phone TEXT,

  status TEXT DEFAULT 'completed',

  correction_reason TEXT,

  items JSONB NOT NULL,

  payments JSONB NOT NULL
);

-- =====================================================
-- STOCK TRANSFERS
-- =====================================================

CREATE TABLE stock_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  batch_id TEXT NOT NULL,

  meat_type TEXT NOT NULL,

  weight DECIMAL(10,2) NOT NULL,

  destination TEXT NOT NULL,

  transfer_time TIMESTAMPTZ DEFAULT now() NOT NULL,

  status TEXT DEFAULT 'pending'
);

-- =====================================================
-- EXPENSES
-- =====================================================

CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  category TEXT NOT NULL,

  amount DECIMAL(10,2) NOT NULL,

  description TEXT,

  date DATE DEFAULT CURRENT_DATE,

  recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- CUSTOMERS
-- =====================================================

CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  name TEXT NOT NULL,

  phone TEXT UNIQUE NOT NULL,

  location TEXT,

  is_favorite BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- ANIMALS
-- =====================================================

CREATE TABLE animals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  tag_number TEXT,

  type TEXT NOT NULL,

  weight DECIMAL(10,2) NOT NULL,

  source_farm TEXT,

  status TEXT DEFAULT 'waiting',

  arrival_time TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- SLAUGHTER LOGS
-- =====================================================

CREATE TABLE slaughter_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  animal_id UUID REFERENCES animals(id),

  type TEXT NOT NULL,

  initial_weight DECIMAL(10,2) NOT NULL,

  slaughter_time TIMESTAMPTZ DEFAULT now() NOT NULL,

  carcass_weight DECIMAL(10,2),

  status TEXT DEFAULT 'completed'
);

-- =====================================================
-- MEAT BATCHES
-- =====================================================

CREATE TABLE meat_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  meat_type TEXT NOT NULL,

  initial_weight DECIMAL(10,2) NOT NULL,

  current_weight DECIMAL(10,2) NOT NULL,

  status TEXT DEFAULT 'processing',

  source_name TEXT,
  source_location TEXT,

  owner_name TEXT,

  inspected_by TEXT,

  received_by TEXT,

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- MEAT CUTS
-- =====================================================

CREATE TABLE meat_cuts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  batch_id UUID REFERENCES meat_batches(id),

  name TEXT NOT NULL,

  weight DECIMAL(10,2) NOT NULL,

  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- BUTCHER WASTE
-- =====================================================

CREATE TABLE butcher_waste (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  branch_code TEXT REFERENCES branches(code),

  batch_id UUID REFERENCES meat_batches(id),

  reason TEXT NOT NULL,

  weight DECIMAL(10,2) NOT NULL,

  recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- DISABLE ROW LEVEL SECURITY (RLS)
-- =====================================================
-- Disabling RLS allows the app to perform CRUD operations 
-- without complex policies during the initial setup phase.

ALTER TABLE public.branches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transfers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.animals DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.slaughter_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.meat_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.meat_cuts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.butcher_waste DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- GRANTS / PERMISSIONS
-- =====================================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
```

## 2. Environment Variables

Update the `.env` file in the root directory with your Supabase Project credentials:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 3. Storage

1. Create a bucket named `product-images` in Supabase Storage.
2. Set the bucket to **Public**.
3. Create a folder named `products` inside the bucket (optional, the app handles paths).
