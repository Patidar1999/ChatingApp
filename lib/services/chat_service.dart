import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../utils/app_constants.dart';

/// Handles all real-time chat operations using Firestore.
///
/// Firestore structure:
///   chats/
///     {chatRoomId}/           ← ChatRoomModel
///       messages/
///         {messageId}/        ← MessageModel
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid(); // For generating unique message IDs

  // ──────────────────────────────────────────────
  // Send a text message
  // ──────────────────────────────────────────────
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final messageId = _uuid.v4(); // Unique ID for this message
    final now = DateTime.now();

    // Create message object
    final message = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      sentAt: now,
    );

    // Use a Firestore batch to write message + update chat room atomically.
    // This ensures both writes succeed or both fail.
    final batch = _firestore.batch();

    // 1. Add message to the messages subcollection
    final messageRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);
    batch.set(messageRef, message.toMap());

    // 2. Update the chat room's last message preview
    final chatRoomRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId);
    batch.set(chatRoomRef, {
      'chatRoomId': chatRoomId,
      'participants': [senderId, receiverId],
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': senderId,
    }, SetOptions(merge: true));  // merge: true preserves existing fields

    await batch.commit();
  }

  // ──────────────────────────────────────────────
  // Real-time stream of messages in a chat room
  // Returns messages ordered by time (oldest first)
  // ──────────────────────────────────────────────
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .orderBy('sentAt', descending: false)  // Oldest messages at top
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  // ──────────────────────────────────────────────
  // Real-time stream of all chat rooms for a user
  // Used on the home screen to show conversation list
  // ──────────────────────────────────────────────
  Stream<List<ChatRoomModel>> getUserChatRooms(String uid) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)  // Newest chats first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data()))
            .toList());
  }

  // ──────────────────────────────────────────────
  // Mark all messages in a room as read
  // ──────────────────────────────────────────────
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String currentUserId,
  }) async {
    // Fetch unread messages sent TO the current user
    final unread = await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    // Batch-update all unread messages
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
