# Mobile Inventaris Stockflow Guidelines

## Foundational Context
- Client mobile application for **Stockflow** inventory management.
- Backend API: `https://stokflow-be.vercel.app/docs#/`.
- Branching Model: `main` (Protected/Release), `dev` (Primary Development).

## Architecture & Code Standards
- Keep architecture clean, pragmatic, and layered: Presentation -> Domain -> Data.
- Avoid premature abstractions; prefer native standard libraries and framework-native solutions.
- Never hardcode secrets, tokens, or backend base URLs. Use environment variables.
- Write tests alongside feature logic.
- Follow Conventional Commits: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`.
- Output must be ADHD-friendly (lead with action, single next step, numbered small steps).

