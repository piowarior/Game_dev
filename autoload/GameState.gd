extends Node

# ==================================
# GLOBAL STATE
# ==================================
var disaster_selected = ""  
var screen_shake_enabled: bool = true #ini yang gua tambahin is (ipan)
var has_shaken_in_basecamp: bool = false #ini doang juga gua tambahin is (ipan)
var backpack: Array[String] = []
var current_item := ""
var decision_points := 10
var next_scene_path: String = ""
var last_mission_stars: int = 0
var player_in_cover: bool = false


# posisi obstacle per stage
var obstacle_positions := {
	# "gempa": [
	#   { "id": "obs_1", "pos": Vector2(...) }
	# ]
}

# =========================
# MAP PROGRESS (PERSISTENT)
# =========================
var destroyed_obstacles := {}   # id : true
var rescued_victims := {}       # id : true
var victim_rescue_state := {}   # id : {stage, layer}

# =========================
# RESCUE CLOSE-UP STATE
# =========================
var rescue_progress := {
	# victim_id : {
	#   "stage": "EVAC" / "MEDIC",
	#   "layer_index": int
	# }
}

var spawned_victims := {
	# victim_id : {
	#   "position": Vector2,
	#   "profile": Dictionary
	# }
}


const MAX_ITEM := 5


func register_victim_following(id: String, pos: Vector2, profile: Dictionary):
	spawned_victims[id] = {
		"position": pos,
		"profile": profile
	}

# ==================================
# STAGE / DISASTER DATA
# ==================================
# ==================================
# STAGE / DISASTER DATA (Daftarkan semua di sini)
# ==================================
var stage_data := [
	{
		"id": "gempa_1",
		"name": "Gempa: Reruntuhan Kota",
		"unlocked": true, # Terbuka sejak awal
		"stars": 0,
		"scene": "res://scenes/stage_1.tscn"
	},
	{
		"id": "gempa_2",
		"name": "Gempa: Pemukiman",
		"unlocked": false, # Terkunci
		"stars": 0,
		"scene": "res://scenes/stage_gempa_2.tscn"
	},
	{
		"id": "gempa_3",
		"name": "Gempa: Mall",
		"unlocked": false,
		"stars": 0,
		"scene": "res://scenes/stage_gempa_3.tscn"
	},
	{
		"id": "banjir_1",
		"name": "Banjir: Sungai",
		"unlocked": false,
		"stars": 0,
		"scene": "res://scenes/stage_banjir_1.tscn"
	},
	{
		"id": "banjir_2",
		"name": "Banjir: Area Terisolasi",
		"unlocked": false,
		"stars": 0,
		"scene": "res://scenes/stage_banjir_2.tscn"
	},
	{
		"id": "kebakaran_1",
		"name": "Kebakaran: Gudang",
		"unlocked": false,
		"stars": 0,
		"scene": "res://scenes/stage_kebakaran_1.tscn"
	}
]


# ==================================
# MISSION DATABASE (STATIC)
# ==================================
var mission_database := {
	"gempa_1": {
		"name": "Reruntuhan Kota MisTykhan",
		"korban": [
			{"type": "anak perempuan", "status": "tertimbun + terluka", "task": "EVAC + MEDIC + FOLLOW"},
			{"type": "bapak-Bapak", "status": "tertimbun", "task": "EVAC ONLY"},
			{"type": "ibu", "status": "tertimbun + pingsan", "task": "EVAC + MEDIC + AMBULANCE"},
			{"type": "lansia", "status": "pingsan", "task": "MEDIC ONLY"},
			{"type": "pemuda", "status": "tidak diketahui", "task": "SEARCH INFO"}
		],
		"time_limit": 60, # 8 menit dalam detik
		"decision_points": 10
	},
	"gempa_2": {
		"name": "Sektor Pemukiman",
		"korban": [
			{"type": "bayi", "status": "terjebak", "task": "EVAC + FOLLOW"},
			{"type": "ayah", "status": "luka berat", "task": "MEDIC + AMBULANCE"}
		],
		"time_limit": 480,
		"decision_points": 12
	},
	"gempa_3": {
		"name": "Pusat Perbelanjaan",
		"korban": [
			{"type": "wanita", "status": "tertimbun + terluka", "task": "EVAC + MEDIC + FOLLOW"}
		],
		"time_limit": 600,
		"decision_points": 15
	},
	"banjir_1": {
		"name": "Luapan Sungai",
		"korban": [
			{"type": "anak laki-laki", "status": "hanyut", "task": "RESCUE + MEDIC"}
		],
		"time_limit": 300,
		"decision_points": 8
	},
	"banjir_2": {
		"name": "Area Terisolasi",
		"korban": [
			{"type": "ibu hamil", "status": "terjebak", "task": "EVAC + AMBULANCE"}
		],
		"time_limit": 420,
		"decision_points": 10
	},
	"kebakaran_1": {
		"name": "Gudang Kimia",
		"korban": [
			{"type": "petugas", "status": "sesak nafas", "task": "MEDIC + EVAC"}
		],
		"time_limit": 360,
		"decision_points": 10
	}
}

