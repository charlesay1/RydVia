import 'package:flutter/material.dart';

/// Development asset slot, not a logo or a reproduction of the custom wordmark.
/// No artwork is loaded until an approved canonical master is integrated.
class RydViaBrandSlot extends StatelessWidget {
  const RydViaBrandSlot({super.key, this.product});
  final String? product;

  @override
  Widget build(BuildContext context) {
    final label = product == null ? 'RydVia' : 'RydVia · $product';
    return Tooltip(
      excludeFromSemantics: true,
      message: 'Development brand placeholder. Official artwork pending.',
      child: Semantics(
        label:
            '$label. Development brand placeholder; official artwork pending.',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('DEV', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
