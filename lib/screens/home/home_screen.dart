import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../widgets/chat_list_tile.dart';
import '../chat/contacts_screen.dart';
import '../profile/profile_screen.dart';

/// Main home screen showing the user's conversations list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _chatService = ChatService();
  final _userService = UserService();

  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chat'),
        actions: [
          // Profile icon
          StreamBuilder<UserModel?>(
            stream: _userService.getUserStream(_currentUid),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              );
            },
          ),

          // Sign out option
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await _authService.signOut();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Chat rooms list ──
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatService.getUserChatRooms(_currentUid),
        builder: (context, snapshot) {

          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chatRooms = snapshot.data ?? [];

          // Empty state — no conversations yet
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to start chatting',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          // Chat rooms list
          return ListView.separated(
            itemCount: chatRooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final room = chatRooms[index];

              // Find the other participant's UID
              final otherUid = room.participants
                  .firstWhere((uid) => uid != _currentUid);

              return ChatListTile(
                chatRoom: room,
                otherUserId: otherUid,
                currentUserId: _currentUid,
              );
            },
          );
        },
      ),

      // ── Floating Action Button → open contacts ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactsScreen()),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
