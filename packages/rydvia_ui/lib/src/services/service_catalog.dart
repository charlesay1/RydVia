import 'package:flutter/foundation.dart';

enum RydViaServiceGroup {
  ride,
  deliver,
  move,
  towing,
  business,
  scheduled,
  intercity,
}

@immutable
class RydViaService {
  const RydViaService({
    required this.id,
    required this.label,
    required this.group,
  });
  final String id;
  final String label;
  final RydViaServiceGroup group;
}

/// An immutable snapshot supplied by the existing backend adapter.
/// Unknown/missing flags are unavailable. This is presentation filtering only;
/// booking authorization and active-trip policies must be enforced server-side.
@immutable
class RydViaServiceCatalog {
  RydViaServiceCatalog({
    required Iterable<RydViaService> services,
    required Map<String, bool> availability,
  }) : services = List.unmodifiable(services),
       availability = Map.unmodifiable(availability) {
    if (this.services.map((service) => service.id).toSet().length !=
        this.services.length) {
      throw ArgumentError('Service IDs must be unique.');
    }
  }

  final List<RydViaService> services;
  final Map<String, bool> availability;

  List<RydViaService> get enabled => List.unmodifiable(
    services.where((service) => availability[service.id] == true),
  );
}
