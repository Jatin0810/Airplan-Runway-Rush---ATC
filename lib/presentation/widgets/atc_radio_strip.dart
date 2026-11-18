import 'package:flutter/material.dart';
import '../../core/audio/atc_sound_manager.dart';
import '../../core/theme/radar_theme.dart';

/// Reusable Bottom ATC Radio Strip with live frequency status and bilingual toggle.
class AtcRadioStrip extends StatefulWidget {
  final RadarTheme theme;
  final String activeMessage;
  final VoidCallback onLanguageToggle;

  const AtcRadioStrip({
    super.key,
    required this.theme,
    required this.activeMessage,
    required this.onLanguageToggle,
  });

  @override
  State<AtcRadioStrip> createState() => _AtcRadioStripState();
}

class _AtcRadioStripState extends State<AtcRadioStrip> {
  bool isMuted = false;

  @override
  Widget build(BuildContext context) {
    final soundMgr = AtcSoundManager();

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.hudSurface,
        border: Border(
          top: BorderSide(color: widget.theme.hudBorder, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status line: Frequency and Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.podcasts, size: 14, color: widget.theme.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      'TOWER FREQ 118.10 MHz',
                      style: TextStyle(
                        color: widget.theme.accentColor,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Bilingual EN / HI Toggle
                    InkWell(
                      onTap: () {
                        soundMgr.toggleLanguage();
                        soundMgr.playVectorAssigned();
                        widget.onLanguageToggle();
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.theme.hudBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          soundMgr.isHindiVoice ? 'हिन्दी' : 'ENGLISH',
                          style: TextStyle(
                            color: widget.theme.textPrimary,
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mute / Unmute
                    InkWell(
                      onTap: () {
                        setState(() {
                          isMuted = !isMuted;
                          soundMgr.setMuted(isMuted);
                          if (!isMuted) {
                            soundMgr.playAircraftSelected();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.theme.hudBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 15,
                          color: isMuted ? Colors.redAccent : widget.theme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ATC Dialogue Box (Interactive: Tap to hear radio audio)
            InkWell(
              onTap: () {
                soundMgr.playVectorAssigned();
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: widget.theme.airspaceBackground.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.theme.hudBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '"${widget.activeMessage}"',
                        style: TextStyle(
                          color: widget.theme.textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.volume_up,
                      size: 14,
                      color: widget.theme.accentColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

