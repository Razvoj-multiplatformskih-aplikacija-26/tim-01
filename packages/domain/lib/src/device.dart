import 'package:meta/meta.dart';

import 'identifiers.dart';

@immutable
final class Device {
  const Device({required this.id, required this.name, required this.category, required this.description});

  final DeviceId id;
  final String name;
  final String category;
  final String description;

  @override
  bool operator ==(Object other) =>
      other is Device &&
      other.id == id &&
      other.name == name &&
      other.category == category &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, name, category, description);
}
