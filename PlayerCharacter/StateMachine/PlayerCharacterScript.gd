extends CharacterBody3D

class_name PlayerCharacter

@export_group("Movement variables")
var moveSpeed : float
var moveAccel : float
var moveDeccel : float
var desiredMoveSpeed : float 
@export var desiredMoveSpeedCurve : Curve
@export var maxSpeed : float
@export var inAirMoveSpeedCurve : Curve
var inputDirection : Vector2 
var moveDirection : Vector3 
@export var hitGroundCooldown : float #amount of time the character keep his accumulated speed before losing it (while being on ground)
var hitGroundCooldownRef : float 
@export var bunnyHopDmsIncre : float #bunny hopping desired move speed incrementer
@export var autoBunnyHop : bool = false
var lastFramePosition : Vector3 
var lastFrameVelocity : Vector3
var wasOnFloor : bool
var walkOrRun : String = "WalkState" #keep in memory if play char was walking or running before being in the air
#for crouch visible changes
@export var baseHitboxHeight : float
@export var baseModelHeight : float
@export var heightChangeSpeed : float

@export_group("Crouch variables")
@export var crouchSpeed : float
@export var crouchAccel : float
@export var crouchDeccel : float
@export var continiousCrouch : bool = false #if true, doesn't need to keep crouch button on to crouch
@export var crouchHitboxHeight : float
@export var crouchModelHeight : float

@export_group("Walk variables")
@export var walkSpeed : float
@export var walkAccel : float
@export var walkDeccel : float

@export_group("Run variables")
@export var runSpeed : float
@export var runAccel : float 
@export var runDeccel : float 
@export var continiousRun : bool = false #if true, doesn't need to keep run button on to run

@export_group("Jump variables")
@export var jumpHeight : float
@export var jumpTimeToPeak : float
@export var jumpTimeToFall : float
@onready var jumpVelocity : float = (2.0 * jumpHeight) / jumpTimeToPeak
@export var jumpCooldown : float
var jumpCooldownRef : float 
@export var nbJumpsInAirAllowed : int 
var nbJumpsInAirAllowedRef : int 
var jumpBuffOn : bool = false
var bufferedJump : bool = false
@export var coyoteJumpCooldown : float
var coyoteJumpCooldownRef : float
var coyoteJumpOn : bool = false

@export_group("Gravity variables")
@onready var jumpGravity : float = (-2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak)
@onready var fallGravity : float = (-2.0 * jumpHeight) / (jumpTimeToFall * jumpTimeToFall)

@export_group("Keybind variables")
@export var moveForwardAction : String = ""
@export var moveBackwardAction : String = ""
@export var moveLeftAction : String = ""
@export var moveRightAction : String = ""
@export var runAction : String = ""
@export var crouchAction : String = ""
@export var jumpAction : String = ""

@export_group("World Gen")
@export var worldGen : Node
@export var blockInteractDistance : float
@export var hotbar : Node

#references variables
@onready var camHolder : Node3D = $CameraHolder
@onready var model : MeshInstance3D = $Model
@onready var hitbox : CollisionShape3D = $Hitbox
@onready var stateMachine : Node = $StateMachine
@onready var hud : CanvasLayer = $HUD
@onready var ceilingCheck : RayCast3D = $Raycasts/CeilingCheck
@onready var floorCheck : RayCast3D = $Raycasts/FloorCheck

var hotbar_index : int = 0
var active_blocktype : Block.BlockType = 0

func hotbar_num_from_input() -> int:
	if Input.is_action_just_pressed("1"):
		return 1
	elif Input.is_action_just_pressed("2"):
		return 2
	elif Input.is_action_just_pressed("3"):
		return 3
	elif Input.is_action_just_pressed("4"):
		return 4
	elif Input.is_action_just_pressed("5"):
		return 5
	elif Input.is_action_just_pressed("6"):
		return 6
	elif Input.is_action_just_pressed("7"):
		return 7
	elif Input.is_action_just_pressed("8"):
		return 8
	elif Input.is_action_just_pressed("9"):
		return 9
	elif Input.is_action_just_pressed("0"):
		return 10
	return -1

func _ready():
	#set move variables, and value references
	moveSpeed = walkSpeed
	moveAccel = walkAccel
	moveDeccel = walkDeccel
	
	hitGroundCooldownRef = hitGroundCooldown
	jumpCooldownRef = jumpCooldown
	nbJumpsInAirAllowedRef = nbJumpsInAirAllowed
	coyoteJumpCooldownRef = coyoteJumpCooldown
	
func _process(_delta: float):
	if Input.is_action_just_pressed("leftClick") or Input.is_action_just_pressed("rightClick"):
		var from = $CameraHolder/Camera.global_transform.origin
		var direction = -$CameraHolder/Camera.global_transform.basis.z
		var result = worldGen.raycast_block(from, direction.normalized(), blockInteractDistance)

		if result.has("hit"):
			var blockPos: Vector3i = result["hit"]
			var prevPos: Vector3i = result["previous"]
			
			# Break
			if Input.is_action_just_pressed("leftClick"):
				worldGen.set_block(blockPos, null)
				worldGen.update_adjacent_chunks(blockPos)
				
			# Place	
			elif Input.is_action_just_pressed("rightClick"):
				# Place block on the air block before the hit
				if prevPos.x >= 0 and prevPos.x < worldGen.WORLD_WIDTH and \
				   prevPos.y >= 0 and prevPos.y < worldGen.WORLD_DEPTH and \
				   prevPos.z >= 0 and prevPos.z < worldGen.WORLD_WIDTH:
					if worldGen.is_air(prevPos):
						worldGen.set_block(prevPos, Block.new(active_blocktype))
						worldGen.update_adjacent_chunks(prevPos)
	
	var num_input : int = hotbar_num_from_input()
	var prev_hotbar_index : int = hotbar_index
	if num_input > 0 and num_input <= hotbar.HotbarNodes.size() and num_input != prev_hotbar_index:
		hotbar_index = num_input - 1
		hotbar.HotbarNodes[hotbar_index].selected = true
		hotbar.HotbarNodes[prev_hotbar_index].selected = false
		active_blocktype = hotbar_index
		
	
func _physics_process(_delta : float):
	modifyPhysicsProperties()
	move_and_slide()
		
func modifyPhysicsProperties():
	lastFramePosition = position #get play char position every frame
	lastFrameVelocity = velocity #get play char velocity every frame
	wasOnFloor = !is_on_floor() #check if play char was on floor every frame
	
func gravityApply(delta : float):
	#if play char goes up, apply jump gravity
	#otherwise, apply fall gravity
	if velocity.y >= 0.0: velocity.y += jumpGravity * delta
	elif velocity.y < 0.0: velocity.y += fallGravity * delta
