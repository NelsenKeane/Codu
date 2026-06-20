import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_data_service.dart';

class FriendService {
  FriendService._internal();
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Syncs the current user's profile info to Firestore.
  /// This ensures they can be searched and found by other users.
  Future<void> syncUserToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final email = user.email ?? "";

    // Load local stats/details
    final savedName = await UserDataService().getDisplayName();
    final localUsername = email.split('@')[0];
    String displayName = (savedName != null && savedName.isNotEmpty)
        ? savedName
        : (user.displayName != null && user.displayName!.isNotEmpty
            ? user.displayName!
            : localUsername);

    final normalizedUsername = displayName.toLowerCase().replaceAll(' ', '_');
    final streak = await UserDataService().getStreak();
    final trophies = await UserDataService().getTrophies();
    final avatarIndex = await UserDataService().getAvatarIndex();
    final wins = await UserDataService().getWins();
    final losses = await UserDataService().getLosses();

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': normalizedUsername,
      'streak': streak,
      'trophies': trophies,
      'avatarIndex': avatarIndex,
      'wins': wins,
      'losses': losses,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Searches for a user by their username (normalized, without the '@' symbol).
  Future<Map<String, dynamic>?> searchUserByUsername(String query) async {
    final currentUid = _uid;
    if (currentUid == null) return null;

    final cleanQuery = query.trim().replaceAll('@', '').toLowerCase().replaceAll(' ', '_');
    if (cleanQuery.isEmpty) return null;

    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: cleanQuery)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    if (doc.id == currentUid) return null; // Cannot add yourself

    return doc.data();
  }

  /// Searches for multiple users by username or display name prefix.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final currentUid = _uid;
    if (currentUid == null) return [];

    final cleanQueryForUsername = query.trim().replaceAll('@', '').toLowerCase().replaceAll(' ', '_');
    final cleanQueryForDisplay = query.trim().replaceAll('@', '');
    if (cleanQueryForUsername.isEmpty) return [];

    try {
      // 1. Search by username prefix
      final usernameSnap = await _db
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: cleanQueryForUsername)
          .where('username', isLessThanOrEqualTo: '$cleanQueryForUsername\uf8ff')
          .limit(15)
          .get();

      // 2. Search by display name prefix with case combinations
      final displayPrefixes = {
        cleanQueryForDisplay,
        cleanQueryForDisplay.toLowerCase(),
        cleanQueryForDisplay.toUpperCase(),
        cleanQueryForDisplay.isNotEmpty 
            ? cleanQueryForDisplay[0].toUpperCase() + cleanQueryForDisplay.substring(1).toLowerCase() 
            : cleanQueryForDisplay
      };

      final List<QuerySnapshot<Map<String, dynamic>>> displaySnaps = [];
      for (var prefix in displayPrefixes) {
        if (prefix.isNotEmpty) {
          final snap = await _db
              .collection('users')
              .where('displayName', isGreaterThanOrEqualTo: prefix)
              .where('displayName', isLessThanOrEqualTo: '$prefix\uf8ff')
              .limit(10)
              .get();
          displaySnaps.add(snap);
        }
      }

      final Map<String, Map<String, dynamic>> resultsMap = {};

      for (var doc in usernameSnap.docs) {
        if (doc.id != currentUid) {
          resultsMap[doc.id] = doc.data();
        }
      }

      for (var snap in displaySnaps) {
        for (var doc in snap.docs) {
          if (doc.id != currentUid) {
            resultsMap[doc.id] = doc.data();
          }
        }
      }

      return resultsMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Streams the list of friends for the current user.
  Stream<List<Map<String, dynamic>>> streamFriends() {
    final currentUid = _uid;
    if (currentUid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> friendsList = [];
      for (var doc in snapshot.docs) {
        final friendUid = doc.id;
        // Fetch friend's latest profile details
        final userDoc = await _db.collection('users').doc(friendUid).get();
        if (userDoc.exists) {
          friendsList.add(userDoc.data()!);
        }
      }
      return friendsList;
    });
  }

  /// Streams the incoming friend requests for the current user.
  Stream<List<Map<String, dynamic>>> streamIncomingRequests() {
    final currentUid = _uid;
    if (currentUid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(currentUid)
        .collection('requests')
        .where('type', isEqualTo: 'incoming')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> requestList = [];
      for (var doc in snapshot.docs) {
        final requesterUid = doc.id;
        final userDoc = await _db.collection('users').doc(requesterUid).get();
        if (userDoc.exists) {
          requestList.add(userDoc.data()!);
        }
      }
      return requestList;
    });
  }

  /// Sends a friend request to another user.
  Future<void> sendFriendRequest(String targetUid) async {
    final currentUid = _uid;
    if (currentUid == null || currentUid == targetUid) return;

    final batch = _db.batch();

    // Write outgoing to sender
    batch.set(
      _db.collection('users').doc(currentUid).collection('requests').doc(targetUid),
      {
        'type': 'outgoing',
        'timestamp': FieldValue.serverTimestamp(),
      },
    );

    // Write incoming to recipient
    batch.set(
      _db.collection('users').doc(targetUid).collection('requests').doc(currentUid),
      {
        'type': 'incoming',
        'timestamp': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// Accepts an incoming friend request.
  Future<void> acceptFriendRequest(String targetUid) async {
    final currentUid = _uid;
    if (currentUid == null) return;

    final batch = _db.batch();

    // Remove requests docs
    batch.delete(_db.collection('users').doc(currentUid).collection('requests').doc(targetUid));
    batch.delete(_db.collection('users').doc(targetUid).collection('requests').doc(currentUid));

    // Add friend doc to current user
    batch.set(_db.collection('users').doc(currentUid).collection('friends').doc(targetUid), {
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add friend doc to target user
    batch.set(_db.collection('users').doc(targetUid).collection('friends').doc(currentUid), {
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Declines or cancels a friend request.
  Future<void> declineFriendRequest(String targetUid) async {
    final currentUid = _uid;
    if (currentUid == null) return;

    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(currentUid).collection('requests').doc(targetUid));
    batch.delete(_db.collection('users').doc(targetUid).collection('requests').doc(currentUid));
    await batch.commit();
  }

  /// Removes a friend.
  Future<void> removeFriend(String targetUid) async {
    final currentUid = _uid;
    if (currentUid == null) return;

    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(currentUid).collection('friends').doc(targetUid));
    batch.delete(_db.collection('users').doc(targetUid).collection('friends').doc(currentUid));
    await batch.commit();
  }

  /// Check if a user is already a friend or has pending request
  Future<String> getFriendshipStatus(String targetUid) async {
    final currentUid = _uid;
    if (currentUid == null) return 'none';

    final friendDoc = await _db.collection('users').doc(currentUid).collection('friends').doc(targetUid).get();
    if (friendDoc.exists) return 'friend';

    final reqDoc = await _db.collection('users').doc(currentUid).collection('requests').doc(targetUid).get();
    if (reqDoc.exists) {
      return reqDoc.data()?['type'] ?? 'none';
    }

    return 'none';
  }
}
