import 'package:cipherx/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cipherx/database_helper.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  double totalBudget = 0.0;
  double totalSpent = 0.0;
  double remaining = 0.0;
  List<Map<String, dynamic>> categoryBudgets = [];
  bool isLoading = true;
  
  // Month selection variables
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int selectedMonthIndex = DateTime.now().month - 1;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  // Default category budgets
  final List<Map<String, dynamic>> defaultCategories = [
    {'category': 'Food', 'budget': 5000.0, 'spent': 0.0, 'icon': Icons.fastfood, 'color': Colors.red},
    {'category': 'Shopping', 'budget': 3000.0, 'spent': 0.0, 'icon': Icons.shopping_cart, 'color': Colors.orange},
    {'category': 'Travel', 'budget': 2000.0, 'spent': 0.0, 'icon': Icons.directions_car, 'color': Colors.blue},
    {'category': 'Entertainment', 'budget': 1500.0, 'spent': 0.0, 'icon': Icons.movie, 'color': Colors.purple},
    {'category': 'Subscription', 'budget': 1000.0, 'spent': 0.0, 'icon': Icons.subscriptions, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Get the first and last day of the selected month
  DateTime _getFirstDayOfMonth() {
    return DateTime(selectedYear, selectedMonthIndex + 1, 1);
  }

  DateTime _getLastDayOfMonth() {
    return DateTime(selectedYear, selectedMonthIndex + 1 + 1, 0);
  }

  // Go to previous month
  void _previousMonth() {
    setState(() {
      if (selectedMonthIndex == 0) {
        selectedMonthIndex = 11;
        selectedYear--;
      } else {
        selectedMonthIndex--;
      }
      selectedMonth = months[selectedMonthIndex];
      _loadData();
    });
  }

  // Go to next month
  void _nextMonth() {
    setState(() {
      if (selectedMonthIndex == 11) {
        selectedMonthIndex = 0;
        selectedYear++;
      } else {
        selectedMonthIndex++;
      }
      selectedMonth = months[selectedMonthIndex];
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get date range for the selected month
      DateTime startDate = _getFirstDayOfMonth();
      DateTime endDate = _getLastDayOfMonth();
      
      // Format dates for database query
      String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
      
      // In a real app, pass the date range to filter expenses by month
      final expenses = await _dbHelper.getCategorySummaryByDateRange(
        'expense', 
        startDateStr, 
        endDateStr
      );
      
      // Create a copy of default categories
      List<Map<String, dynamic>> updatedBudgets = List.from(defaultCategories);
      
      // Update spent amounts from actual expenses
      for (var expense in expenses) {
        final categoryName = expense['category'] as String;
        final amount = expense['total'] as double;
        
        final index = updatedBudgets.indexWhere((item) => 
          item['category'].toString().toLowerCase() == categoryName.toLowerCase());
        
        if (index != -1) {
          updatedBudgets[index]['spent'] = amount;
        }
      }
      
      // Calculate totals
      double total = 0.0;
      double spent = 0.0;
      
      for (var budget in updatedBudgets) {
        total += budget['budget'] as double;
        spent += budget['spent'] as double;
      }
      
      setState(() {
        categoryBudgets = updatedBudgets;
        totalBudget = total;
        totalSpent = spent;
        remaining = total - spent;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to format currency
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Stack(
          children: [
            _buildGradientBackground(),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildHeader(),
                          SizedBox(height: 10),
                          _buildMonthSelector(),
                          SizedBox(height: 20),
                          _buildBudgetSummary(),
                          SizedBox(height: 20),
                          _buildCategoryBudgets(),
                          // Add extra space at the bottom
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBudgetDialog();
        },
        backgroundColor: Color(0xFF7F57F6),
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE6A7FF), // Light Purple at the Top
            Color(0xFFF8E1FF), // Fades into White
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.purple[800]),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false, // Removes all previous routes
              );
            },
          ),
          // Title with flexible width
          Flexible(
            child: Text(
              "Budget Manager",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Empty container to balance the layout
          Container(width: 48)
        ],
      ),
    );
  }

  // New month selector widget similar to home screen
  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 18),
            onPressed: _previousMonth,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  "$selectedMonth $selectedYear",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  // Original dropdown (can be removed or kept as an alternative)
  Widget _buildMonthDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          icon: Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple[100],
            ),
            child: Icon(Icons.arrow_drop_down, size: 18, color: Colors.purple),
          ),
          items: months.map((String month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(
                month,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedMonth = newValue!;
              selectedMonthIndex = months.indexOf(newValue);
              // Filter budgets by month
              _loadData();
            });
          },
        ),
      ),
    );
  }

  Widget _buildBudgetSummary() {
    // Calculate percentage spent
    double percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0;
    percentage = percentage > 1 ? 1 : percentage; // Cap at 100%
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 5,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Budget",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatCurrency(totalBudget),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: percentage > 0.9 ? Colors.red : 
                             percentage > 0.7 ? Colors.orange : 
                             Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem("Spent", _formatCurrency(totalSpent), Colors.red),
                _buildSummaryItem("Remaining", _formatCurrency(remaining), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBudgets() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Category Budgets",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          ...categoryBudgets.map((budget) => _buildCategoryBudgetItem(
            budget['category'],
            budget['budget'],
            budget['spent'],
            budget['icon'],
            budget['color'],
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetItem(String category, double budgetAmount, double spentAmount, IconData icon, Color color) {
    double percentage = budgetAmount > 0 ? (spentAmount / budgetAmount) : 0;
    percentage = percentage > 1 ? 1 : percentage; // Cap at 100%
    
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "${_formatCurrency(spentAmount)} of ${_formatCurrency(budgetAmount)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  _showEditBudgetDialog(category, budgetAmount);
                },
              ),
            ],
          ),
          SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: percentage > 0.9 ? Colors.red : 
                           percentage > 0.7 ? Colors.orange : 
                           Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog() {
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Budget Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Budget Amount",
                  border: OutlineInputBorder(),
                  prefixText: "₹",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation
                if (categoryController.text.trim().isEmpty || 
                    amountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill all fields"))
                  );
                  return;
                }
                
                double amount;
                try {
                  amount = double.parse(amountController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid amount"))
                  );
                  return;
                }
                
                // Add new budget category
                setState(() {
                  categoryBudgets.add({
                    'category': categoryController.text,
                    'budget': amount,
                    'spent': 0.0,
                    'icon': Icons.category,
                    'color': Colors.blueGrey,
                  });
                  
                  // Update total budget
                  totalBudget += amount;
                  remaining = totalBudget - totalSpent;
                });
                
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showEditBudgetDialog(String category, double currentAmount) {
    final TextEditingController amountController = TextEditingController(text: currentAmount.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Budget: $category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Budget Amount",
                  border: OutlineInputBorder(),
                  prefixText: "₹",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Remove this category
                setState(() {
                  int index = categoryBudgets.indexWhere((budget) => budget['category'] == category);
                  if (index != -1) {
                    totalBudget -= categoryBudgets[index]['budget'] as double;
                    categoryBudgets.removeAt(index);
                    remaining = totalBudget - totalSpent;
                  }
                });
                
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text("Delete"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation
                if (amountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter an amount"))
                  );
                  return;
                }
                
                double newAmount;
                try {
                  newAmount = double.parse(amountController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid amount"))
                  );
                  return;
                }
                
                // Update budget amount
                setState(() {
                  int index = categoryBudgets.indexWhere((budget) => budget['category'] == category);
                  if (index != -1) {
                    double oldAmount = categoryBudgets[index]['budget'] as double;
                    categoryBudgets[index]['budget'] = newAmount;
                    
                    // Update total budget
                    totalBudget = totalBudget - oldAmount + newAmount;
                    remaining = totalBudget - totalSpent;
                  }
                });
                
                Navigator.of(context).pop();
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }
}