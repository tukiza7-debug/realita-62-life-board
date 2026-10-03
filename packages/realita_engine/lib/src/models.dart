/// All monetary values are stored in **Rupiah millions** (Rp 1M = Rp 1.000.000).
library;

typedef Rp = double; // millions

enum Career {
  ojolDriver('ojol', 4.0, 'Ojol Driver', 'Driver Ojol'),
  dailyWorker('daily', 3.5, 'Daily Worker', 'Pekerja Harian'),
  scbdEmployee('scbd', 12.0, 'SCBD Employee', 'Karyawan SCBD'),
  pns('pns', 9.0, 'Civil Servant (PNS)', 'PNS'),
  contractor('contractor', 8.0, 'Contractor', 'Kontraktor'),
  politicianClean(
      'politician_clean', 7.0, 'Politician (Clean)', 'Politikus (Bersih)'),
  politicianCorrupt(
      'politician_corrupt', 7.0, 'Politician (Corrupt)', 'Politikus (Korupsi)');

  final String id;
  final double grossPayday;
  final String labelEn;
  final String labelId;
  const Career(this.id, this.grossPayday, this.labelEn, this.labelId);

  bool get isPolitician => id.startsWith('politician');
  bool get isCorrupt => this == Career.politicianCorrupt;

  static Career fromId(String id) =>
      Career.values.firstWhere((c) => c.id == id);
}

enum MaritalStatus { single, marriedModest, marriedLavish }

enum EducationPath {
  college('college', 2.0, 10.0),
  smaSmk('sma_smk', 3.0, 0.0);

  final String id;
  final double startingCash;
  final double uktDebt;
  const EducationPath(this.id, this.startingCash, this.uktDebt);

  static EducationPath fromId(String id) =>
      EducationPath.values.firstWhere((p) => p.id == id);
}

enum Route { none, clean, corrupt }

enum RetirementChoice {
  kampungJogja('jogja'),
  islandBali('bali'),
  eliteMenteng('menteng');

  final String id;
  const RetirementChoice(this.id);

  static RetirementChoice fromId(String id) =>
      RetirementChoice.values.firstWhere((r) => r.id == id);
}

class Child {
  final String id;
  final int ageLaps;
  final bool isFunded;
  final bool isPrivateSchool;
  final double legacyFunded;
  final double legacyUnfunded;

  const Child({
    required this.id,
    this.ageLaps = 0,
    this.isFunded = false,
    this.isPrivateSchool = false,
    this.legacyFunded = 0.0,
    this.legacyUnfunded = 0.0,
  });

  Child copyWith({
    String? id,
    int? ageLaps,
    bool? isFunded,
    bool? isPrivateSchool,
    double? legacyFunded,
    double? legacyUnfunded,
  }) =>
      Child(
        id: id ?? this.id,
        ageLaps: ageLaps ?? this.ageLaps,
        isFunded: isFunded ?? this.isFunded,
        isPrivateSchool: isPrivateSchool ?? this.isPrivateSchool,
        legacyFunded: legacyFunded ?? this.legacyFunded,
        legacyUnfunded: legacyUnfunded ?? this.legacyUnfunded,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ageLaps': ageLaps,
        'isFunded': isFunded,
        'isPrivateSchool': isPrivateSchool,
        'legacyFunded': legacyFunded,
        'legacyUnfunded': legacyUnfunded,
      };

  factory Child.fromJson(Map<String, dynamic> j) => Child(
        id: j['id'] as String,
        ageLaps: (j['ageLaps'] as num).toInt(),
        isFunded: j['isFunded'] as bool? ?? false,
        isPrivateSchool: j['isPrivateSchool'] as bool? ?? false,
        legacyFunded: (j['legacyFunded'] as num?)?.toDouble() ?? 0.0,
        legacyUnfunded: (j['legacyUnfunded'] as num?)?.toDouble() ?? 0.0,
      );
}

class Asset {
  final String id;
  final String name;
  final double price;
  double remainingKpr;
  double kprInterestBase; // per-lap fraction (0.03 = 3%)
  int kprInterestBoostLapsLeft;
  bool propertyTaxPaid;

  Asset({
    required this.id,
    required this.name,
    required this.price,
    this.remainingKpr = 0.0,
    this.kprInterestBase = 0.03,
    this.kprInterestBoostLapsLeft = 0,
    this.propertyTaxPaid = false,
  });

  double get downPayment => price * 0.20;
  double get kprPrincipal => price * 0.80;
  double get netValue => price - remainingKpr;
  bool get hasKpr => remainingKpr > 0.001;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'remainingKpr': remainingKpr,
        'kprInterestBase': kprInterestBase,
        'kprInterestBoostLapsLeft': kprInterestBoostLapsLeft,
        'propertyTaxPaid': propertyTaxPaid,
      };

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        remainingKpr: (j['remainingKpr'] as num?)?.toDouble() ?? 0.0,
        kprInterestBase: (j['kprInterestBase'] as num?)?.toDouble() ?? 0.03,
        kprInterestBoostLapsLeft:
            (j['kprInterestBoostLapsLeft'] as num?)?.toInt() ?? 0,
        propertyTaxPaid: j['propertyTaxPaid'] as bool? ?? false,
      );
}

