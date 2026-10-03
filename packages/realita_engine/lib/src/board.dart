/// Board tile definitions and factory. Mirrors the Kotlin BoardFactory
/// layout (60 tiles in a winding path) so a Dart game and a Kotlin game
/// with the same seed land on the same tile types in the same order.
library;

enum TileType {
  start('start'),
  educationFork('education_fork'),
  payday('payday'),
  event_('event'),
  luck('luck'),
  marriage('marriage'),
  child('child'),
  assetShop('asset_shop'),
  maharPartaiGate('mahar_partai_gate'),
  tender('tender'),
  retirementFork('retirement_fork'),
  blank('blank');

  final String id;
  const TileType(this.id);

  static TileType fromId(String id) =>
      TileType.values.firstWhere((t) => t.id == id);
}

class Tile {
  final int index;
  final TileType type;
  final String nameEn;
  final String nameId;
  final String landmarkEn;
  final String landmarkId;

  const Tile({
    required this.index,
    required this.type,
    this.nameEn = '',
    this.nameId = '',
    this.landmarkEn = '',
    this.landmarkId = '',
  });
}

class BoardFactory {
  /// Generate the default 60-tile winding board. Mirrors
  /// legacy-kotlin/.../Board.kt default() exactly.
  static List<Tile> defaultBoard({int size = 60}) {
    final tiles = <Tile>[];
    tiles.add(Tile(
      index: 0,
      type: TileType.start,
      nameEn: 'Start',
      nameId: 'Mulai',
      landmarkEn: 'Your story begins',
      landmarkId: 'Cerita Anda dimulai',
    ));

    final landmarks = [
      ('SCBD Skyline', 'Pemandangan SCBD'),
      ('Kampung Streets', 'Gang Kampung'),
      ('Menteng', 'Menteng'),
      ('Jogja', 'Jogja'),
      ('Bali', 'Bali'),
      ('Warung Pojok', 'Warung Pojok'),
      ('Pasar Tradisional', 'Pasar Tradisional'),
      ('Kantor Lurah', 'Kantor Lurah'),
      ('Stasiun Kereta', 'Stasiun Kereta'),
      ('Halte TransJakarta', 'Halte TransJakarta'),
    ];

    for (var i = 1; i < size - 1; i++) {
      final t;
      if (i == 6) {
        t = TileType.marriage;
      } else if (i == 12) {
        t = TileType.child;
      } else if (i == 18) {
        t = TileType.assetShop;
      } else if (i == 24) {
        t = TileType.maharPartaiGate;
      } else if (i == 30) {
        t = TileType.tender;
      } else if (i == 36) {
        t = TileType.marriage;
      } else if (i == 42) {
        t = TileType.child;
      } else if (i == 48) {
        t = TileType.assetShop;
      } else if (i % 5 == 0) {
        t = TileType.payday;
      } else if (i % 7 == 0) {
        t = TileType.luck;
      } else if (i % 3 == 0) {
        t = TileType.event_;
      } else {
        t = TileType.blank;
      }
      final (en, id) = landmarks[i % landmarks.length];
      tiles.add(Tile(
        index: i,
        type: t,
        nameEn: 'Tile $i',
        nameId: 'Tile $i',
        landmarkEn: en,
        landmarkId: id,
      ));
    }

    tiles.add(Tile(
      index: size - 1,
      type: TileType.retirementFork,
      nameEn: 'Retirement Fork',
      nameId: 'Percabangan Pensiun',
      landmarkEn: 'Choose your retirement',
      landmarkId: 'Pilih masa pensiun Anda',
    ));
    return tiles;
  }
}
