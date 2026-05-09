# CLAUDE.md — PoketSync · Personal Finance Tracker

This file is automatically read by Claude Code at session start. It contains everything needed to understand, extend, and maintain this project without asking the human for context.

---

## 1. Project Overview

**PoketSync** is a private household finance tracker — a Progressive Web App (PWA) that any family or couple can self-host for free. It tracks spending across multiple bank and credit card accounts, visualizes trends, and provides AI-powered savings advice.

- **Platform**: PWA — installable on Android and iOS without any app store
- **Users**: Configurable (default: 2 household members). Defined in `USER_CONFIG` inside `public/index.html`
- **Budget**: $0/month — Firebase free tier only
- **Distribution**: Android via Chrome PWA install or sideloaded APK. iOS via Safari "Add to Home Screen"
- **Sync**: Firebase Firestore real-time — all members' phones stay in sync in < 1 second
- **Goal**: Monthly spending visibility, month-over-month trends, AI-powered savings advice

---

## 2. Repository Structure

```
PoketSync/                               ← git root
├── CLAUDE.md                       ← YOU ARE HERE
├── README.md                       ← Setup guide (Firebase steps, install instructions)
├── .gitignore
├── .env.example                    ← Template for local dev config (safe to commit)
├── firebase.json                   ← Firebase Hosting config (serves public/ folder)
├── .firebaserc                     ← Firebase project ID (fill in after setup)
├── firestore.rules                 ← Security rules — only listed emails can read/write
├── firestore.indexes.json          ← Composite indexes for Firestore queries
│
├── .github/
│   └── workflows/deploy.yml        ← GitHub Actions CI/CD — deploys on push to main
│
├── public/                         ← Firebase Hosting root
│   ├── index.html                  ← THE MAIN APP — single-file PWA
│   ├── manifest.json               ← PWA install manifest (includes PNG icons)
│   ├── sw.js                       ← Service worker (offline support + CDN caching)
│   ├── mobile_mockup.html          ← Visual design reference — 8 phone screens
│   └── icons/
│       ├── icon.svg                ← App icon (purple gradient, $ symbol)
│       ├── icon-192.png            ← PWA install icon
│       ├── icon-512.png            ← PWA splash / maskable icon
│       ├── icon-180.png            ← iOS home screen icon
│       └── favicon-32.png          ← Browser tab favicon
│
├── screenshots/                    ← README screenshots (generated from mobile_mockup.html)
│   ├── screen-1-2-login-overview.png
│   ├── screen-3-4-transactions-add.png
│   ├── screen-5-6-accounts-chat.png
│   ├── screen-7-8-offline-savings.png
│   └── mockup-full.png             ← Full page (all 8 screens combined)
│
├── data/                           ← Sample CSV files (replace with your own)
│   ├── transactions_sample-01.csv  ← Sample month 1
│   └── transactions_sample-02.csv  ← Sample month 2
│
├── scripts/
│   └── dev.sh                      ← Local dev helper script
│
└── standalone/
    └── finance_dashboard.html      ← Standalone desktop version (no Firebase)
                                       Reference implementation — read before editing PWA
```

---

## 3. User Configuration

All household-specific values are defined in a single `USER_CONFIG` object near the top of `public/index.html`. This is the **only place** personal details should appear.

```javascript
const USER_CONFIG = {
  // ── Household ────────────────────────────────────────────
  householdName: "My Household",          // shown in the app header
  currency:      "USD",                   // ISO 4217 currency code
  timezone:      "America/Los_Angeles",   // IANA timezone string

  // ── Members (add or remove as needed) ───────────────────
  members: [
    { name: "Member 1", email: "member1@example.com" },
    { name: "Member 2", email: "member2@example.com" },
  ],

  // ── Accounts (update to match your real accounts) ───────
  accounts: [
    { bank: "Bank of America", name: "Checking – Primary",   type: "Checking",     owner: "Member 1" },
    { bank: "Bank of America", name: "Checking – Secondary", type: "Checking",     owner: "Member 2" },
    { bank: "Chase",           name: "Sapphire – Primary",   type: "Credit Card",  owner: "Member 1", creditLimit: 10000 },
    { bank: "Discover",        name: "Discover IT",          type: "Credit Card",  owner: "Member 2", creditLimit: 5000  },
  ],
};
```

