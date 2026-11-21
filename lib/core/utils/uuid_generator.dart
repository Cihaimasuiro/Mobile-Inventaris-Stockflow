import 'package:uuid/uuid.dart';

/// Pembuat ID entitas. Selalu UUID v4 (AGENTS.md dan API meminta v4).
/// Di-inject agar tes bisa memakai ID deterministik.
abstract interface class IdGenerator {
  String newId();
}

class UuidV4Generator implements IdGenerator {
  const UuidV4Generator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
