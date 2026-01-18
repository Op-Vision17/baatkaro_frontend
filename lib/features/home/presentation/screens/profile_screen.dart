import 'dart:io';
import 'package:baatkaro/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/providers/shared_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final dio = ref.read(dioProvider);
      final authRepo = AuthRepository(dio, prefs);

      final profile = await authRepo.getUserProfile();

      if (mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _profilePhotoUrl = profile['profilePhoto'];
        });
      }
    } catch (e) {
      _showError('Failed to load profile');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final prefs = await ref.read(sharedPreferencesProvider.future);
      final dio = ref.read(dioProvider);
      final authRepo = AuthRepository(dio, prefs);

      final photoUrl = await authRepo.uploadProfilePhoto(File(pickedFile.path));
      await authRepo.updateProfile(_nameController.text, photoUrl);

      if (mounted) {
        setState(() {
          _profilePhotoUrl = photoUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile photo updated!')));

        ref.invalidate(currentUserNameProvider);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('Failed to upload photo: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final dio = ref.read(dioProvider);
      final authRepo = AuthRepository(dio, prefs);

      await authRepo.updateProfile(
        _nameController.text.trim(),
        _profilePhotoUrl,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        ref.invalidate(currentUserNameProvider);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to update profile: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmailAsync = ref.watch(currentUserEmailProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),

            // Profile Photo
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                    color: theme.colorScheme.surface,
                  ),
                  child: _isUploading
                      ? Center(child: CircularProgressIndicator())
                      : _profilePhotoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _profilePhotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              size: 60,
                              color: theme.iconTheme.color,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: theme.iconTheme.color,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadPhoto,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: theme.appBarTheme.foregroundColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            SizedBox(height: 16),

            // Email Field (Read-only)
            userEmailAsync.when(
              data: (email) => TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                ),
                controller: TextEditingController(text: email ?? ''),
              ),
              loading: () => SizedBox.shrink(),
              error: (_, __) => SizedBox.shrink(),
            ),

            SizedBox(height: 32),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
