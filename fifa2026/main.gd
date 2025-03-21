extends Node3D

@onready var ball = $BallRigidBody3D
@onready var cage = $Cage/StaticBody3D
@onready var player = $Player
@onready var goal = $Goal
@onready var player2 = $Player_2

@onready var trajectory_mesh = ImmediateMesh.new()
@onready var trajectory_instance = MeshInstance3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.cage = cage
	player2.cage = cage
	trajectory_instance.mesh = trajectory_mesh
	add_child(trajectory_instance)

func draw_trajectory():
	var points = goal._draw_ball_trajectory(ball.global_transform.origin, ball.linear_velocity, -9.81)

	# Redessiner à chaque frame
	trajectory_mesh.clear_surfaces()  # Enlève l'ancienne surface si tu veux mettre à jour

	trajectory_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for point in points:
		trajectory_mesh.surface_add_vertex(point)

	trajectory_mesh.surface_end()

func shoot_ball():
	# Direction vers laquelle tu veux tirer
	var direction = Vector3(0, 0, -1)

	# Force d'impulsion
	var power = 10.0  # Change la force du tir selon ce que tu veux

	# Applique une impulsion au ballon
	ball.apply_impulse(direction * power)

func _physics_process(delta):
	player.ball = ball
	goal.ball = ball
	player2.ball = ball
	player2.o_player = player
	player2.o_goal = goal
	
func _on_GoalZone_body_entered(body):
	if body.name == "BallRigidBody3D":  # ou vérifie une autre condition
		print("GOOOOAAALLL !!")
		# Tu peux lancer une anim, ajouter un score, reset la balle, etc.

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		
	if Input.is_action_just_pressed("reset"):
		# Réinitialiser la vitesse linéaire
		#ball.linear_velocity = Vector3.ZERO  # Réinitialiser la vitesse
		
		# Calculer la direction du tir en fonction de l'orientation de la caméra du joueur
		var cam_forward = -player.camera_player.global_transform.basis.z
		cam_forward.y = 0  # Ignorer l'axe vertical
		var player_pos = player.player.global_transform.origin
		player_pos.y = 0.1
		# Placer la balle juste devant le joueur
		ball.global_transform.origin = player_pos + cam_forward.normalized() * 2.0  # Positionner devant le joueur à une distance de 2 unités

		goal.player.global_transform.origin = Vector3(0.0, 2.0, -6.0)

	if Input.is_action_just_pressed("shoot") and player.have_ball:
		shoot_ball()
		
	player.locked_ball = goal.have_ball
	if player.shot:
		draw_trajectory()
	
	#coequipier
	player2.locked_ball = goal.have_ball
	if player2.shot:
		draw_trajectory()
	#print("Main set locked_ball to:", player.locked_ball)
		
