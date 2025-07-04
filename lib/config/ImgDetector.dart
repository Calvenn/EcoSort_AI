import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageUploader {
  // Compute SHA256 hash from image bytes
  static Future<String> computeImageHash(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  // Check if this image has already been scanned by the user
  static Future<bool> isDuplicateUpload(String hash) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history') // 💡 Only using 'history'
        .where('hash', isEqualTo: hash)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Detect and return whether image is duplicate
  static Future<bool> detectDuplicate(File image) async {
    final hash = await computeImageHash(image);
    return await isDuplicateUpload(hash);
  }
}
