import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Bild aus Galerie oder Kamera auswählen (nur .jpeg/.jpg oder .png möglich)
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Komprimierung für bessere Performance
        maxWidth: 800,
        maxHeight: 800,
        requestFullMetadata: false, // Metadaten werden nicht speichern
      );

      // Zusätzliche Validierung des Dateiformats
      if (image != null) {
        final String extension = image.name.split('.').last.toLowerCase();
        if (!_isAllowedImageFormat(extension)) {
          throw Exception('Nur JPEG und PNG Dateien sind erlaubt');
        }
      }

      return image;
    } catch (e) {
      return null;
    }
  } 
  
  // Profilbild zu Firebase Storage hochladen

  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      // Erkenne das Original-Format vom Bild für Content-Type
      String extension = 'jpg'; // Fallback
      if (imageFile.name.contains('.')) {
        extension = imageFile.name.split('.').last.toLowerCase();
      }

      // Prüfe ob das Dateiformat erlaubt ist (nur JPEG und PNG)
      if (!_isAllowedImageFormat(extension)) {
        throw Exception('Nur JPEG und PNG Dateien sind als Profilbild erlaubt');
      }

      // Erstelle Pfad OHNE Dateiendung (passend zu Firebase Rule)
      final String fileName = 'profile_images/$uid';
      final Reference ref = _storage.ref().child(fileName);

      late UploadTask uploadTask;

      if (kIsWeb) {
        // Web: Verwende Bytes statt File
        final Uint8List bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: _getContentType(extension)),
        );
      } else {
        // Mobile: Verwende File
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: _getContentType(extension)),
        );
      }

      // Warte auf bis Upload fertig ist
      final TaskSnapshot snapshot = await uploadTask;

      // Hole die Download-URL
      final String downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      return null;
    }
  }

  // Content-Type basierend auf Dateiendung
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg'; // Fallback
    }
  }

  // Prüft ob das Bildformat für Profilbilder erlaubt ist
  bool _isAllowedImageFormat(String extension) {
    final allowedFormats = ['jpg', 'jpeg', 'png'];
    return allowedFormats.contains(extension.toLowerCase());
  }

  // Profilbild-URL in Firestore speichern
  Future<bool> updateProfileImageUrl(String uid, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Kompletter Workflow: Bild auswählen, hochladen und URL speichern
  Future<String?> updateProfileImage(
    String uid, {
    ImageSource source = ImageSource.gallery,
  }) async {
    // Schritt 1: Bild auswählen
    final XFile? image = await pickImage(source: source);
    if (image == null) return null;

    // Schritt 2: Bild hochladen
    final String? downloadURL = await uploadProfileImage(uid, image);
    if (downloadURL == null) return null;

    // Schritt 3: URL in Firestore speichern
    final bool success = await updateProfileImageUrl(uid, downloadURL);
    if (!success) return null;

    return downloadURL;
  }

  Future<String?> uploadActivityImage(String uid, XFile imageFile) async {
    try {
      String extension = 'jpg';
      if (imageFile.name.contains('.')) {
        extension = imageFile.name.split('.').last.toLowerCase();
      }
      if (!_isAllowedImageFormat(extension)) return null;

      final String fileName =
          'activity_images/$uid/${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref = _storage.ref().child(fileName);

      late UploadTask uploadTask;
      if (kIsWeb) {
        final Uint8List bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: _getContentType(extension)),
        );
      } else {
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: _getContentType(extension)),
        );
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Altes Profilbild löschen (optional für Speicherplatz-Optimierung)
  Future<bool> deleteProfileImage(String uid) async {
    try {
      // Lösche Profilbild ohne Dateiendung (passend zu Firebase Rule)
      final String fileName = 'profile_images/$uid';
      final Reference ref = _storage.ref().child(fileName);
      await ref.delete();
      return true;
    } catch (e) {
      // Kein Fehler wenn Datei nicht existiert
      return true;
    }
  }
}
