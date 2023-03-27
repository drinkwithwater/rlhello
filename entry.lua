
local pyskynet = require "pyskynet"
local skynet = require "skynet"
local foreign = require "pyskynet.foreign"
local thlua = require "thlua"
thlua.patch()
local Game = require "CellGame"

local CMD = {}
local mGame = Game.new()
function CMD.reset()
    mGame = Game.new()
    return nil
end

function CMD.step(vAction)
    return mGame:step(vAction)
end

function CMD.step(vAction)
    return mGame:step(vAction)
end

function CMD.dump()
	mGame:dump()
end

pyskynet.start(function()
    foreign.dispatch(CMD)
end)
