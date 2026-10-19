enum ProductRole { customer, driver, business }

class AccessProfile {
  AccessProfile({
    required this.userId,
    required Iterable<String> roles,
    required this.onboarded,
  }) : roles = Set.unmodifiable(roles);
  final String userId;
  final Set<String> roles;
  final bool onboarded;
  bool permits(ProductRole role) => roles.contains(role.name);
}

class ServiceAvailability {
  const ServiceAvailability({
    required this.id,
    required this.name,
    required this.group,
    required this.enabled,
  });
  final String id;
  final String name;
  final String group;
  final bool enabled;
}
