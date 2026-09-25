library local_storage;

import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart' as path;

import '../logs/logs.dart';


part 'caching.dart';

part 'hive_box.dart';

part 'hive_keys.dart';

class LocalStorage {
  static LocalStorage? _instance;

  factory LocalStorage() {
    _instance ??= LocalStorage._internal();
    return _instance!;
  }

  LocalStorage._internal();

  // Initialize Hive
  Future<void> initHive() async {
    try {
      String? directoryPath;

      if (Platform.isIOS) {
        final directory = await path.getApplicationSupportDirectory();
        directoryPath = directory.path;
        devPrint('iOS Hive directory: $directoryPath');
      } else if (Platform.isAndroid) {
        final directory = await path.getApplicationDocumentsDirectory();
        directoryPath = directory.path;
        devPrint('Android Hive directory: $directoryPath');
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      if (directoryPath.isEmpty) {
        throw Exception('Failed to get application directory path');
      }

      // Initialize Hive with the directory path
      await Hive.initFlutter(directoryPath);
      devPrint('Hive initialized successfully');
    } catch (e) {
      devPrint('Error initializing Hive: $e');
      // You might want to handle this error appropriately
      // For example, show a user-friendly error message or retry
      rethrow; // or handle the error as needed
    }
  }

  // Open a box
  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  /// Close the box
  Future<void> closeBox<T>(String boxName) async {
    final box = await _getBoxByName(boxName);
    await box!.close();
  }

  // Write data to a box
  Future<void> writeData<T>({
    required String boxName,
    required String key,
    required T value,
  }) async {
    final box = await _getBoxByName(boxName);
    String encodedValue = json.encode(value);
    await box!.put(key, encodedValue);
  }

  // Read data from a box
  Future<T?> readData<T>({
    required String boxName,
    required String key,
  }) async {
    final box = await _getBoxByName(boxName);
    final encodedString = await box!.get(key);
    if (encodedString != null) {
      T? decodedData = json.decode(encodedString);
      return decodedData;
    } else {
      return null;
    }
  }

  // Delete data from a box
  Future<void> deleteData<T>({
    required String boxName,
    String? key,
  }) async {
    final box = await _getBoxByName(boxName);
    if (key != null) {
      await box!.delete(key);
    } else {
      await box!.clear();
    }
  }

  // box declarations
  Box? user; // dynamic values
  Box? commonBox; // dynamic values
  Box? orderData; // dynamic values

  /// get box by name
  Future<Box?> _getBoxByName<T>(String boxName) async {
    switch (boxName) {
      case HiveBox.user:
        user ??= await openBox(boxName);
        return user;
      case HiveBox.commonBox:
        commonBox ??= await openBox(HiveBox.commonBox);
        return commonBox;
      default:
        commonBox ??= await openBox(HiveBox.commonBox);
        return commonBox;
    }
  }
}
