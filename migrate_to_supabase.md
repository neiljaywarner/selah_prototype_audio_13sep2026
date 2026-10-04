# Migration Guide: Migrating from Firebase to Supabase

This document outlines how to migrate Selah's Backend-as-a-Service layer from Firebase to Supabase using our clean repository interfaces (`AuthRepository` and `ScriptureUserDataRepository`).

---

## 1. Why Migrating is Painless in Selah

Selah uses CodeWithAndrea's Feature-First pattern with abstract repository interfaces:
- `lib/src/core/services/auth_repository.dart`
- `lib/src/core/services/user_data_repository.dart`

The Flutter UI and Riverpod providers talk **only** to these interfaces, meaning zero UI code needs to be altered.

---

## 2. Dependencies
Replace `firebase_auth` and `cloud_firestore` with `supabase_flutter`:
```yaml
dependencies:
  supabase_flutter: ^2.8.0
```

---

## 3. Implementing `SupabaseAuthRepository`

Create `lib/src/core/services/supabase_auth_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class SupabaseAuthUser implements AuthUser {
  final User _user;
  SupabaseAuthUser(this._user);

  @override
  String get uid => _user.id;
  @override
  String? get email => _user.email;
  @override
  String? get displayName => _user.userMetadata?['name'];
  @override
  bool get isAnonymous => _user.isAnonymous;
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Stream<AuthUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) =>
          event.session?.user != null ? SupabaseAuthUser(event.session!.user) : null);

  @override
  AuthUser? get currentUser =>
      _client.auth.currentUser != null ? SupabaseAuthUser(_client.auth.currentUser!) : null;

  @override
  Future<AuthUser> signInAnonymously() async {
    final res = await _client.auth.signInAnonymously();
    return SupabaseAuthUser(res.user!);
  }

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    return SupabaseAuthUser(res.user!);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
```

---

## 4. PostgreSQL Schema in Supabase (Replacing Firestore)

Run this SQL in the Supabase SQL Editor:
```sql
-- User Favorites Table
create table public.user_favorites (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    passage_ref text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(user_id, passage_ref)
);

-- Meditation Sessions Table
create table public.meditation_sessions (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    reference text not null,
    completed_loops integer not null,
    duration_seconds integer not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.user_favorites enable row level security;
alter table public.meditation_sessions enable row level security;

create policy "Users can manage own favorites" on public.user_favorites
    for all using (auth.uid() = user_id);

create policy "Users can manage own sessions" on public.meditation_sessions
    for all using (auth.uid() = user_id);
```
