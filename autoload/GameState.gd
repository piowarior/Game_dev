extends Node

# ==================================
# GLOBAL STATE
# ==================================
var disaster_selected = ""  
var backpack: Array[String] = []
var current_item := ""
var decision_points := 10
var next_scene_path: String = ""

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
var stage_data := [
	{
		"id": "gempa",
		"name": "Gempa Bumi",
		"unlocked": true,
		"stars": 0,              # ⭐ HASIL PEMAIN
		"scene": "res://scenes/stage_1.tscn"
	},
	{
		"id": "banjir",
		"name": "Banjir",
		"unlocked": false,
		"stars": 0,
		"scene": "res://scenes/stage_2.tscn"
	}
]



# ==================================
# MISSION DATABASE (STATIC)
# ==================================
var mission_database := {
	"gempa": {
		"korban": [
			{"type": "anak", "count": 2, "status": "tertimbun"},
			{"type": "lansia", "count": 1, "status": "sekarat"},
			{"type": "pemuda", "count": 1, "status": "terjebak"},
			{"type": "ibu hamil", "count": 1, "status": "kurang jelas"}
		],
		"time_limit": 300,
		"decision_points": 10,
		"total_victim": 5
	},
	"banjir": {
		"korban": [
			{"type": "anak", "count": 3, "status": "terjebak"},
			{"type": "dewasa", "count": 2, "status": "aman"}
		],
		"time_limit": 240,
		"decision_points": 8,
		"total_victim": 5
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
	"description": "Alat dasar untuk membersihkan puing ringan. Wajib digunakan pertama.",
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
	"description": "Menggali tanah dan reruntuhan lunak sebelum rescue.",
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
	"description": "Menghancurkan beton dan puing keras.",
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
	"description": "Mencongkel besi dan logam berat dengan cepat.",
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
	"description": "Memotong kayu dan balok.",
	"effects": {
		"can_remove": ["kayu"],
		"speed": 1.2
	},
	"rules": {
		"wrong_layer_zero_progress": true
	}
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

# =================================================
# 🔦 PENERANGAN (AWAL RESCUE)
# =================================================
"Senter": {
	"category": "LIGHT",
	"usage_context": ["RESCUE_CLOSEUP", "MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_senter2-removebg-preview.png"),
	"description": "Menerangi seluruh area rescue dengan cahaya normal.",
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
	"icon": preload("res://assets/tilesets/item_icon/item_senter-removebg-preview.png"),
	"description": "Cahaya fokus, mempercepat rescue.",
	"effects": {
		"light_radius": "focused",
		"rescue_speed_bonus": 0.2
	},
	"rules": {
		"battery_limited": true
	}
},

# =================================================
# 📣 KOMUNIKASI (MAP NORMAL)
# =================================================
"Peluit Darurat": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_peluit-removebg-preview.png"),
	"description": "Memancing respon korban di sekitar.",
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
	"description": "Menandai area luas dan memancing respon korban.",
	"effects": {
		"scan_radius": 10,
		"single_use": true
	},
	"rules": {}
},

"Radio Scanner": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_senter-removebg-preview.png"),
	"description": "Mendeteksi sinyal suara dan reruntuhan aktif.",
	"effects": {
		"detect_paths": true,
		"delay": 2
	},
	"rules": {}
},

"Beacon Suara": {
	"category": "COMM",
	"usage_context": ["MAP"],
	"icon": preload("res://assets/tilesets/item_icon/item_p3k-removebg-preview.png"),
	"description": "Menarik suara balasan korban dari area tertentu.",
	"effects": {
		"lure_npc": true
	},
	"rules": {
		"static_position": true
	}
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
	"icon": preload("res://assets/tilesets/item_icon/item_senter-removebg-preview.png"),
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


# ==================================
# UI HELPER (OPSIONAL TAPI AMAN)
# ==================================
func get_total_victim() -> int:
	if current_mission.has("total_victim"):
		return current_mission["total_victim"]
	return 0


func get_remaining_time() -> int:
	return time_left
