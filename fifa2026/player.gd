extends Node3D

@onready var ball
@onready var cage
@onready var player = $CharacterBody3D
@onready var camera_player = $CharacterBody3D/TwistPivot/PitchPivot/Camera3D
@onready var camera_back = $CharacterBody3D/TwistPivot/Camera3DBack
@onready var twist_pivot = $CharacterBody3D/TwistPivot
@onready var pitch_pivot = $CharacterBody3D/TwistPivot/PitchPivot
@onready var collisionshape_player = $CharacterBody3D/CollisionShape3D
@export var have_ball : bool = false
@export var locked_ball = false
@export var o_player : Node3D
@export var o_goal : Node3D

var ALL_PLAYER = []

var gravity = 9.8

var twist_input := 0.0
var pitch_input := 0.0
var speed = 5.0

var shoot_power = 0.0  # Puissance actuelle du tir
var max_shoot_power = 60.0  # Puissance maximale
var shoot_charge_time = 0.5  # Temps maximum pour charger la puissance (en secondes)

@export var shot = false

var push_ball = true
var distanceb = 2.0

var which_view = 1
var twist_speed = 2.0 # Vitesse de rotation en radians/seconde

#assist
var rotation_speed = 3.0  # Vitesse de rotation (tu peux ajuster)
var max_twist_speed = 2.0  # Valeur maximale de twist_input, genre pour simuler le joueur humain

@export var active = false
@export var assist = false
var go_toball = false
var pass_tome = false

#-----------------BRAIN---------------------
var move : bool = false
var shoot_goal : bool = false

var move_target_pos : Vector2 


#----------END BRAIN ---------------------------


func _physics_process(delta):
	if not assist:
		_process_me(delta)
	else:
		_process_assist(delta, active)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if active:
		camera_player.make_current()
		
	which_view = 1
	player.velocity = Vector3.ZERO

