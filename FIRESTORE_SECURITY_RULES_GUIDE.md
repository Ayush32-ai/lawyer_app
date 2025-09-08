# Firestore Security Rules Guide

## Current Issue: Permission Denied

Your app is getting this error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

This means your Firestore security rules are too restrictive.

## 🔧 **Quick Fix (Development)**

Go to [Firebase Console](https://console.firebase.google.com/) → Your Project → Firestore Database → Rules and update to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to subcollections
      match /{subcollection}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Allow authenticated users to read/write documents
    match /documents/{documentId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write lawyers
    match /lawyers/{lawyerId} {
      allow read: if true; // Public read access
      allow write: if request.auth != null;
    }
    
    // Test collection for debugging
    match /_test/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🔒 **Production Security Rules**

For production, use more restrictive rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Subcollections (documents, locations, etc.)
      match /{subcollection}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Documents collection - users can only access their own
    match /documents/{documentId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Lawyers - public read, authenticated write
    match /lawyers/{lawyerId} {
      allow read: if true;
      allow write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.admin == true);
    }
    
    // Public collections
    match /public/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🧪 **Testing Rules**

### 1. **Test Mode (Development Only)**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **WARNING**: Only use this for development! It allows anyone to read/write your data.

### 2. **Authenticated Users Only**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📱 **App-Specific Rules**

Based on your lawyer app structure:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles and data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's documents
      match /documents/{documentId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's locations
      match /locations/{locationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Global documents collection
    match /documents/{documentId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Lawyers - public read, owner write
    match /lawyers/{lawyerId} {
      allow read: if true;
      allow write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Public data
    match /public/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🔍 **Debugging Rules**

### 1. **Check Current Rules**
- Go to Firebase Console → Firestore → Rules
- Review your current rules

### 2. **Test Rules in Console**
- Use the Firebase Console Rules Playground
- Test read/write operations with different user states

### 3. **Common Issues**
- **Missing authentication check**: `request.auth != null`
- **Wrong user ID comparison**: `request.auth.uid == userId`
- **Missing subcollection rules**: Need to explicitly allow subcollection access

## 🚀 **Implementation Steps**

### **Step 1: Update Rules (Development)**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `lawyer-app-a9af7`
3. Click "Firestore Database" in left sidebar
4. Click "Rules" tab
5. Replace rules with the development version above
6. Click "Publish"

### **Step 2: Test Your App**
1. Restart your app
2. Try uploading a document
3. Check console logs for any remaining errors

### **Step 3: Production Rules (Later)**
1. Once everything works, update to production rules
2. Test thoroughly before deploying

## 📋 **Rule Structure Explanation**

```javascript
match /users/{userId} {
  // This matches documents like: /users/abc123
  allow read, write: if request.auth != null && request.auth.uid == userId;
  
  match /{subcollection}/{document=**} {
    // This matches subcollections like: /users/abc123/documents/doc1
    // The ** means "any number of path segments"
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

## ⚠️ **Important Notes**

1. **Always test rules** before deploying to production
2. **Start with permissive rules** for development
3. **Gradually restrict** as you build your app
4. **Monitor usage** to ensure rules work as expected
5. **Backup your rules** before making changes

## 🆘 **Need Help?**

If you're still having issues:

1. Check the Firebase Console for error logs
2. Verify your user is properly authenticated
3. Test rules in the Firebase Console Rules Playground
4. Check that your app is using the correct Firebase project