# ==================================
# CURRENT MISSION (RUNTIME COPY)
# ==================================
var current_mission := {}        # ⬅️ DIPAKAI UI
var time_left := 0               # ⬅️ DIPAKAI UI
var victim_saved := 0            # ⬅️ DIPAKAI UI


# ==================================
# ITEM DATABASE (LENGKAP)
# ==================================
var item_database := {

# =================================================
# 🔧 EVAKUASI (CLOSE-UP & MAP)
# =================================================
"Sarung Tangan": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_sarung_tangan-removebg-preview.png"),
	"sfx": preload("res://assets/sound/sound sarungtangan.mp3"),
	"description": "Alat pelindung dasar yang wajib digunakan pada tahap awal evakuasi. Sarung tangan memungkinkan petugas membersihkan debu dan puing ringan tanpa melukai tangan, serta menjadi syarat utama sebelum menggunakan alat berat lain. Tanpa sarung tangan, progres evakuasi awal akan lebih lambat dan berisiko cedera.",
	"effects": {
		"can_remove": ["debu", "puing_ringan"],
		"speed": 0.6
	},
	"rules": {
		"required_first": true,
		"wrong_tool_penalty": -1
	}
},

"Sekop": {
	"category": "EVAC",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_scrup_1-removebg-preview.png"),
	"description": "Digunakan untuk menggali tanah, lumpur, dan reruntuhan lunak di area peta. Sekop membantu membuka jalur evakuasi awal sebelum korban dapat dijangkau. Tidak efektif digunakan pada area close-up karena ukurannya yang besar dan membutuhkan ruang gerak.",
	"effects": {
		"can_clear_path": true,
		"speed": 1.0
	},
	"rules": {
		"cannot_use_closeup": true
	}
},

"Pickaxe": {
	"category": "EVAC",
	"usage_context": ["MAP", "RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pixace-removebg-preview.png"),
	"sfx": preload("res://assets/sound/sound pixace.mp3"),
	"description": "Alat berat untuk menghancurkan beton, batu besar, dan puing keras. Efektif pada lapisan keras baik di map maupun close-up, namun membutuhkan stamina lebih besar dan berisiko salah penggunaan jika tidak sesuai lapisan.",
	"effects": {
		"can_remove": ["beton"],
		"speed": 1.4,
		"stamina_cost": 2
	},
	"rules": {
		"wrong_layer_penalty": -2
	}
},

"Linggis": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_linggis-removebg-preview.png"),
	"sfx": preload("res://assets/sound/linggis2 sound.mp3"),
	"description": "Digunakan untuk mencongkel besi, rangka logam, atau pintu yang terjepit. Sangat cepat membuka jalur logam, namun menimbulkan suara keras yang dapat meningkatkan stres korban atau menarik bahaya tambahan.",
	"effects": {
		"can_remove": ["logam"],
		"speed": 1.6
	},
	"rules": {
		"noise": true,
		"npc_stress": true
	}
},

"Gergaji": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_gergaji-removebg-preview.png"),
	"sfx": preload("res://assets/sound/sound gergaji.mp3"),
	"description": "Alat pemotong kayu dan balok besar. Cocok untuk membersihkan reruntuhan kayu yang menghalangi korban. Jika digunakan pada material yang salah, progres akan berhenti total.",
	"effects": {
		"can_remove": ["kayu"],
		"speed": 1.2
	},
	"rules": {
		"wrong_layer_zero_progress": true
	}
},

"Gunting Kawat Air": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pemotong_kawat.PNG"),
	"description": "Digunakan untuk memotong kawat, pagar, dan jerat logam yang terendam air.",
	"effects": {
		"can_remove": ["kawat", "pagar"],
		"speed": 1.2
	},
	"rules": {}
},

