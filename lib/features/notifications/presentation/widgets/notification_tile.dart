import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getTypeIcon(notification.type),
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTypeText(notification.type),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  _formatDate(notification.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildTrailingWidget(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.chat:
        iconData = Icons.chat;
        iconColor = Colors.blue;
        break;
      case NotificationType.system:
        iconData = Icons.system_update;
        iconColor = Colors.orange;
        break;
      case NotificationType.marketing:
        iconData = Icons.campaign;
        iconColor = Colors.purple;
        break;
      case NotificationType.reminder:
        iconData = Icons.alarm;
        iconColor = Colors.green;
        break;
      case NotificationType.update:
        iconData = Icons.update;
        iconColor = Colors.indigo;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildTrailingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!notification.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        if (notification.priority == NotificationPriority.high ||
            notification.priority == NotificationPriority.urgent)
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: notification.priority == NotificationPriority.urgent
                  ? Colors.red
                  : Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              notification.priority == NotificationPriority.urgent
                  ? 'URGENT'
                  : 'HIGH',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.marketing:
        return Icons.campaign;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.update:
        return Icons.update;
    }
  }

  String _getTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return 'Chat';
      case NotificationType.system:
        return 'System';
      case NotificationType.marketing:
        return 'Marketing';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.update:
        return 'Update';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd').format(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
