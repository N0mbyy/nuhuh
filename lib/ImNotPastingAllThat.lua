require("NovaScript.NovaScript_natives")

local function pid_to_ped(pid)
    return GET_PLAYER_PED(pid)
end 

function CreateVehicle(Hash, Pos, Heading, Invincible)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_vehicle(Hash, Pos, Heading)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    if Invincible then
        ENTITY.SET_ENTITY_INVINCIBLE(SpawnedVehicle, true)
    end
    return SpawnedVehicle
end

function CreatePed(index, Hash, Pos, Heading)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_ped(index, Hash, Pos, Heading)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    return SpawnedVehicle
end

function CreateObject(Hash, Pos, static)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_object(Hash, Pos)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    if static then
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicle, true)
    end
    return SpawnedVehicle
end

local spawned_objects = {}
local function BitTest(bits, place)
    return (bits & (1 << place)) != 0
end

local function SetBit(addr: number, bit: number)
	memory.write_int(addr, memory.read_int(addr) | 1 << bit)
end

local function ClearBit(addr: number, bit: number)
	memory.write_int(addr, memory.read_int(addr) ~ 1 << bit)
end

local function IS_PLAYER_USING_ORBITAL_CANNON(pid)
    return BitTest(memory.read_int(memory.script_global((2657704 + (pid * 463 + 1) + 424))), 0) -- Global_2657704[PLAYER::PLAYER_ID() /*463*/].f_424
end

local function IS_PLAYER_FLYING_ANY_DRONE(pid)
   return BitTest(memory.read_int(memory.script_global(1853988 + (pid * 867 + 1) + 267 + 366)), 26) -- Global_1853988[PLAYER::PLAYER_ID() /*867*/].f_267.f_366, 26)
end

local function IS_PLAYER_USING_GUIDED_MISSILE(pid)
    return (memory.read_int(memory.script_global(2657704 + 1 + (pid * 463) + 321 + 10)) != -1 and IS_PLAYER_FLYING_ANY_DRONE(pid)) -- Global_2657704[PLAYER::PLAYER_ID() /*463*/].f_321.f_10
end

local function IS_PLAYER_USING_MISSILE_TURRET(pid)
    return BitTest(memory.read_int(memory.script_global(1853988 + 1 + (pid * 867) + 267 + 480)), 25) -- Global_1853988[PLAYER::PLAYER_ID() /*867*/].f_267.f_480), 25)
end

local function IS_PLAYER_IN_RC_BANDITO(pid)
    return BitTest(memory.read_int(memory.script_global(1853988 + (pid * 867 + 1) + 267 + 366)), 29)  -- Global_1853988[PLAYER::PLAYER_ID() /*867*/].f_267.f_366, 29)
end

local function IS_PLAYER_IN_RC_TANK(pid)
    return BitTest(memory.read_int(memory.script_global(1853988 + (pid * 867 + 1) + 267 + 429 + 2)), 16) -- Global_1853988[bParam0 /*867*/].f_267.f_429.f_2
end

local function IS_PLAYER_IN_REMOTE_VEHICLE(pid)
    return IS_PLAYER_FLYING_ANY_DRONE(pid) or IS_PLAYER_USING_GUIDED_MISSILE(pid) or IS_PLAYER_IN_RC_BANDITO(pid) or IS_PLAYER_IN_RC_TANK(pid)
end

local function IS_PLAYER_RIDING_ROLLER_COASTER(pid)
    return BitTest(memory.read_int(memory.script_global(1853988 + 1 + (pid * 867) + 863)), 15) -- Global_1853988[PLAYER::PLAYER_ID() /*867*/].f_863), 15)
end

local function GET_SPAWN_STATE(pid)
    return memory.read_int(memory.script_global(((2657704 + 1) + (pid * 463)) + 232)) -- Global_2657704[PLAYER::PLAYER_ID() /*463*/].f_232
end

local function GET_INTERIOR_FROM_PLAYER(pid)
    return memory.read_int(memory.script_global(((2657704 + 1) + (pid * 463)) + 245)) -- Global_2657704[bVar0 /*463*/].f_245
end

local function IS_PLAYER_IN_INTERIOR(pid)
    local id = {0, 233985, 169473, 169729, 169985, 170241, 177665, 177409, 185089, 184833, 184577, 163585, 167425, 167169, 138241}
    for id as interior do
        if GET_INTERIOR_FROM_PLAYER(pid) != interior then
            return false
        end
    end
    return true
end


local function DoesPlayerExist(pid)
    if NETWORK_PLAYER_GET_NAME(pid) == "**Invalid**" then
        return false
    end
    return true
end


function GetPlayers()
    local pids = {}
    for pid = 0, 32 do
        local playerName = NETWORK_PLAYER_GET_NAME(pid)
        if playerName ~= "**Invalid**" then
            table.insert(pids, pid)
        end
    end
    return pids
end

local function GetOffsetFromPlayerCamera(player, distance)
    local pos = players.get_cam_pos(player)
    local direction = players.get_cam_rot(player):toDir()
    direction:mul(distance)
    pos:add(direction)
    return pos
end

local function GET_SEAT_PED_IS_IN(ped) -- thanks rockstar for making me do this cus you guys are too lazy to have a native for it :D
    local vehicle = GET_VEHICLE_PED_IS_USING(ped)
    if vehicle == 0 then
        return nil
    end
    local num_of_seats = GET_VEHICLE_MODEL_NUMBER_OF_SEATS(GET_ENTITY_MODEL(vehicle))
    for i = -1, num_of_seats - 1 do
        local ped_in_seat = GET_PED_IN_VEHICLE_SEAT(vehicle, i)
        if ped_in_seat == ped then
            return i
        end
    end
end

local function IS_PLAYER_MOVING(pid)
    local oldpos = players.get_position(pid)
    yield(100)
    local currentpos = players.get_position(pid)
    if v3.distance(oldpos, currentpos) > 0.1 then
        return true
    end
    return false
end

local function StandUser(pid) -- credit to sapphire for this
    if players.exists(pid) and pid != players.user() then
        for menu.player_root(pid):getChildren() as cmd do
            if cmd:getType() == COMMAND_LIST_CUSTOM_SPECIAL_MEANING and cmd:refByRelPath("Stand User"):isValid() then
                return true
            end
        end
    end
    return false
end

local function IsDetectionPresent(pid, detection)
    if players.exists(pid) and menu.player_root(pid):isValid() then
        for menu.player_root(pid):getChildren() as cmd do
            if cmd:getType() == COMMAND_LIST_CUSTOM_SPECIAL_MEANING and cmd:refByRelPath(detection):isValid() and players.exists(pid) then
                return true
            end
        end
    end
    return false
end
 
local function LegitPlatePattern(plate)
    if string.match(plate, "%d%d%a%a%a%d%d%d") then
      return true
    else
      return false
    end
end

local function LoadWeaponAsset(weapon_name)
    local projectile = joaat(weapon_name)
    while not HAS_WEAPON_ASSET_LOADED(projectile) do
        REQUEST_WEAPON_ASSET(projectile, 31, false)
        yield()
    end
    return projectile
end

local function RequestAnimation(hash)
    REQUEST_ANIM_DICT(hash)
    while not HAS_ANIM_DICT_LOADED(hash) do
        yield()
    end
