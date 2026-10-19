import 'package:flutter/material.dart';

import '../services/service_catalog.dart';
import '../theme/tokens.g.dart';

class RydViaButton extends StatelessWidget {
  const RydViaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: RydViaIconSize.small,
                child: MediaQuery.disableAnimationsOf(context)
                    ? const Icon(
                        Icons.hourglass_empty_outlined,
                        size: RydViaIconSize.small,
                      )
                    : const CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Loading',
                      ),
              ),
              const SizedBox(width: RydViaSpacing.s8),
              Flexible(child: Text(label)),
            ],
          )
        : Text(label),
  );
}

class RydViaTextField extends StatelessWidget {
  const RydViaTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
  });
  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    onFieldSubmitted: onSubmitted,
    obscureText: obscureText,
    decoration: InputDecoration(labelText: label),
  );
}

class RydViaSearchField extends StatelessWidget {
  const RydViaSearchField({
    super.key,
    required this.label,
    required this.onChanged,
    this.controller,
  });
  final String label;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.search_outlined),
    ),
  );
}

class RydViaCard extends StatelessWidget {
  const RydViaCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(RydViaSpacing.s16),
      child: child,
    ),
  );
}

class RydViaServiceTile extends StatelessWidget {
  const RydViaServiceTile({
    super.key,
    required this.service,
    required this.onPressed,
  });
  final RydViaService service;
  final VoidCallback onPressed;

  static IconData iconFor(RydViaServiceGroup group) => switch (group) {
    RydViaServiceGroup.ride => Icons.directions_car_outlined,
    RydViaServiceGroup.deliver => Icons.inventory_2_outlined,
    RydViaServiceGroup.move => Icons.local_shipping_outlined,
    RydViaServiceGroup.towing => Icons.car_repair_outlined,
    RydViaServiceGroup.business => Icons.business_center_outlined,
    RydViaServiceGroup.scheduled => Icons.event_outlined,
    RydViaServiceGroup.intercity => Icons.route_outlined,
  };

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.all(RydViaSpacing.s16),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RydViaRadius.card),
      ),
    ),
    onPressed: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(service.group), size: RydViaIconSize.service),
        const SizedBox(height: RydViaSpacing.s8),
        Text(service.label, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// Wrap uses natural heights so large text does not clip inside fixed grid rows.
/// Rebuild with each backend snapshot; no local service toggles are maintained.
class RydViaServiceGrid extends StatelessWidget {
  const RydViaServiceGrid({
    super.key,
    required this.catalog,
    required this.onSelected,
  });
  final RydViaServiceCatalog catalog;
  final ValueChanged<RydViaService> onSelected;

  @override
  Widget build(BuildContext context) {
    final services = catalog.enabled;
    if (services.isEmpty) {
      return const RydViaEmptyState(
        title: 'Services are unavailable',
        message: 'Please check again later.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 320.0;
        final scaledMinimum =
            120 * MediaQuery.textScalerOf(context).scale(16) / 16;
        final columns = (width / (scaledMinimum + RydViaSpacing.s12))
            .floor()
            .clamp(1, 4);
        final tileWidth = (width - RydViaSpacing.s12 * (columns - 1)) / columns;
        return Wrap(
          spacing: RydViaSpacing.s12,
          runSpacing: RydViaSpacing.s12,
          children: services
              .map(
                (service) => SizedBox(
                  key: ValueKey(service.id),
                  width: tileWidth,
                  child: RydViaServiceTile(
                    service: service,
                    onPressed: () => onSelected(service),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class RydViaVehicleCard extends StatelessWidget {
  const RydViaVehicleCard({
    super.key,
    required this.name,
    required this.eta,
    required this.capacity,
    required this.price,
    required this.description,
    required this.selected,
    required this.onPressed,
  });
  final String name;
  final String eta;
  final String capacity;

  /// Localized by the host app, including currency and estimate qualifiers.
  final String price;
  final String description;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(RydViaSpacing.s16),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: selected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RydViaRadius.card),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: RydViaSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_outline
                    : Icons.directions_car_outlined,
              ),
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              RydViaPrice(formatted: price),
            ],
          ),
          const SizedBox(height: RydViaSpacing.s8),
          Text('$eta · $capacity'),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

class RydViaPrice extends StatelessWidget {
  const RydViaPrice({super.key, required this.formatted});
  final String formatted;
  @override
  Widget build(BuildContext context) => Text(
    formatted,
    style: RydViaTypography.price.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class RydViaChip extends StatelessWidget {
  const RydViaChip({super.key, required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: RydViaIconSize.small),
    label: Text(label),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RydViaRadius.button),
    ),
  );
}

class RydViaMapControl extends StatelessWidget {
  const RydViaMapControl({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
  );
}

class RydViaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RydViaAppBar({super.key, required this.title, this.actions});
  final String title;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) =>
      AppBar(title: Text(title), actions: actions);
}

abstract final class RydViaBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: RydViaMotion.sheet,
            reverseDuration: RydViaMotion.component,
          ),
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        RydViaSpacing.s20,
        RydViaSpacing.s8,
        RydViaSpacing.s20,
        RydViaSpacing.s24 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: builder(context),
    ),
  );
}

class RydViaDriverCard extends StatelessWidget {
  const RydViaDriverCard({
    super.key,
    required this.name,
    required this.vehicle,
    required this.registration,
    required this.rating,
    this.onContact,
  });
  final String name;
  final String vehicle;
  final String registration;
  final String rating;
  final VoidCallback? onContact;
  @override
  Widget build(BuildContext context) => RydViaCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        Text('$vehicle · $registration'),
        Text('Rating $rating'),
        if (onContact != null)
          TextButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.call_outlined),
            label: const Text('Contact driver'),
          ),
      ],
    ),
  );
}

class RydViaTripCard extends StatelessWidget {
  const RydViaTripCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.formattedPrice,
  });
  final String pickup;
  final String destination;
  final String status;
  final String formattedPrice;
  @override
  Widget build(BuildContext context) => RydViaCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pickup: $pickup'),
        Text('Destination: $destination'),
        RydViaChip(label: status, icon: Icons.route_outlined),
        RydViaPrice(formatted: formattedPrice),
      ],
    ),
  );
}

class RydViaEmptyState extends StatelessWidget {
  const RydViaEmptyState({
    super.key,
    required this.title,
    required this.message,
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(RydViaSpacing.s24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inbox_outlined, size: RydViaIconSize.service),
        const SizedBox(height: RydViaSpacing.s12),
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class RydViaLoadingState extends StatelessWidget {
  const RydViaLoadingState({super.key, this.label = 'Loading'});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.all(RydViaSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (MediaQuery.disableAnimationsOf(context))
            const Icon(Icons.hourglass_empty_outlined)
          else
            CircularProgressIndicator(semanticsLabel: label),
          const SizedBox(height: RydViaSpacing.s12),
          Text(label),
        ],
      ),
    ),
  );
}

class RydViaErrorState extends StatelessWidget {
  const RydViaErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.all(RydViaSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: RydViaSpacing.s12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
