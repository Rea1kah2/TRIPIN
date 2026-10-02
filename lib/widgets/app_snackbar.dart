import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

void showAppSnackbar(BuildContext context, String message,
    {bool isError = false}) {
  final colors = context.colors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: isError ? colors.onError : colors.onPrimary),
      ),
      backgroundColor: isError ? colors.error : colors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
