import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImagePick;
  final VoidCallback onVoiceRecord;
  final bool isUploading;

  const ChatInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onImagePick,
    required this.onVoiceRecord,
    this.isUploading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image Button
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                ),
                onPressed: isUploading ? null : onImagePick,
                tooltip: 'Send image',
              ),
            ),
            SizedBox(width: 8),

            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isUploading,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: theme.inputDecorationTheme.hintStyle,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            SizedBox(width: 8),

            // Send or Voice Button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;

                return Container(
                  decoration: BoxDecoration(
                    color: hasText
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color?.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (hasText
                                    ? theme.colorScheme.primary
                                    : theme.iconTheme.color ?? Colors.grey)
                                .withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      isUploading
                          ? Icons.hourglass_bottom
                          : (hasText ? Icons.send_rounded : Icons.mic),
                      color: hasText
                          ? theme.appBarTheme.foregroundColor
                          : theme.colorScheme.surface,
                      size: 20,
                    ),
                    onPressed: isUploading
                        ? null
                        : (hasText ? onSend : onVoiceRecord),
                    tooltip: hasText ? 'Send' : 'Record voice',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