end

function GetControlOfEntity(entity)
    local ctr = 0
    while not NETWORK_HAS_CONTROL_OF_ENTITY(entity) do
        if ctr >= 250 then
            ctr = 0
            return
        end
        NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        yield()
        ctr += 1
    end
end

local function DeletePed(ped)
    local ctrl_ctr = 0
    local del_ctr = 0
    repeat
        if del_ctr > 250 then
            del_ctr = 0
            return
        end
        GetControlOfEntity(ped)
        entities.delete(ped)
        del_ctr += 1
        yield()
    until ped == nil or not DOES_ENTITY_EXIST(ped)
end

local function DOES_VEHICLE_HAVE_IMANI_TECH(vehicle_model)
    switch vehicle_model do
        case joaat("deity"):
        case joaat("granger2"):
        case joaat("buffalo4"):
        case joaat("jubilee"):
        case joaat("patriot3"):
        case joaat("champion"):
        case joaat("greenwood"):
        case joaat("omnisegt"):
        case joaat("virtue"):
        case joaat("r300"):
        case joaat("stingertt"):
        case joaat("buffalo5"):
        case joaat("coureur"):
        case joaat("monstrociti"):
        return true
    end
    return false
end

local function RELEASE_VEH_HANDLE(vehicle)
    if vehicle ~= entities.get_user_vehicle_as_handle() then
        RELEASE_SCRIPT_GUID_FROM_ENTITY(vehicle)
    end
end

local function NullCheck(string)
    if string == "NULL" or string == nil then
        return ""
    else
        return string
    end
end

local cooldown_time = 0
local function cooldown(time)
    cooldown_time += 1
    yield(time)
    cooldown_time = 0
end
local attack_weapons = {
    584646201,
    961495388,
    317205821,
    324215364,
    911657153,
    1119849093,
    1834241177,
    2138347493,
    1672152130,
    -608341376,
    -86904375,
    -1075685676,
    -1466123874,
    -1355376991,
    -1312131151,
    -581044007,
    -538741184,
    -102973651,
}

local weapon_stuff = {
    {"Firework", "weapon_firework"}, 
    {"Up N Atomizer", "weapon_raypistol"},
    {"Unholy Hellbringer", "weapon_raycarbine"},
    {"Rail Gun", "weapon_railgun"},
    {"Red Laser", "vehicle_weapon_enemy_laser"},
    {"Green Laser", "vehicle_weapon_player_laser"},
    {"P-996 Lazer", "vehicle_weapon_player_lazer"},
    {"RPG", "weapon_rpg"},
    {"Homing Launcher", "weapon_hominglauncher"},
    {"EMP Launcher", "weapon_emplauncher"},
    {"Flare Gun", "weapon_flaregun"},
    {"Shotgun", "weapon_bullpupshotgun"},
    {"Stungun", "weapon_stungun"},
    {"Smoke Gun", "weapon_smokegrenade"},
}

local proofs = {
    bullet = {name="Bullets",on=false},
    fire = {name="Fire",on=false},
    explosion = {name="Explosions",on=false},
    collision = {name="Collision",on=false},
    melee = {name="Melee",on=false},
    steam = {name="Steam",on=false},
    drown = {name="Drowning",on=false},
}

local modded_weapons = {
    "weapon_railgun",
    "weapon_stungun",
    "weapon_digiscanner",
}

local veh_things = {
    "brickade2",
    "hauler",
    "hauler2",
    "manchez3",
    "terbyte",
    "minitank",
    "rcbandito",
    "phantom3"
}

local doors = {
    "v_ilev_ml_door1",
    "v_ilev_ta_door",
    "v_ilev_247door",
    "v_ilev_247door_r",
    "v_ilev_lostdoor",
    "v_ilev_bs_door",
    "v_ilev_cs_door01",
    "v_ilev_cs_door01_r",
    "v_ilev_gc_door03",
    "v_ilev_gc_door04",
    "v_ilev_clothmiddoor",
    "v_ilev_clothmiddoor",
    "prop_shop_front_door_l",
    "prop_shop_front_door_r",
    "prop_com_ls_door_01",
    "v_ilev_carmod3door",
}

local object_stuff = {
    names = {
        "Ferris Wheel",
        "UFO",
        "Windmill",
        "Cement Mixer",
        "Scaffolding",
        "Big Bowling Ball",
        "Big Soccer Ball",
        "Big Orange Ball",
        "Stunt Ramp",

    },
    objects = {
        "prop_ld_ferris_wheel",
        "p_spinning_anus_s",
        "prop_windmill_01",
        "prop_staticmixer_01",
        "prop_towercrane_02a",
        "des_scaffolding_root",
        "stt_prop_stunt_bowling_ball",
        "stt_prop_stunt_soccer_ball",
        "prop_juicestand",
        "stt_prop_stunt_jump_l",
    }
}

local attackers = {
    names = {
        "Clown",
        "Mexican",
        "Zombie",
        "Swat Officer",
        "Juggernaut",
        "Astronaut",
        "Bigfoot",
        "Alien",
        "Space Monkey",
        "Impotent Rage",
        "Lester",
    },
    mdl = {
        "s_m_y_clown_01",
        "u_m_y_mani",
        "u_m_y_zombie_01",
        "s_m_y_swat_01",
        "u_m_y_juggernaut_01",
        "s_m_m_movspace_01",
        "ig_orleans",
        "s_m_m_movalien_01",
        "u_m_y_pogo_01",
        "u_m_y_imporage",
        "ig_lestercrest"
    }
}

local vehicle_classes = {
    "Compacts",
    "Sedans",
    "SUVs",
    "Coupes",
    "Muscle",
    "Sports Classics",
    "Sports",
    "Super",
    "Motorcycles",
    "Off-road",
    "Industrial",
    "Utility",
    "Vans",
    "Cycles",
    "Boats",
    "Helicopters",
    "Planes",
    "Service",
    "Emergency",
    "Military",
    "Commercial",
    "Trains",
    "Openwheel"
}

