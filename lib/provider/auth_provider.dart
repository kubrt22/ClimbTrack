import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

//services provider
final authServiceProvider = Provider<AuthServices>((ref) {
  return AuthServices();
});

//auth-state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
