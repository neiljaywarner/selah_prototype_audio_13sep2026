# Migrating from Cloud Firestore to Supabase / Appwrite.io

## 📋 Executive Overview

Selah uses **Cloud Firestore** for early prototype agility, real-time community feature voting, and feedback tracking. While Firestore offers zero-maintenance serverless scaling on Google Cloud Platform, Firestore charges per-document read/write/delete operation. At viral or high-frequency scale, operation-based pricing can become unpredictable compared to flat-rate or self-hosted relational/document backends.

This guide outlines our architectural strategy to ensure **zero vendor lock-in** and provides a step-by-step migration blueprint to **Supabase** (PostgreSQL) or **Appwrite.io** whenever required by scale, operational budgets, or self-hosting compliance.

---

## ⚖️ Architecture Comparison: Firestore vs. Supabase vs. Appwrite vs. Dedicated Tools

| Metric / Dimension | Cloud Firestore | Supabase (PostgreSQL) | Appwrite.io | Canny / Featurebase |
| :--- | :--- | :--- | :--- | :--- |
| **Pricing Model** | Per operation (reads/writes/deletes) | Flat compute + database size | Flat compute / Self-hosted Docker | Per tracked user ($99/mo+) |
| **Database Engine** | NoSQL Document Store | Relational PostgreSQL | MariaDB / Document Store | Closed SaaS |
| **Flutter SDK** | `cloud_firestore` / REST | `supabase_flutter` / PostgREST | `appwrite` / REST | WebView / REST API |
| **Self-Hostable?** | No (Proprietary GCP) | Yes (Docker, Helm, Coolify) | Yes (Single Docker compose) | No |
| **Offline Cache** | Native in mobile SDK | Via local SQLite / Hive | Via local cache layer | N/A |
| **Security Model** | Security Rules (`firestore.rules`) | Postgres Row Level Security (RLS) | Appwrite Document Permissions | API keys / JWT |
| **Best Used For** | Fast prototyping, Google cloud sync | Complex relational queries, SQL, scale | Self-hosted control, predictable cost | Standalone product feedback |

### Why Not Canny for Selah Now?
* **Cost:** Canny charges $99+/month once exceeding 100 active users, whereas Supabase and Appwrite offer generous free tiers (500MB DB, 50,000 MAU) that scale smoothly into flat $25/mo plans.
* **In-App Integration:** Building voting directly into Selah's native dark-mode theme provides a seamless, distraction-free prayer and meditation experience without embedding external iframes or webviews.

---

## 🏛️ Abstraction Layer in Selah

Selah abstracts feature voting and feedback behind a clean repository interface (`FeatureVotingRepository` / `FeedbackService`). The UI widgets (`FeatureVotingSheet`, `_FeatureVotingTile`) interact exclusively with the Riverpod notifier, never directly with raw Firestore or HTTP clients.

```
┌──────────────────────────────────────────────┐
│  Flutter UI (FeatureVotingSheet, Tiles)      │
└──────────────────────┬───────────────────────┘
                       │ Watches State
┌──────────────────────▼───────────────────────┘
│  FeatureVotingNotifier (Riverpod Notifier)   │
└──────────────────────┬───────────────────────┘
                       │ Calls
┌──────────────────────▼───────────────────────┘
│  FeatureVotingService / Repository Interface  │
├──────────────────────┬───────────────────────┤
│  Current:            │  Drop-in Migration:   │
│  Firestore REST /    │  Supabase PostgREST / │
│  Local Cache         │  Appwrite SDK         │
└──────────────────────┴───────────────────────┘
```

Because of this decoupled design, switching backends requires modifying only the concrete service implementation without touching any presentation widgets or test suites.

---

## 🚀 Migration Path to Supabase

### 1. Database Schema & RLS Setup (SQL)
Run in the Supabase SQL editor:

```sql
-- Create table for feature voting
CREATE TABLE public.feature_votes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    target_version TEXT NOT NULL,
    votes INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Enable Row Level Security
ALTER TABLE public.feature_votes ENABLE ROW LEVEL SECURITY;

-- Allow public anonymous read
CREATE POLICY "Allow public read access"
ON public.feature_votes FOR SELECT
TO anon, authenticated
USING (true);

-- Allow atomic vote increment function
CREATE OR REPLACE FUNCTION increment_feature_vote(feature_id TEXT, delta INT)
RETURNS VOID AS $$
BEGIN
    UPDATE public.feature_votes
    SET votes = votes + delta,
        updated_at = timezone('utc'::text, now())
    WHERE id = feature_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. Export Firestore Data
Export existing `feature_votes` documents via the Firebase Admin SDK or REST export:
```bash
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://firestore.googleapis.com/v1/projects/selahwordapp/databases/(default)/documents/feature_votes" \
  | jq '[.documents[] | {id: (.name | split("/") | last), title: .fields.title.stringValue, votes: (.fields.votes.integerValue | tonumber)}]' \
  > feature_votes_export.json
```

### 3. Client Migration in Dart
Swap the REST endpoint in `FeatureVotingService` to call Supabase's PostgREST API:
```dart
// Fetch:
final response = await dio.get('https://<project-ref>.supabase.co/rest/v1/feature_votes?select=*');

// Increment Vote via RPC:
await dio.post(
  'https://<project-ref>.supabase.co/rest/v1/rpc/increment_feature_vote',
  data: {'feature_id': featureId, 'delta': 1},
  options: Options(headers: {'apikey': kSupabaseAnonKey}),
);
```

---

## 🐳 Migration Path to Self-Hosted Appwrite

### 1. Appwrite Collection Setup
Create database `selah` and collection `feature_votes`:
* `title` (string, required)
* `description` (string, required)
* `target_version` (string, required)
* `votes` (integer, default 0)
* Permissions: `read("any")`, `update("any")`

### 2. Client Migration in Dart
Add `appwrite: ^12.0.0` or query the Appwrite REST API:
```dart
final client = Client()
    .setEndpoint('https://api.selahapp.org/v1')
    .setProject('selah_prod');
final databases = Databases(client);

// Get votes:
final documents = await databases.listDocuments(
    databaseId: 'selah',
    collectionId: 'feature_votes',
);
```

---

## 📌 Recommendation & Next Steps
1. **Current Phase (v0.2.x):** Continue using **Cloud Firestore** for community voting. It is serverless, already configured on `selahwordapp`, and requires zero infrastructure upkeep.
2. **Review Trigger:** If monthly active listeners exceed 25,000 users or daily database reads exceed 50,000, trigger migration evaluation to Supabase for predictable flat-tier pricing.
