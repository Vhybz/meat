# Supabase Setup Guide

This project is prepared to use Supabase. Follow these steps to set up your database for **Mi~Corazon Freshmeat Butchery**.

## 1. Clean Database Setup (SQL)

Run the following SQL in your Supabase SQL Editor. This script handles the schema reset, table creations, storage policies, and permissions in one go.

**WARNING: This will delete all existing data in the public schema.**

```sql
-- =====================================================
-- 1. DROP EVERYTHING / CLEAN DATABASE RESET
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
-- 2. TABLES (Schema Definition)
-- =====================================================

-- BRANCHES (Business Units)
CREATE TABLE branches (
  code TEXT PRIMARY KEY, -- This is the 'Shop Registration Code' shared with staff
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  admin_id UUID,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- USERS (Staff & Admin Profiles)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  surname TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  gender TEXT,
  dob DATE,
  photo_url TEXT,
  role TEXT NOT NULL,
  branch_code TEXT REFERENCES branches(code),
  secondary_roles TEXT[] DEFAULT '{}',
  shop_location TEXT,
  status TEXT NOT NULL DEFAULT 'approved',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  last_seen TIMESTAMPTZ, -- Track activity
  is_deleted BOOLEAN DEFAULT false,
  temporary_role TEXT,
  temp_role_start TIMESTAMPTZ,
  temp_role_end TIMESTAMPTZ,
  enabled_permissions TEXT[] DEFAULT '{"/settings"}',
  newly_added_permissions TEXT[] DEFAULT '{}',
  salary_amount DECIMAL(10,2), -- Financial analytics
  salary_day INT,
  last_salary_date DATE,
  theme_mode TEXT DEFAULT 'system',
  theme_primary_color BIGINT
);

-- PRODUCTS (Inventory Items)
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  name TEXT NOT NULL,
  retail_price DECIMAL(10,2) NOT NULL,
  wholesale_price DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2) DEFAULT 0, -- Added for profit analytics
  retail_brackets JSONB DEFAULT '[]',
  wholesale_brackets JSONB DEFAULT '[]',
  image_url TEXT,
  category TEXT NOT NULL,
  stock_quantity DECIMAL(10,2) DEFAULT 0,
  unit TEXT DEFAULT 'kg',
  discount_percentage DECIMAL(10,2) DEFAULT 0,
  promo_start TIMESTAMPTZ,
  promo_end TIMESTAMPTZ,
  promo_target TEXT DEFAULT 'both',
  promo_customer_target TEXT DEFAULT 'all',
  is_deleted BOOLEAN DEFAULT false,
  low_stock_threshold DECIMAL(10,2) DEFAULT 5.0,
  daily_stock_added DECIMAL(10,2) DEFAULT 0,
  last_stock_update TIMESTAMPTZ
);

-- SALES (Transactions)
CREATE TABLE sales (
  id TEXT PRIMARY KEY,
  branch_code TEXT REFERENCES branches(code),
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL,
  cashier_id UUID REFERENCES users(id),
  cashier_name TEXT NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  total_discount DECIMAL(10,2) DEFAULT 0,
  total_cost DECIMAL(10,2) DEFAULT 0, -- Added for profit analytics
  applied_promo TEXT,
  customer_name TEXT,
  customer_phone TEXT,
  status TEXT DEFAULT 'completed',
  correction_reason TEXT,
  bank_receipt_url TEXT, -- Link to bank deposit photo
  bank_receipt_id TEXT, -- Manual reference ID from bank slip
  items JSONB NOT NULL,
  payments JSONB NOT NULL,
  is_verified BOOLEAN DEFAULT false -- Trigger for inventory subtraction
);

-- STOCK TRANSFERS
CREATE TABLE stock_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  batch_id TEXT NOT NULL,
  meat_type TEXT NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  destination TEXT NOT NULL,
  transfer_time TIMESTAMPTZ DEFAULT now() NOT NULL,
  status TEXT DEFAULT 'pending',
  is_individual BOOLEAN DEFAULT false,
  customer_name TEXT,
  customer_phone TEXT,
  customer_location TEXT
);

-- EXPENSES
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  category TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  notes TEXT,
  receipt_url TEXT, -- Link to expense receipt photo
  date DATE DEFAULT CURRENT_DATE,
  recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- CUSTOMERS
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  location TEXT,
  is_favorite BOOLEAN DEFAULT false,
  loyalty_points DECIMAL(10,2) DEFAULT 0.0,
  visit_count INT DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false, -- For soft deletes
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ANIMALS (Traceability)
CREATE TABLE animals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  tag_number TEXT,
  type TEXT NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  purchase_price DECIMAL(10,2) DEFAULT 0, -- Cost tracking
  source_farm TEXT,
  status TEXT DEFAULT 'waiting',
  arrival_time TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- SLAUGHTER LOGS
CREATE TABLE slaughter_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  animal_id UUID REFERENCES animals(id),
  tag_number TEXT, -- Human readable tag
  manual_farm_tag TEXT, -- Manual tag from farm
  type TEXT NOT NULL,
  initial_weight DECIMAL(10,2) NOT NULL,
  price DECIMAL(10,2) DEFAULT 0, -- Selling/Market Value
  farm_price DECIMAL(10,2) DEFAULT 0, -- Purchase/Cost Price
  slaughter_time TIMESTAMPTZ, -- Set when task is completed
  carcass_weight DECIMAL(10,2),
  status TEXT DEFAULT 'pending' -- pending, slaughtering, cleaned, completed, processed
);

-- MEAT BATCHES
CREATE TABLE meat_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  animal_id UUID REFERENCES animals(id), -- Linked to source animal
  meat_type TEXT NOT NULL,
  initial_weight DECIMAL(10,2) NOT NULL,
  current_weight DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2) DEFAULT 0, -- Cost of the batch
  status TEXT DEFAULT 'transporting', -- transporting, received, preparing, mincing, cutting, packaging, frozen, completed
  source_name TEXT,
  source_location TEXT,
  owner_name TEXT,
  inspected_by TEXT,
  received_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- MEAT CUTS
CREATE TABLE meat_cuts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  batch_id UUID REFERENCES meat_batches(id),
  name TEXT NOT NULL,
  meat_type TEXT, -- Denormalized for analytics
  weight DECIMAL(10,2) NOT NULL,
  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- BUTCHER WASTE
CREATE TABLE butcher_waste (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  batch_id UUID REFERENCES meat_batches(id),
  product_id UUID REFERENCES products(id), -- If waste is a specific product
  reason TEXT NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- BUTCHER ORDERS
CREATE TABLE butcher_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  customer_id UUID REFERENCES customers(id), -- Link to customer profile
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  items JSONB NOT NULL,
  total_weight DECIMAL(10,2) NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- AUDIT LOGS (Security & Accountability)
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  user_id UUID REFERENCES users(id),
  user_name TEXT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL, -- 'PRODUCT', 'SALE', 'USER', etc.
  entity_id TEXT,
  old_data JSONB,
  new_data JSONB,
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- NOTIFICATIONS (System Alerts)
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  user_id UUID REFERENCES users(id), -- Null if for everyone in branch
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info', -- 'info', 'warning', 'error', 'success'
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- CUSTOMER PAYMENTS (For Debt Tracking)
CREATE TABLE customer_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  customer_id UUID REFERENCES customers(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL,
  reference TEXT,
  sale_id TEXT REFERENCES sales(id),
  collected_by UUID REFERENCES users(id),
  payment_date TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- PRODUCT STOCK HISTORY (For Inventory Analytics)
CREATE TABLE stock_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES branches(code),
  product_id UUID REFERENCES products(id),
  change_amount DECIMAL(10,2) NOT NULL,
  new_quantity DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL, -- 'SALE', 'RESTOCK', 'ADJUSTMENT', 'TRANSFER', 'WASTE'
  reference_id TEXT, -- Sale ID or Batch ID
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- 3. SECURITY & PERMISSIONS (CRITICAL)
-- =====================================================

-- Disable RLS to allow rapid development
ALTER TABLE branches DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfers DISABLE ROW LEVEL SECURITY;
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE animals DISABLE ROW LEVEL SECURITY;
ALTER TABLE slaughter_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE meat_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE meat_cuts DISABLE ROW LEVEL SECURITY;
ALTER TABLE butcher_waste DISABLE ROW LEVEL SECURITY;
ALTER TABLE butcher_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer_payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_history DISABLE ROW LEVEL SECURITY;

-- Grant Full Permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- =====================================================
-- 4. STORAGE BUCKET POLICIES
-- =====================================================

-- Clean up existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public Read Access" ON storage.objects;
DROP POLICY IF EXISTS "Allow Image Upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow Image Update" ON storage.objects;
DROP POLICY IF EXISTS "Allow Image Delete" ON storage.objects;

DROP POLICY IF EXISTS "Allow users to upload own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Public View Access" ON storage.objects;

DROP POLICY IF EXISTS "Receipts Read Access" ON storage.objects;
DROP POLICY IF EXISTS "Receipts Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Receipts Delete Access" ON storage.objects;

-- Policies for 'product-images'
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT TO public USING ( bucket_id = 'product-images' );
CREATE POLICY "Allow Image Upload" ON storage.objects FOR INSERT TO public WITH CHECK ( bucket_id = 'product-images' );
CREATE POLICY "Allow Image Update" ON storage.objects FOR UPDATE TO public USING ( bucket_id = 'product-images' );
CREATE POLICY "Allow Image Delete" ON storage.objects FOR DELETE TO public USING ( bucket_id = 'product-images' );

-- Policies for 'user-profiles'
CREATE POLICY "Allow users to upload own profile pictures" ON storage.objects FOR INSERT TO public WITH CHECK ( bucket_id = 'user-profiles' );
CREATE POLICY "Allow users to update own profile pictures" ON storage.objects FOR UPDATE TO public USING ( bucket_id = 'user-profiles' );
CREATE POLICY "Allow users to delete own profile pictures" ON storage.objects FOR DELETE TO public USING ( bucket_id = 'user-profiles' );
CREATE POLICY "Public View Access" ON storage.objects FOR SELECT TO public USING ( bucket_id = 'user-profiles' );

-- Policies for 'receipts'
CREATE POLICY "Receipts Read Access" ON storage.objects FOR SELECT TO public USING ( bucket_id = 'receipts' );
CREATE POLICY "Receipts Upload Access" ON storage.objects FOR INSERT TO public WITH CHECK ( bucket_id = 'receipts' );
CREATE POLICY "Receipts Delete Access" ON storage.objects FOR DELETE TO public USING ( bucket_id = 'receipts' );
```

## 2. Environment Variables

Update the `.env` file in the root directory with your Supabase Project credentials:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 3. Storage Buckets

Create the following buckets in Supabase Storage and set them to **Public**:

1.  **`product-images`**: For inventory product photos.
2.  **`user-profiles`**: For staff profile pictures.
3.  **`receipts`**: For business expense receipt and bank deposit uploads.

*Note: Ensure "Public" access is enabled for each bucket to allow the app to generate and display URLs correctly.*
