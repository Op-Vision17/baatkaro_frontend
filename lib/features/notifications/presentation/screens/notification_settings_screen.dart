import 'package:baatkaro/features/notifications/presentation/provider/notification_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationSettingsControllerProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(notificationSettingsControllerProvider);
    final settings = settingsState.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Notification Settings')),
      body: settingsState.isLoading && settings == null
          ? Center(child: CircularProgressIndicator())
          : settingsState.error != null && settings == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load settings',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    settingsState.error!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .loadSettings();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : settings == null
          ? Center(child: Text('No settings available'))
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Manage Notifications',
                        style: theme.textTheme.displaySmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Control how you receive notifications',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Enable Notifications
                Card(
                  child: SwitchListTile(
                    title: Text(
                      'Enable Notifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      settings.enabled
                          ? 'You will receive notifications'
                          : 'You will not receive any notifications',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: settings.enabled,
                    activeColor: theme.colorScheme.primary,
                    secondary: Icon(
                      Icons.notifications,
                      color: settings.enabled
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color?.withOpacity(0.5),
                    ),
                    onChanged: settingsState.isLoading
                        ? null
                        : (value) async {
                            final success = await ref
                                .read(
                                  notificationSettingsControllerProvider
                                      .notifier,
                                )
                                .toggleEnabled(value);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Notifications ${value ? "enabled" : "disabled"}'
                                        : 'Failed to update settings',
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            }
                          },
                  ),
                ),

                SizedBox(height: 16),

                // Message Notifications
                Card(
                  child: SwitchListTile(
                    title: Text(
                      'Message Notifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      settings.messageNotifications
                          ? 'Get notified for new messages'
                          : 'Message notifications are off',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: settings.messageNotifications,
                    activeColor: theme.colorScheme.primary,
                    secondary: Icon(
                      Icons.message,
                      color: settings.messageNotifications
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color?.withOpacity(0.5),
                    ),
                    onChanged: settingsState.isLoading || !settings.enabled
                        ? null
                        : (value) async {
                            final success = await ref
                                .read(
                                  notificationSettingsControllerProvider
                                      .notifier,
                                )
                                .toggleMessageNotifications(value);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Message notifications ${value ? "enabled" : "disabled"}'
                                        : 'Failed to update settings',
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            }
                          },
                  ),
                ),

                SizedBox(height: 16),

                // Sound Notifications
                Card(
                  child: SwitchListTile(
                    title: Text(
                      'Sound',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      settings.soundEnabled
                          ? 'Play sound for notifications'
                          : 'Notifications will be silent',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: settings.soundEnabled,
                    activeColor: theme.colorScheme.primary,
                    secondary: Icon(
                      settings.soundEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: settings.soundEnabled
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color?.withOpacity(0.5),
                    ),
                    onChanged: settingsState.isLoading || !settings.enabled
                        ? null
                        : (value) async {
                            final success = await ref
                                .read(
                                  notificationSettingsControllerProvider
                                      .notifier,
                                )
                                .toggleSound(value);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Sound ${value ? "enabled" : "disabled"}'
                                        : 'Failed to update settings',
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            }
                          },
                  ),
                ),

                SizedBox(height: 32),

                // Info Card
                Card(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'About Notifications',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• You only receive notifications when you\'re offline\n'
                          '• Tap a notification to open the chat\n'
                          '• Notifications are sent to all your devices',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (settingsState.isLoading)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
