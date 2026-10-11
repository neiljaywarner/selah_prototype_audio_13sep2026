abstract class AuthUser {
  String get uid;
  String? get email;
  String? get displayName;
  bool get isAnonymous;
}

class SimpleAuthUser implements AuthUser {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final bool isAnonymous;

  const SimpleAuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signInAnonymously();
  Future<AuthUser> signInWithEmailPassword(String email, String password);
  Future<void> signOut();
}

class InMemoryAuthRepository implements AuthRepository {
  AuthUser? _user = const SimpleAuthUser(uid: 'anon_demo_user', isAnonymous: true);

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> signInAnonymously() async {
    _user = const SimpleAuthUser(uid: 'anon_demo_user', isAnonymous: true);
    return _user!;
  }

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    _user = SimpleAuthUser(uid: 'user_${email.hashCode}', email: email);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}
