import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/airport_repository.dart';
import 'atc_gameplay_screen.dart';

class AirportSelectScreen extends StatelessWidget {
  const AirportSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = RadarThemeScope.of(context);
    final stages = AirportRepository.stages;

    return Scaffold(
      backgroundColor: theme.airspaceBackground,
      appBar: AppBar(
        backgroundColor: theme.hudSurface,
        elevation: 0,
        title: Text(
          'INDIAN AIRPORTS & SECTORS',
          style: TextStyle(
            color: theme.accentColor,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.1,
          ),
        ),
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final airport = stages[index];
          final isHeroStage = airport.iata == 'BOM';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.hudSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHeroStage ? theme.accentColor : theme.hudBorder,
                width: isHeroStage ? 1.6 : 1.0,
              ),
              boxShadow: isHeroStage
                  ? [
                      BoxShadow(
                        color: theme.accentColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AtcGameplayScreen(airport: airport),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.accentColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  airport.iata,
                                  style: TextStyle(
                                    color: theme.accentColor,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STAGE ${airport.stageNumber}: ${airport.city}',
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    airport.code,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.ilsConeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: theme.ilsConeColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'RWY ${airport.activeRunwayId}',
                              style: TextStyle(
                                color: theme.ilsConeColor,
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        airport.description,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TARGET LANDINGS: ${airport.targetLandings}',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'OPEN RADAR',
                                style: TextStyle(
                                  color: theme.accentColor,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: theme.accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