**Firestore security rules** (`firestore.rules`) must also be updated — replace the email placeholders with the actual emails from `USER_CONFIG.members`.

---

## 4. Firebase Configuration

The app auto-detects whether Firebase is configured:

```javascript
const FIREBASE_CONFIG = {
  apiKey:            "YOUR_API_KEY",   // ← placeholder = not configured
  authDomain:        "YOUR_PROJECT_ID.firebaseapp.com",
  projectId:         "YOUR_PROJECT_ID",
  storageBucket:     "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId:             "YOUR_APP_ID"
};

const FB_READY = FIREBASE_CONFIG.apiKey !== "YOUR_API_KEY";
// FB_READY === false → local/standalone mode (no login, demo data only)
// FB_READY === true  → Firebase mode (login required, Firestore real-time sync)
```

**Never** hard-code real user emails anywhere except `firestore.rules` and `USER_CONFIG`. Both are safe to commit — Firebase web API keys are public by design; Firestore rules enforce data access.

---

## 5. Architecture Decisions (Do Not Change These)

| Decision | Choice | Reason |
|---|---|---|
| Framework | Vanilla HTML/CSS/JS | No build step, no npm, deployable anywhere |
| Firebase SDK | Compat v10 (CDN) | Global `firebase` object, works in plain `<script>` tags |
| Charts | Chart.js 4.4.1 (CDN) | Stable, no alternative |
| Styling | Inline `<style>` block | Single-file constraint |
| Database | Firebase Firestore | Real-time sync, free tier sufficient for any household |
| Auth | Firebase Email/Password | Simple, no OAuth complexity |
| iOS distribution | Safari PWA / Add to Home Screen | Only $0 option on iOS |
| Android distribution | Chrome PWA install or TWA APK | Both free |

**Single-file constraint**: `public/index.html` must remain self-contained. Do not create separate `.js` or `.css` files unless explicitly asked.

---

## 6. Data Model

### Firestore Collection: `transactions`

```javascript
{
  id:        "auto-generated",     // Firestore doc ID
  date:      "2026-03-15",         // YYYY-MM-DD string
  desc:      "WHOLE FOODS",        // merchant / description
  category:  "Groceries",          // must match a key in CATEGORIES constant
  account:   "Chase Sapphire",     // must match a name in USER_CONFIG.accounts
  amount:    -74.80,               // negative = expense, positive = income
  type:      "expense",            // "expense" | "income"
  createdBy: "member1@example.com",// email of the person who added it
  createdAt: Timestamp,            // firebase.firestore.FieldValue.serverTimestamp()
  _source:   "january-2026.csv"    // present only if imported via CSV
}
```

### CSV Import Format

Users import their own bank/card exports via the "Load CSV" button. Expected columns:

```
date,description,category,account,amount,type
2026-03-06,EMPLOYER PAYROLL,Income,Checking – Primary,5000.00,income
2026-03-02,WHOLE FOODS,Groceries,Chase Sapphire,-56.26,expense
```

- `amount`: negative for expenses, positive for income
- `category`: must match one of the keys in the `CATEGORIES` constant
- All other CSV formats are rejected with a user-friendly error

### Categories (built-in — add new ones by updating the `CATEGORIES` constant)

Groceries, Dining Out, Amazon, Housing & Rent, Utilities, Internet & Phone, Donations & Charity, Shopping & Retail, Insurance, Gas & Fuel, Automotive & DMV, Healthcare, Subscriptions, Personal Care, Cash & ATM, Taxes, Income