func _process(delta: float) -> void:
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process_me(delta: float) -> void:
	if Input.is_action_just_pressed("camera_back"):
		camera_back.make_current()
		which_view = 2
	elif Input.is_action_just_pressed("camera_first_person"):
		camera_player.make_current()
		which_view = 1
	
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0

	# Rotation caméra / joueur
	twist_input = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
			
		
	# Inputs
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	
	var deadzone = 0.1

	if abs(input_x) < deadzone:
		input_x = 0
	if abs(input_z) < deadzone:
		input_z = 0
		
		

	# Vecteur brut basé sur les inputs
	var input_f = Vector3(input_x, 0, -input_z)

	# Tourner le vecteur selon la rotation du twist_pivot (ou de la caméra)
	input_f = twist_pivot.global_transform.basis * input_f

	# Normaliser si besoin
	if input_f.length() > 0:
		input_f = input_f.normalized()

	# Appliquer la direction à la vitesse
	player.velocity.x = input_f.x * speed
	player.velocity.z = input_f.z * speed
	
	# Toujours appeler move_and_slide() !
	player.move_and_slide()
	
	#print("Player sees locked_ball as:", locked_ball)
	
	if ball:
		var ball_pos = ball.global_transform.origin
		var player_pos = player.global_transform.origin
		var distance = player_pos.distance_to(ball_pos)
		
		have_ball = (distance <= 2.5) and (ball_pos.y <= 2.5)
							
		if have_ball and not locked_ball:
			var cam_forward = Vector3.ZERO
			var cam_right = Vector3.ZERO
			if which_view == 1:
				cam_forward = -camera_player.global_transform.basis.z
				cam_right = -camera_player.global_transform.basis.x  # Direction gauche/droite

			elif which_view == 2:
				cam_forward = -camera_back.global_transform.basis.z
				cam_right = -camera_back.global_transform.basis.x  # Direction gauche/droite
				
							
			if Input.is_action_pressed("shoot_player1"):
				# Augmente la puissance au fil du temps d'appui
				shoot_power = min(shoot_power + delta * (max_shoot_power / shoot_charge_time), max_shoot_power)
			elif Input.is_action_just_released("shoot_player1"):
				# Quand tu relâches la touche, applique la puissance
				shot = true
				var distancec = player_pos.distance_to(cage.global_transform.origin)
				# Calculer la direction devant le joueur (on prend la direction où le joueur regarde)
				var forward_dir = cam_forward # Direction devant le joueur, en fonction du pivot
				forward_dir.y = 0  # Ignorer l'axe vertical pour garder la balle à plat
								
				# Prendre en compte la vitesse du joueur pour ajuster la direction du tir
				# Si le joueur avance, la direction de tir devrait correspondre à son mouvement
				#var player_velocity = player.velocity
				#if player_velocity.length() > 0:
					# Calculer la direction en fonction de la vitesse du joueur
				#	forward_dir = player_velocity  # La direction du mouvement du joueur

				# Calcul de la hauteur du tir (en fonction de la distance)
				var height_factor = clamp(distancec / 100.0, 0.2, 2.0)  # Ajuste la hauteur en fonction de la distance
				#print(height_factor)
				# Calculer la direction du tir (l'ajustement de hauteur sera ajouté à la direction devant le joueur)
				var shoot_direction = forward_dir + Vector3(0, height_factor, 0)  # Direction finale avec hauteur ajoutée
				#print(shoot_direction.x, " ", shoot_direction.y, " ", shoot_direction.z)
				
				# Appliquer l'impulsion dans la direction du tir
				ball.angular_velocity = Vector3.ZERO
				ball.linear_velocity = Vector3.ZERO
				ball.apply_impulse(shoot_direction.normalized() * shoot_power)

				# Réinitialiser la puissance pour le prochain tir
				shoot_power = 0.0
		
			
			if not shot :
				# Distance de la balle par rapport au joueur (en avant)
				if input_z > 0.5:
					if push_ball:
						distanceb += 2 * delta 
					else:
						distanceb -= 2 * delta 
					if distanceb >= 2.0:
						push_ball = false
						
					if distanceb <= 1.5:
						push_ball = true
								
				# Direction avant du joueur (là où il regarde)
				var forward_dir = -twist_pivot.global_transform.basis.z
				forward_dir.y = 0
				forward_dir = forward_dir.normalized()

				# Position exacte où on veut placer la balle
				var ball_target_position = player.global_transform.origin + forward_dir * distanceb

				# On garde la hauteur de la balle au même niveau
				ball_target_position.y = 0.1

				# On positionne directement la balle devant le joueur
				ball.global_transform.origin = ball_target_position

								
				ball.rotate_y(twist_input)
				ball.rotate_x(input_z)
				ball.rotate_z(input_x)

				# Appliquer la rotation à la balle
				ball.angular_velocity = Vector3.ZERO

				# Si tu veux annuler les autres vitesses (lorsque la balle ne doit pas se déplacer de façon indépendante)
				ball.linear_velocity = Vector3.ZERO
					
					
		else:
			shot = false
	
	
	
	

	if twist_input > 0.1:
		twist_pivot.rotate_y(-twist_speed * delta)
		#ball.rotate_x(twist_input*0.1)
		ball.rotate_z(-twist_input)
	elif twist_input < -0.1:
		twist_pivot.rotate_y(twist_speed * delta)
		#ball.rotate_x(twist_input*0.1)
		ball.rotate_z(twist_input)

	
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))

	# Reset inputs (optionnel si tu en as besoin ailleurs)
	twist_input = 0.0
	pitch_input = 0.0
		
		
func update_twist_to_ball(delta)->float:
	# --- 1. Vecteur direction du joueur vers la balle (sur le plan XZ uniquement) ---
	var player_pos = twist_pivot.global_transform.origin
	var ball_pos = ball.global_transform.origin
	
	var to_ball = (ball_pos - player_pos)
	to_ball.y = 0  # On ignore la hauteur
	to_ball = to_ball.normalized()
	
	# --- 2. Obtenir la direction actuelle du joueur (forward) ---
	var player_forward = -twist_pivot.global_transform.basis.z
	player_forward.y = 0
	player_forward = player_forward.normalized()

	# --- 3. Calculer l'angle entre le forward du joueur et la direction vers la balle ---
	var angle_to_ball = player_forward.signed_angle_to(to_ball, Vector3.UP)

	# --- 4. Créer un twist_input basé sur cet angle ---
	return angle_to_ball #clamp(angle_to_ball, -max_twist_speed, max_twist_speed)

