import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import 'notifications_page.dart';

class NotificationIntegrationExample extends StatefulWidget {
  const NotificationIntegrationExample({super.key});

  @override
  State<NotificationIntegrationExample> createState() =>
      _NotificationIntegrationExampleState();
}

class _NotificationIntegrationExampleState
    extends State<NotificationIntegrationExample> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(
        const InitializeNotificationsRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Integration Example'),
        actions: [
          // Notification badge in app bar
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is UnreadCountLoaded && state.unreadCount > 0) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${state.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Notifications Feature Integration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This example shows how to integrate the notifications feature into your app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
              child: const Text('Open Notifications'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Get unread count
                context.read<NotificationBloc>().add(
                  const GetUnreadCountRequested(),
                );
              },
              child: const Text('Check Unread Count'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Show notification settings
                context.read<NotificationBloc>().add(
                  const GetNotificationSettingsRequested(),
                );
              },
              child: const Text('Notification Settings'),
            ),
            const SizedBox(height: 30),
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is UnreadCountLoaded) {
                  return Text(
                    'Unread notifications: ${state.unreadCount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Example of how to add the notification bloc to your app
class AppWithNotifications extends StatelessWidget {
  const AppWithNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App with Notifications',
      home: BlocProvider(
        create: (context) => NotificationBloc(
          getNotificationsUseCase: context.read(),
          markNotificationAsReadUseCase: context.read(),
          getUnreadCountUseCase: context.read(),
          initializeNotificationsUseCase: context.read(),
          notificationRepository: context.read(),
        ),
        child: const NotificationIntegrationExample(),
      ),
    );
  }
}

// Example of how to show a local notification
class LocalNotificationExample extends StatelessWidget {
  const LocalNotificationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Notification Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // This would typically be done through the notification service
                // For demonstration purposes, we'll show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local notification would be shown here'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Show Local Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // This would typically be done through the notification service
                // For demonstration purposes, we'll show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scheduled notification would be set here'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Schedule Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
