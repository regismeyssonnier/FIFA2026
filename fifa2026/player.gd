extends Node3D

@onready var ball
@onready var cage
@onready var player = $CharacterBody3D
@onready var camera_player = $CharacterBody3D/TwistPivot/PitchPivot/Camera3D
@onready var camera_back = $CharacterBody3D/TwistPivot/Camera3DBack
@onready var twist_pivot = $CharacterBody3D/TwistPivot
@onready var pitch_pivot = $CharacterBody3D/TwistPivot/PitchPivot
@export var have_ball : bool = false
@export var locked_ball = false

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

func _physics_process(delta):
	pass	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_player.make_current()
	which_view = 1
	player.velocity = Vector3.ZERO



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
	
	

	# Appliquer les inputs sur X/Z
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
		

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventJoypadMotion:
		#if event.axis == JOY_AXIS_RIGHT_X:
		#	twist_input = -event.axis_value
			
		if event.axis == JOY_AXIS_RIGHT_Y:
			pitch_input = event.axis_value * 0.1