---

## 7. Key JavaScript Patterns

### State Variables
```javascript
let TRANSACTIONS = [...ALL_TRANSACTIONS]; // mutable — replaced by Firestore data at runtime
let filteredTx   = [...TRANSACTIONS];     // current view after filters applied
let loadedFiles  = [];                    // CSV filenames currently loaded (local mode)
let currentPage  = 1;
const PAGE_SIZE  = 15;
let donutChart, barChart, timelineChart;  // Chart.js instances (never destroy, only update)
let db = null, auth = null;              // Firebase instances
let firestoreUnsub = null;               // Firestore unsubscribe handle
let currentUser = null;                  // Firebase Auth user object
// Mobile state
let editingTxId = null;                  // non-null when modal is in edit mode
let currentTabName = 'overview';         // tracks active tab for History API
let isOnline = navigator.onLine;         // live connectivity flag
let gesturesInitialized = false;         // prevents double-attach on auth state changes
const QUEUE_KEY = 'pocketsync_queue';    // localStorage key for offline write queue
```

### The Refresh Pipeline
Every data or filter change must flow through this exact sequence — never call render functions directly:

```
applyFilters()
  → filters TRANSACTIONS → filteredTx
  → resets currentPage = 1
  → calls refreshDashboard()
      → renderKPIs(filteredTx)
      → updateCharts(filteredTx)     ← mutates chart data, calls chart.update('none')
      → renderTable()
```

### Chart Update Rule
- `renderCharts()` — called **once** on init to create Chart.js instances
- `updateCharts(txList)` — called on every filter change, mutates `.data` in place, then `chart.update('none')`
- **Never** destroy and recreate charts — it causes flicker and loses animation state

### Firestore Real-time Listener
```javascript
function listenToTransactions() {
  firestoreUnsub = db.collection('transactions')
    .orderBy('date', 'desc')
    .onSnapshot(snapshot => {
      const txs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      TRANSACTIONS = txs.length > 0 ? txs : [...ALL_TRANSACTIONS]; // fallback to demo data
      filteredTx = [...TRANSACTIONS];
      populateFilters();
      applyFilters();
      showSyncStatus('synced');
    }, err => showSyncStatus('error'));
}
```

### CSV → Firestore Batch Write
When Firebase is active, CSV imports go to Firestore (not local array):
```javascript
const batch = db.batch();
parsed.forEach(tx => {
  const ref = db.collection('transactions').doc();
  batch.set(ref, { ...tx, createdBy: currentUser.email, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
});
await batch.commit();
```

### Mobile Function Reference

| Function | Purpose |
|---|---|
| `showTab(name, skipHistory)` | Switches active tab, pushes `history.pushState`, fires haptic, syncs bottom nav |
| `vibrate(pattern)` | Wraps `navigator.vibrate` — degrades silently on iOS |
| `initSwipeGestures()` | Single `touchstart/touchmove/touchend` handler for PTR (vertical) and tab swipe (horizontal) — guarded by `gesturesInitialized` |
| `initModalDrag()` | Drag-to-dismiss on `.modal-handle`; dismisses at > 120 px or > 0.5 px/ms; snap-back otherwise |
| `renderQuickAddChips()` | Populates preset amount chips and top-4 category chips in the Add/Edit modal |
| `triggerRefresh()` | Re-subscribes Firestore listener (Firebase mode) or re-applies filters (local mode) — called by PTR |
| `updateMonthMiniHeader()` | Auto-detects dominant month in filtered view; called at start of `renderTable()` |
| `updateChartsForViewport()` | Adjusts chart options (legend position, point radius, tension) for mobile vs desktop |
| `toggleFilterBar()` | Shows/hides `.filter-row-extras`; called by the filter toggle button |
| `updateFilterBadge()` | Counts active non-default filters; updates badge text; called by `applyFilters()` |
| `getOfflineQueue()` | Reads `localStorage[QUEUE_KEY]` → parsed array |
| `queueTxOffline(tx)` | Appends a transaction to the localStorage queue |
| `flushOfflineQueue()` | Commits queued writes to Firestore in order; called on reconnect and on every snapshot |
| `updateQueueBadge()` | Updates the queue count badge in the sync indicator |

