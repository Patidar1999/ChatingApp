import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/app_constants.dart';

/// Screen where users can view and update their profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _userService = UserService();
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  UserModel? _userModel;
  File? _newPhoto;
  bool _isLoading = false;
  bool _isEditing = false;  // Toggle between view and edit mode

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getUserById(_currentUid);
    if (user != null) {
      setState(() {
        _userModel = user;
        _nameController.text = user.name;
      });
    }
  }

  // ──────────────────────────────────────────────
  // Pick new profile photo from gallery
  // ──────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked != null) {
      setState(() => _newPhoto = File(picked.path));
    }
  }

  // ──────────────────────────────────────────────
  // Save profile changes
  // ──────────────────────────────────────────────
  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      context.showSnack('Name cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update name if changed
      if (newName != _userModel?.name) {
        await _userService.updateUserName(_currentUid, newName);
      }

      // Upload new photo if selected
      if (_newPhoto != null) {
        await _userService.uploadProfilePhoto(_currentUid, _newPhoto!);
      }

      await _loadUser();  // Refresh UI with latest data

      setState(() {
        _isEditing = false;
        _newPhoto = null;
        _isLoading = false;
      });

      context.showSnack('Profile updated successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      context.showSnack('Error updating profile: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Edit / Save toggle button
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_isEditing) {
                      _saveChanges();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Profile photo ──
                  GestureDetector(
                    onTap: _isEditing ? _pickPhoto : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey.shade200,
                          // Show new photo if picked, otherwise existing photo
                          backgroundImage: _newPhoto != null
                              ? FileImage(_newPhoto!)
                              : (_userModel?.photoUrl != null
                                  ? NetworkImage(_userModel!.photoUrl!)
                                      as ImageProvider
                                  : null),
                          child: (_newPhoto == null && _userModel?.photoUrl == null)
                              ? Text(
                                  _userModel!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 48, color: Colors.grey),
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Name field ──
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: !_isEditing,
                      fillColor: Colors.grey.shade100,
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 16),

                  // ── Phone (read-only) ──
                  TextField(
                    controller: TextEditingController(text: _userModel!.phone),
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      helperText: 'Phone number cannot be changed',
                      filled: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 16),

                  // ── Member since ──
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Member Since'),
                    subtitle: Text(
                      '${_userModel!.createdAt.day}/${_userModel!.createdAt.month}/${_userModel!.createdAt.year}',
                    ),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),

                  // Loading indicator during save
                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
    );
  }
}
