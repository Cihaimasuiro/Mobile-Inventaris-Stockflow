# Mobile Inventaris Stockflow (CLAUDE.md)

## Foundational Context
- **Product**: StokFlow UMKM - Mobile App Inventaris Cepat & Offline-First (MVP Fase 1).
- **Platform**: Flutter (Android & iOS).
- **Backend API**: Stockflow REST API (`https://stokflow-be.vercel.app/docs#/`).
- **Branching Model**: `dev` (Default Working Branch) -> PR -> `main` (Protected Production).

## MVP Phase 1 Scope (Strict Boundaries)
- **Role**: `OWNER` only (Multi-user/Staff is strictly Phase 2).
- **Core Features**:
  1. Auth (Register/Login via Email or Phone, Logout with offline sync warning).
  2. Master Data Produk (Add/Edit/Archive, Barcode scanner via camera `mobile_scanner`).
  3. Transaksi: `STOCK_IN` (tambah) & `STOCK_OUT` (kurang, **current_stock >= 0 wajib**).
  4. Riwayat Transaksi (Filter jenis transaksi, urutan waktu terbaru).
  5. Offline-First (Local SQLite/Drift reads/writes < 0.5s; background auto-sync status `PENDING` -> `SYNCED` / `FAILED`).
- **Feature Creep Ban (DO NOT BUILD)**:
  - ❌ Low Stock Alerts (Phase 3)
  - ❌ Staff Role / Multi-user permissions (Phase 2)
  - ❌ Categories & CSV/Excel Exports (Phase 2)
  - ❌ Guided Stock Opname (Phase 3)
  - ❌ Multi-Warehouse / POS / Thermal Printer (Phase 3/4)

## Architecture & Code Standards
- **Pattern**: Clean Pragmatic Layered (`core/`, `data/`, `domain/`, `presentation/`).
- **Multi-Business SaaS**: Wajib menyertakan `business_id` pada setiap entitas dan query.
- **UI Design**: Sesuai `docs/Mockup Visual High-Fidelity StokFlow UMKM (MVP).pdf`. Minimalis, padat (*compact*), sentuhan minimal 44x44 dp, tanpa *visual slop* (tanpa badge dekoratif berlebihan).
- **Security**: Token JWT disimpan di `flutter_secure_storage`. Jangan commit `.env` atau keystore.
- **Output Style**: ADHD-friendly (Lead with next action, numbered small steps, 1 immediate next action under 2 mins, restate state).
