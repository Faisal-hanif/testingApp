import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  // Private variables
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userEmail;
  String? _userName;
  String? _userRole;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userRole => _userRole;

  // Demo users database (temporary)
  final Map<String, Map<String, String>> _users = {
    'demo@sqa.com': {
      'password': 'password123',
      'name': 'Demo User',
      'role': 'admin'
    },
    'user@test.com': {
      'password': 'test123',
      'name': 'Test User',
      'role': 'user'
    },
    'nehal@test.com': {
      'password': 'nehal123',
      'name': 'Syed Nehal',
      'role': 'admin'
    }
  };

  // Login method
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user exists
      if (_users.containsKey(email)) {
        final user = _users[email]!;

        // Check password
        if (user['password'] == password) {
          _isAuthenticated = true;
          _userEmail = email;
          _userName = user['name'];
          _userRole = user['role'];

          print('✅ Login successful: $email');
        } else {
          throw Exception('Invalid password');
        }
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('❌ Login failed: $e');
      rethrow; // Re-throw the error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register method
  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user already exists
      if (_users.containsKey(email)) {
        throw Exception('User already exists');
      }

      // Add new user
      _users[email] = {
        'password': password,
        'name': name,
        'role': 'user'
      };

      // Auto login after registration
      _isAuthenticated = true;
      _userEmail = email;
      _userName = name;
      _userRole = 'user';

      print('✅ Registration successful: $email');
    } catch (e) {
      print('❌ Registration failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userRole = null;

    _isLoading = false;
    notifyListeners();

    print('✅ Logout successful');
  }

  // Check if user is admin
  bool isAdmin() {
    return _userRole == 'admin';
  }

  // Get user info
  Map<String, dynamic> getUserInfo() {
    return {
      'email': _userEmail,
      'name': _userName,
      'role': _userRole,
      'isAuthenticated': _isAuthenticated,
    };
  }

  // Reset password (demo)
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    if (_users.containsKey(email)) {
      print('📧 Password reset link sent to: $email');
    } else {
      throw Exception('Email not found');
    }

    _isLoading = false;
    notifyListeners();
  }
}