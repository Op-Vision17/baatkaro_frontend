// widgets/room_list_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RoomListItem extends StatelessWidget {
  final String roomId;
  final String roomName;
  final String roomCode;
  final String? roomPhoto;
  final int memberCount;
  final VoidCallback onTap;
  final VoidCallback? onPhotoTap;

  const RoomListItem({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.roomCode,
    this.roomPhoto,
    required this.memberCount,
    required this.onTap,
    this.onPhotoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(theme),
                SizedBox(width: 16),
                Expanded(
                  child: _buildContent(theme),
                ),
                _buildTrailingIcon(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return GestureDetector(
      onTap: roomPhoto != null ? onPhotoTap : null,
      child: Hero(
        tag: 'room_photo_$roomId',
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: roomPhoto != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: roomPhoto!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                )
              : Center(
                  child: Text(
                    roomName[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.appBarTheme.foregroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          roomName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$memberCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.circle,
              size: 4,
              color: theme.textTheme.bodySmall?.color,
            ),
            SizedBox(width: 8),
            Text(
              'Code: $roomCode',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailingIcon(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.primary,
      ),
    );
  }
}