"Pemotong Sampah": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP", "MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_penghancur_sampah.PNG"),
	"description": "Menghancurkan tumpukan sampah, plastik, dan ranting yang menyumbat jalur evakuasi banjir.",
	"effects": {
		"can_clear_path": true,
		"speed": 1.0
	},
	"rules": {}
},

"Tangga Apung": {
	"category": "EVAC",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_jembatan_keperahu.PNG"),
	"description": "Tangga ringan yang digunakan untuk naik ke perahu atau permukaan aman dari area banjir.",
	"effects": {
		"open_escape_route": true
	},
	"rules": {
		"static_position": true
	}
},

"Pelampung Keselamatan": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pelampung_banjir.PNG"),
	"description": "Menjaga korban tetap mengapung selama proses evakuasi di air.",
	"effects": {
		"prevent_drowning": true
	},
	"rules": {}
},

"Handuk Termal": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_selimut_penghangat.PNG"),
	"description": "Menghangatkan korban setelah dievakuasi dari air untuk mencegah hipotermia.",
	"effects": {
		"reduce_hypothermia": true
	},
	"rules": {}
},

"Alat Pemadam Api": {
	"category": "EVAC",
	"usage_context": ["MAP", "RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pemadam_api.PNG"),
	"description": "Digunakan untuk memadamkan api kecil hingga sedang agar jalur evakuasi aman.",
	"effects": {
		"extinguish_fire": true,
		"reduce_fire_area": true,
		"safe_path": true
	},
	"rules": {
		"limited_use": true,
		"uses": 3
	}
},


"Kapak Pemadam": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_Kapak_pemadam.PNG"),
	"description": "Digunakan untuk membuka pintu dan struktur yang terbakar.",
	"effects": {
		"can_remove": ["kayu_terbakar"],
		"speed": 1.3
	},
	"rules": {}
},

"Pemotong Baja Panas": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_Pemotong_tahanapi.PNG"),
	"description": "Memotong rangka logam yang panas akibat kebakaran.",
	"effects": {
		"can_remove": ["logam_panas"],
		"stamina_cost": 2
	},
	"rules": {}
},

"Alat Penarik Korban": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_alat_penarik_korban.PNG"),
	"description": "Menarik korban dari area panas tanpa kontak langsung.",
	"effects": {
		"safe_pull": true
	},
	"rules": {}
},

"Tangga Evakuasi Api": {
	"category": "EVAC",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_tangga_evakuasi_api.PNG"),
	"description": "Digunakan untuk menyelamatkan korban dari ketinggian saat kebakaran.",
	"effects": {
		"open_escape_route": true
	},
	"rules": {}
},

"Pemecah Kaca": {
	"category": "EVAC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pemecah_kaca.PNG"),
	"description": "Memecahkan kaca jendela untuk jalur evakuasi darurat.",
	"effects": {
		"can_remove": ["kaca"],
		"speed": 1.5
	},
	"rules": {}
},



# =================================================
# 🩺 MEDIS (SETELAH PUING BERSIH)
# =================================================
"Air": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_air-removebg-preview.png"),
	"description": "Membersihkan luka korban.",
	"effects": {
		"remove_status": ["kotor", "berdarah"]
	},
	"rules": {
		"must_before": ["Alkohol", "P3K"]
	}
},

"Alkohol": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_alkohol-removebg-preview.png"),
	"description": "Mensterilkan luka agar tidak infeksi.",
	"effects": {
		"reduce_infection": true
	},
	"rules": {
		"must_after": ["Air"]
	}
},

"P3K": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_p3k-removebg-preview.png"),
	"description": "Menstabilkan kondisi korban.",
	"effects": {
		"revive": true,
		"stop_bleeding": true
	},
	"rules": {
		"must_after": ["Air", "Alkohol"]
	}
},

"Bidai": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_bidai-removebg-preview.png"),
	"description": "Menangani patah tulang agar korban bisa bergerak.",
	"effects": {
		"fix_fracture": true
	},
	"rules": {}
},

"Masker Oksigen": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_masker-oksigen-removebg-preview.png"),
	"description": "Membantu korban pingsan atau sulit bernapas.",
	"effects": {
		"revive_delay": 3,
		"extend_life_time": 30
	},
	"rules": {
		"needs_wait": true
	}
},

"Telepon Ambulans": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_telpon_ambulan.PNG"),
	"description": "Perangkat komunikasi darurat untuk memanggil ambulans ke lokasi. Korban akan langsung dievakuasi oleh tim medis. Hanya dapat digunakan satu kali.",
	"effects": {
		"call_ambulance": true,
		"instant_evacuate": true,
		"single_use": true
	},
	"rules": {
		"remove_after_use": true
	}
},

