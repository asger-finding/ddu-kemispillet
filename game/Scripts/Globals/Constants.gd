extends Node

# Scenes
const DEFAULT_SCENE = "Menu/ConfigureConnectionMenu"

# World
const GRAVITY := 6500.0
const SPAWN_POSITION := Vector2(7953.0, -961.0)
const COUNTDOWN_TIME := 5.0 # s

# Questions
const TIME_BETWEEN_QUESTIONS := 60.0 # s
const WRONG_ANSWER_LOCK_TIME := 20.0 #s
const QUESTION_POPUP_AUTOCLOSE_TIME := 30.0 # s
const QUESTIONS = [
	{
		"CHAPTER": "Elektronparbindinger",
		"KEY": 0,
		"QUESTION": "Navngiv stoffet CO₂",
		"DESCRIPTION": "Navngivning følger antal iltatomer; “di-oxid” angiver to iltatomer bundet til kulstof.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "Kuldioxid"
	},
	{
		"CHAPTER": "Elektronparbindinger",
		"KEY": 1,
		"QUESTION": "Navngiv stoffet N₂O₃",
		"DESCRIPTION": "Præfikser angiver antal; to nitrogenatomer og tre iltatomer giver dinitrogentrioxid.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "Dinitrogentrioxid"
	},
	{
		"CHAPTER": "Elektronparbindinger",
		"KEY": 2,
		"QUESTION": "Hvor mange elektroner har H₂?",
		"DESCRIPTION": "H₂ består af to hydrogenatomer med én elektron hver; summen er to.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "2"
	},
	{
		"CHAPTER": "Elektronparbindinger",
		"KEY": 3,
		"QUESTION": "Er bindingen mellem H og Cl polær eller upolær",
		"DESCRIPTION": "Elektronegativitetsforskellen mellem H og Cl er betydelig; elektronparret forskydes mod chlor.",
		"ANSWER_TYPE": "RADIO",
		"OPTIONS": ["Polær", "Upolær"],
		"ANSWER": 0
	},
	{
		"CHAPTER": "Elektronparbindinger",
		"KEY": 4,
		"QUESTION": "Kan polære stoffer opløses i vand",
		"DESCRIPTION": "Vand er polært; polære molekyler interagerer gunstigt via dipol-dipol-kræfter.",
		"ANSWER_TYPE": "RADIO",
		"OPTIONS": ["Ja", "Nej"],
		"ANSWER": 0
	},

	{
		"CHAPTER": "Grundstoffer",
		"KEY": 5,
		"QUESTION": "Givet isotop 238,92-Uranium, angiv antal protoner, neutroner og elektroner?",
		"DESCRIPTION": "Atomnummer giver protoner og elektroner; neutroner fås ved massetal minus atomnummer.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "Protoner: 92, Neutroner: 146, Elektroner: 92"
	},
	{
		"CHAPTER": "Grundstoffer",
		"KEY": 6,
		"QUESTION": "Hvilke af disse atomer er ædelgasser?\nHe, Ne, Ar, N₂, O₂",
		"DESCRIPTION": "Ædelgasser findes i gruppe 18; de øvrige er ikke i gruppen.",
		"ANSWER_TYPE": "CHECKBOX",
		"OPTIONS": ["He", "Ne", "Ar", "N₂", "O₂"],
		"ANSWER": ["He", "Ne", "Ar"]
	},
	{
		"CHAPTER": "Ionforbindelser",
		"KEY": 7,
		"QUESTION": "Skriv kemisk formel for ionforbindelsen kobber(II)oxid",
		"DESCRIPTION": "Cu²⁺ kombineres med O²⁻ i forholdet 1:1.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "CuO"
	},
	{
		"CHAPTER": "Ionforbindelser",
		"KEY": 8,
		"QUESTION": "Skriv kemisk formel for det fleratomige ion hydroxid",
		"DESCRIPTION": "Hydroxid består af oxygen og hydrogen og har ladningen minus en.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "OH⁻"
	},
	{
		"CHAPTER": "Ionforbindelser",
		"KEY": 9,
		"QUESTION": "Skriv kemisk formel for det fleratomige ion sulfat",
		"DESCRIPTION": "Sulfat består af et svovlatom og fire oxygenatomer og bærer ladningen minus to.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "SO₄²⁻"
	},
	{
		"CHAPTER": "Mængdeberegning",
		"KEY": 10,
		"QUESTION": "Hvor mange gram vand svarer til 0,25 mol? (M = 18,0 g/mol)",
		"DESCRIPTION": "Masse beregnes ved n·M; n=mol, M=g/mol.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "4,5 g"
	},
	{
		"CHAPTER": "Mængdeberegning",
		"KEY": 11,
		"QUESTION": "Beregn volumen af 0,50 mol O₂ ved 25 °C (298 K) og trykket er 2 bar. (R = 8,31 J/(mol·K))",
		"DESCRIPTION": "Brug idealgasloven V = nRT/p; tryk omregnes til pascal og resultatet til liter.",
		"ANSWER_TYPE": "TEXT",
		"ANSWER": "6,19 L"
	}
]

# Connection states
const OFFLINE = "offline"
const ONLINE = "online"
const HANDSHAKED = "handshaked"
const SERVER = "server"