class PlayerTokens {
  int skipTurnLoss;
  int cancelNegativeEvent;
  int waiveNextSchoolFee;
  int clinicCostCancel;

  PlayerTokens({
    this.skipTurnLoss = 0,
    this.cancelNegativeEvent = 0,
    this.waiveNextSchoolFee = 0,
    this.clinicCostCancel = 0,
  });

  Map<String, dynamic> toJson() => {
        'skipTurnLoss': skipTurnLoss,
        'cancelNegativeEvent': cancelNegativeEvent,
        'waiveNextSchoolFee': waiveNextSchoolFee,
        'clinicCostCancel': clinicCostCancel,
      };

  factory PlayerTokens.fromJson(Map<String, dynamic> j) => PlayerTokens(
        skipTurnLoss: (j['skipTurnLoss'] as num?)?.toInt() ?? 0,
        cancelNegativeEvent: (j['cancelNegativeEvent'] as num?)?.toInt() ?? 0,
        waiveNextSchoolFee: (j['waiveNextSchoolFee'] as num?)?.toInt() ?? 0,
        clinicCostCancel: (j['clinicCostCancel'] as num?)?.toInt() ?? 0,
      );
}

class Player {
  int id;
  String name;
  bool isAI;
  Career? career;
  EducationPath? education;
  MaritalStatus maritalStatus;
  List<Child> children;
  Route route;
  double cash;
  int happiness;
  int position;
  int lapsCompleted;
  List<Asset> assets;
  double uktDebt;
  double pinjolDebt;
  double pinjolInterestNextLap;
  bool insurance;
  PlayerTokens tokens;
  int corruptionHeat;
  bool skipsNextTurn;
  bool skipsNextPayday;
  double fuelSubsidyExtraPerRoll;
  int fuelSubsidyLapsLeft;
  int sideBusinessLapsLeft;
  double sideBusinessIncomePerLap;
  int landlordRentExtraLapsLeft;
  double landlordRentExtraPerLap;
  int cheapRentDiscountLapsLeft;
  double cheapRentDiscountPct;
  bool retired;
  RetirementChoice? retirement;
  bool corruptFlagEver;
  bool usedNepotismPerk;

  Player({
    required this.id,
    required this.name,
    this.isAI = false,
    this.career,
    this.education,
    this.maritalStatus = MaritalStatus.single,
    List<Child>? children,
    this.route = Route.none,
    this.cash = 0.0,
    this.happiness = 0,
    this.position = 0,
    this.lapsCompleted = 0,
    List<Asset>? assets,
    this.uktDebt = 0.0,
    this.pinjolDebt = 0.0,
    this.pinjolInterestNextLap = 0.0,
    this.insurance = false,
    PlayerTokens? tokens,
    this.corruptionHeat = 0,
    this.skipsNextTurn = false,
    this.skipsNextPayday = false,
    this.fuelSubsidyExtraPerRoll = 0.0,
    this.fuelSubsidyLapsLeft = 0,
    this.sideBusinessLapsLeft = 0,
    this.sideBusinessIncomePerLap = 0.0,
    this.landlordRentExtraLapsLeft = 0,
    this.landlordRentExtraPerLap = 0.0,
    this.cheapRentDiscountLapsLeft = 0,
    this.cheapRentDiscountPct = 0.0,
    this.retired = false,
    this.retirement,
    this.corruptFlagEver = false,
    this.usedNepotismPerk = false,
  })  : children = children ?? [],
        assets = assets ?? [],
        tokens = tokens ?? PlayerTokens();

  double totalDebt() =>
      uktDebt + pinjolDebt + assets.fold(0.0, (s, a) => s + a.remainingKpr);

  double netAssets() => assets.fold(0.0, (s, a) => s + a.netValue);

  bool get hasPinjol => pinjolDebt > 0.001;
  bool get hasKpr => assets.any((a) => a.hasKpr);
  bool get hasUkt => uktDebt > 0.001;
  bool get hasNoDebt => totalDebt() < 0.001;

