import 'package:flutter/material.dart';

class LightProfile {
  final String id;
  final String name;
  final String title;
  final String perk;
  final String assetPath;
  final Color primaryColor;
  final Color glowColor;

  const LightProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.perk,
    required this.assetPath,
    required this.primaryColor,
    required this.glowColor,
  });
}

class HeavyProfile {
  final String id;
  final String name;
  final String title;
  final String perk;
  final String assetPath;
  final Color primaryColor;
  final Color glowColor;

  const HeavyProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.perk,
    required this.assetPath,
    required this.primaryColor,
    required this.glowColor,
  });
}

class BackgroundThemeOption {
  final String id;
  final String name;
  final String subtitle;
  final String assetPath;
  final Color skyTint;
  final Color accentColor;
  final Color platformTopColor;
  final Color platformBodyColor;

  const BackgroundThemeOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.assetPath,
    required this.skyTint,
    required this.accentColor,
    required this.platformTopColor,
    required this.platformBodyColor,
  });
}

enum TetherPattern { plasma, steel, magChain, runic }

class TetherStyleOption {
  final String id;
  final String name;
  final String subtitle;
  final Color primaryColor;
  final Color pulseColor;
  final TetherPattern pattern;

  const TetherStyleOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primaryColor,
    required this.pulseColor,
    required this.pattern,
  });
}

class PilotBadgeOption {
  final String id;
  final String name;
  final String callsign;
  final IconData icon;
  final Color badgeColor;

  const PilotBadgeOption({
    required this.id,
    required this.name,
    required this.callsign,
    required this.icon,
    required this.badgeColor,
  });
}

class CustomizationCatalog {
  static const List<LightProfile> lightProfiles = [
    LightProfile(
      id: 'aero_wisp',
      name: 'Aero-Wisp',
      title: 'Cyan Sky-Glider',
      perk: 'Aerodynamic Delta Wings',
      assetPath: 'assets/images/profiles/light_aero_wisp.png',
      primaryColor: Color(0xFF38BDF8),
      glowColor: Color(0xFF22D3EE),
    ),
    LightProfile(
      id: 'volt_sprite',
      name: 'Volt-Sprite',
      title: 'Emerald Cyber-Acrobat',
      perk: 'Plasma Arc Thrusters',
      assetPath: 'assets/images/profiles/light_volt_sprite.png',
      primaryColor: Color(0xFF34D399),
      glowColor: Color(0xFF6EE7B7),
    ),
    LightProfile(
      id: 'solar_falcon',
      name: 'Solar-Falcon',
      title: 'Phoenix Jet-Runner',
      perk: 'Solar Flare Plume',
      assetPath: 'assets/images/profiles/light_solar_falcon.png',
      primaryColor: Color(0xFFFBBF24),
      glowColor: Color(0xFFFB7185),
    ),
    LightProfile(
      id: 'nebula_lynx',
      name: 'Nebula-Lynx',
      title: 'Void Stealth Dasher',
      perk: 'Starlight Drift Trail',
      assetPath: 'assets/images/profiles/light_nebula_lynx.png',
      primaryColor: Color(0xFFE879F9),
      glowColor: Color(0xFFC084FC),
    ),
  ];

  static const List<HeavyProfile> heavyProfiles = [
    HeavyProfile(
      id: 'titan_core',
      name: 'Titan-Core',
      title: 'Amber Mech-Golem',
      perk: 'Twin Gyro Stabilizers',
      assetPath: 'assets/images/profiles/heavy_titan_core.png',
      primaryColor: Color(0xFFFB923C),
      glowColor: Color(0xFFFBBF24),
    ),
    HeavyProfile(
      id: 'bastion_mk4',
      name: 'Bastion-MK4',
      title: 'Cobalt Tank Automaton',
      perk: 'Reinforced Hydraulic Hull',
      assetPath: 'assets/images/profiles/heavy_bastion_mk4.png',
      primaryColor: Color(0xFF60A5FA),
      glowColor: Color(0xFF93C5FD),
    ),
    HeavyProfile(
      id: 'magma_atlas',
      name: 'Magma-Atlas',
      title: 'Volcanic Forge Colossus',
      perk: 'Molten Core Reactor',
      assetPath: 'assets/images/profiles/heavy_magma_atlas.png',
      primaryColor: Color(0xFFF43F5E),
      glowColor: Color(0xFFF97316),
    ),
    HeavyProfile(
      id: 'jade_bulwark',
      name: 'Jade-Bulwark',
      title: 'Ancient Temple Guardian',
      perk: 'Runic Gravity Chassis',
      assetPath: 'assets/images/profiles/heavy_jade_bulwark.png',
      primaryColor: Color(0xFF34D399),
      glowColor: Color(0xFFFBBF24),
    ),
  ];

