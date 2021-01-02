extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(5)
	yield(yield_for(0.1), YIELD)
	card = cards[0]
	target = cards[2]


# Checks that custom scripts fire correctly
func test_custom_script():
	card = cards[2]
	# Custom scripts have to be predefined in code
	# So not possible to specify them as runtime scripts
	card.execute_scripts()
	yield(yield_for(0.1), YIELD)
	assert_freed(card, "Test Card 2")
	card = cards[1]
	target = cards[3]
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_for(0.3), YIELD)
	assert_freed(target, "Test Card 1")


func test_rotate_card():
	card.scripts = {"manual": {"board": [
			{"name": "rotate_card",
			"subject": "self",
			"degrees": 90}]}}
	yield(table_move(card, Vector2(100,200)), "completed")
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 90,
			"Card should be rotated 90 degrees")


func test_flip_card():
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": false}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(target.is_faceup,
			"Target should be face-down")
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": true}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(target.is_faceup,
			"Target should be face-up again")


func test_move_card_to_container():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "self",
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.discard,card.get_parent(),
			"Card should have moved to discard pile")
	card = cards[1]
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "self",
			"dest_index": 5,
			"dest_container":  cfc.NMAP.deck}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.deck,card.get_parent(),
			"Card should have moved to deck")
	assert_eq(5,card.get_my_card_index(),
			"Card should have moved to index 5")


func test_move_card_hand_to_board():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "self",
			"board_position":  Vector2(100,100)}]}}
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.board,card.get_parent(),
			"Card should have moved to board")
	assert_eq(Vector2(100,100),card.global_position,
			"Card should have moved to specified position")


func test_move_card_cont_to_cont():
	target = cfc.NMAP.deck.get_card(5)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_index": 5,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.discard,target.get_parent(),
			"Card should have moved to discard pile")
	target = cfc.NMAP.deck.get_card(3)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_index": 3,
			"dest_index": 1,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_eq(cfc.NMAP.discard,target.get_parent(),
			"Card should have moved to discard")
	assert_eq(1,target.get_my_card_index(),
			"Card should have moved to index 1")


func test_move_card_cont_to_board():
	yield(yield_for(0.2), YIELD)
	target = cfc.NMAP.deck.get_card(5)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"subject_index": 5,
			"src_container":  cfc.NMAP.deck,
			"board_position":  Vector2(1000,200)}]}}
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_for(0.2), YIELD)
	assert_almost_eq(Vector2(1000,200),target.global_position, Vector2(5,5),
			"Card should have moved to specified board position")
	target = cfc.NMAP.deck.get_card(0)
	var target2 = cfc.NMAP.deck.get_card(1)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"subject_count": 4,
			"subject_index": "bottom",
			"src_container":  cfc.NMAP.deck,
			"grid_name":  "BoardPlacementGrid"}]}}
	board.get_node("BoardPlacementGrid").visible = true
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_not_null(target._placement_slot,
			"Card should have moved to a grid slot")
	assert_not_null(target2._placement_slot,
			"Card should have moved to a grid slot")
	if target._placement_slot:
		assert_eq(target._placement_slot.get_grid_name(), "BoardPlacementGrid",
				"Card placed in the correct grid")
		assert_ne(target._placement_slot, target2._placement_slot,
				"Cards not placed in the same slot")


