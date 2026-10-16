--!strict

local Config = {
	TEAM_SIZE = 3,
	DEBUG_ALLOW_SOLO = game:GetService("RunService"):IsStudio(),
	COUNTDOWN_SECONDS = 10,
	POINTS_PER_SET = 25,
	DECISIVE_SET_POINTS = 15,
	SETS_TO_WIN = 2,
	SERVE_LIMIT_SECONDS = 8,
	MAX_CONTACT_DISTANCE = 6,
	MAX_REMOTE_RATE = 0.12,
	BALL_GRAVITY = 60,
	DATASTORE_NAME = "IndoorVolleyball_v1",

	Court = {
		LENGTH = 64,
		WIDTH = 32,
		FLOOR_THICKNESS = 1,
		NET_HEIGHT = 9,
		NET_THICKNESS = 0.25,
		ATTACK_LINE_DISTANCE = 10.7,
		BOUNDARY_HEIGHT = 45,
		BOUNDARY_THICKNESS = 1,
		SERVE_ZONE_DEPTH = 8,
		OBBY_START = Vector3.new(46, 4, 180),
	},

	Lobby = {
		CENTER = Vector3.new(0, 0, 180),
		FLOOR_SIZE = Vector3.new(72, 1, 52),
		SPAWN_OFFSET = Vector3.new(-26, 1, 12),
	},

	Colors = {
		CourtFloor = Color3.fromRGB(35, 105, 155),
		CourtLine = Color3.fromRGB(245, 245, 235),
		Net = Color3.fromRGB(35, 35, 38),
		Post = Color3.fromRGB(190, 195, 205),
		LobbyFloor = Color3.fromRGB(85, 105, 115),
		LobbyWall = Color3.fromRGB(50, 70, 82),
		PlayPad = Color3.fromRGB(45, 190, 95),
		TrainingPad = Color3.fromRGB(55, 145, 220),
	},

	Obby = {
		StageCount = 20,
		BadgeId = 0,
		EnableSkipProduct = false,
		SkipProductId = 0,
		BestTimeStore = "VolleyballObbyBestTime_v1",
		LeaderboardRefreshSeconds = 120,
		StageGapLimit = { 4.5, 5.5, 6.5, 7.5 },
		ZoneColors = {
			Color3.fromRGB(77, 177, 112),
			Color3.fromRGB(58, 143, 203),
			Color3.fromRGB(164, 102, 201),
			Color3.fromRGB(225, 158, 68),
		},
		StageTypes = {
			"Benches", "LargeJumps", "NarrowWalkway", "Zigzag", "Fading",
			"NetClimb", "Sweeper", "Conveyor", "MovingPlatforms", "RollingBalls",
			"Arc", "Lasers", "Discs", "Pillars", "Trampolines",
			"Elevators", "DoubleSweepers", "Blinking", "SpikeJump", "Podium",
		},
	},
}

return Config
