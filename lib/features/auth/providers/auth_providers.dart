import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_api.dart';

/// Provider for the raw [AuthApi]. Singletons are fine — it just wraps Dio.
final authApiProvider = Provider<AuthApi>((ref) => AuthApi());