func test_mod_tokens():
	target.scripts = {"manual": {"hand": [
			{"name": "mod_tokens",
			"subject": "self",
			"modification": 5,
			"token_name":  "industry"}]}}
	target.execute_scripts()
	var industry_token: Token = target.tokens.get_token("industry")
	assert_eq(5,industry_token.count,"Token increased by specified amount")
	card.scripts = {"manual": {"hand": [
			{"name": "mod_tokens",
			"subject": "target",
			"modification": 2,
			"set_to_mod": true,
			"token_name":  "industry"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	# My scripts are slower now
	yield(yield_for(0.2), YIELD)
	assert_eq(2,industry_token.count,"Token set to specified amount")


func test_spawn_card():
	target.scripts = {"manual": {"hand": [
			{"name": "spawn_card",
			"scene_path": "res://src/custom/CGFCardTemplate.tscn",
			"object_count": 3,
			"board_position":  Vector2(500,200)}]}}
	target.execute_scripts()
	assert_eq(3,board.get_card_count(),
		"Card spawned on board")
	card = board.get_card(0)
	assert_eq("res://src/custom/CGFCardTemplate.tscn",card.filename,
		"Card of the correct scene spawned")
	assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
		"Spawned card left in correct state")
	assert_almost_eq(Vector2(500,200),card.position,Vector2(2,2),
		"Card spawned in correct location")
	var offsetx = CFConst.CARD_SIZE.x * CFConst.PLAY_AREA_SCALE.x
	assert_almost_eq(Vector2(500 + offsetx * 2,200),
			board.get_card(2).position,Vector2(2,2),
			"Third Card spawned in correct location")
	target.scripts = {"manual": {"hand": [
			{"name": "spawn_card",
			"scene_path": "res://src/custom/CGFCardTemplate.tscn",
			"object_count": 10,
			"grid_name":  "BoardPlacementGrid"}]}}
	target.execute_scripts()
	# Give time to the card to instance
	yield(yield_for(0.4), YIELD)
	assert_eq(7,board.get_card_count(),
		"5 Card spawned on grid")
	if board.get_card_count() > 1:
		card = board.get_card(3)
		assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
			"Spawned card left in correct state")
		assert_not_null(card._placement_slot,
				"Card should have moved to a grid slot")


func test_shuffle_container():
	card.scripts = {"manual": {"hand": [
			{"name": "shuffle_container",
			"dest_container":  cfc.NMAP.hand}]}}
	var rng_threshold: int = 0
	var prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	assert_gt(3,rng_threshold,
		"Card should not fall in he same spot too many times")


func test_attach_to_card():
	yield(table_move(target, Vector2(500,400)), "completed")
	card.scripts = {"manual": {"hand": [
			{"name": "attach_to_card",
			"subject": "target"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(card.current_host_card,target,
			"Card has been hosted on the target")


func test_host_card():
	yield(table_move(card, Vector2(500,400)), "completed")
	card.scripts = {"manual": {"board": [
			{"name": "host_card",
			"subject": "target"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(target.current_host_card,card,
			"target has been hosted on the card")


func test_modify_properties():
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Name": "GUT Test", "Type": "Orange"}}]}}
	card.execute_scripts()
	assert_eq("GUT Test",card.card_name,
			"Card name should be changed")
	assert_eq("GUT Test",card.card_name,
			"Card type should be changed")

func test_create_grid():
	card.scripts = {"manual": {"hand": [
			{"name": "add_grid",
			"scene_path": "res://src/custom/CGFPlacementGridDemo.tscn",
			"object_count": 2,
			"board_position":  Vector2(50,50)}]}}
	card.execute_scripts()
	yield(yield_for(0.1), YIELD)
	var grids: Array = get_tree().get_nodes_in_group("placement_grid")
	assert_eq(grids.size(), 3, "All grids were created")
	card.scripts = {"manual": {"hand": [
			{"name": "add_grid",
			"scene_path": "res://src/custom/CGFPlacementGridDemo.tscn",
			"grid_name": "GUT Grid",
			"object_count": 3,
			"board_position":  Vector2(600,50)}]}}
	card.execute_scripts()
	yield(yield_for(0.1), YIELD)
	var gut_grids := []
	for g in get_tree().get_nodes_in_group("placement_grid"):
		if not g in grids:
			gut_grids.append(g)
	for grid in gut_grids:
		assert_eq(grid.name_label.text, "GUT Grid",
				"Created grid has correct label")

func test_mod_counter():
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 5,
			"counter_name":  "research"}]}}
	card.execute_scripts()
	assert_eq(5,board.counters.get_counter("research"),
			"Counter increased by specified amount")
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 2,
			"set_to_mod": true,
			"counter_name": "credits"}]}}
	card.execute_scripts()
	assert_eq(2,board.counters.get_counter("credits"),
			"Counter set to the specified amount")

func test_execute_scripts():
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "manual",
			"require_exec_state": "hand"}]}}
	target.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "self",
			"board_position":  Vector2(100,100)}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(target.get_parent(),cfc.NMAP.board,
			"Card should have moved to board")
	target.scripts = {"manual": {"board": [
			{"name": "mod_tokens",
			"subject": "self",
			"modification": 1,
			"token_name":  "industry"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	var industry_token: Token = target.tokens.get_token("industry")
	assert_null(industry_token,
			"scripts not executed because exec state does not match")
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "manual",}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_for(0.1), YIELD)
	industry_token = target.tokens.get_token("industry")
	assert_not_null(industry_token,
			"scripts executed because exec state not defined")
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "false",}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_for(0.1), YIELD)
	industry_token = target.tokens.get_token("industry")
	assert_not_null(industry_token)
	if industry_token:
		assert_eq(industry_token.count, 1,
				"scripts not executed because exec_trigger does not match")

func test_execute_scripts_with_temp_mod_property():
	target.modify_property("Cost", 1)
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "manual",
			"exec_temp_mod_properties": {"Cost": 1},
			"require_exec_state": "hand"}]}}
	target.scripts = {"manual": {
		"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_count": "per_property",
			"src_container": deck,
			"dest_container": hand,
			"subject_index": "top",
			"per_property": {
				"subject": "self",
				"property_name": "Cost"}
			},
		]}
	}
	card.execute_scripts()
	yield(target_card(card,target, "slow"), "completed")
	yield(yield_for(0.5), YIELD)
	assert_eq(hand.get_card_count(), 7,
		"Draw the temp modified amount of cards")
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "manual",
			"exec_temp_mod_properties": {"Cost": -5},
			"require_exec_state": "hand"}]}}
	card.execute_scripts()
	yield(target_card(card,target, "slow"), "completed")
	yield(yield_for(0.5), YIELD)
	assert_eq(hand.get_card_count(), 7,
		"Ensure the property does not go negative")
	target.execute_scripts()
	assert_eq(hand.get_card_count(), 8,
		"Ensure temp property modifiers don't remain")

func test_execute_scripts_with_temp_mod_counter():
	cfc.NMAP.board.counters.mod_counter("research", 1)
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "manual",
			"exec_temp_mod_counters": {"research": 1},
			"require_exec_state": "hand"}]}}
	target.scripts = {"manual": {
		"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_count": "per_counter",
			"src_container": deck,
			"dest_container": hand,
			"subject_index": "top",
			"per_counter": {
				"counter_name": "research"}
			},
		]}
	}
	card.execute_scripts()
	yield(target_card(card,target, "slow"), "completed")
	yield(yield_for(0.5), YIELD)
	assert_eq(hand.get_card_count(), 7,
		"Draw the temp modified amount of cards")
	card.scripts = {"manual": {"hand": [
			{"name": "execute_scripts",
			"subject": "target",
			"exec_trigger":  "manual",
			"exec_temp_mod_counters": {"research": -5},
			"require_exec_state": "hand"}]}}
	card.execute_scripts()
	yield(target_card(card,target, "slow"), "completed")
	yield(yield_for(0.5), YIELD)
	assert_eq(hand.get_card_count(), 7,
		"Ensure the counter does not go negative")
	target.execute_scripts()
	assert_eq(hand.get_card_count(), 8,
		"Ensure temp property modifiers don't remain")
