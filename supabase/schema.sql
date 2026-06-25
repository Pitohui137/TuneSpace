-- ============================================================
-- TuneSpace — Supabase Database Schema
-- Jalankan seluruh script ini di Supabase SQL Editor
-- Dashboard → SQL → New query → Paste → Run
-- ============================================================

-- 1. Tabel profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nama        TEXT NOT NULL,
  email       TEXT NOT NULL,
  no_telp     TEXT,
  role        TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tabel studios
CREATE TABLE IF NOT EXISTS public.studios (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama_studio   TEXT NOT NULL,
  deskripsi     TEXT,
  fasilitas     TEXT,
  harga_per_jam NUMERIC(12, 2) NOT NULL CHECK (harga_per_jam >= 0),
  foto_url      TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.studio_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id   UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
  photo_url   TEXT NOT NULL,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Tabel bookings
CREATE TABLE IF NOT EXISTS public.bookings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  studio_id       UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
  tanggal_booking DATE NOT NULL,
  jam_mulai       TIME NOT NULL,
  durasi_jam      INTEGER NOT NULL CHECK (durasi_jam > 0),
  total_harga     NUMERIC(12, 2) NOT NULL CHECK (total_harga >= 0),
  payment_proof_url TEXT,
  payment_file_name TEXT,
  payment_uploaded_at TIMESTAMPTZ,
  status          TEXT NOT NULL DEFAULT 'menunggu'
                  CHECK (status IN ('menunggu', 'disetujui', 'ditolak', 'selesai')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS payment_proof_url TEXT,
  ADD COLUMN IF NOT EXISTS payment_file_name TEXT,
  ADD COLUMN IF NOT EXISTS payment_uploaded_at TIMESTAMPTZ;

-- 4. Trigger: buat profil otomatis saat user mendaftar
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, nama, email, no_telp, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nama', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.raw_user_meta_data->>'no_telp',
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Helper: cek apakah user saat ini adalah admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 6. Row Level Security
ALTER TABLE public.profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.studios   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.studio_photos ENABLE ROW LEVEL SECURITY;

-- ---- profiles policies ----
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
  FOR SELECT USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "profiles_update_admin" ON public.profiles;
CREATE POLICY "profiles_update_admin" ON public.profiles
  FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "profiles_delete_admin" ON public.profiles;
CREATE POLICY "profiles_delete_admin" ON public.profiles
  FOR DELETE USING (public.is_admin());

-- ---- studios policies ----
DROP POLICY IF EXISTS "studios_select_all" ON public.studios;
CREATE POLICY "studios_select_all" ON public.studios
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "studios_insert_admin" ON public.studios;
CREATE POLICY "studios_insert_admin" ON public.studios
  FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "studios_update_admin" ON public.studios;
CREATE POLICY "studios_update_admin" ON public.studios
  FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "studios_delete_admin" ON public.studios;
CREATE POLICY "studios_delete_admin" ON public.studios
  FOR DELETE USING (public.is_admin());

DROP POLICY IF EXISTS "studio_photos_select_all" ON public.studio_photos;
CREATE POLICY "studio_photos_select_all" ON public.studio_photos
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "studio_photos_insert_admin" ON public.studio_photos;
CREATE POLICY "studio_photos_insert_admin" ON public.studio_photos
  FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "studio_photos_update_admin" ON public.studio_photos;
CREATE POLICY "studio_photos_update_admin" ON public.studio_photos
  FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "studio_photos_delete_admin" ON public.studio_photos;
CREATE POLICY "studio_photos_delete_admin" ON public.studio_photos
  FOR DELETE USING (public.is_admin());

-- ---- bookings policies ----
DROP POLICY IF EXISTS "bookings_select_own_or_admin" ON public.bookings;
CREATE POLICY "bookings_select_own_or_admin" ON public.bookings
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "bookings_insert_own" ON public.bookings;
CREATE POLICY "bookings_insert_own" ON public.bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "bookings_update_admin" ON public.bookings;
CREATE POLICY "bookings_update_admin" ON public.bookings
  FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "bookings_delete_admin" ON public.bookings;
CREATE POLICY "bookings_delete_admin" ON public.bookings
  FOR DELETE USING (public.is_admin());

-- 7. RPC: data slot booking untuk kalender ketersediaan
CREATE OR REPLACE FUNCTION public.get_studio_booked_slots(
  studio_uuid UUID,
  start_date DATE,
  end_date DATE
)
RETURNS TABLE (
  tanggal_booking DATE,
  jam_mulai TIME,
  durasi_jam INTEGER,
  status TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    b.tanggal_booking,
    b.jam_mulai,
    b.durasi_jam,
    b.status
  FROM public.bookings b
  WHERE b.studio_id = studio_uuid
    AND b.tanggal_booking BETWEEN start_date AND end_date
    AND b.status IN ('menunggu', 'disetujui');
$$;

GRANT EXECUTE ON FUNCTION public.get_studio_booked_slots(UUID, DATE, DATE) TO authenticated;

-- 8. Storage bucket bukti pembayaran
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('studio-photos', 'studio-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "payment_proofs_select_authenticated" ON storage.objects;
CREATE POLICY "payment_proofs_select_authenticated" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'payment-proofs');

DROP POLICY IF EXISTS "payment_proofs_insert_authenticated" ON storage.objects;
CREATE POLICY "payment_proofs_insert_authenticated" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'payment-proofs');

DROP POLICY IF EXISTS "payment_proofs_update_authenticated" ON storage.objects;
CREATE POLICY "payment_proofs_update_authenticated" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'payment-proofs')
  WITH CHECK (bucket_id = 'payment-proofs');

DROP POLICY IF EXISTS "studio_photos_select_authenticated" ON storage.objects;
CREATE POLICY "studio_photos_select_authenticated" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'studio-photos');