local interiors = {
    {"Safe Space [AFK Room]", {x=-158.71494, y=-982.75885, z=149.13135}},
    {"Torture Room", {x=147.170, y=-2201.804, z=4.688}},
    {"Mining Tunnels", {x=-595.48505, y=2086.4502, z=131.38136}},
    {"Omegas Garage", {x=2330.2573, y=2572.3005, z=46.679367}},
    {"50 Car Garage", {x=520.0, y=-2625.0, z=-50.0}},
    {"Server Farm", {x=2474.0847, y=-332.58887, z=92.9927}},
    {"Character Creation", {x=402.91586, y=-998.5701, z=-99.004074}},
    {"Life Invader Building", {x=-1082.8595, y=-254.774, z=37.763317}},
    {"Mission End Garage", {x=405.9228, y=-954.1149, z=-99.6627}},
    {"Destroyed Hospital", {x=304.03894, y=-590.3037, z=43.291893}},
    {"Stadium", {x=-256.92334, y=-2024.9717, z=30.145584}},
    {"Comedy Club", {x=-430.00974, y=261.3437, z=83.00648}},
    {"Record A Studios", {x=-1010.6883, y=-49.127754, z=-99.40313}},
    {"Bahama Mamas Nightclub", {x=-1394.8816, y=-599.7526, z=30.319544}},
    {"Janitors House", {x=-110.20285, y=-8.6156025, z=70.51957}},
    {"Therapists House", {x=-1913.8342, y=-574.5799, z=11.435149}},
    {"Martin Madrazos House", {x=1395.2512, y=1141.6833, z=114.63437}},
    {"Floyds Apartment", {x=-1156.5099, y=-1519.0894, z=10.632717}},
    {"Michaels House", {x=-813.8814, y=179.07889, z=72.15914}},
    {"Franklins House (Strawberry)", {x=-14.239959, y=-1439.6913, z=31.101551}},
    {"Franklins House (Vinewood Hills)", {x=7.3125067, y=537.3615, z=176.02803}},
    {"Trevors House", {x=1974.1617, y=3819.032, z=33.436287}},
    {"Lesters House", {x=1273.898, y=-1719.304, z=54.771}},
    {"Lesters Warehouse", {x=713.5684, y=-963.64795, z=30.39534}},
    {"Lesters Office", {x=707.2138, y=-965.5549, z=30.412853}},
    {"Meth Lab", {x=1391.773, y=3608.716, z=38.942}},
    {"Acid Lab", {x=484.69, y=-2625.36, z=-49.0}},
    {"Morgue Lab", {x=495.0, y=-2560.0, z=-50.0}},
    {"Humane Labs", {x=3625.743, y=3743.653, z=28.69009}},
    {"Motel Room", {x=152.2605, y=-1004.471, z=-99.024}},
    {"Police Station", {x=443.4068, y=-983.256, z=30.689589}},
    {"Bank Vault", {x=263.39627, y=214.39891, z=101.68336}},
    {"Blaine County Bank", {x=-109.77874, y=6464.8945, z=31.626724}}, -- credit to fluidware for telling me about this one
    {"Tequi-La-La Bar", {x=-564.4645, y=275.5777, z=83.074585}},
    {"Scrapyard Body Shop", {x=485.46396, y=-1315.0614, z=29.2141}},
    {"The Lost MC Clubhouse", {x=980.8098, y=-101.96038, z=74.84504}},
    {"Vangelico Jewlery Store", {x=-629.9367, y=-236.41296, z=38.057056}},
    {"Airport Lounge", {x=-913.8656, y=-2527.106, z=36.331566}},
    {"Morgue", {x=240.94368, y=-1379.0645, z=33.74177}},
    {"Union Depository", {x=1.298771, y=-700.96967, z=16.131021}},
    {"Fort Zancudo Tower", {x=-2357.9187, y=3249.689, z=101.45073}},
    {"Agency Interior", {x=-1118.0181, y=-77.93254, z=-98.99977}},
    {"Agency Garage", {x=-1071.0494, y=-71.898506, z=-94.59982}},
    {"Terrobyte Interior", {x=-1421.015, y=-3012.587, z=-80.000}},
    {"Bunker Interior", {x=899.5518,y=-3246.038, z=-98.04907}},
    {"IAA Office", {x=128.20, y=-617.39, z=206.04}},
    {"FIB Top Floor", {x=135.94359, y=-749.4102, z=258.152}},
    {"FIB Floor 47", {x=134.5835, y=-766.486, z=234.152}},
    {"FIB Floor 49", {x=134.635, y=-765.831, z=242.152}},
    {"Big Fat White Cock", {x=-31.007448, y=6317.047, z=40.04039}},
    {"Strip Club DJ Booth", {x=121.398254, y=-1281.0024, z=29.480522}},
}
local tp_locations = {
    [4] = "Sandy Shores",
    [7] = "Tequi-La-La",
    [8] = "LSIA (Bottom Level)",
    [9] = "Yellow Jack Bar",
    [10] = "Spitroasters Meat House",
    [11] = "Up-n-Atom Burger",
    [13] = "Alamo Fruit Market",
    [25] = "Lesters Warehouse",
    [28] = "Bennys Shop",
    [31] = "Sandy Shores Boat House",
    [42] = "Hookies Food Diner",
    [56] = "Paleto Bay",
    [58] = "Grapeseed Airfield",
    [59] = "Paleto Bay Ammunation",
    [60] = "LSIA (Top Level)",
    [66] = "Observatory",
    [68] = "Casino",
    [72] = "Casino Roof",
    [87] = "Martin Madrazos House",
    [90] = "LS Docks",
    [91] = "Del Perro Pier",
    [97] = "Country Club",
    [114] = "Mount Chiliad"
}

--[[local station_name = {
    ["Blaine County Radio"] = "RADIO_11_TALK_02", 
    ["The Blue Ark"] = "RADIO_12_REGGAE",
    ["Worldwide FM"] = "RADIO_13_JAZZ",
    ["FlyLo FM"] = "RADIO_14_DANCE_02",
    ["The Lowdown 9.11"] = "RADIO_15_MOTOWN",
    ["The Lab"] = "RADIO_20_THELAB",
    ["Radio Mirror Park"] = "RADIO_16_SILVERLAKE",
    ["Space 103.2"] = "RADIO_17_FUNK",
    ["Vinewood Boulevard Radio"] = "RADIO_18_90S_ROCK",
    ["Blonded Los Santos 97.8 FM"] = "RADIO_21_DLC_XM17",
    ["Los Santos Underground Radio"] = "RADIO_22_DLC_BATTLE_MIX1_RADIO",
    ["iFruit Radio"] = "RADIO_23_DLC_XM19_RADIO",
    ["Motomami Lost Santos"] = "RADIO_19_USER",
    ["Los Santos Rock Radio"] = "RADIO_01_CLASS_ROCK",
    ["Non-Stop-Pop FM"] = "RADIO_02_POP",
    ["Radio Los Santos"] = "RADIO_03_HIPHOP_NEW",
    ["Channel X"] = "RADIO_04_PUNK",
    ["West Coast Talk Radio"] = "RADIO_05_TALK_01",
    ["Rebel Radio"] = "RADIO_06_COUNTRY", 
    ["Soulwax FM"] = "RADIO_07_DANCE_01",
    ["East Los FM"] = "RADIO_08_MEXICAN",
    ["West Coast Classics"] = "RADIO_09_HIPHOP_OLD",
    ["Media Player"] = "RADIO_36_AUDIOPLAYER",
    ["The Music Locker"] = "RADIO_35_DLC_HEI4_MLR",
    ["Kult FM"] = "RADIO_34_DLC_HEI4_KULT",
    ["Still Slipping Los Santos"] = "RADIO_27_DLC_PRHEI4",
}

    
local station_name = {
    [0] = "Los Santos Rock Radio",
    [1] = "Non-Stop-Pop FM",
    [2] = "Radio Los Santos",
    [3] = "Channel X",
    [4] = "West Coast Talk Radio",
    [5] = "Rebel Radio",
    [6] = "Soulwax FM",
    [7] = "East Los FM",
    [8] = "West Coast Classics",
    [9] = "Media Player", 
    [10] = "The Blue Ark",
    [11] = "Worldwide FM",   
    [12] = "FlyLo FM", 
    [13] = "The Lowdown 9.11",   
    [14] = "Radio Mirror Park",  
    [15] = "Space 103.2",  
    [16] = "Vinewood Boulevard Radio", 
    [17] = "Motomami Lost Santos", 
    [18] = "The Lab",    
    [19] = "Blonded Los Santos 97.8 FM",   
    [23] = "iFruit Radio",
    [27] = "Still Slipping Los Santos",
    [31] = "The Music Locker",
}]]


