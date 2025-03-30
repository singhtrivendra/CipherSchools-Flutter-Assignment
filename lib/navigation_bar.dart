import 'package:cipherx/add_expemse.dart';
import 'package:cipherx/add_income.dart';
import 'package:cipherx/budget.dart';
import 'package:cipherx/transaction.dart';
import 'package:flutter/material.dart';
import 'package:cipherx/home.dart';

import 'package:cipherx/profile.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  
  const CustomBottomNavBar({required this.selectedIndex});
  
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_filled, 0), // Home
          _buildNavItem(context, Icons.swap_horiz, 1), // Expense
          SizedBox(width: 40), // Space for FAB
          _buildNavItem(context, Icons.pie_chart_outline, 2), // Income
          _buildNavItem(context, Icons.person_outline, 3), // Profile
        ],
      ),
    );
  }
  
  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: selectedIndex == index ? Color(0xFF7F57F6) : Colors.grey,
      ),
      onPressed: () {
        if (selectedIndex != index) {
          // Navigate only if we're not already on this page
          Widget page;
          switch (index) {
            case 0:
              page = HomeScreen();
              break;
            case 1:
              page = TransactionHistoryScreen();
              break;
            case 2:
              page = BudgetScreen();
              break;
            case 3:
              page = ProfileScreen();
              break;
            default:
              page = HomeScreen();
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
    );
  }
}