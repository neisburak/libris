import 'package:flutter/foundation.dart';

/// Logger class
class Logger {
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
