Import Mojo
Import Math
Import brl.json
Import user
Import user_interface

Const SCREEN_WIDTH:Int = 640
Const SCREEN_HEIGHT:Int = 480

Class Unit
	Field unit_id:Int
	Field player_id:String
	Field position:Vec2D
	Field velocity:Vec2D
	Field control:ControlPoint
	Field moveXPoints:FloatDeque
	Field moveYPoints:FloatDeque
	Field points:Deque<Vec2D>
	Field heading:Float
	Field friendly:Int
	Field currentEnergy:Float
	Field armor:Int
	Field unit_type:UnitType

	Method New(unit_id:Int, x:Float, y:Float, initial_heading:Float, unit_type:UnitType, player_id:String, isfriendly:Int)
		Self.unit_id = unit_id
		Self.player_id = player_id
		Self.unit_type = unit_type

		Self.position = New Vec2D(x, y)
		Self.control = New ControlPoint(x + Self.unit_type.maxVelocity, y, initial_heading, 10, 10)

		Self.heading = initial_heading
		Self.velocity = New Vec2D(Self.unit_type.maxVelocity * Cosr(heading * (PI/180)), Self.unit_type.maxVelocity * Sinr(heading * (PI/180)))
		Self.SetControl(velocity.x, velocity.y, SCREEN_WIDTH, SCREEN_HEIGHT)
		Self.friendly = isfriendly

		Self.currentEnergy = 0.0

		Self.armor = Self.unit_type.maxArmor
	End

	Method DrawStatic(game_player_id:String, game_state:String)
		If (Self.player_id = game_player_id)
			SetColor(128, 255, 128)
		Else
			SetColor(255, 128, 128)
		End
		
		DrawImage(Self.unit_type.image, Self.position.x, Self.position.y, -Self.heading, 1, 1)

		If (Self.player_id = game_player_id And (game_state = "multiplayer" Or game_state = "tutorial"))
			Self.control.Draw()

			For Local i:Int = 0 Until Self.points.Length - 1
				If ((Self.currentEnergy + i * Self.unit_type.chargeEnergy) Mod Self.unit_type.maxEnergy = 0)
					SetColor(100, 100, 255)
				Else
					SetColor(255, 255, 255)
				End
				Local this_point:Vec2D = Self.points.Get(i)
				DrawPoint(this_point.x, this_point.y)
			End
		End
	End
	
	Method Update()
		Local next_point:Vec2D = Self.points.PopFirst()

		Self.heading = ATan2((next_point.y - Self.position.y), (next_point.x - Self.position.x))
		Self.velocity.Set(Self.unit_type.maxVelocity * Cosr(heading * (PI/180)), Self.unit_type.maxVelocity * Sinr(Self.heading * (PI/180)))
		Self.position = next_point
		Self.currentEnergy = Min(Self.unit_type.maxEnergy, Self.currentEnergy + Self.unit_type.chargeEnergy)
	End


	Method ControlSelected(click_x:Float, click_y:Float)
		If (Self.control.selected)
			Return True
		Else If ((click_x >= Self.control.position.x - Self.control.width) And
			(click_x <= (Self.control.position.x + Self.control.width)) And
			(click_y >= Self.control.position.y - Self.control.width) And
			(click_y <= (Self.control.position.y + Self.control.height)))
			Self.control.selected = True
			Return True
		Else
			Return False
		End
	End
	
	Method ControlReleased()
		Self.control.selected = False
	End
	
	Method SetControl(click_x:Float, click_y:Float, map_width:Float, map_height:Float)
		Local goal_angle = ATan2((click_y - Self.position.y), (click_x - Self.position.x))
		Local start_angle = Self.heading
		Local control_pos:Vec2D = New Vec2D(Self.position.x, Self.position.y, Self.heading)
		Self.points = New Deque<Vec2D>
		
		For Local i:Int = 0 Until 30
			control_pos = NewPoint(control_pos, start_angle, goal_angle, Self.unit_type.maxRotation, Self.unit_type.maxVelocity/30.0)
			start_angle = control_pos.heading
			goal_angle = ATan2((click_y - control_pos.y), (click_x - control_pos.x))
			Self.points.PushLast(control_pos)
		End
		
		If (control_pos.x > map_width)
			control_pos.x = map_width - 10
			control_pos.heading = 180
		Else If (control_pos.x < 0)
			control_pos.x = 10
			control_pos.heading = 0
		End
		
		If (control_pos.y > map_height)
			control_pos.y = map_height - 10
			control_pos.heading = 270
		Else If (control_pos.y < 0)
			control_pos.y = 10
			control_pos.heading = 90
		End
		
		Self.control.position.Set(control_pos.x, control_pos.y, control_pos.heading)
	End
	
	Method SetServerControl(click_x:Float, click_y:Float, click_angle:Float, map_width:Float, map_height:Float)
		Local goal_angle:Float = click_angle
		Local start_angle:Float = Self.heading
		Local control_pos:Vec2D = New Vec2D(Self.position.x, Self.position.y, Self.heading)
		Self.points = New Deque<Vec2D>
		
		For Local i:Int = 0 Until 30
			control_pos = NewPoint(control_pos, start_angle, goal_angle, Self.unit_type.maxRotation, Self.unit_type.maxVelocity/30.0)
			start_angle = control_pos.heading
			goal_angle = ATan2((click_y - control_pos.y), (click_x - control_pos.x))
			Self.points.PushLast(control_pos)
		End
		
		'If (control_pos.x > map_width)
		'	control_pos.x = map_width - 10
		'	control_pos.heading = 180
		'Else If (control_pos.x < 0)
		'	control_pos.x = 10
		'	control_pos.heading = 0
		'End
		
		'If (control_pos.y > map_height)
		'	control_pos.y = map_height - 10
		'	control_pos.heading = 270
		'Else If (control_pos.y < 0)
		'	control_pos.y = 10
		'	control_pos.heading = 90
		'End
		
		'Self.control.position.Set(control_pos.x, control_pos.y, control_pos.heading)
		'Self.control.heading = control_pos.heading
	
	End
	
	Method FireWeapon()
		Self.currentEnergy = 0
	End
	
	Method TakeDamage()
		Self.armor = Self.armor - 1
	End
