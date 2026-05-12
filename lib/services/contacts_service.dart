import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Fetches and manages device contacts.
/// Uses flutter_contacts package to access the address book.
class ContactsService {

  // ──────────────────────────────────────────────
  // Request contacts permission from the user
  // Returns true if permission is granted
  // ──────────────────────────────────────────────
  Future<bool> requestContactsPermission() async {
    // Check current status
    PermissionStatus status = await Permission.contacts.status;

    if (status.isGranted) return true;

    // Request permission if not already granted
    status = await Permission.contacts.request();
    return status.isGranted;
  }

  // ──────────────────────────────────────────────
  // Fetch all device contacts with phone numbers
  // ──────────────────────────────────────────────
  Future<List<Contact>> getContacts() async {
    final hasPermission = await requestContactsPermission();
    if (!hasPermission) return [];

    // withProperties: true fetches phone numbers & other details
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    // Filter: only return contacts who have at least one phone number
    return contacts
        .where((contact) => contact.phones.isNotEmpty)
        .toList();
  }

  // ──────────────────────────────────────────────
  // Extract the first phone number from a contact
  // and normalize it for Firebase lookup
  // ──────────────────────────────────────────────
  String extractPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) return '';

    String phone = contact.phones.first.number;

    // Remove spaces, dashes, parentheses
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Ensure it has a + prefix (international format)
    if (!phone.startsWith('+')) {
      // Default to India (+91) — change this for your country
      phone = '+91${phone.replaceAll(RegExp(r'^0+'), '')}';
    }

    return phone;
  }
}