DROP POLICY IF EXISTS "studio_photos_insert_admin" ON storage.objects;
CREATE POLICY "studio_photos_insert_admin" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'studio-photos' AND public.is_admin());

DROP POLICY IF EXISTS "studio_photos_update_admin" ON storage.objects;
CREATE POLICY "studio_photos_update_admin" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'studio-photos' AND public.is_admin())
  WITH CHECK (bucket_id = 'studio-photos' AND public.is_admin());

-- 9. RPC: simpan URL bukti pembayaran pada booking milik user
CREATE OR REPLACE FUNCTION public.attach_payment_proof(
  booking_uuid UUID,
  proof_url TEXT,
  file_name TEXT
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated_booking public.bookings;
BEGIN
  UPDATE public.bookings
  SET
    payment_proof_url = proof_url,
    payment_file_name = file_name,
    payment_uploaded_at = NOW()
  WHERE id = booking_uuid
    AND user_id = auth.uid()
  RETURNING * INTO updated_booking;

  IF updated_booking.id IS NULL THEN
    RAISE EXCEPTION 'Booking tidak ditemukan atau tidak memiliki akses';
  END IF;

  RETURN updated_booking;
END;
$$;

GRANT EXECUTE ON FUNCTION public.attach_payment_proof(UUID, TEXT, TEXT) TO authenticated;

-- 10. Data contoh studio (opsional)
INSERT INTO public.studios (nama_studio, deskripsi, fasilitas, harga_per_jam, foto_url)
VALUES
  (
    'TuneSpace Studio A',
    'Studio rekaman profesional dengan akustik terbaik untuk vokal dan instrumen.',
    'Microphone condenser, Audio interface, Monitor speaker, Soundproof room',
    150000,
    NULL
  ),
  (
    'TuneSpace Studio B',
    'Studio latihan band dengan peralatan drum dan amplifier lengkap.',
    'Drum set, Guitar amp, Bass amp, PA system, Jam space',
    120000,
    NULL
  ),
  (
    'TuneSpace Podcast Room',
    'Ruang podcast dengan setup siap pakai untuk konten kreator.',
    'Podcast mic, Mixer, Headphone, Recording software, Lighting',
    100000,
    NULL
  )
ON CONFLICT DO NOTHING;

-- 11. Cara membuat akun Admin:
--    a) Daftar akun biasa lewat aplikasi
--    b) Jalankan query berikut (ganti email):
--
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@tunespace.com';
