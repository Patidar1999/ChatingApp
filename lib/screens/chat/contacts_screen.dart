import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/contacts_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_constants.dart';
import 'chat_screen.dart';

/// Shows device contacts who are registered on the app.
/// Tap a contact to open a chat with them.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _contactsService = ContactsService();
  final _userService = UserService();

  List<Contact> _contacts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // ──────────────────────────────────────────────
  // Fetch device contacts
  // ──────────────────────────────────────────────
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final contacts = await _contactsService.getContacts();

    if (contacts.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No contacts found or permission denied.';
      });
      return;
    }

    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  // ──────────────────────────────────────────────
  // When a contact is tapped:
  // 1. Look up their phone number in Firestore
  // 2. If found → open chat
  // 3. If not found → show message
  // ──────────────────────────────────────────────
  Future<void> _openChat(Contact contact) async {
    final phone = _contactsService.extractPhoneNumber(contact);
    if (phone.isEmpty) {
      context.showSnack('Invalid phone number', isError: true);
      return;
    }

    // Show loading indicator while looking up user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final UserModel? user = await _userService.getUserByPhone(phone);
    Navigator.pop(context); // Dismiss loading

    if (user == null) {
      context.showSnack(
        '${contact.displayName} is not on Flutter Chat yet.',
        isError: true,
      );
      return;
    }

    if (user.uid == _currentUid) {
      context.showSnack("You can't chat with yourself!");
      return;
    }

    // Navigate to chat with this user
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverUser: user,
          chatRoomId: getChatRoomId(_currentUid, user.uid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contacts, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContacts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final phone = contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : 'No phone';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        // Show contact photo if available
                        backgroundImage: contact.photo != null
                            ? MemoryImage(contact.photo!)
                            : null,
                        child: contact.photo == null
                            ? Text(
                                contact.displayName.isNotEmpty
                                    ? contact.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(phone,
                          style: const TextStyle(color: Colors.grey)),
                      onTap: () => _openChat(contact),
                    );
                  },
                ),
    );
  }
}