  /// Living cost for the current lap, factoring children and cheap-rent
  /// discount and landlord extra.
  double livingCostThisLap(double baseCost, double perChild) {
    final raw = baseCost + children.length * perChild;
    final discount =
        cheapRentDiscountLapsLeft > 0 ? raw * cheapRentDiscountPct : 0.0;
    final rentExtra =
        landlordRentExtraLapsLeft > 0 ? landlordRentExtraPerLap : 0.0;
    final v = raw - discount + rentExtra;
    return v < 0 ? 0.0 : v;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isAI': isAI,
        'career': career?.id,
        'education': education?.id,
        'maritalStatus': maritalStatus.name,
        'children': children.map((c) => c.toJson()).toList(),
        'route': route.name,
        'cash': cash,
        'happiness': happiness,
        'position': position,
        'lapsCompleted': lapsCompleted,
        'assets': assets.map((a) => a.toJson()).toList(),
        'uktDebt': uktDebt,
        'pinjolDebt': pinjolDebt,
        'pinjolInterestNextLap': pinjolInterestNextLap,
        'insurance': insurance,
        'tokens': tokens.toJson(),
        'corruptionHeat': corruptionHeat,
        'skipsNextTurn': skipsNextTurn,
        'skipsNextPayday': skipsNextPayday,
        'fuelSubsidyExtraPerRoll': fuelSubsidyExtraPerRoll,
        'fuelSubsidyLapsLeft': fuelSubsidyLapsLeft,
        'sideBusinessLapsLeft': sideBusinessLapsLeft,
        'sideBusinessIncomePerLap': sideBusinessIncomePerLap,
        'landlordRentExtraLapsLeft': landlordRentExtraLapsLeft,
        'landlordRentExtraPerLap': landlordRentExtraPerLap,
        'cheapRentDiscountLapsLeft': cheapRentDiscountLapsLeft,
        'cheapRentDiscountPct': cheapRentDiscountPct,
        'retired': retired,
        'retirement': retirement?.id,
        'corruptFlagEver': corruptFlagEver,
        'usedNepotismPerk': usedNepotismPerk,
      };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        isAI: j['isAI'] as bool? ?? false,
        career:
            j['career'] == null ? null : Career.fromId(j['career'] as String),
        education: j['education'] == null
            ? null
            : EducationPath.fromId(j['education'] as String),
        maritalStatus: MaritalStatus.values
            .byName((j['maritalStatus'] as String?) ?? 'single'),
        children: (j['children'] as List? ?? [])
            .map((c) => Child.fromJson(c as Map<String, dynamic>))
            .toList(),
        route: Route.values.byName((j['route'] as String?) ?? 'none'),
        cash: (j['cash'] as num?)?.toDouble() ?? 0.0,
        happiness: (j['happiness'] as num?)?.toInt() ?? 0,
        position: (j['position'] as num?)?.toInt() ?? 0,
        lapsCompleted: (j['lapsCompleted'] as num?)?.toInt() ?? 0,
        assets: (j['assets'] as List? ?? [])
            .map((a) => Asset.fromJson(a as Map<String, dynamic>))
            .toList(),
        uktDebt: (j['uktDebt'] as num?)?.toDouble() ?? 0.0,
        pinjolDebt: (j['pinjolDebt'] as num?)?.toDouble() ?? 0.0,
        pinjolInterestNextLap:
            (j['pinjolInterestNextLap'] as num?)?.toDouble() ?? 0.0,
        insurance: j['insurance'] as bool? ?? false,
        tokens: PlayerTokens.fromJson(
            (j['tokens'] as Map? ?? {}).cast<String, dynamic>()),
        corruptionHeat: (j['corruptionHeat'] as num?)?.toInt() ?? 0,
        skipsNextTurn: j['skipsNextTurn'] as bool? ?? false,
        skipsNextPayday: j['skipsNextPayday'] as bool? ?? false,
        fuelSubsidyExtraPerRoll:
            (j['fuelSubsidyExtraPerRoll'] as num?)?.toDouble() ?? 0.0,
        fuelSubsidyLapsLeft: (j['fuelSubsidyLapsLeft'] as num?)?.toInt() ?? 0,
        sideBusinessLapsLeft: (j['sideBusinessLapsLeft'] as num?)?.toInt() ?? 0,
        sideBusinessIncomePerLap:
            (j['sideBusinessIncomePerLap'] as num?)?.toDouble() ?? 0.0,
        landlordRentExtraLapsLeft:
            (j['landlordRentExtraLapsLeft'] as num?)?.toInt() ?? 0,
        landlordRentExtraPerLap:
            (j['landlordRentExtraPerLap'] as num?)?.toDouble() ?? 0.0,
        cheapRentDiscountLapsLeft:
            (j['cheapRentDiscountLapsLeft'] as num?)?.toInt() ?? 0,
        cheapRentDiscountPct:
            (j['cheapRentDiscountPct'] as num?)?.toDouble() ?? 0.0,
        retired: j['retired'] as bool? ?? false,
        retirement: j['retirement'] == null
            ? null
            : RetirementChoice.fromId(j['retirement'] as String),
        corruptFlagEver: j['corruptFlagEver'] as bool? ?? false,
        usedNepotismPerk: j['usedNepotismPerk'] as bool? ?? false,
      );
}

class AssetDef {
  final String id;
  final String nameEn;
  final String nameId;
  final double price;
  final double kprInterestBasePerLapPct;
  const AssetDef(this.id, this.nameEn, this.nameId, this.price,
      {this.kprInterestBasePerLapPct = 0.03});
}

class AssetCatalogue {
  final List<AssetDef> items;
  const AssetCatalogue(this.items);

  static const AssetCatalogue defaultCatalogue = AssetCatalogue([
    AssetDef(
        'kampung_house', 'Small Kampung House', 'Rumah Kampung Kecil', 20.0),
    AssetDef('apartment', 'Apartment', 'Apartemen', 35.0),
    AssetDef('jogja_land', 'Land in Jogja/Bali', 'Tanah di Jogja/Bali', 40.0),
    AssetDef(
        'menteng_mansion', 'Menteng Mansion', 'Rumah Besar Menteng', 120.0),
  ]);
}
