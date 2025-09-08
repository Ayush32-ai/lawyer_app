# Firebase Storage Troubleshooting Guide

## Error: `[firebase_storage/object-not-found] No object exists at the desired reference`

This error occurs when trying to access Firebase Storage that doesn't exist or isn't properly configured.

## Common Causes & Solutions

### 1. Firebase Storage Not Enabled

**Problem**: Firebase Storage service is not enabled in your Firebase project.

**Solution**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click "Storage"
4. If you see "Get started", click it to enable Storage
5. Choose a location for your storage bucket
6. Set up security rules (start with test mode for development)

### 2. Storage Rules Too Restrictive

**Problem**: Firebase Storage security rules are blocking access.

**Solution**:
1. Go to Firebase Console → Storage → Rules
2. Update rules to allow authenticated uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload documents
    match /documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read their own documents
    match /documents/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Missing Firebase Configuration

**Problem**: Your app doesn't have the correct Firebase configuration.

**Solution**:
1. Check if you have `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
2. Verify the configuration files are in the correct locations
3. Ensure the package name/bundle ID matches your Firebase project

### 4. Storage Bucket Doesn't Exist

**Problem**: The storage bucket referenced in your app doesn't exist.

**Solution**:
1. Check your Firebase project settings
2. Verify the storage bucket name in your configuration
3. Create the bucket manually if needed

## Implementation Fixes Applied

The code has been updated with the following improvements:

### 1. Enhanced Error Handling
- Specific error messages for different Firebase Storage errors
- Better debugging information
- User-friendly error messages

### 2. Storage Initialization
- Automatic bucket initialization
- User storage structure creation
- Collection verification

### 3. Configuration Checking
- Pre-upload Firebase service validation
- Storage accessibility verification
- Authentication state checking

### 4. User Experience
- Helpful error dialogs
- Troubleshooting guidance
- Progress feedback

## Testing Your Setup

### 1. Check Firebase Console
- Ensure Storage is enabled
- Verify security rules
- Check project configuration

### 2. Test with Simple Upload
```dart
// Test if storage is accessible
final isAccessible = await DocumentService.isStorageAvailable();
print('Storage accessible: $isAccessible');

// Check configuration
final config = await DocumentService.checkFirebaseConfiguration();
print('Configuration: $config');
```

### 3. Verify Authentication
- Ensure user is logged in
- Check Firebase Auth configuration
- Verify user permissions

## Development vs Production

### Development
- Use test mode security rules
- Enable all Firebase services
- Use development Firebase project

### Production
- Implement proper security rules
- Enable only necessary services
- Use production Firebase project
- Set up proper authentication

## Common Security Rules

### Basic Rules (Development)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Secure Rules (Production)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only access their own documents
    match /documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read access for shared documents (if needed)
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Debugging Steps

1. **Check Console Logs**: Look for Firebase initialization messages
2. **Verify Dependencies**: Ensure `firebase_storage` is in `pubspec.yaml`
3. **Test Authentication**: Verify user login state
4. **Check Network**: Ensure internet connectivity
5. **Verify Project**: Confirm you're using the correct Firebase project

## Getting Help

If the issue persists:

1. Check Firebase Console for error logs
2. Verify your Firebase project configuration
3. Test with a simple Firebase Storage example
4. Check Firebase documentation for your platform
5. Review Firebase Storage quotas and limits

## Prevention

- Always enable Firebase Storage when creating a new project
- Test storage functionality during development
- Implement proper error handling
- Use development security rules initially
- Monitor Firebase Console for issues