local warnings = {
    "NT_INV",
    "NT_INV_FREE",
    "NT_INV_PARTY_INVITE",
    "NT_INV_PARTY_INVITE_MP",
    "NT_INV_PARTY_INVITE_MP_SAVE",
    "NT_INV_PARTY_INVITE_SAVE",
    "NT_INV_MP_SAVE",
    "NT_INV_SP_SAVE",
}

local transaction_errors = {
    "CTALERT_F_4"
}

local scripts = {
    "valentineRpReward2",
    "main_persistent",
    "cellphone_controller",
    "shop_controller",
    "stats_controller",
    "timershud",
    "am_npc_invites",
    "fm_maintain_cloud_header_data"
}

local values = {
    [1] = 50,
    [2] = 88,
    [3] = 160,
    [4] = 208,
}

local launch_vehicle = {"Launch Up", "Launch Forward", "Launch Backwards", "Launch Down", "Slingshot"}
local invites = {"Yacht", "Office", "Clubhouse", "Office Garage", "Custom Auto Shop", "Apartment"}
local style_names = {"Normal", "Semi-Rushed", "Reverse", "Ignore Lights", "Avoid Traffic", "Avoid Traffic Extremely", "Take Shortest Path", "Sometimes Overtake Traffic"}
local stand_notif = "My brother in christ, what are you doing?! This will not work on a fellow stand user."
local drivingStyles = {786603, 1074528293, 1076, 2883621, 786468, 6, 262144, 5}
local bones = {12844, 24816, 24817, 24818, 35731, 31086}
local interior_stuff = {0, 233985, 169473, 169729, 169985, 170241, 177665, 177409, 185089, 184833, 184577, 163585, 167425, 167169, 138241}


