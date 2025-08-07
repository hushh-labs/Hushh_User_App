import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../components/chat_loading_animation.dart';
import '../bloc/chat_bloc.dart' as chat;

class ChatLoadingPage extends StatefulWidget {
  const ChatLoadingPage({super.key});

  @override
  State<ChatLoadingPage> createState() => _ChatLoadingPageState();
}

class _ChatLoadingPageState extends State<ChatLoadingPage> {
  @override
  void initState() {
    super.initState();
    // Trigger chat loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<chat.ChatBloc>().add(const chat.LoadChatsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<chat.ChatBloc, chat.ChatState>(
      listener: (context, state) {
        if (state is chat.ChatsLoadedState) {
          // Navigate to main chat page when data is loaded
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (state is chat.ChatErrorState) {
          // Handle error state
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading chats: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          // Navigate back or to error page
          Navigator.pop(context);
        }
      },
      child: const ChatLoadingAnimation(onAnimationComplete: null),
    );
  }
}
