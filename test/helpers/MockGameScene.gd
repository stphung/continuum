extends Node
## Mock Game Scene for testing Kiosk Mode integration


var is_paused: bool = false
var player_spawned: bool = false

func pause_game():
	"""Mock game pause functionality"""
	is_paused = true
	print("MockGameScene: Game paused")

func resume_game():
	"""Mock game resume functionality"""
	is_paused = false
	print("MockGameScene: Game resumed")

func spawn_player():
	"""Mock player spawning"""
	if not has_node("Player"):
		var mock_player = Node.new()
		mock_player.name = "Player"
		mock_player.set_script(preload("res://test/helpers/MockPlayer.gd"))
		mock_player.add_to_group("player")
		add_child(mock_player)
		player_spawned = true
		print("MockGameScene: Player spawned")



func reset_game():
	"""Reset game state for new demo"""
	is_paused = false
	if has_node("Player"):
		get_node("Player").queue_free()
	player_spawned = false