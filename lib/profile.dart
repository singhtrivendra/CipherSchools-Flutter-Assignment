import 'package:cipherx/add_expemse.dart';
import 'package:cipherx/add_income.dart';
import 'package:cipherx/login.dart';

import 'package:cipherx/navigation_bar.dart';
import 'package:cipherx/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String userName = "Loading...";
  String userEmail = "Loading...";
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    // Get user data from the AuthService
    try {
      final userData = await _authService.getUserData();
      final currentUser = _authService.getCurrentUser();

      setState(() {
        userName = userData?['name'] ?? currentUser?.displayName ?? "User";
        userEmail = userData?['email'] ?? currentUser?.email ?? "";
        
        // Get profile image URL if available
        if (currentUser != null) {
          profileImageUrl = currentUser.photoURL;
          
          // Store photoURL in Firestore if not already there
          if (profileImageUrl != null && userData != null && userData['photoURL'] == null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'photoURL': profileImageUrl});
          }
        }
        
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = "User";
        userEmail = "";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background color
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProfileHeader(),
                SizedBox(height: 20),
                _buildProfileOptions(context),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a modal bottom sheet with options for Income or Expense
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))
            ),
            builder: (context) => Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add Transaction", 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        "Income",
                        Icons.arrow_downward,
                        Colors.green,
                        () {
                          Navigator.pop(context); // Close the bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => IncomeEntryScreen()),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        "Expense",
                        Icons.arrow_upward,
                        Colors.red,
                        () {
                          Navigator.pop(context); // Close the bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExpenseEntryScreen()),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
        backgroundColor: Color(0xFF7F57F6), // Purple color matching UI
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(selectedIndex: 3), // 3 for Profile
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile picture - now uses Google profile image if available
          _buildProfileImage(),
          SizedBox(height: 10),
          Text(
            "Username",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          Text(
            userName,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            userEmail,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 5),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.grey),
            onPressed: () {
              _showEditProfileDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // Google profile image if available, otherwise default asset
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Image.network(
            profileImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default if network image fails
              return CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/profile.png'),
                child: userEmail.isNotEmpty 
                  ? null 
                  : Icon(Icons.person, size: 40, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else {
      // Default profile picture
      return CircleAvatar(
        radius: 40,
        backgroundImage: AssetImage('assets/profile.png'),
        child: userEmail.isNotEmpty 
          ? null 
          : Icon(Icons.person, size: 40, color: Colors.grey),
      );
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController(text: userName);
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile picture preview at the top
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildProfileImage(),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Email cannot be changed',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    userEmail,
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 16),
                if (profileImageUrl == null)
                  Text(
                    'Profile picture is automatically linked from your Google account if you signed in with Google.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7F57F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
              onPressed: () async {
                // Update name in Firestore
                try {
                  final user = _authService.getCurrentUser();
                  if (user != null) {
                    // Update display name in Firebase Auth
                    await user.updateDisplayName(nameController.text);
                    
                    // Update name in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': nameController.text});
                        
                    setState(() {
                      userName = nameController.text;
                    });
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                } catch (e) {
                  print('Error updating profile: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile')),
                  );
                }
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildOptionTile(Icons.account_circle, "Account", onTap: () {
            _showAccountDetails(context);
          }),
          _buildOptionTile(Icons.settings, "Settings", onTap: () {
            // Navigate to settings screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Settings feature coming soon')),
            );
          }),
          _buildOptionTile(Icons.upload, "Export Data", onTap: () {
            // Handle export data action
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export feature coming soon')),
            );
          }),
          _buildOptionTile(Icons.logout, "Logout", isLogout: true, onTap: () {
            _handleLogout(context);
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, {bool isLogout = false, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Color(0xFF7F57F6)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, color: isLogout ? Colors.red : Colors.black),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showAccountDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Account Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image in account details
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildProfileImage(),
                ),
              ),
              Text('Name:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text(userName, style: GoogleFonts.poppins()),
              SizedBox(height: 10),
              Text('Email:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text(userEmail, style: GoogleFonts.poppins()),
              SizedBox(height: 10),
              FutureBuilder<String?>(
                future: _authService.getUserIdFromPrefs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ID:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text(
                        snapshot.data != null && snapshot.data!.length > 10
                            ? snapshot.data!.substring(0, 10) + '...'
                            : snapshot.data ?? 'Not available',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 10),
              Text('Sign-in Method:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text(
                profileImageUrl != null ? 'Google' : 'Email/Password',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7F57F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Close', style: GoogleFonts.poppins(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('Cancel', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Logging out...", style: GoogleFonts.poppins()),
                ],
              ),
            ),
          );
        },
      );

      try {
        // Logout using the AuthService
        await _authService.signOut();
        
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }
}

// Add these imports at the top of the file
