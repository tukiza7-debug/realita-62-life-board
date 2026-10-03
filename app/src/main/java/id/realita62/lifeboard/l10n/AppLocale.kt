package id.realita62.lifeboard.l10n

/**
 * App locales. Indonesian (in) and English (en) are mandatory.
 * Default falls back to the device locale, then to English.
 */
enum class AppLocale(val code: String, val nativeName: String) {
    ENGLISH("en", "English"),
    INDONESIAN("id", "Bahasa Indonesia");

    companion object {
        fun default(): AppLocale {
            // Best-effort device locale detection — falls back to English.
            val tag = java.util.Locale.getDefault().language
            return entries.firstOrNull { it.code == tag } ?: ENGLISH
        }
        fun fromCode(code: String): AppLocale = entries.firstOrNull { it.code == code } ?: ENGLISH
    }
}

/**
 * Maps an Indonesian term to its localized form. Used by the Glossary screen
 * and by event card tooltips that reference cultural terms (UKT, KPR, Pinjol,
 * Mahar Partai, THR, Arisan, Gotong Royong, MBG, TAPERA, OTT KPK, etc.).
 *
 * See docs/GLOSSARY.md for the source URLs used to verify each term.
 */
object Glossary {
    data class Term(val key: String, val shortEn: String, val shortId: String, val longEn: String, val longId: String)

    val terms: List<Term> = listOf(
        Term("UKT", "Tuition fee", "UKT (uang kuliah tunggal)",
            "One-semester tuition charged by Indonesian state universities.",
            "Biaya kuliah satu semester yang dibebankan oleh perguruan tinggi negeri."),
        Term("KPR", "Mortgage", "KPR (kredit pemilikan rumah)",
            "Home ownership loan from a bank.",
            "Kredit pemilikan rumah dari bank."),
        Term("Pinjol", "Online payday loan", "Pinjol (pinjaman online)",
            "Short-term online loan with very high interest.",
            "Pinjaman online jangka pendek dengan bunga sangat tinggi."),
        Term("PPN", "VAT (12%)", "PPN (pajak pertambahan nilai)",
            "Value-added tax applied to asset purchases and goods.",
            "Pajak pertambahan nilai yang dikenakan pada pembelian aset dan barang."),
        Term("TAPERA", "Housing savings deduction", "Tapera (tabungan perumahan rakyat)",
            "Mandatory housing-savings deduction for PNS and certain employees.",
            "Potongan wajib tabungan perumahan untuk PNS dan karyawan tertentu."),
        Term("MBG", "Free nutritious meal program", "MBG (Makan Bergizi Gratis)",
            "Government free-meal program; subject to skimming in the game.",
            "Program makan bergizi gratis pemerintah; di dalam game rawan disunat."),
        Term("Ojol", "Ride-hailing driver", "Ojol (ojek online)",
            "Driver for an online ride-hailing app.",
            "Pengemudi ojek berbasis aplikasi."),
        Term("PNS", "Civil servant", "PNS (pegawai negeri sipil)",
            "Indonesian government employee with stable income.",
            "Pegawai negeri dengan penghasilan stabil."),
        Term("SCBD", "SCBD office worker", "Karyawan SCBD",
            "Private-sector employee in the Sudirman-CBD business district.",
            "Karyawan swasta di kawasan bisnis Sudirman-CBD."),
        Term("Arisan", "Rotating savings club", "Arisan",
            "Indonesian rotating savings and credit association.",
            "Arisan: simpan-pinjam bergilir antar anggota."),
        Term("Gotong Royong", "Community mutual help", "Gotong Royong",
            "Indonesian tradition of communal mutual aid.",
            "Tradisi tolong-menolong warga secara bersama-sama."),
        Term("Mahar Partai", "Party dowry", "Mahar Partai",
            "Cost to enter politics; unofficial 'party dowry'.",
            "Biaya masuk politik; 'mahar partai' secara tidak resmi."),
        Term("THR", "Holiday allowance", "THR (tunjangan hari raya)",
            "Mandatory annual bonus paid before religious holidays.",
            "Tunjangan wajib tahunan menjelang hari raya keagamaan."),
        Term("KPK OTT", "Anti-corruption sting", "OTT KPK (operasi tangkap tangan)",
            "Anti-corruption agency sting operation catching officials red-handed.",
            "Operasi tangkap tangan KPK menangkap pejabat di lokasi kejahatan."),
        Term("BPJS", "National health insurance", "BPJS Kesehatan",
            "Indonesian national health insurance program.",
            "Program jaminan kesehatan nasional."),
        Term("PBB", "Property tax", "PBB (pajak bumi dan bangunan)",
            "Annual land and building tax.",
            "Pajak tahunan atas bumi dan bangunan."),
        Term("PHK", "Mass layoffs", "PHK (pemutusan hubungan kerja)",
            "Indonesian term for layoffs / termination of employment.",
            "Pemutusan hubungan kerja secara sepihak."),
        Term("Warung", "Small food stall", "Warung",
            "Small family-run food/grocery stall.",
            "Kios kecil milik keluarga untuk jualan makanan/belanja."),
        Term("Kondangan", "Wedding invitation", "Kondangan",
            "Guest invited to a wedding; usually brings a cash envelope.",
            "Tamu yang diundang ke pesta pernikahan; biasa membawa amplop uang."),
        Term("Mudik", "Homecoming trip", "Mudik",
            "Annual trip back to one's home town, typically during Lebaran.",
            "Tradisi pulang ke kampung halaman, biasanya saat Lebaran.")
    )

    fun find(key: String): Term? = terms.firstOrNull { it.key.equals(key, ignoreCase = true) }
}
