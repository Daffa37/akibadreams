-- =============================================
-- MINECRAFT ADDON SITE - SUPABASE SCHEMA
-- Run this in your Supabase SQL Editor
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- CATEGORIES TABLE
-- =============================================
CREATE TABLE categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  icon TEXT DEFAULT 'puzzle',
  color TEXT DEFAULT '#22c55e',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO categories (name, slug, description, icon, color) VALUES
  ('Mobs', 'mobs', 'New creatures and entity modifications', 'ghost', '#ef4444'),
  ('Weapons & Tools', 'weapons-tools', 'New weapons, swords, and tools', 'sword', '#f97316'),
  ('World Generation', 'world-gen', 'New biomes, structures, and terrain', 'mountain', '#22c55e'),
  ('Technology', 'technology', 'Machines, automation, and redstone', 'cpu', '#3b82f6'),
  ('Magic', 'magic', 'Spells, potions, and magical items', 'sparkles', '#8b5cf6'),
  ('Decoration', 'decoration', 'Furniture, blocks, and decorations', 'home', '#ec4899'),
  ('Adventure', 'adventure', 'Quests, dungeons, and challenges', 'map', '#f59e0b'),
  ('Utility', 'utility', 'QoL improvements and useful tools', 'settings', '#6b7280');

-- =============================================
-- ADDONS TABLE
-- =============================================
CREATE TABLE addons (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  short_description TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  version TEXT NOT NULL DEFAULT '1.0.0',
  mc_version TEXT NOT NULL DEFAULT '1.20+',
  author TEXT NOT NULL,
  author_email TEXT,
  thumbnail_url TEXT,
  images TEXT[] DEFAULT '{}',
  file_url TEXT,
  file_name TEXT,
  file_size BIGINT DEFAULT 0,
  downloads INTEGER DEFAULT 0,
  views INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  tags TEXT[] DEFAULT '{}',
  featured BOOLEAN DEFAULT FALSE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'published', 'rejected', 'draft')),
  changelog TEXT,
  requirements TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  published_at TIMESTAMP WITH TIME ZONE
);

-- =============================================
-- RATINGS TABLE
-- =============================================
CREATE TABLE ratings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  addon_id UUID REFERENCES addons(id) ON DELETE CASCADE,
  user_identifier TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(addon_id, user_identifier)
);

-- =============================================
-- DOWNLOAD LOGS TABLE
-- =============================================
CREATE TABLE download_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  addon_id UUID REFERENCES addons(id) ON DELETE CASCADE,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- ADMIN USERS TABLE
-- =============================================
CREATE TABLE admin_users (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'admin' CHECK (role IN ('superadmin', 'admin', 'moderator')),
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default admin (password: admin123 - CHANGE IN PRODUCTION)
-- Password is SHA-256 hashed: admin123
INSERT INTO admin_users (email, username, password_hash, role) VALUES
  ('yuuki@mcaddons.com', 'yuuki', '0582b6e3f744deab93bc508651aa734b578b161ba56f4466de46236eb497e5a2', 'superadmin');

-- =============================================
-- SITE SETTINGS TABLE
-- =============================================
CREATE TABLE site_settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO site_settings (key, value) VALUES
  ('site_name', 'MC Addons Hub'),
  ('site_description', 'The best Minecraft addon repository'),
  ('site_logo', ''),
  ('banner_title', 'Discover Amazing Minecraft Addons'),
  ('banner_subtitle', 'Browse thousands of mods, skins, and resource packs'),
  ('allow_submissions', 'true'),
  ('require_approval', 'true'),
  ('max_file_size_mb', '50'),
  ('allowed_extensions', 'mcpack,mcaddon,zip'),
  ('discord_url', ''),
  ('twitter_url', ''),
  ('github_url', '');

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Auto update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER addons_updated_at
  BEFORE UPDATE ON addons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update addon rating when new rating inserted
CREATE OR REPLACE FUNCTION update_addon_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE addons SET
    rating = (SELECT AVG(score) FROM ratings WHERE addon_id = NEW.addon_id),
    rating_count = (SELECT COUNT(*) FROM ratings WHERE addon_id = NEW.addon_id)
  WHERE id = NEW.addon_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ratings_update_addon
  AFTER INSERT OR UPDATE ON ratings
  FOR EACH ROW EXECUTE FUNCTION update_addon_rating();

-- Generate slug from title
CREATE OR REPLACE FUNCTION generate_slug(title TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN LOWER(REGEXP_REPLACE(REGEXP_REPLACE(title, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

ALTER TABLE addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE download_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;

-- Public can read published addons
CREATE POLICY "Public read published addons" ON addons
  FOR SELECT USING (status = 'published');

-- Public can read categories
CREATE POLICY "Public read categories" ON categories
  FOR SELECT USING (true);

-- Public can read site settings
CREATE POLICY "Public read site settings" ON site_settings
  FOR SELECT USING (true);

-- Public can insert ratings
CREATE POLICY "Public insert ratings" ON ratings
  FOR INSERT WITH CHECK (true);

-- Public can read ratings
CREATE POLICY "Public read ratings" ON ratings
  FOR SELECT USING (true);

-- Public can insert download logs
CREATE POLICY "Public insert download logs" ON download_logs
  FOR INSERT WITH CHECK (true);

-- Service role bypass (for admin operations via API)
-- Use service role key in admin panel

-- =============================================
-- STORAGE BUCKETS (run in Supabase Dashboard)
-- =============================================
-- Create two buckets manually in Supabase Dashboard > Storage:
-- 1. "addon-files" - private bucket for .mcpack/.mcaddon files
-- 2. "addon-images" - public bucket for thumbnails and screenshots
-- 
-- For addon-images bucket, set it to public and add policy:
-- Allow public read access
-- For addon-files bucket, add download_logs insert when file is accessed

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX idx_addons_status ON addons(status);
CREATE INDEX idx_addons_category ON addons(category_id);
CREATE INDEX idx_addons_featured ON addons(featured);
CREATE INDEX idx_addons_downloads ON addons(downloads DESC);
CREATE INDEX idx_addons_created ON addons(created_at DESC);
CREATE INDEX idx_addons_slug ON addons(slug);
CREATE INDEX idx_ratings_addon ON ratings(addon_id);
CREATE INDEX idx_download_logs_addon ON download_logs(addon_id);

-- =============================================
-- SAMPLE DATA (optional)
-- =============================================
-- Uncomment to add sample addons for testing

/*
INSERT INTO addons (title, slug, description, short_description, category_id, version, mc_version, author, status, featured, downloads, rating, rating_count, tags)
SELECT 
  'Epic Dragons Addon',
  'epic-dragons-addon',
  'Add majestic dragons to your Minecraft world! This addon introduces 5 different dragon types with unique abilities, attacks, and drops. Each dragon has its own territory and behavior patterns.',
  'Adds 5 unique dragon types with custom behaviors and epic loot!',
  c.id,
  '2.1.0',
  '1.20+',
  'DragonMaster99',
  'published',
  true,
  15420,
  4.8,
  234,
  ARRAY['dragons', 'mobs', 'fantasy', 'combat']
FROM categories c WHERE c.slug = 'mobs';
*/
