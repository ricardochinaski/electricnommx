import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveProfile({
    required String name,
    required String email,
    required String position,
    required String specialty,
    String? photoUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre': name,
          'email': email,
          'cargo': position,
          'especialidad': specialty,
          'fotoUrl': photoUrl,
          'fecha_actualizacion': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
      } else {
        debugPrint('[UserService] No hay usuario autenticado para guardar.');
      }
    } on TimeoutException {
      // Sin respuesta del servidor (offline): Firestore ya encoló la escritura
      // en su caché local (persistenceEnabled) y la sincronizará al volver la
      // red. NO es un error para el usuario en terreno.
      debugPrint('[UserService] Perfil guardado en caché offline; sincronización pendiente.');
    } catch (e) {
      debugPrint('[UserService] Error al guardar perfil: $e');
      rethrow;
    }
  }

  Future<void> syncBookmarks(List<String> bookmarks) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).set({
          'marcadores': bookmarks,
          'fecha_sincronizacion': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
      } else {
        throw Exception('Usuario no autenticado');
      }
    } on TimeoutException {
      // Offline: la escritura quedó encolada en la caché local de Firestore
      // y se sincronizará automáticamente al recuperar conexión.
      debugPrint('[UserService] Marcadores guardados en caché offline; sincronización pendiente.');
    } catch (e) {
      debugPrint('[UserService] Error al sincronizar marcadores: $e');
      rethrow;
    }
  }
}

