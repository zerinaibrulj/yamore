import 'package:flutter/material.dart';

/// Root [Navigator] key so session and deep-link code can navigate without a [BuildContext].
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
