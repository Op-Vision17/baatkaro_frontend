import 'dart:io';
import 'package:baatkaro/shared/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../shared/providers/shared_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      final prefs = await ref.read(sharedPreferencesProvider.future);
      final dio = ref.read(dioProvider);
      final authRepo = AuthRepository(dio, prefs);

      final photoUrl = await authRepo.uploadProfilePhoto(_selectedImage!);

      setState(() {
        _uploadedPhotoUrl = photoUrl;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Photo uploaded successfully!')));
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .completeOnboarding(
          _nameController.text.trim(),
          profilePhoto: _uploadedPhotoUrl,
        );

    if (mounted) {
      if (success) {
        try {
          print('🔔 Registering FCM token after onboarding...');
          await ref
              .read(notificationControllerProvider.notifier)
              .registerToken();
          print('✅ FCM token registered successfully');
        } catch (e) {
          print('⚠️ Failed to register FCM token: $e');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        final error = ref.read(authControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to complete onboarding')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),

                // Profile Photo Selector
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: _isUploadingPhoto
                            ? Center(child: CircularProgressIndicator())
                            : _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_add,
                                    size: 60,
                                    color: theme.colorScheme.primary,
                                  ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
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
                    ],
                  ),
                ),

                SizedBox(height: 12),

                Text(
                  'Add Photo (Optional)',
                  style: theme.textTheme.bodyMedium,
                ),

                SizedBox(height: 32),

                Text(
                  'Welcome to Baatkro!',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                Text(
                  'Let\'s get to know you better',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (authState.isLoading || _isUploadingPhoto)
                        ? null
                        : _completeOnboarding,
                    child: authState.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Continue'),
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  'Your name and photo will be visible to other users',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}