---

## 8. AI Chat System

Five providers supported. Built-in works with no API key:

| Provider | Key Prefix | Free? | Notes |
|---|---|---|---|
| Built-in | none | ✓ | Keyword engine, works offline, default |
| Gemini | `AIza...` | ✓ | aistudio.google.com |
| Groq | `gsk_...` | ✓ | console.groq.com |
| OpenRouter | `sk-or-v1-...` | ✓ free tier | openrouter.ai |
| Claude | `sk-ant-...` | paid | console.anthropic.com |

**Dashboard Action System**: AI responses embed `<DASHBOARD_ACTION>{...}</DASHBOARD_ACTION>` tags to control the dashboard (navigate tabs, apply filters, highlight rows). Parsed in `executeDashboardAction()`. Do not remove.

**Extending the built-in engine**: Add keywords to `catKeywords` in `answerBuiltIn()` and add a new conditional branch. Never replace the whole function.

**System prompt** (`SYSTEM_PROMPT` constant): References `USER_CONFIG.householdName` and member names dynamically — do not hardcode any personal details in the prompt string.

---

## 9. CSS Design System

All CSS uses variables defined in `:root`:

```css
--bg:       #0f1117   /* page background */
--surface:  #1a1d27   /* card background */
--surface2: #22263a   /* nested surface / hover */
--border:   #2e3350   /* all borders */
--accent:   #6366f1   /* primary — purple */
--accent2:  #8b5cf6   /* secondary — lighter purple */
--green:    #10b981   /* income, positive, success */
--red:      #ef4444   /* expense, negative, error */
--yellow:   #f59e0b   /* warning, tax, caution */
--blue:     #3b82f6   /* neutral data */
--cyan:     #06b6d4   /* neutral data alt */
--text:     #e2e8f0   /* body text */
--muted:    #8892a4   /* secondary text, labels */
--radius:   14px
--chat-w:   400px
```

**Dark theme only.** No light mode. Do not add a toggle.

---

## 10. Mobile Layout Rules

| Breakpoint | Behaviour |
|---|---|
| `≤ 768px` | Bottom nav visible · Top tab-bar hidden · `padding-bottom: 80px` on main content |
| `> 768px` | Top tab-bar visible · Bottom nav hidden · Chat panel sticky on right |
| FAB (`#addTxFab`) | `bottom: 80px` on mobile (clears bottom nav) · `bottom: 24px` on desktop |
| Chat panel | `position: fixed` overlay on mobile · `position: sticky` on desktop |
| Safe areas | Use `env(safe-area-inset-bottom)` for notched phones (iPhone X+) |
| Charts | `height: 180px` (donut) / `160px` (bar/timeline) on mobile; legend moves to bottom |
| Filter bar | `.filter-row-extras` hidden by default on mobile; `display: contents` on desktop to dissolve wrappers back into flex row |

### Touch interaction rules
- Swipe left/right on `#mainContent` navigates between tabs — guarded against canvas elements (Chart.js)
- Pull-to-refresh (`#ptrBar`) triggers at 52 px pull depth — vertical movement only
- PTR and swipe share one unified touch handler in `initSwipeGestures()` — they discriminate by direction
- Modal drag uses `will-change: transform` for GPU compositing — always reset `transform` and `transition` in `closeAddModal()`
- All touch listeners on scroll containers use `{ passive: true }`; only the drag touchmove uses `{ passive: false }` (needs `preventDefault`)

---

## 11. New UI Components (PWA only, not in standalone)

