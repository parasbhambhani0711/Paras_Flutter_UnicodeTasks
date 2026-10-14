import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'mk5pufoj';
  static const String uploadPreset = 'Study_Brahmastra_Preset';

  static Future<Map<String, String>?> uploadFile(
      File file, String mediaType) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'study_brahmastra/notes'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'secure_url': json['secure_url'] as String,
          'public_id': json['public_id'] as String,
        };
      }
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
    }
    return null;
  }

  static String getPdfThumbnailUrl(String pdfUrl) {
    if (!pdfUrl.endsWith('.pdf')) return pdfUrl;
    return pdfUrl.replaceAll(RegExp(r'\.pdf$'), '.jpg');
  }
}
