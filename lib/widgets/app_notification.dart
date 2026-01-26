import 'package:flutter/material.dart';

/// Klasa do wyświetlania powiadomień w aplikacji
/// Powiadomienia wyświetlane są na dole ekranu, znikają automatycznie
class AppNotification {
  /// Pokaż krótkie powiadomienie (toast)
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // Zamknij poprzednie powiadomienie
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color backgroundColor;
    IconData icon;

    if (isError) {
      backgroundColor = Colors.red[600]!;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green[600]!;
      icon = Icons.check_circle_outline;
    } else {
      backgroundColor = Colors.blue[600]!;
      icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Przycisk X do zamknięcia
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dismissDirection: DismissDirection.horizontal,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? 'OK',
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Pokaż powiadomienie o dodaniu do koszyka
  static void cartAdded(BuildContext context, String productName, {int quantity = 1}) {
    show(
      context,
      message: quantity > 1
          ? '$productName (x$quantity) dodano'
          : '$productName dodano',
      isSuccess: true,
      duration: const Duration(milliseconds: 1500),
    );
  }

  /// Pokaż powiadomienie o błędzie
  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      isError: true,
      duration: const Duration(seconds: 4),
    );
  }

  /// Pokaż powiadomienie o sukcesie
  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  /// Pokaż informację
  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }
}
