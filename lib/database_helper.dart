import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  static Database? _database;
  
  // List of months for converting between names and numbers
  final List<String> months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  // Full month names for UI display
  final List<String> fullMonths = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await initDatabase();
    return _database!;
  }
  
  Future<Database> initDatabase() async {
    // Initialize FFI only on desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    String path = join(await getDatabasesPath(), 'finance_tracker.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create transactions table
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            description TEXT,
            category TEXT NOT NULL,
            wallet TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
        
        // Create budgets table
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            month TEXT NOT NULL,
            year INTEGER NOT NULL,
            amount REAL NOT NULL,
            UNIQUE(category, month, year)
          )
        ''');
      },
    );
  }
  
  // Add a new transaction (income or expense)
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction);
  }
  
  // Get all transactions
  Future<List<Map<String, dynamic>>> getTransactions() async {
    Database db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }
  
  // Get transactions by type (income or expense)
  Future<List<Map<String, dynamic>>> getTransactionsByType(String type) async {
    Database db = await database;
    return await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC'
    );
  }
  
  // Get transactions by month
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
  
  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Get total income
  Future<double> getTotalIncome() async {
    Database db = await database;
    var result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "income"'
    );
    return result.isEmpty || result.first['total'] == null ? 0.0 : (result.first['total'] as num).toDouble();
  }
  
  // Get total expense
  Future<double> getTotalExpense() async {
    Database db = await database;
    var result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "expense"'
    );
    return result.isEmpty || result.first['total'] == null ? 0.0 : (result.first['total'] as num).toDouble();
  }
  
  // Get total income by month
  Future<double> getTotalIncomeByMonth(String month) async {
    Database db = await database;
    final monthIndex = months.indexOf(month) + 1; // Convert month name to number
    
    var result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "income" AND strftime("%m", date) = ?',
      [monthIndex.toString().padLeft(2, '0')]
    );
    return result.isEmpty || result.first['total'] == null ? 0.0 : (result.first['total'] as num).toDouble();
  }
  
  // Get total expense by month
  Future<double> getTotalExpenseByMonth(String month) async {
    Database db = await database;
    final monthIndex = months.indexOf(month) + 1; // Convert month name to number
    
    var result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "expense" AND strftime("%m", date) = ?',
      [monthIndex.toString().padLeft(2, '0')]
    );
    return result.isEmpty || result.first['total'] == null ? 0.0 : (result.first['total'] as num).toDouble();
  }
  
  // Get recent transactions limited by count
  Future<List<Map<String, dynamic>>> getRecentTransactions(int limit) async {
    Database db = await database;
    return await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit
    );
  }
  
  // Get recent transactions by month limited by count
  Future<List<Map<String, dynamic>>> getRecentTransactionsByMonth(String month, int limit) async {
    final db = await database;
    final monthIndex = months.indexOf(month) + 1; // Convert month name to number
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM transactions WHERE strftime('%m', date) = ? ORDER BY date DESC LIMIT ?",
      [monthIndex.toString().padLeft(2, '0'), limit]
    );
    
    return result;
  }
  
  // Get transaction summary by category (for pie chart)
  Future<List<Map<String, dynamic>>> getCategorySummary(String type) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total 
      FROM transactions 
      WHERE type = ? 
      GROUP BY category
      ORDER BY total DESC
      ''',
      [type]
    );
  }
  
  // Get category summary by month
  Future<List<Map<String, dynamic>>> getCategorySummaryByMonth(String type, String month) async {
    Database db = await database;
    final monthIndex = months.indexOf(month) + 1; // Convert month name to number
    
    return await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ?
      GROUP BY category
      ORDER BY total DESC
      ''',
      [type, monthIndex.toString().padLeft(2, '0')]
    );
  }
  
  // Get monthly summary (for trend analysis)
  Future<List<Map<String, dynamic>>> getMonthlySummary(String type) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT substr(date, 1, 7) as month, SUM(amount) as total 
      FROM transactions 
      WHERE type = ? 
      GROUP BY substr(date, 1, 7)
      ORDER BY month
      ''',
      [type]
    );
  }

  // Save a budget for a category and month
  Future<int> saveBudget(String category, String month, int year, double amount) async {
    Database db = await database;
    
    // Check if budget already exists
    List<Map<String, dynamic>> existing = await db.query(
      'budgets', 
      where: 'category = ? AND month = ? AND year = ?',
      whereArgs: [category, month, year]
    );
    
    if (existing.isNotEmpty) {
      // Update existing budget
      return await db.update(
        'budgets',
        {'amount': amount},
        where: 'category = ? AND month = ? AND year = ?',
        whereArgs: [category, month, year]
      );
    } else {
      // Insert new budget
      return await db.insert('budgets', {
        'category': category,
        'month': month,
        'year': year,
        'amount': amount
      });
    }
  }

  // Get budgets for a specific month and year
  Future<List<Map<String, dynamic>>> getBudgetsForMonth(String month, int year) async {
    Database db = await database;
    return await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year]
    );
  }
  
  // Get budget vs actual spending for a month
  Future<List<Map<String, dynamic>>> getBudgetVsActual(String month, int year) async {
    Database db = await database;
    final monthIndex = fullMonths.indexOf(month) + 1; // Convert month name to number
    
    return await db.rawQuery('''
      SELECT 
        b.category, 
        b.amount as budget, 
        COALESCE(SUM(t.amount), 0) as spent
      FROM 
        budgets b
      LEFT JOIN 
        transactions t ON b.category = t.category 
        AND t.type = 'expense' 
        AND strftime('%m', t.date) = ?
        AND strftime('%Y', t.date) = ?
      WHERE 
        b.month = ? AND b.year = ?
      GROUP BY 
        b.category
    ''', 
    [monthIndex.toString().padLeft(2, '0'), year.toString(), month, year]);
  }
  
  // Delete a budget
  Future<int> deleteBudget(String category, String month, int year) async {
    Database db = await database;
    return await db.delete(
      'budgets',
      where: 'category = ? AND month = ? AND year = ?',
      whereArgs: [category, month, year],
    );
  }
  
  // Get category summary by date range (for budget screen)
  Future<List<Map<String, dynamic>>> getCategorySummaryByDateRange(
    String type, 
    String startDate, 
    String endDate
  ) async {
    Database db = await database;
    
    return await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND date >= ? AND date <= ?
      GROUP BY category
      ORDER BY total DESC
      ''',
      [type, startDate, endDate]
    );
  }
  
  // Get total budget for a month
  Future<double> getTotalBudgetForMonth(String month, int year) async {
    Database db = await database;
    var result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM budgets 
      WHERE month = ? AND year = ?
      ''',
      [month, year]
    );
    return result.isEmpty || result.first['total'] == null ? 0.0 : (result.first['total'] as num).toDouble();
  }
}