local OFNKkdmf = 5
ryze = {
    int = function(global, value)
        local radress = memory.script_global(global)
        memory.write_int(radress, value)
    end,

    request_model_load = function(hash)
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
    end,

    cwash_in_progwess = function()
        kitty_alpha = 0
        kitty_alpha_incr = 0.01
        kitty_alpha_thread = util.create_thread(function (thr)
            while true do
                kitty_alpha = kitty_alpha + kitty_alpha_incr
                if kitty_alpha > 1 then
                    kitty_alpha = 1
                elseif kitty_alpha < 0 then 
                    kitty_alpha = 0
                    util.stop_thread()
                end
                util.yield(5)
            end
        end)

        kitty_thread = util.create_thread(function (thr)
            starttime = os.clock()
            local alpha = 0
            while true do
                timepassed = os.clock() - starttime
                if timepassed > 3 then
                    kitty_alpha_incr = -0.01
                end
                if kitty_alpha == 0 then
                    util.stop_thread()
                end
                util.yield(5)
            end
        end)
    end,

    modded_vehicles = {
        "conada2",
        "inductor",
        "inductor2",
        "buffalo5",
        "brigham",
        "gauntlet6",
        "squaddie",
        "coureur"
    },

    pets = {
        "a_c_cat_01",
        "a_c_shepherd",  
        "a_c_husky",
    },

    modded_weapons = {
        "weapon_railgun",
        "weapon_stungun",
        "weapon_digiscanner",
    },

    get_spawn_state = function(player_id)
        return memory.read_int(memory.script_global(((2657704 + 1) + (player_id * 463)) + 232)) -- Global_2657589[PLAYER::PLAYER_ID() /*466*/].f_232
    end,

    get_interior_player_is_in = function(player_id)
        return memory.read_int(memory.script_global(((2657704 + 1) + (player_id * 463)) + 245))
    end,

    is_player_in_interior = function(player_id)
        return (memory.read_int(memory.script_global(2657589 + 1 + (player_id * 466) + 245)) ~= 0)
    end,

    get_random_pos_on_radius = function()
        local angle = random_float(0, 2 * math.pi)
        pos = v3.new(pos.x + math.cos(angle) * radius, pos.y + math.sin(angle) * radius, pos.z)
        return pos
    end,

    get_transition_state = function(player_id)
        return memory.read_int(memory.script_global(((0x2908D3 + 1) + (player_id * 0x1C5)) + 230))
    end,

    ChangeNetObjOwner = function(object, player)
        if NETWORK.NETWORK_IS_IN_SESSION() then
            local net_object_mgr = memory.read_long(CNetworkObjectMgr)
            if net_object_mgr == NULL then
                return false
            end
            if not ENTITY.DOES_ENTITY_EXIST(object) then
                return false
            end
            local netObj = get_net_obj(object)
            if netObj == NULL then
                return false
            end
            local net_game_player = GetNetGamePlayer(player)
            if net_game_player == NULL then
                return false
            end
            util.call_foreign_function(ChangeNetObjOwner_addr, net_object_mgr, netObj, net_game_player, 0)
            return true
        else
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            return true
        end
    end,

    anim_request = function(hash)
        STREAMING.REQUEST_ANIM_DICT(hash)
        while not STREAMING.HAS_ANIM_DICT_LOADED(hash) do
            util.yield()
        end
    end,

    disableProjectileLoop = function(projectile)
        util.create_thread(function()
            util.create_tick_handler(function()
                WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(projectile, false)
                return remove_projectiles
            end)
        end)
    end,

    yieldModelLoad = function(hash)
        while not STREAMING.HAS_MODEL_LOADED(hash) do util.yield() end
    end,

    get_control_request = function(ent)
        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
            local tick = 0
            while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) and tick <= 100 do
                tick = tick + 1
                util.yield()
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
            end
        end
        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then
            util.toast("Does not have control of "..ent)
        end
        return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent)
    end,

    rotation_to_direction = function(rotation)
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
    end,

    request_model = function(hash, timeout)
        timeout = timeout or 3
        STREAMING.REQUEST_MODEL(hash)
        local end_time = os.time() + timeout
        repeat
            util.yield()
        until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
        return STREAMING.HAS_MODEL_LOADED(hash)
    end,

    BlockSyncs = function(player_id, callback)
        for _, i in ipairs(players.list(false, true, true)) do
            if i ~= player_id then
                local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
                menu.trigger_command(outSync, "on")
            end
        end
        util.yield(10)
        callback()
        for _, i in ipairs(players.list(false, true, true)) do
            if i ~= player_id then
                local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
                menu.trigger_command(outSync, "off")
            end
        end
    end,

    disable_traffic = true,
    disable_peds = true,
    pwayerp = players.user_ped(),
    pwayer = players.user(),
    thermal_command = menu.ref_by_path("Game>Rendering>Thermal Vision"),

    maxTimeBetweenPress = 300,
    pressedT = util.current_time_millis(),
    Int_PTR = memory.alloc_int(),
    mpChar = util.joaat("mpply_last_mp_char"),

    getMPX = function()
        STATS.STAT_GET_INT(ryze.mpChar, ryze.Int_PTR, -1)
        return memory.read_int(ryze.Int_PTR) == 0 and "MP0_" or "MP1_"
    end,

    STAT_GET_INT = function(Stat)
        STATS.STAT_GET_INT(util.joaat(ryze.getMPX() .. Stat), ryze.Int_PTR, -1)
        return memory.read_int(ryze.Int_PTR)
    end,
    

    getNightclubDailyEarnings = function()
        local popularity = math.floor(STAT_GET_INT("CLUB_POPULARITY") / 10)
        if popularity > 90 then return 10000
        elseif popularity > 85 then return 9000
        elseif popularity > 80 then return 8000
        elseif popularity > 75 then return 7000
        elseif popularity > 70 then return 6000
        elseif popularity > 65 then return 5500
        elseif popularity > 60 then return 5000
        elseif popularity > 55 then return 4500
        elseif popularity > 50 then return 4000
        elseif popularity > 45 then return 3500
        elseif popularity > 40 then return 3000
        elseif popularity > 35 then return 2500
        elseif popularity > 30 then return 2000
        elseif popularity > 25 then return 1500
        elseif popularity > 20 then return 1000
        elseif popularity > 15 then return 750
        elseif popularity > 10 then return 500
        elseif popularity > 5 then return 250
        else return 100
        end
    end,

    isWhitelisted = function(playerPid)
        if whitelistedPlayerName then
            if players.get_name(playerPid) == whitelistedPlayerName then return true end
        end
        local whitelist = players.list(not whitelistSelf, not whitelistFriends, not whitelistStrangers)
        for i = 1, #whitelist do
            if playerPid == whitelist[i] then return true end
        end
        for k, v in pairs(whitelistListTable) do 
            if playerPid == v then return true end
        end
        return false
    end,

    playerIsTargetingEntity = function(playerPed)
        local playerList = players.list(true, true, true)
        for k, playerPid in pairs(playerList) do
            if PLAYER.IS_PLAYER_TARGETTING_ENTITY(playerPid, playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY  (playerPid, playerPed) then 
                if not isWhitelisted(playerPid) then
                    karma[playerPed] = {
                        pid = playerPid, 
                        ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
                    }
                    return true 
                end
            end
        end
        karma[playerPed] = nil
        return false 
    end,

    explodePlayer = function(ped, loop)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        local blamedPlayer = PLAYER.PLAYER_PED_ID() 
        if blameExpPlayer and blameExp then 
            blamedPlayer = PLAYER.GET_PLAYER_PED(blameExpPlayer)
        elseif blameExp then
            local playerList = players.list(true, true, true)
            blamedPlayer = PLAYER.GET_PLAYER_PED(math.random(0, #playerList))
        end
        if not loop and PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
            for i = 0, 50, 1 do --50 explosions to account for armored vehicles
                if ownExp or blameExp then 
                    owned_explosion(blamedPlayer, pos)
                else
                    explosion(pos)
                end
                util.yield(10)
            end
        elseif ownExp or blameExp then
            owned_explosion(blamedPlayer, pos)
        else
            explosion(pos)
        end
        util.yield(10)
    end,

    get_coords = function(entity)
        entity = entity or PLAYER.PLAYER_PED_ID()
        return ENTITY.GET_ENTITY_COORDS(entity, true)
    end,

    play_all = function(sound, sound_group, wait_for)
        for i=0, 31, 1 do
            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, sound, PLAYER.GET_PLAYER_PED(i), sound_group, true, 20)
        end
        util.yield(wait_for)
    end,

    explode_all = function(earrape_type, wait_for)
        for i=0, 31, 1 do
            coords = ryze.get_coords(PLAYER.GET_PLAYER_PED(i))
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 100, true, false, 150, false)
            if earrape_type == EARRAPE_BED then
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "Bed", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
            end
            if earrape_type == EARRAPE_FLASH then
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "MP_Flash", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "MP_Flash", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "MP_Flash", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
            end
        end
        util.yield(wait_for)
    end,

    kicks = {
        1104117595,
        697566862,
        1268038438,
        915462795,
        697566862,
        1268038438,
        915462795
    },

    --power_kick = function(player_id)
    --    for i, v in pairs(ryze.kicks) do
    --        arg1 = math.random(-2147483647, 2147483647)
    --        arg2 = math.random(-1987543, 1987543)
    --        arg3 = math.random(-19, 19)
    --        util.trigger_script_event(1 << player_id, {v, pid, arg1, arg3, arg2, arg2, arg1, arg1, arg3, arg3, arg1, arg3, arg2, arg3, arg1, arg1, arg2, arg3, arg1, arg2, arg2, arg3, arg3})
    --        util.yield()
    --    end
    --    util.toast("You have kicked " .. PLAYER.GET_PLAYER_NAME(player_id))
    --end,

    power_crash = function(player_id)
        for i, v in pairs(ryze.kicks) do
            arg1 = math.random(-2147483647, 2147483647)
            arg2 = math.random(-1987543, 1987543)
            arg3 = math.random(-19, 19)
            util.trigger_script_event(1 << player_id, {v, player_id, arg1, arg3, arg2, arg2, arg1, arg1, arg3, arg3, arg1, arg3, arg2, arg3, arg1, arg1, arg2, arg3, arg1, arg2, arg2, arg3, arg3})
            util.yield()
        end
        util.toast("You have crashed " .. PLAYER.GET_PLAYER_NAME(player_id))
    end,

    clear_all_area = function()
        for k, v in entities.get_all_peds_as_handles() do
            if v ~= players.user_ped() and not PED.IS_PED_A_PLAYER(ped) then
                entities.delete_by_handle(v)
                util.yield(5)
            end
        end
        for k, b in entities.get_all_vehicles_as_handles() do
            if b ~= PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false) and DECORATOR.DECOR_GET_INT(vehicle, "Player_Vehicle") == 0 and NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                entities.delete_by_handle(b)
                util.yield(5)
            end
        end
        for k, y in entities.get_all_objects_as_handles() do
            entities.delete_by_handle(y)
            util.yield(5)
        end
        for k, n in entities.get_all_pickups_as_handles() do
            entities.delete_by_handle(n)
            util.yield(5)
        end
    end
}

-----------

UI2 = {}

local container = {
    new = function ()
        return {    
        type = 'C',
        elements = {},
        width = 0,
        height = 0,
        func = function ()
            error("func not implemented", 2)
        end}
    end

}

