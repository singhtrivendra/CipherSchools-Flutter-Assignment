import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Email/Password Sign Up
  Future<User?> createUserWithEmailAndPassword(
      {required String email, required String password, required String name}) async {
    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get user
      final User? user = userCredential.user;
      
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);
        await user.reload(); // Reload user to get updated display name
        
        // Create a new user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Save user ID to SharedPreferences
        await _saveUserIdToPrefs(user.uid);
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during email/password sign up: $e');
      // Rethrow to handle in UI
      rethrow;
    } catch (e) {
      print('Error during email/password sign up: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
  
// Updated Google Sign In implementation
// Completely revised Google Sign In implementation
Future<User?> signInWithGoogle() async {
  try {
    // Try to sign out first to ensure a clean state
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Pre-signout error (can be ignored): $e');
    }
    
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      print('Google sign in process was aborted by user');
      return null;
    }
    
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    if (googleAuth.idToken == null) {
      print('Failed to get ID token from Google Sign In');
      return null;
    }
    
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // Sign in with the credential directly to Firebase
    final userCredential = await _auth.signInWithCredential(credential);
    
    final User? user = userCredential.user;
    
    if (user != null) {
      // Don't await the Firestore operations to prevent blocking
      // Firebase auth completes first
      _saveUserToFirestore(user);
      _saveUserIdToPrefs(user.uid);
    }
    
    return user;
  } catch (e) {
    print('Error signing in with Google: $e');
    
    // Special handling for the PigeonUserDetails error
    if (e.toString().contains('PigeonUserDetails')) {
      // The user was actually signed in despite the error
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('User was actually signed in despite error: ${currentUser.uid}');
        // Save user data in the background
        _saveUserToFirestore(currentUser);
        _saveUserIdToPrefs(currentUser.uid);
        return currentUser;
      }
    }
    
    rethrow;
  }
}

// Helper method to save user to Firestore without awaiting
void _saveUserToFirestore(User user) {
  _firestore.collection('users').doc(user.uid).get().then((doc) {
    if (!doc.exists) {
      _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((e) {
        print('Error creating user document: $e');
      });
    }
  }).catchError((e) {
    print('Error checking if user exists: $e');
  });
}
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;
      
      if (user != null) {
        // Save user ID to SharedPreferences
        await _saveUserIdToPrefs(user.uid);
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during email/password sign in: $e');
      rethrow;
    } catch (e) {
      print('Error signing in with email/password: $e');
      rethrow;
    }
  }
  
  // Save user ID to SharedPreferences
  Future<void> _saveUserIdToPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
  
  // Get current user ID from SharedPreferences
  Future<String?> getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
  
  // Check if user is logged in - improved to check both Firebase and SharedPreferences
  Future<bool> isUserLoggedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // If no current user in Firebase, check if we have a userId in SharedPreferences
      final userId = await getUserIdFromPrefs();
      if (userId == null) {
        return false;
      }
      
      // If we have a userId but no current user, try to refresh the auth state
      try {
        await _auth.authStateChanges().first;
        return _auth.currentUser != null;
      } catch (e) {
        return false;
      }
    }
    return true;
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}