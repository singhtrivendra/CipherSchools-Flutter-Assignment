# CipherSchools Expense Tracker App

A personal finance management application built with Flutter and Firebase that helps users track their expenses, categorize spending, and visualize financial data.

## Features

### Authentication
- Google Sign-in authentication
- Session persistence using SharedPreferences
- Clean login/signup flow with modern UI

### Expense Management
- Add income and expense entries with categories
- Delete transactions with swipe gestures
- Categorization of expenses (Food, Travel, Shopping, Bills, etc.)
- Detailed transaction history

### Budget Planning
- Set and manage monthly budgets
- Category-specific budget allocation
- Visual progress tracking for each budget category
- Remaining budget calculation

### Dashboard & Analytics
- Financial summary dashboard
- Account balance overview
- Income vs. Expenses visualization
- Recent transactions list

### User Experience
- Clean, intuitive Material Design UI
- Color-coded categories and transactions
- Responsive layout for various device sizes

## Screens

The app includes the following screens:
  <table>
      <tr>
        <h3>Splash Screen || OnBoarding Screen || Signup</h3>
       <td><img src="https://github.com/user-attachments/assets/2bfc6ef7-0f7e-4650-8049-6a19e1228243" width ="300" height = "600"></td>
       <td><img src="https://github.com/user-attachments/assets/aeffae59-293b-4527-bebe-9b4df173a574" width = "300" height = "600"></td>
       <td><img src="https://github.com/user-attachments/assets/3e29cb7e-d35c-4a8f-9585-01518274424b" width = "300" height = "600"></td>
      </tr>
  </table>
  <table>
      <tr>
      <h3>Home || History || Profile</h3>
       <td><img src="https://github.com/user-attachments/assets/f1241017-178d-40e9-a7b2-0330b2bf2a28" width = "300" height = "600"></td>
       <td><img src="https://github.com/user-attachments/assets/c67a45cf-0de8-480a-a560-aec07c22cee0" width = "300" height = "600"></td>
       <td><img src="https://github.com/user-attachments/assets/6ce53556-447e-4663-a8b0-dc0e5f58594c" width = "300" height = "600"></td>

    </tr>
  </table>
  <table>
      <tr>
      <h3>Bugget || Add Income || Add Expense </h3>
       <td><img src="https://github.com/user-attachments/assets/d7b90551-602b-4a45-9cf6-49e6fbd8e459" width = "300" height = "600"></td>
       <td><img src="https://github.com/user-attachments/assets/33715db7-a537-409d-9ed8-46dd20cab402" width = "300" height = "600"></td>
       <td><img src="https://github.com/user-attachments/assets/2d0a8878-4f1b-466e-a66a-3dc4d5881ff7" width = "300" height = "600"></td>
       </tr>
  </table>


## Technical Implementation

### State Management
- Provider package for state management
- Efficient UI updates based on data changes

### Data Storage
- Local storage with SQLite/Hive for offline access
- Firebase Cloud Firestore for user data synchronization
- User document structure based on Firebase UID

### Authentication
- Firebase Authentication for secure Google sign-in
- Token management and session persistence

## Project Structure
```
lib/
├── main.dart
├── services/
│   ├── auth_service.dart
│   ├── add_expense.dart
│   ├── add_income.dart
│   ├── budget.dart
│   ├── database_helper.dart
│   ├── firebase_options.dart
│   ├── home.dart
│   ├── login.dart
│   ├── navigation_bar.dart
│   ├── notification.dart
│   ├── onboarding.dart
│   ├── profile.dart
│   ├── signup.dart
│   ├── splash_screen.dart
│   └── transaction.dart
```

## Installation and Setup

### Prerequisites
- Flutter SDK (2.5.0 or higher)
- Dart SDK (2.14.0 or higher)
- Android Studio / VS Code
- Firebase account

### Getting Started
1. Clone the repository
```   
git clone https://github.com/yourusername/CipherSchools-Flutter-Assignment.git
```
2. Navigate to project directory
```
   cd CipherSchools-Flutter-Assignment
```

3. Install dependencies
   ```
   flutter pub get
   ```
## Configure Firebase
- Create a new Firebase project
- Add Android application with package name `com.cipherschools.assignment`
- Download and add `google-services.json` to `/android/app/`
- Enable Google Authentication in Firebase console
- Create Firestore database

## Run the application
```
flutter run
```
## Implementation Details

### Local Database
The app uses SQLite/Hive for local storage to ensure offline functionality. Key data structures include:
- User profile information
- Transaction history
- Budget categories and allocations

### Firebase Integration
- Authentication: Google Sign-in with secure token management
- Firestore: Document structure with user-specific collections
- Real-time data synchronization when online

### UI Components
- Custom budget progress indicators
- Transaction list with swipe-to-delete functionality
- Category selection with visual icons
- Form validation for expense/income entry



## Bonus Features Implemented

1. **Budget Alerts**: Notifications when approaching category budget limits
2. **Dark/Light Theme Toggle**: Support for system and user-selected themes
3. **Data Export**: Ability to export transaction history as CSV
4. **Recurring Transactions**: Support for scheduled recurring expenses
5. **Multi-currency Support**: Track expenses in different currencies

## Future Enhancements

- Expense analytics with charts and graphs
- Bill reminders and due date tracking
- Financial goal setting and tracking
- OCR receipt scanning for automatic expense entry
- Cloud backup and restore functionality

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Design inspiration from Figma templates
- CipherSchools for the project requirements
- Flutter and Firebase documentation

📩 Contact
For any queries or support, feel free to reach out:
✉️ trivendrasingh0711@gmail.com
