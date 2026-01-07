// lib/features/scan/providers/scanned_image_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This simple provider will hold the image file during navigation.
final scannedImageProvider = StateProvider<File?>((ref) => null);