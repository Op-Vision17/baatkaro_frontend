import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageMessageBubble extends StatelessWidget {
  final String? imageUrl;
  final String? localFilePath;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback? onTap;

  const ImageMessageBubble({
    Key? key,
    this.imageUrl,
    this.localFilePath,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(),
          ),
          
          // 🔥 Upload Progress Overlay
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: uploadProgress,
                              strokeWidth: 3,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '${(uploadProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Show local file while uploading
    if (isUploading && localFilePath != null) {
      return Image.file(
        File(localFilePath!),
        width: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    // Show uploaded image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Hero(
        tag: imageUrl!,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 250,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildError(),
        ),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 250,
      height: 250,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: 250,
      height: 250,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey[500]),
          SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}