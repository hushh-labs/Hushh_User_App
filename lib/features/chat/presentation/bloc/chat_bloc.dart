import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/chat_usecase.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadChatsEvent extends ChatEvent {
  const LoadChatsEvent();
}

class RefreshChatsEvent extends ChatEvent {
  const RefreshChatsEvent();
}

class LoadUsersEvent extends ChatEvent {
  const LoadUsersEvent();
}

class SearchUsersEvent extends ChatEvent {
  final String query;
  const SearchUsersEvent(this.query);

  @override
  List<Object> get props => [query];
}

class GetCurrentUserEvent extends ChatEvent {
  const GetCurrentUserEvent();
}

class SearchChatsEvent extends ChatEvent {
  final String query;

  const SearchChatsEvent(this.query);

  @override
  List<Object> get props => [query];
}

class SendMessageEvent extends ChatEvent {
  final String chatId;
  final String message;
  final bool isBot;
  final MessageType? messageType;
  final List<int>? imageData;
  final String? imageUrl;
  final String? fileName;

  const SendMessageEvent({
    required this.chatId,
    required this.message,
    this.isBot = false,
    this.messageType,
    this.imageData,
    this.imageUrl,
    this.fileName,
  });

  @override
  List<Object> get props => [
    chatId,
    message,
    isBot,
    messageType ?? MessageType.text,
    imageData ?? [],
    imageUrl ?? '',
    fileName ?? '',
  ];
}

class OpenChatEvent extends ChatEvent {
  final String chatId;