End

Class ControlPoint
	Field position:Vec2D
	Field width:Float
	Field height:Float
	Field selected:Bool
	Field heading:Float

	Method New(x:Float, y:Float, heading:Float, width:Float, height:Float)
		Self.position = New Vec2D(x, y)
		Self.width = width
		Self.height = height
		Self.selected = False
		Self.heading = heading
	End
	
	Method Draw()
		SetColor(255, 255, 128)
		DrawRect(Self.position.x, Self.position.y, Self.width, Self.height)
	End
	
End


Class Particle
	Field position:Vec2D
	Field past_position:Vec2D
	Field size:Float
	Field power:Float
	Field speed:Float
	Field angle:Float
	Field lifetime:Int
	Field friendly:Int
	
	Method New(pos:Vec2D, size:Float, power:Float, angle:Float, speed:Float, friendly:Int)
		Local newx = pos.x + 10 * Cosr(angle * (PI/180))
		Local newy = pos.y + 10 * Sinr(angle * (PI/180))
		Self.position = New Vec2D(pos.x, pos.y)
		Self.past_position = New Vec2D(pos.x, pos.y)
		Self.size = size
		Self.power = power
		Self.speed = speed
		Self.angle = angle
		Self.lifetime = 30
		Self.friendly = friendly
	End
	
	Method Draw()
		
		SetColor(255 * friendly, 0, 255)
		DrawCircle(position.x - size, position.y - size, size)
		DrawLine(past_position.x, past_position.y, position.x, position.y)
	End
	
	Method Update()
		Local posx:Float = position.x
		Local posy:Float = position.y
		past_position.Set(posx, posy)
		position.Set(position.x + speed * Cosr(angle * (PI/180)), position.y + speed * Sinr(angle * (PI/180)))
		lifetime = lifetime - 1
	End
	
End

Function NewPoint:Vec2D (start_point:Vec2D, start_angle:Float, goal_angle:Float, max_angle_change:Float, distance:Float)

	Local new_angle:Float
	If ((start_angle >= 0 And goal_angle >= 0) Or (start_angle < 0 And goal_angle < 0))
		If (start_angle > goal_angle)
			new_angle = start_angle - Min((start_angle - goal_angle), max_angle_change)
		Else If (start_angle < goal_angle)
			new_angle = start_angle + Min((goal_angle - start_angle), max_angle_change)
		Else
			new_angle = start_angle
		End
	Else If (start_angle >= 0 And goal_angle < 0)
		If (start_angle - goal_angle > 180)
			new_angle = start_angle + max_angle_change
		Else
			new_angle = start_angle - Min((start_angle - goal_angle), max_angle_change)
		End
	Else If (start_angle < 0 And goal_angle >= 0)
		If (goal_angle - start_angle > 180)
			new_angle = start_angle - max_angle_change
		Else
			new_angle = start_angle + Min((goal_angle - start_angle), max_angle_change)
		End	
	End

	Return New Vec2D(start_point.x + distance * Cosr(new_angle * (PI/180)), start_point.y + distance * Sinr(new_angle * (PI/180)), new_angle)

End

Class UnitType
	Field name:String
	Field maxVelocity:Float
	Field maxRotation:Float
	Field maxEnergy:Float
	Field chargeEnergy:Float
	Field maxArmor:Float
	Field image:Image
	
	Method New(type_json:JsonObject)
		Self.name = type_json.GetString("name")
		Self.maxVelocity = Float(type_json.GetString("speed"))
		Self.maxRotation = Float(type_json.GetString("turn"))
		Self.maxEnergy = Float(type_json.GetString("full_energy"))
		Self.chargeEnergy = Float(type_json.GetString("charge_energy"))
		Self.maxArmor = Float(type_json.GetString("armor"))
		
		Local image_name:String = type_json.GetString("image")
		Self.image = LoadImage("images/" + image_name, 1, Image.MidHandle)
	End
