import 'package:cipherx/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cipherx/database_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String filterType = "all"; // "all", "income", or "expense"

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> result;
      
      if (filterType == "all") {
        result = await _dbHelper.getTransactions();
      } else {
        result = await _dbHelper.getTransactionsByType(filterType);
      }
      
      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
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
      appBar: AppBar(
        title:           Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
onPressed: () {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => HomeScreen()),
    (route) => false, // Removes all previous routes
  );
},

              ),
              SizedBox(width: 30),
              Text(
                "Transaction History",
                style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        backgroundColor: Color(0xFF7F57F6),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, size: 70, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          "No transactions found",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      var transaction = transactions[index];
                      bool isIncome = transaction['type'] == 'income';
                      return _buildTransactionCard(
                        id: transaction['id'] as int,
                        category: transaction['category'] as String,
                        description: transaction['description'] as String? ?? 'No description',
                        amount: transaction['amount'] as double,
                        date: transaction['date'] as String,
                        wallet: transaction['wallet'] as String,
                        isIncome: isIncome,
                      );
                    },
                  ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Filter Transactions",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.all_inclusive, color: Color(0xFF7F57F6)),
                title: Text("All Transactions", style: GoogleFonts.poppins()),
                onTap: () {
                  setState(() {
                    filterType = "all";
                  });
                  Navigator.pop(context);
                  _loadTransactions();
                },
                selected: filterType == "all",
                selectedTileColor: Colors.purple[50],
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward, color: Colors.green),
                title: Text("Income Only", style: GoogleFonts.poppins()),
                onTap: () {
                  setState(() {
                    filterType = "income";
                  });
                  Navigator.pop(context);
                  _loadTransactions();
                },
                selected: filterType == "income",
                selectedTileColor: Colors.green[50],
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: Colors.red),
                title: Text("Expenses Only", style: GoogleFonts.poppins()),
                onTap: () {
                  setState(() {
                    filterType = "expense";
                  });
                  Navigator.pop(context);
                  _loadTransactions();
                },
                selected: filterType == "expense",
                selectedTileColor: Colors.red[50],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard({
    required int id,
    required String category,
    required String description,
    required double amount,
    required String date,
    required String wallet,
    required bool isIncome,
  }) {
    DateTime transactionDate = DateTime.parse(date);
    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(transactionDate);
    
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
      child: Card(
        elevation: 2,
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getColorForCategory(category).withOpacity(0.2),
                        child: Icon(_getIconForCategory(category), color: _getColorForCategory(category)),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            wallet,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    isIncome ? "+ ${_formatCurrency(amount)}" : "- ${_formatCurrency(amount)}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty && description != 'No description')
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
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
}