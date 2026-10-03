/// Tutorial screen — rewritten per master-prompt section 6.6 to cover
/// everything the rules need (Tender, living cost, interest, TAPERA,
/// savings buffer, insurance, Good Luck cap, skip tokens, KPK sting,
/// bankruptcy, autosave/resume, Warga Teladan, scoring).
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final steps = isId ? _stepsId : _stepsEn;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tutorialTitle)),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: steps.length,
          itemBuilder: (context, i) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child:
                  Text(steps[i], style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ),
      ),
    );
  }
}

const _stepsEn = [
  '1. Pick an education path: College (PTN) starts with Rp 2M cash and Rp 10M UKT debt; SMA/SMK starts with Rp 3M and no debt.',
  '2. Roll the dice to move. Pass-and-play between 2–4 players on one device, or solo vs AI.',
  '3. Payday tile (every 5th tile) gives your career\'s payday. PNS and SCBD employees lose 3% TAPERA.',
  '4. Event tiles draw a "Nasib Warga +62" card with realistic effects: fuel hikes, mass layoffs, KPK OTT, PPN shocks.',
  '5. Luck tiles draw a Good Luck or Bad Luck card at random. Cash losses are reduced by 25% if you have ≥ Rp 10M savings; insurance halves medical cards. Good Luck is capped at Rp 5M per card, max 2 per player per lap.',
  '6. Tender tile: Contractor-only bonus. Asset Shop tile: buy a Kampung House (Rp 20M), Apartment (Rp 35M), Jogja/Bali Land (Rp 40M), or Menteng Mansion (Rp 120M) — 12% PPN on top, 20% down payment, 80% as KPR.',
  '7. Marriage tile: Modest (KUA, Rp 1M, +8 Happiness) or Lavish (Rp 8M, +25 Happiness; if cash goes negative, the difference becomes Pinjol debt).',
  '8. Child tile: each child adds Rp 1.5M per lap. Fund their schooling (+Rp 3M Legacy bonus per funded child at retirement).',
  '9. Mahar Partai gate (Rp 15M): enter politics. Choose Clean (low income, +Happiness, public mockery) or Corrupt (steal Rp 6M per lap, +Corruption Heat; P(KPK sting) = heat × 10%; caught → -50% cash, -20 Happiness, lose 2 turns).',
  '10. Living cost per lap: Rp 3M base + Rp 1.5M per child. Interest per lap: UKT 2%, KPR 3%, Pinjol 15%.',
  '11. Bankruptcy: if cash stays below 0 for too long, you can be forced to take a Pinjol loan. Avoid chronic debt.',
  '12. Autosave after every turn. Resume on launch. Settings persist. A corrupted save falls back to a New Game screen.',
  '13. Retirement fork: choose Kampung Jogja, Island Bali, or Elite Menteng. Score = Net Assets + Cash + (Happiness × Rp 0.5M) + Legacy bonus. Corrupt route with negative Happiness has the score halved.',
  '14. Warga Teladan +62 (Model Citizen): no corruption, no Pinjol at the end, positive Happiness, retire in Jogja or Bali.',
];

const _stepsId = [
  '1. Pilih jalur pendidikan: PTN (Kuliah) bermula dengan Rp 2M tunai dan utang UKT Rp 10M; SMA/SMK bermula dengan Rp 3M tanpa utang.',
  '2. Lempar dadu untuk bergerak. Bermain bergiliran antara 2–4 pemain pada satu perangkat, atau sendiri melawan AI.',
  '3. Tile Payday (setiap 5 tile) memberi gaji sesuai pekerjaan. PNS dan karyawan SCBD dipotong 3% TAPERA.',
  '4. Tile Event menarik kartu "Nasib Warga +62" dengan efek realistis: kenaikan harga BBM, PHK massal, OTT KPK, kejutan PPN.',
  '5. Tile Luck menarik kartu Good Luck atau Bad Luck secara acak. Kerugian tunai dikurangi 25% bila tabungan ≥ Rp 10M; asuransi memangkas separuh tagihan medis. Good Luck dibatasi Rp 5M per kartu, maksimal 2 per pemain per putaran.',
  '6. Tile Tender: bonus khusus Kontraktor. Tile Asset Shop: beli Rumah Kampung (Rp 20M), Apartemen (Rp 35M), Tanah Jogja/Bali (Rp 40M), atau Rumah Besar Menteng (Rp 120M) — ditambah PPN 12%, uang muka 20%, sisanya 80% sebagai KPR.',
  '7. Tile Marriage: Sederhana (KUA, Rp 1M, +8 Kebahagiaan) atau Mewah (Rp 8M, +25 Kebahagiaan; bila tunai minus, selisihnya menjadi utang Pinjol).',
  '8. Tile Child: setiap anak menambah biaya hidup Rp 1,5M per putaran. Biayai sekolah anak (+Rp 3M bonus Dynasty per anak yang dibiayai saat pensiun).',
  '9. Tile Mahar Partai (Rp 15M): masuk jalur politik. Pilih Bersih (penghasilan kecil, +Kebahagiaan, dicemo warga) atau Korupsi (curi Rp 6M per putaran, +Corruption Heat; P(OTT KPK) = heat × 10%; ketahuan → -50% tunai, -20 Kebahagiaan, lewat 2 giliran).',
  '10. Biaya hidup per putaran: Rp 3M dasar + Rp 1,5M per anak. Bunga per putaran: UKT 2%, KPR 3%, Pinjol 15%.',
  '11. Kebangkrutan: bila tunai minus terlalu lama, Anda bisa dipaksa mengambil pinjaman Pinjol. Hindari utang kronis.',
  '12. Simpan otomatis setelah setiap giliran. Lanjutkan saat aplikasi dibuka. Pengaturan tersimpan. Save yang rusak akan kembali ke layar Permainan Baru.',
  '13. Tile pensiun: pilih Kampung Jogja, Pulau Bali, atau Menteng Elite. Skor = Aset Bersih + Tunai + (Kebahagiaan × Rp 0,5M) + Bonus Dynasty. Jalur Korupsi dengan Kebahagiaan negatif, skor dipotong separuh.',
  '14. Warga Teladan +62: tanpa korupsi, tanpa Pinjol di akhir, Kebahagiaan positif, pensiun di Jogja atau Bali.',
];
