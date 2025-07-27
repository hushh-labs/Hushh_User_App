import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:go_router/go_router.dart';
import 'video_recording_page.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/user_card.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/core/utils/toast_manager.dart';

class NameInputPage extends StatefulWidget {
  final String? email;
  final String? phoneNumber;

  const NameInputPage({super.key, this.email, this.phoneNumber});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createUserCard() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final userCard = UserCard(
      id: currentUser.uid,
      userId: currentUser.uid,
      email: widget.email,
      fullName: _nameController.text.trim(),
      videoUrl: null, // Will be set later in video recording
    );

    context.read<AuthBloc>().add(CreateUserCardEvent(userCard));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UserCardCreatedState) {
          // Navigate to video recording page
          context.go(RoutePaths.videoRecording);
        } else if (state is UserCardCreationFailureState) {
          ToastManager(
            Toast(
              title: 'Card Creation Failed',
              description: 'Failed to create card: ${state.message}',
              type: ToastType.error,
              duration: const Duration(seconds: 4),
            ),
          ).show(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD8DADC)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_sharp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What\'s your name?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Please enter your full name as it appears on your ID.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),
                const Spacer(),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return InkWell(
                      onTap: state is CreatingUserCardState
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _createUserCard();
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0XFFA342FF), Color(0XFFE54D60)],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: state is CreatingUserCardState
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    color: Color(0xffFFFFFF),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
