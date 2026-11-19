# AGENTS.md

> Mandatory engineering guideline for AI coding agents and human developers working on **StokFlow - Mobile Inventaris UMKM**.
>
> Primary goals:
> - **Strict PRD Adherence**: Align 100% with `docs/prd_sistem_inventaris_umkm_mvp.md` (MVP Phase 1).
> - **Offline-First Architecture**: Operations run locally on device first; background sync to cloud.
> - **Multi-Business SaaS Isolation**: Strict data boundary enforcement via `business_id`.
> - **High Performance & Lean Footprint**: Instant local search (< 0.5s), rapid transaction input (< 15s).
> - **Pragmatic Implementation (YAGNI)**: Zero unnecessary abstractions or speculative features.
> - **Tactical Minimal UI (Zero AI Slop)**: Match high-fidelity mockups in `docs/Mockup Visual High-Fidelity StokFlow UMKM (MVP).pdf`.
> - **Protected Git Workflow**: `feature/*` -> PR -> `dev` (Default) -> Release PR -> `main` (Protected).

---

# 1. Behavioral Directives & Quality Enforcements

1. **Automatic Pragmatism & Zero Over-Engineering (YAGNI):**
   - Strictly follow the Phase 1 MVP scope. Never introduce speculative abstractions, redundant wrapper layers, or features from future phases.
   - Prefer native Flutter/Dart standard library and established plugins (`mobile_scanner`, `sqflite`/`drift`, `flutter_secure_storage`).
   - Do NOT build custom solutions for problems already solved by standard packages.

2. **ADHD-Friendly Output Formatting (`i-have-adhd`):**
   - **Lead with Next Action**: The first line of output must be the concrete action (command, file path, or code change), not meta-commentary or plan prose.
   - **Numbered Multi-Step Tasks**: Structure multi-step work into small, bounded, single-action numbered steps without nested "and then"s.
   - **End with One Action**: End responses with exactly ONE concrete next step achievable in under two minutes.
   - **Suppress Tangents**: Address the primary task first. Offer secondary improvements as separate follow-up questions.
   - **Restate State**: Explicitly restate progress state on every turn (e.g., "Step X of Y completed...").

3. **No AI Slop & Minimal Compact UI Design:**
   - Follow `docs/Mockup Visual High-Fidelity StokFlow UMKM (MVP).pdf` strictly.
   - **Zero Gratuitous Visual Clutter**: Never add unrequested decorative badges, glowing borders, artificial gradients, or floating status pills.
   - **Compact & High-Density Sizing**: Mobile screens require efficient density. Clean typography, high contrast, standard touch targets (min 44x44 dp), and crisp padding.

---

# 2. Product Scope & MVP Boundaries (Strictly Enforced)

