class GamificationRules {
  GamificationRules._();

  static const int xpPerLevel = 100;

  static int levelOf(int xp) => (xp ~/ xpPerLevel) + 1;

  static int xpInCurrentLevel(int xp) => xp % xpPerLevel;

  static int xpToNextLevel(int xp) => xpPerLevel - (xp % xpPerLevel);

  static double progressInLevel(int xp) {
    return (xp % xpPerLevel) / xpPerLevel;
  }
}
