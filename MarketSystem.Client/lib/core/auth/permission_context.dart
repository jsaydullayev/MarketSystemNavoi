import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Ergonomic `context.can('products.create')` permission check.
///
/// Reads the [AuthProvider] without subscribing — a user's permission set is
/// fixed for the lifetime of a session (it only changes on the next login /
/// token refresh), so there is nothing to rebuild for mid-session.
extension PermissionContext on BuildContext {
  /// True when the signed-in user may perform [permissionKey].
  /// See [Permissions] for the key catalogue.
  bool can(String permissionKey) =>
      Provider.of<AuthProvider>(this, listen: false).can(permissionKey);
}
