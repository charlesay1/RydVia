import 'package:flutter/material.dart';
import 'package:rydvia_api/rydvia_api.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_models/rydvia_models.dart';
import '../auth_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.role,
    required this.services,
    required this.auth,
  });
  final ProductRole role;
  final ServicesRepository services;
  final AuthController auth;
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<List<ServiceAvailability>> data;
  @override
  void initState() {
    super.initState();
    data = widget.services.fetchServices();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(switch (widget.role) {
        ProductRole.customer => 'Ride. Deliver. Move.',
        ProductRole.driver => 'Your driver workspace',
        ProductRole.business => 'Your business workspace',
      }, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: RydViaSpacing.s20),
      if (widget.role == ProductRole.customer)
        FutureBuilder<List<ServiceAvailability>>(
          future: data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const RydViaLoadingState(label: 'Loading services');
            if (snapshot.hasError)
              return RydViaErrorState(
                message: 'Services could not be loaded.',
                onRetry: () => setState(() {
                  data = widget.services.fetchServices();
                }),
              );
            final rows = snapshot.data ?? [];
            return RydViaServiceGrid(
              catalog: RydViaServiceCatalog(
                services: rows.map(
                  (row) => RydViaService(
                    id: row.id,
                    label: row.name,
                    group: RydViaServiceGroup.values.firstWhere(
                      (group) => group.name == row.group,
                      orElse: () => RydViaServiceGroup.move,
                    ),
                  ),
                ),
                availability: {for (final row in rows) row.id: row.enabled},
              ),
              onSelected: (_) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking is not available in this release.'),
                ),
              ),
            );
          },
        )
      else
        const RydViaEmptyState(
          title: 'Your account is ready',
          message:
              'Operational jobs, orders, and payment workflows are not enabled in this foundation release.',
        ),
      if (widget.role == ProductRole.customer)
        TextButton(
          onPressed: () => setState(() {
            data = widget.services.fetchServices();
          }),
          child: const Text('Refresh services'),
        ),
      TextButton(
        onPressed: widget.auth.busy ? null : widget.auth.signOut,
        child: const Text('Sign out'),
      ),
    ],
  );
}
