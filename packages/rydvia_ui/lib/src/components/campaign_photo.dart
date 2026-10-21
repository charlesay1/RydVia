import 'package:flutter/material.dart';
import '../theme/tokens.g.dart';

/// Shared photographic surface. Keep copy outside the image and preserve the
/// full 3:2 source composition on every viewport so faces are not center-cropped.
class RydViaCampaignPhoto extends StatelessWidget {
  const RydViaCampaignPhoto({
    super.key,
    required this.asset,
    this.fallbackIcon = Icons.landscape_outlined,
  });
  final String asset;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 3 / 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final decodeWidth =
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, 1536);
          return Image.asset(
            'assets/photography/$asset.webp',
            package: 'rydvia_ui',
            fit: BoxFit.cover,
            alignment: const Alignment(.3, -.2),
            cacheWidth: decodeWidth,
            excludeFromSemantics: true,
            errorBuilder: (_, error, stack) => ColoredBox(
              color: RydViaColors.midnightNavy,
              child: Center(
                child: Icon(
                  fallbackIcon,
                  size: RydViaSpacing.s48,
                  color: RydViaColors.warmCoral,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