func update_twist_to_player(delta:float, target_player)->float:
	# --- 1. Vecteur direction du joueur vers la balle (sur le plan XZ uniquement) ---
	var player_pos = twist_pivot.global_transform.origin
	var ball_pos = target_player.global_transform.origin
	
	var to_ball = (ball_pos - player_pos)
	to_ball.y = 0  # On ignore la hauteur
	to_ball = to_ball.normalized()
	
	# --- 2. Obtenir la direction actuelle du joueur (forward) ---
	var player_forward = -twist_pivot.global_transform.basis.z
	player_forward.y = 0
	player_forward = player_forward.normalized()

	# --- 3. Calculer l'angle entre le forward du joueur et la direction vers la balle ---
	var angle_to_ball = player_forward.signed_angle_to(to_ball, Vector3.UP)

	# --- 4. Créer un twist_input basé sur cet angle ---
	return angle_to_ball #clamp(angle_to_ball, -max_twist_speed, max_twist_speed)
	
func update_twist_to_pos(delta:float, target_player)->float:
	# --- 1. Vecteur direction du joueur vers la balle (sur le plan XZ uniquement) ---
	var player_pos = twist_pivot.global_transform.origin
	var ball_pos = target_player
	
	var to_ball = (ball_pos - player_pos)
	to_ball.y = 0  # On ignore la hauteur
	to_ball = to_ball.normalized()
	
	# --- 2. Obtenir la direction actuelle du joueur (forward) ---
	var player_forward = -twist_pivot.global_transform.basis.z
	player_forward.y = 0
	player_forward = player_forward.normalized()

	# --- 3. Calculer l'angle entre le forward du joueur et la direction vers la balle ---
	var angle_to_ball = player_forward.signed_angle_to(to_ball, Vector3.UP)

	# --- 4. Créer un twist_input basé sur cet angle ---
	return angle_to_ball #clamp(angle_to_ball, -max_twist_speed, max_twist_speed)
	
	
func get_auto_inputs(target_pos : Vector3) -> Vector2:
	# --- Position du joueur et de la balle ---
	var player_pos = twist_pivot.global_transform.origin
	var ball_pos = target_pos
	
	# --- Direction vers la balle ---
	var to_ball = (ball_pos - player_pos)
	to_ball.y = 0
	to_ball = to_ball.normalized()

	# --- Forward et Right du joueur (twist_pivot) ---
	var forward = -twist_pivot.global_transform.basis.z
	var right = twist_pivot.global_transform.basis.x
	
	forward.y = 0
	right.y = 0
	
	forward = forward.normalized()
	right = right.normalized()

	# --- Projeter la direction vers la balle sur ces axes ---
	var input_z = forward.dot(to_ball)  # Avancer/reculer
	var input_x = right.dot(to_ball)    # Gauche/droite

	# --- Optionnel : clamp pour lisser ---
	input_z = clamp(input_z, -1.0, 1.0)
	input_x = clamp(input_x, -1.0, 1.0)

	return Vector2(input_x, input_z)
		
		
func passe_vers_joueur(target_player):
	# Position de la balle et du joueur cible
	var ball_pos = ball.global_transform.origin
	var target_pos = target_player.global_transform.origin
	
	# Direction vers le joueur
	var dir_to_player = target_pos - ball_pos
	dir_to_player.y = 0  # Passe à plat (si tu veux que ça reste ras du sol)
	
	var distance = dir_to_player.length()
	
	# --- Paramètres du tir ---
	var base_power = 5.0  # Force minimale
	var power_multiplier = 1.75  # Influence de la distance sur la force
	
	var shoot_power = clamp(base_power + distance/5.0 * power_multiplier, 3.0, 60.0)
	
	# --- Optionnel : ajouter une courbe à la passe ---
	var height_factor = clamp(0.2 * distance / 10.0, 0.2, 1.0)
	dir_to_player = dir_to_player.normalized()
	
	# Passe légèrement en hauteur
	var passe_direction = dir_to_player + Vector3(0, height_factor, 0)
	
	# --- On applique l'impulsion ---
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	
	shot = true
	ball.apply_impulse(passe_direction.normalized() * shoot_power)

	# Debug print
	print("Passe vers le joueur avec puissance :", shoot_power)
		