  static const List<BackgroundThemeOption> backgrounds = [
    BackgroundThemeOption(
      id: 'canyon_twilight',
      name: 'Twilight Canyon',
      subtitle: 'Starry Violet Chasm',
      assetPath: 'assets/images/backgrounds/bg_1.png',
      skyTint: Color(0xFF1E1B4B),
      accentColor: Color(0xFF38BDF8),
      platformTopColor: Color(0xFF475569),
      platformBodyColor: Color(0xFF1E293B),
    ),
    BackgroundThemeOption(
      id: 'emerald_sky',
      name: 'Emerald Spires',
      subtitle: 'Sunlit Jade Peaks',
      assetPath: 'assets/images/backgrounds/bg_2.png',
      skyTint: Color(0xFF064E3B),
      accentColor: Color(0xFF34D399),
      platformTopColor: Color(0xFF059669),
      platformBodyColor: Color(0xFF064E3B),
    ),
    BackgroundThemeOption(
      id: 'sunset_mesa',
      name: 'Sunset Mesa',
      subtitle: 'Amber Sandstone Gorge',
      assetPath: 'assets/images/backgrounds/bg_3.png',
      skyTint: Color(0xFF7C2D12),
      accentColor: Color(0xFFFBBF24),
      platformTopColor: Color(0xFFD97706),
      platformBodyColor: Color(0xFF451A03),
    ),
    BackgroundThemeOption(
      id: 'biolum_abyss',
      name: 'Crystal Abyss',
      subtitle: 'Subterranean Biolume',
      assetPath: 'assets/images/backgrounds/bg_4.png',
      skyTint: Color(0xFF082F49),
      accentColor: Color(0xFF22D3EE),
      platformTopColor: Color(0xFF0284C7),
      platformBodyColor: Color(0xFF0F172A),
    ),
  ];

  static const List<TetherStyleOption> tetherStyles = [
    TetherStyleOption(
      id: 'plasma_arc',
      name: 'Plasma Arc',
      subtitle: 'Luminous Energy Beam',
      primaryColor: Color(0xFF38BDF8),
      pulseColor: Color(0xFFFFFFFF),
      pattern: TetherPattern.plasma,
    ),
    TetherStyleOption(
      id: 'braided_steel',
      name: 'Braided Steel',
      subtitle: 'Industrial Alloy Cable',
      primaryColor: Color(0xFF94A3B8),
      pulseColor: Color(0xFFFBBF24),
      pattern: TetherPattern.steel,
    ),
    TetherStyleOption(
      id: 'mag_chain',
      name: 'Mag-Chain',
      subtitle: 'Floating Force Links',
      primaryColor: Color(0xFFA78BFA),
      pulseColor: Color(0xFF38BDF8),
      pattern: TetherPattern.magChain,
    ),
    TetherStyleOption(
      id: 'runic_gold',
      name: 'Runic Filament',
      subtitle: 'Gilded Mystic Thread',
      primaryColor: Color(0xFFFBBF24),
      pulseColor: Color(0xFFFEF08A),
      pattern: TetherPattern.runic,
    ),
  ];

  static const List<PilotBadgeOption> pilotBadges = [
    PilotBadgeOption(
      id: 'vanguard',
      name: 'Vanguard Crest',
      callsign: 'SKY-01',
      icon: Icons.shield_rounded,
      badgeColor: Color(0xFF38BDF8),
    ),
    PilotBadgeOption(
      id: 'apex',
      name: 'Apex Bolt',
      callsign: 'GLIDE-X',
      icon: Icons.bolt_rounded,
      badgeColor: Color(0xFFFBBF24),
    ),
    PilotBadgeOption(
      id: 'nova',
      name: 'Starlight Halo',
      callsign: 'AERO-9',
      icon: Icons.auto_awesome_rounded,
      badgeColor: Color(0xFFE879F9),
    ),
    PilotBadgeOption(
      id: 'anchor',
      name: 'Iron Anchor',
      callsign: 'TITAN-7',
      icon: Icons.anchor_rounded,
      badgeColor: Color(0xFF34D399),
    ),
  ];
}