### Login Screen (`#loginScreen`)
- Full-screen overlay, `display: flex`, centered card
- Email + password inputs, Sign In button, error message div
- No sign-up UI — accounts are created in Firebase Console

### Add Transaction Modal (`#addTxModal`)
- Bottom sheet on mobile, centered modal on desktop
- Fields: Date · Description · Category (from `CATEGORIES`) · Account (from `USER_CONFIG.accounts`) · Amount · Type toggle
- On save: write to Firestore (Firebase mode) or push to local array (local mode)

### Bottom Navigation (`.bottom-nav`)
- 5 items: Overview · Transactions · ➕ Add (center, accent) · Accounts · Savings
- Hidden on desktop via `@media (min-width: 769px)`
- Active state synced with `showTab()`

### Sync Status Badge (`.sync-badge` in header)
- `syncing` → yellow · `synced` → green · `error` → red
- Hidden entirely in local mode (`FB_READY === false`)

### Toast Notifications (`#toast`)
- Fixed position, fades in/out
- `showToast(message, type)` — type is `'success'` or `'error'`

### Pull-to-Refresh Bar (`#ptrBar`)
- First child of `#mainContent`; `margin: -20px -20px 0` bleeds to edges
- Height expands via `touchmove` (deltaY × 0.4, capped at 52 px)
- Hidden on desktop via `@media (min-width: 769px)`

### Month Mini-Header (`#monthMiniHeader`)
- Inside `#tab-transactions`, above the `.card` table wrapper
- Shows dominant month of current filtered view (most frequent month by transaction count)
- Toggled by `updateMonthMiniHeader()` at start of `renderTable()`

### Offline Banner + Queue Badge
- Yellow `#offlineBanner` shown when `isOnline === false`
- `.queue-badge` span inside `#syncBadge` shows pending write count
- `updateQueueBadge()` keeps it in sync with `localStorage[QUEUE_KEY]`

### Quick-Add Chips (`#quickAmountRow`, `#quickCategoryRow`)
- Rendered inside the Add/Edit modal below the Amount field
- Amount chips: $10 / $20 / $50 / $100 / $200 / $500 (formatted with `fmtDec`)
- Category chips: top-4 expense categories by frequency in `TRANSACTIONS`
- Both rows hidden by default; shown on mobile via `@media (max-width: 768px)` override

---

## 12. Deployment

```bash
# One-time setup
npm install -g firebase-tools
firebase login

# Full deploy (hosting + rules + indexes)
firebase deploy

# Hosting only (faster iteration)
firebase deploy --only hosting

# Local development server
firebase serve              # → http://localhost:5000
```

---

## 13. Common Tasks Reference

### Add a spending category
1. Add to `CATEGORIES` constant in `public/index.html` (color + emoji)
2. Add keywords to `catKeywords` in `answerBuiltIn()`
3. Optionally add to `standalone/finance_dashboard.html` too

### Add a new household member
1. Add to `USER_CONFIG.members` array
2. Add their email to `firestore.rules` authorized list
3. Create their Firebase Auth account in Firebase Console
4. Run `firebase deploy --only firestore:rules`

### Seed Firestore on first login
First login finds an empty Firestore collection → app falls back to `ALL_TRANSACTIONS` demo data.
To seed real data: use "Load CSV" button → rows are batch-written to Firestore → both phones sync.

### Rename the app
Change `"name"` and `"short_name"` in `public/manifest.json` and the `<title>` tag in `public/index.html`.

---

## 14. What NOT to Do

