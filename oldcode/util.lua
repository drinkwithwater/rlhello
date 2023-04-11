local ns = require "numsky"
local prep_util = {}

function prep_util._clip(value, _min, _max)
    return math.min(_max, math.max(_min, value))
end


function prep_util._one_hot_embed(index, length)
    assert(0 <= index and index < length)
    local embed = {}
    for i=1, length do
        embed[i] = 0.0
    end
    embed[index + 1] = 1.0
    return embed
end


function prep_util._lidar_embed(dx, dz, self_camera, lidar_radius, env_radius, embed_length)
	if lidar_radius == nil then lidar_radius = 10 end
	if env_radius == nil then env_radius = 25 end
	if embed_length == nil then embed_length = 12 end

	local lidar_embedding = {}
	local camera_direction = self_camera / 180 * math.pi
    for i = 0, embed_length-1 do
        local theta = 2 * math.pi / embed_length * i + camera_direction
        local lidar_point_x = dx + lidar_radius * math.cos(theta)
        local lidar_point_z = dz + lidar_radius * math.sin(theta)
        local distance = math.sqrt(lidar_point_x * lidar_point_x + lidar_point_z * lidar_point_z)
        local lidar_point_embed = nil
        if distance >= env_radius then
            lidar_point_embed = 1.0
        else
            lidar_point_embed = 0.0
        end
        lidar_embedding[i+1] = lidar_point_embed
    end
    return lidar_embedding
end


function prep_util._binary_embed(value, min_value, max_value, length, power)
    if power == nil then power = 1.0 end

    assert(min_value <= value and value <= max_value, "value: "..value..", min_value: "..min_value..", max_value: "..max_value)
    local embed = {}
    for i = 1, length do
        embed[i] = 0.0
    end
    local scale = math.floor(((value - min_value) ^ power) / ((max_value - min_value + 1e-8) ^ power) * (2^length))
    while scale > 0 do
        if scale % 2 == 1 then
            embed[length] = 1.0
        end
        scale = scale // 2
        length = length - 1
    end
    return embed
end


function prep_util._power_embed(value, min_value, max_value, length, power, monotonic)
    if power == nil then power = 0.5 end
    if monotonic == nil then monotonic = true end

    assert(min_value <= value and value <= max_value, "value: "..value..", min_value: "..min_value..", max_value: "..max_value)
    local vid, max_vid = nil, nil
    if power == 0.5 then
        vid = math.sqrt(value - min_value)
        max_vid = math.sqrt(max_value - min_value)
    elseif power == 1.0 then
        vid = value - min_value
        max_vid = max_value - min_value
    else
        vid = (value - min_value) ^ power
        max_vid = (max_value - min_value) ^ power
    end

    local p = nil
    if max_vid > 0 then
        p = vid / max_vid
    else
        p = 0.0
    end

    local embed = {}
    for i =1, length do
        embed[i] = 0.0
    end
    if p > 0 then
        local idx = math.ceil(p / (1.0 / length)) - 1
        if monotonic then
            for i = 1, idx do
                embed[i] = 1.0
            end
            embed[idx + 1] = p * length - idx
        else
            embed[idx + 1] = 1.0
        end
    end
    return embed
end


function prep_util._position_embed( pos, d_hid )
    local embed = {}
    for i = 0, d_hid-1 do
        if i % 2 == 0 then
            embed[i+1] = math.sin(pos / (10000. ^ (2.0 * math.floor(i / 2) / d_hid)))
        else
            embed[i+1] = math.cos(pos / (10000. ^ (2.0 * math.floor(i / 2) / d_hid)))
        end
    end
    return embed
end


function prep_util._cal_relative_angle(cur, base)
    local angle = (cur - base) % 360
    return angle / 180 * math.pi
end


function prep_util._relative_angle_one_hot(theta, length)
	return ns.cos(ns.linspace(0, math.pi*2, length, false) - theta)
end

