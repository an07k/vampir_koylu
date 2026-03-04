# Null Safety Guidelines

This document explains how null values are handled throughout the codebase.

## Overview

We use Dart's null safety (non-nullable by default) to prevent null-related bugs. This means:
- Variables are **non-nullable by default**
- Use `?` to indicate nullable types: `String?`
- Always check for null before using nullable values

## Service Layer Null Handling

### AuthService

```dart
// getCurrentUser() - Returns null if no user logged in
Future<Map<String, dynamic>?> getCurrentUser()
// Returns: null | {'userId', 'displayName', 'avatarColor', 'nickname'?, 'isGuest'}

// login() - Always returns a result object
Future<Map<String, dynamic>> login(...)
// Returns: {'success': bool, 'error'?: String, ...user data if success}
```

**Null-safe usage:**
```dart
final user = await AuthService.getCurrentUser();
if (user != null) {
  print(user['displayName']); // Safe
}

final result = await AuthService.login(...);
if (result['success']) {
  final userId = result['userId']; // Safe - success guarantees userId
}
```

### GoldService

```dart
// getGold() - Always returns an int (default 0 if not found)
Future<int> getGold(String userId)
// Returns: 0 or positive integer
// Throws: Exception if Firebase fails (use try-catch)

// addGold() - Void function
Future<void> addGold(String userId, int amount)
// userId: must not be empty
// amount: must be >= 0
// Throws: Exception if Firebase fails
```

**Null-safe usage:**
```dart
try {
  final gold = await GoldService.getGold(userId);
  print('Gold: $gold'); // Safe - gold is always int
} catch (e) {
  // Handle error
}
```

### UserDataService

```dart
// loadUserData() - Returns null if not logged in
Future<Map<String, dynamic>?> loadUserData()
// Returns: null | {'displayName', 'avatarColor', 'gold', 'isGuest', 'nickname'?}

// getUserActiveRoom() - Returns roomId or null
Future<String?> getUserActiveRoom(String userId)
// Returns: null if no active room, or room ID string
```

**Null-safe usage:**
```dart
final userData = await UserDataService.loadUserData();
if (userData != null) {
  final displayName = userData['displayName']!; // Safe - we checked
  final nickname = userData['nickname'];        // Nullable - check if needed
  if (nickname != null) {
    print('@$nickname');
  }
}
```

## UI Layer Null Handling

### MainMenuScreen

```dart
// Build with FutureBuilder - handles loading/error states
FutureBuilder<Map<String, dynamic>?>(
  future: _userDataFuture,
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data == null) {
      return const WelcomeScreen(); // No user
    }

    final userData = snapshot.data!;
    // userData is guaranteed non-null here
  },
)
```

## Common Patterns

### Pattern 1: Optional User Nickname
```dart
final nickname = userData['nickname']; // Could be null for guests
if (nickname != null) {
  Text('@$nickname');
} else {
  // Show badge for guest instead
  Text('Guest');
}
```

### Pattern 2: Safe Map Access
```dart
final gold = (doc.data()?['gold'] as int?) ?? 0;
// If doc doesn't exist or field missing, defaults to 0
```

### Pattern 3: Assert for Validation
```dart
Future<void> addGold(String userId, int amount) async {
  assert(userId.isNotEmpty, 'userId cannot be empty');
  assert(amount >= 0, 'amount must be non-negative');
  // Code continues only if asserts pass
}
```

## Error Handling

All database operations should handle exceptions:

```dart
try {
  final user = await AuthService.getCurrentUser();
  // Use user
} catch (e) {
  // Handle error appropriately:
  // - Show error dialog to user
  // - Log error
  // - Return default value
  debugPrint('Error: $e');
}
```

## Rules Summary

| Scenario | Type | Handling |
|----------|------|----------|
| User logged in? | `Map<String, dynamic>?` | Check `!= null` |
| User nickname | `String?` | Check `!= null` |
| Gold balance | `int` | Never null, default 0 |
| Firebase error | Exception | Use try-catch |
| Function parameter | Non-nullable by default | Use `assert()` to validate |

## Future Work

- Add Firebase mock testing for null scenarios
- Add widget tests with null value scenarios
- Document all public functions with null safety docs