func tir_vers_but():
	# Position de la balle et du joueur cible
	var ball_pos = ball.global_transform.origin
	var target_pos = Vector3(-3, 0.0, -6.42)
	var stepv = 6.0 / 50.0
	var dmax = -1000000.0
	var stepvres = Vector3.ZERO
	for i in range(50):
		var dist =  target_pos.distance_to(o_goal.player.global_transform.origin)
		if dist > dmax:
			dmax = dist
			stepvres = target_pos 
						
		target_pos.x += stepv
	
	target_pos = stepvres	
	
	# Direction vers le joueur
	var dir_to_player = target_pos - ball_pos
	dir_to_player.y = 0  # Passe à plat (si tu veux que ça reste ras du sol)
	
	var distance = dir_to_player.length()
	
	# --- Paramètres du tir ---
	var base_power = 10.0  # Force minimale
	var power_multiplier = 1.75  # Influence de la distance sur la force
	
	var shoot_power = clamp(base_power + distance/2.0 * power_multiplier, 15.0, 100.0)*2.0
	
	# --- Optionnel : ajouter une courbe à la passe ---
	var height_factor = clamp(shoot_power / 100.0, 0.05, 0.15)
	dir_to_player = dir_to_player.normalized()
	
	# Passe légèrement en hauteur
	var passe_direction = dir_to_player + Vector3(0, height_factor, 0)
	
	# --- On applique l'impulsion ---
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	
	shot = true
	ball.apply_impulse(passe_direction.normalized() * shoot_power)

	# Debug print
	print("Tir vers le but avec puissance :", shoot_power)
		
		
		
func orienter_IA_vers_joueur(target_player):
	var ai_pos = player.global_transform.origin
	var target_pos = target_player.global_transform.origin
	
	var dir_to_target = target_pos - ai_pos
	dir_to_target.y = 0
	
	var distance = dir_to_target.length()
	
	if distance < 0.1:
		return 0.0
	
	dir_to_target = dir_to_target.normalized()
	
	var forward = -player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var dot = forward.dot(dir_to_target)
	var angle = forward.angle_to(dir_to_target)
	var cross = forward.cross(dir_to_target).y
	
	# DEBUG
	print("distance:", distance, "dot:", dot, "angle:", rad_to_deg(angle), "cross:", cross)
	
	# Seuil dynamique si c'est loin
	var seuil_dot_base = 0.95
	var seuil_dot_far = 0.85
	var seuil_distance = 10.0
	
	var seuil_dot = seuil_dot_base
	if distance > seuil_distance:
		seuil_dot = seuil_dot_far
	
	var seuil_angle_stop = deg_to_rad(10)
	
	# Si aligné, on arrête
	if dot > seuil_dot or angle < seuil_angle_stop:
		# Option : faire la passe ici
		# faire_passe(target_player)
		return 0.0
	
	# Dead zone cross => on ne tourne plus
	if abs(cross) < 0.01:
		return 0.0
	
	# Tourner dans la bonne direction
	var twist_input = deg_to_rad(2.5)
	if cross < 0:
		twist_input *= -1
	
	# Ralentir la rotation si l'angle est petit
	twist_input *= clamp(angle / PI, 0.1, 1.0)
	
	return twist_input

var GOAL_LINE_Z = -6.4  # Position de la ligne de but

func anti_blockage(delta: float) -> Vector3:
	var player_pos = player.global_transform.origin
	var new_target = Vector3.ZERO
	var count = 0
	
	# --- Interaction avec les autres joueurs (comme avant) ---
	ALL_PLAYER = [
		o_goal.player.global_transform.origin,
		Vector3(-3.7, 0.0, -6.42),  # poteau gauche
		Vector3(3.5, 0.0, -6.42)    # poteau droit
	]
	
		
				
	for pl in ALL_PLAYER:
		var dir_to_other = (pl - player_pos).normalized()
		#var dot = (-player.global_transform.basis.z).dot(dir_to_other)
		var dist = player_pos.distance_to(pl)
		
		if dist < 1.0:
			var cross_dir = dir_to_other.cross(Vector3.UP).normalized()
			new_target += cross_dir * 3.0
			count += 1
	
	# --- Retourner une nouvelle destination si bloqué ---
	if count > 0:
		return player_pos + new_target.normalized() * 50.0
	else:
		return Vector3(-1000000, -1000000, -1000000)

	
