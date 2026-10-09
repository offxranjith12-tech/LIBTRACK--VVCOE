import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Staff photos are stored as base64-encoded strings (see EditProfileScreen,
/// which encodes the picked image before sending it to PUT /api/staff/me).
/// Returns null for an empty or malformed value so callers can fall back to
/// initials safely.
ImageProvider? decodeAvatar(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  try {
    final Uint8List bytes = base64Decode(photoUrl);
    if (bytes.isEmpty) return null;
    return MemoryImage(bytes);
  } catch (_) {
    return null;
  }
}