function prep_util.array_add(a1, a2)
    for i = 1, #a2 do
        a1[#a1+1] = a2[i]
    end
    return a1
end


return prep_util




-- TODO: 测试util里的各种embed函数






local pb = require "pb"
local protoc = require "protoc"
local util = require "prep_utils"
local ns = require "numsky"

local protoc_obj = protoc.new()
protoc_obj:loadfile("./GamebotAPI.proto")

local observation_xml = io.open("lua/observation.xml"):read("*a")

Pi = 3.14159265358979323846264338328
heroHpMax = 250000
heroHpSize = 16

heroMpMax = 60000.0
heroMpSize = 6

heroBurstEnergyMax = 10000.0
heroBurstEnergySize = 4

heroDodageMax = 600.0
heroDodageSize = 10

heroShieldMax = 10000.0
heroShieldSize = 6

MapH = 24
MapW = 24
MapC = 9

default_feature_config = {
    position_embed_size= 16,
    angle_embed_size= 8,
    radius_embed_size= 6,
    move_quant_level= 24}


local WindowState = {}

function WindowState.new(str, n)
	local self = {
		name="",
		items={},
		count=0,
		idx=0
	}
	setmetatable(self, {__index = WindowState})
self.name = str
	self.items = {}
	for i = 1, n do
		self.items[#self.items + 1] = 0
	end
	self.count = 0
	self.idx = 1
	return self
end

function WindowState:push(obj)
	self.items[self.idx] = obj
	self.idx = self.idx + 1
	self.count = self.count + 1
	self.idx = self.idx % #self.items + 1
end

local GamebotCppEnv = {}

function GamebotCppEnv.new()
	local self = {
		action_space = {},
		reward_space ={},
		reward = {},
		done = nil,
		info = {},
		obs = {},
		_available_skills ={},
		_action = {},
		distance_stat = nil,
		meta = {},
		user_index = 0,
		prev_reward = {},

		request = nil,
		request_step = nil,
		request_reset = nil,
		response = nil,
		response_step = nil,
		response_quit = nil,
		init_ob = nil,
		hero_me = nil,
		hero_you = nil,

		feature_config = {},
		dict_skillIndex2Slot = {},
		self_pos = {},
		camera = nil,
		preprocess_result = {}
	}
	setmetatable(self, {__index = GamebotCppEnv})
	self.feature_config["position_embed_size"]=16
    self.feature_config["angle_embed_size"]=8
    self.feature_config["radius_embed_size"]=6
    self.feature_config["move_quant_level"]=24

    self.action_space[1] = self.feature_config["move_quant_level"] + 1
    self.action_space[2] = 12
    self.action_space[3] = 5

    self.self_pos ={0, 0}
self.camera = 0

    self.feature_config["global_feature_size"] = 21
    self.feature_config["hero_feature_size"] = 172
    self.feature_config["hero_skill_feature_size"] = 25
    self.feature_config["box_feature_size"] = 110

    self.meta = {1., 1., 0., 0., 0., 0., 0., 0.}
    self.user_index = 1
    self.dict_skillIndex2Slot = {1,0}

    return self
end


function GamebotCppEnv:get_done()
	return self.done
end


function GamebotCppEnv:get_reward()
	return self.reward["r_hp"]
end


function GamebotCppEnv:get_info()
	return self.info
end


function GamebotCppEnv:get_camera()
	return self.camera
end


function GamebotCppEnv:step_wait(proto_data, prev_action_0, prev_action_1)
    if prev_action_0 == nil then prev_action_0 = 0 end
    if prev_action_1 == nil then prev_action_1 = 0 end

    self.request = pb.decode("GamebotAPIProtocol.Request", proto_data)
    self.request_step = self.request.step
    self.done = self.request_step.done
   	self._action[1] = prev_action_0
   	self._action[2] = prev_action_1

   	local pre_result = self:_preprocess_info(self.request_step, self._action)
   	self.reward = self:_process_step_reward(self.request_step, self._action, pre_result)

self.info["r_win"] = self.reward["r_win"]
self.info["r_hp_your"] = self.reward["r_hp_your"]
self.info["r_hp_my"] = self.reward["r_hp_my"]
self.info["r_common"] = self.reward["r_common"]
   	self.reward["r_common"] = nil

   	local sum = 0.0
   	for k, v in ipairs(self.info["r_common"]) do
   		sum  = sum + v
   	end
   	self.reward["r_common"] = math.min(1.0, math.max(-1.0, sum))

   	sum = 0.0
   	local dis_count = self.distance_stat.count > #self.distance_stat.items and #self.distance_stat.items or self.distance_stat.count
   	for i = 1, #self.distance_stat.items do
   		sum = sum + self.distance_stat.items[i]
   	end
self.info["distance"] = sum / dis_count

   	local s = self:_process_step_observation(self.request_step, self._action,self.reward)
   	self:_postprocess_info(self.request_step, self._action, self.reward)

	return s
end


function GamebotCppEnv:reset(proto_data, meta_data, player_index)
	self.obs = {}
	self._action = {0., 0.}

	self.prev_reward["r_hp"] = 0.
    self.prev_reward["r_win"] = 0.
    self.prev_reward["r_hp_your"] = 0.
    self.prev_reward["r_hp_my"] = 0.
    self.prev_reward["r_common"] = 0.
    self.self_pos = {0., 0.}
self.camera = 0

    self.distance_stat = WindowState.new("distance", 1000)

    self.request = pb.decode("GamebotAPIProtocol.Request", proto_data)
    self.request_reset = self.request.restart_game
    self:_process_reset_observation(self.request_reset)

    self._available_skills = {1., 1.}
    self.user_index = player_index

    if player_index == 1 then
    	self.hero_me = self.request_reset.hero_observation[1]
    	self.hero_you = self.request_reset.hero_observation[2]
    else
    	self.hero_me = self.request_reset.hero_observation[2]
    	self.hero_you = self.request_reset.hero_observation[1]
    end

    -- ？？？
    -- prev_reward["r_hp"].push_back(0.0);
    -- prev_reward["r_win"].push_back(0.0);
    -- prev_reward["r_common"].push_back(0.0);
    -- prev_reward["r_hp_your"].push_back(0.0);
    -- prev_reward["r_hp_my"].push_back(0.0);

    self.meta = meta_data
    self.preprocess_result = {}
	self.observation_canvas = ns.canvas(observation_xml, "observation.xml")
	self.observation_canvas:reset(self.feature_config, self.action_space)
    return 1

end


function GamebotCppEnv:get_camera()
	return self.camera
end


function GamebotCppEnv:available_skills()
	return self._available_skills
end


function GamebotCppEnv:_process_reset_observation(ob)
	self.init_ob = ob.init_observation

end



function GamebotCppEnv:_preprocess_info(ob, action)
	local result = {}
	for i = 1, #ob.hero_observation do
		local heroProperty = ob.hero_observation[i].hero_property
		if heroProperty.user_index == self.user_index then
			result["executed"] = ob.hero_observation[i].last_action_right_result
			self.self_pos[1] = heroProperty.hero_x
			self.self_pos[2] = heroProperty.hero_z

			for j = 1, #ob.hero_observation do
				if i ~= j then
					local dx = ob.hero_observation[j].hero_property.hero_x - heroProperty.hero_x
					local dz = ob.hero_observation[j].hero_property.hero_z - heroProperty.hero_z
self.camera = math.floor(math.atan(dx, dz) / Pi * 180 + 360) % 360
				end
			end
		end
	end

	local delta_x  = ob.hero_observation[1].hero_property.hero_x - ob.hero_observation[2].hero_property.hero_x
    local delta_z = ob.hero_observation[1].hero_property.hero_z - ob.hero_observation[2].hero_property.hero_z
    self.distance_stat:push(math.sqrt(delta_x * delta_x + delta_z * delta_z))

    return result
end


function GamebotCppEnv:_postprocess_info(f_ob, f_action, f_reward)
	if self.user_index == 1 then
		self.hero_me = f_ob.hero_observation[1]
		self.hero_you = f_ob.hero_observation[2]
	else
		self.hero_me = f_ob.hero_observation[2]
		self.hero_you = f_ob.hero_observation[1]
	end

	self.prev_reward = f_reward


end


function GamebotCppEnv:_process_step_reward(ob, prev_action, pre_result)
	local me = self.user_index
	local you = 3 - me
	local reward_ = {}

	reward_["r_win"] = 0.
	reward_["r_hp"] = 0.
	reward_["r_hp_my"] = 0.
	reward_["r_hp_your"] = 0.
	if ob.state_win_user_index == me then
		reward_["r_win"] = 1.0
	elseif ob.state_win_user_index == you then
		reward_["r_win"] = -1.0
	elseif ob.state_win_user_index == 3 then
		reward_["r_win"] = 0.0
	else
		reward_["r_win"] = 0.0
	end

	local my, your = nil, nil
	local delta_hp = {0., 0.}

	for i = 1, 2 do
		if ob.hero_observation[i].hero_property.user_index == me then
			my = ob.hero_observation[i]
			delta_hp[1] = ob.hero_observation[i].hero_property.hero_hp - self.hero_me.hero_property.hero_hp
			delta_hp[1] = delta_hp[1] / ob.hero_observation[i].hero_property.hero_hp_max
		elseif ob.hero_observation[i].hero_property.user_index == you then
			your = ob.hero_observation[i]
			delta_hp[2] = ob.hero_observation[i].hero_property.hero_hp - self.hero_you.hero_property.hero_hp
			delta_hp[2] = delta_hp[2] / ob.hero_observation[i].hero_property.hero_hp_max
		else
			;
		end
	end

	reward_["r_hp"] = delta_hp[1] * self.meta[1] - delta_hp[2] * self.meta[2]
	reward_["r_hp_my"] = delta_hp[1]
	reward_["r_hp_your"] = -delta_hp[2]


	local r_common = {0., 0., 0., 0., 0., 0.}
	for i = 1, 6 do
		r_common[i] = r_common[i] * self.meta[i+2]
	end
	reward_["r_common"] = r_common

	return reward_
end

function GamebotCppEnv:_process_step_observation(ob, action, f_reward)
	return self.observation_canvas:render(self, ob, action, f_reward)
end

if false then

-- TEST
local env = nil

function initEnv()
	env = GamebotCppEnv.new()
	return 1
end


function reset_env_array(proto_data, meta_data, player_index)
	return env:reset(proto_data, meta_data, player_index)
end


function step(proto_data, prev_action_0, prev_action_1)
	return env:step_wait(proto_data, prev_action_0, prev_action_1)
end

function get_camera()
	return env:get_camera()
end


function computer_action_right(action1)
	return env.dict_skillIndex2Slot[action1]
end


function get_array_by_key(key)
	return env.preprocess_result[key]
end

end


return GamebotCppEnv
