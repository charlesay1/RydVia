import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:rydvia_models/rydvia_models.dart';

abstract interface class ServicesRepository {
  Future<List<ServiceAvailability>> fetchServices();
}

class SupabaseServicesRepository implements ServicesRepository {
  const SupabaseServicesRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<ServiceAvailability>> fetchServices() async {
    try {
      final rows = await client
          .from('available_services')
          .select('id,name,service_group,enabled')
          .order('sort_order');
      return rows
          .map(
            (row) => ServiceAvailability(
              id: row['id'] as String,
              name: row['name'] as String,
              group: row['service_group'] as String,
              enabled: row['enabled'] == true,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      throw const AppFailure(
        'services',
        'Services could not be loaded. Please try again.',
      );
    }
  }
}