- **Do not** introduce npm, webpack, vite, or any build pipeline
- **Do not** split `public/index.html` into multiple files unless explicitly asked
- **Do not** use the Firebase modular SDK (ES module imports) — use compat CDN only
- **Do not** add a sign-up/registration flow — all accounts are created in Firebase Console
- **Do not** add a light mode — dark theme is intentional and final
- **Do not** destroy and recreate Chart.js instances on filter changes
- **Do not** reference `ALL_TRANSACTIONS` in render logic — always use `TRANSACTIONS`
- **Do not** hardcode any user names, emails, or account details outside of `USER_CONFIG`
- **Do not** create separate config files for secrets — Firebase web keys are safe to commit
- **Do not** add new touch listeners outside `initSwipeGestures()` — they conflict with PTR and swipe; extend that function instead
- **Do not** call `initSwipeGestures()` more than once — the `gesturesInitialized` guard exists for this; respect it
- **Do not** reset `modal-sheet` transform or transition anywhere except `closeAddModal()` — drag state must be fully cleared on every close

---

## 15. Implementation Status

| Feature | Status | Notes |
|---|---|---|
| Standalone dashboard (desktop) | ✅ Done | `standalone/finance_dashboard.html` |
| KPI cards | ✅ Done | `renderKPIs()` |
| Donut + bar + timeline charts | ✅ Done | `renderCharts()` / `updateCharts()` |
| Transaction table + pagination | ✅ Done | `renderTable()` |
| Reactive filters | ✅ Done | `applyFilters()` → `refreshDashboard()` |
| CSV data source + chip UI | ✅ Done | `handleCsvLoad()` |
| Accounts tab | ✅ Done | `renderAccounts()` |
| Savings tips tab | ✅ Done | `renderSavings()` |
| AI chat — 5 providers | ✅ Done | `sendMessage()` + provider functions |
| Built-in AI engine | ✅ Done | `answerBuiltIn()` |
| Dashboard action control via AI | ✅ Done | `executeDashboardAction()` |
| PWA manifest + PNG icons | ✅ Done | `public/manifest.json`, `public/icons/` |
| Service worker | ✅ Done | `public/sw.js` |
| App icon | ✅ Done | `public/icons/icon.svg` + PNG variants |
| Firebase config files | ✅ Done | `firebase.json`, `.firebaserc`, rules |
| `public/index.html` — PWA app | ✅ Done | Single-file, self-contained |
| Firebase Auth (login screen) | ✅ Done | `#loginScreen` — email/password |
| Firestore real-time sync | ✅ Done | `listenToTransactions()` + `onSnapshot` |
| Add Transaction modal + FAB | ✅ Done | `#addTxModal`, `#addTxFab`, `saveTx()` |
| Edit / delete transaction | ✅ Done | `openEditModal()`, `deleteTx()` — inline row actions |
| Mobile bottom navigation | ✅ Done | `.bottom-nav` — 5 items, synced with `showTab()` |
| Sync status indicator | ✅ Done | `.sync-badge` with queue count badge |
| `USER_CONFIG` — generic user config | ✅ Done | Single object near top of `index.html` |
| Android back-button (History API) | ✅ Done | `pushState` in `showTab()`, `popstate` listener |
| Haptic feedback | ✅ Done | `vibrate()` utility — silent on iOS |
| Swipe navigation | ✅ Done | `initSwipeGestures()` — horizontal swipe between tabs |
| Pull-to-refresh | ✅ Done | `#ptrBar` + `triggerRefresh()` |
| Collapsible filter bar | ✅ Done | `toggleFilterBar()`, `updateFilterBadge()` |
| Portrait-optimized charts | ✅ Done | `updateChartsForViewport()` — responsive legend + sizing |
| Month mini-header | ✅ Done | `updateMonthMiniHeader()` in `renderTable()` |
| Offline queue | ✅ Done | `queueTxOffline()`, `flushOfflineQueue()`, localStorage |
| Drag-to-dismiss modal | ✅ Done | `initModalDrag()` — velocity + distance threshold |
| Quick-add chips | ✅ Done | `renderQuickAddChips()` — amounts + top categories |
| CI/CD pipeline | ✅ Done | `.github/workflows/deploy.yml` — auto-deploy on push |
