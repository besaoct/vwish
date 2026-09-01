import 'package:flutter/material.dart';
import 'package:vwish_domain/vwish_domain.dart';
import '../theme/vwish_theme.dart';

class VwishSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final List<Chapter> chapters;
  final AbLoop? abLoop;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration>? onSeeking;

  const VwishSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.buffer,
    this.chapters = const [],
    this.abLoop,
    required this.onSeek,
    this.onSeeking,
  });

  @override
  State<VwishSeekBar> createState() => _VwishSeekBarState();
}

class _VwishSeekBarState extends State<VwishSeekBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _isHovering = false;
  double _hoverFraction = 0.0;

  @override
  Widget build(BuildContext context) {
    final durMs = widget.duration.inMilliseconds;
    final posMs = widget.position.inMilliseconds;
    final bufMs = widget.buffer.inMilliseconds;

    final playedFraction = durMs > 0
        ? (_isDragging ? _dragValue : (posMs / durMs).clamp(0.0, 1.0))
        : 0.0;
    final bufferFraction = durMs > 0 ? (bufMs / durMs).clamp(0.0, 1.0) : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localX = event.localPosition.dx;
          final width = box.size.width;
          if (width > 0) {
            setState(() {
              _hoverFraction = (localX / width).clamp(0.0, 1.0);
            });
          }
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) {
          setState(() {
            _isDragging = true;
            _updateFraction(details.localPosition.dx);
          });
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            _updateFraction(details.localPosition.dx);
          });
          if (widget.onSeeking != null && durMs > 0) {
            widget.onSeeking!(Duration(milliseconds: (_dragValue * durMs).round()));
          }
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          if (durMs > 0) {
            widget.onSeek(Duration(milliseconds: (_dragValue * durMs).round()));
          }
        },
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.size.width > 0) {
            final fraction = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
            if (durMs > 0) {
              widget.onSeek(Duration(milliseconds: (fraction * durMs).round()));
            }
          }
        },
        child: SizedBox(
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Track Background & Chapters
              CustomPaint(
                size: const Size(double.infinity, 28),
                painter: _SeekBarPainter(
                  playedFraction: playedFraction,
                  bufferFraction: bufferFraction,
                  chapters: widget.chapters,
                  duration: widget.duration,
                  abLoop: widget.abLoop,
                  isHovering: _isHovering || _isDragging,
                  hoverFraction: _hoverFraction,
                ),
              ),

              // Hover Time Popup Capsule
              if ((_isHovering || _isDragging) && durMs > 0)
                Positioned(
                  left: ((_isDragging ? _dragValue : _hoverFraction) * (MediaQuery.of(context).size.width - 40)).clamp(30.0, MediaQuery.of(context).size.width - 90),
                  bottom: 22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: VwishColors.surfaceElevatedHigher,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: VwishColors.borderBright, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatDuration(Duration(
                        milliseconds: (((_isDragging ? _dragValue : _hoverFraction) * durMs).round()),
                      )),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateFraction(double localDx) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.size.width > 0) {
      _dragValue = (localDx / box.size.width).clamp(0.0, 1.0);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SeekBarPainter extends CustomPainter {
  final double playedFraction;
  final double bufferFraction;
  final List<Chapter> chapters;
  final Duration duration;
  final AbLoop? abLoop;
  final bool isHovering;
  final double hoverFraction;

  _SeekBarPainter({
    required this.playedFraction,
    required this.bufferFraction,
    required this.chapters,
    required this.duration,
    this.abLoop,
    required this.isHovering,
    required this.hoverFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = isHovering ? 6.0 : 4.0;
    final yCenter = size.height / 2;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, yCenter - trackHeight / 2, size.width, trackHeight),
      const Radius.circular(3),
    );

    // 1. Inactive Track
    final bgPaint = Paint()..color = VwishColors.trackBackground;
    canvas.drawRRect(trackRect, bgPaint);

    // 2. A-B Loop highlight band
    if (abLoop != null && duration.inMilliseconds > 0) {
      final aFrac = (abLoop!.a.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      final bFrac = abLoop!.b != null
          ? (abLoop!.b!.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 1.0;
      final loopPaint = Paint()..color = VwishColors.cyan.withValues(alpha: 0.35);
      final loopRect = Rect.fromLTWH(
        aFrac * size.width,
        yCenter - trackHeight / 2,
        (bFrac - aFrac) * size.width,
        trackHeight,
      );
      canvas.drawRect(loopRect, loopPaint);
    }

    // 3. Buffered Track
    if (bufferFraction > 0) {
      final bufRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, yCenter - trackHeight / 2, size.width * bufferFraction, trackHeight),
        const Radius.circular(3),
      );
      final bufPaint = Paint()..color = VwishColors.bufferTrack;
      canvas.drawRRect(bufRect, bufPaint);
    }

    // 4. Played Track with Gradient
    if (playedFraction > 0) {
      final playedWidth = size.width * playedFraction;
      final playedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, yCenter - trackHeight / 2, playedWidth, trackHeight),
        const Radius.circular(3),
      );
      final playedPaint = Paint()
        ..shader = const LinearGradient(
          colors: [VwishColors.primary, VwishColors.cyan],
        ).createShader(Rect.fromLTWH(0, 0, playedWidth, trackHeight));
      canvas.drawRRect(playedRect, playedPaint);
    }

    // 5. Chapter Break Ticks
    if (chapters.isNotEmpty && duration.inMilliseconds > 0) {
      final tickPaint = Paint()
        ..color = VwishColors.background
        ..strokeWidth = 2.0;
      for (final ch in chapters) {
        if (ch.start > Duration.zero) {
          final frac = ch.start.inMilliseconds / duration.inMilliseconds;
          final x = frac * size.width;
          canvas.drawLine(
            Offset(x, yCenter - trackHeight / 2 - 1),
            Offset(x, yCenter + trackHeight / 2 + 1),
            tickPaint,
          );
        }
      }
    }

    // 6. Thumb Handle
    if (isHovering || playedFraction > 0) {
      final thumbRadius = isHovering ? 6.5 : 4.5;
      final thumbX = size.width * playedFraction;
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(thumbX, yCenter), thumbRadius + 1, shadowPaint);

      final thumbPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(thumbX, yCenter), thumbRadius, thumbPaint);

      final innerPaint = Paint()..color = VwishColors.primary;
      canvas.drawCircle(Offset(thumbX, yCenter), thumbRadius - 2.5, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SeekBarPainter oldDelegate) {
    return oldDelegate.playedFraction != playedFraction ||
        oldDelegate.bufferFraction != bufferFraction ||
        oldDelegate.isHovering != isHovering ||
        oldDelegate.hoverFraction != hoverFraction ||
        oldDelegate.abLoop != abLoop;
  }
}