  const OpenChatEvent(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class SetTypingStatusEvent extends ChatEvent {
  final String chatId;
  final String userId;
  final bool isTyping;

  const SetTypingStatusEvent(this.chatId, this.userId, this.isTyping);

  @override
  List<Object> get props => [chatId, userId, isTyping];
}

class ListenTypingStatusEvent extends ChatEvent {
  final String chatId;
  final String otherUserId;

  const ListenTypingStatusEvent(this.chatId, this.otherUserId);

  @override
  List<Object> get props => [chatId, otherUserId];
}

class UploadFileEvent extends ChatEvent {
  final String chatId;
  final String fileType;

  const UploadFileEvent({required this.chatId, required this.fileType});

  @override
  List<Object> get props => [chatId, fileType];
}

class ClearChatEvent extends ChatEvent {
  final String chatId;
  final String userId;

  const ClearChatEvent({required this.chatId, required this.userId});

  @override
  List<Object> get props => [chatId, userId];
}

class BlockUserEvent extends ChatEvent {
  final String userId;
  final String blockedUserId;

  const BlockUserEvent({required this.userId, required this.blockedUserId});

  @override
  List<Object> get props => [userId, blockedUserId];
}

class RemoveChatFromListEvent extends ChatEvent {
  final String chatId;

  const RemoveChatFromListEvent(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class UpdateChatsEvent extends ChatEvent {
  final List<ChatItem> chats;

  const UpdateChatsEvent(this.chats);

  @override
  List<Object> get props => [chats];
}

class UpdateMessagesEvent extends ChatEvent {
  final String chatId;
  final List<ChatMessage> messages;

  const UpdateMessagesEvent(this.chatId, this.messages);

  @override
  List<Object> get props => [chatId, messages];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class BlockStatus {
  final bool isBlocked;
  final String errorMessage;
  final bool blockedByMe;

  const BlockStatus({
    required this.isBlocked,
    required this.errorMessage,
    required this.blockedByMe,
  });
}

class ChatInitialState extends ChatState {
  const ChatInitialState();
}

class ChatLoadingState extends ChatState {
  const ChatLoadingState();
}

class ChatsLoadedState extends ChatState {
  final List<ChatItem> chats;
  final List<ChatItem> filteredChats;

  const ChatsLoadedState({required this.chats, required this.filteredChats});

  @override
  List<Object> get props => [chats, filteredChats];
}

class ChatMessagesLoadedState extends ChatState {
  final String chatId;
  final List<ChatMessage> messages;
  final bool isOtherUserTyping;

  const ChatMessagesLoadedState({
    required this.chatId,
    required this.messages,
    this.isOtherUserTyping = false,
  });

  @override
  List<Object> get props => [chatId, messages, isOtherUserTyping];
}

class TypingStatusChangedState extends ChatState {
  final bool isOtherUserTyping;

  const TypingStatusChangedState(this.isOtherUserTyping);

  @override
  List<Object> get props => [isOtherUserTyping];
}

class MessageSentState extends ChatState {
  final ChatMessage message;

  const MessageSentState(this.message);

  @override
  List<Object> get props => [message];
}

class FileUploadingState extends ChatState {
  const FileUploadingState();
}

class FileUploadedState extends ChatState {
  final String fileName;
  final String analysisResult;

  const FileUploadedState({
    required this.fileName,
    required this.analysisResult,
  });

  @override
  List<Object> get props => [fileName, analysisResult];
}

class ChatClearedState extends ChatState {
  final String chatId;
  final String userId;

  const ChatClearedState({required this.chatId, required this.userId});

  @override
  List<Object> get props => [chatId, userId];
}

class UserBlockedState extends ChatState {
  final String blockedUserId;

  const UserBlockedState({required this.blockedUserId});

  @override
  List<Object> get props => [blockedUserId];
}

class ChatErrorState extends ChatState {
  final String message;

  const ChatErrorState(this.message);

  @override
  List<Object> get props => [message];
}

class UsersLoadedState extends ChatState {
  final List<ChatUserEntity> users;

  const UsersLoadedState({required this.users});

  @override
  List<Object> get props => [users];
}

class CurrentUserLoadedState extends ChatState {
  final ChatUserEntity? user;

  const CurrentUserLoadedState({this.user});

  @override
  List<Object> get props => [user ?? ''];
}

// Data Models (for UI)
class ChatItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String avatarIcon;
  final String avatarColor;
  final String? lastMessageTime;
  final bool isBot;
  final bool isUnread;
  final bool? isLastMessageSeen;

  const ChatItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatarIcon,
    required this.avatarColor,
    this.lastMessageTime,
    this.isBot = false,
    this.isUnread = false,
    this.isLastMessageSeen,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    avatarIcon,
    avatarColor,
    lastMessageTime,
    isBot,
    isUnread,
    isLastMessageSeen,
  ];

  ChatItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? avatarIcon,
    String? avatarColor,
    String? lastMessageTime,
    bool? isBot,
    bool? isUnread,
    bool? isLastMessageSeen,
  }) {
    return ChatItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarColor: avatarColor ?? this.avatarColor,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isBot: isBot ?? this.isBot,
      isUnread: isUnread ?? this.isUnread,
      isLastMessageSeen: isLastMessageSeen ?? this.isLastMessageSeen,
    );
  }
}

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final MessageType type;
  final List<int>? imageData;
  final String? imageUrl;
  final String? fileName;
  final String? fileUrl;
  final bool isSeen;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageData,
    this.imageUrl,
    this.fileName,
    this.fileUrl,
    this.isSeen = false,
  });

  @override
  List<Object?> get props => [
    id,
    text,
    isBot,
    timestamp,
    type,
    imageData,
    imageUrl,
    fileName,
    fileUrl,
    isSeen,
  ];

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isBot,
    DateTime? timestamp,
    MessageType? type,
    List<int>? imageData,
    String? imageUrl,
    String? fileName,
    String? fileUrl,
    bool? isSeen,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isBot: isBot ?? this.isBot,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      imageData: imageData ?? this.imageData,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetUserChats? getUserChats;
  final GetChatMessages? getChatMessages;
  final SendMessage? sendMessage;
  final CreateChat? createChat;
  final GetExistingChatId? getExistingChatId;
  final SetTypingStatus? setTypingStatus;
  final StreamUserChats? streamUserChats;
  final StreamChatMessages? streamChatMessages;
  final StreamTypingStatus? streamTypingStatus;
  final ChatRepository? repository;
  final GetChatById? getChatById;
  final GetUserDisplayName? getUserDisplayName;
  final GetUsers? getUsers;
  final GetCurrentUser? getCurrentUser;
  final SearchUsers? searchUsers;

  // Add cached state for users and chats
  List<ChatUserEntity> _cachedUsers = [];
  ChatUserEntity? _cachedCurrentUser;
  List<ChatItem> _cachedChats = [];

  // Public getter for cached chats
  List<ChatItem> get cachedChats => _cachedChats;

  // Factory constructor for backward compatibility
  factory ChatBloc() {
    print('BLoC: Creating ChatBloc instance');
    final repository = GetIt.instance.get<ChatRepository>();
    print('BLoC: Repository injected: ${repository != null}');
    return ChatBloc._(
      getUserChats: GetIt.instance.get<GetUserChats>(),
      getChatMessages: GetIt.instance.get<GetChatMessages>(),
      sendMessage: GetIt.instance.get<SendMessage>(),
      createChat: GetIt.instance.get<CreateChat>(),
      getExistingChatId: GetIt.instance.get<GetExistingChatId>(),
      getChatById: GetIt.instance.get<GetChatById>(),
      setTypingStatus: GetIt.instance.get<SetTypingStatus>(),
      streamUserChats: GetIt.instance.get<StreamUserChats>(),
      streamChatMessages: GetIt.instance.get<StreamChatMessages>(),
      streamTypingStatus: GetIt.instance.get<StreamTypingStatus>(),
      repository: repository,
      getUserDisplayName: GetIt.instance.get<GetUserDisplayName>(),
      getUsers: GetIt.instance.get<GetUsers>(),
      getCurrentUser: GetIt.instance.get<GetCurrentUser>(),
      searchUsers: GetIt.instance.get<SearchUsers>(),
    );
  }

  ChatBloc._({
    this.getUserChats,
    this.getChatMessages,
    this.sendMessage,
    this.createChat,
    this.getExistingChatId,
    this.getChatById,
    this.setTypingStatus,
    this.streamUserChats,
    this.streamChatMessages,
    this.streamTypingStatus,
    this.repository,
    this.getUserDisplayName,
    this.getUsers,
    this.getCurrentUser,
    this.searchUsers,
  }) : super(const ChatInitialState()) {
    print('🔍 BLoC: ChatBloc._ constructor called');
    on<LoadChatsEvent>(_onLoadChats);
    on<RefreshChatsEvent>(_onRefreshChats);
    on<SearchChatsEvent>(_onSearchChats);
    on<SendMessageEvent>(_onSendMessage);
    on<OpenChatEvent>(_onOpenChat);
    on<SetTypingStatusEvent>(_onSetTypingStatus);
    on<ListenTypingStatusEvent>(_onListenTypingStatus);
    on<UploadFileEvent>(_onUploadFile);
    on<ClearChatEvent>(_onClearChat);
    on<BlockUserEvent>(_onBlockUser);
    on<RemoveChatFromListEvent>(_onRemoveChatFromList);
    on<UpdateChatsEvent>(_onUpdateChats);
    on<UpdateMessagesEvent>(_onUpdateMessages);
    on<LoadUsersEvent>(_onLoadUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    print('🔍 BLoC: Event handlers registered');
  }

  @override
  void onEvent(ChatEvent event) {
    print('🔍 BLoC: Event received: ${event.runtimeType}');
    super.onEvent(event);
  }

  @override
  void onChange(Change<ChatState> change) {
    print(
      '🔍 BLoC: State changed from ${change.currentState.runtimeType} to ${change.nextState.runtimeType}',
    );
    super.onChange(change);
  }

  List<ChatItem> _allChats = [];
  Map<String, List<ChatMessage>> _chatMessages = {};

  void _onLoadChats(LoadChatsEvent event, Emitter<ChatState> emit) async {
    try {
      print('BLoC: Loading chats');

      // Force fresh query for debugging - always clear cache
      print('🔍 BLoC: Clearing cache and forcing fresh query');
      _cachedChats.clear();

      emit(const ChatLoadingState());

      final hushhBotChat = const ChatItem(
        id: 'hushh_bot',
        title: 'Hushh Bot',
        subtitle: 'Talk to Hushh Bot / upload bills for Insights',
        avatarIcon: 'smart_toy',
        avatarColor: '#A342FF',
        isBot: true,
        isUnread: false,
        isLastMessageSeen: null,
      );

      if (streamUserChats != null) {
        print('BLoC: Repository available, listening to chats stream');
        await emit.onEach<List<ChatEntity>>(
          streamUserChats!(),
          onData: (chatEntities) async {
            print('BLoC: Received ${chatEntities.length} chat entities');

            final regularChats = chatEntities
                .where((entity) => entity.id != 'hushh_bot')
                .map(
                  (entity) => ChatItem(
                    id: entity.id,
                    title: '', // Will be replaced by real name
                    subtitle: entity.lastText ?? 'No messages yet',
                    avatarIcon: _getAvatarIcon(entity),
                    avatarColor: _getAvatarColor(entity),
                    lastMessageTime: _formatTime(entity.lastTextTime),
                    isBot: false,
                    isUnread: entity.isUnread,
                    isLastMessageSeen: entity.isLastTextSeen,
                  ),
                )
                .toList();

            final updatedChats = <ChatItem>[hushhBotChat];
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            for (final chat in regularChats) {
              if (currentUserId == null) {
                updatedChats.add(chat);
                continue;
              }

              final participants = chat.id.split('_');
              String otherUserId = '';
              if (participants.length >= 2) {
                otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );
              }

              if (otherUserId.isNotEmpty) {
                final realName = await _getUserDisplayNameAsync(otherUserId);
                updatedChats.add(chat.copyWith(title: realName));
              } else {
                updatedChats.add(chat.copyWith(title: 'Unknown Chat'));
              }
            }

            _allChats = updatedChats;
            _cachedChats = updatedChats;
            print('🔍 BLoC: Updated cached chats: ${_cachedChats.length}');
            print(
              '🔍 BLoC: Chat IDs: ${_cachedChats.map((c) => c.id).join(', ')}',
            );

            if (!isClosed) {
              emit(
                ChatsLoadedState(
                  chats: updatedChats,
                  filteredChats: updatedChats,
                ),
              );
            }
          },
          onError: (error, stackTrace) {
            print('BLoC: Error loading chats: $error');
            _allChats = [hushhBotChat];
            if (!isClosed) {
              emit(
                ChatsLoadedState(chats: _allChats, filteredChats: _allChats),
              );
            }
          },
        );
      } else {
        print('BLoC: No repository available, using fallback');
        _allChats = [hushhBotChat];
        emit(ChatsLoadedState(chats: _allChats, filteredChats: _allChats));
      }
    } catch (e) {
      print('BLoC: Exception loading chats: $e');
      final hushhBotChat = const ChatItem(
        id: 'hushh_bot',
        title: 'Hushh Bot',
        subtitle: 'Talk to Hushh Bot / upload bills for Insights',
        avatarIcon: 'smart_toy',
        avatarColor: '#A342FF',
        isBot: true,
        isUnread: false,
        isLastMessageSeen: null,
      );
      _allChats = [hushhBotChat];
      _cachedChats = [hushhBotChat];
      emit(ChatsLoadedState(chats: _allChats, filteredChats: _allChats));
    }
  }

  void _onRefreshChats(RefreshChatsEvent event, Emitter<ChatState> emit) async {
    try {
      print('🔍 BLoC: Refreshing chats - clearing cache and forcing reload');

      // Clear cache to force fresh reload
      _cachedChats.clear();
      _allChats.clear();

      // If we're currently in ChatMessagesLoadedState, transition to loading first
      if (state is ChatMessagesLoadedState) {
        print('🔍 BLoC: Transitioning from ChatMessagesLoadedState to loading');
        emit(const ChatLoadingState());
      }

      // Force reload from database
      _onLoadChats(const LoadChatsEvent(), emit);
    } catch (e) {
      print('BLoC: Exception refreshing chats: $e');
      emit(ChatErrorState('Failed to refresh chats: ${e.toString()}'));
    }
  }

  void _onSearchChats(SearchChatsEvent event, Emitter<ChatState> emit) {
    // Use cached chats if available, otherwise use current state
    List<ChatItem> chatsToSearch = [];

    if (state is ChatsLoadedState) {
      final currentState = state as ChatsLoadedState;
      chatsToSearch = currentState.chats;
    } else if (_cachedChats.isNotEmpty) {
      chatsToSearch = _cachedChats;
    }

    if (chatsToSearch.isNotEmpty) {
      final filteredChats = event.query.isEmpty
          ? chatsToSearch
          : chatsToSearch
                .where(
                  (chat) =>
                      chat.title.toLowerCase().contains(
                        event.query.toLowerCase(),
                      ) ||
                      chat.subtitle.toLowerCase().contains(
                        event.query.toLowerCase(),
                      ),
                )
                .toList();

      emit(
        ChatsLoadedState(chats: chatsToSearch, filteredChats: filteredChats),
      );
    }
  }

  void _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    try {
      print('🔍 BLoC: _onSendMessage called');
      print('🔍 BLoC: Chat ID: ${event.chatId}');
      print('🔍 BLoC: Message text: ${event.message}');
      print('🔍 BLoC: Is bot: ${event.isBot}');

      // Check if user is blocked before sending message
      if (event.chatId != 'hushh_bot') {
        final blockStatus = await _checkBlockStatus(event.chatId);
        if (blockStatus.isBlocked) {
          print('❌ BLoC: User is blocked, cannot send message');
          emit(ChatErrorState(blockStatus.errorMessage));
          return;
        }
      }

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.message,
        isBot: event.isBot,
        timestamp: DateTime.now(),
        type: event.messageType ?? MessageType.text,
        imageData: event.imageData,
        imageUrl: event.imageUrl,
        fileName: event.fileName,
        isSeen: false,
      );

      print('🔍 BLoC: Created message with ID: ${message.id}');
      print('🔍 BLoC: Message text: "${message.text}"');

      // Add message to local state
      if (_chatMessages[event.chatId] == null) {
        _chatMessages[event.chatId] = [];
        print('🔍 BLoC: Created new message list for chat: ${event.chatId}');
      }

      print(
        '🔍 BLoC: Previous messages count: ${_chatMessages[event.chatId]!.length}',
      );
      _chatMessages[event.chatId]!.add(message);
      print(
        '🔍 BLoC: New messages count: ${_chatMessages[event.chatId]!.length}',
      );

      // Update chat list with new message
      final chatIndex = _allChats.indexWhere((chat) => chat.id == event.chatId);
      if (chatIndex != -1) {
        print('🔍 BLoC: Updating chat list with new message');
        final updatedChat = _allChats[chatIndex].copyWith(
          subtitle: event.message,
          lastMessageTime: _formatTime(DateTime.now()),
        );
        _allChats[chatIndex] = updatedChat;
      }

      // Emit updated state immediately
      print('🔍 BLoC: Emitting updated state with new message');
      print(
        '🔍 BLoC: Messages in local state: ${_chatMessages[event.chatId]!.length}',
      );
      print('🔍 BLoC: Chat ID for emission: ${event.chatId}');

      // Log each message in local state
      for (int i = 0; i < _chatMessages[event.chatId]!.length; i++) {
        final msg = _chatMessages[event.chatId]![i];
        print('🔍 BLoC: Local message $i: "${msg.text}" (ID: ${msg.id})');
      }

      final newState = ChatMessagesLoadedState(
        chatId: event.chatId,
        messages: List.from(_chatMessages[event.chatId]!),
        isOtherUserTyping: false,
      );

      print('🔍 BLoC: About to emit state with chat ID: ${newState.chatId}');
      print('🔍 BLoC: State hash: ${newState.hashCode}');

      if (!isClosed) {
        emit(newState);
      }

      print('🔍 BLoC: State emitted successfully');

      // Send message to Firebase
      final newChatId = await _sendMessageToFirebase(event.chatId, message);

      if (newChatId != event.chatId) {
        // The chat ID has changed, so we need to update our local cache
        // and re-emit the state with the new chat ID.
        final messages = _chatMessages.remove(event.chatId) ?? [message];
        _chatMessages[newChatId] = messages;

        emit(
          ChatMessagesLoadedState(
            chatId: newChatId,
            messages: messages,
            isOtherUserTyping: false,
          ),
        );
      }
    } catch (e) {
      print('❌ BLoC: Error sending message: $e');
      emit(ChatErrorState('Failed to send message: ${e.toString()}'));
    }
  }

  void _onOpenChat(OpenChatEvent event, Emitter<ChatState> emit) async {
    try {
      print('🔍 BLoC: _onOpenChat called');
      print('🔍 BLoC: Chat ID: ${event.chatId}');

      // Check if we already have messages in local state
      if (_chatMessages[event.chatId] != null &&
          _chatMessages[event.chatId]!.isNotEmpty) {
        print(
          '🔍 BLoC: Using existing local messages for chat: ${event.chatId}',
        );
        final messages = _chatMessages[event.chatId] ?? [];
        emit(
          ChatMessagesLoadedState(
            chatId: event.chatId,
            messages: messages,
            isOtherUserTyping: false,
          ),
        );
      } else {
        // Check if chat exists in database (including reversed order)
        final chatExists = await _checkIfChatExists(event.chatId);
        print('🔍 BLoC: Chat exists for ${event.chatId}: $chatExists');

        if (chatExists) {
          // Chat exists - find the correct chat ID and load existing messages
          final correctChatId = await _getCorrectChatId(event.chatId);
          print(
            '🔍 BLoC: Loading existing messages for existing chat: $correctChatId',
          );

          // Check if we already have messages in local state
          if (_chatMessages[correctChatId] != null &&
              _chatMessages[correctChatId]!.isNotEmpty) {
            print(
              '🔍 BLoC: Using existing local messages for chat: $correctChatId',
            );
            emit(
              ChatMessagesLoadedState(
                chatId: correctChatId,
                messages: _chatMessages[correctChatId]!,
                isOtherUserTyping: false,
              ),
            );
          } else {
            // Load messages from Firebase
            print(
              '🔍 BLoC: Loading messages from Firebase for chat: $correctChatId',
            );
            await _loadExistingMessages(correctChatId, emit);
          }
        } else {
          // Chat doesn't exist - show empty state immediately
          // Don't create the chat here - wait for first message
          print(
            '🔍 BLoC: Chat does not exist, showing empty state (chat will be created on first message)',
          );
          _chatMessages[event.chatId] = [];
          emit(
            ChatMessagesLoadedState(
              chatId: event.chatId,
              messages: [],
              isOtherUserTyping: false,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ BLoC: Error opening chat: $e');
      // On error, show empty state
      _chatMessages[event.chatId] = [];
      emit(
        ChatMessagesLoadedState(
          chatId: event.chatId,
          messages: [],
          isOtherUserTyping: false,
        ),
      );
    }
  }

  Future<bool> _checkIfChatExists(String chatId) async {
    try {
      print('BLoC: Checking if chat exists: $chatId');

      // First, try the original chat ID
      if (getChatById != null) {
        final result = await getChatById!(chatId);
        if (result.fold((failure) => false, (chat) => chat != null)) {
          print('BLoC: Chat found with original ID: $chatId');
          return true;
        }
      }

      // If not found, try the reverse order
      final participants = chatId.split('_');
      if (participants.length == 2) {
        final reversedChatId = '${participants[1]}_${participants[0]}';
        print('BLoC: Trying reversed chat ID: $reversedChatId');

        if (getChatById != null) {
          final reversedResult = await getChatById!(reversedChatId);
          if (reversedResult.fold((failure) => false, (chat) => chat != null)) {
            print('BLoC: Chat found with reversed ID: $reversedChatId');
            return true;
          }
        }
      }

      print('BLoC: Chat not found with either ID');
      return false;
    } catch (e) {
      print('BLoC: Error checking if chat exists: $e');
      return false;
    }
  }

  Future<void> _loadExistingMessages(
    String chatId,
    Emitter<ChatState> emit,
  ) async {
    print('🔍 BLoC: _loadExistingMessages called for chat: $chatId');
    try {
      // Load messages from Firebase
      if (repository != null) {
        print('🔍 BLoC: Repository available, listening to messages stream');

        // First, emit empty state to show the chat is ready
        _chatMessages[chatId] = [];
        emit(
          ChatMessagesLoadedState(
            chatId: chatId,
            messages: [],
            isOtherUserTyping: false,
          ),
        );

        print('🔍 BLoC: Starting stream listener for chat: $chatId');

        // Then listen to the stream for real-time updates
        final stream = repository!.getChatMessages(chatId);
        print('🔍 BLoC: Stream created for chat: $chatId');

        stream.listen(
          (messages) {
            print('🔍 BLoC: Stream received messages for chat: $chatId');
            print('🔍 BLoC: Messages count: ${messages.length}');
            print('🔍 BLoC: BLoC isClosed: $isClosed');
            print('🔍 BLoC: Stream active: true');

            // Always process messages, even if BLoC appears closed
            // The stream might still be active even if isClosed is true temporarily
            print(
              'BLoC: Received ${messages.length} message entities for chat: $chatId',
            );

            // Log each message from the stream
            for (int i = 0; i < messages.length; i++) {
              print(
                '🔍 BLoC: Stream message $i: "${messages[i].text}" (ID: ${messages[i].id})',
              );
            }

            final chatMessages = messages
                .map(
                  (messageEntity) => ChatMessage(
                    id: messageEntity.id,
                    text: messageEntity.text,
                    isBot: false,
                    timestamp: messageEntity.timestamp,
                    type: messageEntity.type,
                    isSeen: messageEntity.isSeen,
                  ),
                )
                .toList();

            print(
              'BLoC: Converted ${chatMessages.length} messages for chat: $chatId',
            );
            _chatMessages[chatId] = chatMessages;

            // Try to add the event, but don't fail if BLoC is closed
            try {
              if (!isClosed) {
                print('✅ BLoC: Adding UpdateMessagesEvent');
                add(UpdateMessagesEvent(chatId, chatMessages));
              } else {
                print(
                  '⚠️ BLoC: BLoC appears closed, but trying to add event anyway',
                );
                // Try to add the event even if isClosed is true
                // Sometimes this is a false positive
                add(UpdateMessagesEvent(chatId, chatMessages));
              }
            } catch (e) {
              print('❌ BLoC: Error adding UpdateMessagesEvent: $e');
            }
          },
          onError: (error) {
            print('❌ BLoC: Stream error for chat $chatId: $error');
            print(
              'BLoC: Error loading existing messages for chat $chatId: $error',
            );
            log('Error loading existing messages: $error');
            // Keep empty state on error
            _chatMessages[chatId] = [];
            try {
              if (!isClosed) {
                add(UpdateMessagesEvent(chatId, []));
              } else {
                add(UpdateMessagesEvent(chatId, []));
              }
            } catch (e) {
              print('❌ BLoC: Error adding UpdateMessagesEvent on error: $e');
            }
          },
          cancelOnError: false,
        );

        print('🔍 BLoC: Stream listener set up for chat: $chatId');
      } else {
        print('❌ BLoC: No repository available, using fallback for messages');
        // Fallback to empty state
        _chatMessages[chatId] = [];
        emit(
          ChatMessagesLoadedState(
            chatId: chatId,
            messages: [],
            isOtherUserTyping: false,
          ),
        );
      }
    } catch (e) {
      print('❌ BLoC: Exception loading existing messages for chat $chatId: $e');
      log('Error loading existing messages: $e');
      // Fallback to empty state
      _chatMessages[chatId] = [];
      emit(
        ChatMessagesLoadedState(
          chatId: chatId,
          messages: [],
          isOtherUserTyping: false,
        ),
      );
    }
  }

  void _onSetTypingStatus(
    SetTypingStatusEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      print('🔍 BLoC: _onSetTypingStatus called');
      print('🔍 BLoC: Chat ID: ${event.chatId}');
      print('🔍 BLoC: User ID: ${event.userId}');
      print('🔍 BLoC: Is Typing: ${event.isTyping}');
      print(
        '🔍 BLoC: Current messages in _chatMessages: ${_chatMessages[event.chatId]?.length ?? 0}',
      );

      // Use the SetTypingStatus use case instead of calling repository directly
      if (setTypingStatus != null) {
        print('🔍 BLoC: setTypingStatus use case available');
        final result = await setTypingStatus!(
          SetTypingStatusParams(
            chatId: event.chatId,
            userId: event.userId,
            isTyping: event.isTyping,
          ),
        );

        result.fold(
          (failure) {
            print('❌ BLoC: Failed to set typing status: ${failure.toString()}');
            // Don't emit any state on failure - just log it
          },
          (_) {
            print('✅ BLoC: Typing status updated successfully');
            print(
              '🔍 BLoC: Current messages after typing status: ${_chatMessages[event.chatId]?.length ?? 0}',
            );
            // Don't emit state for local typing status - only for remote typing status
          },
        );
      } else {
        print('❌ BLoC: No setTypingStatus use case available');
      }
    } catch (e) {
      print('❌ BLoC: Error setting typing status: $e');
      // Don't emit any state on error - just log it
    }
  }

  void _onListenTypingStatus(
    ListenTypingStatusEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      print('🔍 BLoC: _onListenTypingStatus called');
      print('🔍 BLoC: Chat ID: ${event.chatId}');
      print('🔍 BLoC: Other User ID: ${event.otherUserId}');
      print(
        '🔍 BLoC: Current messages in _chatMessages: ${_chatMessages[event.chatId]?.length ?? 0}',
      );

      if (streamTypingStatus != null) {
        print('🔍 BLoC: streamTypingStatus available');
        bool lastTypingStatus = false; // Track the last typing status
        List<ChatMessage> lastMessages = []; // Track the last messages

        await emit.onEach<bool>(
          streamTypingStatus!(event.chatId, event.otherUserId),
          onData: (isTyping) {
            print('🔍 BLoC: Stream received typing status: $isTyping');

            // Check if BLoC is still active before processing
            if (isClosed) {
              print('❌ BLoC: Skipping typing status update - BLoC is closed');
              return;
            }

            // Get current messages for this chat
            final currentMessages = _chatMessages[event.chatId] ?? [];
            print('🔍 BLoC: Current messages count: ${currentMessages.length}');
            print('🔍 BLoC: Last messages count: ${lastMessages.length}');
            print('🔍 BLoC: Last typing status: $lastTypingStatus');
            print('🔍 BLoC: New typing status: $isTyping');

            // Only emit if typing status or messages actually changed
            if (isTyping != lastTypingStatus ||
                !_areMessagesEqual(currentMessages, lastMessages)) {
              print('🔄 BLoC: State changed - emitting new state');
              print('🔄 BLoC: Typing: $lastTypingStatus -> $isTyping');
              print(
                '🔄 BLoC: Messages: ${lastMessages.length} -> ${currentMessages.length}',
              );

              lastTypingStatus = isTyping;
              lastMessages = List.from(currentMessages);

              // Emit combined state with messages and typing status
              emit(
                ChatMessagesLoadedState(
                  chatId: event.chatId,
                  messages: currentMessages,
                  isOtherUserTyping: isTyping,
                ),
              );
              print('✅ BLoC: State emitted successfully');
            } else {
              print('⏭️ BLoC: No state change - skipping emission');
            }
          },
        );
      } else {
        print('❌ BLoC: streamTypingStatus not available');
      }
    } catch (e) {
      print('❌ BLoC: Error in _onListenTypingStatus: $e');
      if (!isClosed) {
        emit(ChatErrorState('Failed to listen typing status: ${e.toString()}'));
      }
    }
  }

  // Helper method to compare messages efficiently
  bool _areMessagesEqual(
    List<ChatMessage> messages1,
    List<ChatMessage> messages2,
  ) {
    if (messages1.length != messages2.length) return false;

    for (int i = 0; i < messages1.length; i++) {
      if (messages1[i].id != messages2[i].id) return false;
    }
    return true;
  }

  void _onUploadFile(UploadFileEvent event, Emitter<ChatState> emit) async {
    emit(const FileUploadingState());

    try {
      // TODO: Implement actual file upload logic
      await Future.delayed(const Duration(seconds: 2));

      const analysisResult =
          'Analysis complete! Here are some insights:\n\n• Total amount: \$125.50\n• Category: Utilities\n• Compared to last month: +15%\n• Tip: Consider energy-saving options to reduce costs.';

      // Add upload confirmation message
      final uploadMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'File uploaded successfully! I\'m analyzing your bill...',
        isBot: true,
        timestamp: DateTime.now(),
      );

      _chatMessages[event.chatId] = [
        ...(_chatMessages[event.chatId] ?? []),
        uploadMessage,
      ];

      emit(
        ChatMessagesLoadedState(
          chatId: event.chatId,
          messages: _chatMessages[event.chatId]!,
        ),
      );

      // Add analysis result after delay
      await Future.delayed(const Duration(seconds: 1));

      final analysisMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: analysisResult,
        isBot: true,
        timestamp: DateTime.now(),
      );

      _chatMessages[event.chatId] = [
        ...(_chatMessages[event.chatId] ?? []),
        analysisMessage,
      ];

      emit(
        ChatMessagesLoadedState(
          chatId: event.chatId,
          messages: _chatMessages[event.chatId]!,
        ),
      );
    } catch (e) {
      emit(ChatErrorState('Failed to upload file: ${e.toString()}'));
    }
  }

  void _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) async {
    try {
      // Clear messages locally
      _chatMessages[event.chatId] = [];

      // Update the chat item to show it's been cleared
      final chatIndex = _allChats.indexWhere((chat) => chat.id == event.chatId);
      if (chatIndex != -1) {
        final chat = _allChats[chatIndex];
        _allChats[chatIndex] = ChatItem(
          id: chat.id,
          title: chat.title,
          subtitle: 'Chat cleared',
          avatarIcon: chat.avatarIcon,
          avatarColor: chat.avatarColor,
          isBot: chat.isBot,
          isUnread: false,
          isLastMessageSeen: null,
        );
      }

      // TODO: In real implementation, this would update Firebase
      // to mark messages as deleted for this user
      // await repository.setChatDeletionFlag(event.chatId, event.userId, messages.length);

      emit(ChatClearedState(chatId: event.chatId, userId: event.userId));

      // Also emit updated chat list
      _cachedChats = _allChats;
      emit(ChatsLoadedState(chats: _allChats, filteredChats: _allChats));
    } catch (e) {
      emit(ChatErrorState('Failed to clear chat: ${e.toString()}'));
    }
  }

  void _onBlockUser(BlockUserEvent event, Emitter<ChatState> emit) async {
    try {
      // TODO: In real implementation, this would update Firebase
      // to mark user as blocked

      emit(UserBlockedState(blockedUserId: event.blockedUserId));
    } catch (e) {
      emit(ChatErrorState('Failed to block user: ${e.toString()}'));
    }
  }

  void _onRemoveChatFromList(
    RemoveChatFromListEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      _allChats.removeWhere((chat) => chat.id == event.chatId);
      _allChats.sort((a, b) {
        // Always keep Hushh Bot at the top
        if (a.id == 'hushh_bot') return -1;
        if (b.id == 'hushh_bot') return 1;

        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;

        final timeA = _parseTimeString(a.lastMessageTime!);
        final timeB = _parseTimeString(b.lastMessageTime!);
        return timeB.compareTo(timeA);
      });

      _cachedChats = _allChats;
      emit(ChatsLoadedState(chats: _allChats, filteredChats: _allChats));
    } catch (e) {
      emit(ChatErrorState('Failed to remove chat from list: ${e.toString()}'));
    }
  }

  void _onUpdateChats(UpdateChatsEvent event, Emitter<ChatState> emit) {
    print('🔍 BLoC: _onUpdateChats called');
    print('🔍 BLoC: Chats count: ${event.chats.length}');
    print('🔍 BLoC: Current state type: ${state.runtimeType}');

    _allChats = event.chats;
    _cachedChats = event.chats;

    // Always emit ChatsLoadedState when we have updated chats
    // This ensures the chat list is updated even when returning from a conversation
    print('🔍 BLoC: Emitting ChatsLoadedState');
    emit(ChatsLoadedState(chats: _allChats, filteredChats: _allChats));
  }

  void _onUpdateMessages(UpdateMessagesEvent event, Emitter<ChatState> emit) {
    print('🔍 BLoC: _onUpdateMessages called');
    print('🔍 BLoC: Chat ID: ${event.chatId}');
    print('🔍 BLoC: Messages count: ${event.messages.length}');
    print(
      '🔍 BLoC: Previous messages count: ${_chatMessages[event.chatId]?.length ?? 0}',
    );

    _chatMessages[event.chatId] = event.messages;
    print('🔍 BLoC: Messages updated in _chatMessages');
    print(
      '🔍 BLoC: New messages count: ${_chatMessages[event.chatId]?.length ?? 0}',
    );

    // Log each message for debugging
    for (int i = 0; i < event.messages.length; i++) {
      print(
        '🔍 BLoC: Message $i: "${event.messages[i].text}" (ID: ${event.messages[i].id})',
      );
    }

    emit(
      ChatMessagesLoadedState(
        chatId: event.chatId,
        messages: event.messages,
        isOtherUserTyping: false,
      ),
    );
    print('✅ BLoC: ChatMessagesLoadedState emitted');
  }

  // Helper method to parse time strings for sorting
  DateTime _parseTimeString(String timeString) {
    // Simple parsing for demo purposes
    // In real app, you'd want more robust time parsing
    final now = DateTime.now();
    final parts = timeString.split(' ');
    if (parts.length == 2) {
      final time = parts[0];
      final period = parts[1];
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        int hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    }
    return now;
  }

  String _getBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! How can I assist you today?';
    } else if (message.contains('bill') || message.contains('upload')) {
      return 'Great! You can upload your bills and I\'ll provide insights. Just tap the attachment icon and select your file.';
    } else if (message.contains('help')) {
      return 'I can help you with:\n• Analyzing bills and expenses\n• Providing financial insights\n• Answering questions about your account\n• General assistance';
    } else {
      return 'Thanks for your message! I\'m here to help with bills analysis and insights. Feel free to upload any bills or ask me questions.';
    }
  }

  // Async method to get user display name for updating chat titles
  Future<String> _getUserDisplayNameAsync(String userId) async {
    print('🔍 BLoC: Getting display name for user: $userId');
    if (getUserDisplayName != null) {
      try {
        final result = await getUserDisplayName!(userId);
        return result.fold(
          (failure) {
            print('🔍 BLoC: Failed to get user name: $failure');
            // Fallback to shortened user ID on error
            if (userId.length > 8) {
              return 'User ${userId.substring(0, 8)}...';
            }
            return 'User $userId';
          },
          (userName) {
            print('🔍 BLoC: Got user name: $userName');
            return userName;
          },
        );
      } catch (e) {
        print('🔍 BLoC: Exception getting user name: $e');
        // Fallback to shortened user ID on exception
        if (userId.length > 8) {
          return 'User ${userId.substring(0, 8)}...';
        }
        return 'User $userId';
      }
    } else {
      print('🔍 BLoC: getUserDisplayName use case not available');
      // Fallback if use case is not available
      if (userId.length > 8) {
        return 'User ${userId.substring(0, 8)}...';
      }
      return 'User $userId';
    }
  }

  String _getAvatarIcon(ChatEntity entity) {
    if (entity.id == 'hushh_bot') return 'smart_toy';
    return 'person';
  }

  String _getAvatarColor(ChatEntity entity) {
    if (entity.id == 'hushh_bot') return '#A342FF';

    // Generate color based on participant ID
    final colors = ['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336'];
    final index = entity.participants.isNotEmpty
        ? entity.participants[1].hashCode % colors.length
        : 0;
    return colors[index];
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<BlockStatus> _checkBlockStatus(String chatId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Extract other user ID from chat ID (assuming format: user1_user2)
      final participants = chatId.split('_');
      String otherUserId = '';

      if (participants.length >= 2) {
        if (participants[0] == currentUserId) {
          otherUserId = participants[1];
        } else if (participants[1] == currentUserId) {
          otherUserId = participants[0];
        }
      }

      if (otherUserId.isNotEmpty && repository != null) {
        // Check if current user is blocked by other user
        final isBlockedByOtherResult = await repository!.isUserBlocked(
          otherUserId,
          currentUserId,
        );
        final isBlockedByOther = isBlockedByOtherResult.fold(
          (failure) => false,
          (isBlocked) => isBlocked,
        );

        if (isBlockedByOther) {
          return BlockStatus(
            isBlocked: true,
            errorMessage: 'You have been blocked by this user.',
            blockedByMe: false,
          );
        }

        // Check if current user has blocked other user
        final hasBlockedOtherResult = await repository!.isUserBlocked(
          currentUserId,
          otherUserId,
        );
        final hasBlockedOther = hasBlockedOtherResult.fold(
          (failure) => false,
          (isBlocked) => isBlocked,
        );

        if (hasBlockedOther) {
          return BlockStatus(
            isBlocked: true,
            errorMessage:
                'You have blocked this user. Unblock to send messages.',
            blockedByMe: true,
          );
        }
      }

      return BlockStatus(
        isBlocked: false,
        errorMessage: '',
        blockedByMe: false,
      );
    } catch (e) {
      log('Error checking block status: $e');
      return BlockStatus(
        isBlocked: false,
        errorMessage: '',
        blockedByMe: false,
      );
    }
  }

  Future<String> _sendMessageToFirebase(
    String chatId,
    ChatMessage message,
  ) async {
    try {
      print('🔍 BLoC: _sendMessageToFirebase called');
      print('🔍 BLoC: Chat ID: $chatId');
      print('🔍 BLoC: Message text: ${message.text}');
      print('🔍 BLoC: Message ID: ${message.id}');

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      print('🔍 BLoC: Current user ID: $currentUserId');

      final messageEntity = MessageEntity(
        id: message.id,
        text: message.text,
        senderId: currentUserId,
        timestamp: message.timestamp,
        type: message.type,
        isSeen: false,
      );

      print('🔍 BLoC: Created message entity');

      // Check if chat exists in database
      final chatExists = await _checkIfChatExists(chatId);
      print('🔍 BLoC: Chat exists: $chatExists');

      String finalChatId = chatId;

      if (!chatExists) {
        // Chat doesn't exist - create it first with all proper fields
        print('🔍 BLoC: Creating chat in database with all fields');
        final otherUserId = _getOtherUserId(chatId, currentUserId);
        final participantIds = [currentUserId, otherUserId]..sort();

        // Use the CreateChat use case instead of calling repository directly
        if (createChat != null) {
          final result = await createChat!(participantIds);
          finalChatId = result.fold(
            (failure) {
              print('❌ BLoC: Failed to create chat: ${failure.toString()}');
              return chatId;
            },
            (newChatId) {
              print('✅ BLoC: Chat created in database: $newChatId');
              return newChatId;
            },
          );
        } else {
          print('❌ BLoC: No createChat use case available');
        }
      }

      // Send message to database using the SendMessage use case
      print('🔍 BLoC: Sending message to database');
      if (sendMessage != null) {
        final result = await sendMessage!(
          SendMessageParams(
            chatId: finalChatId,
            text: messageEntity.text,
            type: messageEntity.type,
          ),
        );
        result.fold(
          (failure) {
            print('❌ BLoC: Failed to send message: ${failure.toString()}');
          },
          (_) {
            print('✅ BLoC: Message sent to database: ${message.text}');
          },
        );
      } else {
        print('❌ BLoC: No sendMessage use case available');
      }
      return finalChatId;
    } catch (e) {
      print('❌ BLoC: Error sending message to Firebase: $e');
      log('Error sending message to Firebase: $e');
      return chatId;
      // Don't throw here to avoid breaking the UI
    }
  }

  String _getOtherUserId(String chatId, String currentUserId) {
    if (chatId.startsWith('temp_chat_')) {
      return chatId.substring('temp_chat_'.length);
    }
    final participants = chatId.split('_');
    if (participants.length < 2) return '';
    return participants[0] == currentUserId ? participants[1] : participants[0];
  }

  Future<String> _getCorrectChatId(String requestedChatId) async {
    try {
      // First, try the original chat ID
      final result = await repository?.getChatById(requestedChatId);
      if (result?.fold((failure) => false, (chat) => true) ?? false) {
        return requestedChatId;
      }

      // If not found, try the reverse order
      final participants = requestedChatId.split('_');
      if (participants.length == 2) {
        final reversedChatId = '${participants[1]}_${participants[0]}';
        final reversedResult = await repository?.getChatById(reversedChatId);
        if (reversedResult?.fold((failure) => false, (chat) => true) ?? false) {
          return reversedChatId;
        }
      }

      // If neither exists, return the original (for new chat creation)
      return requestedChatId;
    } catch (e) {
      print('BLoC: Error getting correct chat ID: $e');
      return requestedChatId;
    }
  }

  void _onLoadUsers(LoadUsersEvent event, Emitter<ChatState> emit) async {
    try {
      // If we have cached users and we're not in a loading state, return cached data
      if (_cachedUsers.isNotEmpty && state is! ChatLoadingState) {
        emit(UsersLoadedState(users: _cachedUsers));
        return;
      }

      if (getUsers != null) {
        final result = await getUsers!(const NoParams());
        result.fold((failure) => emit(ChatErrorState(failure.toString())), (
          users,
        ) {
          _cachedUsers = users;
          emit(UsersLoadedState(users: users));
        });
      }
    } catch (e) {
      emit(ChatErrorState(e.toString()));
    }
  }

  void _onSearchUsers(SearchUsersEvent event, Emitter<ChatState> emit) async {
    try {
      if (searchUsers != null) {
        final result = await searchUsers!(event.query);
        result.fold((failure) => emit(ChatErrorState(failure.toString())), (
          users,
        ) {
          // Don't cache search results, but use them for display
          emit(UsersLoadedState(users: users));
        });
      }
    } catch (e) {
      emit(ChatErrorState(e.toString()));
    }
  }

  void _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // If we have cached current user, return it
      if (_cachedCurrentUser != null && state is! ChatLoadingState) {
        emit(CurrentUserLoadedState(user: _cachedCurrentUser));
        return;
      }

      if (getCurrentUser != null) {
        final result = await getCurrentUser!(const NoParams());
        result.fold((failure) => emit(ChatErrorState(failure.toString())), (
          user,
        ) {
          _cachedCurrentUser = user;
          emit(CurrentUserLoadedState(user: user));
        });
      }
    } catch (e) {
      emit(ChatErrorState(e.toString()));
    }
  }
}
