import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_constants.dart';
import '../home/home_screen.dart';

/// Screen shown to NEW users after OTP verification.
/// They must enter a name before proceeding.
class SetupProfileScreen extends StatefulWidget {
  final String uid;
  final String phone;

  const SetupProfileScreen({
    super.key,
    required this.uid,
    required this.phone,
  });

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  File? _pickedImage;   // Holds locally selected profile photo
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Let user pick a profile photo from gallery
  // ──────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,  // Compress image to save storage space
      maxWidth: 512,
    );

    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  // ──────────────────────────────────────────────
  // Save profile and navigate to HomeScreen
  // ──────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showSnack('Please enter your name', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Save basic user info to Firestore
      await _authService.saveUserToFirestore(
        uid: widget.uid,
        phone: widget.phone,
        name: name,
      );

      // 2. If user picked a photo, upload it to Firebase Storage
      if (_pickedImage != null) {
        await _userService.uploadProfilePhoto(widget.uid, _pickedImage!);
      }

      // 3. Navigate to HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      context.showSnack('Error saving profile: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Text(
                'Set Up Your Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'This is how people will see you',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Profile photo picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : null,
                      child: _pickedImage == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    // Camera icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Text('Tap to add photo', style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 32),

              // Name input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 32),

              // Continue button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