UI2.new = function()
    -- PRIVATE VARIABLES
    local self = {}

    local background_colour = {
        ['r'] = 0.000,
        ['g'] = 0.000,
        ['b'] = 0.00,
        ['a'] = 0.000
    }

    --gray colour for the header
    local gray_colour = {
        ['r'] = 0.0,
        ['g'] = 0.0,
        ['b'] = 0.0,
        ['a'] = 0
    }

    -- text colour
    local primary_text_colour = {
        ['r'] = 1.0,
        ['g'] = 1.0,
        ['b'] = 1.0,
        ['a'] = 1.0
    }

    local secondary_text_colour = {
        ['r'] = 0.094,
        ['g'] = 1.098,
        ['b'] = 1.101,
        ['a'] = 1
    }

    local highlight_colour = {
        ['r'] = 0.0,
        ['g'] = 0.0,
        ['b'] = 0.0,
        ['a'] = 0.0
    }

    local plain_text_size = 0.5
    local subhead_text_size = 0.6

    local horizontal_temp_width = 0
    local horizontal_temp_height = 0

    local cursor_mode = false

    local temp_container = {}

    local temp_x, temp_y = 0,0

    local current_window = {}

    local windows = {}

    local tab_containers = {}

    local function get_aspect_ratio()
        local screen_x, screen_y = directx.get_client_size()

        return screen_x / screen_y
    end

    local function UI_update()
        cursor_pos = {x = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)}
        directx.draw_texture(cursor_texture, 0.004, 0.004, 0.5, 0, cursor_pos.x, cursor_pos.y, 0, primary_text_colour)
        return cursor_mode
    end

    -- get an if an area is overlapping with the center of the screen
    local function get_overlap_with_rect(width, height, rect_x, rect_y, cursor_pos)
        if rect_x <= cursor_pos.x and rect_x + width >= cursor_pos.x then
            if rect_y <= cursor_pos.y and rect_y + height >= cursor_pos.y then
                return true
            end
        else
            return false
        end
    end

    local function draw_collapse_button(x_pos, y_pos, size, dir)
        size = size or 1
        local button_size = {x = 0.005 * dir, y = 0.005}
        local aspect_ratio = get_aspect_ratio()
        if aspect_ratio >= 1 then
            button_size.y = button_size.y * aspect_ratio
        else
            button_size.x = button_size.x * aspect_ratio
        end
        local half_size = {x = button_size.x * 0.5, y = button_size.y * 0.5}
        if cursor_mode then
            if get_overlap_with_rect(button_size.x + 0.01, button_size.y + 0.01,x_pos - button_size.x * 0.5 - 0.005, y_pos - button_size.y * 0.5 - 0.005, cursor_pos) then
                directx.draw_triangle(x_pos + half_size.x * size, y_pos, x_pos - half_size.x * size, y_pos  + half_size.y * size, x_pos - half_size.x * size, y_pos - half_size.y * size, highlight_colour)
                return PAD.IS_CONTROL_JUST_PRESSED(2, 18)
           end
        end
        directx.draw_triangle(x_pos + half_size.x * size, y_pos, x_pos - half_size.x * size, y_pos  + half_size.y * size, x_pos - half_size.x * size, y_pos - half_size.y * size, primary_text_colour) 
    end

    local function draw_tabs(tab_count)
        local aspect_ratio = get_aspect_ratio()
            local button_size = current_window.tabs_collapsed and {x = 0.015, y = 0.015} or {x = 0.06, y = 0.015}
            if aspect_ratio >= 1 then
                button_size.y = button_size.y * aspect_ratio
            else
                button_size.x = button_size.x * aspect_ratio
            end
            local drawpos = {x = current_window.x - button_size.x - 0.005, y = current_window.y - 0.004}
            directx.draw_rect(drawpos.x, drawpos.y, button_size.x, current_window.height + 0.008, background_colour)
            directx.draw_rect(drawpos.x, drawpos.y, button_size.x, button_size.y - 0.002, gray_colour)
            if draw_collapse_button(drawpos.x + 0.0075, drawpos.y + button_size.y *0.5 - 0.03, 1.25, current_window.tabs_collapsed and -1 or 1) then
                current_window.tabs_collapsed = not current_window.tabs_collapsed
            end
            

                for i = 1, tab_count, 1 do
                    local button_drawpos = {x = drawpos.x, y = drawpos.y + (i - 1) * button_size.y}
                    if cursor_mode then
                        if get_overlap_with_rect( button_size.x, button_size.y, button_drawpos.x, button_drawpos.y, cursor_pos) then
                            directx.draw_rect(button_drawpos.x, button_drawpos.y, button_size.x, button_size.y, highlight_colour)
                            if PAD.IS_CONTROL_JUST_PRESSED(2, 18) then
                                current_window.current_tab = i
                            end
                        else
                            directx.draw_rect(button_drawpos.x, button_drawpos.y, button_size.x, button_size.y, gray_colour)
                        end 
                    else
                        directx.draw_rect(button_drawpos.x, button_drawpos.y, button_size.x, button_size.y, gray_colour)
                    end
                    directx.draw_texture(current_window.tabs[i].data.icon, 0.006, 0.006, -0.1, 0.5, button_drawpos.x, button_drawpos.y + button_size.y * 0.5, 0, primary_text_colour)
                    if not current_window.tabs_collapsed then
                        directx.draw_text(button_drawpos.x + (button_size.x * 0.1) * 2, button_drawpos.y + button_size.y * 0.5, current_window.tabs[i].data.title, ALIGN_CENTRE_LEFT, 0.5, primary_text_colour, false)
                    end
                end
                if not current_window.tabs_collapsed then
                    directx.draw_text(drawpos.x + button_size.x * 0.5,current_window.y + button_size.y * 0.5 - 0.034, "tabs", ALIGN_CENTRE, 0.5, primary_text_colour)
                end
    end

    local function add_with_and_height(width, height, horizontal)
        if not horizontal then
            if width > current_window.width then
                current_window.width = width
            end
            current_window.height = current_window.height + height
        else
            horizontal_temp_width = horizontal_temp_width + width
            if height > horizontal_temp_height then
                horizontal_temp_height = height
            end
        end
    end

    local function draw_container(container)
        for index, element in pairs(container.elements) do
            local type = element.type
            if type == 'E' then
                element.func(element.data)
            else if type == 'C' then
                element.func(element)
            end
            end

        end
    end

    local function draw_text(data)
        if not current_window.horizontal then
            directx.draw_text(temp_x, temp_y, data.text, ALIGN_TOP_LEFT, 0.5, data.colour or primary_text_colour, false)
            temp_y = temp_y + data.height
        else
            directx.draw_text(temp_x, temp_y, data.text, ALIGN_TOP_LEFT, 0.5, data.colour or primary_text_colour, false)
            temp_x = temp_x + data.width
        end
    end

    local function draw_label(data)
        if not current_window.horizontal then
            directx.draw_text(temp_x, temp_y, data.name, ALIGN_TOP_LEFT, 0.5, data.colour or primary_text_colour, false)
            temp_x = temp_x + current_window.width
            directx.draw_text(
                temp_x,
                temp_y,
                data.value,
                ALIGN_TOP_RIGHT,
                0.5,
                data.highlight_colour or highlight_colour,
                false
            )
            temp_x = temp_x - current_window.width
            temp_y = temp_y + data.height
        else
            directx.draw_text(temp_x, temp_y, data.name, ALIGN_TOP_LEFT, 0.5, data.colour or primary_text_colour, false)
            temp_x = temp_x + data.name_width
            directx.draw_text(
                temp_x,
                temp_y,
                data.value,
                ALIGN_TOP_LEFT,
                0.5,
                data.highlight_colour or highlight_colour,
                false
            )
            temp_x = temp_x + data.value_width
        end
    end

    local function draw_div(data)
        if not current_window.horizontal then
            temp_y = temp_y + 0.01
            directx.draw_line(
                temp_x,
                temp_y,
                temp_x + current_window.width,
                temp_y,
                data.highlight_colour or highlight_colour,
                data.highlight_colour or highlight_colour
            )
            temp_y = temp_y + 0.01
        else
            temp_x = temp_x + 0.005
            directx.draw_line(
                temp_x,
                temp_y,
                temp_x,
                temp_y + 0.02,
                data.highlight_colour or highlight_colour,
                data.highlight_colour or highlight_colour
            )
            temp_x = temp_x + 0.005
        end
    end

    local function enable_horizontal(data)
        current_window.horizontal = true
        draw_container(data)
    end

    local function disable_horizontal(data)
        current_window.horizontal = false
        temp_x = temp_x - data.width
        temp_y = temp_y + data.height
    end

    local function draw_subhead(data)
        if not current_window.horizontal then
            directx.draw_text(
                temp_x + current_window.width * 0.5,
                temp_y,
                data.text,
                ALIGN_TOP_CENTRE,
                0.55,
                data.colour or highlight_colour,
                false
            )
            local x, y = directx.get_text_size(data.text, 0.55)
            temp_y = temp_y + y + 0.003
        else
            directx.draw_text(
                temp_x,
                temp_y,
                data.text,
                ALIGN_TOP_LEFT,
                0.55,
                data.colour or highlight_colour,
                false
            )
            temp_x = temp_x + directx.get_text_size(data.text, 0.55)
        end
    end

    local function draw_button(data)
        directx.draw_rect(temp_x, temp_y, data.width, data.height - 0.005, data.colour or highlight_colour)
        directx.draw_text(temp_x - data.padding, temp_y, data.text, ALIGN_TOP_LEFT, 0.5, secondary_text_colour)
        if not current_window.horizontal then
            temp_y = temp_y + data.height
        else
            temp_x = temp_x + data.width + (data.padding * 3)
        end
    end

    local function draw_toggle(data)
        directx.draw_rect(temp_x, temp_y, data.button_size.x, data.button_size.y, gray_colour)
        if data.state then
            directx.draw_texture(checkmark_texture, 0.005, 0.005, 0, 0, temp_x, temp_y, 0, primary_text_colour)
        end
        temp_x = temp_x + data.button_size.x
        directx.draw_text(temp_x, temp_y, data.text, ALIGN_TOP_LEFT, 0.5, data.colour)
        if not current_window.horizontal then
            temp_y = temp_y + data.button_size.y + data.padding
            temp_x = temp_x - data.button_size.x
        else
            temp_x = temp_x + data.width + data.padding
        end
    end

    -- SETTERS
    self.set_background_colour = function(r, g, b)
        background_colour = {['r'] = r, ['g'] = g, ['b'] = b, ['a'] = 1}
    end
    self.set_highlight_colour = function(r, g, b)
        highlight_colour = {['r'] = r, ['g'] = g, ['b'] = b, ['a'] = 1}
    end
    self.set_primary_text_colour = function(r, g, b)
        primary_text_colour = {['r'] = r, ['g'] = g, ['b'] = b, ['a'] = 1}
    end
    self.set_secondary_text_colour = function(r, g, b)
        secondary_text_colour = {['r'] = r, ['g'] = g, ['b'] = b, ['a'] = 1}
    end
    self.set_gray_colour = function (r,g,b)
        gray_colour = {['r'] = r, ['g'] = g, ['b'] = b, ['a'] = 1}
        
    end
    -- OTHER METHODS

    --enable or disable the cursor
    self.toggle_cursor_mode = function(state2)
        if state2 == nil then
            cursor_mode = not cursor_mode
        else
            cursor_mode = state2
        end
        PAD._SET_cursor_LOCATION(0.5, 0.5)
        util.create_tick_handler(UI_update)
        if cursor_mode then
            menu.trigger_commands("disablelookud on")
            menu.trigger_commands("disablelooklr on")
            menu.trigger_commands("disableattack on")
            menu.trigger_commands("disableattack2 on")
        else
            menu.trigger_commands("disablelookud off")
            menu.trigger_commands("disablelooklr off")
            menu.trigger_commands("disableattack off")
            menu.trigger_commands("disableattack2 off")
        end
    end

    self.start_tab_container = function (title, x_pos, y_pos, tabs, id)
        local sizex, sizey = directx.get_text_size(title, 0.6)
        local hash = util.joaat(id)
        if tab_containers[hash] ~= nil then
            current_window = tab_containers[hash]
            current_window.open_containers = {}
            current_window.active_container = container.new()
            current_window.horizontal = false
            current_window.height = sizey + 0.02
            current_window.tabs = tabs
            temp_y = current_window.y
            temp_x = current_window.x
        else
            current_window ={
                x = x_pos,
                y = y_pos,
                width = sizex + 0.02,
                height = sizey + 0.02,
                largest_height = 0,
                title = title,
                horizontal = false,
                open_containers = {},
                active_container = container.new(),
                is_being_dragged = false,
                tabs_collapsed = false,
                id = hash,
                current_tab = 1,
                tabs = tabs
            }
            tab_containers[hash] = current_window
        end
        temp_y = temp_y - 0.03
        current_window.tabs[current_window.current_tab].content()
        temp_y = temp_y + 0.03

        self.finish_tab_container()
    end

    self.finish_tab_container = function ()
        --determine if we use calculated height or largest height
        if current_window.height < current_window.largest_height then
            current_window.height = current_window.largest_height
        else
            current_window.largest_height = current_window.height
        end
        --calculate width + tabs
        local tab_width = current_window.tabs_collapsed == true and 0.016 or 0.061
        -- draw border
        directx.draw_rect(
            temp_x - 0.005 - tab_width,
            temp_y - 0.005 - 0.03,
            current_window.width + tab_width + 0.01,
            current_window.height + 0.04,
            highlight_colour
        )

        -- draw background
        directx.draw_rect(
            temp_x - 0.004,
            temp_y - 0.004,
            current_window.width + 0.008,
            current_window.height + 0.008,
            background_colour
        )
        --draw title bar
        directx.draw_rect(temp_x - tab_width - 0.004, temp_y - 0.004 - 0.03, current_window.width + tab_width + 0.008, 0.03, gray_colour)

                --draw tabs
                draw_tabs(#current_window.tabs)

        directx.draw_text(
            temp_x + current_window.width  * 0.5,
            temp_y - 0.03,
            current_window.title,
            ALIGN_TOP_CENTRE,
            .6,
            primary_text_colour,
            false
        )

        if cursor_mode then
            if get_overlap_with_rect(current_window.width + 0.008, 0.03, temp_x - 0.004, temp_y - 0.004 - 0.03, cursor_pos) then
                if PAD.IS_CONTROL_JUST_PRESSED(2, 18) then
                    current_window.is_being_dragged = true
                end
            end
            if PAD.IS_CONTROL_JUST_RELEASED(2, 18) then
                current_window.is_being_dragged = false
            end

            if current_window.is_being_dragged then
                current_window.x = cursor_pos.x - (current_window.width - tab_width) * 0.5
                current_window.y = cursor_pos.y + 0.004 + 0.015
            end
        end

        draw_container(current_window.active_container)

        temp_container = {}
        current_window = {}
    end
    --start a new window
    self.begin = function(title, x_pos, y_pos, Id)
        local sizex, sizey = directx.get_text_size(title, 0.6)
        local hash = util.joaat(Id or title)
            if windows[hash] ~= nil then
                current_window = windows[hash]
                current_window.open_containers = {}
                current_window.active_container = container.new()
                current_window.horizontal = false
                current_window.width = sizex + 0.02
                current_window.height = sizey + 0.02
                current_window.tabs = {}
                temp_y = current_window.y
                temp_x = current_window.x
            else
                current_window = {
                    x = x_pos,
                    y = y_pos,
                    width = sizex + 0.02,
                    height = sizey + 0.02,
                    title = title,
                    horizontal = false,
                    open_containers = {},
                    active_container = container.new(),
                    is_being_dragged = false,
                    id = hash
                }
                windows[hash] = current_window
            end
    end

    --finish and draw the window
    self.finish = function()
            directx.draw_rect(
                temp_x - 0.005,
                temp_y - 0.005,
                current_window.width + 0.01,
                current_window.height + 0.01,
                highlight_colour
            )
            directx.draw_rect(
                temp_x - 0.004,
                temp_y - 0.004,
                current_window.width + 0.008,
                current_window.height + 0.008,
                background_colour
            )
            directx.draw_rect(temp_x - 0.004, temp_y - 0.004, current_window.width + 0.008, 0.03, gray_colour)
    
            directx.draw_text(
                temp_x + current_window.width * 0.5,
                temp_y,
                current_window.title,
                ALIGN_TOP_CENTRE,
                .6,
                primary_text_colour,
                false
            )
    
            if cursor_mode then
                if get_overlap_with_rect(current_window.width + 0.008, 0.03, temp_x, temp_y, cursor_pos) then
                    if PAD.IS_CONTROL_JUST_PRESSED(2, 18) then
                        current_window.is_being_dragged = true
                    end
                end
                if PAD.IS_CONTROL_JUST_RELEASED(2, 18) then
                    current_window.is_being_dragged = false
                end
    
                if current_window.is_being_dragged then
                    current_window.x = cursor_pos.x - current_window.width * 0.5
                    current_window.y = cursor_pos.y - 0.03 * 0.5
                end
            end
    
            temp_y = temp_y + 0.03
    
            draw_container(current_window.active_container)
            temp_container = {}
            current_window = {}
    end

    --add a text element to the current window
    self.text = function(text, colour)
        text = tostring(text)
        local width, height = directx.get_text_size(text, plain_text_size)
        add_with_and_height(width, height, current_window.horizontal)
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {text = text, width = width, height = height, colour = colour},
            func = draw_text,
            type = 'E'
        }
    end

    --add a subhead to the current window
    self.subhead = function(text, colour)
        text = tostring(text)
        local width, height = directx.get_text_size(text, subhead_text_size)
        add_with_and_height(width, height, current_window.horizontal)
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {text = text, width = width, height = height, colour = colour},
            func = draw_subhead,
            type = 'E'
        }
    end

    --add a divider to the current window
    self.divider = function(colour)
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {colour = colour},
            func = draw_div,
            type = 'E'
        }
        add_with_and_height(0.01, 0.02, current_window.horizontal)
    end

    --add a label to the current window (usefull for displaying variables and there value)
    self.label = function(name, value, colour, label_highlight_colour)
        name = tostring(name)
        value = tostring(value)
        local name_x, name_y = directx.get_text_size(name, plain_text_size)
        local value_x = directx.get_text_size(value, plain_text_size)
        local total_x = value_x + name_x
        add_with_and_height(total_x, name_y, current_window.horizontal)
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {
                name = name,
                value = value,
                name_width = name_x,
                value_width = value_x,
                height = name_y,
                colour = colour,
                highlight_colour = label_highlight_colour
            },
            func = draw_label,
            type = 'E'
        }
    end

    --adds a button to the current window
    self.button = function(name, colour, button_highlight_colour)
        name = tostring(name)
        local name_width, name_height = directx.get_text_size(name, plain_text_size)
        local padding = 0.001
        name_width, name_height = name_width + padding, name_height + 0.005 + padding
        local clicked = false
        if cursor_mode then
            if
                get_overlap_with_rect(
                    name_width,
                    name_height - (padding * 4),
                    horizontal_temp_width + temp_x,
                    current_window.height + temp_y - name_height * 0.5 + padding * 2,
                    cursor_pos
                )
             then
                colour =
                    button_highlight_colour or
                    {
                        ["r"] = 1.5,
                        ["g"] = 1.0,
                        ["b"] = 1.5,
                        ["a"] = 1
                    }
                if PAD.IS_CONTROL_JUST_PRESSED(2, 18) then
                    clicked = true
                end
            end
        end
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {
                text = name,
                width = name_width,
                height = name_height,
                colour = colour or highlight_colour,
                padding = padding
            },
            func = draw_button,
            type = 'E'
        }
        add_with_and_height(name_width + (padding * 3), name_height, current_window.horizontal)
        return clicked
    end

    --adds a toggle to the current menu
    self.toggle = function(name, state, colour, optional_function)
        state = state or false
        colour = colour or primary_text_colour
        name = tostring(name)
        local name_width, name_height = directx.get_text_size(name, plain_text_size)

        local button_size = {x = 0.010, y = 0.010}
        local aspect_ratio = get_aspect_ratio()
        if aspect_ratio >= 1 then
            button_size.y = button_size.y * aspect_ratio
        else
            button_size.x = button_size.x * aspect_ratio
        end

        local padding = 0.005

        if cursor_mode then
            if
                get_overlap_with_rect(
                    button_size.x,
                    button_size.y,
                    horizontal_temp_width + temp_x,
                    current_window.height + temp_y - button_size.y * 0.5,
                    cursor_pos
                )
             then
                if PAD.IS_CONTROL_JUST_PRESSED(2, 18) then
                    state = not state
                    if optional_function ~= nil then
                        optional_function(state)
                    end
                end
            end
        end
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {
                text = name,
                width = name_width,
                height = name_height,
                colour = colour,
                button_size = button_size,
                padding = padding,
                state = state
            },
            func = draw_toggle,
            type = 'E'
        }
        add_with_and_height(name_width + button_size.x + padding, button_size.y + padding, current_window.horizontal)
        return state
    end

    --start drawing elements in the horizontal direction
    self.start_horizontal = function()
        if horizontal_temp_width ~= 0 then
            error("new horizontal started without closing previous horizontal", 2)
        end
        current_window.open_containers[#current_window.open_containers + 1] = current_window.active_container
        temp_container = container.new()
        temp_container.func = enable_horizontal
        current_window.active_container = temp_container
        current_window.horizontal = true
    end

    --return to drawing in the diagonal direction
    self.end_horizontal = function()
        current_window.active_container.elements[#current_window.active_container.elements + 1] = {
            data = {width = horizontal_temp_width, height = horizontal_temp_height},
            func = disable_horizontal,
            type = 'E'
        }
        current_window.horizontal = false
        add_with_and_height(horizontal_temp_width, horizontal_temp_height, current_window.horizontal)
        local parent = current_window.open_containers[#current_window.open_containers]
        parent.elements[#parent.elements+1] = temp_container
        current_window.active_container = parent
        horizontal_temp_width, horizontal_temp_height = 0, 0
    end
    return self
end

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
