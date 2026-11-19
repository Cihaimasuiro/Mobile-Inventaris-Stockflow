# AGENTS.md

> Mandatory engineering guideline for AI coding agents and developers working on **Mobile Inventaris Stockflow**.
>
> Primary goals:
> - Maintainability & Testability
> - High Performance & Lightweight Footprint
> - Security & Secure Credential Storage
> - Clean, Tactical & Minimal UI (Zero AI Slop)
> - Strict Git Workflow (`dev` -> `main` with protection)
> - Seamless Integration with Stockflow Backend API (`https://stokflow-be.vercel.app/docs#/`)

---

# 1. Default Behavioral Directives & Enforcements

1. **Active Pragmatism & Zero Over-Engineering (YAGNI):**
   - Automatically apply lean implementation standards. Never introduce speculative abstractions, redundant wrappers, or unused DTO layers.
   - Always choose native platform features and official framework capabilities before adding third-party packages.
   - Solve the exact problem requested using the most direct, clean, and maintainable path.

2. **ADHD-Friendly Output Formatting (`i-have-adhd`):**
   - **Lead with Next Action**: The first line of output must be the concrete action (command, file path, or code change), not meta-commentary or plan prose.
   - **Numbered Multi-Step Tasks**: Structure multi-step work into small, bounded, single-action numbered steps without nested "and then"s.
   - **End with One Action**: End responses with exactly ONE concrete next step achievable in under two minutes.
   - **Suppress Tangents**: Address the primary task first. Offer secondary improvements as separate follow-up questions.
   - **Restate State**: Explicitly restate progress state on every turn (e.g., "Step X of Y completed...").

3. **No AI Slop & Minimal Compact UI Design:**
   - **Zero Gratuitous Visual Clutter**: Never add unrequested decorative badges, status pills, count indicators, glowing cards, or artificial gradients.
   - **Plain & Standard Presentation**: Render text, numbers, IDs, and statuses cleanly using high-contrast, accessible, and readable components.
   - **Compact & High-Density Sizing**: Mobile screens have limited real estate. Use compact font sizing, crisp margins, and comfortable touch targets (minimum 44x44 dp) without oversized padding or bloated card borders.

---

# 2. Git & Branching Strategy (SIM-SARPRAS Pattern)

This project strictly follows the two-tier protected branch model:

```text
feature/xyz  ───►  PR  ───►  [dev]  (Active Development)
                               │
                               ▼
                       Release PR / Tag
                               │
                               ▼
                            [main]  (Production / Protected)
```

1. **`main` Branch (Production / Protected):**
   - Always stable, deployable, and tagged for releases.
   - **Protected**: Direct pushes are strictly forbidden. All merges must go through a Pull Request with reviews and passing CI checks.

2. **`dev` Branch (Primary Working Branch):**
   - The default development target. Daily feature development, testing, and day-to-day commits land here.
   - All feature branches branch off `dev` and merge back into `dev`.

3. **Commit Message Format (Conventional Commits):**
   ```text
   feat(scope): concise description of new feature
   fix(scope): concise description of bug fix
   refactor(scope): code change without behavior alteration
   perf(scope): performance improvement
   test(scope): test addition or correction
   chore(scope): build, dependency, or config update
   ```

---

# 3. Architecture & API Guidelines

## 3.1 Backend Integration
- Target Backend API: **Stockflow Backend** (`https://stokflow-be.vercel.app/docs#/`)
- Endpoints, query parameters, headers, and authentication schemas must strictly adhere to the OpenAPI specification provided in the documentation.
- Never hardcode API base URLs, keys, or credentials in source code. Use environment configurations (`.env.example` template).

## 3.2 Mobile Architecture Layers
Organize code into clean, pragmatic layers:
```text
lib/ / src/
├── core/           # Shared utilities, themes, constants, network client
├── data/           # API providers, data sources, models / serialization
├── domain/         # Business entities, use cases, repository contracts
└── presentation/   # Screens, widgets/components, state management
```

## 3.3 Security Rules
- Store auth tokens securely using the platform's secure vault (e.g. Flutter Secure Storage / EncryptedSharedPreferences on Android & Keychain on iOS).
- Never commit `.env`, keystore files (`.jks`, `.keystore`), certificates, or private keys.
- Validate and sanitize all user input before sending payloads to the backend.
