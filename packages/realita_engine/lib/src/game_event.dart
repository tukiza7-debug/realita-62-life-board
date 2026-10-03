/// Engine event types. The engine emits these as it resolves a turn;
/// the UI consumes them to drive animations and the Game Log.
library;

import 'package:realita_engine/src/models.dart';
import 'package:realita_engine/src/seeded_rng.dart';

sealed class GameEvent {
  final int playerIdx;
  const GameEvent._(this.playerIdx);

  @override
  String toString() => runtimeType.toString();
}

class Payday extends GameEvent {
  final Career career;
  final double amount;
  final double tapera;
  const Payday(int p, this.career, this.amount, this.tapera) : super._(p);
}

class PaydaySkipped extends GameEvent {
  const PaydaySkipped(int p) : super._(p);
}

class LivingCost extends GameEvent {
  final double amount;
  const LivingCost(int p, this.amount) : super._(p);
}

class UktInterest extends GameEvent {
  final double amount;
  const UktInterest(int p, this.amount) : super._(p);
}

class KprInterest extends GameEvent {
  final String assetId;
  final double amount;
  const KprInterest(int p, this.assetId, this.amount) : super._(p);
}

class PinjolInterest extends GameEvent {
  final double amount;
  const PinjolInterest(int p, this.amount) : super._(p);
}

class SideBusinessPaid extends GameEvent {
  final double amount;
  const SideBusinessPaid(int p, this.amount) : super._(p);
}

class SideBusinessEnded extends GameEvent {
  const SideBusinessEnded(int p) : super._(p);
}

class FuelSubsidyEnded extends GameEvent {
  const FuelSubsidyEnded(int p) : super._(p);
}

class LandlordRentEnded extends GameEvent {
  const LandlordRentEnded(int p) : super._(p);
}

class CheapRentEnded extends GameEvent {
  const CheapRentEnded(int p) : super._(p);
}

class StoleProjectFunds extends GameEvent {
  final double amount;
  final int newHeat;
  const StoleProjectFunds(int p, this.amount, this.newHeat) : super._(p);
}

class KpkStingMiss extends GameEvent {
  const KpkStingMiss(int p) : super._(p);
}

class KpkStingCaught extends GameEvent {
  final double cashLost;
  const KpkStingCaught(int p, this.cashLost) : super._(p);
}

class Married extends GameEvent {
  final bool lavish;
  final double cost;
  final int happiness;
  const Married(int p, this.lavish, this.cost, this.happiness) : super._(p);
}

class ChildBorn extends GameEvent {
  final String childId;
  const ChildBorn(int p, this.childId) : super._(p);
}

class SchoolFunded extends GameEvent {
  final int childIdx;
  final bool private;
  final double cost;
  const SchoolFunded(int p, this.childIdx, this.private, this.cost)
      : super._(p);
}

class EnteredPoliticianPath extends GameEvent {
  final bool corrupt;
  final double dowry;
  const EnteredPoliticianPath(int p, this.corrupt, this.dowry) : super._(p);
}

class PoliticianEntryFailed extends GameEvent {
  final String reason;
  const PoliticianEntryFailed(int p, this.reason) : super._(p);
}

class NepotismPerk extends GameEvent {
  final double gain;
  const NepotismPerk(int p, this.gain) : super._(p);
}

class Retired extends GameEvent {
  final RetirementChoice choice;
  final double score;
  final bool wargaTeladan;
  const Retired(int p, this.choice, this.score, this.wargaTeladan)
      : super._(p);
}

class CardDrawn extends GameEvent {
  final String cardId;
  final bool isLuck;
  const CardDrawn(int p, this.cardId, this.isLuck) : super._(p);
}

class CashDelta extends GameEvent {
  final double amount;
  final String reason;
  const CashDelta(int p, this.amount, this.reason) : super._(p);
}

class HappinessDelta extends GameEvent {
  final int delta;
  final String reason;
  const HappinessDelta(int p, this.delta, this.reason) : super._(p);
}

class SkipTurn extends GameEvent {
  final int laps;
  const SkipTurn(int p, this.laps) : super._(p);
}

class Moved extends GameEvent {
  final int fromTile;
  final int toTile;
  const Moved(int p, this.fromTile, this.toTile) : super._(p);
}

class LapCompleted extends GameEvent {
  final int laps;
  const LapCompleted(int p, this.laps) : super._(p);
}

class AssetPurchased extends GameEvent {
  final String assetId;
  final String name;
  const AssetPurchased(int p, this.assetId, this.name) : super._(p);
}

class TokenAwarded extends GameEvent {
  final String token;
  const TokenAwarded(int p, this.token) : super._(p);
}

class LoanTaken extends GameEvent {
  final double principal;
  final double interestPct;
  const LoanTaken(int p, this.principal, this.interestPct) : super._(p);
}

class DebtFlagged extends GameEvent {
  final String flag;
  const DebtFlagged(int p, this.flag) : super._(p);
}

class EmptyEvent extends GameEvent {
  static const EmptyEvent instance = EmptyEvent._();
  const EmptyEvent._() : super._(-1);
}
