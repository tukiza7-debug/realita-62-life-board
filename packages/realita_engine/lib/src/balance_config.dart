/// Game-wide balance config. Mirrors the Kotlin `BalanceConfig` exactly so
/// that the Dart engine produces identical results to the Kotlin reference
/// for the same seed.
library;

class BalanceConfig {
  final double baseLivingCostPerLap;
  final double perChildLivingCost;
  final double ppnPct;
  final double taperaPct;
  final double uktInterestPerLapPct;
  final double kprInterestBasePerLapPct;
  final double pinjolInterestPerLapPct;
  final double fuelSubsidyExtraPerRoll;
  final int fuelSubsidyLaps;
  final double savingsBufferThreshold;
  final double badLuckCashReductionPct;
  final double goodLuckCashCap;
  final int maxGoodLuckPerLap;
  final double kpkStingChancePerHeatPct;
  final double kpkStingCaughtCashLossPct;
  final int kpkStingCaughtHeatLoss;
  final int kpkStingCaughtSkips;
  final int cleanHappinessBonus;
  final double sideBusinessIncomePerLap;
  final int sideBusinessLaps;
  final double sideBusinessFlopChance;
  final double legacyPerFundedChild;
  final double legacyPerUnfundedChild;
  final double happinessValueInScore;
  final double partyDowry;
  final double modestWeddingCost;
  final int modestWeddingHappiness;
  final double lavishWeddingCost;
  final int lavishWeddingHappiness;
  final double enterCorruptTheftPerLap;
  final int enterCorruptHeatPerTheft;
  final int corruptRouteFinalHappinessThreshold;
  final int corruptRouteFinalScoreDivider;
  final int boardSize;

  const BalanceConfig({
    this.baseLivingCostPerLap = 3.0,
    this.perChildLivingCost = 1.5,
    this.ppnPct = 0.12,
    this.taperaPct = 0.03,
    this.uktInterestPerLapPct = 0.02,
    this.kprInterestBasePerLapPct = 0.03,
    this.pinjolInterestPerLapPct = 0.15,
    this.fuelSubsidyExtraPerRoll = 0.2,
    this.fuelSubsidyLaps = 3,
    this.savingsBufferThreshold = 10.0,
    this.badLuckCashReductionPct = 0.25,
    this.goodLuckCashCap = 5.0,
    this.maxGoodLuckPerLap = 2,
    this.kpkStingChancePerHeatPct = 0.10,
    this.kpkStingCaughtCashLossPct = 0.50,
    this.kpkStingCaughtHeatLoss = 20,
    this.kpkStingCaughtSkips = 2,
    this.cleanHappinessBonus = 5,
    this.sideBusinessIncomePerLap = 2.0,
    this.sideBusinessLaps = 3,
    this.sideBusinessFlopChance = 0.25,
    this.legacyPerFundedChild = 3.0,
    this.legacyPerUnfundedChild = 0.5,
    this.happinessValueInScore = 0.5,
    this.partyDowry = 15.0,
    this.modestWeddingCost = 1.0,
    this.modestWeddingHappiness = 8,
    this.lavishWeddingCost = 8.0,
    this.lavishWeddingHappiness = 25,
    this.enterCorruptTheftPerLap = 6.0,
    this.enterCorruptHeatPerTheft = 1,
    this.corruptRouteFinalHappinessThreshold = 0,
    this.corruptRouteFinalScoreDivider = 2,
    this.boardSize = 60,
  });

  static const BalanceConfig defaultConfig = BalanceConfig();
}
