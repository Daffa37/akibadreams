// =============================================
// KONFIGURASI SUPABASE — Edit sesuai project Anda
// =============================================
// 1. Buka https://supabase.com → project → Settings → API
// 2. Copy Project URL dan anon/public key
// 3. Isi di bawah ini lalu simpan

window.SUPABASE_URL        = 'YOUR_SUPABASE_URL';
// contoh: 'https://sxxauaiauhxlyumrscmx.supabase.co'

window.SUPABASE_ANON_KEY   = 'YOUR_SUPABASE_ANON_KEY';
// contoh: 'sb_publishable_lIdcZiKumeKI8FFi1X31YA_1hi-37ti'

window.SUPABASE_SERVICE_KEY = 'YOUR_SUPABASE_SERVICE_ROLE_KEY';
// Service role key (hanya untuk admin, jaga kerahasiaan!)

// Nama storage buckets (buat manual di Supabase Dashboard → Storage)
window.ADDON_FILES_BUCKET  = 'addon-files';   // private bucket
window.ADDON_IMAGES_BUCKET = 'addon-images';  // public bucket

// =============================================
// REALTIME CONFIG
// Supabase Realtime aktif otomatis bila URL dikonfigurasi
// =============================================
