import 'package:collection/collection.dart';

// God forgive me for this horrendous code
class MapKey {
  final Map<String, dynamic> map;

  MapKey(this.map);

  @override
  int get hashCode {
    return Object.hashAll(map.values
        .map(
          (e) => e.toString(),
        )
        .toList()
      ..sort(
        (a, b) => a.compareTo(b),
      ));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapKey &&
          const DeepCollectionEquality().equals(map, other.map));
}