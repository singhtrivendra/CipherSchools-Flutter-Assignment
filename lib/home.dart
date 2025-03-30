import 'package:cipherx/add_expemse.dart';
import 'package:cipherx/add_income.dart';
import 'package:cipherx/database_helper.dart';
import 'package:cipherx/navigation_bar.dart';
import 'package:cipherx/notification.dart';
import 'package:cipherx/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Add this new screen for showing all transactions
class AllTransactionsScreen extends StatefulWidget {
  final String selectedMonth;

  const AllTransactionsScreen({Key? key, required this.selectedMonth}) : super(key: key);

  @override
  _AllTransactionsScreenState createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String selectedMonth = "";

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.selectedMonth;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get all transactions for the selected month
      final allTransactions = await _dbHelper.getTransactionsByMonth(selectedMonth);
      
      setState(() {
        transactions = allTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'shopping':
        return Icons.shopping_cart;
      case 'travel':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'subscription':
        return Icons.subscriptions;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.laptop;
      case 'investments':
        return Icons.trending_up;
      default:
        return Icons.attach_money;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.red;
      case 'shopping':
        return Colors.orange;
      case 'travel':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'subscription':
        return Colors.indigo;
      case 'salary':
        return Colors.green;
      case 'freelance':
        return Colors.teal;
      case 'investments':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Transactions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF7F57F6),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(
                  child: Text(
                    "No transactions for $selectedMonth",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionItem(
                      transaction['category'] as String,
                      transaction['description'] as String? ?? 'No description',
                      transaction['type'] == 'income'
                          ? "+ ${_formatCurrency(transaction['amount'] as double)}"
                          : "- ${_formatCurrency(transaction['amount'] as double)}",
                      DateFormat('dd MMM, hh:mm a').format(DateTime.parse(transaction['date'] as String)),
                      _getIconForCategory(transaction['category'] as String),
                      _getColorForCategory(transaction['category'] as String),
                      transaction['id'] as int,
                    );
                  },
                ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, String time, IconData icon, Color color, int id) {
    return Dismissible(
      key: Key(id.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm'),
              content: Text('Are you sure you want to delete this transaction?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await _dbHelper.deleteTransaction(id);
        _loadTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction deleted'))
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amount.startsWith('+') ? Colors.green : Colors.red,
                ),
              ),
              Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// Update the DatabaseHelper class with a new method to get transactions by month
// You'll need to add this method to your database_helper.dart file
/*
class DatabaseHelper {
  // ... your existing code

  Future<List<Map<String, dynamic>>> getTransactionsByMonth(String month) async {
    final db = await database;
    final monthIndex = months.indexOf(month) + 1; // Convert month name to number
    
    // Query transactions where the month part of the date matches the selected month
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM transactions WHERE strftime('%m', date) = ? ORDER BY date DESC",
      [monthIndex.toString().padLeft(2, '0')]
    );
    
    return result;
  }
  
  // Also update your getRecentTransactions method to filter by month
  Future<List<Map<String, dynamic>>> getRecentTransactionsByMonth(String month, int limit) async {
    final db = await database;
    final monthIndex = months.indexOf(month) + 1; // Convert month name to number
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM transactions WHERE strftime('%m', date) = ? ORDER BY date DESC LIMIT ?",
      [monthIndex.toString().padLeft(2, '0'), limit]
    );
    
    return result;
  }
}
*/

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Initialize selectedMonth to current month
  late String selectedMonth;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  String userName = "User";
  String? profileImageUrl;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];
  bool isLoading = true;

  // 3-letter abbreviations for months
  final List<String> months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  void initState() {
    super.initState();
    // Set default selected month to current month
    final currentMonth = DateTime.now().month;
    selectedMonth = months[currentMonth - 1]; // Adjust for 0-based index
    _loadData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      final currentUser = _authService.getCurrentUser();

      setState(() {
        userName = userData?['name'] ?? currentUser?.displayName ?? "User";
        
        if (currentUser != null) {
          profileImageUrl = currentUser.photoURL;
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get income and expense totals for the selected month
      final income = await _dbHelper.getTotalIncomeByMonth(selectedMonth);
      final expense = await _dbHelper.getTotalExpenseByMonth(selectedMonth);
      
      // Get recent transactions for the selected month
      final transactions = await _dbHelper.getRecentTransactionsByMonth(selectedMonth, 4);
      
      setState(() {
        totalIncome = income;
        totalExpense = expense;
        balance = income - expense;
        recentTransactions = transactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await _loadUserData();
        },
        child: Stack(
          children: [
            _buildGradientBackground(),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20),
                        _buildSummarySection(),
                        SizedBox(height: 20),
                        _buildTransactionSection(),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => IncomeEntryScreen()),
                          ).then((_) => _loadData());
                        },
                      ),
                      _buildActionButton(
                        context,
                        "Expense",
                        Icons.arrow_upward,
                        Colors.red,
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExpenseEntryScreen()),
                          ).then((_) => _loadData());
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
        backgroundColor: Color(0xFF7F57F6),
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(selectedIndex: 0),
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

  Widget _buildGradientBackground() {
    return Container(
      height: 250, // Reduced height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE9CBFF), // Lighter purple top
            Colors.white, // Fades into white
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  // Profile navigation action
                },
                child: profileImageUrl != null 
                  ? Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return CircleAvatar(
                              radius: 25,
                              backgroundImage: AssetImage('assets/profile.png'),
                            );
                          },
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
              ),
              
              // Month selector moved here (left of notification)
              _buildMonthDropdown(),
              
              // Clickable notification icon
              GestureDetector(
                onTap: () {
                  // Navigate to notifications page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.notifications, color: Colors.purple, size: 24),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Bolder, smaller greeting
          Text(
            "$greeting, $userName!",
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.w800, // Bolder
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Here's your financial summary",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(_formatCurrency(balance), 
                     style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Account Balance", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Smaller container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          isDense: true, // Makes dropdown more compact
          icon: Icon(
            Icons.keyboard_arrow_up, // Inverted caret
            color: Colors.purple,
            size: 20,
          ),
          items: months.map((String month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month, 
                style: GoogleFonts.poppins(
                  fontSize: 14, // Smaller text
                  fontWeight: FontWeight.w500
                )
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedMonth = newValue!;
              _loadData(); // Reload data when month changes
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryCard("Income", _formatCurrency(totalIncome), Colors.green[600]!, Icons.arrow_downward),
          _buildSummaryCard("Expenses", _formatCurrency(totalExpense), Colors.red[600]!, Icons.arrow_upward),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title, 
                    style: GoogleFonts.poppins(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    amount, 
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransactionHeader(),
          SizedBox(height: 10),
          recentTransactions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No transactions for $selectedMonth. Add your first transaction!",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: recentTransactions.map((transaction) {
                    return _buildTransactionItem(
                      transaction['category'] as String,
                      transaction['description'] as String? ?? 'No description',
                      transaction['type'] == 'income'
                          ? "+ ${_formatCurrency(transaction['amount'] as double)}"
                          : "- ${_formatCurrency(transaction['amount'] as double)}",
                      DateFormat('dd MMM, hh:mm a').format(DateTime.parse(transaction['date'] as String)),
                      _getIconForCategory(transaction['category'] as String),
                      _getColorForCategory(transaction['category'] as String),
                      transaction['id'] as int,
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'shopping':
        return Icons.shopping_cart;
      case 'travel':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'subscription':
        return Icons.subscriptions;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.laptop;
      case 'investments':
        return Icons.trending_up;
      default:
        return Icons.attach_money;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.red;
      case 'shopping':
        return Colors.orange;
      case 'travel':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'subscription':
        return Colors.indigo;
      case 'salary':
        return Colors.green;
      case 'freelance':
        return Colors.teal;
      case 'investments':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Recent Transactions", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {
            // Navigate to all transactions screen with selected month
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllTransactionsScreen(selectedMonth: selectedMonth),
              ),
            ).then((_) => _loadData()); // Refresh data when returning
          },
          child: Text("See All", style: GoogleFonts.poppins(fontSize: 14, color: Colors.purple)),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, String time, IconData icon, Color color, int id) {
    return Dismissible(
      key: Key(id.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm'),
              content: Text('Are you sure you want to delete this transaction?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await _dbHelper.deleteTransaction(id);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction deleted'))
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amount.startsWith('+') ? Colors.green : Colors.red,
                ),
              ),
              Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}