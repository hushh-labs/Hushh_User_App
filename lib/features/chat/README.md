# Chat Feature

This directory contains the chat functionality for the Hushh User App.

## Features Implemented

### 1. Chat Navigation
- Added chat icon to the bottom navigation bar
- Chat is restricted for guest users (requires authentication)
- Uses the existing chat icon asset (`assets/chat_bottom_bar_icon.svg`)

### 2. Chat List Page
- Displays all user's chat conversations
- Shows last message and timestamp
- Empty state with call-to-action
- Floating action button to start new chat
- Real-time updates using Firebase Firestore

### 3. Chat Conversation Page
- Real-time message display
- Message input with send functionality
- Message bubbles with different colors for sender/receiver
- Timestamp display for messages
- Auto-scroll to bottom on new messages
- Loading states and error handling

### 4. Data Models
- `ChatModel`: Represents a chat conversation
- `MessageModel`: Represents individual messages

### 5. Architecture
- Clean Architecture with BLoC pattern
- Dependency injection using GetIt
- Firebase Firestore for real-time data
- Proper error handling and loading states

## File Structure

```
chat/
├── data/
│   ├── datasources/
│   │   └── chat_datasource.dart
│   └── models/
│       └── chat_model.dart
├── di/
│   └── chat_module.dart
├── presentation/
│   ├── bloc/
│   │   └── chat_bloc.dart
│   ├── pages/
│   │   ├── chat_page.dart
│   │   ├── chat_page_wrapper.dart
│   │   └── chat_list_page.dart
│   └── widgets/
│       └── chat_test_widget.dart
└── README.md
```

## Firebase Structure

### Chats Collection
```json
{
  "id": "chat_id",
  "participants": ["user_id_1", "user_id_2"],
  "lastMessage": "Last message text",
  "lastMessageTime": "timestamp",
  "createdAt": "timestamp"
}
```

### Messages Subcollection
```json
{
  "id": "message_id",
  "text": "Message text",
  "senderId": "user_id",
  "timestamp": "timestamp",
  "isRead": false
}
```

## Usage

### Adding Chat to Navigation
The chat feature is already integrated into the main app navigation. Users can access it through the bottom navigation bar.

### Testing
Use the `ChatTestWidget` to create test data:
1. Create a test chat
2. Add test messages
3. Verify the chat functionality

### Guest Mode
Chat is restricted for guest users. They will see a locked UI with an option to sign in.

## Future Enhancements

1. **User Search**: Implement user search to start new chats
2. **Push Notifications**: Add push notifications for new messages
3. **Message Status**: Show read receipts and typing indicators
4. **Media Messages**: Support for images, videos, and files
5. **Group Chats**: Support for group conversations
6. **Message Reactions**: Add emoji reactions to messages
7. **Message Search**: Search within conversations
8. **Chat Settings**: Mute, archive, and delete conversations

## Dependencies

- `flutter_bloc`: State management
- `cloud_firestore`: Real-time database
- `firebase_auth`: User authentication
- `equatable`: Value equality for BLoC
- `get_it`: Dependency injection 