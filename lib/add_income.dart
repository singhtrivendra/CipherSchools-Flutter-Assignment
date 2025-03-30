import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cipherx/database_helper.dart';

class IncomeEntryScreen extends StatefulWidget {
  @override
  _IncomeEntryScreenState createState() => _IncomeEntryScreenState();
}

class _IncomeEntryScreenState extends State<IncomeEntryScreen> {
  double amount = 0;
  String? selectedCategory;
  String? selectedWallet;
  String? description;
  final TextEditingController amountController = TextEditingController(text: "0");
  final TextEditingController descriptionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final List<String> categories = ["Salary", "Freelance", "Investments", "Other"];
  final List<String> wallets = ["Cash", "Bank Account", "UPI"];

  @override
  void initState() {
    super.initState();
    amountController.addListener(() {
      if (amountController.text.isNotEmpty) {
        setState(() {
          amount = double.tryParse(amountController.text) ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Save transaction to database
  Future<void> _saveTransaction() async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount'))
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category'))
      );
      return;
    }

    if (selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a wallet'))
      );
      return;
    }

    try {
      final transaction = {
        'amount': amount,
        'description': descriptionController.text,
        'category': selectedCategory!,
        'wallet': selectedWallet!,
        'type': 'income',
        'date': DateTime.now().toIso8601String(),
      };

      await _dbHelper.insertTransaction(transaction);
      
      // Return to home screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7F57F6), // Purple background matching screenshot
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(child: _buildBottomCard()),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Go back to home screen
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: 90),
              Text(
                "Income",
                style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              
            ],
          ),
          SizedBox(height: 120),
          Text("How much?", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
          SizedBox(height: 5),
          Row(
            children: [
              Text(
                "₹",
                style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Smooth curved top
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              
              _buildDropdown("Category", categories, (value) {
                setState(() {
                  selectedCategory = value;
                });
              }),
              SizedBox(height: 15),
              _buildTextField("Description", descriptionController),
              SizedBox(height: 15),
              _buildDropdown("Wallet", wallets, (value) {
                setState(() {
                  selectedWallet = value;
                });
              }),
              SizedBox(height: 50),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        hint: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
        value: label == "Category" ? selectedCategory : selectedWallet,
        items: items.map((String item) {
          return DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.poppins(fontSize: 14)));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7F57F6), // Same purple color as header
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text("Continue", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}