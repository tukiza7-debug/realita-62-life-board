/// Cultural terms used throughout the game. Verified against KBBI,
/// Badan Bahasa, official Indonesian government sites (BPJS Kesehatan,
/// DJP, BP Tapera, KPK, Kemenaker). See docs/GLOSSARY.md for source URLs.
library;

class GlossaryTerm {
  final String key;
  final String shortEn;
  final String shortId;
  final String longEn;
  final String longId;
  const GlossaryTerm({
    required this.key,
    required this.shortEn,
    required this.shortId,
    required this.longEn,
    required this.longId,
  });
}

const List<GlossaryTerm> glossaryTerms = [
  GlossaryTerm(
    key: 'UKT',
    shortEn: 'Tuition fee',
    shortId: 'UKT (uang kuliah tunggal)',
    longEn:
        'One-semester tuition charged by Indonesian state universities.',
    longId:
        'Biaya kuliah satu semester yang dibebankan oleh perguruan tinggi negeri.',
  ),
  GlossaryTerm(
    key: 'KPR',
    shortEn: 'Mortgage',
    shortId: 'KPR (kredit pemilikan rumah)',
    longEn: 'Home ownership loan from a bank.',
    longId: 'Kredit pemilikan rumah dari bank.',
  ),
  GlossaryTerm(
    key: 'Pinjol',
    shortEn: 'Online payday loan',
    shortId: 'Pinjol (pinjaman online)',
    longEn:
        'Short-term online loan with very high interest.',
    longId:
        'Pinjaman online jangka pendek dengan bunga sangat tinggi.',
  ),
  GlossaryTerm(
    key: 'PPN',
    shortEn: 'VAT (12%)',
    shortId: 'PPN (pajak pertambahan nilai)',
    longEn:
        'Value-added tax applied to asset purchases and goods.',
    longId:
        'Pajak pertambahan nilai yang dikenakan pada pembelian aset dan barang.',
  ),
  GlossaryTerm(
    key: 'TAPERA',
    shortEn: 'Housing savings deduction',
    shortId: 'Tapera (tabungan perumahan rakyat)',
    longEn:
        'Mandatory housing-savings deduction for PNS and certain employees.',
    longId:
        'Potongan wajib tabungan perumahan untuk PNS dan karyawan tertentu.',
  ),
  GlossaryTerm(
    key: 'MBG',
    shortEn: 'Free nutritious meal program',
    shortId: 'MBG (Makan Bergizi Gratis)',
    longEn:
        'Government free-meal program; subject to skimming in the game.',
    longId:
        'Program makan bergizi gratis pemerintah; di dalam game rawan disunat.',
  ),
  GlossaryTerm(
    key: 'Ojol',
    shortEn: 'Ride-hailing driver',
    shortId: 'Ojol (ojek online)',
    longEn: 'Driver for an online ride-hailing app.',
    longId: 'Pengemudi ojek berbasis aplikasi.',
  ),
  GlossaryTerm(
    key: 'PNS',
    shortEn: 'Civil servant',
    shortId: 'PNS (pegawai negeri sipil)',
    longEn:
        'Indonesian government employee with stable income.',
    longId: 'Pegawai negeri dengan penghasilan stabil.',
  ),
  GlossaryTerm(
    key: 'SCBD',
    shortEn: 'SCBD office worker',
    shortId: 'Karyawan SCBD',
    longEn:
        'Private-sector employee in the Sudirman-CBD business district.',
    longId:
        'Karyawan swasta di kawasan bisnis Sudirman-CBD.',
  ),
  GlossaryTerm(
    key: 'Arisan',
    shortEn: 'Rotating savings club',
    shortId: 'Arisan',
    longEn:
        'Indonesian rotating savings and credit association.',
    longId:
        'Arisan: simpan-pinjam bergilir antar anggota.',
  ),
  GlossaryTerm(
    key: 'Gotong Royong',
    shortEn: 'Community mutual help',
    shortId: 'Gotong Royong',
    longEn: 'Indonesian tradition of communal mutual aid.',
    longId:
        'Tradisi tolong-menolong warga secara bersama-sama.',
  ),
  GlossaryTerm(
    key: 'Mahar Partai',
    shortEn: 'Party dowry',
    shortId: 'Mahar Partai',
    longEn:
        'Cost to enter politics; unofficial "party dowry".',
    longId:
        'Biaya masuk politik; "mahar partai" secara tidak resmi.',
  ),
  GlossaryTerm(
    key: 'THR',
    shortEn: 'Holiday allowance',
    shortId: 'THR (tunjangan hari raya)',
    longEn:
        'Mandatory annual bonus paid before religious holidays.',
    longId:
        'Tunjangan wajib tahunan menjelang hari raya keagamaan.',
  ),
  GlossaryTerm(
    key: 'KPK OTT',
    shortEn: 'Anti-corruption sting',
    shortId: 'OTT KPK (operasi tangkap tangan)',
    longEn:
        'Anti-corruption agency sting operation catching officials red-handed.',
    longId:
        'Operasi tangkap tangan KPK menangkap pejabat di lokasi kejahatan.',
  ),
  GlossaryTerm(
    key: 'BPJS',
    shortEn: 'National health insurance',
    shortId: 'BPJS Kesehatan',
    longEn:
        'Indonesian national health insurance program.',
    longId: 'Program jaminan kesehatan nasional.',
  ),
  GlossaryTerm(
    key: 'PBB',
    shortEn: 'Property tax',
    shortId: 'PBB (pajak bumi dan bangunan)',
    longEn: 'Annual land and building tax.',
    longId: 'Pajak tahunan atas bumi dan bangunan.',
  ),
  GlossaryTerm(
    key: 'PHK',
    shortEn: 'Mass layoffs',
    shortId: 'PHK (pemutusan hubungan kerja)',
    longEn:
        'Indonesian term for layoffs / termination of employment.',
    longId: 'Pemutusan hubungan kerja secara sepihak.',
  ),
  GlossaryTerm(
    key: 'Warung',
    shortEn: 'Small food stall',
    shortId: 'Warung',
    longEn:
        'Small family-run food/grocery stall.',
    longId:
        'Kios kecil milik keluarga untuk jualan makanan atau belanja.',
  ),
  GlossaryTerm(
    key: 'Kondangan',
    shortEn: 'Wedding invitation',
    shortId: 'Kondangan',
    longEn:
        'Guest invited to a wedding; usually brings a cash envelope.',
    longId:
        'Tamu yang diundang ke pesta pernikahan; biasa membawa amplop uang.',
  ),
  GlossaryTerm(
    key: 'Mudik',
    shortEn: 'Homecoming trip',
    shortId: 'Mudik',
    longEn:
        'Annual trip back to one\'s home town, typically during Lebaran.',
    longId:
        'Tradisi pulang ke kampung halaman, biasanya saat Lebaran.',
  ),
];
