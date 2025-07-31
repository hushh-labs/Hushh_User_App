import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const GetNotificationsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NotificationBloc>().add(
                const RefreshNotificationsRequested(),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  context.read<NotificationBloc>().add(
                    const MarkAllNotificationsAsReadRequested(),
                  );
                  break;
                case 'delete_all':
                  _showDeleteAllDialog();
                  break;
                case 'settings':
                  _showSettingsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Text('Delete all'),
              ),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is NotificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (state.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(
                          Icons.mark_email_unread,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${state.unreadCount} unread notification${state.unreadCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return NotificationTile(
                        notification: notification,
                        onTap: () {
                          context.read<NotificationBloc>().add(
                            MarkNotificationAsReadRequested(notification.id),
                          );
                        },
                        onDelete: () {
                          context.read<NotificationBloc>().add(
                            DeleteNotificationRequested(notification.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is NotificationFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                        const GetNotificationsRequested(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('No notifications'));
        },
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NotificationBloc>().add(
                const DeleteAllNotificationsRequested(),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    context.read<NotificationBloc>().add(
      const GetNotificationSettingsRequested(),
    );

    showDialog(
      context: context,
      builder: (context) => BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationSettingsLoaded) {
            return AlertDialog(
              title: const Text('Notification Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Chat Notifications'),
                    value: state.settings['chat'] ?? true,
                    onChanged: (value) {
                      final newSettings = Map<String, bool>.from(
                        state.settings,
                      );
                      newSettings['chat'] = value;
                      context.read<NotificationBloc>().add(
                        UpdateNotificationSettingsRequested(newSettings),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('System Notifications'),
                    value: state.settings['system'] ?? true,
                    onChanged: (value) {
                      final newSettings = Map<String, bool>.from(
                        state.settings,
                      );
                      newSettings['system'] = value;
                      context.read<NotificationBloc>().add(
                        UpdateNotificationSettingsRequested(newSettings),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Marketing Notifications'),
                    value: state.settings['marketing'] ?? false,
                    onChanged: (value) {
                      final newSettings = Map<String, bool>.from(
                        state.settings,
                      );
                      newSettings['marketing'] = value;
                      context.read<NotificationBloc>().add(
                        UpdateNotificationSettingsRequested(newSettings),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Reminder Notifications'),
                    value: state.settings['reminder'] ?? true,
                    onChanged: (value) {
                      final newSettings = Map<String, bool>.from(
                        state.settings,
                      );
                      newSettings['reminder'] = value;
                      context.read<NotificationBloc>().add(
                        UpdateNotificationSettingsRequested(newSettings),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
