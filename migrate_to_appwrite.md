# Migration Guide: Migrating from Firebase to Appwrite

This document explains how to migrate Selah's Backend-as-a-Service layer to Appwrite using our clean repository interfaces (`AuthRepository` and `ScriptureUserDataRepository`).

---

## 1. Appwrite Architecture in Selah

Because `lib/src/core/services/auth_repository.dart` defines a platform-agnostic interface, switching to Appwrite requires implementing the interface using `appwrite` SDK methods.

---

## 2. Dependencies
Add `appwrite` to `pubspec.yaml`:
```yaml
dependencies:
  appwrite: ^12.0.3
```

---

## 3. Implementing `AppwriteAuthRepository`

Create `lib/src/core/services/appwrite_auth_repository.dart`:
```dart
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'auth_repository.dart';

class AppwriteAuthUser implements AuthUser {
  final models.User _user;
  AppwriteAuthUser(this._user);

  @override
  String get uid => _user.$id;
  @override
  String? get email => _user.email.isNotEmpty ? _user.email : null;
  @override
  String? get displayName => _user.name.isNotEmpty ? _user.name : null;
  @override
  bool get isAnonymous => _user.email.isEmpty;
}

class AppwriteAuthRepository implements AuthRepository {
  final Account _account;
  AuthUser? _currentUser;

  AppwriteAuthRepository(Client client) : _account = Account(client);

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_currentUser);

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signInAnonymously() async {
    final session = await _account.createAnonymousSession();
    final user = await _account.get();
    _currentUser = AppwriteAuthUser(user);
    return _currentUser!;
  }

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    await _account.createEmailPasswordSession(email: email, password: password);
    final user = await _account.get();
    _currentUser = AppwriteAuthUser(user);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _account.deleteSession(sessionId: 'current');
    _currentUser = null;
  }
}
```

---

## 4. Appwrite Database Collections

Create a Database named `selah_db` in Appwrite Console:
1. **Collection `user_favorites`**:
   - `userId` (string, required)
   - `passageRef` (string, required)
   - Document Security: Enabled (Read/Write: `user:[USER_ID]`).
2. **Collection `meditation_sessions`**:
   - `userId` (string, required)
   - `reference` (string, required)
   - `completedLoops` (integer, required)
   - `durationSeconds` (integer, required)
