import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_data_service.dart';

class FriendService {
  FriendService._internal();
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _syncSubcollectionsAllowed = true;
  static bool _syncRootCollectionsAllowed = true;

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

    final List<String> subjects = ['Python', 'C++', 'Javascript', 'Java'];
    final history = await UserDataService().getHistory();
    
    final Map<String, Map<String, int>> allSubjectsLevels = {};
    final Map<String, int> allSubjectsCompleted = {};
    final Map<String, dynamic> coursesData = {};

    for (final subject in subjects) {
      final String docId = subject.toLowerCase();
      int completedCount = 0;
      for (var item in history) {
        if (item['lang'] == subject) {
          completedCount = item['completed'] ?? 0;
          break;
        }
      }
      allSubjectsCompleted[docId] = completedCount;
      
      final starsMap = await UserDataService().getLevelStars(subject);
      final Map<String, int> levelsData = {};
      starsMap.forEach((key, val) {
        levelsData[key.toString()] = val;
      });
      allSubjectsLevels[docId] = levelsData;

      coursesData[docId] = {
        'subject': subject,
        'completed': completedCount,
        'levels': levelsData,
      };
    }

    // 1. Direct Write for User Profile and Inline Courses Map (guaranteed to succeed under /users/{uid})
    try {
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
        'courses': coursesData, // Fail-safe inline map field sync
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("Profile and inline courses progress synced successfully!");
    } catch (e) {
      debugPrint("Failed to sync profile progress: $e");
    }

    // 2. Batch 1: User Subcollection progress (Path A: /users/{uid}/courses/{courseName})
    if (_syncSubcollectionsAllowed) {
      final batch1 = _db.batch();
      for (final subject in subjects) {
        final String docId = subject.toLowerCase();
        final completedCount = allSubjectsCompleted[docId] ?? 0;
        final levelsData = allSubjectsLevels[docId] ?? {};

        batch1.set(_db.collection('users').doc(uid).collection('courses').doc(docId), {
          'subject': subject,
          'completed': completedCount,
          'levels': levelsData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      try {
        await batch1.commit();
        debugPrint("Nested courses progress subcollection synced successfully!");
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('permission-denied') || errStr.contains('PERMISSION_DENIED')) {
          _syncSubcollectionsAllowed = false;
          debugPrint("Nested courses progress subcollection sync: permission denied (check Firestore Security Rules). Disabling subcollection sync to prevent log spam.");
        } else {
          debugPrint("Failed to sync nested courses progress subcollection: $e");
        }
      }
    }

    // 3. Batch 2: Root-level courses collection (might fail if rules deny writes to /courses)
    if (_syncRootCollectionsAllowed) {
      final batch2 = _db.batch();
      for (final subject in subjects) {
        final String docId = subject.toLowerCase();
        final completedCount = allSubjectsCompleted[docId] ?? 0;
        final levelsData = allSubjectsLevels[docId] ?? {};

        // Path B: /courses/{courseName}/users/{uid}
        batch2.set(_db.collection('courses').doc(docId).collection('users').doc(uid), {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'subject': subject,
          'completed': completedCount,
          'levels': levelsData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Path C: /courses/{uid}_{courseName}
        batch2.set(_db.collection('courses').doc('${uid}_$docId'), {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'subject': subject,
          'completed': completedCount,
          'levels': levelsData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      try {
        await batch2.commit();
        debugPrint("Root-level courses collection synced successfully!");
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('permission-denied') || errStr.contains('PERMISSION_DENIED')) {
          _syncRootCollectionsAllowed = false;
          debugPrint("Root-level courses collection sync: permission denied (check Firestore Security Rules). Disabling root-level sync to prevent log spam.");
        } else {
          debugPrint("Failed to sync root-level courses progress: $e");
        }
      }
    }
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
