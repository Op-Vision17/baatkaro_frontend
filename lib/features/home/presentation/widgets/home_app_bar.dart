// widgets/home_app_bar.dart
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onLogoutTap;

  const HomeAppBar({
    Key? key,
    required this.onProfileTap,
    required this.onNotificationsTap,
    required this.onLogoutTap,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: Padding(
        padding: EdgeInsets.all(4.0),
        child: Image.asset('assets/logo_secondary.png', fit: BoxFit.contain),
      ),
      leadingWidth: 150,
      title: null,
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, size: 20),
          ),
          onPressed: onProfileTap,
          tooltip: 'Profile',
        ),
        SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.more_vert, size: 20),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'notifications') {
              onNotificationsTap();
            } else if (value == 'logout') {
              onLogoutTap();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Notification Settings'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.logout, size: 18, color: Colors.red),
                  ),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: 8),
      ],
    );
  }
}
