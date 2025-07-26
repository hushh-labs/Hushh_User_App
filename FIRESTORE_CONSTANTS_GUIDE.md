# Firestore Constants Guide

This guide explains how to properly organize and use Firestore collections, subcollections, and field names in your Clean Architecture Flutter app.

## 📍 Location

**Firestore constants are stored in**: `lib/shared/constants/firestore_constants.dart`

This is the **root-level shared location** for maximum reusability across all features.

## 🏗️ Structure

### **1. Collections** (`FirestoreCollections`)
```dart
// Main collections
static const String users = 'users';
static const String posts = 'posts';
static const String comments = 'comments';
static const String messages = 'messages';

// Subcollections
static const String userPosts = 'posts';
static const String postComments = 'comments';
static const String chatMessages = 'messages';
```

### **2. Fields** (`FirestoreFields`)
```dart
// Common fields
static const String id = 'id';
static const String userId = 'userId';
static const String createdAt = 'createdAt';
static const String updatedAt = 'updatedAt';

// Specific fields (prefixed to avoid conflicts)
static const String postTitle = 'title';
static const String commentLikeCount = 'likeCount';
static const String messageIsRead = 'isRead';
```

### **3. Indexes** (`FirestoreIndexes`)
```dart
// Query indexes
static const String usersByEmail = 'users_by_email';
static const String postsByUserId = 'posts_by_user_id';
static const String commentsByPostId = 'comments_by_post_id';
```

### **4. Security Rules** (`FirestoreSecurity`)
```dart
// Permission constants
static const String userCanReadOwnData = 'request.auth != null && request.auth.uid == resource.data.userId';
static const String userCanWriteOwnPosts = 'request.auth != null && request.auth.uid == resource.data.userId';
```

### **5. Limits** (`FirestoreLimits`, `FirestoreBatch`)
```dart
// Query limits
static const int maxQueryResults = 1000;
static const int defaultPageSize = 20;

// Batch limits
static const int maxBatchSize = 500;
static const int maxWriteOperations = 500;
```

## 🚀 Usage Examples

### **1. In Data Sources**
```dart
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<UserModel> getUser(String id) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    throw Exception('User not found');
  }
  
  @override
  Future<List<UserModel>> getUsers() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.isActive, isEqualTo: true)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .limit(FirestoreLimits.defaultPageSize)
        .get();
    
    return querySnapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }
}
```

### **2. In Models**
```dart
class UserModel extends BaseModel<UserEntity> {
  final String email;
  final String name;
  final String? photoUrl;
  
  const UserModel({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    required this.email,
    required this.name,
    this.photoUrl,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json[FirestoreFields.id],
      email: json[FirestoreFields.email],
      name: json[FirestoreFields.name],
      photoUrl: json[FirestoreFields.photoUrl],
      createdAt: DateTime.parse(json[FirestoreFields.createdAt]),
      updatedAt: json[FirestoreFields.updatedAt] != null 
        ? DateTime.parse(json[FirestoreFields.updatedAt]) 
        : null,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      FirestoreFields.id: id,
      FirestoreFields.email: email,
      FirestoreFields.name: name,
      FirestoreFields.photoUrl: photoUrl,
      FirestoreFields.createdAt: createdAt.toIso8601String(),
      FirestoreFields.updatedAt: updatedAt?.toIso8601String(),
    };
  }
}
```

### **3. In Subcollections**
```dart
class PostRepositoryImpl implements PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<List<CommentModel>> getPostComments(String postId) async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.posts)
        .doc(postId)
        .collection(FirestoreCollections.postComments)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .limit(FirestoreLimits.defaultPageSize)
        .get();
    
    return querySnapshot.docs
        .map((doc) => CommentModel.fromJson(doc.data()))
        .toList();
  }
  
  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    await _firestore
        .collection(FirestoreCollections.posts)
        .doc(postId)
        .collection(FirestoreCollections.postComments)
        .add(comment.toJson());
  }
}
```

### **4. In Batch Operations**
```dart
class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> createUserWithPosts(UserModel user, List<PostModel> posts) async {
    final batch = _firestore.batch();
    
    // Add user document
    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(user.id);
    batch.set(userRef, user.toJson());
    
    // Add posts to user's subcollection
    for (final post in posts) {
      final postRef = userRef
          .collection(FirestoreCollections.userPosts)
          .doc(post.id);
      batch.set(postRef, post.toJson());
    }
    
    await batch.commit();
  }
}
```

### **5. In Security Rules**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Subcollections
      match /posts/{postId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Public posts
    match /posts/{postId} {
      allow read: if resource.data.isPublic == true;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

## 🎯 Best Practices

### **1. Naming Conventions**
- **Collections**: Use plural nouns (`users`, `posts`, `comments`)
- **Subcollections**: Use descriptive names (`userPosts`, `postComments`)
- **Fields**: Use camelCase (`userId`, `createdAt`, `isActive`)
- **Indexes**: Use descriptive names (`users_by_email`, `posts_by_user_id`)

### **2. Field Organization**
- **Common fields**: `id`, `userId`, `createdAt`, `updatedAt`
- **Specific fields**: Prefix with context (`postTitle`, `commentLikeCount`)
- **Boolean fields**: Use `is` prefix (`isActive`, `isPublic`, `isRead`)

### **3. Query Optimization**
- **Use indexes**: Create composite indexes for complex queries
- **Limit results**: Use `FirestoreLimits.defaultPageSize`
- **Order efficiently**: Order by indexed fields
- **Filter early**: Apply filters before ordering

### **4. Security Rules**
- **Use constants**: Reference `FirestoreSecurity` constants
- **Validate data**: Check field types and values
- **Limit access**: Grant minimum required permissions
- **Test rules**: Use Firebase Emulator for testing

### **5. Performance**
- **Batch operations**: Use batch writes for multiple operations
- **Pagination**: Implement cursor-based pagination
- **Caching**: Use offline persistence for better UX
- **Indexing**: Create indexes for frequently queried fields

## 📊 Benefits

### **1. Consistency**
- All features use the same collection names
- Consistent field naming across the app
- Standardized query patterns

### **2. Maintainability**
- Single source of truth for Firestore structure
- Easy to update collection names
- Clear documentation of data structure

### **3. Scalability**
- Easy to add new collections and fields
- Structured approach to subcollections
- Organized index management

### **4. Team Collaboration**
- Clear naming conventions
- Shared understanding of data structure
- Easy onboarding for new developers

## 🔄 Migration Strategy

### **1. Adding New Collections**
```dart
// In FirestoreCollections
static const String newFeature = 'new_feature';
static const String newFeatureSubcollection = 'subcollection';
```

### **2. Adding New Fields**
```dart
// In FirestoreFields
static const String newField = 'newField';
static const String newFeatureField = 'newFeatureField';
```

### **3. Updating Existing Code**
```dart
// Old way
.collection('users')

// New way
.collection(FirestoreCollections.users)
```

This structure provides a **scalable and maintainable** approach to managing Firestore collections and fields across your entire application! 🚀 