Refer to [PRD Section 9 & 22](file:///e:/Github/Mobile-Inventaris-Stockflow/docs/prd_sistem_inventaris_umkm_mvp.md):

### ✅ INCLUDED in MVP (Phase 1):
1. **Authentication (`OWNER` only)**:
   - Register, Login (Email or Phone + Password/PIN), Logout.
   - Logout validation: Warn user if unsynced offline data (`PENDING`) exists.
2. **Master Data Produk**:
   - Fields: Name, Unit (`pcs`, `dus`, `kg`, `pack`, etc.), Selling Price, Initial Stock, optional SKU/Barcode, optional Cost Price.
   - Camera Barcode Scanning: Via `mobile_scanner` with flashlight toggle and auto-focus.
   - Search: Instant case-insensitive search by name or barcode on local database.
   - Status: `ACTIVE` or `ARCHIVED` (soft archive; never hard delete products with transaction history).
3. **Transactions (`STOCK_IN` & `STOCK_OUT`)**:
   - `STOCK_IN`: Increases stock.
   - `STOCK_OUT`: Decreases stock. Must validate `current_stock >= quantity` (NEVER allow negative stock).
   - Multi-item transactions supported under a single transaction number.
   - Transaction number format: `[BUSINESS_CODE]-[TAHUN]-[NOMOR_URUT]`.
   - Snapshot cost: `unit_cost_snapshot` recorded at transaction time to preserve historical financial records.
4. **Offline-First & Auto-Sync**:
   - Local DB reads/writes first (`< 0.5s`).
   - Sync states: `PENDING`, `SYNCED`, `FAILED`.
   - Automatic background sync when internet connection is restored.
   - Client-generated UUIDs for idempotent syncing (prevent duplicate transactions on reconnection).
5. **Transaction History**:
   - List ordered by newest first.
   - Filter by type: `ALL`, `STOCK_IN`, `STOCK_OUT`.

### ❌ STRICTLY EXCLUDED from MVP (Reject Feature Creep):
Do NOT implement any of the following without explicit authorization:
- ❌ **Low Stock Alerts & Minimum Stock Thresholds** (Phase 3)
- ❌ **Staff Accounts / Multi-User Roles & Permissions** (Phase 2)
- ❌ **Product Categories & CSV/Excel Report Exporting** (Phase 2)
- ❌ **Guided Stock Opname with discrepancy calculation** (Phase 3)
- ❌ **Multi-Warehouse / Multi-Branch support** (Phase 4)
- ❌ **Bluetooth Thermal Printer (Barcode labels & receipts)** (Phase 3)
- ❌ **Supplier Management & Purchase Orders (PO)** (Phase 3)
- ❌ **Batch Tracking & Expired Dates / FEFO** (Phase 3)
- ❌ **POS / Cashier Module with payment gateways** (Phase 4)

---

# 3. Core Architecture & Tech Stack

## 3.1 Technology Stack
- **Framework**: Flutter (Dart) — targeting Android & iOS.
- **Local Database (Offline-First)**: `sqflite` or `drift` (SQLite engine).
- **Backend API**: Stockflow REST API (`https://stokflow-be.vercel.app/docs#/`).
- **Barcode Scanner**: `mobile_scanner` (camera-based scanning).
- **Secure Storage**: `flutter_secure_storage` (Android KeyStore / iOS Keychain) for JWT tokens.
- **Network / HTTP Client**: `dio` or `http` with connectivity detection (`connectivity_plus`).

## 3.2 Pragmatic Layered Structure
```text
lib/
├── core/
│   ├── constants/       # App constants, API endpoints, error strings
│   ├── network/         # HTTP client, interceptors, connectivity check
│   ├── storage/         # Secure storage wrapper, local SQLite DB helper
│   ├── theme/           # App colors, typography, minimal clean widgets
│   └── utils/           # Formatters (currency, date), UUID generator
│
├── data/
│   ├── datasources/
│   │   ├── local/       # SQLite DAOs (product_dao, transaction_dao, sync_dao)
│   │   └── remote/      # Stockflow REST API client (auth, product, transaction)
│   ├── models/          # Data serialization models with JSON & DB mappers
│   └── repositories/    # Offline-first repository implementations
│
├── domain/
│   ├── entities/        # Business entities (Product, Transaction, Business, User)
│   └── repositories/    # Abstract repository interfaces (contracts)
│
└── presentation/
    ├── auth/            # Login, register, profile screens
    ├── catalog/         # Product list, add/edit product, scan barcode modal
    ├── transactions/    # Stock in/out form, transaction review
    ├── history/         # Transaction history & detail
    └── shared/          # Clean reusable widgets (buttons, inputs, scanner overlay)
```

---

# 4. Critical Business & Data Rules

1. **Multi-Business Isolation**:
   - Every single table row (`products`, `stock_transactions`, `stock_transaction_items`) MUST have a valid `business_id`.
   - Never query or update data without scoping to the current authenticated `business_id`.

2. **Zero Negative Stock**:
   ```dart
   if (currentStock < requestedQuantity) {
     throw BusinessException("Stok tidak mencukupi untuk transaksi keluar.");
   }
   ```

3. **No Hard Delete on Products**:
   - Products referenced in transactions must be archived (`status = 'ARCHIVED'`). Never delete them from SQLite or backend.

4. **Idempotent Sync Mechanism**:
   - All transactions and products created locally generate a client UUID (`v4`).
   - When sending sync payloads to the backend, the backend recognizes existing UUIDs and ignores duplicate submissions.

5. **Historical Cost Integrity**:
   - When recording `stock_transaction_items`, always record `unit_cost_snapshot = product.costPrice`.
   - Future updates to product cost price must NEVER modify past transaction snapshots.

---

# 5. Git Workflow & Quality Gates (SIM-SARPRAS Standard)

```text
feature/xyz  ───►  PR  ───►  [dev]  (Default Working Branch)
                                │
                                ▼
                        Release PR / Tag
                                │
                                ▼
                             [main]  (Production / Protected)
```

1. **Branch Roles**:
   - `main`: Production releases only. Protected (direct push blocked; requires PR + 1 review + passing CI).
   - `dev`: Active development target. Default branch. All features merge here via PR.
   - `feature/*`: Short-lived branches created from `dev`.

2. **Commit Conventions**:
   - `feat(scope): ...`
   - `fix(scope): ...`
   - `refactor(scope): ...`
   - `test(scope): ...`
   - `chore(scope): ...`

3. **Security Constraints**:
   - Never commit `.env`, keystore files (`*.jks`, `*.keystore`), credentials, or tokens.
   - Verify CI passes before merging PRs.
