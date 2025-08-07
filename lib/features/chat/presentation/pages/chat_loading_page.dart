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
    context.read<chat.ChatBloc>().add(const chat.LoadChatsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<chat.ChatBloc, chat.ChatState>(
      listener: (context, state) {
        if (state is chat.ChatsLoadedState) {
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (state is chat.ChatErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading chats: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: const ChatLoadingAnimation(onAnimationComplete: null),
    );
  }
}
