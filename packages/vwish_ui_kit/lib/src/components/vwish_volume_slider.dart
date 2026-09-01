import 'package:flutter/material.dart';
import '../theme/vwish_theme.dart';

class VwishVolumeSlider extends StatelessWidget {
  final double volume; // 0.0 to 300.0
  final bool muted;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;

  const VwishVolumeSlider({
    super.key,
    required this.volume,
    required this.muted,
    required this.onVolumeChanged,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveVol = muted ? 0.0 : volume;
    final isBoosted = effectiveVol > 100.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            muted || effectiveVol == 0
                ? Icons.volume_off_rounded
                : effectiveVol < 50
                    ? Icons.volume_mute_rounded
                    : effectiveVol <= 100
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
            color: isBoosted ? VwishColors.boostBand : VwishColors.textPrimary,
            size: 20,
          ),
          splashRadius: 18,
          onPressed: onToggleMute,
          tooltip: muted ? 'Unmute (M)' : 'Mute (M)',
        ),
        SizedBox(
          width: 86,
          height: 24,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: isBoosted ? VwishColors.boostBand : VwishColors.primary,
              inactiveTrackColor: VwishColors.trackBackground,
              thumbColor: isBoosted ? VwishColors.boostBand : Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: effectiveVol.clamp(0.0, 300.0),
              min: 0.0,
              max: 300.0,
              onChanged: onVolumeChanged,
            ),
          ),
        ),
        if (isBoosted)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${effectiveVol.round()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: VwishColors.boostBand,
              ),
            ),
          ),
      ],
    );
  }
}