End

Class Game
	Field id:String
	Field units:StringMap<Unit>
	Field opponents:List<Unit>
	Field particles:List<Particle>
	Field types:StringMap<UnitType>
	Field player_state:String
	
	Method New()
		Self.units = New StringMap<Unit>()
		Self.opponents = New List<Unit>()
		Self.particles = New List<Particle>()
		Self.types = New StringMap<UnitType>()
	End
	
	Method LoadFromJson(game_json:JsonObject, player_id:String)
		Self.units.Clear()
		Self.opponents.Clear()
		Self.particles.Clear()
		Self.types.Clear()

		Self.id = game_json.GetString("id")
		Local unit_list:JsonArray = JsonArray(game_json.Get("units"))
		Local types_list:JsonArray = JsonArray(game_json.Get("types"))
		Local player_list:JsonArray = JsonArray(game_json.Get("players"))
		Local particle_list:JsonArray = JsonArray(game_json.Get("particles"))
		
		For Local i:Int = 0 Until types_list.Length
			Local type_json:JsonObject = JsonObject(types_list.Get(i))
			Local new_type:UnitType = New UnitType(type_json)
			Self.types.Add(new_type.name, new_type)
		End
		
		For Local i:Int = 0 Until unit_list.Length
			Local unit_json:JsonObject = JsonObject(unit_list.Get(i))
			Local type_name:String = unit_json.GetString("type")
			Local unit_type:UnitType = Self.types.Get(type_name)

			Local new_unit:Unit = New Unit(Int(unit_json.GetString("id")), 
											Float(unit_json.GetString("x")), 
											Float(unit_json.GetString("y")), 
											Float(unit_json.GetString("heading")), 
											unit_type, 
											Int(unit_json.GetString("player_id")), 
											Int(unit_json.GetString("player_id")))
			Self.units.Add(new_unit.unit_id, new_unit)
		End
		
		For Local i:Int = 0 Until player_list.Length
			Local player_json:JsonObject = JsonObject(player_list.Get(i))
			Local current_player_id:String = player_json.GetString("player_id")
			Local current_player_state:String = player_json.GetString("player_state")
			If (current_player_id = player_id)
				Self.player_state = current_player_state
				Print "setting game player state to " + current_player_state
				Exit
			End
		End
		
		For Local i:Int = 0 Until particle_list.Length
			Local particle_json:JsonObject = JsonObject(particle_list.Get(i))
			Local current_particle_id:String = particle_json.GetString("id")
			
			Local new_particle:Particle = New Particle(New Vec2D( Float(particle_json.GetString("x")), Float(particle_json.GetString("y")) ),
													    2.5,
													    Float(particle_json.GetString("power")),
													    Float(particle_json.GetString("heading")),
													    Float(particle_json.GetString("speed")),
													    Int(particle_json.GetString("team")) )
			Self.particles.AddLast(new_particle)
		End
		
	End
	
	Method LoadServerMoves(game_json:JsonObject)
		Local unit_list:JsonArray = JsonArray(game_json.Get("units"))
		For Local i:Int = 0 Until unit_list.Length
			Local unit_json:JsonObject = JsonObject(unit_list.Get(i))
			Local current_unit:Unit = Self.units.Get(unit_json.GetString("id"))
			current_unit.position.Set(Float(unit_json.GetString("x")), Float(unit_json.GetString("y")))
			current_unit.heading = Float(unit_json.GetString("heading"))
			current_unit.SetServerControl(Float(unit_json.GetString("control_x")), Float(unit_json.GetString("control_y")), Float(unit_json.GetString("control_heading")), SCREEN_WIDTH, SCREEN_HEIGHT)
			current_unit.armor = Int(unit_json.GetString("armor"))
		End
	End
	
	Method SetUnitPathsToServerSimulation(server_json:JsonObject, player_id:String)
		Local moves_json:JsonObject = JsonObject(server_json.Get("move_points"))
		For Local key:String = Eachin Self.units.Keys
			Local current_unit:Unit = Self.units.Get(key)
			If (current_unit.player_id = player_id)
				current_unit.points = New Deque<Vec2D>
				Local moves_array:JsonArray = JsonArray(moves_json.Get(key))
				For Local i:Int = 0 Until moves_array.Length
					Local move_json:JsonObject = JsonObject(moves_array.Get(i))
					Local move:Vec2D = New Vec2D(Float(move_json.GetFloat("x")), Float(move_json.GetFloat("y")), Float(move_json.GetFloat("heading")))
					
					current_unit.points.PushLast(move)
				End
				Local last_point:Vec2D = current_unit.points.Get(current_unit.points.Length - 1)
				current_unit.control.position.Set(last_point.x, last_point.y, last_point.heading)
			End
		End
	End
	
End
