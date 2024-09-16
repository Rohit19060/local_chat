import 'package:flutter/material.dart';

import 'main.dart';

void showToast(String msg, {void Function()? trigger, String actionLabel = 'Undo'}) {
  final theme = Theme.of(navigatorKey.currentContext!);
  ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentSnackBar();
  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
    SnackBar(
      content: Text(msg, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
      backgroundColor: theme.colorScheme.secondary,
      actionOverflowThreshold: 1,
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      margin: const EdgeInsets.all(20),
      action: trigger != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: trigger,
              textColor: Colors.white,
            )
          : null,
    ),
  );
}
