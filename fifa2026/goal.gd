extends Node3D

@onready var ball
@onready var cage
@onready var player = $CharacterBody3D
@export var distance_to_player = 1000.0

var gravity_player = 9.81
var goal_plane_z = -6.0  # La ligne de but (ajuste selon ta scène)
var speed = 7.5

var have_ball = false
var shoot_power = 10.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _draw_ball_trajectory(ball_pos: Vector3, ball_velocity: Vector3, gravity: float, steps: int = 50, time_step: float = 0.1):
	var positions = []
	var current_pos = ball_pos
	var current_vel = ball_velocity
	
	for i in range(steps):
		positions.append(current_pos)
		
		# Simuler le mouvement
		current_vel.y += gravity * time_step  # On applique la gravité
		current_pos += current_vel * time_step  # On avance la position
		
	return positions

func predict_goal_intercept(ball_pos: Vector3, ball_velocity: Vector3, goal_planez: float, gravity: float = -9.81, max_steps: int = 50, time_step: float = 0.1) -> Dictionary:
	var current_pos = ball_pos
	var current_vel = ball_velocity
	
	for i in range(max_steps):
		if current_pos.z <= goal_planez and current_pos.x >= -4.0 and current_pos.x <= 4.0 and current_pos.y <= 3.5:
			return {
				"found": true,
				"position": current_pos
			}
		
		current_vel.y += gravity * time_step
		current_pos += current_vel * time_step
	
	return {
		"found": false,
		"position": Vector3.ZERO
	}

func player_dribble(delta)->bool:
	var res = false
	var ball_pos = ball.global_transform.origin
	var cage_pos = Vector3(0.0, 0.0, -6.0)
	
	var distance = cage_pos.distance_to(ball_pos)
	
	if distance < 5.0 and ball_pos.z > -6.42:
		#Déplacer le goal vers la cible (en restant sur le plan z du goal)
		player.global_transform.origin = player.global_transform.origin.move_toward(ball_pos, speed * delta)
		res = true
	
	
	return res
	

func catch_ball():
	# Stopper les mouvements
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	
	# Calculer la direction "devant" le joueur (là où il regarde)
	var forward_dir = player.global_transform.basis.z.normalized()
	
	# Placer la balle devant, légèrement en hauteur
	var offset = forward_dir * 1.5 + Vector3(0, 1, 0)  # 1.5 unités devant, 1m en hauteur
	
	# Positionner la balle
	ball.global_transform.origin = player.global_transform.origin + offset
	
	have_ball = true

func _physics_process(delta):
	
		
	var ball_pos = ball.global_transform.origin
	var ball_velocity = ball.linear_velocity
	
	var res = player_dribble(delta)
	# Prédire où la balle va croiser la ligne de but
		
	var result = predict_goal_intercept(ball_pos, ball_velocity, goal_plane_z)

	if not res and result.found:
		var target_pos = Vector3(result.position.x, result.position.y, goal_plane_z)
		var distance = player.global_transform.origin.distance_to(target_pos)

		if distance > 0.1:
			var move_dir = (target_pos - player.global_transform.origin).normalized() * speed
			player.velocity.x = move_dir.x
			player.velocity.z = move_dir.z
		else:
			player.velocity.x = 0
			player.velocity.z = 0
	else:
		player.velocity.x = 0
		player.velocity.z = 0


	if not player.is_on_floor():
		player.velocity.y -= gravity_player * delta
	else:
		player.velocity.y = 0
		
	player.move_and_slide()
	
	
		
	# Distance réelle à la balle (3D)
	var distance_to_ball = player.global_transform.origin.distance_to(ball_pos)
		
	# Vérifie si la balle est suffisamment proche pour l'attraper
	if distance_to_ball < 1.0:  # plus précis
		catch_ball()
	else:
		if have_ball and distance_to_ball > 5.0:
			have_ball = false
	# Si le goal a la balle, tirer !
	if have_ball:
		# Petite pause avant de tirer si tu veux (facultatif)
		# Sinon, tirer directement
		var shoot_direction = Vector3(0, 1.5, 5)  # Devant avec une courbe vers le haut
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.apply_impulse(shoot_direction.normalized() * shoot_power)
		print("shoot")
		
	

	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
