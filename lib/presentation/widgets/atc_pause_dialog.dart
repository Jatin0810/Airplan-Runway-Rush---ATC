import 'package:flutter/material.dart';
import '../../core/audio/atc_sound_manager.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/airport.dart';

class AtcPauseDialog extends StatefulWidget {
  final RadarTheme theme;
  final AirportData airport;
  final int landings;
  final int score;
  final int activeAircraftCount;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const AtcPauseDialog({
    super.key,
    required this.theme,
    required this.airport,
    required this.landings,
    required this.score,
    required this.activeAircraftCount,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  @override
  State<AtcPauseDialog> createState() => _AtcPauseDialogState();
}

class _AtcPauseDialogState extends State<AtcPauseDialog> {
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _isMuted = AtcSoundManager().isMuted;
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      AtcSoundManager().setMuted(_isMuted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.hudSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentColor,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.accentColor.withValues(alpha: 0.22),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Pause Icon & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 32,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'RADAR PAUSED',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.airport.name} (${widget.airport.iata})',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 18),

            // Live Airspace Stats Grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.airspaceBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.hudBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        theme: theme,
                        label: 'LANDED',
                        value: '${widget.landings} / ${widget.airport.targetLandings}',
                        valueColor: AtcColors.ilsActiveGreen,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: theme.hudBorder,
                      ),
                      _StatColumn(
                        theme: theme,
                        label: 'SCORE',
                        value: '${widget.score}',
                        valueColor: theme.accentColor,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: theme.hudBorder,
                      ),
                      _StatColumn(
                        theme: theme,
                        label: 'IN SECTOR',
                        value: '${widget.activeAircraftCount}',
                        valueColor: theme.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: theme.hudBorder, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE RUNWAY: ${widget.airport.activeRunwayId}',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'WIND: ${widget.airport.windHeadingDeg.toInt()}° / ${widget.airport.windSpeedKnots.toInt()}KT',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sound / TTS Mute Toggle Bar
            InkWell(
              onTap: _toggleMute,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.hudBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isMuted
                        ? AtcColors.tcasWarningYellow.withValues(alpha: 0.5)
                        : theme.hudBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          size: 16,
                          color: _isMuted
                              ? AtcColors.tcasWarningYellow
                              : theme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ATC RADIO & VOICE AUDIO',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _isMuted ? 'MUTED' : 'ACTIVE',
                      style: TextStyle(
                        color: _isMuted
                            ? AtcColors.tcasWarningYellow
                            : AtcColors.ilsActiveGreen,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Primary Action: Resume Airspace
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: widget.onResume,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text(
                  'RESUME RADAR CONTACT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Actions: Restart & Exit
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.hudBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: widget.onRestart,
                      icon: Icon(Icons.refresh_rounded, size: 16, color: theme.textSecondary),
                      label: Text(
                        'RESTART',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.hudBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: widget.onExit,
                      icon: Icon(Icons.exit_to_app_rounded, size: 16, color: theme.textSecondary),
                      label: Text(
                        'SECTORS',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final RadarTheme theme;
  final String label;
  final String value;
  final Color valueColor;

  const _StatColumn({
    required this.theme,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

