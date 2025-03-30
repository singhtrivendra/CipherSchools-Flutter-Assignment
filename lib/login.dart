import 'package:cipherx/home.dart';
import 'package:cipherx/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cipherx/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    _checkCurrentUser();
  }
  
  // Check if user is already logged in and navigate to home if needed
  Future<void> _checkCurrentUser() async {
    final isLoggedIn = await _authService.isUserLoggedIn();
    if (isLoggedIn && mounted) {
      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  // Email/Password login
Future<void> _handleLogin() async {
  final String email = _emailController.text.trim();
  final String password = _passwordController.text;
  
  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter both email and password')),
    );
    return;
  }
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    User? user;
    
    try {
      user = await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      print('Email sign-in error: $e');
      
      // Check if user is actually signed in despite the error
      user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('User is actually signed in: ${user.uid}');
      }
    }
    
    if (user != null) {
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful! Redirecting...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
      
      // Delay before navigation
      await Future.delayed(Duration(milliseconds: 1000));
      if (!mounted) return;
      
      // Force navigation to home screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed. Please check your credentials and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage = 'Failed to login';
    
    if (e.code == 'user-not-found') {
      errorMessage = 'No user found for that email';
    } else if (e.code == 'wrong-password') {
      errorMessage = 'Wrong password provided for that user';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'The email address is not valid';
    } else if (e.code == 'user-disabled') {
      errorMessage = 'This user has been disabled';
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to login: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // Google sign-google-in
Future<void> _handleGoogleSignIn() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    User? user;
    
    try {
      user = await _authService.signInWithGoogle();
    } catch (e) {
      print('Google sign-in error: $e');
      
      // Check if user is actually signed in despite the error
      if (e.toString().contains('PigeonUserDetails')) {
        user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('User is actually signed in: ${user.uid}');
        }
      }
    }
    
    if (user != null) {
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in successful! Redirecting...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
      
      // Delay before navigation
      await Future.delayed(Duration(milliseconds: 1000));
      if (!mounted) return;
      
      // Force navigation to home screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in was cancelled or failed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Center(
          child: Text(
            "Login",
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          SizedBox(width: 48), // Ensures title stays centered
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Add forgot password functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Forgot password feature to be implemented')),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color.fromARGB(255, 121, 44, 244),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                ? Center(child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 121, 44, 244),
                  ))
                : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: const Color.fromARGB(255, 121, 44, 244),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: Text(
                    "Login",
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Or with",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: const Color.fromARGB(255, 220, 220, 220),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/google.svg",
                      height: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Continue with Google",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 129, 129, 129),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 3),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromARGB(255, 121, 44, 244),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}