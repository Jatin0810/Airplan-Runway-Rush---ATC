import 'package:flutter/material.dart';
import '../models/aircraft.dart';
import '../models/airport.dart';

class AirportRepository {
  static final List<AirportData> stages = [
    // Stage 1: Surat International Airport
    const AirportData(
      code: 'VASU',
      iata: 'STV',
      name: 'Surat International Airport',
      city: 'Surat, Gujarat',
      stageNumber: 1,
      targetLandings: 20,
      windHeadingDeg: 220,
      windSpeedKnots: 8,
      activeRunwayId: '22',
      description: 'Single commercial runway 04/22. Ideal entry training airspace for new controllers.',
      runways: [
        RunwayData(
          id: '04/22',
          activeThresholdId: '22',
          headingDeg: 40.0,
          lengthMeters: 2905,
          lengthPixels: 200,
          widthPixels: 14,
          allowedCategories: [
            AircraftCategory.narrowBody,
            AircraftCategory.turboprop,
            AircraftCategory.militaryFighter,
          ],
        ),
      ],
      helipads: [
        HelipadData(id: 'H1', offset: Offset(-60, 50)),
      ],
    ),

    // Stage 2: Sardar Vallabhbhai Patel International Airport
    const AirportData(
      code: 'VAAH',
      iata: 'AMD',
      name: 'Sardar Vallabhbhai Patel International',
      city: 'Ahmedabad, Gujarat',
      stageNumber: 2,
      targetLandings: 25,
      windHeadingDeg: 230,
      windSpeedKnots: 11,
      activeRunwayId: '23',
      description: 'High-density single runway with parallel rapid-exit taxiways.',
      runways: [
        RunwayData(
          id: '05/23',
          activeThresholdId: '23',
          headingDeg: 50.0,
          lengthMeters: 3505,
          lengthPixels: 220,
          widthPixels: 15,
          allowedCategories: [
            AircraftCategory.narrowBody,
            AircraftCategory.wideBodyHeavy,
            AircraftCategory.turboprop,
            AircraftCategory.militaryFighter,
          ],
        ),
      ],
      helipads: [
        HelipadData(id: 'H1', offset: Offset(-70, -50)),
      ],
    ),

    // Stage 3: Chhatrapati Shivaji Maharaj International Airport (MUMBAI) - THE HERO STAGE
    const AirportData(
      code: 'VABB',
      iata: 'BOM',
      name: 'Chhatrapati Shivaji Maharaj International',
      city: 'Mumbai, Maharashtra',
      stageNumber: 3,
      targetLandings: 35,
      windHeadingDeg: 270,
      windSpeedKnots: 14,
      activeRunwayId: '27',
      hasTakeoffRunway: true,
      description: 'Triple runway operation: Main 09/27 (Heavies), Cross 14/32 (Regional/IAF), and 3rd Runway 22L (Take-Off / Departures) + Helipads.',
      runways: [
        // Primary Main Runway 09/27 (Horizontal East-West): Accepts HEAVIES (B777) & standard jets
        RunwayData(
          id: '09/27',
          activeThresholdId: '27',
          headingDeg: 0.0,
          lengthMeters: 3660,
          lengthPixels: 235,
          widthPixels: 17,
          ilsConeLength: 160,
          allowedCategories: [
            AircraftCategory.wideBodyHeavy, // Big International Planes
            AircraftCategory.narrowBody,
            AircraftCategory.turboprop,
            AircraftCategory.militaryFighter,
          ],
        ),
        // Secondary Cross Runway 14/32 (Diagonal 45°): Mini runway for Regional, Narrow-body, and IAF Fighters.
        // HEAVIES ARE STRICTLY PROHIBITED DUE TO RUNWAY LENGTH!
        RunwayData(
          id: '14/32',
          activeThresholdId: '14',
          headingDeg: 45.0,
          lengthMeters: 2990,
          lengthPixels: 180,
          widthPixels: 13,
          ilsConeLength: 130,
          allowedCategories: [
            AircraftCategory.narrowBody,
            AircraftCategory.turboprop,
            AircraftCategory.militaryFighter,
            // Notice: wideBodyHeavy is NOT in allowedCategories!
          ],
        ),
        // 3rd Runway: Dedicated Departure & Take-Off Runway 22L
        RunwayData(
          id: '04R/22L',
          activeThresholdId: '22L',
          headingDeg: 60.0,
          lengthMeters: 2600,
          centerOffset: Offset(30, -55),
          lengthPixels: 165,
          widthPixels: 13,
          isTakeoffOnly: true,
          allowedCategories: [
            AircraftCategory.narrowBody,
            AircraftCategory.wideBodyHeavy,
            AircraftCategory.turboprop,
            AircraftCategory.militaryFighter,
          ],
        ),
      ],
      helipads: [
        HelipadData(id: 'H1', offset: Offset(-80, 65), radius: 15),
        HelipadData(id: 'H2', offset: Offset(80, -65), radius: 15),
      ],
    ),

    // Stage 4: Pune Airport
    const AirportData(
      code: 'VAPO',
      iata: 'PNQ',
      name: 'Pune Airport (Lohegaon)',
      city: 'Pune, Maharashtra',
      stageNumber: 4,
      targetLandings: 30,
      windHeadingDeg: 280,
      windSpeedKnots: 10,
      activeRunwayId: '28',
      description: 'Joint civil enclave and Indian Air Force airbase with single runway 10/28.',
      runways: [
        RunwayData(
          id: '10/28',
          activeThresholdId: '28',
          headingDeg: 100.0,
          lengthMeters: 2535,
          lengthPixels: 190,
          widthPixels: 14,
        ),
      ],
      helipads: [
        HelipadData(id: 'H1', offset: Offset(60, -50)),
      ],
    ),

    // Stage 5: Kempegowda International Airport (Bengaluru)
    const AirportData(
      code: 'VOBL',
      iata: 'BLR',
      name: 'Kempegowda International Airport',
      city: 'Bengaluru, Karnataka',
      stageNumber: 5,
      targetLandings: 35,
      windHeadingDeg: 270,
      windSpeedKnots: 12,
      activeRunwayId: '27R',
      description: 'Dual parallel independent runways (09L/27R & 09R/27L) allowing simultaneous approaches.',
      runways: [
        RunwayData(
          id: '09L/27R',
          activeThresholdId: '27R',
          headingDeg: 0.0,
          lengthMeters: 4000,
          centerOffset: Offset(0, -35),
          lengthPixels: 220,
          widthPixels: 14,
        ),
        RunwayData(
          id: '09R/27L',
          activeThresholdId: '27L',
          headingDeg: 0.0,
          lengthMeters: 4000,
          centerOffset: Offset(0, 35),
          lengthPixels: 220,
          widthPixels: 14,
        ),
      ],
      helipads: [
        HelipadData(id: 'H1', offset: Offset(-90, 70)),
      ],
    ),

    // Stage 6: Indira Gandhi International Airport (Delhi)
    const AirportData(
      code: 'VIDP',
      iata: 'DEL',
      name: 'Indira Gandhi International Airport',
      city: 'New Delhi, NCR',
      stageNumber: 6,
      targetLandings: 40,
      windHeadingDeg: 280,
      windSpeedKnots: 15,
      activeRunwayId: '28',
      description: 'India\'s busiest aviation hub with 4 active runways. The ultimate air traffic controller challenge.',
      runways: [
        RunwayData(
          id: '10/28',
          activeThresholdId: '28',
          headingDeg: 100.0,
          lengthMeters: 3810,
          centerOffset: Offset(-10, -40),
          lengthPixels: 230,
          widthPixels: 15,
        ),
        RunwayData(
          id: '11L/29R',
          activeThresholdId: '29R',
          headingDeg: 110.0,
          lengthMeters: 4430,
          centerOffset: Offset(10, 20),
          lengthPixels: 240,
          widthPixels: 16,
        ),
        RunwayData(
          id: '09/27',
          activeThresholdId: '27',
          headingDeg: 90.0,
          lengthMeters: 2816,
          centerOffset: Offset(-20, 70),
          lengthPixels: 180,
          widthPixels: 13,
        ),
      ],
      helipads: [
        HelipadData(id: 'H1', offset: Offset(-90, -70)),
      ],
    ),
  ];

  static AirportData getAirportByCode(String code) {
    return stages.firstWhere(
      (a) => a.code == code,
      orElse: () => stages[2], // Default Mumbai
    );
  }
}