"Selimut Termal": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_selimut_termal.PNG"),
	"description": "Menjaga suhu tubuh korban setelah terendam air dingin.",
	"effects": {
		"prevent_hypothermia": true
	},
	"rules": {}
},

"Pembersih Luka Air Kotor": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pembersih_lukaairkotor.PNG"),
	"description": "Membersihkan luka dari bakteri dan kotoran air banjir.",
	"effects": {
		"remove_status": ["infeksi_air"]
	},
	"rules": {}
},

"Salep Luka Bakar": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_salep_lukabakar.PNG"),
	"description": "Mengurangi kerusakan dan nyeri akibat luka bakar.",
	"effects": {
		"heal_burn": true
	},
	"rules": {}
},

"Masker Oksigen Portable": {
	"category": "MEDIC",
	"usage_context": ["RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_masker_oksigenportabel.PNG"),
	"description": "Membantu korban yang mengalami keracunan asap.",
	"effects": {
		"remove_status": ["asap"],
		"revive": true
	},
	"rules": {}
},



# =================================================
# 🔦 PENERANGAN (AWAL RESCUE)
# =================================================
"Senter": {
	"category": "LIGHT",
	"usage_context": ["RESCUE_CLOSEUP", "MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_senter3.PNG"),
	"description": "Penerangan standar untuk area rescue. Memberikan visibilitas normal tanpa bonus atau penalti tambahan.",
	"effects": {
		"light_radius": "full",
		"rescue_speed_bonus": 0
	},
	"rules": {
		"default_light": true
	}
},

"Headlamp": {
	"category": "LIGHT",
	"usage_context": ["RESCUE_CLOSEUP", "MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_hadlamp.PNG"),
	"description": "Lampu kepala dengan cahaya fokus. Memberikan bonus kecepatan rescue karena tangan tetap bebas, namun memiliki keterbatasan daya baterai.",
	"effects": {
		"light_radius": "focused",
		"rescue_speed_bonus": 0.2
	},
	"rules": {
		"battery_limited": true
	}
},

"Lampu Tahan Air": {
	"category": "LIGHT",
	"usage_context": ["MAP", "RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_senter_tahan_air.PNG"),
	"description": "Lampu khusus yang tetap menyala di area tergenang air. Membantu visibilitas di air keruh saat proses evakuasi banjir.",
	"effects": {
		"light_radius": "water",
		"visibility_bonus": true
	},
	"rules": {}
},

"Kamera Termal": {
	"category": "LIGHT",
	"usage_context": ["MAP", "RESCUE_CLOSEUP"],
	"icon": preload("res://assets/tilesets/item_icon/item_kamera_termal.PNG"),
	"description": "Menampilkan panas tubuh korban melalui asap tebal dan api.",
	"effects": {
		"detect_heat": true
	},
	"rules": {}
},



# =================================================
# 📣 KOMUNIKASI (MAP NORMAL)
# =================================================
"Peluit Darurat": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_peluit-removebg-preview.png"),
	"description": "Digunakan untuk memancing respon suara korban di sekitar area. Tidak menunjukkan posisi pasti, tetapi membantu menentukan area pencarian.",
	"effects": {
		"scan_radius": 5,
		"show_presence": true
	},
	"rules": {
		"no_exact_position": true,
		"dps_penalty_if_skipped": -2
	}
},

"Flare": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_flare-removebg-preview.png"),
	"description": "Digunakan untuk menandai area luas dan menarik perhatian korban. Sekali pakai dan sangat efektif untuk area besar.",
	"effects": {
		"scan_radius": 10,
		"single_use": true
	},
	"rules": {}
},

"Radio Scanner": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_radio_scaner.PNG"),
	"description": "Mendeteksi sinyal suara dan aktivitas reruntuhan. Membutuhkan waktu pemindaian sebelum hasil muncul.",
	"effects": {
		"detect_paths": true,
		"delay": 2
	},
	"rules": {}
},

"Beacon Suara": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_becon_suar.PNG"),
	"description": "Diletakkan di satu titik untuk menarik respon korban ke lokasi tertentu.",
	"effects": {
		"lure_npc": true
	},
	"rules": {
		"static_position": true
	}
},

"Pelampung Sinyal": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_pelampung_sinyal.PNG"),
	"description": "Mengirim sinyal lokasi korban di area banjir yang luas.",
	"effects": {
		"show_presence": true,
		"scan_radius": 8
	},
	"rules": {}
},

