import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/player_controller.dart';
import '../controllers/providers.dart';

enum SettingsCategory {
  main,
  video,
  color,
  audio,
  subtitles,
  playback,
  shortcuts,
}

class VwishSettingsPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const VwishSettingsPanel({super.key, required this.onClose});

  @override
  ConsumerState<VwishSettingsPanel> createState() => _VwishSettingsPanelState();
}

class _VwishSettingsPanelState extends ConsumerState<VwishSettingsPanel> {
  SettingsCategory _category = SettingsCategory.main;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final playerCtrl = ref.read(playerControllerProvider.notifier);

    return Container(
      width: 360,
      margin: const EdgeInsets.only(right: 16, bottom: 64),
      child: VwishGlassCard(
        padding: const EdgeInsets.all(0),
        backgroundColor: VwishColors.surfaceElevated.withValues(alpha: 0.96),
        borderColor: VwishColors.borderBright,
        borderRadius: 14,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              const Divider(color: VwishColors.border, height: 1),

              // Content based on category
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: switch (_category) {
                    SettingsCategory.main => _buildMainMenu(state),
                    SettingsCategory.video => _buildVideoMenu(state, playerCtrl),
                    SettingsCategory.color => _buildColorMenu(state, playerCtrl),
                    SettingsCategory.audio => _buildAudioMenu(state, playerCtrl),
                    SettingsCategory.subtitles => _buildSubtitlesMenu(state, playerCtrl),
                    SettingsCategory.playback => _buildPlaybackMenu(state, playerCtrl),
                    SettingsCategory.shortcuts => _buildShortcutsMenu(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = switch (_category) {
      SettingsCategory.main => 'Settings',
      SettingsCategory.video => 'Video Settings',
      SettingsCategory.color => 'Color Adjustments',
      SettingsCategory.audio => 'Audio & 10-Band EQ',
      SettingsCategory.subtitles => 'Subtitle Styling',
      SettingsCategory.playback => 'Playback & Loop',
      SettingsCategory.shortcuts => 'Keyboard Shortcuts',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (_category != SettingsCategory.main)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              splashRadius: 14,
              onPressed: () => setState(() => _category = SettingsCategory.main),
            )
          else
            const Icon(Icons.tune_rounded, size: 18, color: VwishColors.primaryLight),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: VwishColors.textSecondary),
            splashRadius: 14,
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu(PlayerState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuTile(
          icon: Icons.videocam_rounded,
          title: 'Video',
          subtitle: state.transform.aspectOverride ?? 'Auto Aspect / HW Safe',
          onTap: () => setState(() => _category = SettingsCategory.video),
        ),
        _menuTile(
          icon: Icons.palette_rounded,
          title: 'Color Adjustments',
          subtitle: 'Brightness, Contrast, Saturation, Gamma',
          onTap: () => setState(() => _category = SettingsCategory.color),
        ),
        _menuTile(
          icon: Icons.graphic_eq_rounded,
          title: 'Audio & Equalizer',
          subtitle: '10-Band EQ, Night Mode, Normalization',
          onTap: () => setState(() => _category = SettingsCategory.audio),
        ),
        _menuTile(
          icon: Icons.subtitles_rounded,
          title: 'Subtitles',
          subtitle: 'Font, Border, Outline, Delay (${state.subtitleDelay.inMilliseconds}ms)',
          onTap: () => setState(() => _category = SettingsCategory.subtitles),
        ),
        _menuTile(
          icon: Icons.speed_rounded,
          title: 'Playback & A-B Loop',
          subtitle: '${state.speed}x / Loop: ${state.abLoop != null ? 'A-B active' : 'Off'}',
          onTap: () => setState(() => _category = SettingsCategory.playback),
        ),
        _menuTile(
          icon: Icons.keyboard_rounded,
          title: 'Keyboard Shortcuts',
          subtitle: 'Keymap & hotkeys cheat-sheet',
          onTap: () => setState(() => _category = SettingsCategory.shortcuts),
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: VwishColors.primaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: VwishColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: VwishColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoMenu(PlayerState state, PlayerController playerCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aspect Ratio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            _choiceChip('Auto', state.transform.aspectOverride == null, () => playerCtrl.setVideoTransform(state.transform.copyWith(aspectOverride: null))),
            _choiceChip('16:9', state.transform.aspectOverride == '16:9', () => playerCtrl.setVideoTransform(state.transform.copyWith(aspectOverride: '16:9'))),
            _choiceChip('4:3', state.transform.aspectOverride == '4:3', () => playerCtrl.setVideoTransform(state.transform.copyWith(aspectOverride: '4:3'))),
            _choiceChip('2.35:1', state.transform.aspectOverride == '2.35:1', () => playerCtrl.setVideoTransform(state.transform.copyWith(aspectOverride: '2.35:1'))),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Hardware Decode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            _choiceChip('Auto-Safe', true, () {}),
            _choiceChip('Software', false, () {}),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Zoom', style: TextStyle(fontSize: 12, color: Colors.white)),
            Text('${(state.transform.zoom * 100).round()}%', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: state.transform.zoom,
          min: 0.5,
          max: 3.0,
          onChanged: (z) => playerCtrl.setVideoTransform(state.transform.copyWith(zoom: z)),
        ),
      ],
    );
  }

  Widget _buildColorMenu(PlayerState state, PlayerController playerCtrl) {
    return Column(
      children: [
        _sliderRow('Brightness', state.adjust.brightness, -100, 100, (v) => playerCtrl.setVideoAdjust(state.adjust.copyWith(brightness: v))),
        _sliderRow('Contrast', state.adjust.contrast, -100, 100, (v) => playerCtrl.setVideoAdjust(state.adjust.copyWith(contrast: v))),
        _sliderRow('Saturation', state.adjust.saturation, -100, 100, (v) => playerCtrl.setVideoAdjust(state.adjust.copyWith(saturation: v))),
        _sliderRow('Gamma', state.adjust.gamma, -100, 100, (v) => playerCtrl.setVideoAdjust(state.adjust.copyWith(gamma: v))),
        _sliderRow('Hue', state.adjust.hue, -100, 100, (v) => playerCtrl.setVideoAdjust(state.adjust.copyWith(hue: v))),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reset All Colors'),
          onPressed: () => playerCtrl.setVideoAdjust(VideoAdjust.normal),
        ),
      ],
    );
  }

  Widget _buildAudioMenu(PlayerState state, PlayerController playerCtrl) {
    final filter = state.audioFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio Delay
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Audio Delay Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
            Text('${state.audioDelay.inMilliseconds} ms', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: state.audioDelay.inMilliseconds.toDouble(),
          min: -2000.0,
          max: 2000.0,
          divisions: 80,
          onChanged: (ms) => playerCtrl.setAudioDelay(Duration(milliseconds: ms.round())),
        ),
        const SizedBox(height: 12),

        // 10-Band EQ Presets
        const Text('Equalizer Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AudioFilter.presets.keys.map((preset) {
            return _choiceChip(preset, false, () {
              playerCtrl.setAudioFilters(filter.applyPreset(preset));
            });
          }).toList(),
        ),
        const SizedBox(height: 14),

        // 10-Band EQ Sliders
        const Text('10-Band Graphic Equalizer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: filter.equalizerBands.asMap().entries.map((entry) {
              final idx = entry.key;
              final band = entry.value;
              return Column(
                children: [
                  Text(band.label, style: const TextStyle(fontSize: 9, color: VwishColors.textMuted)),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: band.gain,
                        min: -12.0,
                        max: 12.0,
                        onChanged: (g) {
                          final bands = List<EqualizerBand>.from(filter.equalizerBands);
                          bands[idx] = band.copyWith(gain: g);
                          playerCtrl.setAudioFilters(filter.copyWith(equalizerBands: bands));
                        },
                      ),
                    ),
                  ),
                  Text('${band.gain.round()}', style: const TextStyle(fontSize: 8, color: Colors.white)),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // DRC & Normalization switches
        SwitchListTile(
          title: const Text('Night Mode (DRC)', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Compresses loud peaks, boosts quiet dialogue', style: TextStyle(fontSize: 11, color: VwishColors.textMuted)),
          value: filter.nightModeDrc,
          onChanged: (on) => playerCtrl.setAudioFilters(filter.copyWith(nightModeDrc: on)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Loudness Normalization', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Standard -16 LUFS target loudness', style: TextStyle(fontSize: 11, color: VwishColors.textMuted)),
          value: filter.loudnessNormalization,
          onChanged: (on) => playerCtrl.setAudioFilters(filter.copyWith(loudnessNormalization: on)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSubtitlesMenu(PlayerState state, PlayerController playerCtrl) {
    final style = state.subtitleStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle Delay
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtitle Delay Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
            Text('${state.subtitleDelay.inMilliseconds} ms', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: state.subtitleDelay.inMilliseconds.toDouble(),
          min: -5000.0,
          max: 5000.0,
          divisions: 200,
          onChanged: (ms) => playerCtrl.setSubtitleDelay(Duration(milliseconds: ms.round())),
        ),
        const SizedBox(height: 12),

        // Font Size
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Font Size', style: TextStyle(fontSize: 12, color: Colors.white)),
            Text('${style.fontSize.round()} pt', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: style.fontSize,
          min: 24.0,
          max: 96.0,
          onChanged: (s) => playerCtrl.setSubtitleStyle(style.copyWith(fontSize: s)),
        ),
        const SizedBox(height: 8),

        // Border Outline
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Border Outline', style: TextStyle(fontSize: 12, color: Colors.white)),
            Text('${style.borderSize.round()} px', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: style.borderSize,
          min: 0.0,
          max: 8.0,
          onChanged: (b) => playerCtrl.setSubtitleStyle(style.copyWith(borderSize: b)),
        ),
      ],
    );
  }

  Widget _buildPlaybackMenu(PlayerState state, PlayerController playerCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Speed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
            Text('${state.speed}x', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: state.speed,
          min: 0.25,
          max: 3.0,
          divisions: 22,
          onChanged: (s) => playerCtrl.setSpeed(s),
        ),
        const SizedBox(height: 12),
        const Text('A-B Loop Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VwishColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => playerCtrl.setAbLoop(state.position, null),
              child: const Text('Set Point A'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.abLoop != null
                  ? () => playerCtrl.setAbLoop(state.abLoop!.a, state.position)
                  : null,
              child: const Text('Set Point B'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: state.abLoop != null ? () => playerCtrl.setAbLoop(null, null) : null,
              tooltip: 'Clear A-B Loop',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutsMenu() {
    const map = <String, String>{
      'Space / K': 'Play / Pause',
      '← / →': 'Seek ±5 seconds',
      'J / L': 'Seek ±10 seconds',
      '↑ / ↓': 'Volume ±5%',
      'M': 'Toggle Mute',
      'F': 'Toggle Fullscreen',
      'T': 'Pin Always on Top',
      'C': 'Cycle Subtitles',
      '#': 'Cycle Audio Track',
      '[ / ]': 'Speed ±0.1x',
      'I': 'Stats for Nerds HUD',
      'P': 'Queue / Playlist',
      'O': 'Open Video File',
      'Ctrl+,': 'Settings',
    };

    return Column(
      children: map.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VwishColors.surfaceElevatedHigher,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: VwishColors.borderBright, width: 0.8),
                ),
                child: Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VwishColors.cyan)),
              ),
              Text(e.value, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
            Text('${value.round()}', style: const TextStyle(fontSize: 12, color: VwishColors.cyan)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : VwishColors.textSecondary)),
      selected: selected,
      selectedColor: VwishColors.primary,
      backgroundColor: VwishColors.surfaceElevatedHigher,
      onSelected: (_) => onSelected(),
    );
  }
}