func _process_assist(delta: float, active : bool) -> void:
	
	if active:
		if Input.is_action_just_pressed("camera_back"):
			camera_back.make_current()
			which_view = 2
		elif Input.is_action_just_pressed("camera_first_person"):
			camera_player.make_current()
			which_view = 1
	
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0

	# Rotation caméra / joueur
	twist_input = update_twist_to_ball(delta)
			
	var input_xz = Vector2.ZERO
		
	var coeq_pos = o_player.player.global_transform.origin
	if not o_player.have_ball and not have_ball:
		go_toball = true
	else:
		go_toball = false
		
	if go_toball:
		
		var ab = anti_blockage(delta)
		if ab.x == -1000000:
			input_xz = get_auto_inputs(ball.global_transform.origin)
		else:
			input_xz = get_auto_inputs(ab)
	else:
		var player_pos = player.global_transform.origin
		if coeq_pos.distance_to(player_pos) >= 5.0:
			input_xz = get_auto_inputs(coeq_pos)
			
	# Inputs
	var input_x = input_xz.x
	var input_z = input_xz.y
		
	var deadzone = 0.1

	if abs(input_x) < deadzone:
		input_x = 0
	if abs(input_z) < deadzone:
		input_z = 0
		
		

	# Vecteur brut basé sur les inputs
	var input_f = Vector3(input_x, 0, -input_z)

	# Tourner le vecteur selon la rotation du twist_pivot (ou de la caméra)
	input_f = twist_pivot.global_transform.basis * input_f

	# Normaliser si besoin
	if input_f.length() > 0:
		input_f = input_f.normalized()
		
	
	# Appliquer la direction à la vitesse
	player.velocity.x = input_f.x * speed 
	player.velocity.z = input_f.z * speed 
	

	# Toujours appeler move_and_slide() !
	player.move_and_slide()
	
	#print("Player sees locked_ball as:", locked_ball)
	
	if ball:
		var ball_pos = ball.global_transform.origin
		var player_pos = player.global_transform.origin
		var distance = player_pos.distance_to(ball_pos)
		
		have_ball = (distance <= 2.5) and (ball_pos.y <= 2.5)
							
		if have_ball and not locked_ball:
			var cam_forward = Vector3.ZERO
			var cam_right = Vector3.ZERO
			if which_view == 1:
				cam_forward = -camera_player.global_transform.basis.z
				cam_right = -camera_player.global_transform.basis.x  # Direction gauche/droite

			elif which_view == 2:
				cam_forward = -camera_back.global_transform.basis.z
				cam_right = -camera_back.global_transform.basis.x  # Direction gauche/droite
				
				
			
			if not shot :
				# Distance de la balle par rapport au joueur (en avant)
				distanceb = 2.0
				
				# Direction avant du joueur (là où il regarde)
				var forward_dir = -twist_pivot.global_transform.basis.z
				forward_dir.y = 0
				forward_dir = forward_dir.normalized()

				# Position exacte où on veut placer la balle
				var ball_target_position = player.global_transform.origin + forward_dir * distanceb

				# On garde la hauteur de la balle au même niveau
				ball_target_position.y = 0.1

				# On positionne directement la balle devant le joueur
				ball.global_transform.origin = ball_target_position

								
				ball.rotate_y(twist_input)
				ball.rotate_x(input_z)
				ball.rotate_z(input_x)

				# Appliquer la rotation à la balle
				ball.angular_velocity = Vector3.ZERO

				# Si tu veux annuler les autres vitesses (lorsque la balle ne doit pas se déplacer de façon indépendante)
				ball.linear_velocity = Vector3.ZERO
				
				if player.global_transform.origin.distance_to(cage.global_transform.origin) < 20.0:
					twist_input = update_twist_to_pos(delta, cage.global_transform.origin)
					if abs(twist_input) < deg_to_rad(5):
						tir_vers_but()
				else:
					twist_input= update_twist_to_player(delta, o_player.player)
							
					if abs(twist_input) < deg_to_rad(5):
						passe_vers_joueur(o_player.player)
					
					
		else:
			#if ball.global_transform.origin.distance_to(player.global_transform.origin) > 2.0:
			shot = false
	
	
	
	
	twist_pivot.rotate_y(twist_input)
	if twist_input > 0.1:
		ball.rotate_z(-twist_input)
	elif twist_input < -0.1:
		ball.rotate_z(twist_input)

	
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))

	# Reset inputs (optionnel si tu en as besoin ailleurs)
	twist_input = 0.0
	pitch_input = 0.0



func _unhandled_input(event: InputEvent) -> void:
	
	if active:
		if event is InputEventJoypadMotion:
			#if event.axis == JOY_AXIS_RIGHT_X:
			#	twist_input = -event.axis_value
				
			if event.axis == JOY_AXIS_RIGHT_Y:
				pitch_input = event.axis_value * 0.1
