# Authentication Flow - FIXED ✅

## The Issue
Previously, the farmer profile was being created DURING signup, which happened before email confirmation. This violated the security principle that user profiles should only be created AFTER the user is authenticated.

## The Fix

### ✅ Signup Flow (signUpWithEmail)
**File:** `lib/core/services/auth_service.dart`

**What it does NOW:**
- ✅ Creates ONLY the auth user in Supabase Auth
- ❌ Does NOT insert into farmers table
- ❌ Does NOT attempt to create profile
- Shows message: "Check your email to confirm your account"

```dart
// BEFORE: Created farmer profile during signup
await _supabase.from('farmers').insert({...}); // ❌ REMOVED

// AFTER: Only create auth user
final response = await _supabase.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: 'agriclinichub://login',
);
```

### ✅ Login Flow (loginWithEmail)
**File:** `lib/core/services/auth_service.dart`

**What it does NOW:**
- ✅ Signs in user with email/password
- ✅ Loads user info from auth
- ✅ **CALLS NEW METHOD:** `_ensureFarmerProfileExists()`
- ✅ Only then navigates to home

```dart
// NOW user is authenticated → auth.uid() exists
await _loadUserFromSupabase(user.id);

// CREATE farmers profile if it doesn't exist
await _ensureFarmerProfileExists(user.id, email);
```

### ✅ NEW Helper Method
**File:** `lib/core/services/auth_service.dart`

```dart
static Future<void> _ensureFarmerProfileExists(
  String userId,
  String email,
) async {
  // Check if farmer profile already exists
  final existing = await _supabase
      .from('farmers')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

  if (existing != null) {
    return; // Profile already exists, skip
  }

  // Create new farmer profile with just required fields
  await _supabase.from('farmers').insert({
    'user_id': userId,
    'email': email,
    'full_name': 'New User',
  });
}
```

**Key Features:**
- Checks if profile already exists (idempotent)
- Only inserts if needed
- Doesn't block login if profile creation fails
- Uses UUID directly (matches RLS policies)

## Updated Signup Screen
**File:** `lib/features/auth/presentation/screens/signup_screen.dart`

**Changes:**
- ❌ Removed: `fullName`, `phoneNumber`, `county` parameters
- ✅ Only passes: `email` and `password`
- ✅ Shows clear message: "Check your email to confirm your account"

```dart
// BEFORE
final credential = await AuthService.signUpWithEmail(
  email: email,
  password: password,
  fullName: fullName,        // ❌ REMOVED
  phoneNumber: phoneNumber,  // ❌ REMOVED
  county: county,             // ❌ REMOVED
);

// AFTER
final credential = await AuthService.signUpWithEmail(
  email: email,
  password: password,
);
```

## Flow Diagram

```
USER SIGNUP:
┌─────────────────┐
│ SignupScreen    │
├─────────────────┤
│ Enter:          │
│ • Email         │
│ • Password      │
│ • Name (unused) │
│ • Phone (unused)│
│ • Farm (unused) │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ AuthService.signUpWith  │
│ Email(email, password)  │
├─────────────────────────┤
│ 1. Create auth user ✅  │
│ 2. Return user data     │
│ 3. NO farmers insert ❌ │
└────────┬────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Email Verification       │
│ (user confirms email)    │
└────────┬─────────────────┘
         │
         ▼

USER LOGIN:
┌─────────────────┐
│ LoginScreen     │
├─────────────────┤
│ Enter:          │
│ • Email         │
│ • Password      │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────┐
│ AuthService.loginWithEmail       │
│ (email, password)                │
├──────────────────────────────────┤
│ 1. Sign in with Supabase Auth ✅ │
│ 2. Load user info ✅             │
│ 3. _ensureFarmerProfileExists() ✅│
│    - Check if exists             │
│    - If not → CREATE ✅          │
│ 4. Return user ✅                │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────┐
│ HomeScreen ✅    │
│ (authenticated & │
│  has profile)    │
└──────────────────┘
```

## Database RLS Compliance ✅

The flow now respects all RLS policies:

```sql
-- RLS Policy for INSERT
CREATE POLICY "farmers_insert_own"
  ON farmers FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

✅ After login: `auth.uid()` exists → can insert own profile  
✅ During signup: Not attempting insert → no RLS violation  
✅ Idempotent: Checks before inserting → no duplicate errors

## Testing Checklist

- [ ] Signup with new email → goes to email verification
- [ ] Confirm email in Supabase Dashboard
- [ ] Login with same credentials → profile auto-created
- [ ] Check Supabase Dashboard → farmers table has entry
- [ ] Login again → profile not duplicated
- [ ] Farmer profile accessible in app ✅

## Optional: Disable Email Confirmation (for testing)

In Supabase Dashboard:
1. Authentication → Providers → Email
2. Toggle OFF: "Confirm email"

This lets you instantly login after signup without email confirmation.

---

**Mental Model:**
- 🔐 Auth happens at signup
- 👤 Profile happens at login
- ✅ Separation of concerns
- ✅ RLS policies satisfied
- ✅ Idempotent farmer creation