"Radio Tahan Panas": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_radio_tahanapi2.PNG"),
	"description": "Radio komunikasi yang tetap berfungsi di suhu tinggi.",
	"effects": {
		"communication_stable": true
	},
	"rules": {}
},



# =================================================
# 🛡️ KEAMANAN (PASSIVE BUFF)
# =================================================
"Helm": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_helmet-removebg-preview.png"),
	"description": "Melindungi kepala dari reruntuhan.",
	"effects": {
		"prevent_progress_reset": true
	},
	"rules": {}
},

"Baju Tahan Api": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_baju_tahanapi_tipe1.PNG"),
	"description": "Mengurangi kerusakan akibat panas dan api.",
	"effects": {
		"fire_resist": true
	},
	"rules": {}
},

"Masker Respirator Api": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_masker_respiratorapi.PNG"),
	"description": "Melindungi pernapasan dari asap tebal dan gas beracun.",
	"effects": {
		"smoke_resist": true
	},
	"rules": {}
},


"Masker": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_masker_petugas-removebg-preview.png"),
	"description": "Melindungi pernapasan dari debu.",
	"effects": {
		"extend_npc_timer": 0.3
	},
	"rules": {
		"stamina_drain": true
	}
},

"Rompi Safety": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_rompi-removebg-preview.png"),
	"description": "Meningkatkan keamanan dan kepercayaan korban.",
	"effects": {
		"npc_compliance": true
	},
	"rules": {
		"movement_slow": true
	}
},

"Sarung Tangan Safety": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_sarungtangan_safty.PNG"),
	"description": "Pegangan lebih aman saat rescue.",
	"effects": {
		"mistake_tolerance": true
	},
	"rules": {
		"tool_switch_slow": true
	}
},

"Sepatu Boots": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_sepatu_boot-removebg-preview.png"),
	"description": "Stabil berjalan di puing.",
	"effects": {
		"prevent_slip": true
	},
	"rules": {
		"sprint_penalty": true
	}
},

"Rompi Pelampung": {
	"category": "SAFETY",
	"usage_context": ["PASSIVE"],
	"icon": preload("res://assets/tilesets/item_icon/item_rompi_pelampung.PNG"),
	"description": "Mencegah petugas tenggelam saat melakukan evakuasi banjir.",
	"effects": {
		"prevent_drowning": true
	},
	"rules": {}
}


}



# ==================================
# BACKPACK
# ==================================
signal backpack_changed   # ⬅️ UI bisa listen ini

func reset_backpack():
	backpack.clear()
	current_item = ""
	emit_signal("backpack_changed")


# ==================================
# MISSION START (UI FRIENDLY)
# ==================================
func start_mission(disaster_type: String):
	if not mission_database.has(disaster_type):
		push_error("Mission tidak ditemukan")
		return

	# 🔥 PENTING: DUPLICATE → BIAR UI AMAN
	current_mission = mission_database[disaster_type].duplicate(true)

	time_left = current_mission["time_limit"]
	decision_points = current_mission["decision_points"]
	victim_saved = 0


# ==================================
# ITEM HANDLING
# ==================================
func add_item(name: String) -> bool:
	if backpack.size() >= MAX_ITEM:
		return false
	if not item_database.has(name):
		return false

	backpack.append(name)

	if backpack.size() == 1:
		current_item = name

	emit_signal("backpack_changed")
	return true


func get_item_data(name: String):
	return item_database.get(name, null)


func finish_mission(stage_id: String) -> int:
	var stars := 1

	var total_victim := get_total_victim()

	if victim_saved >= total_victim:
		stars = 2

	if victim_saved >= total_victim and time_left > 0:
		stars = 3

	# 🔒 SIMPAN KE STAGE DATA
	for stage in stage_data:
		if stage.id == stage_id:
			stage.stars = max(stage.stars, stars)
			break

	return stars
	
func unlock_next_stage(current_id: String):
	for i in range(stage_data.size()):
		if stage_data[i].id == current_id:
			# Jika ada stage berikutnya, buka kunci stage tersebut
			if i + 1 < stage_data.size():
				stage_data[i+1].unlocked = true
			break


# ==================================
# UI HELPER (OPSIONAL TAPI AMAN)
# ==================================
func get_total_victim() -> int:
	if current_mission.has("total_victim"):
		return current_mission["total_victim"]
	return 0


func get_remaining_time() -> int:
	return time_left
