
local loaded, packages, require_ = {}, {}, require

local function require(path)
    if loaded[path] then
        return loaded[path]
    elseif packages[path] then
        loaded[path] = packages[path](path)
        return loaded[path]
    else
        return require_(path)
    end
end

--thlua.Enum begin ==========(
do local _ENV = _ENV
packages['thlua.Enum'] = function (...)

local Enum = {}

Enum.SymbolKind_CONST = "const"
Enum.SymbolKind_LOCAL = "local"
Enum.SymbolKind_PARAM = "param"
Enum.SymbolKind_ITER = "iter"

Enum.CastKind_COVAR = "@"
Enum.CastKind_CONTRA = "@>"
Enum.CastKind_CONIL = "@!"
Enum.CastKind_FORCE = "@?"
Enum.CastKind_POLY = "@<"

return Enum

end end
--thlua.Enum end ==========)

--thlua.Exception begin ==========(
do local _ENV = _ENV
packages['thlua.Exception'] = function (...)

local class = require "thlua.class"


	  
	  


local Exception = class ()
Exception.__tostring=function(t)
	return "Exception:"..tostring(t.node)..":"..t.msg
end

function Exception:ctor(vMsg, vNode)
	self.msg = tostring(vMsg)
	self.node = vNode
end

return Exception

end end
--thlua.Exception end ==========)

--thlua.TestCase begin ==========(
do local _ENV = _ENV
packages['thlua.TestCase'] = function (...)

local Runtime = require "thlua.runtime.DiagnosticRuntime"
local CodeEnv = require "thlua.code.CodeEnv"
local SplitCode = require "thlua.code.SplitCode"

	  
	  


local TestCase = {}
TestCase.__index = TestCase

function TestCase.new(vScript)
	local nLineToResult   = {}
	local nLineList = {}
	for nLine in string.gmatch(vScript, "([^\n]*)") do
		nLineList[#nLineList + 1] = nLine
		if nLine:match("--E$") then
			nLineToResult[#nLineList] = 0
		end
	end
	local self = setmetatable({
		_runtime = nil  ,
		_script = vScript,
		_lineToResult = nLineToResult,
	}, TestCase)
	self._runtime = Runtime.new(self)
	return self
end

function TestCase:getRuntime()
	return self._runtime
end

function TestCase.go(vScript, vName)
	if not vName then
		local nInfo = debug.getinfo(2)
		print(nInfo.source..":"..nInfo.currentline..":")
	else
		print(vName)
	end
	local case = TestCase.new(vScript)
	local nRuntime = case:getRuntime()
	local oldprint = print
	do
		print = function(...)
		end
	end
	nRuntime:pmain("[test]")
	print = oldprint
	local nLineToResult = case._lineToResult
	for _, nDiaList in pairs(nRuntime:getAllDiagnostic()) do
		for _, nDiagnostic in pairs(nDiaList) do
			local nLine = nDiagnostic.node.l
			local nResult = nLineToResult[nLine]
			if type(nResult) == "number" then
				nLineToResult[nLine] = nResult + 1
			else
				nLineToResult[nLine] = nDiagnostic.msg
			end
		end
	end
	local l    = {}
	for nLine, nResult in pairs(nLineToResult) do
		l[#l + 1] = {nLine, nResult}
	end
	for _, nPair in pairs(l) do
		local nLine, nResult = nPair[1], nPair[2]
		if nResult == 0 then
			print(nLine, "fail: no diagnostic")
		elseif type(nResult) == "string" then
			print(nLine, "fail: diagnostic unexpected", nResult)
		else
			print(nLine, "ok")
		end
	end
end

function TestCase:thluaSearch(vPath)
	error("test case can't search path")
end

function TestCase:thluaParseFile(vFileName)
	if vFileName == "[test]" then
    local nCodeEnv = CodeEnv.new(self._script, vFileName)
    local ok, err = nCodeEnv:checkOkay()
    if not ok then
        error(err)
    end
    return nCodeEnv
	else
		error("test case can only parse its script")
	end
end

return TestCase

end end
--thlua.TestCase end ==========)

--thlua.auto.AutoFlag begin ==========(
do local _ENV = _ENV
packages['thlua.auto.AutoFlag'] = function (...)

return {}

end end
--thlua.auto.AutoFlag end ==========)

--thlua.auto.AutoHolder begin ==========(
do local _ENV = _ENV
packages['thlua.auto.AutoHolder'] = function (...)

local Exception = require "thlua.Exception"


	  
	  


local AutoHolder = {}
AutoHolder.__index = AutoHolder
AutoHolder.__tostring = function(self)
	return "auto@"..tostring(self._node)
end

function AutoHolder.new(vNode , vContext)
	local self = setmetatable({
		_node=vNode,
		_context=vContext,
		_term=false
	}, AutoHolder)
	return self
end

function AutoHolder:checkRefineTerm(vContext)
	local nTerm = self._term
	if nTerm then
		return nTerm
	else
		error(Exception.new("undeduced auto param is used", vContext:getNode()))
	end
end

function AutoHolder:setAutoCastType(vContext, vType)
	local nTerm = vContext:RefineTerm(vType)
	self._term = nTerm
	return nTerm
end

function AutoHolder:getRefineTerm()
	return self._term
end

function AutoHolder:getType()
	local nTerm = self._term
	return nTerm and nTerm:getType()
end

function AutoHolder:getNode()
	return self._node
end

function AutoHolder.is(t)
	return getmetatable(t) == AutoHolder
end

return AutoHolder

end end
--thlua.auto.AutoHolder end ==========)

--thlua.auto.AutoTail begin ==========(
do local _ENV = _ENV
packages['thlua.auto.AutoTail'] = function (...)

local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"


	  
	  


local AutoTail = {}
AutoTail.__index = AutoTail

function AutoTail.new(vNode, vContext, vInit)
	local self = setmetatable({
		_node=vNode,
		_context=vContext,
		_holderList=vInit or {},
		_sealTail=false  ,
	}, AutoTail)
	return self
end

function AutoTail:getMore(vContext, vMore)
	local nList = self._holderList
	local nHolder = nList[vMore]
	if nHolder then
		return nHolder
	else
		local nSealTail = self._sealTail
		if not nSealTail then
			for i=#nList + 1, vMore do
				nList[i] = AutoHolder.new(self._node, self._context)
			end
			return nList[vMore]
		else
			if nSealTail == true then
				return vContext:NilTerm()
			else
				return nSealTail:getMore(vContext, vMore - #nList)
			end
		end
	end
end

function AutoTail:openTailFrom(vContext, vFrom)
	if vFrom == 1 then
		return self
	elseif vFrom > 1 then
		local nSelfHolderList = self._holderList
		local nSelfLen = #nSelfHolderList
		local nNewHolderList = {}
		for i=vFrom, nSelfLen do
			nNewHolderList[#nNewHolderList + 1] = nSelfHolderList[i]
			nSelfHolderList[i] = nil
		end
		local nNewAutoTail = AutoTail.new(self._node, self._context, nNewHolderList)
		self._sealTail = nNewAutoTail
		return nNewAutoTail
	else
		error("openTailFrom must take from > 0")
	end
end

function AutoTail:sealTailFrom(vContext, vFrom, vSealTail )
	if vSealTail == true then
		self._sealTail = true
	else
		self._sealTail = DotsTail.new(vContext, vSealTail)
	end
end

    
function AutoTail:recurPutTermWithTail(vList) 
	local nTail = self._sealTail
	if not nTail then
		return self
	end
	for i,v in ipairs(self._holderList) do
		local nTerm = v:getRefineTerm()
		if nTerm then
			vList[#vList + 1] = nTerm
		else
			vList[#vList + 1] = v
		end
	end
	if nTail == true then
		return false
	else
		if AutoTail.is(nTail) then
			return nTail:recurPutTermWithTail(vList)
		else
			return nTail
		end
	end
end

           
function AutoTail:_recurPutTypeWhenCheckout(vList, vSeal) 
	for i,v in ipairs(self._holderList) do
		local nType = v:getType()
		if nType then
			vList[#vList + 1] = nType
		else
			return false
		end
	end
	local nTail = self._sealTail
	if not nTail then
		if vSeal then
			self._sealTail = true
			return true
		else
			return false
		end
	elseif nTail == true then
		return true
	elseif AutoTail.is(nTail) then
		return nTail:_recurPutTypeWhenCheckout(vList, vSeal)
	else
		return nTail:getRepeatType()
	end
end

function AutoTail:checkTypeTuple(vSeal)
	local nList = {}
	local nDotsType = self:_recurPutTypeWhenCheckout(nList, vSeal or false)
	if not nDotsType then
		return false
	else
		local nContext = self._context
		local nTuple = nContext:getTypeManager():TypeTuple(nContext:getNode(), table.unpack(nList))
		if nDotsType == true then
			return nTuple
		else
			return nTuple:Dots(nDotsType)
		end
	end
end

function AutoTail.is(t)
	return getmetatable(t) == AutoTail
end

return AutoTail

end end
--thlua.auto.AutoTail end ==========)

--thlua.boot begin ==========(
do local _ENV = _ENV
packages['thlua.boot'] = function (...)
tprint=function()
end
ttprint=function()
end

local ParseEnv = require "thlua.code.ParseEnv"

local boot = {}

boot.path = package.path:gsub("[.]lua", ".thlua")

boot.compile = ParseEnv.compile

function boot.load(chunk, chunkName, ...)
	local luaCode = boot.compile(chunk, chunkName)
	local f, err3 = load(luaCode, chunkName, ...)
	if not f then
		error(err3)
	end
	return f
end

function boot.searcher(name)
	local fileName, err1 = package.searchpath(name, boot.path)
	if not fileName then
		fileName, err1 = package.searchpath(name, package.path)
		if not fileName then
			return err1
		end
	end
	local file, err2 = io.open(fileName, "r")
	if not file then
		return err2
	end
	local thluaCode = file:read("*a")
	file:close()
	return boot.load(thluaCode, fileName)
end

local patch = false

function boot.patch()
	if not patch then
		table.insert(package.searchers, boot.searcher)
		patch = true
	end
end

-- start check from a main file
function boot.runCheck(vMainFileName)
	boot.patch()
	local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"
	local thloader = require "thlua.code.thloader"
	local nRuntime = DiagnosticRuntime.new(thloader)
	assert(nRuntime:pmain(vMainFileName))
end

function boot.makePlayGround()
	local PlayGround = require "thlua.server.PlayGround"
	local playground = PlayGround.new()
	return function(a, b)
		return playground:update(a, b)
	end
end

-- run language server
function boot.runServer(vMode)
	boot.patch()
	local FastServer = require "thlua.server.FastServer"
	local SlowServer = require "thlua.server.SlowServer"
	local server
	if vMode == "fast" then
		server = FastServer.new()
	else
		server = SlowServer.new()
	end

	print=function(...)
		--[[client:notify("window/logMessage", {
			message = client:packToString(3, ...),
			type = 3,
		})]]
	end

	server:mainLoop()
end

return boot

end end
--thlua.boot end ==========)

--thlua.builder.DoBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.builder.DoBuilder'] = function (...)

local Exception = require "thlua.Exception"
  

local DoBuilder = {}
DoBuilder.__index=DoBuilder

function DoBuilder.new(vContext, vNode)
	return setmetatable({
		pass=false,
	}, DoBuilder)
end

function DoBuilder:build(vHintInfo)
	if vHintInfo.attrSet.pass then
		self.pass = true
	end
end

return DoBuilder

end end
--thlua.builder.DoBuilder end ==========)

--thlua.builder.FunctionBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.builder.FunctionBuilder'] = function (...)

local AutoFlag = require "thlua.auto.AutoFlag"
local AutoFunction = require "thlua.func.AutoFunction"
local Reference = require "thlua.refer.Reference"
local Exception = require "thlua.Exception"
local Enum = require "thlua.Enum"
local Interface = require "thlua.object.Interface"
local AutoHolder = require "thlua.auto.AutoHolder"
local ClassFactory = require "thlua.func.ClassFactory"
local ClassTable = require "thlua.object.ClassTable"
local TermTuple = require "thlua.tuple.TermTuple"
local RetBuilder = require "thlua.tuple.RetBuilder"


	  
	  

	  
	    

	  
	      
	   

	   
		 
	

	   
		 
		 
		
		 
		 
		 
	

	   
		
		
		
		
		
	 
		
	


local FunctionBuilder = {}
FunctionBuilder.__index=FunctionBuilder

function FunctionBuilder.new(
	vStack,
	vNode ,
	vUpState,
	vInfo,
	vPrefixHint,
	vParRetMaker
)
	local self = {
		_stack=vStack,
		_manager=vStack:getTypeManager(),
		_node=vNode,
		_lexShot=vUpState,
		_prefixHint=vPrefixHint,
		_pass=vPrefixHint.attrSet.pass and true or false,
		_parRetMaker=vParRetMaker,
	}
	for k,v in pairs(vInfo) do
		self[k] = v
	end
	setmetatable(self, FunctionBuilder)
	return self
end

function FunctionBuilder:error(...)
	if not self._pass then
		self._stack:getRuntime():nodeError(self._node, ...)
	end
end

function FunctionBuilder:_makeRetTuples(
	vSuffixHint,
	vTypeList,
	vSelfType
)
	local nRetBuilder = RetBuilder.new(self._manager, self._node)
	local ok, err = pcall(vSuffixHint.caller, {
		extends=function(vHint, _)
			error("extends can only be used with function:class")
			return vHint
		end,
		implements=function(vHint, _)
			error("impl can only be used with function:class")
			return vHint
		end,
		isguard=function(vHint, vType)
			error("isguard can only be used with function.open")
			return vHint
		end,
		RetDots=function(vHint, vFirst, ...)
			nRetBuilder:RetDots(vFirst, ...)
			return vHint
		end,
		Ret=function(vHint, ...)
			nRetBuilder:Ret(...)
			return vHint
		end,
		Err=function(vHint, vErrType)
			nRetBuilder:Err(vErrType)
			return vHint
		end,
	})
	if not ok then
		error(Exception.new(tostring(err), self._node))
	end
	if nRetBuilder:isEmpty() then
		return false
	end
	local nRetTuples = nRetBuilder:build()
	if not self._hasRetSome then
		if nRetTuples and not self._pass then
			local hasVoid = false
			local hasSome = false
			nRetTuples:foreachWithFirst(function(vTypeTuple, _)
				if #vTypeTuple > 0 then
					hasSome = true
				else
					hasVoid = true
				end
			end)
			if hasSome and not hasVoid then
				self:error("hint return something but block has no RetStat")
			end
		end
	end
	return nRetTuples
end

function FunctionBuilder:_buildInnerFn()  
	local nNode = self._node
	assert(nNode.tag == "Function")
	local nPolyParNum = self._polyParNum
	local nFnMaker = function(vPolyParList, vSelfType)
		local nAutoFn = self._stack:newAutoFunction(nNode, self._lexShot)
		local nNewStack = nAutoFn:getBuildStack()
		nAutoFn:initAsync(function()
			local nGenParam, nSuffixHint, nGenFunc = self._parRetMaker(nNewStack, vPolyParList, vSelfType)
			local nCastTypeFn = nAutoFn:pickCastTypeFn()
			  
			local nCastArgs = nCastTypeFn and nCastTypeFn:getParTuple():makeTermTuple(nNewStack:inplaceOper())
			local nParTermTuple = nGenParam(nCastArgs)
			local nParTuple = nParTermTuple:checkTypeTuple()
			  
			local nCastRet = nCastTypeFn and nCastTypeFn:getRetTuples()
			local nHintRetTuples = self:_makeRetTuples(nSuffixHint, vPolyParList, vSelfType)
			if nHintRetTuples and nCastRet then
				if not nCastRet:includeTuples(nHintRetTuples) then
					nNewStack:error("hint return not match when cast")
				end
			end
			local nRetTuples = nHintRetTuples or nCastRet or (not self._hasRetSome and self._manager:VoidRetTuples(self._node))
			return nParTuple, nRetTuples, function()
				if self._pass then
					if not nParTuple or not nRetTuples then
						error("pass function can't take auto return or auto parameter")
					end
					return nParTuple, nRetTuples
				else
					local nRetTermTuple, nErrType = nGenFunc()
					local nParTuple = nParTuple or nParTermTuple:checkTypeTuple(true)
					if not nParTuple then
						nNewStack:error("auto parameter deduce failed")
						error("auto parameter deduce failed")
					end
					local nRetTuples = nRetTuples or self._manager:SingleRetTuples(self._node, nRetTermTuple:checkTypeTuple(), nErrType)
					if not nRetTuples then
						nNewStack:error("auto return deduce failed")
						error("auto return deduce failed")
					end
					return nParTuple, nRetTuples
				end
			end
		end)
		return nAutoFn
	end
	if not self._member then
		if nPolyParNum <= 0 then
			local ret = nFnMaker({}, false)
			self._stack:getSealStack():scheduleSealType(ret)
			return ret
		else
			return self._manager:PolyFunction(self._node, function(...)
				return nFnMaker({...}, false)
			end, nPolyParNum, self._stack)
		end
	else
		local nPolyFn = self._manager:PolyFunction(self._node, function(self, ...)
			return nFnMaker({...}, self)
		end, nPolyParNum + 1, self._stack)
		return self._manager:AutoMemberFunction(self._node, nPolyFn)
	end
end

function FunctionBuilder:_buildOpen()
	if self._hasSuffixHint then
		local nGuardFn = self._stack:newOpenFunction(self._node, self._lexShot)
		local nMakerStack = nGuardFn:newStack(self._node, self._stack)
		local nSetted = false
		local nGenParam, nSuffixHint, nGenFunc = self._parRetMaker(nMakerStack, {}, false)
		local ok, err = pcall(nSuffixHint.caller, {
			extends=function(vHint, _)
				error("extends can only be used with function:class")
				return vHint
			end,
			implements=function(vHint, _)
				error("impl can only be used with function:class")
				return vHint
			end,
			RetDots=function(vHint, vFirst, ...)
				error("open function can't take RetDots")
				return vHint
			end,
			Ret=function(vHint, ...)
				error("open function can't take Ret")
				return vHint
			end,
			Err=function(vHint, _)
				error("open function can't take Err")
				return vHint
			end,
			isguard=function(vHint, vType)
				assert(not nSetted, "isguard can only use once here")
				nGuardFn:lateInitFromGuard(vType)
				return vHint
			end,
		})
		if not ok then
			error(Exception.new(tostring(err), self._node))
		end
		return nGuardFn
	else
		return self._stack:newOpenFunction(self._node, self._lexShot):lateInitFromBuilder(self._polyParNum, function(vOpenFn, vContext, vPolyArgs, vTermTuple)
			local nGenParam, nSuffixHint, nGenFunc = self._parRetMaker(vContext, vPolyArgs, false)
			nGenParam(vTermTuple)
			return nGenFunc()
		end)
	end
end

function FunctionBuilder:_buildClass() 
	local nNode = self._node
	assert(nNode.tag == "Function")
	local nPrefixHint = self._prefixHint
	local nReferOrNil = nil
	local ok, err = pcall(nPrefixHint.caller, {
		class=function(vHint, vRefer)
			assert(vRefer and Reference.is(vRefer), "impl's first arg must be a Reference")
			nReferOrNil = vRefer
			return vHint
		end,
	})
	if not ok then
		error(Exception.new(tostring(err), self._node))
	end
	local nRefer = assert(nReferOrNil, "reference not setted when function:class")
	local nPolyParNum = self._polyParNum
	local nFnMaker = function(vPolyParList)
		local nInterfaceGetter = function(vSuffixHint)  
			local nImplementsArg = nil
			local nExtendsArg = nil
			local nErrType = nil
			local ok, err = pcall(vSuffixHint.caller, {
				implements=function(vHint, vInterface)
					nImplementsArg = vInterface
					return vHint
				end,
				extends=function(vHint, vBaseClass)
					nExtendsArg = vBaseClass
					return vHint
				end,
				Ret=function(vHint, ...)
					error("class function can't take Ret")
					return vHint
				end,
				RetDots=function(vHint, vFirst, ...)
					error("class function can't take RetDots")
					return vHint
				end,
				Err=function(vHint, vErrType)
					nErrType = vErrType
					return vHint
				end,
				isguard=function(vHint, vType)
					return vHint
				end,
			})
			if not ok then
				error(Exception.new(tostring(err), self._node))
			end
			local nExtendsTable = false
			if nExtendsArg then
				local nType = nExtendsArg:checkAtomUnion()
				if nType:isUnion() then
					error("base class can't be union")
				end
				if ClassTable.is(nType) then
					nExtendsTable = nType
				else
					if nType == self._manager.type.False or nType == self._manager.type.Nil then
						       
					else
						error("base class type must be ClassTable")
					end
				end
			end
			local nImplementsInterface = nExtendsTable and nExtendsTable:getInterface() or self._manager.type.AnyObject
			if nImplementsArg then
				local nType = nImplementsArg:checkAtomUnion()
				if nType:isUnion() then
					error("interface can't be union")
				end
				if Interface.is(nType) then
					nImplementsInterface = nType
				else
					if nType == self._manager.type.False or nType == self._manager.type.Nil then
						      
					else
						error("interface type must be TypedObject")
					end
				end
			end
			return nExtendsTable, nImplementsInterface, nErrType
		end
		local nFactory = self._stack:newClassFactory(nNode, self._lexShot)
		local nClassTable = nFactory:getClassTable()
		local nNewStack = nFactory:getBuildStack()
		local nGenParam = nil
		local nGenFunc = nil
		local nErrType = nil
		nClassTable:initAsync(function()
			local nGenParam_, nSuffixHint, nGenFunc_ = self._parRetMaker(nNewStack, vPolyParList, false)
			nGenParam = nGenParam_
			nGenFunc = nGenFunc_
			local nExtends, nImplements, nErrType_ = nInterfaceGetter(nSuffixHint)
			nErrType = nErrType_
			return nExtends, nImplements
		end)
		nFactory:initAsync(function()
			nClassTable:waitInit()
			local nParTermTuple = nGenParam(false)
			local nParTuple = nParTermTuple:checkTypeTuple()
			local nRetTuples = self._manager:SingleRetTuples(self._node, self._manager:TypeTuple(self._node, nClassTable), nErrType)
			return nParTuple, nRetTuples, function()
				nNewStack:setClassTable(nClassTable)
				nGenFunc()
				local nParTuple = nParTuple or nParTermTuple:checkTypeTuple(true)
				if not nParTuple then
					nNewStack:error("auto parameter deduce failed")
					error("auto parameter deduce failed")
				end
				nClassTable:onBuildFinish()
				return nParTuple, nRetTuples
			end
		end)
		return nFactory
	end
	if nPolyParNum <= 0 then
		local nFactory = nFnMaker({})
		nRefer:setAssignAsync(self._node, function()
			return nFactory:getClassTable(true)
		end)
		self._stack:getSealStack():scheduleSealType(nFactory)
		return nFactory
	else
		local nPolyFn = self._manager:PolyFunction(self._node, function(...)
			return nFnMaker({...})
		end, nPolyParNum, self._stack)
		nRefer:setTemplateAsync(self._node, function(...)
			local nFactory = nPolyFn:noCtxCastPoly({...})
			assert(ClassFactory.is(nFactory), "class factory's poly must return factory type")
			return nFactory:getClassTable(true)
		end, nPolyParNum)
		return nPolyFn
	end
end

function FunctionBuilder:build()
	local nAttrSet = self._prefixHint.attrSet
	if nAttrSet.open then
		return self:_buildOpen()
	elseif nAttrSet.class then
		if self._member then
			error(Exception.new("class factory can't be member-function-like", self._node))
		end
		return self:_buildClass()
	else
		return self:_buildInnerFn()
	end
end

return FunctionBuilder

end end
--thlua.builder.FunctionBuilder end ==========)

--thlua.builder.TableBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.builder.TableBuilder'] = function (...)

local OpenTable = require "thlua.object.OpenTable"
local AutoTable = require "thlua.object.AutoTable"
local RefineTerm = require "thlua.term.RefineTerm"
local Exception = require "thlua.Exception"
local TableBuilder = {}

  


	   
		
		
	
	    


TableBuilder.__index=TableBuilder

function TableBuilder.new(vStack,
	vNode,
	vHintInfo,
	vPairMaker
)
	return setmetatable({
		_stack=vStack,
		_node=vNode,
		_hintInfo=vHintInfo,
		_pairMaker=vPairMaker,
		_selfInitDict=false  ,
	}, TableBuilder)
end

function TableBuilder._makeLongHint(self)
	return {
		Init=function(vLongHint, vInitDict )
			self._selfInitDict = vInitDict
			return vLongHint
		end,
	}
end

function TableBuilder:_build(vNewTable )
	      
	local nStack = self._stack
	local nManager = nStack:getTypeManager()
	local vList, vDotsStart, vDotsTuple = self._pairMaker()
	local nTermDict  = {}
	local nTypePairList   = {}
	for i, nPair in ipairs(vList) do
		local nKey = nPair[1]:getType()
		local nTerm = nPair[2]
		local nValue = nTerm:getType()
		if nKey:isUnion() or not nKey:isSingleton() then
			nValue = nManager:checkedUnion(nValue, nManager.type.Nil)
			if OpenTable.is(vNewTable) then
				self._stack:getRuntime():nodeError(self._node, "open table can only take singleton type as key")
			end
		else
			nTermDict[nKey] = nPair[2]
		end
		nTypePairList[i] = {nKey, nValue}
	end
	if vDotsTuple then
		local nTypeTuple = vDotsTuple:checkTypeTuple()
		local nRepeatType = nTypeTuple:getRepeatType()
		if nRepeatType then
			nTypePairList[#nTypePairList + 1] = {
				nManager.type.Integer, nManager:checkedUnion(nRepeatType, nManager.type.Nil)
			}
			if OpenTable.is(vNewTable) then
				self._stack:getRuntime():nodeError(self._node, "open table can only take singleton type as key")
			end
		else
			for i=1, #nTypeTuple do
				local nKey = nManager:Literal(vDotsStart + i - 1)
				local nTerm = assert(vDotsTuple:rawget(i))
				nTypePairList[#nTypePairList + 1] = {
					nKey, nTerm:getType()
				}
				nTermDict[nKey] = nTerm
			end
		end
	end
	local nSelfInitDict = self._selfInitDict
	if nSelfInitDict then
		for nKey, nValue in pairs(nSelfInitDict) do
			nKey:checkAtomUnion():foreach(function(vSubKey)
				nTypePairList[#nTypePairList + 1] = {
					vSubKey, nManager:checkedUnion(nValue, nManager.type.Nil)
				}
			end)
		end
	end
	if OpenTable.is(vNewTable) then
		local nCollection = nManager:TypeCollection()
		for k,v in pairs(nTermDict) do
			nCollection:put(k)
		end
		vNewTable:initByKeyValueTerm(self._node, self._stack:topBranch(), nCollection:mergeToAtomUnion(), nTermDict)
	else
		local nKeyUnion, nTypeDict = nManager:typeMapReduce(nTypePairList, function(vList)
			return nManager:unionReduceType(vList)
		end)
		vNewTable:initByKeyValue(self._node, nKeyUnion, nTypeDict)
	end
end

function TableBuilder:build()
	local nLongHint = self:_makeLongHint()
	local ok, err = pcall(self._hintInfo.caller, nLongHint)
	if not ok then
		error(Exception.new(tostring(err), self._node))
	end
	local nStack = self._stack
	local nManager = nStack:getTypeManager()
	local nAttrSet = self._hintInfo.attrSet
	if nAttrSet.class then
		local nNewTable = assert(nStack:getClassTable(), "only function:class(clazz.) can build table hint with {.class")
		self:_build(nNewTable)
		return nNewTable
	else
		if nAttrSet.open then
			if self._selfInitDict then
				self._selfInitDict = false
				self._stack:getRuntime():nodeError(self._node, "open table can't use Init()")
			end
			local nNewTable = OpenTable.new(nManager, self._node, self._stack)
			self:_build(nNewTable)
			return nNewTable
		else
			local nNewTable = AutoTable.new(nManager, self._node, self._stack)
			self:_build(nNewTable)
			return nNewTable
		end
	end
end

return TableBuilder

end end
--thlua.builder.TableBuilder end ==========)

--thlua.class begin ==========(
do local _ENV = _ENV
packages['thlua.class'] = function (...)
local class2meta={}
local meta2class={}


	  
	  


local META_FIELD = {
	__call=1,
	__tostring=1,
	__len=1,
	__bor=1,
	__band=1,
	    
}

local function class (super)
	local class_type={}
	  
	class_type.ctor=false
	class_type.super=super
	class_type.new=function (...)  
			local obj={}
			do
				local function create(c,...)
					if c.super then
						create(c.super,...)
					end
					if c.ctor then
						c.ctor(obj,...)
					end
				end

				create(class_type,...)
			end
			setmetatable(obj, class_type.meta)
			return obj
		end
	local vtbl={}
	local meta={
		__index=vtbl
	}
	class_type.isDict = (setmetatable({}, {
		__index=function(type2is , if_type)
			local cur_type = class_type
			while cur_type do
				if cur_type == if_type then
					type2is[if_type] = true
					return true
				else
					cur_type = cur_type.super
				end
			end
			type2is[if_type] = false
			return false
		end
	}) )  
	class_type.is=function(v)
		local nClassType = meta2class[getmetatable(v) or 1]
		local nIsDict = nClassType and nClassType.isDict
		return nIsDict and nIsDict[class_type] or false
	end
	class_type.meta=meta
	class2meta[class_type]=meta
	meta2class[meta]=class_type

	setmetatable(class_type,{__newindex=
		function(t,k,v)
			if META_FIELD[k] then
				meta[k] = v
			else
				vtbl[k]=v
			end
		end
	})

	if super then
		local super_meta = class2meta[super]
		for k,v in pairs(super_meta.__index) do
			vtbl[k] = v
		end
		for k,v in pairs(super_meta) do
			if k ~= "__index" then
				meta[k] = v
			end
		end
	end

	return class_type
end

return class

end end
--thlua.class end ==========)

--thlua.code.CodeEnv begin ==========(
do local _ENV = _ENV
packages['thlua.code.CodeEnv'] = function (...)

local ParseEnv = require "thlua.code.ParseEnv"
local Node = require "thlua.code.Node"
local Exception = require "thlua.Exception"
local VisitorExtend = require "thlua.code.VisitorExtend"
local SymbolVisitor = require "thlua.code.SymbolVisitor"
local SearchVisitor = require "thlua.code.SearchVisitor"
local HintGener = require "thlua.code.HintGener"
local SplitCode = require "thlua.code.SplitCode"
local class = require "thlua.class"


	  
	  
	    
	   
	   
		  
		  
		 
	


local CodeEnv = {}
CodeEnv.__index=CodeEnv

function CodeEnv.new(vCode , vChunkName, vChunkWithInject)
	local nSplitCode = SplitCode.is(vCode) and vCode or SplitCode.new(vCode)
	local self = setmetatable({
		_code = nSplitCode,
		_chunkName = vChunkName,
		_searcher = SearchVisitor.new(nSplitCode),
		_nodeList = {},
		_typingCode = "--[[no gen code ]]",
		_astTree = nil,
		_parseEnv = nil,
		_typingFn = nil,
	}, CodeEnv)
	if not vChunkWithInject then
		local nAst, nErr = ParseEnv.parse(nSplitCode:getContent())
		if not nAst then
			self:_prepareNode(nErr, false)
			error(Exception.new(nErr[1], nErr))
		end
		self._astTree = nAst
		self._parseEnv = nErr
	else
		self._astTree = vChunkWithInject
	end
	self._typingFn = (self:_buildTypingFn() ) 
	return self
end

function CodeEnv:_prepareNode(vNode, vParent)
	local nNodeList = self._nodeList
	local nIndex = #nNodeList + 1
	nNodeList[nIndex] = vNode
	vNode.index = nIndex
	vNode.parent = vParent or nil
	vNode.path = self._chunkName
	vNode.l, vNode.c = self._code:fixupPos(vNode.pos, vNode)
	Node.bind(vNode)
end

function CodeEnv:_prepare()
	local nAst = self._astTree
	assert(#self._nodeList == 0, "node list has been setted")
	      
	local nStack = {}
	local nVisitor = VisitorExtend(function(visitor, vNode)
		  
		self:_prepareNode(vNode, nStack[#nStack] or false)
		   
		nStack[#nStack + 1] = vNode
		visitor:rawVisit(vNode)
		nStack[#nStack] = nil
	end)
	nVisitor:realVisit(nAst)
	   
	self._searcher:realVisit(nAst)
	   
	local nSymbolVisitor = SymbolVisitor.new(self._code)
	nSymbolVisitor:realVisit(nAst)
	   
	local gener = HintGener.new(self._astTree)
	local nTypingCode = gener:genCode()
	self._typingCode = nTypingCode
end

function CodeEnv:_buildTypingFn()
	self:_prepare()
	local nFunc, nInfo = load(self._typingCode, self._chunkName, "t", setmetatable({}, {
		__index=function(t,k)
			    
			error("indexing global is fatal error, name="..k)
		end
	}))
	if not nFunc then
		error(Exception.new(tostring(nInfo), self._astTree))
	end
	assert(type(nFunc) == "function", Exception.new("typing code must return function", self._astTree))
	if not nFunc then
		    
		error(Exception.new(tostring(nInfo), self._astTree))
	end
	return nFunc
end

function CodeEnv:getNodeList()
	return self._nodeList
end

function CodeEnv:getAstTree()
	return self._astTree
end

function CodeEnv:getTypingCode()
	return self._typingCode
end

function CodeEnv:getTypingFn()
	return self._typingFn
end

function CodeEnv:makeFocusList(vNode)
	local nCurNode = vNode
	local nFocusList = {}
	while nCurNode do
		if nCurNode.tag == "Function" then
			local nFunc = nCurNode  
			if nFunc.letNode then
				nFocusList[#nFocusList + 1] = nFunc
			end
		end
		nCurNode = nCurNode.parent
	end
	return nFocusList
end

function CodeEnv:traceBlockRegion(vTraceList) 
	local nRetBlock = self._astTree[3]
	for i=1,#vTraceList-1 do
		local nTrace = vTraceList[i]
		local nNextBlock = nRetBlock.subBlockList[nTrace]
		if not nNextBlock then
			break
		else
			nRetBlock = nNextBlock
		end
	end
	return nRetBlock, self:makeFocusList(nRetBlock)
end

function CodeEnv:searchHintExprBySuffix(vPos)  
	local nPair = self._searcher:searchHintSuffixPair(vPos)
	if not nPair then
		return false
	end
	local nRetBlock = nil
	local nPrefixNode = nPair[1]
	    
	local nCurNode = nPrefixNode
	local nInHint = true
	while nCurNode do
		if nCurNode.tag == "HintSpace" then
			nInHint = false
		elseif nCurNode.tag == "Block" then
			if not nInHint then
				nRetBlock = nCurNode  
				break
			end
		end
		nCurNode = nCurNode.parent
	end
	if not nRetBlock then
		return false
	end
	return nPrefixNode, nRetBlock, self:makeFocusList(nPrefixNode)
end

function CodeEnv:searchExprBySuffix(vPos) 
	local nPair = self._searcher:searchSuffixPair(vPos)
	if not nPair then
		return false
	end
	local nPrefixNode = nPair[1]
	return nPrefixNode, self:makeFocusList(nPrefixNode)
end

function CodeEnv:searchIdent(vPos)
	return self._searcher:searchIdent(vPos)
end

function CodeEnv:getChunkName()
	return self._chunkName
end

function CodeEnv:getSplitCode()
	return self._code
end

function CodeEnv.is(v)
	return getmetatable(v) == CodeEnv
end

function CodeEnv.genInjectFnByError(vSplitCode, vFileUri, vWrongContent) 
	local nRightAst, nErrNode = ParseEnv.parse(vWrongContent)
	if nRightAst then
		return false
	end
	local nInjectTrace = nErrNode[2]
	if not nInjectTrace then
		return false
	end
	local nChunk = nInjectTrace.capture
	local nOkay, nInjectFn = pcall(function()
		assert(nChunk.injectNode)
		local nFocusEnv = CodeEnv.new(vSplitCode, vFileUri, nChunk)
		
			    
		
		local nRawInjectFn = (nFocusEnv:getTypingFn() ) 
		return function(vStack, vGetter)
			return nRawInjectFn(nFocusEnv:getNodeList(), vStack, vGetter)
		end
	end)
	if nOkay then
		return nInjectFn, nInjectTrace
	else
		return false
	end
end

function CodeEnv:genLuaCode()
	return self._parseEnv:genLuaCode()
end

return CodeEnv

end end
--thlua.code.CodeEnv end ==========)

--thlua.code.HintGener begin ==========(
do local _ENV = _ENV
packages['thlua.code.HintGener'] = function (...)



  
  

   
	             
	  
 
	


   

  
	   
	  
		   
	
	 




local TagToVisiting = {
	Chunk=function(self, node)
		local nInjectNode = node.injectNode
		if not nInjectNode then
			return {
				'local ____nodes,____stk,____globalTerm=... ',
				self:visitIdentDef(node[1], "____globalTerm"),
				" return ", self:stkWrap(node).CHUNK_TYPE(self:visitFunc(node))
			}
		else
			if nInjectNode.tag ~= "HintSpace" then
				return {
					'local ____nodes,____stk,____injectGetter=... ',
					"local let, _ENV = ____stk:INJECT_BEGIN() ",
					" return ", self:visit(nInjectNode),
				}
			else
				return {
					'local ____nodes,____stk,____injectGetter=... ',
					"local let, _ENV = ____stk:INJECT_BEGIN() ",
					" return ", self:fixIHintSpace(nInjectNode),
				}
			end
		end
	end,
	HintTerm=function(self, node)
		return self:stkWrap(node).HINT_TERM(self:fixIHintSpace(node[1]))
	end,
	Block=function(self, node)
		return self:concatList(node, function(i, vStatNode)
			return self:visit(vStatNode)
		end, " ")
		    
		   
		   
		   
		     
			   
				    
			
				    
			
			    
				  
			
		
		    
		
			 
				  
						 
				  
				
					  
							 
					  
				
			
		
	end,
	Do=function(self, node)
		return self:rgnWrap(node).DO(
			self:visitLongHint(node.hintLong),
			self:fnWrap()(self:visit(node[1]))
		)
	end,
	Set=function(self, node)
		return {
			" local ", self:concatList(node[1], function(i,v)
				return "____set_a"..i
			end, ","),
			"=", self:stkWrap(node).EXPRLIST_UNPACK(tostring(#node[1]), self:visit(node[2])),
			self:concatList(node[1], function(i, vVarNode)
				if vVarNode.tag == "Ident" then
					local nDefineIdent = vVarNode.defineIdent
					if nDefineIdent then
						return self:stkWrap(vVarNode).SYMBOL_SET(
							self:codeNode(nDefineIdent),
							"____set_a"..i
						)
					else
						local nIdentENV = vVarNode.isGetFrom
						if self._chunk.injectNode and nIdentENV == self._chunk[1] then
							     
							return ""
						else
							return self:stkWrap(vVarNode).GLOBAL_SET(
								self:codeNode(nIdentENV  ),
								"____set_a"..i
							)
						end
					end
				else
					return self:stkWrap(node).META_SET(
						self:visit(vVarNode[1]),
						self:visit(vVarNode[2]),
						"____set_a"..i
					)
				end
			end, " ")
		}
	end,
	While=function(self, node)
		return self:rgnWrap(node).WHILE(
			self:visit(node[1]),
			self:fnWrap()(self:visit(node[2]))
		)
	end,
	Repeat=function(self, node)
		return self:rgnWrap(node).REPEAT(
			self:fnWrap()(self:visit(node[1])),
			self:visit(node[2])
		)
	end,
	If=function(self, node)
		local function put(exprNode, blockNode, nextIndex, level)
			local nNext1Node, nNext2Node = node[nextIndex], node[nextIndex + 1]
			if nNext1Node then
				if nNext2Node then
					assert(nNext1Node.tag ~= "Block" and nNext2Node.tag == "Block", "if statement error")
					return self:rgnWrap(node).IF_TWO(
						self:visit(exprNode),
						self:fnWrap()(self:visit(blockNode)), self:codeNode(blockNode),
						self:fnWrap()(put(nNext1Node, nNext2Node, nextIndex + 2, level + 1))
					)
				else
					assert(nNext1Node.tag == "Block")
					return self:rgnWrap(node).IF_TWO(
						self:visit(exprNode),
						self:fnWrap()(self:visit(blockNode)), self:codeNode(blockNode),
						self:fnWrap()(self:visit(nNext1Node)), self:codeNode(nNext1Node)
					)
				end
			else
				return self:rgnWrap(node).IF_ONE(
					self:visit(exprNode),
					self:fnWrap()(self:visit(blockNode)), self:codeNode(blockNode)
				)
			end
		end
		local nExpr, nBlock = node[1], node[2]
		assert(nExpr.tag ~= "Block" and nBlock.tag == "Block", "if statement error")
		return put(nExpr, nBlock, 3, 1)
	end,
	Fornum=function(self, node)
		local nHasStep = node[5] and true or false
		local nBlockNode = node[5] or node[4]
		assert(nBlockNode.tag == "Block", "4th or 5th node must be block")
		return self:rgnWrap(node).FOR_NUM(
			self:visit(node[2]), self:visit(node[3]), nHasStep and self:visit(node[4]) or "nil",
			self:fnWrap("____fornum")(
				self:visitIdentDef(node[1], "____fornum"),
				self:visit(nBlockNode)
			),
			self:codeNode(nBlockNode)
		)
	end,
	Forin=function(self, node)
		return {
			"local ____n_t_i=", self:stkWrap(node).EXPRLIST_REPACK("false", self:listWrap(self:visit(node[2]))),
			self:rgnWrap(node).FOR_IN(self:fnWrap("____iterTuple")(
				"local ", self:concatList(node[1], function(i, vNode)
					return "____forin"..i
				end, ","),
				"=", self:stkWrap(node).EXPRLIST_UNPACK(tostring(#node[1]), "____iterTuple"),
				self:concatList(node[1], function(i, vIdent)
					return self:visitIdentDef(vIdent, "____forin"..i)
				end, " "),
				self:visit(node[3])
			), "____n_t_i")
		}
	end,
	Local=function(self, node)
		return {
			line=node.l,
			"local ", self:concatList(node[1], function(i, vNode)
				return "____lo"..i
			end, ","), "=",
			#node[2] > 0
				and self:stkWrap(node).EXPRLIST_UNPACK(tostring(#node[1]), self:visit(node[2]))
				or self:concatList(node[1], function(i, vNode)
					  
					return "nil"
				end, ", "),
			self:concatList(node[1], function(i, vIdent)
				return self:visitIdentDef(vIdent, "____lo"..i)
			end, " ")
		}
	end,
	Localrec=function(self, node)
		  
		return self:visitIdentDef(node[1], self:visit(node[2]), true)
	end,
	Goto=function(self, node)
		  
		return {}
	end,
	Label=function(self, node)
		  
		return {}
	end,
	Return=function(self, node)
		return self:rgnWrap(node).RETURN(
			self:stkWrap(node).EXPRLIST_REPACK(
				"false",
				self:listWrap(self:visit(node[1]))
			)
		)
	end,
	Break=function(self, node)
		return self:rgnWrap(node).BREAK()
	end,
	Call=function(self, node)
		return self:stkAutoUnpack(node,
			self:stkWrap(node).META_CALL(
				self:visit(node[1]),
				self:stkWrap(node).EXPRLIST_REPACK(
					"true",
					self:listWrap(#node[2] > 0 and self:visit(node[2]) or "")
				)
			)
		)
	end,
	Invoke=function(self, node)
		local nHintPolyArgs = node.hintPolyArgs
		return self:stkAutoUnpack(node,
			self:stkWrap(node).META_INVOKE(
				self:visit(node[1]),
				"\""..node[2][1].."\"",
				self:listWrap(nHintPolyArgs and self:fixIHintSpace(nHintPolyArgs) or ""),
				self:stkWrap(node).EXPRLIST_REPACK(
					"false",
					self:listWrap(#node[3] > 0 and self:visit(node[3]) or "")
				)
			)
		)
	end,
	HintSpace=function(self, node)
		if node.kind == "StatHintSpace" then
			         
			return {
				line = node.l,
				" local ____hintStat=function() ",
				self:fixIHintSpace(node),
				" end ____hintStat() "
			}
		else
			error("visit long space or short space in other function")
			return {}
		end
	end,
	Dots=function(self, node)
		return self:stkAutoUnpack(node, "____vDOTS")
	end,
	Nil=function(self, node)
		return self:stkWrap(node).NIL_TERM()
	end,
	True=function(self, node)
		return self:stkWrap(node).LITERAL_TERM("true")
	end,
	False=function(self, node)
		return self:stkWrap(node).LITERAL_TERM("false")
	end,
	Number=function(self, node)
		return self:stkWrap(node).LITERAL_TERM(self:codeNodeValue(node))
	end,
	String=function(self, node)
		return self:stkWrap(node).LITERAL_TERM(self:codeNodeValue(node))
	end,
	Function=function(self, node)
		return self:visitFunc(node)
	end,
	Table=function(self, node)
		local count = 0
		local i2i  = {}
		local tailDots = nil
		for i, nItem in ipairs(node) do
			if nItem.tag ~= "Pair" then
				count = count + 1
				i2i[i] = count
				local nExprTag = nItem.tag
				if i==#node and (nExprTag == "Dots" or nExprTag == "Invoke" or nExprTag == "Call") then
					tailDots = nItem
				end
			end
		end
		return self:stkWrap(node).TABLE_NEW(
			self:visitLongHint(node.hintLong),
			self:fnRetWrap(self:listWrap(self:concatList (node, function(i, vTableItem)
				if vTableItem.tag ~= "Pair" then
					if i==#node and tailDots then
						return "nil"
					else
						return self:listWrap(
							self:stkWrap(vTableItem).LITERAL_TERM(tostring(i2i[i])),
							self:visit(vTableItem)
						)
					end
				else
					return self:listWrap(self:visit(vTableItem[1]), self:visit(vTableItem[2]))
				end
			end, ",")), tostring(count), tailDots and self:visit(tailDots) or "nil")
		)
	end,
	Op=function(self, node)
		local nLogicOpSet  = {["or"]=1,["not"]=1,["and"]=1}
		local nOper = node[1]
		if nLogicOpSet[nOper] then
			if nOper == "not" then
				return self:rgnWrap(node).LOGIC_NOT(
					self:visit(node[2])
				)
			elseif nOper == "or" then
				return self:rgnWrap(node).LOGIC_OR(
					self:visit(node[2]), self:fnRetWrap(self:visit(node[3]))
				)
			elseif nOper == "and" then
				return self:rgnWrap(node).LOGIC_AND(
					self:visit(node[2]), self:fnRetWrap(self:visit(node[3]))
				)
			else
				error("invalid case branch")
			end
		else
			local nRight = node[3]
			if not nRight then
				return self:stkWrap(node).META_UOP(
					"\""..node[1].."\"",
					self:visit(node[2])
				)
			elseif node[1] == "==" then
				return self:stkWrap(node).META_EQ_NE(
					"true",
					self:visit(node[2]),
					self:visit(nRight)
				)
			elseif node[1] == "~=" then
				return self:stkWrap(node).META_EQ_NE(
					"false",
					self:visit(node[2]),
					self:visit(nRight)
				)
			else
				return self:stkWrap(node).META_BOP_SOME(
					"\""..node[1].."\"",
					self:visit(node[2]),
					self:visit(nRight)
				)
			end
		end
	end,
	HintAt=function(self, node)
		local nHintShort = node.hintShort
		return self:stkWrap(node).CAST_HINT(
			{"(", self:visit(node[1]), ")"},
			string.format("%q", nHintShort.castKind),
			self:fixIHintSpace(nHintShort)
		)
	end,
	Paren=function(self, node)
		return self:visit(node[1])
	end,
	Ident=function(self, node)
		assert(node.kind ~= "def")
		local nDefineIdent = node.defineIdent
		if nDefineIdent then
			local symbol = self:codeNode(nDefineIdent)
			local nParent = node.parent
			while nParent.tag == "Paren" do
				nParent = nParent.parent
			end
			local nParentTag = nParent.tag
			local nParentParentTag = nParent.parent.tag
			if nParentTag == "ExprList" then
				local nSymbolGet = self:stkWrap(node).SYMBOL_GET(symbol, "true")
				if nParentParentTag == "Invoke" or nParentParentTag == "Call" then
					  
					return self:fnRetWrap(nSymbolGet)
				else
					return nSymbolGet
				end
			else
				return self:stkWrap(node).SYMBOL_GET(symbol, "false")
			end
		else
			local nIdentENV = node.isGetFrom
			if self._chunk.injectNode and nIdentENV == self._chunk[1] then
				return self:stkWrap(node).INJECT_GET(
					"____injectGetter"
				)
			else
				return self:stkWrap(node).GLOBAL_GET(
					self:codeNode(nIdentENV  )
				)
			end
		end
	end,
	Index=function(self, node)
		return self:stkWrap(node).META_GET(
			self:visit(node[1]), self:visit(node[2]),
			tostring(node.notnil or false)
		)
	end,
	ExprList=function(self, node)
		return self:concatList(node, function(i, expr)
			return self:visit(expr)
		end, ",")
	end,
	ParList=function(self, node)
		error("implement in other way")
		return self:concatList (node, function(i, vParNode)
			return vParNode.tag == "Ident" and "____v_"..vParNode[1]..vParNode.index or "____vDOTS"
		end, ",")
	end,
	VarList=function(self, node)
		return self:concatList(node, function(i, varNode)
			return self:visit(varNode)
		end, ",")
	end,
	IdentList=function(self, node)
		return self:concatList(node, function(i, identNode)
			return self:visit(identNode)
		end, ",")
	end,
}

local HintGener = {}
HintGener.__index = HintGener

function HintGener:visit(vNode)
	local nUnionNode = vNode
	local nFunc = TagToVisiting[nUnionNode.tag]
	if nFunc then
		return nFunc(self, nUnionNode)
	else
		return ""
	end
end

function HintGener:fixIHintSpace(vHintSpace)
	local nResult = {}
	for k,v in ipairs(vHintSpace.evalScriptList) do
		if v.tag == "HintScript" then
			local nLast = nil
			for s in string.gmatch(v[1], "[^\n]*") do
				nLast = {
					line = true,
					" ", s, " "
				}
				nResult[#nResult + 1] = nLast
			end
			if nLast then
				nLast.line = nil
			end
		else
			nResult[#nResult + 1] = self:stkWrap(v).EVAL(self:visit(v[1]))
			nResult[#nResult + 1] = {
				line=v.endLine, " "
			}
		end
	end
	return nResult
end

function HintGener:codeNodeValue(vNode )
	return "____nodes["..vNode.index.."][1]"
end

function HintGener:codeNode(vNode)
	return "____nodes["..vNode.index.."]"
end

function HintGener:visitIdentDef(vIdentNode, vValue, vIsParamOrRec)
	local nHintShort = vIdentNode.hintShort
	return {
		line=vIdentNode.l,
		" ", self:stkWrap(vIdentNode).SYMBOL_NEW(
			string.format("%q", vIdentNode.symbolKind), tostring(vIdentNode.symbolModify or false),
			vValue, vIsParamOrRec and "nil" or (nHintShort and self:fixIHintSpace(nHintShort) or "nil")
		)
	}
end

function HintGener:fnWrap(...)
	local nArgsString = table.concat({...}, ",")
	return function(...)
		local nList = {...}
		local nResult = { " function(", nArgsString, ") " }
		for i=1, #nList do
			nResult[#nResult+1] = nList[i]
			nResult[#nResult+1] = " "
		end
		nResult[#nResult+1] = " end "
		return nResult
	end
end

function HintGener:fnRetWrap(...)
	local nList = {...}
	local nResult = { " function() return " }
	for i=1, #nList do
		nResult[#nResult+1] = nList[i]
		if i~=#nList then
			nResult[#nResult+1] = ","
		end
	end
	nResult[#nResult+1] = " end "
	return nResult
end

function HintGener:dictWrap(vDict )
	local nList = {}
	nList[#nList + 1] = "{"
	for k,v in pairs(vDict) do
		nList[#nList + 1] = k
		nList[#nList + 1] = "="
		nList[#nList + 1] = v
		nList[#nList + 1] = ","
	end
	nList[#nList + 1] = "}"
	return nList
end

function HintGener:listWrap(...)
	local nList = {...}
	local nResult = { "{" }
	for i=1, #nList do
		nResult[#nResult+1] = nList[i]
		if i~=#nList then
			nResult[#nResult+1] = ","
		end
	end
	nResult[#nResult+1] = "}"
	return nResult
end


	  
		    

		
		
		
		
		
		

		
		

		
		
		

		
		
		
		

		
		
		

		
		
		

		
		
	

function HintGener:stkWrap(vNode) 
	return setmetatable({}, {
		__index=function(t,vName)
			return function(...)
				return self:prefixInvoke("____stk", vName, vNode, ...)
			end
		end,
	})
end


	  
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	

function HintGener:rgnWrap(vNode) 
	return setmetatable({}, {
		__index=function(t,vName)
			return function(...)
				return self:prefixInvoke("____stk", vName, vNode, ...)
			end
		end,
	})
end

function HintGener:prefixInvoke(vPrefix, vName, vNode, ...)
	local nList = {...}
	local nResult = {
		line=vNode.l,
		vPrefix, ":", vName, "(", self:codeNode(vNode),
	}
	for i=1, #nList do
		nResult[#nResult+1] = ","
		nResult[#nResult+1] = nList[i]
	end
	nResult[#nResult+1] = ")"
	return nResult
end

function HintGener:stkAutoUnpack(vNode, vInner)
	local nParent = vNode.parent
	local nAutoUnpack = true
	if nParent.tag == "ExprList" or nParent.tag == "ParList" or nParent.tag == "Block" then
		nAutoUnpack = false
	elseif nParent.tag == "Table" then
		local nTableNode = nParent  
		if nTableNode[#nTableNode] == vNode then
			    
			nAutoUnpack = false
		end
	end
	if nAutoUnpack then
		return self:stkWrap(vNode).EXPRLIST_UNPACK("1", vInner)
	else
		return vInner
	end
end

function HintGener:chunkLongHint()
	return self:dictWrap({
		attrSet="{open=1}",
		caller="function(____longHint) return ____longHint end"
	})
end

function HintGener:visitLongHint(vHintSpace)
	local nCallGen = (vHintSpace and #vHintSpace.evalScriptList > 0) and {
		":", self:fixIHintSpace(vHintSpace)
	} or ""
	local nAttrList = vHintSpace and vHintSpace.attrList or ({}  )
	local l = {}
	for i=1, #nAttrList do
		l[#l + 1] = nAttrList[i] .. "=1"
	end
	return self:dictWrap({
		attrSet=self:listWrap(table.unpack(l)),
		caller=self:fnWrap("____longHint")("return ____longHint", nCallGen)
	})
end

function HintGener:visitFunc(vNode )
	local nIsChunk = vNode.tag == "Chunk"
	local nHintPrefix = nIsChunk and self:chunkLongHint() or self:visitLongHint(vNode.hintPrefix)
	local nHintSuffix = nIsChunk and self:chunkLongHint() or self:visitLongHint(vNode.hintSuffix)
	local nParList = nIsChunk and vNode[2] or vNode[1]
	local nBlockNode = nIsChunk and vNode[3] or vNode[2]
	local nLastNode = nParList[#nParList]
	local nLastDots = (nLastNode and nLastNode.tag == "Dots") and nLastNode
	local nParamNum = nLastDots and #nParList-1 or #nParList
	local nFirstPar = nParList[1]
	local nIsMember = nFirstPar and nFirstPar.tag == "Ident" and nFirstPar.isSelf or false
	local nPolyParList = vNode.hintPolyParList
	local nPolyUnpack = {}
	local nPolyParNum = nPolyParList and #nPolyParList or 0
	if nPolyParList and nPolyParNum > 0 then
		nPolyUnpack = {
			" local ", self:concatList(nPolyParList, function(_, vPolyPar)
				return vPolyPar
			end, ","), "=", self:concatList(nPolyParList, function(i, vPolyPar)
				return "____polyArgs["..tostring(i).."]"
			end, ",")
		}
	end
	return self:stkWrap(vNode).FUNC_NEW(self:dictWrap({
		_hasRetSome=tostring(vNode.retFlag or false),
		_hasSuffixHint=tostring((not nIsChunk and vNode.hintSuffix) and true or false),
		_polyParNum=tostring(nPolyParNum),
		_parNum=tostring(nParamNum),
		_member=tostring(nIsMember),
	}), nHintPrefix,
	   
		self:fnWrap("____newStk","____polyArgs", "____self")(
			"local ____stk,let,_ENV=____newStk,____newStk:BEGIN(____stk,", self:codeNode(nBlockNode), ") ",
			nPolyUnpack,
			   
			" local ____vDOTS=false ",
			     
			" return ", self:fnWrap("____termArgs")(
				self:concatList (nParList, function(i, vParNode)
					local nHintShort = vParNode.hintShort
					local nHintType = nHintShort and self:fixIHintSpace(nHintShort) or self:stkWrap(vParNode).AUTO()
					if vParNode.tag ~= "Dots" then
						if i == 1 then
							            
							nHintType = {
								"(____self or ", nHintType, ")"
							}
						end
						return {
							"local ____tempv"..i.."=",
							self:rgnWrap(vParNode).PARAM_UNPACK("____termArgs", tostring(i), nHintType),
							self:visitIdentDef(vParNode, "____tempv"..i, true)
						}
					else
						return {
							"____vDOTS=",
							self:rgnWrap(vParNode).PARAM_DOTS_UNPACK("____termArgs", tostring(nParamNum), nHintType)
						}
					end
				end, " "),
				nLastDots and "" or self:rgnWrap(nParList).PARAM_NODOTS_UNPACK("____termArgs", tostring(nParamNum)),
				" return ", self:rgnWrap(nParList).PARAM_PACKOUT(
					self:listWrap(self:concatList (nParList, function(i, vParNode)
						if vParNode.tag ~= "Dots" then
							return "____tempv"..i
						end
					end, ",")),
					(nLastDots) and "____vDOTS" or tostring(false)
				)
			), ",", nHintSuffix, ",",
			self:fnWrap()(
				self:visit(nBlockNode),
				" return ",
				self:rgnWrap(vNode).END()
			)
		)
	  
	)
end

function HintGener:concatList(
	vList,
	vFunc ,
	vSep
)
	local nResult = {}
	local nLen = #vList
	for i=1,nLen do
		nResult[#nResult + 1] = vFunc(i, vList[i])
		nResult[#nResult + 1] = i~=nLen and vSep or nil
	end
	return nResult
end

function HintGener.new(vChunk)
	local self = setmetatable({
		_chunk=vChunk,
	}, HintGener)
	return self
end

function HintGener:genCode()
	local nBufferList = {}
	local nLineCount = 1
	local function recurAppend(vResult, vDepth)
		if type(vResult) == "table" then
			local nLine = vResult.line
			if type(nLine) == "number" then
				while nLineCount < nLine do
					nBufferList[#nBufferList+1] = "\n"
					nLineCount = nLineCount + 1
				end
			end
			for _, v in ipairs(vResult) do
				recurAppend(v, vDepth+1)
			end
			if nLine == true then
				nBufferList[#nBufferList+1] = "\n"
				nLineCount = nLineCount + 1
			end
		else
			nBufferList[#nBufferList+1] = tostring(vResult)
		end
	end
	recurAppend(self:visit(self._chunk), 0)
	local re = table.concat(nBufferList)
	return re
end

return HintGener

end end
--thlua.code.HintGener end ==========)

--thlua.code.Node begin ==========(
do local _ENV = _ENV
packages['thlua.code.Node'] = function (...)


local Enum = require "thlua.Enum"



  

   
	
	
	
	
	
	
	
	


   
	


   

  
	  
	  
	  
	  
	  
	  
	   
	  
	  
	  
  

  
	  
	   
	  
	  
  

   
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


  
	  
	  
 

  
	  
	
	   
 

   
	
	
	   
 

  
	
	  
	   
  

  
	
	         
	  
  

  
	
	    
 

    

  
	
	
 

  
	  
	  
	  
 

  
	  
	  
	  
 

  
	  
	  
	  
 

  
	  
	  
	  
 

  
	  
	   
  

  
	  
	  
	  
	  
	   
	   
 

  
	  
	  
	  
	  
 

  
	  
	  
	  
	  
 

  
	  
	  
	  
	  
 

  
	  
	  
 

  
	  
	  
 

  
	  
	  
 

  
	  
 

   
	
	


  
	  
	  
	  
 

  
	  
	  
	  
	  
	  
 

   
	
	


  
	  
	  
	  
	  
 

     
	  
	  
	             
	
	  
 

  
	  
	  
	   
	
	
	
	
	  
	  
 

   

   
	
	
	
	
	
	
	
	
	
	
	
	
	
	


  
	  


  
	  


  
	  


  
	  
	  


  
	  
	  
	  


  
	  
	  
	  
	  
	  
	  
	  
	         
	  
	  


  
	  
	  
	   
 

  
	  
	  
	  


  
	  
	  
	  
	   


  
	  
	  


  
	  
	  


  
	  
	  
	  


  
	  
	   
 

  
	  
	  
 

  
	  
	  
 

  
	  
	  
 

   
    
	  
	    



  

    

  

   

   

   
	
	             
	
	


  
	  
	  
	  
 

   
	
 



local Node = {}



  
	
	
	
	


  
	
	
	
	
	



Node.__index=Node

function Node.__tostring(self)
	local before = self.path..":".. self.l ..(self.c > 0 and ("," .. self.c) or "")
	return before
end

function Node.newRootNode(vFileName)
	return setmetatable({tag = "Root", pos=1, posEnd=1, l=1, c=1, path=vFileName}, Node)
end

function Node.getDebugNode(vDepth)
	     
	local nInfo = debug.getinfo(vDepth)
	return setmetatable({tag = "Root", pos=1, posEnd=1, l=nInfo.currentline, c=1, path=nInfo.source}, Node)
end

function Node.bind(vRawNode)
	return setmetatable(vRawNode, Node)
end

return Node


end end
--thlua.code.Node end ==========)

--thlua.code.ParseEnv begin ==========(
do local _ENV = _ENV
packages['thlua.code.ParseEnv'] = function (...)
--[[
This module implements a parser for Lua 5.3 with LPeg,
and generates an Abstract Syntax Tree.

Some code modify from
https://github.com/andremm/typedlua and https://github.com/Alloyed/lua-lsp
]]
local lpeg = require "lpeg"
lpeg.setmaxstack(1000)
lpeg.locale(lpeg)

local ParseEnv = {}

ParseEnv.__index = ParseEnv

local Cenv = lpeg.Carg(1)
local Cpos = lpeg.Cp()
local cc = lpeg.Cc

local function throw(vErr)
	return lpeg.Cmt(Cenv, function(_, i, env)
		error(env:makeErrNode(i, "syntax error : "..vErr))
		return true
	end)
end

local vv=setmetatable({}, {
	__index=function(t,tag)
		local patt = lpeg.V(tag)
		t[tag] = patt
		return patt
	end
})

local vvA=setmetatable({
	IdentDefT=lpeg.V("IdentDefT") + throw("expect a 'Name'"),
	IdentDefN=lpeg.V("IdentDefN") + throw("expect a 'Name'"),
}, {
	__index=function(t,tag)
		local patt = lpeg.V(tag) + throw("expect a '"..tag.."'")
		t[tag] = patt
		return patt
	end
})

local function token (patt)
  return patt * vv.Skip
end

local function symb(str)
	if str=="." then
		return token(lpeg.P(".")*-lpeg.P("."))
	elseif str==":" then
		return token(lpeg.P(":")*-lpeg.P(":"))
	elseif str=="-" then
		return token(lpeg.P("-")*-lpeg.P("-"))
	elseif str == "[" then
		return token(lpeg.P("[")*-lpeg.S("=["))
	elseif str == "~" then
		return token(lpeg.P("~")*-lpeg.P("="))
	elseif str == "@" then
		return token(lpeg.P("@")*-lpeg.S("!<>?"))
	elseif str == "(" then
		return token(lpeg.P("(")*-lpeg.P("@"))
	else
		return token(lpeg.P(str))
	end
end

local function symbA(str)
  return symb(str) + throw("expect symbol '"..str.."'")
end

local function kw (str)
  return token(lpeg.P(str) * -vv.NameRest)
end

local function kwA(str)
  return kw(str) + throw("expect keyword '"..str.."'")
end

local exprF = {
	binOp=function(e1, op, e2)
		if not op then
			return e1
		else
			return {tag = "Op", pos=e1.pos, posEnd=e2.posEnd, op, e1, e2 }
		end
	end,
	suffixed=function(e1, e2)
		local e2tag = e2.tag
		assert(e2tag == "HintAt" or e2tag == "Call" or e2tag == "Invoke" or e2tag == "Index", "exprSuffixed args exception")
		e2.pos = e1.pos
		e2[1] = e1
		return e2
	end,
	hintAt=function(pos, e, hintShort, posEnd)
		return { tag = "HintAt", pos = pos, [1] = e, hintShort=hintShort, posEnd=posEnd}
	end,
	hintExpr=function(pos, e, hintShort, posEnd, env)
		if not hintShort then
			return e
		else
			local eTag = e.tag
			if eTag == "Dots" or eTag == "Call" or eTag == "Invoke" then
				env:markParenWrap(pos-1, hintShort.pos-1)
			end
			-- TODO, use other tag
			return { tag = "HintAt", pos = pos, [1] = e, hintShort = hintShort, posEnd=posEnd}
		end
	end
}

local parF = {
	identUse=function(vPos, vName, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="use"}
	end,
	identDef=function(vPos, vName, vHintShort, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="def", hintShort=vHintShort}
	end,
	identDefSelf=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "self", kind="def", isSelf=true}
	end,
	identDefENV=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "_ENV", kind="def"}
	end,
	identDefLet=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "let", kind="def"}
	end,
}


local function buildLoadChunk(vPos, vBlock)
	return {
		tag="Chunk", pos=vPos, posEnd=vBlock.posEnd,
		letNode = parF.identDefLet(vPos),
		[1]=parF.identDefENV(vPos),
		[2]={
			tag="ParList",pos=vPos,posEnd=vPos,
			[1]={
				tag="Dots",pos=vPos,posEnd=vPos
			}
		},
		[3]=vBlock,
		[4]=false
	}
end

local function buildInjectChunk(expr)
	local nChunk = buildLoadChunk(expr.pos, {
		tag="Block", pos=expr.pos, posEnd=expr.posEnd,
	})
	nChunk.injectNode = expr
	return nChunk
end

local function buildHintInjectChunk(shortHintSpace)
	local nChunk = buildLoadChunk(shortHintSpace.pos, {
		tag="Block", pos=shortHintSpace.pos, posEnd=shortHintSpace.posEnd,
	})
	nChunk.injectNode = shortHintSpace
	return nChunk
end

local tagC=setmetatable({
}, {
	__index=function(t,tag)
		local f = function(patt)
			-- TODO , make this faster : 1. rm posEnd, 2. use table not lpeg.Ct
			if patt then
				return lpeg.Ct(lpeg.Cg(Cpos, "pos") * lpeg.Cg(lpeg.Cc(tag), "tag") * patt * lpeg.Cg(Cpos, "posEnd"))
			else
				return lpeg.Ct(lpeg.Cg(Cpos, "pos") * lpeg.Cg(Cpos, "posEnd") * lpeg.Cg(lpeg.Cc(tag), "tag"))
			end
		end
		t[tag] = f
		return f
	end
})

local hintC={
	wrap=function(isStat, pattBegin, pattBody, pattEnd)
		pattBody = Cenv * pattBody / function(env, ...) return {...} end
		return Cenv *
					Cpos * pattBegin * vv.HintBegin *
					Cpos * pattBody * vv.HintEnd *
					Cpos * (pattEnd and pattEnd * Cpos or Cpos) / function(env,p1,castKind,p2,innerList,p3,p4)
			local evalList = env:captureEvalByVisit(innerList)
			env:markDel(p1, p4-1)
			local nHintSpace = env:buildIHintSpace(isStat and "StatHintSpace" or "ShortHintSpace", innerList, evalList, p1, p2, p3-1)
			nHintSpace.castKind = castKind
			return nHintSpace
		end
	end,
	long=function()
		local name = tagC.String(vvA.Name)
		local colonInvoke = name * symbA"(" * vv.ExprListOrEmpty * symbA")";
		local pattBody = (
			(symb"." * vv.HintBegin * name)*(symb"." * name)^0+
			symb":" * vv.HintBegin * colonInvoke
		) * (symb":" * colonInvoke)^0 * vv.HintEnd
		return Cenv * Cpos * pattBody * Cpos / function(env, p1, ...)
			local l = {...}
			local posEnd = l[#l]
			env:markDel(p1, posEnd-1)
			l[#l] = nil
			local middle = nil
			local nAttrList = {}
			for i, nameOrExprList in ipairs(l) do
				local nTag = nameOrExprList.tag
				if nTag == "ExprList" then
					if not middle then
						middle = i-1
					end
				else
					assert(nTag == "String")
					nAttrList[#nAttrList + 1] = nameOrExprList[1]
				end
			end
			local nEvalList = env:captureEvalByVisit(l)
			if middle then
				local nHintSpace = env:buildIHintSpace("LongHintSpace", l, nEvalList, p1, l[middle].pos, posEnd-1)
				nHintSpace.attrList = nAttrList
				return nHintSpace
			else
				local nHintSpace = {
					tag = "HintSpace",
					kind = "LongHintSpace",
					pos = p1,
					posEnd = posEnd,
					attrList = nAttrList,
					evalScriptList = {},
					table.unpack(l),
				}
				return nHintSpace
			end
		end
	end,
	char=function(char)
		return lpeg.Cmt(Cenv*Cpos*lpeg.P(char), function(_, i, env, pos)
			if not env.hinting then
				env:markDel(pos, pos)
				return true
			else
				return false
			end
		end)
	end,
}

local function chainOp (pat, kwOrSymb, op1, ...)
	local sep = kwOrSymb(op1) * lpeg.Cc(op1)
	local ops = {...}
	for _, op in pairs(ops) do
		sep = sep + kwOrSymb(op) * lpeg.Cc(op)
	end
  return lpeg.Cf(pat * lpeg.Cg(sep * pat)^0, exprF.binOp)
end

local function suffixedExprByPrimary(primaryExpr)
	local notnil = lpeg.Cg(vv.NotnilHint*vv.Skip*cc(true) + cc(false), "notnil")
	local polyArgs = lpeg.Cg(vv.AtPolyHint + cc(false), "hintPolyArgs")
	-- . index
	local index1 = tagC.Index(cc(false) * symb(".") * tagC.String(vv.Name) * notnil)
	-- [] index
	local index2 = tagC.Index(cc(false) * symb("[") * vvA.Expr * symbA("]") * notnil)
	-- invoke
	local invoke = tagC.Invoke(cc(false) * symb(":") * tagC.String(vv.Name) * polyArgs * vvA.FuncArgs)
	-- call
	local call = tagC.Call(cc(false) * vv.FuncArgs)
	-- atPoly
	local atPoly= Cpos * cc(false) * vv.AtPolyHint * Cpos / exprF.hintAt
	-- add completion case
	local succPatt = lpeg.Cf(primaryExpr * (index1 + index2 + invoke + call + atPoly)^0, exprF.suffixed);
	return lpeg.Cmt(Cpos*succPatt * Cenv * Cpos*((symb(".") + symb(":"))*cc(true) + cc(false)), function(_, _, pos, expr, env, posEnd, triggerCompletion)
		if not triggerCompletion then
			if expr.tag == "HintAt" then
				local curExpr = expr[1]
				while curExpr.tag == "HintAt" do
					curExpr = curExpr[1]
				end
				-- if poly cast is after invoke or call, then add ()
				if curExpr.tag == "Invoke" or curExpr.tag == "Call" then
					env:markParenWrap(pos-1, curExpr.posEnd-1)
				end
			end
			return true, expr
		else
			local nNode = env:makeErrNode(posEnd+1, "syntax error : expect a name")
			if not env.hinting then
				nNode[2] = {
					pos=pos,
					capture=buildInjectChunk(expr),
					script=env._subject:sub(pos, posEnd - 1),
					traceList=env.scopeTraceList
				}
			else
				local innerList = {expr}
				local evalList = env:captureEvalByVisit(innerList)
				local hintSpace = env:buildIHintSpace("ShortHintSpace", innerList, evalList, pos, pos, posEnd-1)
				nNode[2] = {
					pos=pos,
					capture=buildHintInjectChunk(hintSpace),
					script=env._subject:sub(pos, posEnd-1),
					traceList=env.scopeTraceList
				}
			end
			-- print("scope trace:", table.concat(env.scopeTraceList, ","))
			error(nNode)
			return false
		end
	end)
end

local G = lpeg.P { "TypeHintLua";
	Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n");
	TypeHintLua = vv.Shebang^-1 * vv.Chunk * (lpeg.P(-1) + throw("invalid chunk"));

  -- hint & eval begin {{{
	HintBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if not env.hinting then
			env.hinting = true
			return true
		else
			error(env:makeErrNode(i, "syntax error : hint space only allow normal lua syntax"))
			return false
		end
	end);

	HintEnd = lpeg.Cmt(Cenv, function(_, _, env)
		assert(env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = false
		return true
	end);

	EvalBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if env.hinting then
			env.hinting = false
			return true
		else
			error(env:makeErrNode(i, "syntax error : eval syntax can only be used in hint"))
			return false
		end
	end);

	EvalEnd = lpeg.Cmt(Cenv, function(_, i, env)
		assert(not env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = true
		return true
	end);

	NotnilHint = hintC.char("!");

	AtCastHint = hintC.wrap(
		false,
		symb("@") * cc("@") +
		symb("@!") * cc("@!") +
		symb("@>") * cc("@>") +
		symb("@?") * cc("@?"),
		vv.SimpleExpr) ;

	ColonHint = hintC.wrap(false, symb(":") * cc(false), vv.SimpleExpr);

	LongHint = hintC.long();

	StatHintSpace = hintC.wrap(true, symb("(@") * cc(nil),
		vv.DoStat + vv.ApplyOrAssignStat + throw("StatHintSpace need DoStat or Apply or AssignStat inside"),
	symbA(")"));

	HintTerm = suffixedExprByPrimary(
		tagC.HintTerm(hintC.wrap(false, symb("(@") * cc(false), vv.EvalExpr + vv.SuffixedExpr, symbA(")"))) +
		vv.PrimaryExpr
	);

	HintPolyParList = Cenv * Cpos * symb("@<") * vvA.Name * (symb"," * vv.Name)^0 * symbA(">") * Cpos / function(env, pos, ...)
		local l = {...}
		local posEnd = l[#l]
		l[#l] = nil
		env:markDel(pos, posEnd - 1)
		return l
	end;

	AtPolyHint = hintC.wrap(false, symb("@<") * cc("@<"),
		vvA.SimpleExpr * (symb"," * vv.SimpleExpr)^0, symbA(">"));

	EvalExpr = tagC.HintEval(symb("$") * vv.EvalBegin * (vv.HintTerm + vvA.SimpleExpr) * vv.EvalEnd);

  -- hint & eval end }}}


	-- parser
	-- Chunk = tagC.Chunk(Cpos/parF.identDefENV * tagC.ParList(tagC.Dots()) * vv.Skip * vv.Block);
	Chunk = Cpos * vv.Skip * vv.Block/buildLoadChunk;

	FuncPrefix = kw("function") * (vv.LongHint + cc(nil));
	FuncDef = vv.FuncPrefix * vv.FuncBody / function(vHint, vFuncExpr)
		vFuncExpr.hintPrefix = vHint
		return vFuncExpr
	end;

	Constructor = (function()
		local Pair = tagC.Pair(
          ((symb"[" * vvA.Expr * symbA"]") + tagC.String(vv.Name)) *
          symb"=" * vv.Expr)
		local Field = Pair + vv.Expr
		local fieldsep = symb(",") + symb(";")
		local FieldList = (Field * (fieldsep * Field)^0 * fieldsep^-1)^-1
		return tagC.Table(symb("{") * lpeg.Cg(vv.LongHint*(symb(",") + symb(";"))^-1, "hintLong")^-1 * FieldList * symbA("}"))
	end)();

	IdentUse = Cpos*vv.Name*Cpos/parF.identUse;
	IdentDefT = Cpos*vv.Name*(vv.ColonHint + cc(nil))*Cpos/parF.identDef;
	IdentDefN = Cpos*vv.Name*cc(nil)*Cpos/parF.identDef;

	LocalIdentList = tagC.IdentList(vvA.IdentDefT * (symb(",") * vv.IdentDefT)^0);
	ForinIdentList = tagC.IdentList(vvA.IdentDefN * (symb(",") * vv.IdentDefN)^0);

	ExprListOrEmpty = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0) + tagC.ExprList();

	ExprList = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0);

	FuncArgs = tagC.ExprList(symb("(") * (vv.Expr * (symb(",") * vv.Expr)^0)^-1 * symb(")") +
             vv.Constructor + vv.String);

	String = tagC.String(token(vv.LongString)*lpeg.Cg(cc(true), "isLong") + token(vv.ShortString));

	UnaryExpr = (function()
		local UnOp = kw("not")/"not" + symb("-")/"-" + symb("~")/"~" + symb("#")/"#"
		local PowExpr = vv.SimpleExpr * ((symb("^")/"^") * vv.UnaryExpr)^-1 / exprF.binOp
		return tagC.Op(UnOp * vv.UnaryExpr) + PowExpr
	end)();
	ConcatExpr = (function()
		local MulExpr = chainOp(vv.UnaryExpr, symb, "*", "//", "/", "%")
		local AddExpr = chainOp(MulExpr, symb, "+", "-")
	  return AddExpr * ((symb("..")/"..") * vv.ConcatExpr) ^-1 / exprF.binOp
	end)();
	Expr = (function()
		local ShiftExpr = chainOp(vv.ConcatExpr, symb, "<<", ">>")
		local BAndExpr = chainOp(ShiftExpr, symb, "&")
		local BXorExpr = chainOp(BAndExpr, symb, "~")
		local BOrExpr = chainOp(BXorExpr, symb, "|")
		local RelExpr = chainOp(BOrExpr, symb, "~=", "==", "<=", ">=", "<", ">")
		local AndExpr = chainOp(RelExpr, kw, "and")
		local OrExpr = chainOp(AndExpr, kw, "or")
		return OrExpr
	end)();

	SimpleExpr = Cpos * (
						vv.String +
						tagC.Number(token(vv.Number)) +
						tagC.Nil(kw"nil") +
						tagC.False(kw"false") +
						tagC.True(kw"true") +
						vv.FuncDef +
						vv.Constructor +
						vv.SuffixedExpr +
						tagC.Dots(symb"...") +
						vv.EvalExpr
					) * (vv.AtCastHint + cc(nil)) * Cpos * Cenv/ exprF.hintExpr;

	PrimaryExpr = vv.IdentUse + tagC.Paren(symb"(" * vv.Expr * symb")");

	SuffixedExpr = suffixedExprByPrimary(vv.PrimaryExpr);

	ApplyOrAssignStat = (function()
		return lpeg.Cmt(Cenv*vv.SuffixedExpr * ((symb(",") * vv.SuffixedExpr) ^ 0 * symb("=") * vv.ExprList)^-1, function(_,pos,env,first,...)
			if not ... then
				if first.tag == "Call" or first.tag == "Invoke" then
					return true, first
				else
					error(env:makeErrNode(pos, "syntax error: "..tostring(first.tag).." expression can't be a single stat"))
				end
			else
				local nVarList = {
					tag="VarList", pos=first.pos, posEnd = 0,
					first, ...
				}
				local nExprList = nVarList[#nVarList]
				nVarList[#nVarList] = nil
				nVarList.posEnd = nVarList[#nVarList].posEnd
				for _, varExpr in ipairs(nVarList) do
					if varExpr.tag ~= "Ident" and varExpr.tag ~= "Index" then
						error(env:makeErrNode(pos, "syntax error: only identify or index can be left-hand-side in assign statement"))
					end
				end
				return true, {
					tag="Set", pos=first.pos, posEnd=nExprList.posEnd,
					nVarList,nExprList
				}
			end
		end)
	end)();

	Block = tagC.Block(lpeg.Cmt(Cenv, function(_,pos,env)
		if not env.hinting then
			--local nLineNum = select(2, env._subject:sub(1, pos):gsub('\n', '\n'))
			--print(pos, nLineNum)
			local len = #env.scopeTraceList
			env.scopeTraceList[len + 1] = 0
			if len > 0 then
				env.scopeTraceList[len] = env.scopeTraceList[len] + 1
			end
		end
		return true
	end) * vv.Stat^0 * vv.RetStat^-1 * lpeg.Cmt(Cenv, function(_,_,env)
		if not env.hinting then
			env.scopeTraceList[#env.scopeTraceList] = nil
		end
		return true
	end));
	DoStat = tagC.Do(kw"do" * lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA"end");
	FuncBody = (function()
		local IdentDefTList = vv.IdentDefT * (symb(",") * vv.IdentDefT)^0;
		local DotsHintable = tagC.Dots(symb"..." * lpeg.Cg(vv.ColonHint, "hintShort")^-1)
		local ParList = tagC.ParList(IdentDefTList * (symb(",") * DotsHintable)^-1 + DotsHintable^-1);
		return tagC.Function(
			lpeg.Cg(Cpos/parF.identDefLet, "letNode")*
			lpeg.Cg(vv.HintPolyParList, "hintPolyParList")^-1*symbA("(") * ParList * symbA(")") *
			lpeg.Cg(vv.LongHint, "hintSuffix")^-1 * vv.Block * kwA("end"))
	end)();

	RetStat = tagC.Return(kw("return") * vv.ExprListOrEmpty * symb(";")^-1);

	Stat = (function()
		local LocalFunc = vv.FuncPrefix * tagC.Localrec(vvA.IdentDefN * vv.FuncBody) / function(vHint, vLocalrec)
			vLocalrec[2].hintPrefix = vHint
			return vLocalrec
		end
		local LocalAssign = tagC.Local(vv.LocalIdentList * (symb"=" * vvA.ExprList + tagC.ExprList()))
		local LocalStat = kw"local" * (LocalFunc + LocalAssign + throw("wrong local-statement")) +
				Cenv * Cpos * kw"const" * vv.HintBegin * vv.HintEnd * (LocalFunc + LocalAssign + throw("wrong const-statement")) / function(env, pos, t)
					env:markConst(pos)
					t.isConst = true
					return t
				end
		local FuncStat = (function()
			local function makeNameIndex(ident1, ident2)
				return { tag = "Index", pos=ident1.pos, posEnd=ident2.posEnd, ident1, ident2}
			end
			local FuncName = lpeg.Cf(vv.IdentUse * (symb"." * tagC.String(vv.Name))^0, makeNameIndex)
			local MethodName = symb(":") * tagC.String(vv.Name) + cc(false)
			return Cpos * vv.FuncPrefix * FuncName * MethodName * Cpos * vv.FuncBody * Cpos / function (pos, hintPrefix, varPrefix, methodName, posMid, funcExpr, posEnd)
				funcExpr.hintPrefix = hintPrefix
				if methodName then
					table.insert(funcExpr[1], 1, parF.identDefSelf(pos))
					varPrefix = makeNameIndex(varPrefix, methodName)
				end
				return {
					tag = "Set", pos=pos, posEnd=posEnd,
					{ tag="VarList", pos=pos, posEnd=posMid, varPrefix},
					{ tag="ExprList", pos=posMid, posEnd=posEnd, funcExpr },
				}
			end
		end)()
		local LabelStat = tagC.Label(symb"::" * vv.Name * symb"::")
		local BreakStat = tagC.Break(kw"break")
		local GoToStat = tagC.Goto(kw"goto" * vvA.Name)
		local RepeatStat = tagC.Repeat(kw"repeat" * vv.Block * kwA"until" * vvA.Expr)
		local IfStat = tagC.If(kw("if") * vvA.Expr * kwA("then") * vv.Block *
			(kw("elseif") * vvA.Expr * kwA("then") * vv.Block)^0 *
			(kw("else") * vv.Block)^-1 *
			kwA("end"))
		local WhileStat = tagC.While(kw("while") * vvA.Expr * kwA("do") * vv.Block * kwA("end"))
		local ForStat = (function()
			local ForBody = kwA("do") * vv.Block
			local ForNum = tagC.Fornum(vv.IdentDefN * symb("=") * vvA.Expr * symbA(",") * vvA.Expr * (symb(",") * vv.Expr)^-1 * ForBody)
			local ForIn = tagC.Forin(vv.ForinIdentList * kwA("in") * vvA.ExprList * ForBody)
			return kw("for") * (ForNum + ForIn + throw("wrong for-statement")) * kwA("end")
		end)()
		local BlockEnd = lpeg.P("return") + "end" + "elseif" + "else" + "until" + lpeg.P(-1)
		return vv.StatHintSpace +
         LocalStat + FuncStat + LabelStat + BreakStat + GoToStat +
				 RepeatStat + ForStat + IfStat + WhileStat +
				 vv.DoStat + vv.ApplyOrAssignStat + symb(";") + (lpeg.P(1)-BlockEnd)*throw("wrong statement")
	end)();

	-- lexer
	Skip     = (lpeg.space^1 + vv.Comment)^0;
	Comment  = Cenv*Cpos*
		lpeg.P"--" * (vv.LongString / function () return end + (lpeg.P(1) - lpeg.P"\n")^0)
		*Cpos/function(env, pos, posEnd) env:markDel(pos, posEnd-1) return end;

	Number = (function()
		local Hex = (lpeg.P"0x" + lpeg.P"0X") * lpeg.xdigit^1
		local Decimal = lpeg.digit^1 * lpeg.P"." * lpeg.digit^0
									+ lpeg.P"." * -lpeg.P"." * lpeg.digit^1
		local Expo = lpeg.S"eE" * lpeg.S"+-"^-1 * lpeg.digit^1
		local Int = lpeg.digit^1
		local Float = Decimal * Expo^-1 + Int * Expo
		return lpeg.C(Hex + Float + Int) / tonumber
	end)();

	LongString = (function()
		local Equals = lpeg.P"="^0
		local Open = "[" * lpeg.Cg(Equals, "openEq") * "[" * lpeg.P"\n"^-1
		local Close = "]" * lpeg.C(Equals) * "]"
		local CloseEq = lpeg.Cmt(Close * lpeg.Cb("openEq"), function (s, i, closeEq, openEq) return #openEq == #closeEq end)
		return Open * lpeg.C((lpeg.P(1) - CloseEq)^0) * (Close+throw("--[...[comment  not close")) / function (s, eqs) return s end
	end)();

	ShortString = lpeg.P('"') * lpeg.C(((lpeg.P('\\') * lpeg.P(1)) + (lpeg.P(1) - lpeg.P('"')))^0) * (lpeg.P'"' + throw('" not close'))
							+ lpeg.P("'") * lpeg.C(((lpeg.P("\\") * lpeg.P(1)) + (lpeg.P(1) - lpeg.P("'")))^0) * (lpeg.P"'" + throw("' not close"));

	NameRest = lpeg.alnum + lpeg.P"_";

	Name = (function()
		local RawName = (lpeg.alpha + lpeg.P"_") * vv.NameRest^0
		local Keywords  = lpeg.P"and" + "break" + "do" + "elseif" + "else" + "end"
		+ "false" + "for" + "function" + "goto" + "if" + "in"
		+ "local" + "nil" + "not" + "or" + "repeat" + "return"
		+ "then" + "true" + "until" + "while" + "const"
		local Reserved = Keywords * -vv.NameRest
		return token(-Reserved * lpeg.C(RawName));
	end)();

}

function ParseEnv.new(vSubject)
	local self = setmetatable({
		hinting = false,
		scopeTraceList = {},
		_subject = vSubject,
		_posToChange = {},
	}, ParseEnv)
	local nOkay, nAstOrErr = pcall(lpeg.match, G, vSubject, nil, self)
	if not nOkay then
		if type(nAstOrErr) == "table" and nAstOrErr.tag == "Error" then
			self._astOrErr = nAstOrErr
		else
			self._astOrErr = self:makeErrNode(1, "unknown parse error: "..tostring(nAstOrErr))
		end
	else
		self._astOrErr = nAstOrErr
	end
	return self
end

function ParseEnv:getAstOrErr()
	return self._astOrErr
end

function ParseEnv:makeErrNode(vPos, vErr)
	return {
		tag="Error",
		pos=vPos,
		posEnd=vPos,
		vErr
	}
end

function ParseEnv:buildIHintSpace(vTag, vInnerList, vEvalList, vRealStartPos, vStartPos, vFinishPos)
	local nHintSpace = {
		tag = "HintSpace",
		kind = vTag,
		pos = vRealStartPos,
		posEnd = vFinishPos + 1,
		evalScriptList = {},
		table.unpack(vInnerList)
	}
	local nEvalScriptList = nHintSpace.evalScriptList
	local nSubject = self._subject
	for _, nHintEval in ipairs(vEvalList) do
		nEvalScriptList[#nEvalScriptList + 1] = {
			tag = "HintScript",
			pos=vStartPos,
			posEnd=nHintEval.pos,
			[1] = nSubject:sub(vStartPos, nHintEval.pos-1)
		}
		nEvalScriptList[#nEvalScriptList + 1] = nHintEval
		vStartPos = nHintEval.posEnd
	end
	if vStartPos <= vFinishPos then
		nEvalScriptList[#nEvalScriptList + 1] = {
			tag="HintScript",
			pos=vStartPos,
			posEnd=vFinishPos+1,
			[1]=nSubject:sub(vStartPos, vFinishPos)
		}
	end
	return nHintSpace
end

-- @ hint for invoke & call , need to add paren
-- eg.
--   aFunc() @ Integer -> (aFunc())
-- so mark paren here
function ParseEnv:markParenWrap(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = "("
	self._posToChange[vFinishPos] = ")"
end

-- hint script to be delete
function ParseEnv:markDel(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = vFinishPos
end

-- local convert to const
function ParseEnv:markConst(vStartPos)
	self._posToChange[vStartPos] = "const"
end

function ParseEnv:assertWithLineNum()
	local nNode = self._astOrErr
	local nLineNum = select(2, self._subject:sub(1, nNode.pos):gsub('\n', '\n'))
	if nNode.tag == "Error" then
		local nMsg = self._chunkName..":".. nLineNum .." ".. nNode[1]
		error(nMsg)
	end
end

function ParseEnv:captureEvalByVisit(vNode, vList)
	vList = vList or {}
	for i=1, #vNode do
		local nChildNode = vNode[i]
		if type(nChildNode) == "table" then
			if nChildNode.tag == "HintEval" then
				vList[#vList + 1] = nChildNode
			else
				self:captureEvalByVisit(nChildNode, vList)
			end
		end
	end
	return vList
end

function ParseEnv:genLuaCode()
	self:assertWithLineNum()
	local nSubject = self._subject
	local nPosToChange = self._posToChange
	local nStartPosList = {}
	for nStartPos, _ in pairs(nPosToChange) do
		nStartPosList[#nStartPosList + 1] = nStartPos
	end
	table.sort(nStartPosList)
	local nContents = {}
	local nPreFinishPos = 0
	for _, nStartPos in pairs(nStartPosList) do
		if nStartPos <= nPreFinishPos then
			-- hint in hint
			-- TODO replace in hint script
			-- continue
		else
			local nChange = nPosToChange[nStartPos]
			if type(nChange) == "number" then
				-- 1. save lua code
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				-- 2. replace hint code with space and newline
				local nFinishPos = nPosToChange[nStartPos]
				local nHintCode = nSubject:sub(nStartPos, nFinishPos)
				nContents[#nContents + 1] = nHintCode:gsub("%S", "")
				nPreFinishPos = nFinishPos
			--[[elseif type(nChange) == "string" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos]]
			elseif nChange == "const" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = "local"
				nPreFinishPos = nStartPos + 4
			elseif nChange == "(" or nChange == ")" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos
			else
				error("unexpected branch")
			end
		end
	end
	nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, #nSubject)
	return table.concat(nContents)
end

-- return lua code or throw error
function ParseEnv.compile(vContent, vChunkName)
	vChunkName = vChunkName or "[anonymous script]"
	local nEnv = ParseEnv.new(vContent)
	local nAstOrErr = nEnv:getAstOrErr()
	if nAstOrErr.tag == "Error" then
		local nLineNum = select(2, vContent:sub(1, nAstOrErr.pos):gsub('\n', '\n'))
		local nMsg = vChunkName..":".. nLineNum .." ".. nAstOrErr[1]
		error(nMsg)
	else
		return nEnv:genLuaCode()
	end
end

-- return false, errorNode | return chunkNode
function ParseEnv.parse(vContent)
	local nEnv = ParseEnv.new(vContent)
	local nAstOrErr = nEnv:getAstOrErr()
	if nAstOrErr.tag == "Error" then
		return false, nAstOrErr
	else
		return nAstOrErr, nEnv
	end
end

return ParseEnv

end end
--thlua.code.ParseEnv end ==========)

--thlua.code.SearchVisitor begin ==========(
do local _ENV = _ENV
packages['thlua.code.SearchVisitor'] = function (...)

local VisitorExtend = require "thlua.code.VisitorExtend"
local Exception = require "thlua.Exception"



  
  
   
	  
	  
	 


  
	   
	  
		   
	
	 




local TagToVisiting = {
	Chunk=function(self, vNode)
		self:rawVisit(vNode)
		table.sort(self._identList, function(a, b)
			return a.pos < b.pos
		end)
		table.sort(self._suffixPairList, function(a, b)
			return a.pos < b.pos
		end)
		table.sort(self._hintSuffixPairList, function(a, b)
			return a.pos < b.pos
		end)
	end,
	HintEval=function(self, vNode)
		self:reverseInHint(false)
		self:rawVisit(vNode)
		self:reverseInHint(true)
	end,
	HintSpace=function(self, vNode)
		self:reverseInHint(true)
		self:rawVisit(vNode)
		self:reverseInHint(false)
	end,
	Ident=function(self, vNode)
		self:rawVisit(vNode)
		table.insert(self._identList, vNode)
		if vNode.kind == "use" then
			local nPair = {
				pos=vNode.pos,posEnd=vNode.posEnd,
				vNode, vNode
			}
			table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
		end
	end,
	Index=function(self, vNode)
		self:rawVisit(vNode)
		local nSuffixExpr = vNode[2]
		if nSuffixExpr.tag == "String" or nSuffixExpr.tag == "Number" then
			local nPair = {
				pos=nSuffixExpr.pos, posEnd=nSuffixExpr.posEnd,
				vNode, nSuffixExpr
			}
			table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
		end
	end,
	Invoke=function(self, vNode)
		self:rawVisit(vNode)
		local nSuffixExpr = vNode[2]
		local nPair = {
			pos=nSuffixExpr.pos, posEnd=nSuffixExpr.posEnd,
			vNode, nSuffixExpr
		}
		table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
	end,
	Call=function(self, vNode)
		self:rawVisit(vNode)
		local nFirstArg = vNode[2][1]
		if nFirstArg and nFirstArg.tag == "String" then
			local nPair = {
				pos=nFirstArg.pos, posEnd=nFirstArg.posEnd,
				vNode, nFirstArg
			}
			table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
		end
	end,
}

local SearchVisitor = VisitorExtend(TagToVisiting)

function SearchVisitor:reverseInHint(vTarget)
	assert(self._inHintSpace ~= vTarget)
	self._inHintSpace = vTarget
end

function SearchVisitor.new(vSplitCode)
	local self = setmetatable({
		_code = vSplitCode,
		_inHintSpace=false,
		_identList = {},
		_suffixPairList = {},
		_hintSuffixPairList = {},
	}, SearchVisitor)
	return self
end

function SearchVisitor:searchSuffixPair(vPos)
	local nIndex, nPair = self._code:binSearch(self._suffixPairList, vPos)
	if not nIndex then
		return false
	end
	if vPos < nPair.pos or vPos >= nPair.posEnd then
		return false
	end
	return nPair
end

function SearchVisitor:searchHintSuffixPair(vPos)
	local nIndex, nPair = self._code:binSearch(self._hintSuffixPairList, vPos)
	if not nIndex then
		return false
	end
	if vPos < nPair.pos or vPos >= nPair.posEnd then
		return false
	end
	return nPair
end

function SearchVisitor:searchIdent(vPos)
	local nIndex, nNode = self._code:binSearch(self._identList, vPos)
	if not nIndex then
		return false
	end
	if vPos >= nNode.pos + #nNode[1] or vPos > nNode.posEnd then
		return false
	end
	return nNode
end

return SearchVisitor

end end
--thlua.code.SearchVisitor end ==========)

--thlua.code.SplitCode begin ==========(
do local _ENV = _ENV
packages['thlua.code.SplitCode'] = function (...)

local class = require "thlua.class"


	
	  
	  
		
		
	


local SplitCode = class ()

local function split(vContent) 
	local nLineList = {}
	local nLinePosList = {}
	local nLineCount = 0
	local nStartPos = 1
	local nFinishPos = 0
	while true do
		nLineCount = nLineCount + 1
		nFinishPos = vContent:find("[\r\n]", nStartPos)
		if not nFinishPos then
			if nStartPos <= #vContent then
				nLinePosList[#nLinePosList + 1] = {
					pos=nStartPos,
					posEnd=#vContent
				}
				nLineList[#nLineList + 1] = vContent:sub(nStartPos)
			end
			break
		else
			if vContent:sub(nFinishPos, nFinishPos + 1) == "\r\n" then
				nFinishPos = nFinishPos + 1
			end
			nLinePosList[#nLinePosList + 1] = {
				pos=nStartPos,
				posEnd=nFinishPos
			}
			nLineList[#nLineList + 1] = vContent:sub(nStartPos, nFinishPos)
			nStartPos = nFinishPos + 1
		end
	end
	return nLineList, nLinePosList
end

function SplitCode:ctor(vContent, ...)
	self._content = vContent
	self._lineList, self._linePosList = split(vContent)
end

function SplitCode:binSearch(vList, vPos) 
	if #vList <= 0 then
		return false
	end
	if vPos < vList[1].pos then
		return false
	end
	local nLeft = 1
	local nRight = #vList
	local count = 0
	while nRight > nLeft do
		count = count + 1
		local nMiddle = (nLeft + nRight) // 2
		local nMiddle1 = nMiddle + 1
		if vPos < vList[nMiddle].pos then
			nRight = nMiddle - 1
		elseif vPos >= vList[nMiddle1].pos then
			nLeft = nMiddle1
		else
			nLeft = nMiddle
			nRight = nMiddle
		end
	end
	return nLeft, vList[nLeft]
end

function SplitCode:lcToPos(vLine, c)
	local nLinePos = self._linePosList
	local nLineInfo = nLinePos[vLine]
	local nLineCount = #nLinePos
	if nLineInfo then
		if c <= 1 then
			return nLineInfo.pos
		else
			return nLineInfo.pos + c - 1
		end
	else
		if vLine > nLineCount then
			return #self._content + 1
		else
			return 1
		end
	end
end

function SplitCode:fixupPos(vPos, vNode) 
	local line, lineInfo = self:binSearch(self._linePosList, vPos)
	if not line or not lineInfo then
		if vPos > #self._content then
			return #self._linePosList + 1, 1
		else
			return 1, 1
		end
	else
		return line, vPos - lineInfo.pos + 1
	end
end

function SplitCode:getContent()
	return self._content
end

function SplitCode:getLine(vLine)
	return self._lineList[vLine]
end

return SplitCode

end end
--thlua.code.SplitCode end ==========)

--thlua.code.SymbolVisitor begin ==========(
do local _ENV = _ENV
packages['thlua.code.SymbolVisitor'] = function (...)

local VisitorExtend = require "thlua.code.VisitorExtend"
local Exception = require "thlua.Exception"
local Enum = require "thlua.Enum"



  
  

  
	   
	  
		   
	
	 


   
	
	
	
	




local TagToVisiting = {
	Do=function(self, stm)
		local nHintLong = stm.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		self:withScope(stm[1], nil, function()
			self:rawVisit(stm)
		end)
	end,
	Table=function(self, node)
		local nHintLong = node.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		for i=1, #node do
			self:realVisit(node[i])
		end
	end,
	While=function(self, stm)
		self:withScope(stm[2], nil, function()
			self:rawVisit(stm)
		end)
	end,
	Repeat=function(self, stm)
		self:withScope(stm[1], nil, function()
			self:rawVisit(stm)
		end)
	end,
	   
	Fornum=function(self, stm)
		local nBlockNode = stm[5]
		self:realVisit(stm[2])
		self:realVisit(stm[3])
		if nBlockNode then
			self:realVisit(stm[4])
		else
			local nSubNode = stm[4]
			assert(nSubNode.tag == "Block", "node must be block here")
			nBlockNode = nSubNode
		end
		self:withScope(nBlockNode, nil, function()
			self:symbolDefine(stm[1], Enum.SymbolKind_ITER)
			 
			           
			self:realVisit(assert(nBlockNode))
		end)
	end,
	Forin=function(self, stm)
		local nBlockNode = stm[3]
		self:realVisit(stm[2])
		self:withScope(nBlockNode, nil, function()
			for i, name in ipairs(stm[1]) do
				self:symbolDefine(name, Enum.SymbolKind_ITER)
			end
			self:realVisit(nBlockNode)
		end)
	end,
	Return=function(self, stm)
		if #stm[1] > 0 then
			self._regionStack[#self._regionStack].retFlag = true
		end
		self:rawVisit(stm)
	end,
	Function=function(self, func)
		local nHintLong = func.hintPrefix
		if nHintLong then
			self:realVisit(nHintLong)
		end
		local nBlockNode = func[2]
		self:withScope(nBlockNode, func, function()
			local nParFullHint = true
			for i, par in ipairs(func[1]) do
				if par.tag == "Ident" then
					self:symbolDefine(par, Enum.SymbolKind_PARAM)
					if not par.isSelf and not par.hintShort then
						nParFullHint = false
					end
				else
					self:dotsDefine(par)
					if not par.hintShort then
						nParFullHint = false
					end
				end
			end
			local nHintLong = func.hintSuffix
			if nHintLong then
				self:realVisit(nHintLong)
			end
			 
			self:realVisit(nBlockNode)
			local nPolyParList = func.hintPolyParList
			func.parFullHint = nParFullHint
			if not nParFullHint then
				if nPolyParList and #nPolyParList > 0 then
					           
					  
				end
			else
				if not func.hintPolyParList then
					func.hintPolyParList = {}
				end
			end
		end)
	end,
	If=function(self, node)
		for i, subNode in ipairs(node) do
			if subNode.tag == "Block" then
				self:withScope(subNode, nil, function()
					self:realVisit(subNode)
				end)
			else
				self:realVisit(subNode)
			end
		end
	end,
	Block=function(self, stm)
		self:rawVisit(stm)
	end,
	Local=function(self, stm)
		local nIdentList = stm[1]
		self:realVisit(stm[2])
		 
		for i, name in ipairs(nIdentList) do
			self:symbolDefine(name, stm.isConst and Enum.SymbolKind_CONST or Enum.SymbolKind_LOCAL)
		end
	end,
	Set=function(self, stm)
		local nVarList = stm[1]
		for i=1, #nVarList do
			local var = nVarList[i]
			if var.tag == "Ident" then
				self:symbolUse(var, true)
			end
		end
		self:rawVisit(stm)
	end,
	Localrec=function(self, stm)
		self:symbolDefine(stm[1], stm.isConst and Enum.SymbolKind_CONST or Enum.SymbolKind_LOCAL)
		self:realVisit(stm[2])
	end,
	Dots=function(self, node)
		self:dotsUse(node)
	end,
	Ident=function(self, node)
		assert(node.kind == "use")
		if node.isGetFrom ~= nil then           
		else
			self:symbolUse(node, false)
		end
	end,
	Chunk=function(self, chunk)
		local nBlockNode = chunk[3]
		self:withScope(nBlockNode, chunk, function()
			self:symbolDefine(chunk[1], Enum.SymbolKind_LOCAL)
			for k, name in ipairs(chunk[2]) do
				if name.tag == "dots" then
					self:dotsDefine(name)
				end
			end
			self:realVisit(nBlockNode)
			local nInjectNode = chunk.injectNode
			if nInjectNode then
				self:realVisit(nInjectNode)
			end
		end)
	end,
	HintSpace=function(self, node)
		self:reverseInHint(true)
		if node.kind == "StatHintSpace" then
			self:realVisit(node[1])
		else
			for i=1, #node do
				self:realVisit(node[i])
			end
		end
		self:reverseInHint(false)
	end,
	HintEval=function(self, vNode)
		vNode.endLine = self._code:fixupPos(vNode.posEnd)
		self:reverseInHint(false)
		self:realVisit(vNode[1])
		self:reverseInHint(true)
	end,
}

local SymbolVisitor = VisitorExtend(TagToVisiting)

function SymbolVisitor:reverseInHint(vTarget)
	assert(self._inHintSpace ~= vTarget)
	self._inHintSpace = vTarget
end

function SymbolVisitor:withHintBlock(vBlockNode, vFuncNode, vInnerCall)
	assert(vBlockNode.tag == "Block", "node tag must be Block or Function but get "..tostring(vBlockNode.tag))
	local nHintStack = self._hintStack
	local nStackLen = #nHintStack
	vBlockNode.subBlockList = {}
	local nPreNode = nHintStack[nStackLen]
	if nPreNode.tag == "Block" then
		vBlockNode.symbolTable = setmetatable({}, {
			__index=nPreNode.symbolTable,
		})
	else
		vBlockNode.symbolTable = {
			let=nPreNode,
		}
	end
	table.insert(self._hintStack, vBlockNode)
	if vFuncNode then
		vFuncNode.letNode = false
		table.insert(self._hintFuncStack, vFuncNode)
		vInnerCall()
		table.remove(self._hintFuncStack)
	else
		vInnerCall()
	end
	table.remove(self._hintStack)
end

function SymbolVisitor:withScope(vBlockNode, vFuncOrChunk, vInnerCall)
	assert(vBlockNode.tag == "Block", "node tag must be Block but get "..tostring(vBlockNode.tag))
	if self._inHintSpace then
		self:withHintBlock(vBlockNode, vFuncOrChunk  , vInnerCall)
		return
	end
	vBlockNode.subBlockList = {}
	local nScopeStack = self._scopeStack
	local nStackLen = #nScopeStack
	if nStackLen > 0 then
		local nPreScope = nScopeStack[nStackLen]
		vBlockNode.symbolTable = setmetatable({}, {
			__index=nPreScope.symbolTable,
		})
		table.insert(nPreScope.subBlockList, vBlockNode)
	else
		vBlockNode.symbolTable = {}
	end
	table.insert(self._scopeStack, vBlockNode)
	if vFuncOrChunk then
		table.insert(self._regionStack, vFuncOrChunk)
		table.insert(self._hintStack, assert(vFuncOrChunk.letNode))
		vInnerCall()
		table.remove(self._regionStack)
		table.remove(self._hintStack)
	else
		vInnerCall()
	end
	table.remove(self._scopeStack)
end

function SymbolVisitor:symbolDefine(vIdentNode, vImmutKind)   
	   
	vIdentNode.symbolKind = vImmutKind
	vIdentNode.symbolModify = false
	local nName = vIdentNode[1]
	if not self._inHintSpace then
		local nHintShort = vIdentNode.hintShort
		if nHintShort then
			self:realVisit(nHintShort)
		end
		local nScope = self._scopeStack[#self._scopeStack]
		local nLookupNode = nScope.symbolTable[nName]
		nScope.symbolTable[nName] = vIdentNode
		vIdentNode.lookupIdent = nLookupNode
	else
		local nBlockOrRegion = self._hintStack[#self._hintStack]
		if nBlockOrRegion.tag == "Block" then
			local nLookupNode = nBlockOrRegion.symbolTable[nName]
			nBlockOrRegion.symbolTable[nName] = vIdentNode
			vIdentNode.lookupIdent = nLookupNode
		else
			error("local stat can't existed here..")
		end
	end
end

function SymbolVisitor:dotsDefine(vDotsNode)
	local nCurRegion = self._inHintSpace and self._hintFuncStack[#self._hintFuncStack] or self._regionStack[#self._regionStack]
	nCurRegion.symbol_dots = vDotsNode
end

function SymbolVisitor:dotsUse(vDotsNode)
	local nCurRegion = self._inHintSpace and self._hintFuncStack[#self._hintFuncStack] or self._regionStack[#self._regionStack]
	local nDotsDefine = nCurRegion and nCurRegion.symbol_dots
	if not nDotsDefine then
		error(Exception.new("cannot use '...' outside a vararg function", vDotsNode))
	end
end

function SymbolVisitor:hintSymbolUse(vIdentNode, vIsAssign)
	local nBlockOrLetIdent = self._hintStack[#self._hintStack]
	local nName = vIdentNode[1]
	local nDefineNode = nil
	if nBlockOrLetIdent.tag == "Block" then
		nDefineNode = nBlockOrLetIdent.symbolTable[nName]
	else
		if nName == "let" then
			nDefineNode = nBlockOrLetIdent
		end
	end
	if not nDefineNode then
		vIdentNode.defineIdent = false
		if nBlockOrLetIdent.tag == "Block" then
			vIdentNode.isGetFrom = nBlockOrLetIdent.symbolTable["let"]
		else
			vIdentNode.isGetFrom = nBlockOrLetIdent
		end
	else
		if vIsAssign then
			nDefineNode.symbolModify = true
			vIdentNode.isGetFrom = false
		else
			vIdentNode.isGetFrom = true
		end
		vIdentNode.defineIdent = nDefineNode
	end
end

function SymbolVisitor:symbolUse(vIdentNode, vIsAssign)
	if self._inHintSpace then
		self:hintSymbolUse(vIdentNode, vIsAssign)
		return
	end
	local nScope = self._scopeStack[#self._scopeStack]
	local nDefineNode = nScope.symbolTable[vIdentNode[1]]
	if not nDefineNode then
		local nEnvIdent = nScope.symbolTable._ENV
		vIdentNode.isGetFrom = nEnvIdent
		vIdentNode.defineIdent = false
		return
	end
	if vIsAssign then
		if nDefineNode.symbolKind == Enum.SymbolKind_CONST then
			error(Exception.new("cannot assign to const variable '"..vIdentNode[1].."'", vIdentNode))
		else
			nDefineNode.symbolModify = true
		end
		vIdentNode.isGetFrom = false
	else
		vIdentNode.isGetFrom = true
	end
	vIdentNode.defineIdent = nDefineNode
end

function SymbolVisitor.new(vCode)
	local self = setmetatable({
		_code=vCode,
		_scopeStack={},
		_regionStack={},
		_inHintSpace=false,
		_hintStack={} ,
		_hintFuncStack={},
	}, SymbolVisitor)
	return self
end

return SymbolVisitor

end end
--thlua.code.SymbolVisitor end ==========)

--thlua.code.VisitorExtend begin ==========(
do local _ENV = _ENV
packages['thlua.code.VisitorExtend'] = function (...)

local Node = require "thlua.code.Node"
local Exception = require "thlua.Exception"



  

   
	
	


  
	   
	  
		   
	
	 




local TagToTraverse = {
	Chunk=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
		self:realVisit(node.letNode)
		local nInjectExpr = node.injectNode
		if nInjectExpr then
			self:realVisit(nInjectExpr)
		end
	end,
	HintTerm=function(self,node)
		self:realVisit(node[1])
	end,
	Block=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,

	 
	Do=function(self, node)
		local nHintLong = node.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		self:realVisit(node[1])
	end,
	Set=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	While=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Repeat=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	If=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	Forin=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
	end,
	Fornum=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
		self:realVisit(node[4])
		local last = node[5]
		if last then
			self:realVisit(last)
		end
	end,
	Local=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Localrec=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Goto=function(self, node)
	end,
	Return=function(self, node)
		self:realVisit(node[1])
	end,
	Break=function(self, node)
	end,
	Label=function(self, node)
	end,
	 
	Call=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Invoke=function(self, node)
		local hint = node.hintPolyArgs
		if hint then
			self:realVisit(hint)
		end
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
	end,

	 
	Nil=function(self, node)
	end,
	False=function(self, node)
	end,
	True=function(self, node)
	end,
	Number=function(self, node)
	end,
	String=function(self, node)
	end,
	Function=function(self, node)
		local nHintLong = node.hintPrefix
		if nHintLong then
			self:realVisit(nHintLong)
		end
		local nLetNode = node.letNode
		if nLetNode then
			self:realVisit(nLetNode)
		end
		self:realVisit(node[1])
		local nHintLong = node.hintSuffix
		if nHintLong then
			self:realVisit(nHintLong)
		end
		self:realVisit(node[2])
	end,
	Table=function(self, node)
		local nHintLong = node.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		for i=1, #node do
			self:realVisit(node[i])
		end
	end,
	Op=function(self, node)
		self:realVisit(node[2])
		local right = node[3]
		if right then
			self:realVisit(right)
		end
	end,
	Paren=function(self, node)
		self:realVisit(node[1])
	end,
	Dots=function(self, node)
	end,
	HintAt=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node.hintShort)
	end,

	 
	Index=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Ident=function(self, node)
		local nHintShort = node.kind == "def" and node.hintShort
		if nHintShort then
			self:realVisit(nHintShort)
		end
	end,

	 
	ParList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	ExprList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	VarList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	IdentList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	Pair=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	HintSpace=function(self, node)
		if node.kind == "StatHintSpace" then
			self:realVisit(node[1])
		else
			for i=1, #node do
				self:realVisit(node[i])
			end
		end
	end,
	HintScript=function(self, node)
	end,
	HintEval=function(self, node)
		self:realVisit(node[1])
	end,
}

local function VisitorExtend(vDictOrFunc)
	local nType = type(vDictOrFunc)
	if nType == "table" then
		local t = {}
		t.__index = t
		function t:realVisit(node)
			local tag = node.tag
			local f = vDictOrFunc[tag] or TagToTraverse[tag]
			if not f then
				error("tag="..tostring(tag).."not existed")
			end
			f(self, node)
		end
		function t:rawVisit(node)
			TagToTraverse[node.tag](self, node)
		end
		return t
	elseif nType == "function" then
		
			   
				
				
			
		
		local t = {
			realVisit=function(self, vNode)
				vDictOrFunc(self, vNode)
			end,
			rawVisit=function(self, vNode)
				TagToTraverse[vNode.tag](self, vNode)
			end
		}
		return t
	else
		error("VisitorExtend must take a function or dict for override")
	end
end

return VisitorExtend

end end
--thlua.code.VisitorExtend end ==========)

--thlua.code.thloader begin ==========(
do local _ENV = _ENV
packages['thlua.code.thloader'] = function (...)

local CodeEnv = require "thlua.code.CodeEnv"

local thloader = {}

function thloader:thluaSearch(vPath)
    local thluaPath = package.path:gsub("[.]lua", ".thlua")
    local fileName, err1 = package.searchpath(vPath, thluaPath)
    if not fileName then
        return false, err1
    end
    return true, fileName
end

function thloader:thluaParseFile(vFileName)
    local file, err = io.open(vFileName, "r")
    if not file then
        error(err)
    end
    local nContent = file:read("*a")
    file:close()
    local nCodeEnv = CodeEnv.new(nContent, vFileName)
    return nCodeEnv
end

return thloader

end end
--thlua.code.thloader end ==========)

--thlua.context.ApplyContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.ApplyContext'] = function (...)

local class = require "thlua.class"
local OpenFunction = require "thlua.func.OpenFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local AssignContext = require "thlua.context.AssignContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"
local RecurChain = require "thlua.context.RecurChain"
local RefineTerm = require "thlua.term.RefineTerm"


	  


local ApplyContext = class (AssignContext)

function ApplyContext:ctor(vNode, ...)
	self._curCase = false  
	self._once = false
	self._recurChain = false  
	self._lookupNodeSet = {}   
	self._stack:getRuntime():recordApplyContext(vNode, self)
	self._finalReturn = false 
end

function ApplyContext:getLookupNodeSet()
	return self._lookupNodeSet
end

function ApplyContext:addLookupNode(vNode, vType)
	if BaseFunction.is(vType) then
		local nIfLua, nNode = vType:getIfLuaNode()
		if nIfLua then
			vNode = nNode
		end
	end
	self._lookupNodeSet[vNode] = true
end

function ApplyContext:recursiveChainTestAndRun(vSelfType, vFunc) 
	local nRecurChain = self._recurChain
	if not nRecurChain then
		nRecurChain = RecurChain.new()
		self._recurChain = nRecurChain
	end
	return nRecurChain:testAndRun(vSelfType, vFunc)
end

function ApplyContext:withCase(vCase, vFunc)
	assert(not self._curCase, "apply context case in case error")
	self._curCase = vCase
	vFunc()
	self._curCase = false
	self._once = true
end

function ApplyContext:pushNothing()
	self._once = true
end

function ApplyContext:openAssign(vType)
	if self._once then
		error(Exception.new("table assign new field can't be mixed actions", self._node))
	end
	vType:setAssigned(self)
	self._once = true
end

   
function ApplyContext:nativeOpenReturn(vTermTuple)
	assert(not self._curCase)
	self._curCase = VariableCase.new()
	self:pushOpenReturn(vTermTuple)
	self._curCase = false
end

function ApplyContext:pushOpenReturn(vTermTuple)
	if RefineTerm.is(vTermTuple) then
		local nFirst = vTermTuple:getType()
		vTermTuple:foreach(function(vType, vCase)
			self:pushFirstAndTuple(vType, nil, vCase)
		end)
	else
		self:unfoldTermTuple(vTermTuple, function(vFirstType, vTypeTuple, vCase)
			self:pushFirstAndTuple(vFirstType, vTypeTuple, vCase)
		end)
	end
	self._once = true
end

function ApplyContext:pushFirstAndTuple(vFirstType, vTuple, vCase)
	error("push return not implement in ApplyContext")
end

function ApplyContext:pushRetTuples(vRetTuples)
	error("push return not implement in ApplyContext")
end

function ApplyContext:raiseError(vErrType)
	self._stack:RAISE_ERROR(self, vErrType)
end

function ApplyContext:getFinalReturn()
	return self._finalReturn
end

return ApplyContext

end end
--thlua.context.ApplyContext end ==========)

--thlua.context.AssignContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.AssignContext'] = function (...)

local class = require "thlua.class"

local Struct = require "thlua.object.Struct"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local AutoHolder = require "thlua.auto.AutoHolder"
local TypedFunction = require "thlua.func.TypedFunction"
local AutoTable = require "thlua.object.AutoTable"
local AutoFunction = require "thlua.func.AutoFunction"

local TermTuple = require "thlua.tuple.TermTuple"
local AutoFlag = require "thlua.auto.AutoFlag"
local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"

local ListDict = require "thlua.manager.ListDict"
local OperContext = require "thlua.context.OperContext"


	  
	  
	   


local AssignContext = class (OperContext)

function AssignContext:ctor(...)
	self._finish = false  
end

function AssignContext:matchArgsToTypeDots(
	vNode,
	vTermTuple,
	vParNum,
	vHintDots
)
	local nTailTermList = {}
	for i=vParNum + 1, #vTermTuple do
		local nTerm = vTermTuple:get(self, i)
		nTailTermList[#nTailTermList + 1] = self:assignTermToType(nTerm, vHintDots)
	end
	local nTermTail = vTermTuple:getTail()
	if AutoTail.is(nTermTail) then
		local nMore = vParNum - #vTermTuple
		if nMore <= 0 then
			nTermTail:sealTailFrom(self, 1, vHintDots)
		else
			nTermTail:sealTailFrom(self, nMore + 1, vHintDots)
		end
	end
	return self:UTermTupleByTail({}, DotsTail.new(self, vHintDots))
end

function AssignContext:matchArgsToAutoDots(
	vNode,
	vTermTuple,
	vParNum
)
	local nTailTermList = {}
	for i=vParNum + 1, #vTermTuple do
		nTailTermList[#nTailTermList + 1] = vTermTuple:get(self, i)
	end
	local nTermTail = vTermTuple:getTail()
	if not AutoTail.is(nTermTail) then
		if nTermTail then
			return self:UTermTupleByTail(nTailTermList, DotsTail.new(self, nTermTail:getRepeatType()))
		else
			return self:UTermTupleByTail(nTailTermList)
		end
	else
		local nMore = vParNum - #vTermTuple
		if nMore <= 0 then
			return self:UTermTupleByTail(nTailTermList, nTermTail)
		else
			return self:UTermTupleByTail(nTailTermList, nTermTail:openTailFrom(self, nMore + 1))
		end
	end
end

function AssignContext:matchArgsToNoDots(
	vNode,
	vTermTuple,
	vParNum
)
	for i=vParNum + 1, #vTermTuple do
		vTermTuple:get(self, i)
		self:error("parameters is not enough")
	end
	local nTermTail = vTermTuple:getTail()
	if AutoTail.is(nTermTail) then
		local nMore = vParNum - #vTermTuple
		if nMore <= 0 then
			nTermTail:sealTailFrom(self, 1, true)
		else
			nTermTail:sealTailFrom(self, nMore + 1, true)
		end
	end
end

function AssignContext:matchArgsToTypeTuple(
	vNode,
	vTermTuple,
	vTypeTuple
)
	local nParNum = #vTypeTuple
	for i=1, #vTermTuple do
		local nAutoTerm = vTermTuple:get(self, i)
		local nHintType = vTypeTuple:get(i)
		self:assignTermToType(nAutoTerm, nHintType)
	end
	for i=#vTermTuple + 1, nParNum do
		local nAutoTerm = vTermTuple:get(self, i)
		local nHintType = vTypeTuple:get(i)
		self:assignTermToType(nAutoTerm, nHintType)
	end
	local nDotsType = vTypeTuple:getRepeatType()
	if nDotsType then
		self:matchArgsToTypeDots(vNode, vTermTuple, nParNum, nDotsType)
	else
		self:matchArgsToNoDots(vNode, vTermTuple, nParNum)
	end
end


       
       
         
               

function AssignContext:tryIncludeCast(
	vAutoFnCastDict,
	vDstType,
	vSrcType
) 
	local nCollection = self._manager:TypeCollection()
	local nDstFnPart = vDstType:partTypedFunction()
	local nDstObjPart = vDstType:partTypedObject()
	local nIncludeSucc = true
	local nCastSucc = true
	local nPutFnPart = false
	local nPutObjPart = false
	vSrcType:foreach(function(vSubType)
		if AutoTable.is(vSubType) and vSubType:isCastable() and not nDstObjPart:isNever() then
			nPutObjPart = true
			local nMatchOne = false
			nDstObjPart:foreach(function(vAtomType)
				if Struct.is(vAtomType) then
					local nAutoFnCastDict = vSubType:castMatchOne(self, vAtomType)
					if nAutoFnCastDict then
						vAutoFnCastDict:putAll(nAutoFnCastDict)
						nCollection:put(vAtomType)
						nMatchOne = true
					end
				end
			end)
			if not nMatchOne then
				nCastSucc = false
			end
		elseif AutoFunction.is(vSubType) and vSubType:isCastable() and not nDstFnPart:isNever() then
			vAutoFnCastDict:putOne(vSubType, nDstFnPart)
			nPutFnPart = true
		elseif vDstType:includeAtom(vSubType) then
			nCollection:put(vSubType)
		else
			nIncludeSucc = false
		end
	end)
	if not nIncludeSucc then
		return false
	else
		if nPutFnPart then
			nCollection:put(nDstFnPart)
		end
		if not nCastSucc and nPutObjPart then
			nCollection:put(nDstObjPart)
		end
		return nCollection:mergeToAtomUnion(), nCastSucc
	end
end

function AssignContext:includeAndCast(vDstType, vSrcType, vWhen)
	local nFnLateDict = self:newAutoFnCastDict()
	local nIncludeType, nCastSucc = self:tryIncludeCast(nFnLateDict, vDstType, vSrcType)
	if nIncludeType then
		self:runLateCast(nFnLateDict)
		if not nCastSucc then
			if vWhen then
				self:error("type cast fail when "..tostring(vWhen))
			else
				self:error("type cast fail")
			end
		end
	else
		if vWhen then
			self:error("type not match when "..tostring(vWhen))
		else
			self:error("type not match")
		end
	end
	return nIncludeType
end

function AssignContext:assignTermToType(vAutoTerm, vDstType)
	local nSrcType = vAutoTerm:getType()
	local nDstType = vDstType:checkAtomUnion()
	if not nSrcType then
		vAutoTerm:setAutoCastType(self, nDstType)
	else
		self:includeAndCast(nDstType, nSrcType)
	end
	      
	return self:RefineTerm(nDstType)
end

function AssignContext:finish()
	assert(not self._finish, "context finish can only called once")
	self._finish = true
end

function AssignContext:newAutoFnCastDict()
	return ListDict ()
end

function AssignContext:runLateCast(vDict)
	vDict:forKList(function(vAutoFn, vTypeFnList)
		for _, nTypeFn in ipairs(vTypeFnList) do
			if TypedFunction.is(nTypeFn) then
				vAutoFn:checkWhenCast(nTypeFn)
			end
		end
	end)
end

function AssignContext:unfoldTermTuple(vTermTuple, vFunc  )
	local nFirstTerm = vTermTuple:get(self, 1)
	if #vTermTuple == 0 then
		vFunc(nFirstTerm:getType(), vTermTuple:checkTypeTuple(), nil)
		return
	end
	local nTail = vTermTuple:getTail()
	local nRepeatType = nTail and nTail:getRepeatType()
	nFirstTerm:foreach(function(vAtomType, vCase)
		local nTypeList = {vAtomType}
		for i=2, #vTermTuple do
			local nTerm = vTermTuple:get(self, i)
			local nType = vCase[nTerm:attachImmutVariable()]
			if not nType then
				nTypeList[i] = nTerm:getType()
			else
				nTypeList[i] = assert(nTerm:getType():safeIntersect(nType), "unexcepted intersect when return")
			end
		end
		local nTypeTuple = self._manager:TypeTuple(self._node, table.unpack(nTypeList))
		local nTypeTuple = nRepeatType and nTypeTuple:Dots(nRepeatType) or nTypeTuple
		vFunc(vAtomType, nTypeTuple, vCase)
	end)
end

return AssignContext

end end
--thlua.context.AssignContext end ==========)

--thlua.context.FieldCompletion begin ==========(
do local _ENV = _ENV
packages['thlua.context.FieldCompletion'] = function (...)

local class = require "thlua.class"


	  
	   
		
	


local FieldCompletion = class ()

function FieldCompletion:ctor()
	self._passDict = {} 
	self._keyToType = {} 
end

function FieldCompletion:putPair(vKey, vValue)
	self._keyToType[vKey] = true
end

function FieldCompletion:testAndSetPass(vAtomType)
	if self._passDict[vAtomType] then
		return false
	else
		self._passDict[vAtomType] = true
		return true
	end
end

function FieldCompletion:foreach(vOnPair )
	for k,v in pairs(self._keyToType) do
		vOnPair(k,v)
	end
end

return FieldCompletion

end end
--thlua.context.FieldCompletion end ==========)

--thlua.context.LogicContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.LogicContext'] = function (...)

local class = require "thlua.class"
local OpenFunction = require "thlua.func.OpenFunction"
local OperContext = require "thlua.context.OperContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local LogicContext = class (OperContext)

function LogicContext:ctor(
	...
)
end

function LogicContext:logicCombineTerm(vLeft, vRight, vRightAndCase)
	local nTypeCaseList = {}
	vLeft:foreach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase}
	end)
	vRight:foreach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase & vRightAndCase}
	end)
	return self:mergeToRefineTerm(nTypeCaseList)
end

function LogicContext:logicNotTerm(vTerm)
	local nTypeCaseList = {}
	local nBuiltinType = self._manager.type
	vTerm:trueEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = { nBuiltinType.False, vCase }
	end)
	vTerm:falseEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = { nBuiltinType.True, vCase }
	end)
	return self:mergeToRefineTerm(nTypeCaseList)
end

function LogicContext:logicTrueTerm(vTerm)
	local nTypeCaseList = {}
	vTerm:trueEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase}
	end)
	return self:mergeToRefineTerm(nTypeCaseList)
end

function LogicContext:logicFalseTerm(vTerm)
	local nTypeCaseList = {}
	vTerm:falseEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase}
	end)
	return self:mergeToRefineTerm(nTypeCaseList)
end

return LogicContext

end end
--thlua.context.LogicContext end ==========)

--thlua.context.MorePushContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.MorePushContext'] = function (...)

local class = require "thlua.class"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local OpenFunction = require "thlua.func.OpenFunction"
local ApplyContext = require "thlua.context.ApplyContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local MorePushContext = class (ApplyContext)

     
function MorePushContext:ctor(
	...
)
	self._retMaxLength = 0
	self._retRepCollection = self._manager:TypeCollection()
	self._retList = {} 
end

function MorePushContext:pushFirstAndTuple(vFirstType, vTypeTuple, vCase)
	local nCurCase = assert(self._curCase, "[FATAL] MorePushContext push value without case")
	self._retList[#self._retList + 1] = {
		vFirstType, vCase and (vCase & nCurCase) or nCurCase, vTypeTuple
	}
	local nLength = vTypeTuple and #vTypeTuple or 1
	if nLength > self._retMaxLength then
		self._retMaxLength = nLength
	end
	if vTypeTuple then
		local nRepeatType = vTypeTuple:getRepeatType()
		if nRepeatType then
			self._retRepCollection:put(nRepeatType)
		end
	end
end

function MorePushContext:pushRetTuples(vRetTuples)
	self:raiseError(vRetTuples:getErrType())
	vRetTuples:foreachWithFirst(function(vTypeTuple, vFirst)
		self:pushFirstAndTuple(vFirst:checkAtomUnion(), vTypeTuple)
	end)
end

function MorePushContext:pcallMergeReturn(vErrType)
	self._retMaxLength = self._retMaxLength + 1
	local nRetList = self._retList
	local nTrue = self._manager.type.True
	local nFalse = self._manager.type.False
	for i=1, #nRetList do
		local nTypeCaseTuple = nRetList[i]
		nTypeCaseTuple[1] = nTrue
		local nTuple = nTypeCaseTuple[3]
		if nTuple then
			nTypeCaseTuple[3] = nTuple:leftAppend(nTrue)
		else
			nTypeCaseTuple[3] = self._manager:TypeTuple(self._node, nTrue)
		end
	end
	nRetList[#nRetList + 1] = {
		nFalse, VariableCase.new(), self._manager:TypeTuple(self._node, nFalse, vErrType)
	}
	if self._retMaxLength < 2 then
		self._retMaxLength = 2
	end
	return self:mergeReturn()
end

function MorePushContext:mergeReturn()
	    
	local nRetList = self._retList
	local nMaxLength = self._retMaxLength
	local nRepeatType = self._retRepCollection:mergeToAtomUnion()
	local nRepeatType = (not nRepeatType:isNever()) and nRepeatType or false
	if nMaxLength <= 0 then
		return self:FixedTermTuple({}, nRepeatType)
	end
	local nTermList = {}
	      
	for i=2,nMaxLength do
		local nCollection = self._manager:TypeCollection()
		for _, nType1TupleCase in pairs(nRetList) do
			local nTypeTuple = nType1TupleCase[3]
			local nType = nTypeTuple and nTypeTuple:get(i) or self._manager.type.Nil
			nCollection:put(nType)
		end
		local nTypeI = nCollection:mergeToAtomUnion()
		nTermList[i] = self:RefineTerm(nTypeI)
	end
	    
	local nTypeCaseList = {}
	for _, nType1TupleCase in pairs(nRetList) do
		local nType1 = nType1TupleCase[1]
		local nCase = nType1TupleCase[2]:copy()
		local nTypeTuple = nType1TupleCase[3]
		for i=2,nMaxLength do
			local nType = nTypeTuple and nTypeTuple:get(i):checkAtomUnion() or self._manager.type.Nil
			nCase:put_and(nTermList[i]:attachImmutVariable(), nType)
		end
		nTypeCaseList[#nTypeCaseList + 1] = {
			nType1, nCase
		}
	end
	nTermList[1] = self:mergeToRefineTerm(nTypeCaseList)
	return self:FixedTermTuple(nTermList, nRepeatType)
end

return MorePushContext

end end
--thlua.context.MorePushContext end ==========)

--thlua.context.NoPushContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.NoPushContext'] = function (...)

local class = require "thlua.class"
local OpenFunction = require "thlua.func.OpenFunction"
local ApplyContext = require "thlua.context.ApplyContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local NoPushContext = class (ApplyContext)

function NoPushContext:pushFirstAndTuple(vFirstType, vTuple, vCase)
	self:pushNothing()
end

function NoPushContext:pushRetTuples(vRetTuples)
	self:raiseError(vRetTuples:getErrType())
	self:pushNothing()
end

return NoPushContext

end end
--thlua.context.NoPushContext end ==========)

--thlua.context.OnePushContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.OnePushContext'] = function (...)

local RefineTerm = require "thlua.term.RefineTerm"
local TermTuple = require "thlua.tuple.TermTuple"
local class = require "thlua.class"
local OpenFunction = require "thlua.func.OpenFunction"
local ApplyContext = require "thlua.context.ApplyContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local OnePushContext = class (ApplyContext)

function OnePushContext:ctor(
	_,_,_,vNotnil
)
	self._retList = {}  
	self._notnil = vNotnil
end

function OnePushContext:pushFirstAndTuple(vFirstType, vTuple, vCase)
	local nCurCase = assert(self._curCase, "[FATAL] OnePushContext push value without case")
	self._retList[#self._retList + 1] = {
		self._notnil and vFirstType:notnilType() or vFirstType, vCase and (vCase & nCurCase) or nCurCase
	}
end

function OnePushContext:pushRetTuples(vRetTuples)
	self:raiseError(vRetTuples:getErrType())
	self:pushFirstAndTuple(vRetTuples:getFirstType())
end

function OnePushContext:mergeFirst()
	local nTypeCaseList = {}
	for _, nType1TupleCase in pairs(self._retList) do
		local nType1 = nType1TupleCase[1]
		local nCase = nType1TupleCase[2]
		nTypeCaseList[#nTypeCaseList + 1] = {
			nType1, nCase
		}
	end
	return self:mergeToRefineTerm(nTypeCaseList)
end

return OnePushContext

end end
--thlua.context.OnePushContext end ==========)

--thlua.context.OperContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.OperContext'] = function (...)

local class = require "thlua.class"

local Exception = require "thlua.Exception"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local AutoHolder = require "thlua.auto.AutoHolder"
local TypedFunction = require "thlua.func.TypedFunction"
local AutoTable = require "thlua.object.AutoTable"
local AutoFunction = require "thlua.func.AutoFunction"

local TermTuple = require "thlua.tuple.TermTuple"
local AutoFlag = require "thlua.auto.AutoFlag"
local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"


	  
	  


local OperContext = class ()

function OperContext:ctor(
	vNode,
	vStack,
	vManager,
	...
)
	self._node=vNode
	self._manager=vManager
	self._stack = vStack
end

function OperContext:newException(vMsg)
	return Exception.new(vMsg, self._node)
end

function OperContext:UTermTupleByAppend(vTermList, vTermTuple  )
	if TermTuple.is(vTermTuple) then
		for i=1, #vTermTuple do
			local nTerm = vTermTuple:rawget(i)
			vTermList[#vTermList + 1] = nTerm
		end
		return self:UTermTupleByTail(vTermList, vTermTuple:getTail())
	else
		if vTermTuple then
			vTermList[#vTermList + 1] = vTermTuple
		end
		return self:UTermTupleByTail(vTermList, false)
	end
end

function OperContext:UTermTupleByTail(vTermList, vTail  )
	if AutoTail.is(vTail) then
		vTail = vTail:recurPutTermWithTail(vTermList)
	end
	if AutoTail.is(vTail) then
		return TermTuple.new(self, true, vTermList, vTail or false, false)
	end
	local nHasAuto = false
	if not nHasAuto then
		for i=1, #vTermList do
			local nAuto = vTermList[i]
			if AutoHolder.is(nAuto) then
				local nTerm = nAuto:getRefineTerm()
				if not nTerm then
					nHasAuto = true
					break
				else
					vTermList[i] = nAuto
				end
			end
		end
	end
	if nHasAuto then
		return TermTuple.new(self, true, vTermList, vTail or false, false)
	else
		return TermTuple.new(self, false, vTermList  , vTail or false, false)
	end
end

function OperContext:FixedTermTuple(vTermList, vDotsType , vTypeTuple)
	if vDotsType then
		local nTail = DotsTail.new(self, vDotsType)
		return TermTuple.new(self, false, vTermList, nTail, vTypeTuple or false)
	else
		return TermTuple.new(self, false, vTermList, false, vTypeTuple or false)
	end
end

function OperContext:RefineTerm(vType)
	return RefineTerm.new(self._node, vType:checkAtomUnion())
end

function OperContext:NeverTerm()
	return RefineTerm.new(self._node, self._manager.type.Never)
end

local function orReduceCase(vCaseList)
	if #vCaseList == 1 then
		return vCaseList[1]
	end
	local nNewCase = VariableCase.new()
	local nFirstCase = vCaseList[1]
	for nImmutVariable, nLeftType in pairs(nFirstCase) do
		local nFinalType = nLeftType
		local nPass = false
		for i=2, #vCaseList do
			local nCurCase = vCaseList[i]
			local nCurType = nCurCase[nImmutVariable]
			if nCurType then
				nFinalType = nFinalType | nCurType
			else
				nPass = true
				break
			end
		end
		if not nPass then
			nNewCase[nImmutVariable] = nFinalType
		end
	end
	return nNewCase
end

function OperContext:mergeToRefineTerm(vTypeCasePairList)
	local nKeyUnion, nTypeDict = self._manager:typeMapReduce(vTypeCasePairList, function(vList)
		return orReduceCase(vList)
	end)
	return RefineTerm.new(self._node, nKeyUnion, nTypeDict)
end

function OperContext:NilTerm()
	return RefineTerm.new(self._node, self._manager.type.Nil)
end

function OperContext:error(...)
	self._stack:getRuntime():nodeError(self._node, ...)
end

function OperContext:warn(...)
	self._stack:getRuntime():nodeWarn(self._node, ...)
end

function OperContext:info(...)
	self._stack:getRuntime():nodeInfo(self._node, ...)
end

function OperContext:getNode()
	return self._node
end

function OperContext:getRuntime()
	return self._stack:getRuntime()
end

function OperContext:getTypeManager()
	return self._manager
end

function OperContext:getStack()
	return self._stack
end

function OperContext:getInstStack()
	return self._stack  
end

return OperContext

end end
--thlua.context.OperContext end ==========)

--thlua.context.RecurChain begin ==========(
do local _ENV = _ENV
packages['thlua.context.RecurChain'] = function (...)

local class = require "thlua.class"


	  


local RecurChain = class ()

function RecurChain:ctor()
	self._curPushChain = {}  
end

function RecurChain:testAndRun(vSelfType, vFunc) 
	local nChain = self._curPushChain
	for i=1, #nChain do
		if nChain[i] == vSelfType then
			return false
		end
	end
	nChain[#nChain + 1] = vSelfType
	local nRet = vFunc()
	nChain[#nChain] = nil
	return true, nRet
end

return RecurChain
end end
--thlua.context.RecurChain end ==========)

--thlua.context.ReturnContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.ReturnContext'] = function (...)

local class = require "thlua.class"
local AssignContext = require "thlua.context.AssignContext"
local TypedFunction = require "thlua.func.TypedFunction"


	  


local ReturnContext = class (AssignContext)

function ReturnContext:ctor(...)
end

function ReturnContext:returnMatchTuples(
	vSrcTuple,
	vRetTuples
) 
	local nAutoFnCastDict = self:newAutoFnCastDict()
	local nOneMatchSucc = false
	local nOneCastSucc = false
	vRetTuples:foreachWithFirst(function(vDstTuple, _)
		local nMatchSucc, nCastSucc = self:tryMatchCast(nAutoFnCastDict, vSrcTuple, vDstTuple)
		if nMatchSucc then
			nOneMatchSucc = true
			if nCastSucc then
				nOneCastSucc = true
			end
		end
	end)
	if nOneMatchSucc then
		self:runLateCast(nAutoFnCastDict)
		return true, nOneCastSucc
	else
		return false
	end
end

function ReturnContext:tryMatchCast(
	vAutoFnCastDict,
	vSrcTuple,
	vDstTuple
) 
	local nCastResult = true
	for i=1, #vSrcTuple do
		local nDstType = vDstTuple:get(i):checkAtomUnion()
		local nSrcType = vSrcTuple:get(i):checkAtomUnion()
		local nIncludeType, nCastSucc = self:tryIncludeCast(vAutoFnCastDict, nDstType, nSrcType)
		if not nIncludeType then
			return false
		else
			nCastResult = nCastResult and nCastSucc
		end
	end
	for i=#vSrcTuple + 1, #vDstTuple do
		local nDstType = vDstTuple:get(i):checkAtomUnion()
		local nSrcType = vSrcTuple:get(i):checkAtomUnion()
		local nIncludeType, nCastSucc = self:tryIncludeCast(vAutoFnCastDict, nDstType, nSrcType)
		if not nIncludeType then
			return false
		else
			nCastResult = nCastResult and nCastSucc
		end
	end
	local nSrcRepeatType = vSrcTuple:getRepeatType()
	if nSrcRepeatType then
		local nDstRepeatType = vDstTuple:getRepeatType()
		if not nDstRepeatType then
			return false
		elseif not nDstRepeatType:includeAll(nSrcRepeatType) then
			return false
		end
	end
	return true, nCastResult
end

return ReturnContext

end end
--thlua.context.ReturnContext end ==========)

--thlua.func.AnyFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.AnyFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"
local TypedFunction = require "thlua.func.TypedFunction"
local PolyFunction = require "thlua.func.PolyFunction"

local BaseFunction = require "thlua.func.BaseFunction"
local class = require "thlua.class"

  

local AnyFunction = class (BaseFunction)

function AnyFunction:detailString(vToStringCache , vVerbose)
	return "AnyFunction"
end

function AnyFunction:meta_call(vContext, vTypeTuple)
	vContext:pushRetTuples(self._manager:VoidRetTuples(vContext:getNode()))
end

function AnyFunction:assumeIncludeAtom(vAssumeSet, vRight, _)
	if BaseFunction.is(vRight) then
		return self
	else
		return false
	end
end

function AnyFunction:mayRecursive()
	return false
end

return AnyFunction

end end
--thlua.func.AnyFunction end ==========)

--thlua.func.AutoFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.AutoFunction'] = function (...)

local TypedFunction = require "thlua.func.TypedFunction"
local SealFunction = require "thlua.func.SealFunction"
local Exception = require "thlua.Exception"

local class = require "thlua.class"


	  


local AutoFunction = class (SealFunction)
AutoFunction.__tostring=function(self)
	return "autofn@"..tostring(self._node)
end

function AutoFunction:ctor(...)
	self._castTypeFn=false
	self._firstAssign = false 
end

function AutoFunction:isCastable()
	return not self._firstAssign
end

function AutoFunction:setAssigned(vContext)
	if not self._firstAssign then
		self._firstAssign = vContext
	end
end

function AutoFunction:checkWhenCast(vTypeFn)
	if self._builderFn then
		local nOldTypeFn = self._castTypeFn
		if not nOldTypeFn then
			self._castTypeFn = vTypeFn
		else
			if vTypeFn:includeAll(nOldTypeFn) then
				self._castTypeFn = vTypeFn
			elseif nOldTypeFn:includeAll(vTypeFn) then
				 
			else
				 
				     
			end
		end
		return true
	else
		return false
	end
end

function AutoFunction:pickCastTypeFn()
	return self._castTypeFn
end

return AutoFunction

end end
--thlua.func.AutoFunction end ==========)

--thlua.func.AutoMemberFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.AutoMemberFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local TypedFunction = require "thlua.func.TypedFunction"
local PolyFunction = require "thlua.func.PolyFunction"
local AutoFunction = require "thlua.func.AutoFunction"
local MemberFunction = require "thlua.func.MemberFunction"
local class = require "thlua.class"


	  


local AutoMemberFunction = class (MemberFunction)

function AutoMemberFunction:ctor(_, _, vPolyFn)
	self._polyFn = vPolyFn
end

function AutoMemberFunction:detailString(vToStringCache , vVerbose)
	return "AutoMemberFunction@"..tostring(self._node)
end

function AutoMemberFunction:meta_invoke(vContext, vSelfType, vPolyArgs, vTypeTuple)
	if #vPolyArgs == 0 and self:needPolyArgs() then
		vContext:error("TODO poly member function called without poly args")
	end
	local nTypeFn = self._polyFn:noCtxCastPoly({vSelfType, table.unpack(vPolyArgs)})
	nTypeFn:meta_call(vContext, vTypeTuple)
end

function AutoMemberFunction:needPolyArgs()
	return self._polyFn:getPolyParNum() > 1
end

function AutoMemberFunction:indexAutoFn(vType)
	local nFn = self._polyFn:noCtxCastPoly({vType})
	if AutoFunction.is(nFn) then
		return nFn
	else
		error("auto function is expected here")
	end
end

function AutoMemberFunction:indexTypeFn(vType)
	local nFn = self._polyFn:noCtxCastPoly({vType})
	if AutoFunction.is(nFn) then
		return nFn:getFnAwait()
	elseif TypedFunction.is(nFn) then
		return nFn
	else
		error("class factory can't member function")
	end
end

function AutoMemberFunction:getIfLuaNode() 
	return true, self._node
end

return AutoMemberFunction

end end
--thlua.func.AutoMemberFunction end ==========)

--thlua.func.BaseFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.BaseFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local BaseFunction = class (BaseAtomType)

function BaseFunction:ctor(vManager, ...)
	self.bits=TYPE_BITS.FUNCTION
end

function BaseFunction:native_type()
	return self._manager:Literal("function")
end

function BaseFunction:detailString(vToStringCache, vVerbose)
	return "BaseFunction"
end

function BaseFunction:meta_call(vContext, vTermTuple)
	error("function "..tostring(self).." can't apply as call")
end

function BaseFunction:isSingleton()
	return false
end

function BaseFunction:getIfLuaNode() 
	return false
end

return BaseFunction

end end
--thlua.func.BaseFunction end ==========)

--thlua.func.ClassFactory begin ==========(
do local _ENV = _ENV
packages['thlua.func.ClassFactory'] = function (...)

local ClassTable = require "thlua.object.ClassTable"
local SealFunction = require "thlua.func.SealFunction"
local Exception = require "thlua.Exception"

local class = require "thlua.class"


	  


local ClassFactory = class (SealFunction)
function ClassFactory.__tostring(self)
	return "class@"..tostring(self._node)
end

function ClassFactory:ctor(vManager, ...)
	local nTask = self._task
	self._classBuildEvent=nTask:makeEvent()
	self._classTable=ClassTable.new(self._manager, self._node, self._buildStack, self)
end

function ClassFactory:getClassTable(vWaitInit)
	local nTable = self._classTable
	if vWaitInit then
		nTable:waitInit()
	end
	return nTable
end

function ClassFactory:wakeupTableBuild()
	self._classBuildEvent:wakeup()
end

function ClassFactory:waitTableBuild()
	self:startPreBuild()
	self:startLateBuild()
	if coroutine.running() ~= self._task:getSelfCo() then
		self._classBuildEvent:wait()
	end
end

return ClassFactory

end end
--thlua.func.ClassFactory end ==========)

--thlua.func.MemberFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.MemberFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local TypedFunction = require "thlua.func.TypedFunction"
local PolyFunction = require "thlua.func.PolyFunction"
local AutoFunction = require "thlua.func.AutoFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local class = require "thlua.class"


	  


local MemberFunction = class (BaseFunction)

function MemberFunction:ctor(vManager, vNode, ...)
	self._node = vNode
end

function MemberFunction:detailString(vToStringCache , vVerbose)
	return ""
end

return MemberFunction

end end
--thlua.func.MemberFunction end ==========)

--thlua.func.OpenFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.OpenFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local TermTuple = require "thlua.tuple.TermTuple"
local Exception = require "thlua.Exception"
local ClassTable = require "thlua.object.ClassTable"
local SealTable = require "thlua.object.SealTable"

local BaseFunction = require "thlua.func.BaseFunction"
local class = require "thlua.class"

  

local OpenFunction = class (BaseFunction)

function OpenFunction:ctor(vManager, vNode, vUpState )
	self._func=nil
	self._polyWrapper=false
	self._lexShot = vUpState or false
	self._node = vNode
	self.name="unknown"
end

function OpenFunction:lateInitFromAutoNative(vNativeFunc)
	self._func = vNativeFunc
	return self
end

function OpenFunction:lateInitFromMetaNative(
	vNativeFunc 
)
	local nFn = function(vStack, vTermTuple)
		assert(TermTuple.isFixed(vTermTuple), Exception.new("this native func can't take auto term", vStack:getNode()))
		return vStack:withMorePushContextWithCase(vStack:getNode(), vTermTuple, function(vContext, vType, vCase)
			vNativeFunc(vContext, vType)
		end):mergeReturn(), vStack:mergeEndErrType()
	end
	self._func = nFn
	return self
end

function OpenFunction:lateInitFromOperNative(
	vNativeFunc   
)
	local nFn = function(vStack, vTermTuple)
		assert(TermTuple.isFixed(vTermTuple), Exception.new("this native func can't take auto term", vStack:getNode()))
		return vNativeFunc(vStack:inplaceOper(), vTermTuple)
	end
	self._func = nFn
	return self
end

function OpenFunction:castPoly(vContext, vTypeList)
	local nPolyWrapper = self._polyWrapper
	if nPolyWrapper then
		return nPolyWrapper(vTypeList)
	else
		vContext:error("this open function can't cast poly")
		return self
	end
end

function OpenFunction:lateInitFromBuilder(vPolyParNum, vFunc    )
	local nNoPolyFn = function(vStack, vTermTuple)
		if vPolyParNum == 0 then
			return vFunc(self, vStack, {}, vTermTuple)
		else
			vStack:error("this open function need poly args")
		end
	end
	local nPolyWrapper = function(vList)
		return OpenFunction.new(self._manager, self._node, self._lexShot):lateInitFromAutoNative(function(vStack, vTermTuple)
			if #vList ~= vPolyParNum then
				vStack:error("poly args number not match")
			end
			return vFunc(self, vStack, vList, vTermTuple)
		end)
	end
	self._func = nNoPolyFn
	self._polyWrapper = nPolyWrapper
	return self
end

function OpenFunction:lateInitFromGuard(vType)
	local nTrue = self._manager.type.True
	local nFalse = self._manager.type.False
	local nFn = function(vStack, vTermTuple)
		local nTableType = vType:checkAtomUnion()
		if not ClassTable.is(nTableType) then
			error("guard function must take a class table")
		end
		assert(TermTuple.isFixed(vTermTuple), "guard function can't take auto term")
		return vStack:withOnePushContext(vStack:getNode(), function(vContext)
			local nTerm = vTermTuple:get(vContext, 1)
			local caseTrue = nTerm:caseIsType(nTableType)
			local caseFalse = nTerm:caseIsNotType(nTableType)
			if caseTrue then
				vContext:withCase(caseTrue, function()
					vContext:pushFirstAndTuple(nTrue)
				end)
			end
			if caseFalse then
				vContext:withCase(caseFalse, function()
					vContext:pushFirstAndTuple(nFalse)
				end)
			end
		end):mergeFirst(), vStack:mergeEndErrType()
	end
	self._func = nFn
	return self
end

function OpenFunction:detailString(v, vVerbose)
	return "OpenFunction-"..self.name
end

function OpenFunction:set_name(name)
	self.name = name
end

function OpenFunction:newStack(vNode, vApplyStack)
	return self._manager:getRuntime():OpenStack(vNode, self._lexShot, self, vApplyStack, false)
end

function OpenFunction:meta_call(vContext, vTermTuple)
	local nRet, nStack = self:meta_open_call(vContext, vTermTuple, false)
	vContext:raiseError(nStack:mergeEndErrType())
	vContext:pushOpenReturn(nRet)
end

function OpenFunction:meta_open_call(vContext, vTermTuple, vIsRequire) 
	local nNewStack = self._manager:getRuntime():OpenStack(vContext:getNode(), self._lexShot, self, vContext:getStack(), vIsRequire)
	return self._func(nNewStack, vTermTuple), nNewStack
end

function OpenFunction:findRequireStack()
	local nLexShot = self._lexShot
	if not nLexShot then
		return false
	end
	return nLexShot.branch:getStack():findRequireStack()
end

function OpenFunction:isSingleton()
	return true
end

function OpenFunction:mayRecursive()
	return false
end

function OpenFunction:getIfLuaNode() 
	return true, self._node
end

return OpenFunction

end end
--thlua.func.OpenFunction end ==========)

--thlua.func.PolyFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.PolyFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local SealFunction = require "thlua.func.SealFunction"
local TypedFunction = require "thlua.func.TypedFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local class = require "thlua.class"

  

local PolyFunction = class (BaseFunction)

function PolyFunction:ctor(vManager, vNode, vFunc, vPolyParNum, vLexStack)
	self._polyParNum=vPolyParNum
	self._makerFn=vFunc
	self._fnDict = {}    
	self._node = vNode
	self._lexStack = vLexStack or false
end

function PolyFunction:detailString(vToStringCache , vVerbose)
	return "PolyFunction@"..tostring(self._node)
end

function PolyFunction:getPolyParNum()
	return self._polyParNum
end

function PolyFunction:noCtxCastPoly(vTypeList) 
	assert(#vTypeList == self._polyParNum, "PolyFunction type args num not match")
	local nAtomUnionList = {}
	for i=1, #vTypeList do
		nAtomUnionList[i] = vTypeList[i]:checkAtomUnion()
	end
	local nKey = self._manager:signTemplateArgs(nAtomUnionList)
	local nFn = self._fnDict[nKey]
	if not nFn then
		local nResult = (self._makerFn(table.unpack(vTypeList)) ) 
		if TypedFunction.is(nResult) or SealFunction.is(nResult) then
			self._fnDict[nKey] = nResult
			if SealFunction.is(nResult) then
				assert(self._lexStack):getSealStack():scheduleSealType(nResult)
			end
			return nResult
		else
			error("poly function must return mono-function type but got:"..tostring(nResult))
		end
	else
		return nFn
	end
end

function PolyFunction:castPoly(vContext, vTypeList)
	local nFn = self:noCtxCastPoly(vTypeList)
	return nFn:getFnAwait()
end

function PolyFunction:native_type()
	return self._manager:Literal("function")
end

function PolyFunction:meta_call(vContext, vTypeTuple)
	error("poly function meta_call TODO")
	 
end

function PolyFunction:mayRecursive()
	return false
end

function PolyFunction:isSingleton()
	return false
end

function PolyFunction:getIfLuaNode() 
	if self._lexStack then
		return true, self._node
	else
		return false
	end
end

return PolyFunction

end end
--thlua.func.PolyFunction end ==========)

--thlua.func.SealFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.SealFunction'] = function (...)

local ScheduleTask = require "thlua.manager.ScheduleTask"
local Exception = require "thlua.Exception"

local BaseFunction = require "thlua.func.BaseFunction"

local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local class = require "thlua.class"


	  
	  
	  
		 
		
			 
		
	


local SealFunction = class (BaseFunction)

function SealFunction:ctor(
	vManager,
	vNode,
	vLexShot
)
	local nNewStack = vManager:getRuntime():SealStack(vNode, vLexShot, self   )
	self._lexStack = vLexShot and vLexShot.branch:getStack() or false
	self._buildStack = nNewStack
	local nTask = vManager:getScheduleManager():newTask(nNewStack)
	self._task = nTask
	self._node = vNode
	self._preBuildEvent=nTask:makeEvent()
	self._lateStartEvent=nTask:makeWildEvent()
	self._lateBuildEvent=nTask:makeEvent()
	self._typeFn=false
	self._retTuples=false
	self._builderFn=false
end

function SealFunction:meta_call(vContext, vTermTuple)
	local nTypeFn = self:getFnAwait()
	return nTypeFn:meta_call(vContext, vTermTuple)
end

function SealFunction:getFnAwait()
	if not self._typeFn then
		self:startPreBuild()
		self._preBuildEvent:wait()
		if not self._typeFn then
			self._lateStartEvent:wakeup()
			self._lateBuildEvent:wait()
		end
	end
	return (assert(self._typeFn, "_typeFn must existed here"))
end

function SealFunction:getNode()
	return self._node
end

function SealFunction:getBuildStack()
	return self._buildStack
end

function SealFunction:findRequireStack()
	local nLexShot = self._lexShot
	if not nLexShot then
		return false
	end
	return nLexShot.branch:getStack():findRequireStack()
end

function SealFunction:getRetTuples()
	return self._retTuples
end

function SealFunction:startPreBuild()
	local nBuilderFn = self._builderFn
	if not nBuilderFn then
		return
	end
	self._builderFn = false
	self._task:runAsync(function()
		local nParTuple, nRetTuples, nLateRunner = nBuilderFn()
		self._retTuples = nRetTuples
		if nParTuple and nRetTuples then
			self._typeFn = self._manager:TypedFunction(self._node, nParTuple, nRetTuples)
		end
		self._preBuildEvent:wakeup()
		self._lateStartEvent:wait()
		local nParTuple, nRetTuples = nLateRunner()
		self._typeFn = self._typeFn or self._manager:TypedFunction(self._node, nParTuple, nRetTuples)
		self._buildStack:seal()
		self._lateBuildEvent:wakeup()
	end)
end

function SealFunction:waitSeal()
	self._lateBuildEvent:wait()
end

function SealFunction:initAsync(vRunner)
	self._builderFn=vRunner
end

function SealFunction:startLateBuild()
	self._lateStartEvent:wakeup()
end

function SealFunction:findRequireStack()
	local nLexStack = self._lexStack
	return nLexStack and nLexStack:findRequireStack() or false
end

function SealFunction:getIfLuaNode() 
	return true, self._node
end

return SealFunction

end end
--thlua.func.SealFunction end ==========)

--thlua.func.TypedFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.TypedFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local TypeTupleDots = require "thlua.tuple.TypeTupleDots"
local Exception = require "thlua.Exception"
local TermTuple = require "thlua.tuple.TermTuple"
local RetBuilder = require "thlua.tuple.RetBuilder"

local BaseFunction = require "thlua.func.BaseFunction"
local class = require "thlua.class"

  

local TypedFunction = class (BaseFunction)

function TypedFunction:ctor(vManager, vNode,
	vParTuple, vRetTuples
)
	self._node=vNode
	self._retBuilder=RetBuilder.new(vManager, vNode)
	self._parTuple=vParTuple
	self._retTuples=vRetTuples
end

function TypedFunction:Dots(vType)
	assert(not self._retTuples, "fn building is finish, can't call Dots")
	local nParTuple = self._parTuple
	if TypeTupleDots.is(nParTuple) then
		error("use Dots but tuple has dots")
	end
	self._parTuple = nParTuple:Dots(vType)
	return self
end

function TypedFunction:RetDots(...)
	     
	assert(not self._retTuples, "fn building is finish, can't call RetDots")
	self._retBuilder:RetDots(...)
	return self
end

function TypedFunction:Err(...)
	assert(not self._retTuples, "fn building is finish, can't call RetDots")
	self._retBuilder:Err(...)
	return self
end

function TypedFunction:Ret(...)
	assert(not self._retTuples, "fn building is finish, can't call Ret")
	self._retBuilder:Ret(...)
	return self
end

function TypedFunction:finish()
	self:_buildRetTuples()
	return self
end

function TypedFunction:_buildRetTuples()
	local nRetTuples = self._retTuples
	if not nRetTuples then
		nRetTuples = self._retBuilder:build()
		self._retTuples = nRetTuples
	end
	return nRetTuples
end

function TypedFunction:native_type()
	return self._manager:Literal("function")
end

function TypedFunction:detailString(vToStringCache, vVerbose)
	local nRetTuples = self:_buildRetTuples()
	local nCache = vToStringCache[self]
	if nCache then
		return nCache
	end
	vToStringCache[self] = "fn-..."
	local nResult = "fn-" .. self._parTuple:detailString(vToStringCache, vVerbose)..
									"->"..nRetTuples:detailString(vToStringCache, vVerbose)
	vToStringCache[self] = nResult
	return nResult
end

function TypedFunction:meta_call(vContext, vTermTuple)
	local nRetTuples = self:_buildRetTuples()
	local nTypeTuple = self._parTuple
	vContext:matchArgsToTypeTuple(vContext:getNode(), vTermTuple, nTypeTuple)
	vContext:pushRetTuples(nRetTuples)
end

function TypedFunction:assumeIncludeFn(vAssumeSet , vRight)
	local nLeftRetTuples = self:_buildRetTuples()
	local nRightRetTuples = vRight:_buildRetTuples()
	if not vRight:getParTuple():assumeIncludeTuple(vAssumeSet, self._parTuple) then
		return false
	end
	if not nLeftRetTuples:assumeIncludeTuples(vAssumeSet, nRightRetTuples) then
		return false
	end
	return true
end

function TypedFunction:assumeIncludeAtom(vAssumeSet, vRight, _)
	if self == vRight then
		return self
	end
	if not TypedFunction.is(vRight) then
		return false
	end
	local nMgr = self._manager
	local nPair = self._manager:makePair(self, vRight)
	if not vAssumeSet then
		return self:assumeIncludeFn({[nPair]=true}, vRight) and self
	end
	local nAssumeResult = vAssumeSet[nPair]
	if nAssumeResult ~= nil then
		return nAssumeResult and self
	end
	vAssumeSet[nPair] = true
	local nAssumeInclude = self:assumeIncludeFn(vAssumeSet, vRight)
	if not nAssumeInclude then
		vAssumeSet[nPair] = false
		return false
	else
		return self
	end
end

function TypedFunction:getParTuple()
	self:_buildRetTuples()
	return self._parTuple
end

function TypedFunction:getRetTuples()
	return self:_buildRetTuples()
end

function TypedFunction:partTypedFunction()
	return self
end

function TypedFunction:mayRecursive()
	return true
end

function TypedFunction:getFnAwait()
	return self
end

return TypedFunction

end end
--thlua.func.TypedFunction end ==========)

--thlua.func.TypedMemberFunction begin ==========(
do local _ENV = _ENV
packages['thlua.func.TypedMemberFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local TypedFunction = require "thlua.func.TypedFunction"
local MemberFunction = require "thlua.func.MemberFunction"
local class = require "thlua.class"


	  


local TypedMemberFunction = class (MemberFunction)

function TypedMemberFunction:ctor(_,_,vHeadlessFn)
	self._headlessFn = vHeadlessFn
	self._typeFnDict = {} 
end

function TypedMemberFunction:detailString(vToStringCache , vVerbose)
	local nHeadlessFn = self._headlessFn
	local nCache = vToStringCache[self]
	if nCache then
		return nCache
	end
	local nParTuple = nHeadlessFn:getParTuple()
	local nRetTuples = nHeadlessFn:getRetTuples()
	vToStringCache[self] = "member:fn-..."
	local nResult = "member:fn-" .. nParTuple:detailStringIfFirst(vToStringCache, vVerbose, false)..
									"->"..nRetTuples:detailString(vToStringCache, vVerbose)
	vToStringCache[self] = nResult
	return nResult
end

function TypedMemberFunction:Dots(vType)
	local nHeadlessFn = assert(self._headlessFn, "member function without wildfn can't take :Dots")
	nHeadlessFn:Dots(vType)
	return self
end

function TypedMemberFunction:RetDots(vFirst, ...)
	local nHeadlessFn = assert(self._headlessFn, "member function without wildfn can't take :Ret")
	nHeadlessFn:RetDots(vFirst, ...)
	return self
end

function TypedMemberFunction:Ret(...)
	local nHeadlessFn = assert(self._headlessFn, "member function without wildfn can't take :Ret")
	nHeadlessFn:Ret(...)
	return self
end

function TypedMemberFunction:meta_invoke(vContext, vSelfType, vPolyArgs, vTypeTuple)
	local nTypeFn = self:indexTypeFn(vSelfType)
	nTypeFn:meta_call(vContext, vTypeTuple)
end

function TypedMemberFunction:needPolyArgs()
	return false
end

function TypedMemberFunction:getHeadlessFn()
	return self._headlessFn
end

function TypedMemberFunction:assumeIncludeAtom(vAssumeSet, vRight, vSelfType)
	 
	if self == vRight then
		return self
	end
	if TypedMemberFunction.is(vRight) then
		return self._headlessFn:assumeIncludeAtom(vAssumeSet, vRight:getHeadlessFn()) and self
	elseif TypedFunction.is(vRight) then
		if vSelfType then
			return self:indexTypeFn(vSelfType):assumeIncludeAtom(vAssumeSet, vRight) and self
		else
			return false
		end
	end
end

function TypedMemberFunction:indexTypeFn(vSelfType)
	local nDict = self._typeFnDict
	local nFn = nDict[vSelfType]
	if nFn then
		return nFn
	else
		local nHeadlessFn = self._headlessFn
		local nRetTuples = nHeadlessFn:getRetTuples()
		local nParTuple = nHeadlessFn:getParTuple():leftAppend(vSelfType)
		local nFn = self._manager:TypedFunction(self._node, nParTuple, nRetTuples)
		nDict[vSelfType] = nFn
		return nFn
	end
end

function TypedMemberFunction:mayRecursive()
	return true
end

return TypedMemberFunction

end end
--thlua.func.TypedMemberFunction end ==========)

--thlua.manager.ListDict begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ListDict'] = function (...)


	  


return function  ()
    local t = {
        _keyToList={}  ,
    }
    function t:putOne(k, v)
        local nList = self._keyToList[k]
        if not nList then
            self._keyToList[k] = {v}
        else
            nList[#nList + 1] = v
        end
    end
    function t:putAll(v)
        local nSelfKeyToList = self._keyToList
        v:forKList(function(vKey, vList)
            local nList = nSelfKeyToList[vKey]
            if not nList then
                nSelfKeyToList[vKey] = {table.unpack(vList)}
            else
                for i,v in ipairs(vList) do
                    nList[#nList + 1] = v
                end
            end
        end)
    end
    function t:get(k)
        return self._keyToList[k]
    end
    function t:pop(k)
        local nList = self._keyToList[k]
        self._keyToList[k] = nil
        return nList
    end
    function t:forKV(vFunc )
        for k,vList in pairs(self._keyToList) do
            for _, v in ipairs(vList) do
                vFunc(k,v)
            end
        end
    end
    function t:forKList(vFunc )
        for k,vList in pairs(self._keyToList) do
            vFunc(k,vList)
        end
    end
    return t
end

end end
--thlua.manager.ListDict end ==========)

--thlua.manager.NameLocation begin ==========(
do local _ENV = _ENV
packages['thlua.manager.NameLocation'] = function (...)


local class = require "thlua.class"


	  


local NameLocation = class ()

function NameLocation.__tostring(self)
    return "NameLocation tostring TODO"
end

function NameLocation:ctor(vSpace, vKey)
    self._space = vSpace
    self._key = vKey
end

return NameLocation
end end
--thlua.manager.NameLocation end ==========)

--thlua.manager.Namespace begin ==========(
do local _ENV = _ENV
packages['thlua.manager.Namespace'] = function (...)

local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local StringLiteral = require "thlua.type.StringLiteral"
local NameLocation= require "thlua.manager.NameLocation"
local Node = require "thlua.code.Node"
local Namespace = {}
Namespace.__tostring=function(self)
	return (self:isLetSpace() and "letspace-" or "namespace-") .. tostring(self._node).."|"..tostring(self._key or "!keynotset")
end
Namespace.__index=Namespace


	  
	   
		
	
	    


local function throw(vMsg)
	local nNode = Node.getDebugNode(4)
	error(Exception.new(vMsg, nNode))
end

function Namespace.new(vManager, vNode, vIndexTable)
	local self = setmetatable({
		_manager=vManager,
		_key2type=(vIndexTable and setmetatable({}, {__index=vIndexTable}) or {}),
		_closed=false,
		_node=vNode,
		_key=false ,
		localExport=nil,
		globalExport=nil,
	}, Namespace)
	self.localExport=(setmetatable({}, {
		__index=function(_,k) 
			local nKeyType = self:assertSpaceKeyType(k)
			local nNode = Node.getDebugNode(3)
			local rawgetV = rawget(self._key2type, nKeyType)
			if rawgetV ~= nil then
				return rawgetV
			end
			local getV = self._key2type[nKeyType]
			if getV ~= nil then
				throw("let can only get symbol in current level key="..tostring(k))
			end
			if self._closed then
				throw("namespace closed, can't create key="..tostring(k))
			end
			local refer = self._manager:Reference(tostring(k))
			refer:pushReferNode(nNode)
			self._key2type[nKeyType] = refer
			return refer
		end,
		__newindex=function(_,k,newV)
			local nKeyType = self:assertSpaceKeyType(k)
			if self._closed then
				throw("namespace closed, can't create key="..tostring(k))
			end
			local getV = self._key2type[nKeyType]
			local rawgetV = rawget(self._key2type, nKeyType)
			if getV ~= nil and rawgetV == nil then
				throw("let shadow set : key="..tostring(nKeyType))
			end
			if rawgetV ~= nil then
				    
				if Reference.is(rawgetV) then
					rawgetV:setAssignAsync(Node.getDebugNode(3), function() return newV end)
				else
					throw("assign conflict: key="..tostring(nKeyType))
				end
			else
				local namespace = Namespace.fromExport(newV)
				if namespace then
					namespace:trySetKey(tostring(nKeyType))
					self._key2type[nKeyType] = newV  
				else
					local refer = self._manager:Reference(tostring(k))
					refer:setAssignAsync(Node.getDebugNode(3), function() return newV end)
					self._key2type[nKeyType] = refer
				end
			end
		end,
		__tostring=function(_)
			return tostring(self).."->localExport"
		end,
		__self=self,
	}) ) 
	self.globalExport=(setmetatable({}, {
		__index=function(_,k) 
			local nKeyType = self:assertSpaceKeyType(k)
			local v = self._key2type[nKeyType]
			if v ~= nil then
				return v
			end
			throw("key with empty value, key="..tostring(nKeyType))
		end,
		__newindex=function(t,k,v)
			throw("global can't assign")
		end,
		__tostring=function(t)
			return tostring(self).."->globalExport"
		end,
		__self=self,
	}) ) 
	return self
end

function Namespace:assertSpaceKeyType(vKey)
	local nNode = Node.getDebugNode(5)
	local nOkay, nType = self._manager:peasyToType(vKey)
	if not nOkay then
		error(Exception.new(nType, nNode))
	end
	local nFinalKey = nType
	if Reference.is(nFinalKey) then
		nFinalKey = nFinalKey:checkAtomUnion()
	end
	if not nFinalKey:isUnion() then
		return nFinalKey
	else
		error("namespace's key can't be union type")
	end
end

function Namespace:trySetKey(vKey)
	if not self._key then
		self._key = vKey
	end
end

function Namespace:isLetSpace()
	return getmetatable(self._key2type) and true or false
end

function Namespace.fromExport(t)
	local nMeta = getmetatable(t)
	if type(nMeta) == "table" then
		local self = rawget(nMeta, "__self")
		if getmetatable(self) == Namespace then
			return self
		end
	end
	return false
end

function Namespace:close()
	self._closed=true
end

function Namespace:check()
	for k,v in pairs(self._key2type) do
		if Reference.is(v) then
		end
	end
end

function Namespace:getKeyToType()
	return self._key2type
end

function Namespace:putCompletion(vCompletion)
	for k,v in pairs(self._key2type) do
		if StringLiteral.is(k) then
			vCompletion:putPair(k:getLiteral(), v)
		end
	end
end

function Namespace:getNode()
	return self._node
end

function Namespace.is(v)
	return getmetatable(v) == Namespace
end

return Namespace

end end
--thlua.manager.Namespace end ==========)

--thlua.manager.ScheduleEvent begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ScheduleEvent'] = function (...)

local ScheduleEvent = {}
ScheduleEvent.__index = ScheduleEvent

  

function ScheduleEvent.new(vManager, vThread)
	return setmetatable({
		_scheduleManager=vManager,
		_selfCo=vThread,
		_coToSid={} ,
	}, ScheduleEvent)
end

function ScheduleEvent:wait()
	local nCoToSid = self._coToSid
	if nCoToSid then
		local nManager = self._scheduleManager
		local nSessionId = nManager:genSessionId()
		local nCurCo = coroutine.running()
		nCoToSid[nCurCo] = nSessionId
		nManager:coWait(nCurCo, nSessionId, self._selfCo)
	end
end

function ScheduleEvent:wakeup()
	local nCoToSid = self._coToSid
	if nCoToSid then
		self._coToSid = false
		local nManager = self._scheduleManager
		for co, sid in pairs(nCoToSid) do
			nManager:coWakeup(co, sid)
		end
	end
end

function ScheduleEvent:isWaken()
	return not self._coToSid
end

return ScheduleEvent

end end
--thlua.manager.ScheduleEvent end ==========)

--thlua.manager.ScheduleManager begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ScheduleManager'] = function (...)

local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local Exception = require "thlua.Exception"
local class = require "thlua.class"

local ScheduleTask = require "thlua.manager.ScheduleTask"


	  
	   
		  
		  
	


local ScheduleManager = class ()

function ScheduleManager:ctor()
	self._coToTask={}   
	self._coToScheduleParam={}  
	self._coToWaitingInfo={} 
	self._sessionIdCounter=0
	self._selfCo=coroutine.running()
end

function ScheduleManager:newTask(vStack)
	local nTask = ScheduleTask.new(self, vStack)
	self._coToTask[nTask:getSelfCo()] = nTask
	return nTask
end

function ScheduleManager:coWait(vWaitCo, vWaitSid, vDependCo)
	assert(vWaitCo == coroutine.running(), "wait co must be current co")
	if vDependCo then
		local nWaitingTask = self._coToTask[vWaitCo]
		if not nWaitingTask then
			local nDependTask = self._coToTask[vDependCo]
			error("can only call coWait in a task, try to get:"..tostring(nDependTask))
		else
			local nDependTask = self._coToTask[vDependCo]
			if nDependTask then
				if not nWaitingTask:canWaitType() and not nDependTask:getStack() then
					error("type not setted"..tostring(nDependTask))
				end
			end
		end
		local nCurCo = vDependCo
		while nCurCo do
			if nCurCo == vWaitCo then
				break
			else
				local nNextWaitingInfo = self._coToWaitingInfo[nCurCo]
				if nNextWaitingInfo then
					nCurCo = nNextWaitingInfo.dependCo
				else
					nCurCo = nil
					break
				end
			end
		end
		if nCurCo then
			   
			error("recursive build type:"..tostring(self._coToTask[nCurCo]))
		end
	else
		vDependCo = self._selfCo
	end
	self._coToWaitingInfo[vWaitCo] = {
		waitSid = vWaitSid,
		dependCo = vDependCo,
	}
	coroutine.yield()
end

function ScheduleManager:coWakeup(vWaitCo, vWaitSid)
	local nWaitingInfo = self._coToWaitingInfo[vWaitCo]
	if not nWaitingInfo then
		   
		print("session is cancel when wakeup")
		return
	elseif vWaitSid ~= nWaitingInfo.waitSid then
		print("wait sid not match when wakeup")
		return
	end
	self._coToWaitingInfo[vWaitCo] = nil
	self._coToScheduleParam[vWaitCo] = true
	local nTask = self._coToTask[coroutine.running()]
	if not nTask or nTask:getStack() then
		self:_schedule()
	end
end

function ScheduleManager:coStart(vCo, vFunc)
	self._coToScheduleParam[vCo] = vFunc
	local nTask = self._coToTask[coroutine.running()]
	if not nTask or nTask:getStack() then
		self:_schedule()
	end
end

function ScheduleManager:_schedule()
	while true do
		local nCoToParam = self._coToScheduleParam
		if not next(nCoToParam) then
			break
		else
			self._coToScheduleParam = {}  
			for co, param in pairs(nCoToParam) do
				assert(coroutine.resume(co, param))
			end
		end
	end
end

function ScheduleManager:genSessionId()
	local nNewId = self._sessionIdCounter + 1
	self._sessionIdCounter = nNewId
	return nNewId
end

function ScheduleManager:makeEvent(vThread)
	return ScheduleEvent.new(self, vThread)
end

return ScheduleManager

end end
--thlua.manager.ScheduleManager end ==========)

--thlua.manager.ScheduleTask begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ScheduleTask'] = function (...)

local Exception = require "thlua.Exception"

local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local class = require "thlua.class"


	  


local ScheduleTask = class ()

     
function ScheduleTask:ctor(vScheduleManager, vStack)
	self._scheduleManager = vScheduleManager
	self._selfCo = coroutine.create(function(vRunFn)
		local ok, nExc = pcall(vRunFn)
		if not ok then
			local nStack = self:getStack()
			if nStack then
				if Exception.is(nExc) then
					nStack:getRuntime():nodeError(nExc.node, nExc.msg)
				else
					nStack:getRuntime():nodeError(nStack:getNode(), tostring(nExc))
				end
			end
			if not nStack or nStack:isRoot() then
				error(nExc)
			end
		end
	end)
	self._stack = vStack or false
end

function ScheduleTask:getSelfCo()
	return self._selfCo
end

function ScheduleTask:canWaitType()
	return not self._stack
end

function ScheduleTask:runAsync(vFunc)
	self._scheduleManager:coStart(self._selfCo, vFunc)
end

function ScheduleTask:getStack()
	return self._stack
end

function ScheduleTask:makeEvent()
	return self._scheduleManager:makeEvent(self._selfCo)
end

function ScheduleTask:makeWildEvent()
	return self._scheduleManager:makeEvent()
end

return ScheduleTask

end end
--thlua.manager.ScheduleTask end ==========)

--thlua.manager.TypeCollection begin ==========(
do local _ENV = _ENV
packages['thlua.manager.TypeCollection'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"

local StringLiteralUnion = require "thlua.union.StringLiteralUnion"
local NumberLiteralUnion = require "thlua.union.NumberLiteralUnion"
local ObjectUnion = require "thlua.union.ObjectUnion"
local FuncUnion = require "thlua.union.FuncUnion"
local ComplexUnion = require "thlua.union.ComplexUnion"
local FalsableUnion = require "thlua.union.FalsableUnion"


	  


local FastTypeBitsToTrue = {
	[TYPE_BITS.NIL]=true,
	[TYPE_BITS.FALSE]=true,
	[TYPE_BITS.TRUE]=true,
	[TYPE_BITS.THREAD]=true,
	[TYPE_BITS.TRUTH]=true,
}

local TrueBitToTrue = {
	[TYPE_BITS.TRUE]=true,
	[TYPE_BITS.OBJECT]=true,
	[TYPE_BITS.FUNCTION]=true,
	[TYPE_BITS.NUMBER]=true,
	[TYPE_BITS.STRING]=true,
	[TYPE_BITS.THREAD]=true,
}

local TypeCollection = {}
TypeCollection.__index=TypeCollection
TypeCollection.__len=function(self)
	return self.count
end

function TypeCollection.new(vManager)
	local self = setmetatable({
		_manager=vManager,
		_type=vManager.type,
		bitsToSet={}  ,
		bits=0  ,
 		count=0  ,
	}, TypeCollection)
	return self
end

function TypeCollection:_putOne(vType)
	local nBitsToSet = self.bitsToSet
	local nBits = vType.bits
	local nSet = nBitsToSet[nBits]
	if not nSet then
		nSet = {}
		nBitsToSet[nBits] = nSet
	end
	if not nSet[vType] then
		nSet[vType] = true
		self.count = self.count + 1
	end
end

function TypeCollection:put(vType)
	local nType = vType:checkAtomUnion()
	nType:foreach(function(vSubType)
		self.bits = self.bits | vSubType.bits
		self:_putOne(vSubType)
	end)
end

function TypeCollection:_makeSimpleTrueType(vBit, vSet )
	local nUnionType = nil
	if vBit == TYPE_BITS.TRUE then
		return self._type.True
	elseif vBit == TYPE_BITS.NUMBER then
		local nNumberType = self._type.Number
		if vSet[nNumberType] then
			return nNumberType
		end
		nUnionType = NumberLiteralUnion.new(self._manager)
	elseif vBit == TYPE_BITS.STRING then
		local nStringType = self._type.String
		if vSet[nStringType] then
			return nStringType
		end
		nUnionType = StringLiteralUnion.new(self._manager)
	elseif vBit == TYPE_BITS.OBJECT then
		nUnionType = ObjectUnion.new(self._manager)
	elseif vBit == TYPE_BITS.FUNCTION then
		nUnionType = FuncUnion.new(self._manager)
	elseif vBit == TYPE_BITS.THREAD then
		return self._type.Thread
	else
		error("bit can't be="..tostring(vBit))
	end
	for nType, _ in pairs(vSet) do
		nUnionType:putAwait(nType)
	end
	return self._manager:_unifyUnion(nUnionType)
end

function TypeCollection:mergeToAtomUnion()
	local nBits = self.bits
	   
	if nBits == 0 then
		    
		return self._type.Never
	else
		              
		if self.count == 1 or FastTypeBitsToTrue[nBits] then
			local nOneType = (next(self.bitsToSet[nBits]))
			return (assert(nOneType, "logic error when type merge"))
		end
	end
	local nTruableBits = nBits & (~ (TYPE_BITS.NIL | TYPE_BITS.FALSE))
	local nFalsableBits = nBits & (TYPE_BITS.NIL | TYPE_BITS.FALSE)
	    
	local nTrueBitToType  = {}
	for nBit, nSet in pairs(self.bitsToSet) do
		if TrueBitToTrue[nBit] then
			nTrueBitToType[nBit] = self:_makeSimpleTrueType(nBit, nSet)
		end
	end
	local nTrueType = self._type.Never
	if TrueBitToTrue[nTruableBits] then
		        
		nTrueType = nTrueBitToType[nTruableBits]
	elseif nTruableBits == TYPE_BITS.TRUTH then
		   
		nTrueType = self._type.Truth
	elseif next(nTrueBitToType) then
		                  
		local nComplexUnion = ComplexUnion.new(self._manager, nTruableBits, nTrueBitToType)
		nTrueType = self._manager:_unifyUnion(nComplexUnion)
	end
	    
	if nFalsableBits == 0 then
		return nTrueType
	else
		local nUnionType = FalsableUnion.new(self._manager, nTrueType, nFalsableBits)
		return self._manager:_unifyUnion(nUnionType)
	end
end

function TypeCollection.is(vData)
	return getmetatable(vData) == TypeCollection
end

return TypeCollection

end end
--thlua.manager.TypeCollection end ==========)

--thlua.manager.TypeManager begin ==========(
do local _ENV = _ENV
packages['thlua.manager.TypeManager'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local TypeCollection = require "thlua.manager.TypeCollection"
local Node = require "thlua.code.Node"
local Exception = require "thlua.Exception"

local Never = require "thlua.union.Never"
local StringLiteral = require "thlua.type.StringLiteral"
local String = require "thlua.type.String"
local NumberLiteral = require "thlua.type.NumberLiteral"
local Number = require "thlua.type.Number"
local BooleanLiteral= require "thlua.type.BooleanLiteral"
local Nil = require "thlua.type.Nil"
local Thread = require "thlua.type.Thread"
local Truth = require "thlua.type.Truth"
local TypedObject = require "thlua.object.TypedObject"
local Struct = require "thlua.object.Struct"
local Interface = require "thlua.object.Interface"
local OpenTable = require "thlua.object.OpenTable"
local AutoTable = require "thlua.object.AutoTable"
local SealTable = require "thlua.object.SealTable"
local OpenFunction = require "thlua.func.OpenFunction"
local TypedFunction = require "thlua.func.TypedFunction"
local PolyFunction = require "thlua.func.PolyFunction"
local AnyFunction = require "thlua.func.AnyFunction"
local Reference = require "thlua.refer.Reference"

local MemberFunction = require "thlua.func.MemberFunction"
local AutoMemberFunction = require "thlua.func.AutoMemberFunction"
local TypedMemberFunction = require "thlua.func.TypedMemberFunction"

local StringLiteralUnion = require "thlua.union.StringLiteralUnion"
local NumberLiteralUnion = require "thlua.union.NumberLiteralUnion"
local ObjectUnion = require "thlua.union.ObjectUnion"
local FuncUnion = require "thlua.union.FuncUnion"
local FalsableUnion = require "thlua.union.FalsableUnion"
local ComplexUnion = require "thlua.union.ComplexUnion"

local RetTuples = require "thlua.tuple.RetTuples"
local TypeTuple = require "thlua.tuple.TypeTuple"
local TypeTupleDots = require "thlua.tuple.TypeTupleDots"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local ScheduleEvent = require "thlua.manager.ScheduleEvent"

local BaseReadyType = require "thlua.type.BaseReadyType"
local BaseAtomType = require "thlua.type.BaseAtomType"
local BaseUnionType = require "thlua.union.BaseUnionType"
local MetaEventCom = require "thlua.object.MetaEventCom"
local native = require "thlua.native"

local AsyncUnion = require "thlua.refer.AsyncUnion"

local TypeRelation = require "thlua.manager.TypeRelation"


	  
	   
		  
		  
	


local TypeManager = {}
TypeManager.__index=TypeManager

local function makeBuiltinFunc(vManager)
	local self = {
		string=native.make_string(vManager),
		next=native.make_next(vManager),
		inext=native.make_inext(vManager),
		bop={
			mathematic=native.make_mathematic(vManager),
			comparison=native.make_comparison(vManager),
			bitwise=native.make_bitwise(vManager),
			concat=native.make_concat(vManager),
		},
	}
	return self
end

function TypeManager.new(
	vRuntime,
	vRootNode,
	vScheduleManager
)
	local function makeBuiltinType(vManager)
		local self = {
			Never = vManager:_unifyUnion(Never.new(vManager)),
			Nil = Nil.new(vManager),
			False = BooleanLiteral.new(vManager, false),
			True = BooleanLiteral.new(vManager, true),
			Thread = Thread.new(vManager),
			Number = Number.new(vManager),
			String = String.new(vManager),
			Truth = Truth.new(vManager),
			AnyFunction = AnyFunction.new(vManager),
			Boolean = nil  ,
			Any = nil  ,
			AnyObject = nil  ,
		}
		self.Integer = self.Number
		return self
	end
	local self = setmetatable({
		_runtime=vRuntime,
		  
		type=nil  ,
		builtin=nil  ,
		generic={}   ,
		_pairToRelation={}   ,
		_literalDict={}   ,
		_unionSignToType=(setmetatable({}, {__mode="v"}) )  ,
		_typeIdCounter=0,
		_rootNode=vRootNode,
		_scheduleManager=vScheduleManager,
	}, TypeManager)
	self.type = makeBuiltinType(self)
	self.type.Boolean = self:buildUnion(vRootNode, self.type.False, self.type.True)
	self.type.Any = self:buildUnion(vRootNode, self.type.False, self.type.Nil, self.type.Truth)
	self.type.AnyObject = self:buildInterface(vRootNode, {})
	self.generic.Dict = self:buildTemplate(vRootNode, function(vKey,vValue)
		assert(vKey and vValue, "key or value can't be nil when build Dict")
		return self:buildStruct(vRootNode, {[vKey]=vValue}, {__next=vKey})
	end)
	self.generic.Cond = self:buildTemplate(vRootNode, function(vCond,v1,v2)
		local nType = vCond
		if Reference.is(vCond) then
			nType = vCond:checkAtomUnion()
		end
		if nType:isUnion() then
			error("Cond's first value can't be union")
		end
		return (nType == self.type.Nil or nType == self.type.False) and v2 or v1
	end)
	self.generic.IDict = self:buildTemplate(vRootNode, function(vKey,vValue)
		assert(vKey and vValue, "key or value can't be nil when build IDict")
		return self:buildInterface(vRootNode, {[vKey]=vValue}, {__next=vKey})
	end)
	self.generic.List = self:buildTemplate(vRootNode, function(vValue)
		assert(vValue, "value can't be nil when build List")
		return self:buildStruct(vRootNode, {[self.type.Integer]=vValue}, {__next=self.type.Integer, __len=self.type.Integer})
	end)
	self.generic.IList = self:buildTemplate(vRootNode, function(vValue)
		assert(vValue, "value can't be nil when build IList")
		return self:buildInterface(vRootNode, {[self.type.Integer]=vValue}, {__len=self.type.Integer})
	end)
	self.generic.KeyOf = self:buildTemplate(vRootNode, function(vOneType)
		local nObject = vOneType
		if Reference.is(vOneType) then
			nObject = vOneType:checkAtomUnion()
		end
		if not TypedObject.is(nObject) then
			error("key of can only worked on object function")
		end
		local nKeyRefer, _ = nObject:getKeyTypes()
		local nRefer = self:Reference(false)
		nRefer:setUnionAsync(nObject:getNode(), function()
			return nKeyRefer:getListAwait(), function()
				nKeyRefer:getTypeAwait()
			end
		end)
		return nRefer
	end)
	return self
end

function TypeManager:lateInit()
	self.builtin = makeBuiltinFunc(self)
end

function TypeManager:_checkAllType(vData)
	if Reference.is(vData) or BaseAtomType.is(vData) or BaseUnionType.is(vData) then
		return vData
	end
	return false
end

function TypeManager:easyToTypeList(...)
	local l = {...}
	for i=1,#l do
		l[i] = self:easyToType(l[i])
	end
	return l
end

function TypeManager:peasyToType(vData)  
	local t = type(vData)
	if t == "table" then
		if Reference.is(vData) or BaseAtomType.is(vData) or BaseUnionType.is(vData) then
			return true, vData
		else
			return false, "to type failed"
		end
	elseif t == "number" or t == "string" or t == "boolean"then
		return true, self:Literal(vData    )
	else
		return false, "easyToType("..t..") invalid"
	end
end

function TypeManager:easyToType(vData)
	local nOkay, nType = self:peasyToType(vData)
	if nOkay then
		return nType
	else
		error(nType)
	end
end

function TypeManager:TypeCollection()
	return TypeCollection.new(self)
end

function TypeManager:AsyncUnion(vTask)
	return AsyncUnion.new(self, vTask)
end

function TypeManager:_buildCombineObject(vNode, vIsInterface, vObjectList)
	local nNewObject = vIsInterface and Interface.new(self, vNode) or Struct.new(self, vNode)
	nNewObject:buildAsync(function(vAsyncKey)
		if vIsInterface then
			assert(#vObjectList>=1, "Intersect must take at least one arguments")
		else
			assert(#vObjectList >= 2, "StructExtend must take at least one interface after struct")
		end
		local nKeyList = {}
		local nKeyValuePairList   = {}
		local nIntersectSet  = {}
		local nMetaEventComList = {}
		local nIntersectNextKey = self.type.Any
		for i=1,#vObjectList do
			local nTypedObject = vObjectList[i]
			if Reference.is(nTypedObject) then
				nTypedObject = nTypedObject:checkAtomUnion()
			end
			if not TypedObject.is(nTypedObject) then
				error("Interface or Struct is expected here")
				break
			end
			if i == 1 then
				if vIsInterface then
					assert(Interface.is(nTypedObject), "Intersect must take Interface")
					nIntersectSet[nTypedObject] = true
				else
					assert(not Interface.is(nTypedObject), "StructExtend must take Struct as first argument")
				end
			else
				assert(Interface.is(nTypedObject), vIsInterface
					and "Intersect must take Interface as args"
					or "StructExtend must take Interface after first argument")
				nIntersectSet[nTypedObject] = true
			end
			local nValueDict = nTypedObject:getValueDict()
			local nKeyRefer, nNextKey = nTypedObject:getKeyTypes()
			for _, nKeyType in ipairs(nKeyRefer:getListAwait()) do
				nKeyList[#nKeyList + 1] = nKeyType
				nKeyValuePairList[#nKeyValuePairList + 1] = {nKeyType, nValueDict[nKeyType]}
			end
			nMetaEventComList[#nMetaEventComList + 1] = nTypedObject:getMetaEventCom() or nil
			if nIntersectNextKey then
				if nNextKey then
					local nTypeOrFalse = nIntersectNextKey:safeIntersect(nNextKey)
					if not nTypeOrFalse then
						error("intersect error")
					else
						nIntersectNextKey = nTypeOrFalse
					end
				else
					nIntersectNextKey = false
				end
			end
		end
		local _, nFinalValueDict = self:typeMapReduce(nKeyValuePairList, function(vList)
			return self:intersectReduceType(vNode, vList)
		end)
		local nKeyAtomUnion = vAsyncKey:setAtomList(nKeyList)
		if #nMetaEventComList > 0 then
			local nNewEventCom = self:makeMetaEventCom(nNewObject)
			nNewEventCom:initByMerge(nMetaEventComList)
			nNewObject:lateInit(nIntersectSet, nFinalValueDict, nIntersectNextKey, nNewEventCom)
		else
			nNewObject:lateInit(nIntersectSet, nFinalValueDict, nIntersectNextKey, false)
		end
		       
		nNewObject:lateCheck()
	end)
	return nNewObject
end

function TypeManager:buildExtendStruct(vNode, vFirst  ,
	... )
	local nStruct = self:_checkAllType(vFirst) or self:buildStruct(vNode, vFirst   )
	local l = {nStruct, ...}
	return self:_buildCombineObject(vNode, false, l)
end

function TypeManager:buildExtendInterface(vNode, ... )
	local l = {...}
	return self:_buildCombineObject(vNode, true, l)
end

function TypeManager:checkedUnion(...)
	local l = {...}
	local nCollection = self:TypeCollection()
	for i=1, select("#", ...) do
		l[i]:checkAtomUnion():foreach(function(vAtomType)
			nCollection:put(vAtomType)
		end)
	end
	return nCollection:mergeToAtomUnion()
end

function TypeManager:buildUnion(vNode, ...)
	local l = {...}
	local nLen = select("#", ...)
	local nNewRefer = self:Reference(false)
	nNewRefer:setUnionAsync(vNode, function()
		local nTypeList = {}
		for i=1, nLen do
			local nItem = self:easyToType(l[i])
			if Reference.is(nItem) then
				local nAsyncType = nItem:waitTypeCom():getTypeNowait()
				if nAsyncType:isAsync() then
					local nList = nAsyncType:getListAwait()
					table.move(nList, 1, #nList, #nTypeList + 1, nTypeList)
				else
					nAsyncType:foreach(function(vAtom)
						nTypeList[#nTypeList + 1] = vAtom
					end)
				end
			else
				nItem:foreach(function(vAtom)
					nTypeList[#nTypeList + 1] = vAtom
				end)
			end
		end
		return nTypeList
	end)
	return nNewRefer
end

function TypeManager:buildInterface(vNode, vTable, vMetaEventDict )
	return self:_buildTypedObject(vNode, vTable, vMetaEventDict, true)
end

function TypeManager:buildStruct(vNode, vTable, vMetaEventDict )
	return self:_buildTypedObject(vNode, vTable, vMetaEventDict, false)
end

function TypeManager:_buildTypedObject(vNode, vTable, vMetaEventDict , vIsInterface)  
	local nNextKey = vMetaEventDict and vMetaEventDict.__next or false
	local nNewObject = vIsInterface and Interface.new(self, vNode) or Struct.new(self, vNode)
	nNewObject:buildAsync(function(vAsyncKey)
		local nIndependentList = {}
		local nKeyList = {}
		local nValueDict  = {}
		for nKey, nValue in pairs(vTable) do
			local nValueType = self:easyToType(nValue)
			local nKeyType = self:easyToType(nKey)
			nIndependentList[#nIndependentList + 1] = nKeyType
			nKeyType:checkAtomUnion():foreach(function(vAtomType)
				nKeyList[#nKeyList + 1] = vAtomType
				if vAtomType:isSingleton() then
					nValueDict[vAtomType] = nValueType
				else
					nValueDict[vAtomType] = self:buildUnion(vNode, nValueType, self.type.Nil)
				end
			end)
		end
		local nKeyAtomUnion = vAsyncKey:setAtomList(nKeyList)
		if vMetaEventDict then
			local nNewEventCom = self:makeMetaEventCom(nNewObject)
			nNewEventCom:initByEventDict(vMetaEventDict)
			nNewObject:lateInit({}, nValueDict, nNextKey, nNewEventCom)
		else
			nNewObject:lateInit({}, nValueDict, nNextKey, false)
		end
		nNewObject:lateCheck()
		if not self:typeCheckIndependent(nIndependentList, nKeyAtomUnion) then
			error("Object's key must be independent")
		end
	end)
	return nNewObject
end

function TypeManager:buildIDict(vNode, vKey, vValue)
	return self:buildInterface(vNode, {[vKey]=vValue})
end

function TypeManager:buildDict(vNode, vKey, vValue)
	return self:buildStruct(vNode, {[vKey]=vValue}, {__next=vKey})
end

function TypeManager:buildIList(vNode, vValue)
	return self:buildInterface(vNode, {[self.type.Integer]=vValue}, {__len=self.type.Integer})
end

function TypeManager:buildList(vNode, vValue)
	return self:buildStruct(vNode, {[self.type.Integer]=vValue}, {__len=self.type.Integer, __next=self.type.Integer})
end

function TypeManager:buildOrNil(vNode, ...)
	return self:buildUnion(vNode, self.type.Nil, ...)
end

function TypeManager:buildOrFalse(vNode, ...)
	return self:buildUnion(vNode, self.type.False, ...)
end

function TypeManager:_unifyUnion(vNewType)
	local nSign = vNewType:unionSign()
	local nSignToType = self._unionSignToType
	local nOldType = nSignToType[nSign]
	if not nOldType then
		vNewType:initWithTypeId(self:genTypeId())
		nSignToType[nSign] = vNewType
		return vNewType
	else
		return nOldType
	end
end

function TypeManager:atomRecordTypeUnionSign(vType)
	self._unionSignToType[tostring(vType.id)] = vType
end

function TypeManager:metaNativeOpenFunction(vFn)
	local nOpenFn = self._runtime:getRootStack():newOpenFunction(self._rootNode)
	nOpenFn:lateInitFromMetaNative(vFn)
	return nOpenFn
end

function TypeManager:fixedNativeOpenFunction(vFn)
	local nOpenFn = self._runtime:getRootStack():newOpenFunction(self._rootNode)
	nOpenFn:lateInitFromOperNative(vFn)
	return nOpenFn
end

function TypeManager:stackNativeOpenFunction(vFn)
	local nOpenFn = self._runtime:getRootStack():newOpenFunction(self._rootNode)
	nOpenFn:lateInitFromAutoNative(vFn)
	return nOpenFn
end

function TypeManager:Literal(vValue  )  
	local nLiteralDict = self._literalDict
	local nLiteralType = nLiteralDict[vValue]
	if not nLiteralType then
		local t = type(vValue)
		if t == "number" then
			nLiteralType = NumberLiteral.new(self, vValue)
			nLiteralDict[vValue] = nLiteralType
		elseif t == "string" then
			nLiteralType = StringLiteral.new(self, vValue)
			nLiteralDict[vValue] = nLiteralType
		elseif t == "boolean" then
			if vValue then
				nLiteralType = self.type.True
			else
				nLiteralType = self.type.False
			end
			nLiteralDict[vValue] = nLiteralType
		else
			error("literal must take number or string value"..t)
		end
	end
	return nLiteralType
end

function TypeManager:TypeTuple(vNode, ...)
	local nTypeList = {}
	for i=1, select("#", ...) do
		local nArg = select(i, ...)
		assert(nArg, "tuple can't take false or nil value")
		if Reference.is(nArg) then
			nTypeList[i] = nArg
		elseif BaseUnionType.is(nArg) or BaseAtomType.is(nArg) then
			nTypeList[i] = nArg
		else
			error("type expected here...")
		end
	end
	return TypeTuple.new(self, vNode, nTypeList)
end

function TypeManager:VoidRetTuples(vNode, vErrType)
	return RetTuples.new(self, vNode, {self:TypeTuple(vNode)}, vErrType or false)
end

function TypeManager:SingleRetTuples(vNode, vTypeTuple, vErrType)
	return RetTuples.new(self, vNode, {vTypeTuple}, vErrType or false)
end

function TypeManager:buildMfn(vNode, ...)
	local nHeadlessFn = self:buildFn(vNode, ...)
	return TypedMemberFunction.new(self, vNode, nHeadlessFn)
end

function TypeManager:buildPfn(vNode, vFunc)
	local nInfo = debug.getinfo(vFunc)
	local nPolyParNum=nInfo.nparams
	if nInfo.isvararg then
		error("poly function can't be vararg")
	end
	return PolyFunction.new(self, vNode, vFunc, nPolyParNum)
end

function TypeManager:buildFn(vNode, ...)
	local nParTuple = self:TypeTuple(vNode, ...)
	return TypedFunction.new(self, vNode, nParTuple, false)
end

function TypeManager:checkedFn(...)
	local nParTuple = self:TypeTuple(self._rootNode, ...)
	return TypedFunction.new(self, self._rootNode, nParTuple, false)
end

function TypeManager:PolyFunction(vNode, vFunc, vPolyParNum, vStack)
	return PolyFunction.new(self, vNode, vFunc, vPolyParNum, vStack)
end

function TypeManager:AutoMemberFunction(vNode, vPolyFn)
	return AutoMemberFunction.new(self, vNode, vPolyFn)
end

function TypeManager:TypedFunction(vNode, vParTuple, vRetTuples)
	assert(TypeTuple.is(vParTuple) or TypeTupleDots.is(vParTuple))
	assert(RetTuples.is(vRetTuples))
	return TypedFunction.new(self, vNode, vParTuple, vRetTuples)
end

function TypeManager:makeMetaEventCom(vObject )
	return MetaEventCom.new(self, vObject)
end

function TypeManager:buildTemplate(vNode, vFunc)
	local nInfo = debug.getinfo(vFunc)
	local nParNum = nInfo.nparams
	if nInfo.isvararg then
		error("template's parameter number is undetermined")
	end
	return self:buildTemplateWithParNum(vNode, vFunc, nParNum)
end

function TypeManager:buildTemplateWithParNum(vNode, vFunc, vParNum)
	local nRefer = self:Reference(false)
	nRefer:setTemplateAsync(vNode, vFunc, vParNum)
	return nRefer
end

function TypeManager:Reference(vName )
	local nRefer = Reference.new(self, vName)
	return nRefer
end

function TypeManager:typeCheckIndependent(vList, vFinalType)
	local nLeftCount = 0
	for k,v in pairs(vList) do
		v:checkAtomUnion():foreach(function(_)
			nLeftCount = nLeftCount + 1
		end)
	end
	local nRightCount = 0
	vFinalType:foreach(function(_)
		nRightCount = nRightCount + 1
	end)
	return nRightCount == nLeftCount
end

function TypeManager:typeMapReduce(
	vTypePairList  ,
	vReduceFn
)  
	local nCollection = self:TypeCollection()
	for _, nPair in ipairs(vTypePairList) do
		local nFieldType = nPair[1]
		if nFieldType:isReference() then
			nFieldType = nFieldType:checkAtomUnion()
			nPair[1] = nFieldType
		end
		nCollection:put(nFieldType)
	end
	local nKeyUnion = nCollection:mergeToAtomUnion()
	   
	local nTypeToList  = {}
	for _, nPair in ipairs(vTypePairList) do
		local nKey = nPair[1]
		local nValueType = nPair[2]
		nKey:foreach(function(vSubType)
			local nIncludeType = assert(nKeyUnion:includeAtom(vSubType), "merge error")
			local nList = nTypeToList[nIncludeType]
			if not nList then
				nTypeToList[nIncludeType] = {nValueType}
			else
				nList[#nList + 1] = nValueType
			end
		end)
	end
	   
	local nTypeDict  = {}
	for k,v in pairs(nTypeToList) do
		nTypeDict[k] = vReduceFn(v)
	end
	return nKeyUnion, nTypeDict
end

function TypeManager:unionReduceType(vList)
	if #vList == 1 then
		return vList[1]
	end
	local nCollection = self:TypeCollection()
	for _, nType in ipairs(vList) do
		nType:foreach(function(vAtomType)
			nCollection:put(vAtomType)
		end)
	end
	return nCollection:mergeToAtomUnion()
end

function TypeManager:intersectReduceType(vNode, vList)
	local nFirst = vList[1]
	if #vList == 1 then
		return nFirst
	end
	local nRefer = self:Reference(false)
	nRefer:setUnionAsync(vNode, function()
		local nFinalType = nFirst:checkAtomUnion()
		for i=2, #vList do
			local nCurType = vList[i]
			local nInterType = nFinalType:safeIntersect(nCurType)
			if not nInterType then
				error("unexpected intersect")
			else
				nFinalType = nInterType
			end
		end
		local nAtomList = {}
		nFinalType:foreach(function(vAtomType)
			nAtomList[#nAtomList + 1] = vAtomType
		end)
		if nFinalType:isNever() then
			error("object intersect can't has never field")
		end
		return nAtomList, function()
			return nFinalType
		end
	end)
	return nRefer
end

function TypeManager:makePair(vLeft, vRight)
	local nLeftId, nRightId = vLeft.id, vRight.id
	assert(nLeftId ~= 0 and nRightId ~=0, "use id ==0")
	return TypeRelation.shiftPair(nLeftId, nRightId)
end

function TypeManager:makeDuPair(vLeft, vRight)  
	local nLeftId, nRightId = vLeft.id, vRight.id
	if nLeftId < nRightId then
		return false, TypeRelation.shiftPair(nLeftId, nRightId), TypeRelation.shiftPair(nRightId, nLeftId)
	else
		return true, TypeRelation.shiftPair(nRightId, nLeftId), TypeRelation.shiftPair(nLeftId, nRightId)
	end
end

function TypeManager:attachPairRelation(vLeft, vRight, vWaitCreate)
	local nInverse, nLRPair, nRLPair = self:makeDuPair(vLeft, vRight)
	if nInverse then
		vRight, vLeft = vLeft, vRight
	end
	local nRelation = self._pairToRelation[nLRPair]
	local nResult = false
	if vWaitCreate then
		if not nRelation then
			nRelation = TypeRelation.new(self)
			self._pairToRelation[nLRPair] = nRelation
			nRelation:buildByObject(vLeft, vRight)
		end
		nResult = nRelation:getAwait()
	else
		if nRelation then
			nResult = nRelation:getNowait()
		end
	end
	if not nResult then
		return nil
	end
	if nInverse then
		if nResult == ">" then
			return "<"
		elseif nResult == "<" then
			return ">"
		else
			return nResult
		end
	else
		return nResult
	end
end

function TypeManager:getRuntime()
	return self._runtime
end

function TypeManager:literal2Primitive(vType)
	if BooleanLiteral.is(vType) then
		return self.type.Boolean:checkAtomUnion()
	elseif NumberLiteral.is(vType) then
		return self.type.Number
	elseif StringLiteral.is(vType) then
		return self.type.String
	else
		return vType
	end
end

function TypeManager:signTemplateArgs(vTypeList)
	local nIdList = {}
	for i=1,#vTypeList do
		nIdList[i] = vTypeList[i].id
	end
	return table.concat(nIdList, "-")
end

function TypeManager:genTypeId()
	local nNewId = self._typeIdCounter + 1
	self._typeIdCounter = nNewId
	return nNewId
end

function TypeManager:dump()
	for k,v in pairs(self._unionSignToType) do
		print(k, tostring(v))
	end
end

function TypeManager:getScheduleManager()
	return self._scheduleManager
end

return TypeManager

end end
--thlua.manager.TypeManager end ==========)

--thlua.manager.TypeRelation begin ==========(
do local _ENV = _ENV
packages['thlua.manager.TypeRelation'] = function (...)

local class = require "thlua.class"
local Interface = require "thlua.object.Interface"

local TypeRelation = {}
TypeRelation.__index = TypeRelation

TypeRelation.HAS = ">"
TypeRelation.IN = "<"
TypeRelation.EQUAL = "="
TypeRelation.SOME = "&"
TypeRelation.NONE = "~"


	  
          


function TypeRelation.new(vManager)
    local nTask = vManager:getScheduleManager():newTask()
    local self = setmetatable({
        _manager = vManager,
        _task = nTask,
        _buildEvent = nTask:makeEvent(),
        _result = false  ,
        _smallIdObj = nil,
        _bigIdObj = nil,
    }, TypeRelation)
    return self
end

local function shiftPair(vId1, vId2)
	return (vId1 << 32) + vId2
end
TypeRelation.shiftPair = shiftPair

function TypeRelation:getAwait()
    self._buildEvent:wait()
    return assert(self._result)
end

function TypeRelation:getNowait()
    return self._result
end

function TypeRelation:buildByObject(vLeft, vRight)
    if vLeft.id > vRight.id then
        vLeft, vRight = vRight, vLeft
    end
    self._smallIdObj = vLeft
    self._bigIdObj = vRight
    self._task:runAsync(function()
        local nLeftId = vLeft.id
        local nRightId = vRight.id
        local nLRPair, nRLPair = shiftPair(nLeftId, nRightId), TypeRelation.shiftPair(nRightId, nLeftId)
        local nLRInclude = vLeft:assumeIncludeObject({[nLRPair]=true}, vRight)
        local nRLInclude = vRight:assumeIncludeObject({[nRLPair]=true}, vLeft)
        if nLRInclude and nRLInclude then
            self._result = TypeRelation.EQUAL
        elseif nLRInclude then
            self._result = TypeRelation.HAS
        elseif nRLInclude then
            self._result = TypeRelation.IN
        else
            if Interface.is(vLeft) and Interface.is(vRight) then
                local nIntersect = vLeft:assumeIntersectInterface({[nLRPair]=true,[nRLPair]=true}, vRight)
                if nIntersect then
                    self._result = TypeRelation.SOME
                else
                    self._result = TypeRelation.NONE
                end
            else
                self._result = TypeRelation.NONE
            end
        end
        self._buildEvent:wakeup()
    end)
end

return TypeRelation
end end
--thlua.manager.TypeRelation end ==========)

--thlua.native begin ==========(
do local _ENV = _ENV
packages['thlua.native'] = function (...)

local TermTuple = require "thlua.tuple.TermTuple"
local TypedFunction = require "thlua.func.TypedFunction"
local SealTable = require "thlua.object.SealTable"
local OpenTable = require "thlua.object.OpenTable"
local AutoTable = require "thlua.object.AutoTable"
local Truth = require "thlua.type.Truth"
local RefineTerm = require "thlua.term.RefineTerm"
local StringLiteral = require "thlua.type.StringLiteral"
local NumberLiteral = require "thlua.type.NumberLiteral"
local Number = require "thlua.type.Number"
local Exception = require "thlua.Exception"
local VariableCase = require "thlua.term.VariableCase"

local native = {}


	  
	   


function native._toTable(vManager, vTable)
	local nPairList  = {}
	for k,v in pairs(vTable) do
		nPairList[#nPairList + 1] = {
			vManager:Literal(k), v
		}
	end
  local nKeyUnion, nTypeDict = vManager:typeMapReduce(nPairList, function(vList)
		return vManager:unionReduceType(vList)
	end)
	local nTable = AutoTable.new(vManager, vManager:getRuntime():getNode(), vManager:getRuntime():getRootStack())
	nTable:initByKeyValue(vManager:getRuntime():getNode(), nKeyUnion, nTypeDict)
	return nTable
end

function native.make(vRuntime)
	local nManager = vRuntime:getTypeManager()
	local global = {
		 
		setmetatable=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			return vStack:withOnePushContext(vStack:getNode(), function(vContext)
				local nTerm1 = vTermTuple:checkFixed(vContext, 1)
				local nType1 = nTerm1:getType()
				local nType2 = vTermTuple:checkFixed(vContext, 2):getType()
				if nType1:isUnion() or nType2:isUnion() then
					vContext:error("setmetatable can't take union type")
				else
					nType1 = nType1:checkAtomUnion()
					nType2 = nType2:checkAtomUnion()
					if SealTable.is(nType2) or OpenTable.is(nType2) then
						nType2:setAssigned(vContext)
						nType1:native_setmetatable(vContext, nType2)
					else
						vContext:error("metatable must be table but get:"..tostring(nType2))
					end
				end
				vContext:nativeOpenReturn(nTerm1)
			end):mergeFirst()
		end),
		getmetatable=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nTerm1 = vTermTuple:get(vContext, 1)
			local nTypeCaseList = {}
			nTerm1:foreach(function(vType1, vVariableCase)
				nTypeCaseList[#nTypeCaseList + 1] = {
					vType1:native_getmetatable(vContext),
					vVariableCase,
				}
			end)
			return vContext:mergeToRefineTerm(nTypeCaseList)
		end),
		next=nManager.builtin.next,
		ipairs=nManager:metaNativeOpenFunction(function(vContext, vType)
			local nTypeTuple = vType:meta_ipairs(vContext) or nManager:TypeTuple(vContext:getNode(), nManager.builtin.inext, vType, nManager:Literal(0))
			vContext:pushFirstAndTuple(nTypeTuple:get(1):checkAtomUnion(), nTypeTuple)
		end),
		pairs=nManager:metaNativeOpenFunction(function(vContext, vType)
			local nTypeTuple = vType:meta_pairs(vContext) or nManager:TypeTuple(vContext:getNode(), nManager.builtin.next, vType, nManager.type.Nil)
			vContext:pushFirstAndTuple(nTypeTuple:get(1):checkAtomUnion(), nTypeTuple)
		end),
		rawequal=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			 
			 
			print("rawequal TODO")
			return vContext:RefineTerm(nManager.type.Boolean)
		end),
		rawget=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			return vStack:withOnePushContext(vStack:getNode(), function(vContext)
				local nType1 = vTermTuple:checkFixed(vContext, 1):getType()
				local nType2 = vTermTuple:checkFixed(vContext, 2):getType()
				assert(not nType1:isUnion(), "rawget for union type TODO")
				assert(not nType2:isUnion(), "rawget for union type TODO")
				vContext:nativeOpenReturn(vContext:RefineTerm(nType1:native_rawget(vContext, nType2)))
			end):mergeFirst()
		end),
		rawset=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			 
			 
			print("rawset TODO")
			return vContext:FixedTermTuple({})
		end),
		collectgarbage=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			return vContext:FixedTermTuple({})
		end),
		tostring=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			return vContext:RefineTerm(nManager.type.String)
		end),
		type=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nTerm = vTermTuple:get(vContext, 1)
			local nTypeCaseList = {}
			nTerm:foreach(function(vType, vVariableCase)
				nTypeCaseList[#nTypeCaseList + 1] = {
					vType:native_type(), vVariableCase
				}
			end)
			return vContext:mergeToRefineTerm(nTypeCaseList)
		end),
		  
		select=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nFirstType = vTermTuple:get(vContext, 1):getType()
			if nFirstType == nManager:Literal("#") then
				return vContext:RefineTerm(nManager.type.Integer)
			else
				if NumberLiteral.is(nFirstType) then
					local nStart = nFirstType:getLiteral()
					if nStart > 0 then
						return vTermTuple:select(vContext, nStart + 1)
					elseif nStart < 0 then
						vContext:error("select first < 0 TODO")
						return vContext:FixedTermTuple({})
					else
						vContext:error("select's first arguments is zero")
						return vContext:FixedTermTuple({})
					end
				else
					if Number.is(nFirstType) then
						local nCollection = nManager:TypeCollection()
						for i=2, #vTermTuple do
							local nType = vTermTuple:get(vContext, i):getType()
							nCollection:put(nType)
						end
						local nRepeatType = vTermTuple:getRepeatType()
						if nRepeatType then
							nCollection:put(nRepeatType)
						end
						local nFinalType = nCollection:mergeToAtomUnion()
						if nRepeatType then
							return nManager:TypeTuple(vContext:getNode()):Dots(nRepeatType):makeTermTuple(vContext)
						else
							local nReList = {}
							for i=2, #vTermTuple do
								nReList[#nReList + 1] = nFinalType
							end
							return nManager:TypeTuple(vContext:getNode(), table.unpack(nReList)):makeTermTuple(vContext)
						end
					else
						vContext:error("select's first value must be number or number-literal")
						return vContext:FixedTermTuple({})
					end
				end
			end
		end),
		print=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			return vContext:FixedTermTuple({})
		end),
		tprint=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nTailContext = vStack:inplaceOper()
			nTailContext:info(vTermTuple)
			return nTailContext:FixedTermTuple({})
		end),
		ttprint=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			vContext:info(vTermTuple:checkTypeTuple())
			return vContext:FixedTermTuple({})
		end),
		tonumber=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			 
			   
			 
			return vContext:RefineTerm(nManager:checkedUnion(nManager.type.False, nManager.type.Number))
		end),
		require=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			return vStack:withOnePushContext(vStack:getNode(), function(vContext)
				local nFileName = vTermTuple:get(vContext, 1):getType()
				if StringLiteral.is(nFileName) then
					local nPath = nFileName:getLiteral()
					local nRetTerm, nOpenFn = vRuntime:require(vStack:getNode(), nPath)
					vContext:addLookupNode(nRetTerm:getNode(), nOpenFn)
					vContext:nativeOpenReturn(nRetTerm)
				else
					vContext:warn("TODO require take non-StringLiteral type ")
					vContext:nativeOpenReturn(vContext:FixedTermTuple({}))
				end
			end):mergeFirst()
		end),
		load=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			 
			return vContext:RefineTerm(nManager.type.AnyFunction)
		end),
		       
		pcall=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nHeadContext = vStack:inplaceOper()
			local nFunc = vTermTuple:get(nHeadContext, 1):checkRefineTerm(nHeadContext)
			local nArgs = vTermTuple:select(nHeadContext, 2)
			local nCallContext = vStack:prepareMetaCall(vStack:getNode(), nFunc, function() return nArgs end)
			return nCallContext:pcallMergeReturn(vStack:mergeEndErrType())
		end),
		xpcall=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nHeadContext = vStack:inplaceOper()
			local nFunc1 = vTermTuple:get(nHeadContext, 1):checkRefineTerm(nHeadContext)
			local nFunc2 = vTermTuple:get(nHeadContext, 2):checkRefineTerm(nHeadContext)
			local nArgs = vTermTuple:select(nHeadContext, 3)
			local nCallContext = vStack:prepareMetaCall(vStack:getNode(), nFunc1, function() return nArgs end)
			local nErrType = vStack:mergeEndErrType()
			local nHandleContext = vStack:prepareMetaCall(vStack:getNode(), nFunc2, function() return nCallContext:FixedTermTuple({nCallContext:RefineTerm(nErrType)}) end)
			local nHandleReturn = nHandleContext:mergeReturn()
			local nType = RefineTerm.is(nHandleReturn) and nHandleReturn:getType() or nHandleReturn:get(nHandleContext, 1):getType()
			return nCallContext:pcallMergeReturn(nType)
		end),
		error=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nOperCtx = vStack:inplaceOper()
			vStack:getApplyStack():nativeError(nOperCtx, vTermTuple:checkFixed(nOperCtx, 1))
			return nOperCtx:FixedTermTuple({})
		end),
		assert=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nHeadContext = vStack:inplaceOper()
			local nFirst = vTermTuple:checkFixed(nHeadContext, 1)
			local nSecond = vTermTuple:rawget(2)
			vStack:getApplyStack():nativeAssert(nHeadContext, nFirst, nSecond and nSecond:checkRefineTerm(nHeadContext))
			local nLogicContext = vStack:newLogicContext(vStack:getNode())
			return vStack:inplaceOper():FixedTermTuple({nLogicContext:logicTrueTerm(nFirst)})
		end),
	}
	for k,v in pairs(global   ) do
		 
	end

	global.string=nManager.builtin.string

	global.os=native.make_os(nManager)
	global.math=native.make_math(nManager)
	global.debug=native.make_debug(nManager)
	global.table=native.make_table(nManager)
	global.io=native.make_io(nManager)
	global.coroutine=native.make_coroutine(nManager)
	global.package=native.make_package(nManager)

	   
	local nGlobalTable = native._toTable(vRuntime:getTypeManager(), global)
    nGlobalTable:setName("_G")

	return nGlobalTable
end

function native.make_package(vManager)
	local type = vManager.type
	local package = {
		searchpath=vManager:checkedFn(type.String, type.String):Ret(type.Nil, type.String):Ret(type.String),
		config=type.String,
	}
	local nTable = native._toTable(vManager, package)
	nTable:setName("package")
	return nTable
end

function native.make_math(vManager)
	local type = vManager.type
	local math = {
		random=vManager:checkedFn():Dots(type.Number):Ret(type.Number),
		max=vManager:checkedFn(type.Number):Dots(type.Number):Ret(type.Number),
		min=vManager:checkedFn(type.Number):Dots(type.Number):Ret(type.Number),
		tointeger=vManager:checkedFn(type.Any):Ret(vManager:checkedUnion(type.Number, type.Nil)),
	}
	local nTable = native._toTable(vManager, math)
	nTable:setName("math")
	return nTable
end

function native.make_debug(vManager)
	   
	local type = vManager.type
	local nInfo = vManager:buildStruct(vManager:getRuntime():getNode(), {
		namewhat=type.String,
		isvararg=type.Boolean,
		ntransfer=type.Integer,
		nups=type.Integer,
		currentline=type.Integer,
		func=type.Truth,
		nparams=type.Integer,
		short_src=type.String,
		ftransfer=type.Integer,
		istailcall=type.Boolean,
		lastlinedefined=type.Integer,
		linedefined=type.Integer,
		source=type.String,
		what=type.String,
	})
	local debug = {
		traceback=vManager:checkedFn():Ret(type.String),
		getinfo=vManager:checkedFn(vManager:checkedUnion(vManager.type.Integer, type.AnyFunction)):Ret(nInfo),
	}
	local nTable = native._toTable(vManager, debug)
	nTable:setName("debug")
	return nTable
end

function native.make_io(vManager)
	local type = vManager.type
	local io = {
		read=vManager:checkedFn(vManager:checkedUnion(type.String, type.Number)):Ret(vManager:checkedUnion(type.String, type.Nil)),
		write=vManager:checkedFn(type.String),
		flush=vManager:checkedFn(),
	}
	local nTable = native._toTable(vManager, io)
	nTable:setName("io")
	return nTable
end

function native.make_coroutine(vManager)
	local type = vManager.type
	local nStatusUnion = vManager:checkedUnion(
		vManager:Literal("running"),
		vManager:Literal("suspended"),
		vManager:Literal("normal"),
		vManager:Literal("dead")
	)
	local co = {
		create=vManager:checkedFn(type.AnyFunction):Ret(type.Thread),
		running=vManager:checkedFn():Ret(type.Thread, type.Boolean),
		resume=vManager:checkedFn(type.Thread):Dots(type.Any):Ret(type.True):Ret(type.False,type.String),
		yield=vManager:checkedFn():Ret(type.Truth),
		status=vManager:checkedFn(type.Thread):Ret(nStatusUnion),
	}
	local nTable = native._toTable(vManager, co)
	nTable:setName("coroutine")
	return nTable
end

function native.make_os(vManager)
	local type = vManager.type
	local string = {
		clock=vManager:checkedFn():Ret(type.Number),
		exit=vManager:checkedFn(),
	}
	local nTable = native._toTable(vManager, string)
	nTable:setName("os")
	return nTable
end

function native.make_string(vManager)
	local type = vManager.type
	local string = {
		rep=vManager:checkedFn(type.String, type.Integer, vManager:checkedUnion(type.String, type.Integer, type.Nil)):Ret(type.String),
		upper=vManager:checkedFn(type.String):Ret(type.String),
		format=vManager:checkedFn(type.String):Dots(type.Any):Ret(type.String),
		gmatch=vManager:checkedFn(type.String, type.String):Ret(
			vManager:checkedFn():Ret(vManager:checkedUnion(type.String, type.Nil))
		),
		sub=vManager:checkedFn(type.String, type.Integer, vManager:checkedUnion(type.Integer, type.Nil)):Ret(type.String, type.Integer),
		gsub=vManager:checkedFn(type.String, type.String, type.String):Ret(type.String, type.Integer),
		match=vManager:checkedFn(type.String, type.String):Ret():Ret(type.String),
		find=vManager:checkedFn(type.String, type.String, vManager:checkedUnion(type.Nil, type.Integer), vManager:checkedUnion(type.True, type.Nil)):Ret(type.Nil):Ret(type.Integer, type.Integer),
	}
	local nTable = native._toTable(vManager, string)
	nTable:setName("string")
	return nTable
end

function native.make_table(vManager)
	local function checkList(vContext, vType, vKey)
		
		   
		   
		
			   
			   
				    
				
			
			    
			
		
		 
		  
		return vContext:getTypeManager().type.Never
	end
	local table = {
		sort=vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nFirstTerm = vTermTuple:get(vContext, 1)
			local nType = nFirstTerm:getType()
			checkList(vContext, nType, "sort")
			return vManager:TypeTuple(vContext:getNode()):makeTermTuple(vContext)
		end),
		concat=vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nFirstTerm = vTermTuple:get(vContext, 1)
			local nType = nFirstTerm:getType()
			checkList(vContext, nType, "concat")
			return vContext:FixedTermTuple({vContext:RefineTerm(vManager.type.String)})
		end),
		insert=vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nFirstTerm = vTermTuple:get(vContext, 1)
			local nType = nFirstTerm:getType()
			checkList(vContext, nType, "insert")
			return vContext:FixedTermTuple({})
		end),
		remove=vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nFirstTerm = vTermTuple:get(vContext, 1)
			local nType = nFirstTerm:getType()
			      
			  
			return vContext:FixedTermTuple({})
		end),
		unpack=vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			    
			   
			   
			   
			
				   
				     
					     
					
				
				    
				
			
			   
			 
			return vContext:FixedTermTuple({})
		end),
		move=vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			  
			  
			return vTermTuple:get(vContext, 5)
		end)
	}
	local nTable = native._toTable(vManager, table)
	nTable:setName("table")
	return nTable
end

function native.make_inext(vManager)
	local nNumber = vManager.type.Number
	local nNil = vManager.type.Nil
	return vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
		local nFirstTerm = vTermTuple:get(vContext, 1)
		    
		local nNotNilValue = vContext:getInstStack():META_GET(vContext:getNode(), nFirstTerm, vContext:RefineTerm(nNumber), true):getType()
		local nValueTerm = vContext:RefineTerm(vManager:checkedUnion(nNotNilValue, nNil))
		local nKeyValue  = {
			[nNumber]=nNotNilValue,
			[nNil]=nNil,
		}
		local nTypeCaseList = {}
		for nOneKey, nOneValue in pairs(nKeyValue) do
			local nCase = VariableCase.new()
			nCase:put_and(nValueTerm:attachImmutVariable(), nOneValue)
			nTypeCaseList[#nTypeCaseList + 1] = {
				nOneKey, nCase
			}
		end
		local nKeyTerm = vContext:mergeToRefineTerm(nTypeCaseList)
		return vContext:FixedTermTuple({nKeyTerm, nValueTerm})
	end)
end

function native.make_next(vManager)
	return vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
		local nType1 = vTermTuple:get(vContext, 1):getType()
		nType1 = nType1:trueType()
		local nType2 = vTermTuple:get(vContext, 2):getType()
		if nType1:isUnion() then
			if nType1:isNever() then
				vContext:error("next must take table as first type")
			else
				vContext:error("TODO: next Union type")
			end
			return vContext:FixedTermTuple({vContext:NilTerm(), vContext:NilTerm()})
		else
			local nValueType, nKeyValue = nType1:native_next(vContext, nType2)
			local nValueTerm = vContext:RefineTerm(nValueType)
			local nTypeCaseList = {}
			for nOneKey, nOneValue in pairs(nKeyValue) do
				local nCase = VariableCase.new()
				nCase:put_and(nValueTerm:attachImmutVariable(), nOneValue)
				nTypeCaseList[#nTypeCaseList + 1] = {
					nOneKey, nCase
				}
			end
			local nKeyTerm = vContext:mergeToRefineTerm(nTypeCaseList)
			return vContext:FixedTermTuple({nKeyTerm, nValueTerm})
		end
	end)
end

function native.make_mathematic(vManager)
	local nNumber = vManager.type.Number
	return vManager:checkedFn(nNumber, nNumber):Ret(nNumber)
end

function native.make_comparison(vManager)
	local nNumber = vManager.type.Number
	return vManager:checkedFn(nNumber, nNumber):Ret(vManager.type.Boolean)
end

function native.make_bitwise(vManager)
	local nNumber = vManager.type.Number
	return vManager:checkedFn(nNumber, nNumber):Ret(nNumber)
end

function native.make_concat(vManager)
	local nType = vManager:checkedUnion(vManager.type.String, vManager.type.Number)
	return vManager:checkedFn(nType, nType):Ret(vManager.type.String)
end

return native


end end
--thlua.native end ==========)

--thlua.object.AutoTable begin ==========(
do local _ENV = _ENV
packages['thlua.object.AutoTable'] = function (...)

local StringLiteral = require "thlua.type.StringLiteral"
local TypedObject = require "thlua.object.TypedObject"
local Struct = require "thlua.object.Struct"
local TypedFunction = require "thlua.func.TypedFunction"
local TypedMemberFunction = require "thlua.func.TypedMemberFunction"
local AutoFunction = require "thlua.func.AutoFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local Nil = require "thlua.type.Nil"

local SealTable = require "thlua.object.SealTable"
local class = require "thlua.class"


	  


local AutoTable = class (SealTable)

function AutoTable:ctor(vManager, ...)
	self._name = false 
	self._firstAssign = false
	self._castDict = {}   
	self._locked = false
end

function AutoTable:detailString(v, vVerbose)
	if not self._firstAssign then
		return "AutoTable@castable@"..tostring(self._node)
	elseif next(self._castDict) then
		return "AutoTable@casted@"..tostring(self._node)
	else
		return "AutoTable@"..tostring(self._node)
	end
end

function AutoTable:setName(vName)
	self._name = vName
end

function AutoTable:castMatchOne(
	vContext,
	vStruct
)
	local nAutoFnCastDict = vContext:newAutoFnCastDict()
	local nCopyValueDict = vStruct:copyValueDict(self)
	local nMatchSucc = true
	self._keyType:foreach(function(vTableKey)
		local vTableValue = self._fieldDict[vTableKey].valueType
		if not nMatchSucc then
			return
		end
		local nMatchKey, nMatchValue = vStruct:indexKeyValue(vTableKey)
		if not nMatchKey then
			nMatchSucc = false
			return
		end
		nMatchValue = nMatchValue:checkAtomUnion()
		if TypedMemberFunction.is(nMatchValue) then
			        
			nMatchValue=nMatchValue:indexTypeFn(vStruct)
		end
		local nIncludeType, nCastSucc = vContext:tryIncludeCast(nAutoFnCastDict, nMatchValue, vTableValue)
		if not nIncludeType or not nCastSucc then
			nMatchSucc = false
			return
		end
		nCopyValueDict[nMatchKey] = nil
	end)
	if not nMatchSucc then
		return false
	end
	for k,v in pairs(nCopyValueDict) do
		if not v:checkAtomUnion():isNilable() then
			return false
		end
	end
	return nAutoFnCastDict
end

function AutoTable:checkTypedObject()
	return self._manager.type.AnyObject
end

function AutoTable:isCastable()
	return not self._firstAssign
end

function AutoTable:setAssigned(vContext)
	if not self._firstAssign then
		if next(self._castDict) then
			vContext:error("AutoTable is casted to some TypedObject")
		end
		self._firstAssign = vContext
		for k, v in pairs(self._fieldDict) do
			v.valueType:setAssigned(vContext)
		end
	end
end

function AutoTable:findRequireStack()
	return self._lexStack:findRequireStack()
end

function AutoTable:setLocked()
	self._locked = true
end

function AutoTable:isLocked()
	return self._locked
end

return AutoTable

end end
--thlua.object.AutoTable end ==========)

--thlua.object.BaseObject begin ==========(
do local _ENV = _ENV
packages['thlua.object.BaseObject'] = function (...)

local Exception = require "thlua.Exception"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local StringLiteral = require "thlua.type.StringLiteral"
local Nil = require "thlua.type.Nil"
local TypedFunction = require "thlua.func.TypedFunction"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"


	  


local BaseObject = class (BaseAtomType)

function BaseObject:ctor(vManager, vNode, ...)
	self.bits=TYPE_BITS.OBJECT
	self._metaEventCom=false
	self._node=vNode
end

function BaseObject:getMetaEventCom()
	return self._metaEventCom
end

function BaseObject:detailString(v, vVerbose)
	return "BaseObject..."
end

function BaseObject:meta_uop_some(vContext, vOper)
	vContext:error("meta uop not implement:")
	return self._manager.type.Never
end

function BaseObject:meta_bop_func(vContext, vOper)
	vContext:error("meta bop not implement:")
	return false, nil
end

function BaseObject:isSingleton()
	return false
end

function BaseObject:native_type()
	return self._manager:Literal("table")
end

function BaseObject:getValueDict() 
	error("not implement")
end

function BaseObject:memberFunctionFillSelf(vChain, vSelfTable)
	error("TODO base object as __index")
end

return BaseObject

end end
--thlua.object.BaseObject end ==========)

--thlua.object.ClassTable begin ==========(
do local _ENV = _ENV
packages['thlua.object.ClassTable'] = function (...)

local VariableCase = require "thlua.term.VariableCase"
local StringLiteral = require "thlua.type.StringLiteral"
local TypedFunction = require "thlua.func.TypedFunction"
local AutoMemberFunction = require "thlua.func.AutoMemberFunction"
local AutoFunction = require "thlua.func.AutoFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local RecurChain = require "thlua.context.RecurChain"
local Nil = require "thlua.type.Nil"

local SealTable = require "thlua.object.SealTable"
local class = require "thlua.class"


	  


local ClassTable = class (SealTable)

function ClassTable:ctor(
	vManager,
	vNode,
	vLexStack,
	vFactory
)
	self._factory = vFactory
	local nTask = self._manager:getScheduleManager():newTask()
	self._task = nTask
	self._initEvent = nTask:makeEvent()
	self._baseClass = false
	self._interface = nil
	self._buildFinish = false
end

function ClassTable:detailString(v, vVerbose)
	return "ClassTable@"..tostring(self._node)
end

function ClassTable:waitInit()
	self._initEvent:wait()
end

function ClassTable:initAsync(vBaseGetter )
	self._task:runAsync(function()
		self._baseClass, self._interface = vBaseGetter()
		self._initEvent:wakeup()
	end)
end

function ClassTable:onSetMetaTable(vContext)
	self._factory:wakeupTableBuild()
	self:onBuildFinish()
end

function ClassTable:onBuildFinish()
	if not self._buildFinish then
		self._buildFinish = true
		self:implInterface()
		local nRecurChain = RecurChain.new()
		self:memberFunctionFillSelf(nRecurChain, self)
		self._factory:wakeupTableBuild()
	end
end

function ClassTable:implInterface()
	local nInterfaceKeyValue = self._interface:copyValueDict(self)
	local nSelfKey = self._keyType
	local nSelfFieldDict = self._fieldDict
	for nKeyAtom, nValue in pairs(nInterfaceKeyValue) do
		local nContext = self._factory:getBuildStack():withOnePushContext(self._factory:getNode(), function(vSubContext)
			vSubContext:withCase(VariableCase.new(), function()
				self:meta_get(vSubContext, nKeyAtom)
			end)
		end)
		local nSelfValue = nContext:mergeFirst():getType()
		if AutoMemberFunction.is(nSelfValue) then
			if TypedFunction.is(nValue) then
				nSelfValue:indexAutoFn(self):checkWhenCast(nValue)
			end
		else
			if not nValue:includeAll(nSelfValue) then
				nContext:error("interface's field must be supertype for table's field, key="..tostring(nKeyAtom))
			end
		end
	end
	
	   
	     
		   
		  
			   
				
			
		  
		
	
end

function ClassTable:ctxWait(vContext)
	self._factory:waitTableBuild()
end

function ClassTable:getBaseClass()
	return self._baseClass
end

function ClassTable:getInterface()
	return self._interface
end

function ClassTable:checkTypedObject()
	return self._interface
end

function ClassTable:assumeIncludeAtom(vAssumeSet, vType, _)
	if ClassTable.is(vType) then
		local nMatchTable = vType
		while nMatchTable ~= self do
			local nBaseClass = nMatchTable:getBaseClass()
			if not nBaseClass then
				break
			else
				nMatchTable = nBaseClass
			end
		end
		return nMatchTable == self and self or false
	else
		   
		return false
	end
end

function ClassTable:isLocked()
	return self._buildFinish
end

return ClassTable

end end
--thlua.object.ClassTable end ==========)

--thlua.object.Interface begin ==========(
do local _ENV = _ENV
packages['thlua.object.Interface'] = function (...)

local TypedObject = require "thlua.object.TypedObject"
local class = require "thlua.class"


	  


local Interface = class (TypedObject)

function Interface:ctor(...)
end

function Interface:detailString(vToStringCache, vVerbose)
	return "interface@"..tostring(self._node)
end

function Interface:assumeIncludeObject(vAssumeSet , vRightObject)
	if vRightObject._intersectSet[self] then
		return true
	end
	local nRightKeyRefer, nRightNextKey = vRightObject:getKeyTypes()
	local nLeftNextKey = self._nextKey
	if nLeftNextKey then
		if not nRightNextKey then
			return false
		end
		if not nLeftNextKey:assumeIncludeAll(vAssumeSet, nRightNextKey) then
			return false
		end
	end
	local nRightValueDict = vRightObject:getValueDict()
	local nRightResultType = nRightKeyRefer:getResultType()
	return self:_everyWith(vRightObject, function(vLeftKey, vLeftValue)
		if nRightResultType then        
			local nRightKey = nRightResultType:assumeIncludeAtom(vAssumeSet, vLeftKey)
			if not nRightKey then
				return false
			end
			local nRightValue = nRightValueDict[nRightKey]
			if not nRightValue then
				return false
			end
			return vLeftValue:assumeIncludeAll(vAssumeSet, nRightValue, vRightObject) and true
		else         
			for _, nRightMoreKey in ipairs(nRightKeyRefer:getListAwait()) do
				if nRightMoreKey:assumeIncludeAtom(vAssumeSet, vLeftKey) then
					local nRightValue = nRightValueDict[nRightMoreKey]
					if nRightValue and vLeftValue:assumeIncludeAll(vAssumeSet, nRightValue, vRightObject) then
						return true
					end
				end
			end
			return false
		end
	end)
end

function Interface:assumeIntersectAtom(vAssumeSet, vRightType)
	if not Interface.is(vRightType) then
		if self == vRightType then
			return self
		elseif vRightType:assumeIncludeAtom(nil, self) then
			return self
		elseif self:assumeIncludeAtom(nil, vRightType) then
			return vRightType
		else
			return false
		end
	end
	if self == vRightType then
		return self
	end
	local nRightStruct = vRightType
	local nMgr = self._manager
	local nRelation = nMgr:attachPairRelation(self, nRightStruct, not vAssumeSet)
	if nRelation then
		if nRelation == ">" then
			return vRightType
		elseif nRelation == "<" then
			return self
		elseif nRelation == "=" then
			return self
		elseif nRelation == "&" then
			return true
		else
			return false
		end
	end
	assert(vAssumeSet, "assume set must be existed here")
	local _, nLRPair, nRLPair = self._manager:makeDuPair(self, nRightStruct)
	local nAssumeResult = vAssumeSet[nLRPair]
	if nAssumeResult ~= nil then
		return nAssumeResult and self
	end
	vAssumeSet[nLRPair] = true
	vAssumeSet[nRLPair] = true
	local nAssumeIntersect = self:assumeIntersectInterface(vAssumeSet, nRightStruct)
	if not nAssumeIntersect then
		vAssumeSet[nLRPair] = false
		vAssumeSet[nRLPair] = false
		return false
	else
		return true
	end
end

function Interface:assumeIntersectInterface(vAssumeSet , vRightObject)
	local nRightValueDict = vRightObject:getValueDict()
	local nRightKeyRefer, nRightNextKey = vRightObject:getKeyTypes()
	local nRightResultType = nRightKeyRefer:getResultType()
	return self:_everyWith(vRightObject, function(vLeftKey, vLeftValue)
		if nRightResultType then        
			local nRightKey = nRightResultType:assumeIncludeAtom(vAssumeSet, vLeftKey)
			if not nRightKey then
				return true
			end
			local nRightValue = nRightValueDict[nRightKey]
			if vLeftValue:assumeIntersectSome(vAssumeSet, nRightValue) then
				return true
			else
				return false
			end
		else
			for _, nRightKey in ipairs(nRightKeyRefer:getListAwait()) do
				if nRightKey:assumeIncludeAtom(vAssumeSet, vLeftKey) then
					local nRightValue = nRightValueDict[nRightKey]
					if vLeftValue:assumeIntersectSome(vAssumeSet, nRightValue) then
						return true
					end
				end
			end
			return false
		end
	end)
end

function Interface:meta_set(vContext, vKeyType, vValueType)
	vContext:error("interface is readonly")
end

function Interface:native_rawset(vContext, vKeyType, vValueType)
	vContext:error("interface is readonly")
end

return Interface

end end
--thlua.object.Interface end ==========)

--thlua.object.MetaEventCom begin ==========(
do local _ENV = _ENV
packages['thlua.object.MetaEventCom'] = function (...)

local Reference = require "thlua.refer.Reference"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local Nil = require "thlua.type.Nil"
local TypedFunction = require "thlua.func.TypedFunction"
local AutoFunction = require "thlua.func.AutoFunction"
local AutoMemberFunction = require "thlua.func.AutoMemberFunction"
local class = require "thlua.class"


	  
	   
		
		
	


local MetaEventCom = {}
MetaEventCom.__index=MetaEventCom

function MetaEventCom.new(vManager, vSelfType )
	local self = setmetatable({
		_manager=vManager,
		_selfType=vSelfType,
		_bopEq=false,
		_bopDict={} ,
		_uopLen=false,
		_uopDict=false,    
		 
		_pairs=false,
		_ipairs=false,
		_tostring=false,
		_mode=false,
		_call=false,   
		_metatable=false,
		_gc=false,
		_name=false,
		_close=false,
	}, MetaEventCom)
	return self
end

function MetaEventCom:getBopFunc(vBopEvent)
	local nField = self._bopDict[vBopEvent]
	return nField and (nField.typeFn or nField.autoFn:getFnAwait())
end

function MetaEventCom:getLenType()
	return self._uopLen
end

function MetaEventCom:getPairsFunc()
	local nField = self._pairs
	return nField and (nField.typeFn or nField.autoFn:getFnAwait())
end

local function buildFieldFromFn(vContext, vEvent, vMethodFn,
	vTypeFnOrNil)
	if vMethodFn:isUnion() then
		vContext:error("meta method can't be union type, event:"..vEvent)
		return nil
	elseif TypedFunction.is(vMethodFn) then
		return {
			typeFn=vMethodFn
		}
	elseif AutoMemberFunction.is(vMethodFn) then
		if vTypeFnOrNil then
			local nSelfType = vTypeFnOrNil:getParTuple():get(1)
			local nAutoFn = vMethodFn:indexAutoFn(nSelfType)
			nAutoFn:checkWhenCast(vTypeFnOrNil)
			return {
				typeFn=vTypeFnOrNil,
			}
		else
			vContext:error("member function cast to type fn in meta field TODO")
			return nil
		end
	elseif AutoFunction.is(vMethodFn) then
		if vTypeFnOrNil then
			vMethodFn:checkWhenCast(vTypeFnOrNil)
			return {
				typeFn=vTypeFnOrNil,
			}
		else
			return {
				autoFn=vMethodFn
			}
		end
	elseif not Nil.is(vMethodFn) then
		vContext:error("meta method type must be function or nil, event:"..vEvent)
	end
	return nil
end

function MetaEventCom:initByTable(vContext, vMetaTable )
	local nSelfType = self._selfType
	local nManager = self._manager
	   
	for nOper, nEvent in pairs(OPER_ENUM.bopNoEq) do
		local nMethodType = vMetaTable:native_rawget(vContext, nManager:Literal(nEvent))
		self._bopDict[nEvent] = buildFieldFromFn(vContext, nEvent, nMethodType)
	end
	local nEqFn = vMetaTable:native_rawget(vContext, nManager:Literal("__eq"))
	if not Nil.is(nEqFn) then
		vContext:error("TODO meta logic for bop __eq", tostring(nEqFn))
	end
	   
	local nLenFn = vMetaTable:native_rawget(vContext, nManager:Literal("__len"))
	local nLenTypeFn = nManager:checkedFn(nSelfType):Ret(nManager.type.Integer)
	local nLenField = buildFieldFromFn(vContext, "__len", nLenFn, nLenTypeFn)
	if nLenField then
		self._uopLen = nManager.type.Integer
		       
		   
	end
	   
	  
	local nStringTypeFn = nManager:checkedFn(nSelfType):Ret(nManager.type.String)
	local nStringFn = vMetaTable:native_rawget(vContext, nManager:Literal("__tostring"))
	self._tostring = buildFieldFromFn(vContext, "__tostring", nStringFn, nStringTypeFn) or false
	  
	local nPairsFn = vMetaTable:native_rawget(vContext, nManager:Literal("__pairs"))
	self._pairs = buildFieldFromFn(vContext, "__pairs", nPairsFn) or false
end

local function buildFieldFromAllType(vEvent, vTypeFn)
	if not vTypeFn then
		return nil
	end
	if Reference.is(vTypeFn) then
		vTypeFn = vTypeFn:waitTypeCom():getTypeAwait()
	end
	if not TypedFunction.is(vTypeFn) then
		error("meta field "..vEvent.." must be single type-function")
	else
		return {
			typeFn=vTypeFn
		}
	end
end

function MetaEventCom:initByEventDict(vActionDict )
	local nManager = self._manager
	   
	for nOper, nEvent in pairs(OPER_ENUM.bopNoEq) do
		self._bopDict[nEvent] = buildFieldFromAllType(nEvent, vActionDict[nEvent])
	end
	if vActionDict["__eq"] then
		print("__eq in action table TODO")
	end
	   
	local nLenType = vActionDict["__len"]
	if nLenType then
		nLenType = nLenType:checkAtomUnion()
		if not nManager.type.Integer:includeAll(nLenType) then
			error("len type must be subtype of Integer")
		end
		self._uopLen = nLenType
	end
	 
	self._pairs = buildFieldFromAllType("__pairs", vActionDict["__pairs"]) or false
	self._ipairs = buildFieldFromAllType("__ipairs", vActionDict["__ipairs"]) or false
end

function MetaEventCom:mergeField(
	vEvent,
	vComList,
	vFieldGetter)
	local nRetField = false
	for _, vCom in ipairs(vComList) do
		local nField = vFieldGetter(vCom)
		if nField then
			if nRetField then
				error("meta field conflict when merge, field:"..vEvent)
			else
				nRetField = nField
			end
		end
	end
	return nRetField
end

function MetaEventCom:initByMerge(vComList)
	self._pairs = self:mergeField("__pairs", vComList, function(vCom)
		return vCom._pairs
	end)
	self._ipairs = self:mergeField("__ipairs", vComList, function(vCom)
		return vCom._ipairs
	end)
	for nOper, nEvent in pairs(OPER_ENUM.bopNoEq) do
		self._bopDict[nEvent] = self:mergeField(nEvent, vComList, function(vCom)
			return vCom._bopDict[nEvent] or false
		end) or nil
	end
	local nFinalUopLen = false
	for _, vCom in ipairs(vComList) do
		local nUopLen = vCom._uopLen
		if nUopLen then
			if nFinalUopLen then
				error("__len conflict in meta when merge")
			else
				nFinalUopLen = nUopLen
			end
		end
	end
	self._uopLen = nFinalUopLen
end

return MetaEventCom

end end
--thlua.object.MetaEventCom end ==========)

--thlua.object.OpenTable begin ==========(
do local _ENV = _ENV
packages['thlua.object.OpenTable'] = function (...)

local StringLiteral = require "thlua.type.StringLiteral"
local TypedObject = require "thlua.object.TypedObject"
local BaseFunction = require "thlua.func.BaseFunction"
local AutoMemberFunction = require "thlua.func.AutoMemberFunction"
local Nil = require "thlua.type.Nil"

local BaseObject = require "thlua.object.BaseObject"
local class = require "thlua.class"


	  
	   
		  
		  
		  
	


local OpenTable = class (BaseObject)

function OpenTable:ctor(vManager, vNode, vLexStack)
	self._keyType=vManager.type.Never 
	self._lexStack = vLexStack
	self._fieldDict={} 
	self._metaIndex=false 
	self._metaNewIndex=false 
	self._nextValue=false 
	self._nextDict=false  
	self._metaTable=false 
	self._locked=false
end

function OpenTable:detailString(v, vVerbose)
	return "OpenTable@"..tostring(self._node)
end

function OpenTable:meta_len(vContext)
	 
	return self._manager.type.Number
end

function OpenTable:initByKeyValueTerm(vNode, vBranch, vKeyType, vValueDict )
	self._keyType = vKeyType
	for k,v in pairs(vValueDict) do
		self._fieldDict[k] = {
			valueTerm = v,
			branch=vBranch,
			lockCtx = false,
		}
	end
end

function OpenTable:native_getmetatable(vContext)
	return self._metaTable or self._manager.type.Nil
end

function OpenTable:native_setmetatable(vContext, vMetaTableType)
	if self._metaTable then
		vContext:error("can only setmetatable once for one table")
		return
	end
	self._metaTable = vMetaTableType
	             
	      
	   
	 
	  
	     
	local nManager = self._manager
	   
	local nIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__index"))
	if nIndexType:isUnion() then
		vContext:error("open table's __index can't be union type")
	else
		if BaseFunction.is(nIndexType) or BaseObject.is(nIndexType) then
			self._metaIndex = nIndexType
		elseif not Nil.is(nIndexType) then
			vContext:error("open table's __index must be object or function or nil")
		end
	end
	   
	local nNewIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__newindex"))
	if nNewIndexType:isUnion() then
		vContext:error("open table's __newindex can't be union type")
	else
		if BaseFunction.is(nNewIndexType) or BaseObject.is(nNewIndexType) then
			self._metaNewIndex = nNewIndexType
		elseif not Nil.is(nNewIndexType) then
			vContext:error("open table's __newindex must be object or function or nil")
		end
	end
end

function OpenTable:meta_set(vContext, vKeyType, vValueTerm)
	local nNotRecursive, nOkay = vContext:recursiveChainTestAndRun(self, function()
		if not vKeyType:isSingleton() then
			vContext:error("open table's key must be singleton type")
		elseif vKeyType:isNilable() then
			vContext:error("open table's key can't be nil")
		else
			local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
			if nKeyIncludeType then
				local nField = self._fieldDict[nKeyIncludeType]
				if nField.lockCtx then
					vContext:error("field is locked"..tostring(vKeyType))
				else
					vContext:addLookupNode(nField.valueTerm:getNode(), nField.valueTerm:getType())
					local nTopBranch = vContext:getStack():topBranch()
					if nField.branch == nTopBranch then
						vContext:warn("field:"..tostring(nKeyIncludeType).." multi assign in one scope")
					end
					nField.valueTerm = vValueTerm
					nField.branch = nTopBranch
				end
			else
				local nMetaNewIndex = self._metaNewIndex
				if BaseFunction.is(nMetaNewIndex) then
					local nTermTuple = vContext:FixedTermTuple({
						vContext:RefineTerm(self), vContext:RefineTerm(vKeyType), vValueTerm
					})
					nMetaNewIndex:meta_call(vContext, nTermTuple)
				elseif BaseObject.is(nMetaNewIndex) then
					nMetaNewIndex:meta_set(vContext, vKeyType, vValueTerm)
				else
					self:native_rawset(vContext, vKeyType, vValueTerm)
				end
			end
		end
		return true
	end)
	if nNotRecursive then
		  
	else
		error("opentable's __newindex chain recursive")
	end
end

local NIL_TRIGGER = 1
local NONE_TRIGGER = 2
function OpenTable:meta_get(vContext, vKeyType)
	local nNotRecursive, nOkay = vContext:recursiveChainTestAndRun(self, function()
		    
		local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
		local nTrigger = false
		if nKeyIncludeType then
			local nField = self._fieldDict[nKeyIncludeType]
			local nTerm = nField.valueTerm
			vContext:addLookupNode(nTerm:getNode(), nTerm:getType())
			nField.lockCtx = vContext
			local nType = nTerm:getType()
			if nType:isUnion() then
				vContext:warn("open table's field is union")
			end
			vContext:pushFirstAndTuple(nType)
			if nType:isNilable() then
				nTrigger = NIL_TRIGGER
			end
		else
			nTrigger = NONE_TRIGGER
		end
		if nTrigger then
			local nMetaIndex = self._metaIndex
			if BaseFunction.is(nMetaIndex) then
				local nTermTuple = vContext:FixedTermTuple({vContext:RefineTerm(self), vContext:RefineTerm(vKeyType)})
				nMetaIndex:meta_call(vContext, nTermTuple)
				return true
			elseif BaseObject.is(nMetaIndex) then
				local nNextOkay = nMetaIndex:meta_get(vContext, vKeyType)
				return nTrigger ~= NONE_TRIGGER or nNextOkay
			else
				vContext:pushFirstAndTuple(self:native_rawget(vContext, vKeyType))
				return nTrigger ~= NONE_TRIGGER
			end
		else
			return true
		end
	end)
	if nNotRecursive then
		return nOkay
	else
		error("opentable's __index chain recursive")
	end
end

function OpenTable:native_rawset(vContext, vKeyType, vValueTerm)
	vContext:openAssign(vValueTerm:getType())
	local nIncludeType = self._keyType:includeAtom(vKeyType)
	if not nIncludeType then
		if vKeyType:isSingleton() and not vKeyType:isNilable() then
			   
			if self._locked then
				vContext:error("assign to locked open-table")
				return
			end
			self._keyType = self._manager:checkedUnion(self._keyType, vKeyType)
			self._fieldDict[vKeyType] = {
				valueTerm = vValueTerm,
				branch = vContext:getStack():topBranch(),
				lockCtx = false,
			}
		else
			vContext:error("set("..tostring(vKeyType)..","..tostring(vValueTerm:getType())..") error")
		end
	else
		if self._locked then
			vContext:error("assign to locked open-table")
			return
		end
		self._fieldDict[nIncludeType] = {
			valueTerm = vValueTerm,
			branch = vContext:getStack():topBranch(),
			lockCtx = false,
		}
	end
end

function OpenTable:native_rawget(vContext, vKeyType)
	local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
	if nKeyIncludeType then
		local nField = self._fieldDict[nKeyIncludeType]
		local nTerm = nField.valueTerm
		vContext:addLookupNode(nTerm:getNode(), nTerm:getType())
		nField.lockCtx = vContext
		return nTerm:getType()
	else
		local nNil = self._manager.type.Nil
		if not self._locked then
			self._fieldDict[vKeyType] = {
				valueTerm=vContext:RefineTerm(nNil),
				branch=vContext:getStack():topBranch(),
				lockCtx=vContext
			}
		end
		return nNil
	end
end

function OpenTable:native_next(vContext, vInitType)
	self._locked = true
	local nNextDict = self._nextDict
	local nValueType = self._nextValue
	if not nNextDict or not nValueType then
		nNextDict = {}
		for nKeyAtom, nField in pairs(self._fieldDict) do
			nNextDict[nKeyAtom] = nField.valueTerm:getType()
		end
		local nNil = self._manager.type.Nil
		local nCollection = self._manager:TypeCollection()
		for nOneKey, nOneField in pairs(self._fieldDict) do
			local nValueType = nOneField.valueTerm:getType()
			local nNotnilType = nValueType:notnilType()
			if not nNotnilType:isNever() then
				nNextDict[nOneKey] = nNotnilType
				nCollection:put(nNotnilType)
			end
			nOneField.lockCtx = nOneField.lockCtx or vContext
		end
		nCollection:put(nNil)
		nValueType = nCollection:mergeToAtomUnion()
		nNextDict[nNil] = nNil
		self._nextValue = nValueType
		self._nextDict = nNextDict
	end
	return nValueType, nNextDict
end

function OpenTable:meta_pairs(vContext)
	
	   
	  
		   
		  
			      
		
	
	return false
end

function OpenTable:meta_ipairs(vContext)
	vContext:error("TODO:open table use __ipairs as meta field")
	return false
end

function OpenTable:memberFunctionFillSelf(vChain, vSelfTable)
	local nNotRecursive = vChain:testAndRun(self, function()
		for _, nField in pairs(self._fieldDict) do
			local nSelfValue = nField.valueTerm:getType()
			if AutoMemberFunction.is(nSelfValue) then
				if not nSelfValue:needPolyArgs() then
					nSelfValue:indexAutoFn(vSelfTable)
				end
			end
		end
		return true
	end)
	if nNotRecursive then
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			if BaseObject.is(nMetaIndex) then
				nMetaIndex:memberFunctionFillSelf(vChain, vSelfTable)
			end
		end
	end
end

function OpenTable:getValueDict() 
	local nDict  = {}
	self._keyType:foreach(function(vType)
		nDict[vType] = self._fieldDict[vType].valueTerm:getType()
	end)
	return nDict
end

function OpenTable:putCompletion(vCompletion)
	if vCompletion:testAndSetPass(self) then
		self._keyType:foreach(function(vType)
			if StringLiteral.is(vType) then
				vCompletion:putPair(vType:getLiteral(), self._fieldDict[vType].valueTerm:getType())
			end
		end)
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			nMetaIndex:putCompletion(vCompletion)
		end
	end
end

function OpenTable:findRequireStack()
	return self._lexStack:findRequireStack()
end

function OpenTable:isSingleton()
	return true
end

function OpenTable:setLocked()
	self._locked = true
end

function OpenTable:isLocked()
	return self._locked
end

return OpenTable

end end
--thlua.object.OpenTable end ==========)

--thlua.object.SealTable begin ==========(
do local _ENV = _ENV
packages['thlua.object.SealTable'] = function (...)

local StringLiteral = require "thlua.type.StringLiteral"
local TypedObject = require "thlua.object.TypedObject"
local TypedFunction = require "thlua.func.TypedFunction"
local AutoMemberFunction = require "thlua.func.AutoMemberFunction"
local AutoFunction = require "thlua.func.AutoFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local Nil = require "thlua.type.Nil"

local BaseObject = require "thlua.object.BaseObject"
local class = require "thlua.class"


	  
	   
		  
		  
	


local SealTable = class (BaseObject)

function SealTable:ctor(vManager, vNode, vLexStack, ...)
	self._lexStack = vLexStack
	self._keyType=vManager.type.Never 
	self._fieldDict={} 
	self._nextValue=false 
	self._nextDict=false  
	self._metaTable=false 
	self._metaIndex=false
	self._newIndexType=false
end

function SealTable:meta_len(vContext)
	 
	return self._manager.type.Number
end

function SealTable:ctxWait(vContext)
end

function SealTable:initByKeyValue(vNode, vKeyType, vValueDict )
	self._keyType = vKeyType
	for k,v in pairs(vValueDict) do
		self._fieldDict[k] = {
			valueType = v,
			assignNode = vNode,
		}
	end
end

function SealTable:onSetMetaTable(vContext)
end

function SealTable:native_setmetatable(vContext, vMetaTableType)
	if self._metaTable then
		vContext:error("can only setmetatable once for one table")
		return
	end
	self._metaTable = vMetaTableType
	     
	assert(not self._metaEventCom, "meta event has been setted")
	local nMetaEventCom = self._manager:makeMetaEventCom(self)
	nMetaEventCom:initByTable(vContext, vMetaTableType)
	self._metaEventCom = nMetaEventCom
	     
	local nManager = self._manager
	local nIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__index"))
	local nNewIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__newindex"))
	    
	self:setMetaIndex(
		vContext,
		not nIndexType:isNever() and nIndexType or false,
		not nNewIndexType:isNever() and nNewIndexType or false)
	    
	self:onSetMetaTable(vContext)
end

function SealTable:meta_set(vContext, vKeyType, vValueTerm)
	self:ctxWait(vContext)
	local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
	if nKeyIncludeType then
		vContext:pushNothing()
		local nTableField = self._fieldDict[nKeyIncludeType]
		local nFieldType = nTableField.valueType
		vContext:includeAndCast(nFieldType, vValueTerm:getType(), "set")
	else
		self:native_rawset(vContext, vKeyType, vValueTerm)
	end
end

local NIL_TRIGGER = 1
local NONE_TRIGGER = 2
function SealTable:meta_get(vContext, vKeyType)
	self:ctxWait(vContext)
	local nNotRecursive, nOkay = vContext:recursiveChainTestAndRun(self, function()
		local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
		local nIndexType = self._metaIndex
		local nTrigger = false
		if nKeyIncludeType then
			local nField = self._fieldDict[nKeyIncludeType]
			vContext:addLookupNode(nField.assignNode, nField.valueType)
			local nValueType = nField.valueType
			if nValueType:isNilable() then
				nTrigger = NIL_TRIGGER
				if nIndexType then
					vContext:pushFirstAndTuple(nValueType:notnilType())
				else
					vContext:pushFirstAndTuple(nValueType)
				end
			else
				vContext:pushFirstAndTuple(nValueType)
			end
		else
			nTrigger = NONE_TRIGGER
			local nInterType = self._keyType:safeIntersect(vKeyType)
			if not nInterType then
				vContext:error("unexpected intersect when table get")
			else
				nInterType:foreach(function(vKeyAtom)
					local nField = self._fieldDict[vKeyAtom]
					vContext:addLookupNode(nField.assignNode, nField.valueType)
					local nValueType = nField.valueType
					if nIndexType then
						vContext:pushFirstAndTuple(nValueType:notnilType())
					else
						vContext:pushFirstAndTuple(nValueType)
					end
				end)
			end
			if not nIndexType then
				vContext:pushFirstAndTuple(self._manager.type.Nil)
			end
		end
		local nOkay = nTrigger ~= NONE_TRIGGER
		if nTrigger and nIndexType then
			if BaseObject.is(nIndexType) then
				local nNextOkay = nIndexType:meta_get(vContext, vKeyType)
				nOkay = nOkay or nNextOkay
			elseif BaseFunction.is(nIndexType) then
				local nTermTuple = vContext:FixedTermTuple({vContext:RefineTerm(self), vContext:RefineTerm(vKeyType)})
				nIndexType:meta_call(vContext, nTermTuple)
				nOkay = true
			end
		end
		return nOkay
	end)
	if nNotRecursive then
		return nOkay
	else
		vContext:pushFirstAndTuple(self._manager.type.Nil)
		return false
	end
end

function SealTable:native_rawset(vContext, vKeyType, vValueTerm)
	self:ctxWait(vContext)
	vContext:openAssign(vValueTerm:getType())
	local nIncludeType = self._keyType:includeAtom(vKeyType)
	if not nIncludeType then
		if vKeyType:isSingleton() and not vKeyType:isNilable() then
			if self:isLocked() then
				vContext:error("table is locked")
				return
			else
				if self._lexStack:getSealStack() ~= vContext:getStack():getSealStack() then
					vContext:error("table new field in wrong scope")
					return
				end
			end
			      
			self._keyType = self._manager:checkedUnion(self._keyType, vKeyType)
			self._fieldDict[vKeyType] = {
				valueType = vValueTerm:getType(),
				assignNode = vContext:getNode(),
			}
		else
			vContext:error("set("..tostring(vKeyType)..","..tostring(vValueTerm:getType())..") error")
		end
	else
		local nTableField = self._fieldDict[nIncludeType]
		local nFieldType = nTableField.valueType
		vContext:addLookupNode(nTableField.assignNode, nTableField.valueType)
		if not nFieldType:includeAll(vValueTerm:getType()) then
			vContext:error("wrong value type when set, key:"..tostring(nIncludeType))
		end
	end
end

function SealTable:native_rawget(vContext, vKeyType)
	self:ctxWait(vContext)
	local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
	if nKeyIncludeType then
		local nField = self._fieldDict[nKeyIncludeType]
		vContext:addLookupNode(nField.assignNode, nField.valueType)
		return nField.valueType
	else
		return self._manager.type.Nil
	end
end

function SealTable:meta_ipairs(vContext)
	self:ctxWait(vContext)
	return false
end

function SealTable:meta_pairs(vContext)
	self:ctxWait(vContext)
	local nCom = self._metaEventCom
	if nCom then
		local nPairsFn = nCom:getPairsFunc()
		if nPairsFn then
			print("meta_pairs TODO")
		end
	else
		return false
	end
end

function SealTable:setMetaIndex(vContext, vIndexType, vNewIndexType)
	if not vIndexType then
		return
	end
	if vIndexType:isUnion() then
		vContext:info("union type as __index TODO")
		return
	end
	if vIndexType:isNilable() then
		vContext:info("TODO, impl interface if setmetatable without index")
		return
	end
	self._metaIndex = vIndexType
end

function SealTable:native_next(vContext, vInitType)
	self:ctxWait(vContext)
	local nNextDict = self._nextDict
	local nValueType = self._nextValue
	if not nNextDict or not nValueType then
		nNextDict = {}
		for nKeyAtom, nField in pairs(self._fieldDict) do
			nNextDict[nKeyAtom] = nField.valueType
		end
		local nNil = self._manager.type.Nil
		local nCollection = self._manager:TypeCollection()
		for nOneKey, nOneField in pairs(self._fieldDict) do
			local nValueType = nOneField.valueType
			local nNotnilType = nValueType:notnilType()
			nNextDict[nOneKey] = nNotnilType
			nCollection:put(nNotnilType)
		end
		nCollection:put(nNil)
		nValueType = nCollection:mergeToAtomUnion()
		nNextDict[nNil] = nNil
		self._nextValue = nValueType
		self._nextDict = nNextDict
	end
	return nValueType, nNextDict
end

function SealTable:native_getmetatable(vContext)
	self:ctxWait(vContext)
	return self._metaTable or self._manager.type.Nil
end

function SealTable:meta_uop_some(vContext, vOper)
	self:ctxWait(vContext)
	vContext:error("meta uop TODO:"..tostring(vOper))
	return self._manager.type.Never
end

function SealTable:meta_bop_func(vContext, vOper)
	self:ctxWait(vContext)
	local nMethodEvent = OPER_ENUM.bopNoEq[vOper]
	local nCom = self._metaEventCom
	if nCom then
		local nMethodFn = nCom:getBopFunc(nMethodEvent)
		if nMethodFn then
			return true, nMethodFn
		end
	end
	return false, nil
end

function SealTable:memberFunctionFillSelf(vChain, vSelfTable)
	local nNotRecursive = vChain:testAndRun(self, function()
		for _, nField in pairs(self._fieldDict) do
			local nSelfValue = nField.valueType
			if AutoMemberFunction.is(nSelfValue) then
				if not nSelfValue:needPolyArgs() then
					nSelfValue:indexAutoFn(vSelfTable)
				end
			end
		end
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			if BaseObject.is(nMetaIndex) then
				nMetaIndex:memberFunctionFillSelf(vChain, vSelfTable)
			end
		end
		return true
	end)
end

function SealTable:getValueDict() 
	local nDict  = {}
	self._keyType:foreach(function(vType)
		nDict[vType] = self._fieldDict[vType].valueType
	end)
	return nDict
end

function SealTable:putCompletion(vCompletion)
	if vCompletion:testAndSetPass(self) then
		self._keyType:foreach(function(vAtomType)
			if StringLiteral.is(vAtomType) then
				vCompletion:putPair(vAtomType:getLiteral(), self._fieldDict[vAtomType].valueType)
			end
		end)
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			nMetaIndex:putCompletion(vCompletion)
		end
	end
end

function SealTable:isLocked()
	error("isLocked not implement")
	return false
end

return SealTable

end end
--thlua.object.SealTable end ==========)

--thlua.object.Struct begin ==========(
do local _ENV = _ENV
packages['thlua.object.Struct'] = function (...)

local MemberFunction = require "thlua.func.MemberFunction"
local TypedObject = require "thlua.object.TypedObject"
local class = require "thlua.class"


	  


local Struct = class (TypedObject)

function Struct:ctor(...)
end

function Struct:detailString(vToStringCache, vVerbose)
	return "Struct@"..tostring(self._node)
end

function Struct:assumeIncludeObject(vAssumeSet , vRightObject)
	local nAssumeInclude = false
	if not Struct.is(vRightObject) then
		return false
	end
	local nRightValueDict = vRightObject:copyValueDict(self)
	local nRightKeyRefer, nRightNextKey = vRightObject:getKeyTypes()
	local nLeftNextKey = self._nextKey
	if nLeftNextKey and nRightNextKey then
		local nLR = nLeftNextKey:assumeIncludeAll(vAssumeSet, nRightNextKey)
		local nRL = nRightNextKey:assumeIncludeAll(vAssumeSet, nLeftNextKey)
		if not (nLR and nRL) then
			return false
		end
	elseif nLeftNextKey or nRightNextKey then
		return false
	end
	local function isMatchedKeyValue(
		vLeftKey, vLeftValue,
		vRightKey, vRightValue)
		if not vRightValue:assumeIncludeAll(vAssumeSet, vLeftValue) then
			return false
		end
		if not vLeftValue:assumeIncludeAll(vAssumeSet, vRightValue) then
			return false
		end
		if not vLeftKey:assumeIncludeAtom(vAssumeSet, vRightKey) then
			return false
		end
		return true
	end
	local nRightResultType = nRightKeyRefer:getResultType()
	if not self:_everyWith(vRightObject, function(nLeftKey, nLeftValue)
		if nRightResultType then        
			local nRightKey = nRightResultType:assumeIncludeAtom(vAssumeSet, nLeftKey)
			if not nRightKey then
				return false
			end
			local nRightValue = nRightValueDict[nRightKey]
			if not nRightValue then
				return false
			end
			if not isMatchedKeyValue(nLeftKey, nLeftValue, nRightKey, nRightValue) then
				return false
			end
			nRightValueDict[nRightKey] = nil
		else         
			local nMatchedKey = nil
			for _, nRightKey in ipairs(nRightKeyRefer:getListAwait()) do
				if nRightKey:assumeIncludeAtom(vAssumeSet, nLeftKey) then
					local nRightValue = nRightValueDict[nRightKey]
					if nRightValue and isMatchedKeyValue(nLeftKey, nLeftValue, nRightKey, nRightValue) then
						nMatchedKey = nRightKey
						break
					end
				end
			end
			if not nMatchedKey then
				return false
			end
			nRightValueDict[nMatchedKey] = nil
		end
		return true
	end) then
		return false
	end
	if next(nRightValueDict) then
		return false
	end
	return true
end

function Struct:meta_set(vContext, vKeyType, vValueTerm)
	vContext:pushNothing()
	local nValueType = vValueTerm:getType()
	local nKey, nSetValue = self:_keyIncludeAtom(vKeyType)
	if nKey then
		if MemberFunction.is(nSetValue) then
			vContext:error("error:set("..tostring(vKeyType)..","..tostring(nValueType)..") in struct, field is member function")
			return
		end
		local nSetType = nSetValue:checkAtomUnion()
		vContext:includeAndCast(nSetType, nValueType, "set")
	else
		vContext:error("error2:set("..tostring(vKeyType)..","..tostring(nValueType)..") in struct, field not exist")
	end
end

function Struct:native_rawset(vContext, vKeyType, vValueTerm)
	vContext:warn("abstract object take rawset")
	local nValueType = vValueTerm:getType()
	local nKey, nSetValue = self:_keyIncludeAtom(vKeyType)
	if nKey then
		if not nSetValue:includeAll(nValueType) then
			vContext:error("error1:set("..tostring(vKeyType)..","..tostring(nValueType)..") in struct, field not match")
		end
	else
		vContext:error("error2:set("..tostring(vKeyType)..","..tostring(nValueType)..") in struct, field not exist")
	end
end

return Struct

end end
--thlua.object.Struct end ==========)

--thlua.object.TypedObject begin ==========(
do local _ENV = _ENV
packages['thlua.object.TypedObject'] = function (...)

local TypedMemberFunction = require "thlua.func.TypedMemberFunction"
local StringLiteral = require "thlua.type.StringLiteral"
local Exception = require "thlua.Exception"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local MetaEventCom = require "thlua.object.MetaEventCom"

local BaseObject = require "thlua.object.BaseObject"
local class = require "thlua.class"


	  


local TypedObject = class (BaseObject)

function TypedObject:ctor(vManager, vNode)
	local nTask = vManager:getScheduleManager():newTask()
	self._task = nTask
	self._keyRefer=vManager:AsyncUnion(nTask)
	self._valueDict=false 
	self._nextKey=false
	self._nextValue=false
	self._nextDict={} 
	self._intersectSet={} 
end

function TypedObject:lateInit(vIntersectSet, vValueDict , vNextKey, vMetaEventCom)
	self._nextKey = vNextKey
	self._intersectSet = vIntersectSet
	self._metaEventCom = vMetaEventCom
	self._valueDict = vValueDict
end

function TypedObject:lateCheck()
	local nNextKey = self._nextKey
	local nValueDict = assert(self._valueDict, "member dict must existed here")
	if nNextKey then
		nNextKey:checkAtomUnion():foreach(function(vKeyAtom)
			local nMember = nValueDict[vKeyAtom]
			if not nMember then
				error("nextKey is not subtype of object's key, missing field:"..tostring(vKeyAtom))
			end
		end)
	end
end

function TypedObject:_everyWith(vRightObject, vFunc )
	local nValueDict = self:getValueDict()
	for nLeftKey, nLeftValue in pairs(nValueDict) do
		if not nLeftValue:mayRecursive() then
			if not vFunc(nLeftKey, nLeftValue) then
				return false
			end
		end
	end
	for nLeftKey, nLeftValue in pairs(nValueDict) do
		if nLeftValue:mayRecursive() then
			if not vFunc(nLeftKey, nLeftValue) then
				return false
			end
		end
	end
	return true
end

function TypedObject:assumeIncludeObject(vAssumeSet , vRightObject)
	error("assume include Object not implement")
	return false
end

function TypedObject:assumeIncludeAtom(vAssumeSet, vRightType, _)
	local nRightStruct = vRightType:checkTypedObject()
	if not nRightStruct then
		return false
	end
	if self == nRightStruct then
		return self
	end
	local nMgr = self._manager
	local nRelation = nMgr:attachPairRelation(self, nRightStruct, not vAssumeSet)
	if nRelation then
		if nRelation == ">" or nRelation == "=" then
			return self
		else
			return false
		end
	else
		assert(vAssumeSet, "assume set must be existed here")
	end
	local nPair = self._manager:makePair(self, nRightStruct)
	local nAssumeResult = vAssumeSet[nPair]
	if nAssumeResult ~= nil then
		return nAssumeResult and self
	end
	vAssumeSet[nPair] = true
	local nAssumeInclude = self:assumeIncludeObject(vAssumeSet, nRightStruct)
	if not nAssumeInclude then
		vAssumeSet[nPair] = false
		return false
	else
		return self
	end
end

function TypedObject:meta_len(vContext)
	local nCom = self:getMetaEventCom()
	if nCom then
		local nType = nCom:getLenType()
		if nType then
			return nType
		end
	end
	vContext:error(self, "object take # oper, but _len action not setted")
	return self._manager.type.Integer
end

function TypedObject:meta_uop_some(vContext, vOper)
	vContext:error("other oper invalid:"..tostring(vOper))
	return self._manager.type.Never
end

function TypedObject:meta_pairs(vContext)
	return false
end

function TypedObject:meta_ipairs(vContext)
	return false
end

function TypedObject:native_next(vContext, vInitType)
	local nValueDict = self:getValueDict()
	local nNextKey = self._nextKey
	local nNil = self._manager.type.Nil
	if not nNextKey then
		vContext:error("this object can not take next")
		return nNil, {[nNil]=nNil}
	end
	local nNextValue = self._nextValue
	local nNextDict = self._nextDict
	if not nNextValue then
		nNextDict = {}
		local nCollection = self._manager:TypeCollection()
		nNextKey:checkAtomUnion():foreach(function(vKeyAtom)
			local nValue = nValueDict[vKeyAtom]
			local nNotnilValue = nValue:checkAtomUnion():notnilType()
			nNextDict[vKeyAtom] = nNotnilValue
			nCollection:put(nNotnilValue)
		end)
		nCollection:put(nNil)
		nNextValue = nCollection:mergeToAtomUnion()
		nNextDict[nNil] = nNil
		self._nextValue = nNextValue
		self._nextDict = nNextDict
	end
	return nNextValue, nNextDict
end

function TypedObject:isSingleton()
	return false
end

function TypedObject:_keyIncludeAtom(vType) 
	local nKey = self._keyRefer:getTypeAwait():includeAtom(vType)
	if nKey then
		return nKey, assert(self._valueDict)[nKey]
	else
		return false
	end
end

function TypedObject:meta_get(vContext, vType)
	local nRet = self:_getValue(vContext, vType)
	vContext:pushFirstAndTuple(nRet)
	return true
end

function TypedObject:_getValue(vContext, vType)
	local nKey, nGetValue = self:_keyIncludeAtom(vType)
	if not nKey then
		vContext:error("error get("..tostring(vType)..") in struct")
		return self._manager.type.Nil
	else
		return nGetValue:checkAtomUnion()
	end
end

function TypedObject:native_rawget(vContext, vKeyType)
	vContext:warn("abstract object take rawget")
	return self:_getValue(vContext, vKeyType)
end

function TypedObject:meta_bop_func(vContext, vOper)
	local nMethodEvent = OPER_ENUM.bopNoEq[vOper]
	local nCom = self:getMetaEventCom()
	if nCom then
		local nFn = nCom:getBopFunc(nMethodEvent)
		if nFn then
			return true, nFn
		end
	end
	return false, nil
end

function TypedObject:indexKeyValue(vKeyType) 
	local nKey, nValue = self:_keyIncludeAtom(vKeyType)
	if nKey then
		return nKey, nValue
	else
		return false
	end
end

function TypedObject:buildAsync(vFunc)
	self._task:runAsync(function()
		vFunc(self._keyRefer)
	end)
end

function TypedObject:detailString(vToStringCache, vVerbose)
	return "TypedObject..."
end

function TypedObject:getValueDict() 
	self._keyRefer:getListAwait()
	return (assert(self._valueDict, "member list is not setted after waiting"))
end

function TypedObject:copyValueDict(vSelfObject ) 
	local nValueDict  = {}
	for k,v in pairs(self:getValueDict()) do
		if not TypedMemberFunction.is(v) then
			nValueDict[k] = v
		else
			nValueDict[k] = v:indexTypeFn(vSelfObject)
		end
	end
	return nValueDict
end

function TypedObject:getMetaEventCom()
	self._keyRefer:getListAwait()
	return self._metaEventCom
end

function TypedObject:getKeyTypes() 
	return self._keyRefer, self._nextKey
end

function TypedObject:checkTypedObject()
	return self
end

function TypedObject:native_type()
	return self._manager:Literal("table")
end

function TypedObject:partTypedObject()
	return self
end

function TypedObject:mayRecursive()
	return true
end

function TypedObject:getNode()
	return self._node
end

function TypedObject:putCompletion(vCompletion)
	if vCompletion:testAndSetPass(self) then
		self._keyRefer:getTypeAwait():foreach(function(vType)
			if StringLiteral.is(vType) then
				vCompletion:putPair(vType:getLiteral(), assert(self._valueDict)[vType])
			end
		end)
	end
end

return TypedObject

end end
--thlua.object.TypedObject end ==========)

--thlua.refer.AsyncUnion begin ==========(
do local _ENV = _ENV
packages['thlua.refer.AsyncUnion'] = function (...)

local ScheduleTask = require "thlua.manager.ScheduleTask"
local class = require "thlua.class"
local Exception = require "thlua.Exception"

  

local AsyncUnion = class ()

function AsyncUnion.__tostring(self)
	local l = {}
	local nTypeList = self._typeList
	if nTypeList then
		for i, v in ipairs(nTypeList) do
			l[i] = tostring(v)
		end
		return "AsyncUnion("..table.concat(l, ",")..")"
	else
		return "AsyncUnion(?)"
	end
end

function AsyncUnion:ctor(vManager, vTask)
	self._manager=vManager
	self._task = vTask
	self._mayRecursive=false
	self._typeList=false
	self._resultType=false
	self._listBuildEvent=vTask:makeEvent()
	self._resultBuildEvent=vTask:makeEvent()
end

function AsyncUnion:getResultType()
	return self._resultType
end

function AsyncUnion:getTypeAwait()
	if not self._resultType then
		self._resultBuildEvent:wait()
	end
	return (assert(self._resultType, "result type not setted"))
end

function AsyncUnion:getMayRecursive()
	return self._mayRecursive
end

function AsyncUnion:getListAwait()
	if not self._typeList then
		self._listBuildEvent:wait()
	end
	return (assert(self._typeList, "type list not setted"))
end

function AsyncUnion:setAtomList(vAtomList, vLateRunner)
	assert(not self._typeList, "type list has been setted")
	    
	self._typeList = vAtomList
	for k, v in ipairs(vAtomList) do
		if v:mayRecursive() then
			self._mayRecursive = true
		end
	end
	self._listBuildEvent:wakeup()
	if vLateRunner then
		local nResultType = vLateRunner()
		if nResultType then
			self._resultType = nResultType
			self._resultBuildEvent:wakeup()
			return nResultType
		end
	end
	      
	local nResultType = nil
	if #vAtomList == 0 then
		nResultType = self._manager.type.Never
	elseif #vAtomList == 1 then
		nResultType = vAtomList[1]
	else
		local nCollection = self._manager:TypeCollection()
		for _, v in ipairs(vAtomList) do
			nCollection:put(v)
		end
		nResultType = nCollection:mergeToAtomUnion()
	end
	self._resultType = nResultType
	self._resultBuildEvent:wakeup()
	return nResultType
end

function AsyncUnion:foreachAwait(vFunc)
	local nResultType = self._resultType
	if nResultType then
		nResultType:foreach(vFunc)
	else
		local nListType = self:getListAwait()
		for _, v in ipairs(nListType) do
			vFunc(v)
		end
	end
end

function AsyncUnion:isAsync()
	return true
end

return AsyncUnion

end end
--thlua.refer.AsyncUnion end ==========)

--thlua.refer.Reference begin ==========(
do local _ENV = _ENV
packages['thlua.refer.Reference'] = function (...)

local Exception = require "thlua.Exception"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Node = require "thlua.code.Node"

local BaseAtomType = require "thlua.type.BaseAtomType"
local BaseUnionType = require "thlua.union.BaseUnionType"

local AsyncUnion = require "thlua.refer.AsyncUnion"

local TypeReferCom = require "thlua.refer.TypeReferCom"
local TemplateReferCom = require "thlua.refer.TemplateReferCom"

local ScheduleEvent = require "thlua.manager.ScheduleEvent"

local ScheduleTask = require "thlua.manager.ScheduleTask"

local class = require "thlua.class"


	  
	   


local Reference = class ()

Reference.__call=function(self, ...)
	  
	local nNode = Node.getDebugNode(3)
	local nArgList = self._manager:easyToTypeList(...)
	local nKey = self._manager:signTemplateArgs(nArgList)
	local nCom = self._com
	if TemplateReferCom.is(nCom) then
		return nCom:call(nNode, nKey, nArgList)
	elseif nCom then
		error(Exception.new("template reference expected here", nNode))
	end
	local nDict = self._callDict
	local nRefer = nDict[nKey]
	if not nRefer then
		nRefer = self._manager:Reference(false)
		nRefer:setAssignAsync(nNode, function()
			local nCom = self:waitTemplateCom()
			return nCom:call(nNode, nKey, nArgList)
		end)
		nDict[nKey] = nRefer
	end
	return nRefer
end

function Reference.__tostring(self)
	return self:detailString({}, false)
end

function Reference.__bor(vLeft, vRight)
	return vLeft._manager:checkedUnion(vLeft, vRight)
end

function Reference.__band(vLeft, vRight)
	local nTypeOrFalse = vLeft:safeIntersect(vRight)
	if nTypeOrFalse then
		return nTypeOrFalse
	else
		error("unexpected intersect")
	end
end

function Reference:ctor(vManager, vKeyOrFalse)
	local nTask = vManager:getScheduleManager():newTask()
	self._manager = vManager
	self._task = nTask
	self._key=vKeyOrFalse
	self._callDict={} 
	self._assignNode=false
	self._referNodes={}
	self.id=vManager:genTypeId()
	self.bits=false
	self._assignComEvent = nTask:makeEvent()
	self._com=false
end

function Reference:getKey()
	return self._key
end

function Reference:detailString(v, vVerbose)
	local nCom = self._com
	if not nCom then
		return "Reference("..(tostring(self._key) or tostring(self._assignNode))..")"
	else
		if TypeReferCom.is(nCom) then
			return "TypeReference("..tostring(nCom:getTypeNowait())..")"
		else
			return "TemplateReference("..(tostring(self._key) or tostring(self._assignNode))..")"
		end
	end
end

function Reference:getComNowait()
	return self._com
end

function Reference:getComAwait()
	if not self._com then
		self._assignComEvent:wait()
	end
	local nCom = assert(self._com, "com not setted after wait finish")
	return nCom
end

function Reference:waitTypeCom()
	local nCom = self:getComAwait()
	assert(TypeReferCom.is(nCom), "type reference expected, but get template reference")
	return nCom
end

function Reference:waitTemplateCom()
	local nCom = self:getComAwait()
	assert(TemplateReferCom.is(nCom), "template reference expected, but get some other reference")
	return nCom
end

function Reference:_setComAndWakeup(vCom)
	self._com = vCom
	self._assignComEvent:wakeup()
end

function Reference:setAssignAsync(vNode, vGetFunc)
	assert(not self._assignNode, Exception.new("refer has been setted:"..tostring(self), vNode))
	self._assignNode = vNode
	self._task:runAsync(function()
		local nAssignValue = vGetFunc()
		if Reference.is(nAssignValue) then
			local nCom = nAssignValue:getComAwait()
			self:_setComAndWakeup(nCom)
		elseif BaseAtomType.is(nAssignValue) then
			local nCom = TypeReferCom.new(self._manager, self._task, nAssignValue)
			self:_setComAndWakeup(nCom)
		elseif BaseUnionType.is(nAssignValue) then
			local nCom = TypeReferCom.new(self._manager, self._task, nAssignValue)
			self:_setComAndWakeup(nCom)
		else
			error("namespace assign a non-type value")
		end
	end)
end

function Reference:setTemplateAsync(vNode, vFunc, vParNum)
	assert(not self._assignNode, Exception.new("refer has been setted:"..tostring(self), vNode))
	self._assignNode = vNode
	local nCom = TemplateReferCom.new(self._manager, self, vFunc, vParNum)
	self._task:runAsync(function()
		self:_setComAndWakeup(nCom)
	end)
end

function Reference:setUnionAsync(
	vNode,
	vGetList 
)
	assert(not self._assignNode, Exception.new("refer has been setted:"..tostring(self), vNode))
	self._assignNode = vNode
	local nAsyncUnion = self._manager:AsyncUnion(self._task)
	self._task:runAsync(function()
		nAsyncUnion:setAtomList(vGetList())
	end)
	local nCom = TypeReferCom.new(self._manager, self._task, nAsyncUnion)
	self:_setComAndWakeup(nCom)
end

function Reference:getAssignNode()
	return self._assignNode
end

function Reference:getReferNode()
	return self._referNodes
end

function Reference:pushReferNode(vNode)
	local nNodes = self._referNodes
	nNodes[#nNodes + 1] = vNode
end

function Reference:checkAtomUnion()
	return self:waitTypeCom():getTypeAwait()
end

function Reference:isReference()
	return true
end

function Reference:foreachAwait(vFunc)
	local nResultType = self:waitTypeCom():getTypeNowait()
	if not nResultType:isAsync() then
		nResultType:foreach(vFunc)
	else
		local nListType = nResultType:getListAwait()
		for _, v in ipairs(nListType) do
			vFunc(v)
		end
	end
end

function Reference:intersectAtom(vRightType)
	local nType = self:checkAtomUnion()
	return nType:intersectAtom(vRightType)
end

function Reference:includeAtom(vRightType)
	local nType = self:checkAtomUnion()
	return nType:includeAtom(vRightType)
end

function Reference:assumeIntersectSome(vAssumeSet, vRight)
	local nResultType = self:waitTypeCom():getTypeNowait()
	if not nResultType:isAsync() then
		return nResultType:assumeIntersectSome(vAssumeSet, vRight)
	else
		local nSomeIntersect = false
		local nTypeList = nResultType:getListAwait()
		vRight:foreachAwait(function(vAtomType)
			if nSomeIntersect then
				return
			end
			local nCurIntersect = false
			for _, nType in ipairs(nTypeList) do
				if nType:assumeIntersectAtom(vAssumeSet, vAtomType) then
					nCurIntersect = true
					break
				end
			end
			if nCurIntersect then
				nSomeIntersect = true
			end
		end)
		return nSomeIntersect
	end
end

function Reference:assumeIncludeAll(vAssumeSet, vRight, vSelfType)
	local nResultType = self:waitTypeCom():getTypeNowait()
	if not nResultType:isAsync() then
		return nResultType:assumeIncludeAll(vAssumeSet, vRight, vSelfType)
	else
		local nAllInclude = true
		local nTypeList = nResultType:getListAwait()
		vRight:foreachAwait(function(vAtomType)
			if not nAllInclude then
				return
			end
			local nCurInclude = false
			for _, nType in ipairs(nTypeList) do
				if nType:assumeIncludeAtom(vAssumeSet, vAtomType, vSelfType) then
					nCurInclude = true
					break
				end
			end
			if not nCurInclude then
				nAllInclude = false
			end
		end)
		return nAllInclude
	end
end

function Reference:unionSign()
	return tostring(self.id)
end

function Reference:safeIntersect(vRight)
	return self:checkAtomUnion():safeIntersect(vRight)
end

function Reference:includeAll(vRight)
	return self:assumeIncludeAll(nil, vRight)
end

function Reference:intersectSome(vRight)
	return self:assumeIntersectSome(nil, vRight)
end

function Reference:mayRecursive()
	local nTypeCom = self:waitTypeCom()
	local nResultType = nTypeCom:getTypeNowait()
	if nResultType:isAsync() then
		return nResultType:getMayRecursive()
	else
		return nResultType:mayRecursive()
	end
end

return Reference

end end
--thlua.refer.Reference end ==========)

--thlua.refer.TemplateReferCom begin ==========(
do local _ENV = _ENV
packages['thlua.refer.TemplateReferCom'] = function (...)

local Exception = require "thlua.Exception"

  

local TemplateReferCom = {}
TemplateReferCom.__index = TemplateReferCom

function TemplateReferCom.new(
	vManager,
	vRefer,
	vFunc,
	vParNum
)
	local self = setmetatable({
		_manager=vManager,
		_refer=vRefer,
		_parNum=vParNum,
		_func=vFunc,
		_cache={} ,
	}, TemplateReferCom)
	return self
end

function TemplateReferCom:call(vNode, vKey, vArgList)
	local nFn = self._func
	local nRefer = self._cache[vKey]
	if not nRefer then
		nRefer = self._manager:Reference(false)
		nRefer:setAssignAsync(vNode, function()
			if #vArgList ~= self._parNum then
				error(Exception.new("template args num not match", vNode))
			end
			return nFn(table.unpack(vArgList))
		end)
		self._cache[vKey] = nRefer
	end
	return nRefer
end

function TemplateReferCom.is(self)
	return getmetatable(self) == TemplateReferCom
end

return TemplateReferCom

end end
--thlua.refer.TemplateReferCom end ==========)

--thlua.refer.TypeReferCom begin ==========(
do local _ENV = _ENV
packages['thlua.refer.TypeReferCom'] = function (...)


local AsyncUnion = require "thlua.refer.AsyncUnion"
local Exception = require "thlua.Exception"

  

local TypeReferCom = {}
TypeReferCom.__index = TypeReferCom

function TypeReferCom.new(
	vManager,
	vTask,
	vAssignType 
)
	local nIsAsync = AsyncUnion.is(vAssignType)
	local self = setmetatable({
        _manager=vManager,
        _task=vTask,
		_asyncType=nIsAsync and vAssignType or false,
		_readyType=(not nIsAsync) and vAssignType or false,
	}, TypeReferCom)
	return self
end

function TypeReferCom:getTypeNowait() 
	return assert(self._readyType or self._asyncType)
end

function TypeReferCom:getTypeAwait()
	local nReadyType = self._readyType
	if not nReadyType then
		nReadyType = assert(self._asyncType):getTypeAwait()
		self._readyType = nReadyType
	end
	return nReadyType
end

function TypeReferCom.is(self)
	return getmetatable(self) == TypeReferCom
end

return TypeReferCom

end end
--thlua.refer.TypeReferCom end ==========)

--thlua.runtime.BaseRuntime begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.BaseRuntime'] = function (...)

local TypedFunction = require "thlua.func.TypedFunction"
local TypeManager = require "thlua.manager.TypeManager"
local OpenFunction = require "thlua.func.OpenFunction"
local BaseAtomType = require "thlua.type.BaseAtomType"
local TermTuple = require "thlua.tuple.TermTuple"
local native = require "thlua.native"
local Node = require "thlua.code.Node"
local Namespace = require "thlua.manager.Namespace"
local Exception = require "thlua.Exception"
local VariableCase = require "thlua.term.VariableCase"

local BaseStack = require "thlua.runtime.BaseStack"
local OpenStack = require "thlua.runtime.OpenStack"
local SealStack = require "thlua.runtime.SealStack"
local AutoFunction = require "thlua.func.AutoFunction"

local ScheduleManager = require "thlua.manager.ScheduleManager"
local class = require "thlua.class"


	
	  
	  

	   
		 
		
	

	   
		
		
		
	

	   
		
		
		
		
		
	




local BaseRuntime = class ()

function BaseRuntime:ctor(vLoader)
	self._loader=vLoader
	self._spaceList={}
	self._pathToFileName={} 
	self._loadedDict={} 
	self._scheduleManager=ScheduleManager.new()
	   
	self._node=nil
	self._manager=nil
	self._globalTable=nil
	self._rootStack=nil
end

function BaseRuntime:getCodeEnv(vFileName)
	local nState = self._loadedDict[vFileName]
	if nState then
		return nState.codeEnv
	else
		return false
	end
end

function BaseRuntime:checkAtomUnionFinish()
	for _, space in pairs(self._spaceList) do
		space:check()
	end
end

function BaseRuntime:import(vDst)
	   
	if type(vDst) == "string" then
		local nPath = vDst  
		local nNode = Node.getDebugNode(3)
		local nLoadedState = self:_cacheLoadPath(Node.getDebugNode(3), nPath)
		local nStack = nLoadedState.stack
		if not nStack then
			error(Exception.new("recursive import:"..nPath, nNode))
		end
		local nSpace = nStack:getNamespace()
		return nSpace.localExport
	elseif BaseAtomType.is(vDst) then
		local nStack = vDst:findRequireStack()
		if nStack then
			local nSpace = nStack:getNamespace()
			return nSpace.localExport
		else
			error("import can only take type in a require stack"..debug.traceback())
		end
	else
		error("import can only take string or type as first argument")
	end
end

function BaseRuntime:pmain(vMainFileName)  
	self._node=Node.newRootNode(vMainFileName)
	self._manager=TypeManager.new(self, self._node, self._scheduleManager)
	local nAutoFn = AutoFunction.new(self._manager, self._node, false)
	local nRootStack = nAutoFn:getBuildStack()
	self._rootStack = nRootStack
	self._manager:lateInit()
	self._globalTable = native.make(self)
	nRootStack:rootSetNamespace(self:RootNamespace())
	local t1 = os.clock()
	local ok, err = pcall(function()
		nAutoFn:initAsync(function()
			return false, false, function()
				local nLoadedState = self:_cacheLoadFile(self._node, vMainFileName)
				local nParTuple = self._manager:TypeTuple(self._node)
				local nRetTuples = self._manager:VoidRetTuples(self._node)
				return nParTuple, nRetTuples
			end
		end)
		nAutoFn:startPreBuild()
		nAutoFn:startLateBuild()
	end)
	if not ok then
		if Exception.is(err) then
			self:nodeError(err.node, err.msg)
		else
			self:nodeError(self._node, err)
		end
	end
	local t2 = os.clock()
	print(t2-t1)
	 
	return ok, err
end

function BaseRuntime:lateSchedule(vAutoFn)
	error("implement lateSchedule function in extends class")
end

function BaseRuntime:recordBranch(vNode, vBranch)
	 
end

function BaseRuntime:recordApplyContext(vNode, vContext)
	 
end

function BaseRuntime:SealStack(...)
	return SealStack.new(self, ...)
end

function BaseRuntime:OpenStack(...)
	return OpenStack.new(self, ...)
end

function BaseRuntime:_cacheLoadFile(vNode, vFileName)
	local nLoadedState = self._loadedDict[vFileName]
	if not nLoadedState then
		local nCodeEnv = self._loader:thluaParseFile(vFileName)
		local nOpenFn = nCodeEnv:getTypingFn()(nCodeEnv:getNodeList(), self._rootStack, self:makeGlobalTerm())
		nLoadedState = {
			openFn=nOpenFn,
			codeEnv=nCodeEnv,
		}
		self._loadedDict[vFileName] = nLoadedState
		local nContext = self._rootStack:newNoPushContext(vNode)
		local nTermTuple = nContext:FixedTermTuple({})
		local nRet, nStack = nOpenFn:meta_open_call(nContext, nTermTuple, true)
		nLoadedState.term = TermTuple.is(nRet) and nRet:checkFixed(nContext, 1) or nRet:checkRefineTerm(nContext)
		nLoadedState.stack = nStack
	end
	return nLoadedState
end

function BaseRuntime:_cacheLoadPath(vNode, vPath)
	local nFileName = self._pathToFileName[vPath]
	if not nFileName then
		local nOkay, nSearchFileName = self._loader:thluaSearch(vPath)
		if not nOkay then
			error(Exception.new(nSearchFileName, vNode))
		else
			nFileName = nSearchFileName
		end
	end
	local nLoadedState = self._loadedDict[nFileName] or self:_cacheLoadFile(vNode, nFileName)
	local nOldPath = nLoadedState.path
	if nOldPath and nOldPath ~= vPath then
		self:nodeWarn(vNode, "mixing path:'"..nOldPath.."','"..vPath.."'")
	end
	nLoadedState.path = vPath
	return nLoadedState
end

function BaseRuntime:require(vNode, vPath) 
	local nLoadedState = self:_cacheLoadPath(vNode, vPath)
	local nTerm = nLoadedState.term
	if not nTerm then
		error(Exception.new("recursive require:"..vPath, vNode))
	end
	return nTerm, nLoadedState.openFn
end

function BaseRuntime:TreeNamespace()
	local nSpace = Namespace.new(self._manager, Node.getDebugNode(4))
	self._spaceList[#self._spaceList + 1] = nSpace
	return nSpace
end

function BaseRuntime:buildSimpleGlobal()
	local nGlobal = {}
	for k,v in pairs(self._manager.type) do
		nGlobal[k] = v
	end
	for k,v in pairs(self._manager.generic) do
		nGlobal[k] = v
	end
	local l = {
		Union="buildUnion",
		Struct="buildStruct",
		Interface="buildInterface",
		ExtendInterface="buildExtendInterface",
		ExtendStruct="buildExtendStruct",
		Template="buildTemplate",
		
		
		
		
		OrNil="buildOrNil",
		OrFalse="buildOrFalse",
		Fn="buildFn",
		Pfn="buildPfn",
		Mfn="buildMfn",
	}
	local nManager = self._manager
	for k,v in pairs(l) do
		nGlobal[k]=function(...)
			return nManager[v](nManager, Node.getDebugNode(3), ...)
		end
	end
	nGlobal.Literal=function(v)
		return nManager:Literal(v)
	end
	nGlobal.namespace=function()
		return self:TreeNamespace().localExport
	end
	nGlobal.lock=function(vType)
		vType:foreach(function(vAtom)
			vAtom:setLocked()
		end)
	end
	nGlobal.import=function(vPath)
		return self:import(vPath)
	end
	nGlobal.foreachPair=function(vObject, vFunc)
		local vObject = vObject:checkAtomUnion()
		local d = vObject:copyValueDict(vObject)
		for k,v in pairs(d) do
			vFunc(k,v)
		end
	end
	for k,v in pairs(_G) do
		nGlobal[k]=v
	end
	nGlobal.print=function(...)
		self:nodeInfo(Node.getDebugNode(3), ...)
	end
	local nRetGlobal = {}
	for k,v in pairs(nGlobal) do
		nRetGlobal[self._manager:Literal(k)] = v
	end
	return nRetGlobal
end

function BaseRuntime:RootNamespace()
	local nSpace = Namespace.new(self._manager, self._node, self:buildSimpleGlobal())
	self._spaceList[#self._spaceList + 1] = nSpace
	nSpace:trySetKey("")
	nSpace:close()
	return nSpace
end

function BaseRuntime:LetNamespace(vParentLet, vRegionNode)
	local nSpace = Namespace.new(self._manager, vRegionNode, vParentLet:getKeyToType())
	self._spaceList[#self._spaceList + 1] = nSpace
	nSpace:trySetKey("")
	return nSpace
end

function BaseRuntime:makeGlobalTerm()
	local nHeadContext = self._rootStack:inplaceOper()
	return nHeadContext:RefineTerm(self._globalTable)
end

function BaseRuntime:_save(vSeverity, vNode, ...)
	 
end

function BaseRuntime:nodeError(vNode, ...)
	print("[ERROR] "..tostring(vNode), ...)
	self:_save(1, vNode, ...)
end

function BaseRuntime:nodeWarn(vNode, ...)
	print("[WARN] "..tostring(vNode), ...)
	self:_save(2, vNode, ...)
end

function BaseRuntime:nodeInfo(vNode, ...)
	print("[INFO] "..tostring(vNode), ...)
	self:_save(3, vNode, ...)
end

function BaseRuntime:getNode()
	return self._node
end

function BaseRuntime:getTypeManager()
	return self._manager
end

function BaseRuntime:getScheduleManager()
	return self._scheduleManager
end

function BaseRuntime:getRootStack()
	return self._rootStack
end

return BaseRuntime

end end
--thlua.runtime.BaseRuntime end ==========)

--thlua.runtime.BaseStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.BaseStack'] = function (...)

local DoBuilder = require "thlua.builder.DoBuilder"
local Branch = require "thlua.runtime.Branch"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"
local AutoHolder = require "thlua.auto.AutoHolder"
local AutoFlag = require "thlua.auto.AutoFlag"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local Node = require "thlua.code.Node"
local LocalSymbol = require "thlua.term.LocalSymbol"
local ImmutVariable = require "thlua.term.ImmutVariable"

local ClassFactory = require "thlua.func.ClassFactory"
local AutoFunction = require "thlua.func.AutoFunction"
local OpenFunction = require "thlua.func.OpenFunction"
local BaseFunction = require "thlua.func.BaseFunction"
local TypedObject = require "thlua.object.TypedObject"
local Truth = require "thlua.type.Truth"

local FunctionBuilder = require "thlua.builder.FunctionBuilder"
local TableBuilder = require "thlua.builder.TableBuilder"
local class = require "thlua.class"

local OperContext = require "thlua.context.OperContext"
local ApplyContext = require "thlua.context.ApplyContext"
local ReturnContext = require "thlua.context.ReturnContext"
local AssignContext = require "thlua.context.AssignContext"
local MorePushContext = require "thlua.context.MorePushContext"
local OnePushContext = require "thlua.context.OnePushContext"
local NoPushContext = require "thlua.context.NoPushContext"
local LogicContext = require "thlua.context.LogicContext"


	  
	  

	   
		
		
	


local BaseStack = class ()

function BaseStack:ctor(
	vRuntime,
	vNode,
	vUpState,
	...
)
	local nManager = vRuntime:getTypeManager()
	self._runtime=vRuntime
	self._manager=nManager
	self._node=vNode
	self._namespace=false
	self._headContext=AssignContext.new(vNode, self, nManager)
	self._fastOper=OperContext.new(vNode, self, nManager)
	self._lexShot = vUpState
	local nTempBranch = Branch.new(self, vUpState and vUpState.uvCase or VariableCase.new(), vUpState and vUpState.branch or false)
	self._branchStack={nTempBranch}
	self._bodyFn=nil
	self._retList={}  
end

function BaseStack:RAISE_ERROR(vContext, vType)
	error("check error in OpenStack or SealStack")
end

function BaseStack:prepareMetaCall(
	vNode,
	vFuncTerm,
	vLazyFunc
)
	local nNil = self._manager.type.Nil
	return self:withMorePushContextWithCase(vNode, vFuncTerm, function(vContext, vFuncType, vCase)
		local nArgTermTuple = nil
		self:_withBranch(vCase, function()
			nArgTermTuple = vLazyFunc()
		end)
		if vFuncType == nNil then
			self._runtime:nodeWarn(vNode, "nil as call func")
		elseif BaseFunction.is(vFuncType) or Truth.is(vFuncType) then
			vFuncType:meta_call(vContext, assert(nArgTermTuple))
		else
			self._runtime:nodeError(vNode, "TODO call by a non-function value, type="..tostring(vFuncType))
		end
	end)
end

   
	      
		  
			 
		
			  
			
			  
		
	 
	   
		
	
	  


function BaseStack:getClassTable()
	return self:getSealStack():getClassTable()
end

function BaseStack:newAutoFunction(vNode , ...)
	local nAutoFn = AutoFunction.new(self._manager, vNode, ...)
	return nAutoFn
end

function BaseStack:newClassFactory(vNode, ...)
	local nFactory = ClassFactory.new(self._manager, vNode, ...)
	return nFactory
end

function BaseStack:newOpenFunction(vNode, vUpState )
	local nOpenFn = OpenFunction.new(self._manager, vNode, vUpState)
	return nOpenFn
end

function BaseStack:withOnePushContext(vNode, vFunc, vNotnil)
	local nCtx = OnePushContext.new(vNode, self, self._manager, vNotnil or false)
	vFunc(nCtx)
	return nCtx
end

function BaseStack:withMorePushContext(vNode, vFunc)
	local nCtx = MorePushContext.new(vNode, self, self._manager)
	vFunc(nCtx)
	return nCtx
end

function BaseStack:withMorePushContextWithCase(vNode, vTermOrTuple , vFunc  )
	local nCtx = MorePushContext.new(vNode, self, self._manager)
	local nTerm = TermTuple.isFixed(vTermOrTuple) and vTermOrTuple:checkFixed(nCtx, 1) or vTermOrTuple
	nTerm:foreach(function(vType, vCase)
		nCtx:withCase(vCase, function()
			vFunc(nCtx, vType, vCase)
		end)
	end)
	return nCtx
end

function BaseStack:newNoPushContext(vNode)
	return NoPushContext.new(vNode, self, self._manager)
end

function BaseStack:newLogicContext(vNode)
	return LogicContext.new(vNode, self, self._manager)
end

function BaseStack:newOperContext(vNode)
	return OperContext.new(vNode, self, self._manager)
end

function BaseStack:newReturnContext(vNode)
	return ReturnContext.new(vNode, self, self._manager)
end

function BaseStack:newAssignContext(vNode)
	return AssignContext.new(vNode, self, self._manager)
end

function BaseStack:getSealStack()
	error("getSealStack not implement in BaseStack")
end

function BaseStack:seal()
end

function BaseStack:_nodeTerm(vNode, vType)
	return RefineTerm.new(vNode, vType:checkAtomUnion())
end

function BaseStack:inplaceOper()
	return self._fastOper
end

function BaseStack:getNamespace()
	local nSpace = self._namespace
	return assert(nSpace, "space is false when get")
end

function BaseStack:error(...)
	self._runtime:nodeError(self._node, ...)
end

function BaseStack:warn(...)
	self._runtime:nodeWarn(self._node, ...)
end

function BaseStack:info(...)
	self._runtime:nodeInfo(self._node, ...)
end

function BaseStack:getNode()
	return self._node
end

function BaseStack:getRuntime()
	return self._runtime
end

function BaseStack:getTypeManager()
	return self._manager
end

function BaseStack:_withBranch(vVariableCase, vFunc, vNode)
	local nStack = self._branchStack
	local nLen = #nStack
	local nNewLen = nLen + 1
	local nOldBranch = nStack[nLen]
	local nNewBranch = Branch.new(self, vVariableCase & nOldBranch:getCase(), nOldBranch, vNode)
	nStack[nNewLen] = nNewBranch
	vFunc()
	nStack[nNewLen] = nil
	return nNewBranch
end

function BaseStack:topBranch()
	local nStack = self._branchStack
	return nStack[#nStack]
end

function BaseStack:nativeError(vContext, vTerm)
	self:RAISE_ERROR(vContext, vTerm:getType())
	self:topBranch():setStop()
end

function BaseStack:nativeAssert(vContext, vFirstTerm, vSecondTerm)
	if vSecondTerm then
		self:RAISE_ERROR(vContext, vSecondTerm:getType())
	end
	local nTrueCase = vFirstTerm:caseTrue()
	if nTrueCase then
		self:topBranch():assertCase(nTrueCase)
	end
end

function BaseStack:findRequireStack()
	return false
end

return BaseStack

end end
--thlua.runtime.BaseStack end ==========)

--thlua.runtime.Branch begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.Branch'] = function (...)

local ImmutVariable = require "thlua.term.ImmutVariable"
local LocalSymbol = require "thlua.term.LocalSymbol"
local VariableCase = require "thlua.term.VariableCase"
local RefineTerm = require "thlua.term.RefineTerm"

local Branch = {}


	  
	  


Branch.__index = Branch
Branch.__tostring = function(self)
	return "Branch@"..tostring(self._node)
end

function Branch.new(vStack, vVariableCase, vPreBranch, vNode)
	   
	   
	local self = setmetatable({
		_stack=vStack,
		_node=vNode or false,
		_stop=false,
		_case=vVariableCase,
		_nodeToSymbol={},
		symbolToVariable={},
		_headCase=vVariableCase,
	}, Branch)
	if vPreBranch then
		if vPreBranch:getStack() == vStack then
			self.symbolToVariable = (setmetatable({}, {__index=vPreBranch.symbolToVariable}) ) 
		end
		self._nodeToSymbol = setmetatable({}, {__index=vPreBranch._nodeToSymbol})
	end
	if vNode then
		assert(vNode.tag == "Block")
		vStack:getRuntime():recordBranch(vNode, self)
	end
	return self
end

function Branch:immutGet(vContext, vImmutVariable)
	local nType = self._case[vImmutVariable]
	if nType then
		if not nType:isNever() then
			local nTerm = vImmutVariable:getTerm():filter(vContext, nType)
			nTerm:initVariable(vImmutVariable)
			return nTerm
		else
			vContext:error("TODO type is never when get symbol"..tostring(vImmutVariable))
			return vContext:NeverTerm()
		end
	else
		return vImmutVariable:getTerm()
	end
end

function Branch:mutGet(vContext, vLocalSymbol)
	local nImmutVariable = self.symbolToVariable[vLocalSymbol]
	if not nImmutVariable then
		    
		nImmutVariable = vLocalSymbol:makeVariable()
		self.symbolToVariable[vLocalSymbol] = nImmutVariable
	end
	return self:immutGet(vContext, nImmutVariable)
end

function Branch:SYMBOL_GET(vNode, vDefineNode, vAllowAuto)
	local nSymbolContext = self._stack:newOperContext(vNode)
	local nSymbol = self:getSymbolByNode(vDefineNode)
	if LocalSymbol.is(nSymbol) then
		return self:mutGet(nSymbolContext, nSymbol)
	elseif ImmutVariable.is(nSymbol) then
		return self:immutGet(nSymbolContext, nSymbol)
	else
		local nTerm = nSymbol:getRefineTerm()
		if nTerm then
			return self:immutGet(nSymbolContext, nTerm:attachImmutVariable())
		else
			if not vAllowAuto then
				error(nSymbolContext:newException("auto term can't be used when it's undeduced:"..tostring(nSymbol)))
			else
				return nSymbol
			end
		end
	end
end

function Branch:setSymbolByNode(vNode, vSymbol)
	self._nodeToSymbol[vNode] = vSymbol
	return vSymbol
end

function Branch:getSymbolByNode(vNode)
	return self._nodeToSymbol[vNode]
end

function Branch:mutMark(vSymbol, vImmutVariable)
	self.symbolToVariable[vSymbol] = vImmutVariable
	vImmutVariable:addSymbol(vSymbol)
end

function Branch:mutSet(vContext, vSymbol, vValueTerm)
	local nValueType = vValueTerm:getType()
	local nDstType = vSymbol:getType()
	local nSetType = vContext:includeAndCast(nDstType, nValueType, "assign") or nDstType
	local nCastTerm = vContext:RefineTerm(nSetType)
	local nImmutVariable = nCastTerm:attachImmutVariable()
	self.symbolToVariable[vSymbol] = nImmutVariable
	nImmutVariable:addSymbol(vSymbol)
end

function Branch:mergeOneBranch(vContext, vOneBranch, vOtherCase)
	if vOneBranch:getStop() then
		if vOtherCase then
			self._case = self._case & vOtherCase
			self._headCase = self._headCase & vOtherCase
		end
	else
		local nSymbolToVariable = self.symbolToVariable
		for nLocalSymbol, nOneVariable in pairs(vOneBranch.symbolToVariable) do
			local nBeforeVariable = nSymbolToVariable[nLocalSymbol]
			if nBeforeVariable then
				local nOneType = vOneBranch:mutGet(vContext, nLocalSymbol):getType()
				if not vOtherCase then
					nSymbolToVariable[nLocalSymbol] = nLocalSymbol:makeVariable(nOneType)
				else
					local nOtherType = vOtherCase[nBeforeVariable] or self._case[nBeforeVariable] or nBeforeVariable:getType()
					local nMergeType = nOneType | nOtherType
					nSymbolToVariable[nLocalSymbol] = nLocalSymbol:makeVariable(nMergeType)
				end
			end
		end
	end
end

function Branch:mergeTwoBranch(vContext, vTrueBranch, vFalseBranch)
	local nTrueStop = vTrueBranch:getStop()
	local nFalseStop = vFalseBranch:getStop()
	if nTrueStop and nFalseStop then
		self._stop = true
		return
	end
	local nModLocalSymbolDict  = {}
	for nLocalSymbol, _ in pairs(vTrueBranch.symbolToVariable) do
		nModLocalSymbolDict[nLocalSymbol] = true
	end
	for nLocalSymbol, _ in pairs(vFalseBranch.symbolToVariable) do
		nModLocalSymbolDict[nLocalSymbol] = true
	end
	for nLocalSymbol, _ in pairs(nModLocalSymbolDict) do
		if self.symbolToVariable[nLocalSymbol] then
			local nType
			if nFalseStop then
				nType = vTrueBranch:mutGet(vContext, nLocalSymbol):getType()
			elseif nTrueStop then
				nType = vFalseBranch:mutGet(vContext, nLocalSymbol):getType()
			else
				local nTrueType = vTrueBranch:mutGet(vContext, nLocalSymbol):getType()
				local nFalseType = vFalseBranch:mutGet(vContext, nLocalSymbol):getType()
				nType = nTrueType | nFalseType
			end
			local nImmutVariable = nLocalSymbol:makeVariable(nType)
			self.symbolToVariable[nLocalSymbol] = nImmutVariable
		end
	end
	local nAndCase
	if nFalseStop then
		nAndCase = vTrueBranch._headCase
	elseif nTrueStop then
		nAndCase = vFalseBranch._headCase
	end
	if nAndCase then
		self._case = self._case & nAndCase
		self._headCase = self._headCase & nAndCase
	end
end

function Branch:assertCase(vVariableCase)
	self._case = self._case & vVariableCase
	self._headCase = self._headCase & vVariableCase
end

function Branch:setStop()
	self._stop = true
end

function Branch:getCase()
	return self._case
end

function Branch:getStop()
	return self._stop
end

function Branch:getStack()
	return self._stack  
end

return Branch

end end
--thlua.runtime.Branch end ==========)

--thlua.runtime.CompletionRuntime begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.CompletionRuntime'] = function (...)

local FieldCompletion = require "thlua.context.FieldCompletion"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local BaseRuntime = require "thlua.runtime.BaseRuntime"
local Namespace = require "thlua.manager.Namespace"
local ListDict = require "thlua.manager.ListDict"
local TypeReference = require "thlua.refer.Reference"
local BaseUnionType = require "thlua.union.BaseUnionType"
local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"


	
	  
	  


local CompletionRuntime = class (BaseRuntime)

function CompletionRuntime:ctor(...)
	self._focusNodeSet = {}   
	self._nodeToAutoFnList = ListDict ()
	self._nodeToBranchList = ListDict ()
	self._nodeToApplyContextList = ListDict ()
end

function CompletionRuntime:lateSchedule(vAutoFn)
	if self._focusNodeSet[vAutoFn:getNode()] then
		vAutoFn:startLateBuild()
	else
		self._nodeToAutoFnList:putOne(vAutoFn:getNode(), vAutoFn)
	end
end

function CompletionRuntime:_save(vSeverity, vNode, ...)
	   
	 
end

function CompletionRuntime:recordBranch(vNode, vBranch)
	self._nodeToBranchList:putOne(vNode, vBranch)
end

function CompletionRuntime:recordApplyContext(vNode, vContext)
	self._nodeToApplyContextList:putOne(vNode, vContext)
end

function CompletionRuntime:focusSchedule(vFuncList)
	    
	local nSet = self._focusNodeSet
	local nAutoFnList = {}
	for _,nNode in pairs(vFuncList) do
		nSet[nNode] = true
		local nList = self._nodeToAutoFnList:pop(nNode)
		if nList then
			for i=1,#nList do
				nAutoFnList[#nAutoFnList + 1] = nList[i]
			end
		end
	end
	for _, nAutoFn in ipairs(nAutoFnList) do
		nAutoFn:startLateBuild()
	end
end

function CompletionRuntime:injectGetAll(vTracePos, vBlockNode, vFn)
	local nList   = {}
	self:_injectForeach(vTracePos, vBlockNode, vFn, function(vItem)
		nList[#nList + 1] = vItem
	end)
	return nList
end

function CompletionRuntime:_injectForeach(vTracePos, vBlockNode, vFn, vCallback  )
	local nBranchList = self._nodeToBranchList:get(vBlockNode)
	if not nBranchList then
		return
	end
	       
	for _, nBranch in pairs(nBranchList) do
		local nStack = nBranch:getStack()
		local nResult = vFn(nStack, function(vIdent)
			    
			local nName = vIdent[1]
			local nDefineIdent = vBlockNode.symbolTable[nName]
			while nDefineIdent and nDefineIdent.pos > vTracePos do
				nDefineIdent = nDefineIdent.lookupIdent
			end
			if nDefineIdent then
				local nAutoTerm = nBranch:SYMBOL_GET(vIdent, nDefineIdent, false)
				if RefineTerm.is(nAutoTerm) then
					return nAutoTerm
				else
					return nStack:NIL_TERM(vIdent)
				end
			end
			    
			local nName = "_ENV"
			local nDefineIdent = vBlockNode.symbolTable[nName]
			while nDefineIdent and nDefineIdent.pos > vTracePos do
				nDefineIdent = nDefineIdent.lookupIdent
			end
			if nDefineIdent then
				local nEnvTerm = nBranch:SYMBOL_GET(vIdent, nDefineIdent, false)
				assert(RefineTerm.is(nEnvTerm), "auto can't be used here")
				local nAutoTerm = nStack:META_GET(vIdent, nEnvTerm, nStack:LITERAL_TERM(vIdent, vIdent[1]), false)
				if RefineTerm.is(nAutoTerm) then
					return nAutoTerm
				else
					return nStack:NIL_TERM(vIdent)
				end
			else
				return nStack:NIL_TERM(vIdent)
			end
		end)
		if RefineTerm.is(nResult) then
			vCallback(nResult)
		else
			if TypeReference.is(nResult) then
				vCallback(nResult)
			elseif BaseAtomType.is(nResult) or BaseUnionType.is(nResult) then
				vCallback(nResult)
			else
				local nSpace = Namespace.fromExport(nResult)
				if nSpace then
					vCallback(nSpace)
				end
			end
		end
	end
end

function CompletionRuntime:injectCompletion(vTracePos, vBlockNode, vFn, vServer)
	local nFieldCompletion = FieldCompletion.new()
	self:_injectForeach(vTracePos, vBlockNode, vFn, function(vResult)
		if RefineTerm.is(vResult) then
			vResult:getType():putCompletion(nFieldCompletion)
		elseif Namespace.is(vResult) then
			vResult:putCompletion(nFieldCompletion)
		end
	end)
	return nFieldCompletion
end

function CompletionRuntime:injectLookup(vTracePos, vBlockNode, vFn)
	local nNode = false
	self:_injectForeach(vTracePos, vBlockNode, vFn, function(vResult)
		if Namespace.is(vResult) then
			nNode = vResult:getNode()
		elseif TypeReference.is(vResult) then
			nNode = vResult:getAssignNode()
		end
	end)
	return nNode
end

function CompletionRuntime:nodeLookup(vNode)
	local nList = self._nodeToApplyContextList:get(vNode)
	if nList and #nList > 0 then
		for _, nContext in pairs(nList) do
			local nLookupNode = next(nContext:getLookupNodeSet())
			if nLookupNode then
				return nLookupNode
			end
		end
	end
	return false
end

return CompletionRuntime

end end
--thlua.runtime.CompletionRuntime end ==========)

--thlua.runtime.DiagnosticRuntime begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.DiagnosticRuntime'] = function (...)

local BaseRuntime = require "thlua.runtime.BaseRuntime"
local CompletionRuntime = require "thlua.runtime.CompletionRuntime"
local class = require "thlua.class"



local DiagnosticRuntime = class (CompletionRuntime)

function DiagnosticRuntime:ctor(...)
	self._diaList={}
end

function DiagnosticRuntime:lateSchedule(vAutoFn)
	vAutoFn:startLateBuild()
end

function DiagnosticRuntime:_save(vSeverity, vNode, ...)
	local l = {}
	for i=1, select("#", ...) do
		l[i] = tostring(select(i, ...))
	end
	local nMsg = table.concat(l, " ")
	local nDiaList = self._diaList
	nDiaList[#nDiaList + 1] = {
		msg=nMsg,
		node=vNode,
		severity=vSeverity,
	}
end

function DiagnosticRuntime:getAllDiagnostic() 
	local nFileToDiaList  = {}
	for _, nDia in pairs(self._diaList) do
		local nPath = nDia.node.path
		local nList = nFileToDiaList[nPath]
		if not nList then
			nList = {}
			nFileToDiaList[nPath] = nList
		end
		nList[#nList + 1] = nDia
	end
	return nFileToDiaList
end

return DiagnosticRuntime

end end
--thlua.runtime.DiagnosticRuntime end ==========)

--thlua.runtime.InstStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.InstStack'] = function (...)

local DoBuilder = require "thlua.builder.DoBuilder"
local Branch = require "thlua.runtime.Branch"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"
local AutoHolder = require "thlua.auto.AutoHolder"
local AutoFlag = require "thlua.auto.AutoFlag"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local Node = require "thlua.code.Node"
local Enum = require "thlua.Enum"
local LocalSymbol = require "thlua.term.LocalSymbol"
local ImmutVariable = require "thlua.term.ImmutVariable"

local BaseFunction = require "thlua.func.BaseFunction"
local TypedObject = require "thlua.object.TypedObject"
local OpenTable = require "thlua.object.OpenTable"
local Truth = require "thlua.type.Truth"

local FunctionBuilder = require "thlua.builder.FunctionBuilder"
local TableBuilder = require "thlua.builder.TableBuilder"
local class = require "thlua.class"
local BaseStack = require "thlua.runtime.BaseStack"

local OperContext = require "thlua.context.OperContext"
local ApplyContext = require "thlua.context.ApplyContext"
local LogicContext = require "thlua.context.LogicContext"


	  
	  


local InstStack = class (BaseStack)

function InstStack:AUTO(vNode)
	return AutoFlag
end

function InstStack:BEGIN(vLexStack, vBlockNode) 
	assert(not self._namespace, "context can only begin once")
	local nUpState = self._lexShot
	local nRootBranch = Branch.new(self, nUpState and nUpState.uvCase or VariableCase.new(), nUpState and nUpState.branch or false, vBlockNode)
	self._branchStack[1]=nRootBranch
	local nSpace = self._runtime:LetNamespace(vLexStack:getNamespace(), vBlockNode)
	self._namespace = nSpace
	return nSpace.localExport, nSpace.globalExport
end

      
function InstStack:EXPRLIST_REPACK(
	vNode,
	vLazy,
	l  
)
	local nPackContext = self:newOperContext(vNode)
	local reFunc
	local nLastIndex = #l
	local nLast = l[nLastIndex]
	if not nLast then
		reFunc = function()
			return nPackContext:FixedTermTuple({})
		end
	else
		local repackWithoutLast = function()
			local nTermList = {}
			for i=1, #l-1 do
				local cur = l[i]
				if TermTuple.is(cur) then
					if #cur ~= 1 then
						        
					end
					nTermList[i] = cur:get(nPackContext, 1)
				elseif RefineTerm.is(cur) or AutoHolder.is(cur) then
					nTermList[i] = cur
				elseif type(cur) == "function" then
					nTermList[i] = cur()
				else
					error("unexcept branch")
				end
			end
			return nTermList
		end
		  
		if TermTuple.is(nLast) then
			reFunc = function()
				return nPackContext:UTermTupleByAppend(repackWithoutLast(), nLast)
			end
		else
			reFunc = function()
				local nTermList = repackWithoutLast()
				if RefineTerm.is(nLast) or AutoHolder.is(nLast) then
					nTermList[#nTermList + 1] = nLast
				elseif type(nLast) == "function" then
					nTermList[#nTermList + 1] = nLast()
				else
					error("unexcept branch")
				end
				return nPackContext:UTermTupleByAppend(nTermList, false)
			end
		end
	end
	if vLazy then
		return reFunc
	else
		return reFunc()
	end
end

       
function InstStack:EXPRLIST_UNPACK(
	vNode,
	vNum,
	... 
)
	local nUnpackContext = self:newOperContext(vNode)
	local l  = {...}
	local re = {}
	for i=1, vNum do
		if i > #l then
			local last = l[#l]
			if TermTuple.is(last) then
				local nIndex = i - #l + 1
				re[i] = last:get(nUnpackContext, nIndex)
				       
					        
				 
			else
				self._runtime:nodeError(vNode, "exprlist_unpack but right value not enough")
				re[i] = nUnpackContext:RefineTerm(self._manager.type.Nil)
			end
		else
			local cur = l[i]
			if TermTuple.is(cur) then
				re[i] = cur:get(nUnpackContext, 1)
			else
				re[i] = cur
			end
		end
	end
	return table.unpack(re)
end

  
function InstStack:META_GET(
	vNode,
	vSelfTerm,
	vKeyTerm,
	vNotnil
)
	return self:withOnePushContext(vNode, function(vContext)
		vSelfTerm:foreach(function(vSelfType, vVariableCase)
			vKeyTerm:foreach(function(vKeyType, vKeyVariableCase)
				vContext:withCase(vVariableCase & vKeyVariableCase, function()
					if not vSelfType:meta_get(vContext, vKeyType) then
						if not OpenTable.is(vSelfType) then
							vContext:error("index error, key="..tostring(vKeyType))
						end
					end
				end)
			end)
		end)
	end, vNotnil):mergeFirst()
end

function InstStack:META_SET(
	vNode,
	vSelfTerm,
	vKeyTerm,
	vValueTerm
)
	local nNil = self._manager.type.Nil
	local vContext = self:newNoPushContext(vNode)
	vSelfTerm:foreach(function(vSelfType, _)
		vKeyTerm:foreach(function(vKeyType, _)
			vSelfType:meta_set(vContext, vKeyType, vValueTerm)
		end)
	end)
end

function InstStack:META_CALL(
	vNode,
	vFuncTerm,
	vLazyFunc
)
	local nCtx = self:prepareMetaCall(vNode, vFuncTerm, vLazyFunc)
	return nCtx:mergeReturn()
end

function InstStack:META_INVOKE(
	vNode,
	vSelfTerm,
	vName,
	vPolyArgs,
	vArgTuple
)
	assert(vPolyArgs, "poly args can't be nil here")
	local nNil = self._manager.type.Nil
	return self:withMorePushContextWithCase(vNode, vSelfTerm, function(vContext, vSelfType, vCase)
		if vSelfType == nNil then
			vContext:warn("nil as invoke self")
		else
			local nFilterSelfTerm = vContext:RefineTerm(vSelfType)
			local nNewArgTuple = vContext:UTermTupleByAppend({nFilterSelfTerm}, vArgTuple)
			local nFuncTerm = self:META_GET(vNode, nFilterSelfTerm, vContext:RefineTerm(self._manager:Literal(vName)), false)
			nFuncTerm:foreach(function(vSingleFuncType, _)
				if vSingleFuncType == nNil then
					self._runtime:nodeWarn(vNode, "nil as invoke func")
				elseif Truth.is(vSingleFuncType) or BaseFunction.is(vSingleFuncType) then
					vSingleFuncType:meta_invoke(vContext, vSelfType, vPolyArgs, nNewArgTuple)
				else
					self._runtime:nodeError(vNode, "TODO non-function-call TODO"..tostring(vSingleFuncType))
				end
			end)
		end
	end):mergeReturn()
end

function InstStack:META_EQ_NE(
	vNode,
	vIsEq,
	vLeftTerm,
	vRightTerm
)
	local nCmpContext = self:newOperContext(vNode)
	local nTypeCaseList = {}
	vLeftTerm:foreach(function(vLeftType, vLeftVariableCase)
		vRightTerm:foreach(function(vRightType, vRightVariableCase)
			local nReType = nil
			if vLeftType:isSingleton() and vRightType:isSingleton() then
				     
				local nTypeIsEq = vLeftType == vRightType
				if vIsEq == nTypeIsEq then
					nReType = self._manager.type.True
				else
					nReType = self._manager.type.False
				end
			elseif not (vLeftType & vRightType):isNever() then
				nReType = self._manager.type.Boolean:checkAtomUnion()
			else
				if vIsEq then
					nReType = self._manager.type.False
				else
					nReType = self._manager.type.True
				end
			end
			nTypeCaseList[#nTypeCaseList + 1] = {nReType, vLeftVariableCase & vRightVariableCase}
		end)
	end)
	return nCmpContext:mergeToRefineTerm(nTypeCaseList)
end

function InstStack:META_BOP_SOME(
	vNode,
	vOper,
	vLeftTerm,
	vRightTerm
)
	return self:withOnePushContext(vNode, function(vContext)
		vLeftTerm:foreach(function(vLeftType, vLeftVariableCase)
			local nLeftHigh, nLeftFunc = vLeftType:meta_bop_func(vContext, vOper)
			if nLeftHigh then
				local nRightType = vRightTerm:getType()
				local nTermTuple = vContext:FixedTermTuple({
					vLeftTerm:filter(vContext, vLeftType), vRightTerm
				})
				vContext:withCase(vLeftVariableCase, function()
					nLeftFunc:meta_call(vContext, nTermTuple)
				end)
			else
				vRightTerm:foreach(function(vRightType, vRightVariableCase)
					local nRightHigh, nRightFunc = vRightType:meta_bop_func(vContext, vOper)
					if nRightHigh then
						local nTermTuple = vContext:FixedTermTuple({
							vLeftTerm:filter(vContext, vLeftType),
							vRightTerm:filter(vContext, vRightType)
						})
						vContext:withCase(vLeftVariableCase & vRightVariableCase, function()
							nRightFunc:meta_call(vContext, nTermTuple)
						end)
					else
						if nLeftFunc and nRightFunc and nLeftFunc == nRightFunc then
							local nTermTuple = vContext:FixedTermTuple({
								vLeftTerm:filter(vContext, vLeftType),
								vRightTerm:filter(vContext, vRightType)
							})
							vContext:withCase(vLeftVariableCase & vRightVariableCase, function()
								nRightFunc:meta_call(vContext, nTermTuple)
							end)
						else
							self._runtime:nodeError(vNode, "invalid bop:"..vOper)
						end
					end
				end)
			end
		end)
	end):mergeFirst()
end

function InstStack:META_UOP(
	vNode,
	vOper,
	vData
)
	local nUopContext = self:newOperContext(vNode)
	local nTypeCaseList = {}
	if vOper == "#" then
		vData:foreach(function(vType, vVariableCase)
			nTypeCaseList[#nTypeCaseList + 1] = {
				vType:meta_len(nUopContext),
				vVariableCase
			}
		end)
	else
		vData:foreach(function(vType, vVariableCase)
			nTypeCaseList[#nTypeCaseList + 1] = {
				vType:meta_uop_some(nUopContext, vOper),
				vVariableCase
			}
		end)
	end
	return nUopContext:mergeToRefineTerm(nTypeCaseList)
end

function InstStack:CHUNK_TYPE(vNode, vTerm)
	return vTerm:getType()
end

function InstStack:FUNC_NEW(vNode ,
	vFnNewInfo,
	vPrefixHint,
	vParRetMaker
)
	local nBranch = self:topBranch()
	local nFnType = FunctionBuilder.new(self, vNode, {
		branch=nBranch,
		uvCase=nBranch:getCase(),
	}, vFnNewInfo, vPrefixHint, vParRetMaker):build()
	return self:_nodeTerm(vNode, nFnType)
end

  
function InstStack:TABLE_NEW(vNode, vHintInfo, vPairMaker)
	local nBuilder = TableBuilder.new(self, vNode, vHintInfo, vPairMaker)
	local nTableType = nBuilder:build()
	return self:_nodeTerm(vNode, nTableType)
end

function InstStack:EVAL(vNode, vTerm)
	if RefineTerm.is(vTerm) then
		return vTerm:getType()
	else
		self:getRuntime():nodeError(vNode, "hint eval fail")
		error("hint eval fail")
	end
end

function InstStack:CAST_HINT(vNode, vTerm, vCastKind, ...)
	local nCastContext = self:newAssignContext(vNode)
	    
	if vCastKind == Enum.CastKind_POLY then
		local nTypeCaseList = {}
		local nTemplateList = self._manager:easyToTypeList(...)
		vTerm:foreach(function(vType, vVariableCase)
			local nAfterType = vType:castPoly(nCastContext, nTemplateList)
			if nAfterType then
				nTypeCaseList[#nTypeCaseList + 1] = {nAfterType, vVariableCase}
			else
				nTypeCaseList[#nTypeCaseList + 1] = {vType, vVariableCase}
			end
		end)
		return nCastContext:mergeToRefineTerm(nTypeCaseList)
	else
		local nDst = assert(..., "hint type can't be nil")
		local nDstType = self._manager:easyToType(nDst):checkAtomUnion()
		local nSrcType = vTerm:getType()
		if vCastKind == Enum.CastKind_CONIL then
			nCastContext:includeAndCast(nDstType, nSrcType:notnilType(), Enum.CastKind_CONIL)
		elseif vCastKind == Enum.CastKind_COVAR then
			nCastContext:includeAndCast(nDstType, nSrcType, Enum.CastKind_COVAR)
		elseif vCastKind == Enum.CastKind_CONTRA then
			if not (nSrcType:includeAll(nDstType) or nDstType:includeAll(nSrcType)) then
				nCastContext:error("@> cast fail")
			end
		elseif vCastKind ~= Enum.CastKind_FORCE then
			vContext:error("unexcepted castkind:"..tostring(vCastKind))
		end
		return nCastContext:RefineTerm(nDstType)
	end
end

function InstStack:NIL_TERM(vNode)
	return self:_nodeTerm(vNode, self._manager.type.Nil)
end

function InstStack:HINT_TERM(vNode, vType)
	return self:_nodeTerm(vNode, vType:checkAtomUnion())
end

function InstStack:LITERAL_TERM(vNode, vValue  )
	local nType = self._manager:Literal(vValue)
	return self:_nodeTerm(vNode, nType)
end

function InstStack:SYMBOL_SET(vNode, vDefineNode, vTerm)
	local nBranch = self:topBranch()
	local nSymbol = nBranch:getSymbolByNode(vDefineNode)
	local nSymbolContext = self:newAssignContext(vNode)
	assert(not ImmutVariable.is(nSymbol), nSymbolContext:newException("immutable symbol can't set "))
	assert(not AutoHolder.is(nSymbol), nSymbolContext:newException("auto symbol can't set "))
	assert(not AutoHolder.is(vTerm), nSymbolContext:newException("TODO.. auto term assign"))
	nBranch:mutSet(nSymbolContext, nSymbol, vTerm)
end

function InstStack:SYMBOL_GET(vNode, vDefineNode, vAllowAuto)
	return self:topBranch():SYMBOL_GET(vNode, vDefineNode, vAllowAuto)
end

function InstStack:PARAM_PACKOUT(
	vNode,
	vList,
	vDots
)
	return self._headContext:UTermTupleByAppend(vList, vDots)
end

function InstStack:PARAM_UNPACK(
	vNode,
	vTermTuple,        
	vIndex,
	vHintType 
)
	local nHeadContext = self._headContext
	if vHintType == AutoFlag then
		if vTermTuple then
			return vTermTuple:get(nHeadContext, vIndex)
		else
			return AutoHolder.new(vNode, nHeadContext)
		end
	else
		if vTermTuple then
			local nAutoTerm = vTermTuple:get(nHeadContext, vIndex)
			nHeadContext:assignTermToType(nAutoTerm, vHintType)
		end
		     
		return nHeadContext:RefineTerm(vHintType)
	end
end

function InstStack:PARAM_NODOTS_UNPACK(
	vNode,
	vTermTuple,
	vParNum
)
	if vTermTuple then
		self._headContext:matchArgsToNoDots(vNode, vTermTuple, vParNum)
	end
end

function InstStack:PARAM_DOTS_UNPACK(
	vNode,
	vTermTuple,
	vParNum,
	vHintDots 
)
	if vTermTuple then
		if vHintDots == AutoFlag then
			return self._headContext:matchArgsToAutoDots(vNode, vTermTuple, vParNum)
		else
			return self._headContext:matchArgsToTypeDots(vNode, vTermTuple, vParNum, vHintDots)
		end
	else
		if vHintDots == AutoFlag then
			return self._headContext:UTermTupleByTail({}, AutoTail.new(vNode, self._headContext))
		else
			return self._headContext:UTermTupleByTail({}, DotsTail.new(self._headContext, vHintDots))
		end
	end
end

function InstStack:SYMBOL_NEW(vNode, vKind, vModify, vTermOrNil, vHintType)
	local nTopBranch = self:topBranch()
	local nSymbolContext = self:newAssignContext(vNode)
	local nTerm = vTermOrNil or nSymbolContext:NilTerm()
	if not vTermOrNil and not vHintType and vKind == Enum.SymbolKind_LOCAL then
		nSymbolContext:warn("define a symbol without any type")
	end
	if vHintType then
		nTerm = nSymbolContext:assignTermToType(nTerm, vHintType)
	else
		local nTermInHolder = nTerm:getRefineTerm()
		if not nTermInHolder then
			if vModify then
				error(nSymbolContext:newException("auto variable can't be modified"))
			elseif vKind == Enum.SymbolKind_LOCAL then
				error(nSymbolContext:newException("auto variable can't be defined as local"))
			end
			return nTopBranch:setSymbolByNode(vNode, nTerm)
		end
		nTerm = nTermInHolder
		local nFromType = nTerm:getType()
		             
		if vModify and vKind == Enum.SymbolKind_LOCAL then
			local nToType = nSymbolContext:getTypeManager():literal2Primitive(nFromType)
			if nFromType ~= nToType then
				nTerm = nSymbolContext:RefineTerm(nToType)
			end
		end
		nFromType:setAssigned(nSymbolContext)
	end
	local nImmutVariable = nTerm:attachImmutVariable()
	if vModify then
		local nLocalSymbol = LocalSymbol.new(nSymbolContext, vNode, nTerm:getType(), nTerm)
		self:topBranch():mutMark(nLocalSymbol, nImmutVariable)
		return nTopBranch:setSymbolByNode(vNode, nLocalSymbol)
	else
		nImmutVariable:setNode(vNode)
		return nTopBranch:setSymbolByNode(vNode, nImmutVariable)
	end
end


function InstStack:IF_ONE(
	vNode,
	vTerm,
	vTrueFunction, vBlockNode
)
	local nIfContext = self:newOperContext(vNode)
	local nTrueCase = vTerm:caseTrue()
	local nFalseCase = vTerm:caseFalse()
	local nBeforeBranch = self:topBranch()
	if nTrueCase then
		local nTrueBranch = self:_withBranch(nTrueCase, vTrueFunction, vBlockNode)
		nBeforeBranch:mergeOneBranch(nIfContext, nTrueBranch, nFalseCase)
	end
end

function InstStack:IF_TWO(
	vNode,
	vTerm,
	vTrueFunction, vTrueBlock,
	vFalseFunction, vFalseBlock
)
	local nIfContext = self:newOperContext(vNode)
	local nTrueCase = vTerm:caseTrue()
	local nFalseCase = vTerm:caseFalse()
	local nBeforeBranch = self:topBranch()
	if nTrueCase then
		local nTrueBranch = self:_withBranch(nTrueCase, vTrueFunction, vTrueBlock)
		if nFalseCase then
			local nFalseBranch = self:_withBranch(nFalseCase, vFalseFunction, vFalseBlock)
			nBeforeBranch:mergeTwoBranch(nIfContext, nTrueBranch, nFalseBranch)
		else
			nBeforeBranch:mergeOneBranch(nIfContext, nTrueBranch, nFalseCase)
		end
	elseif nFalseCase then
		local nFalseBranch = self:_withBranch(nFalseCase, vFalseFunction, vFalseBlock)
		nBeforeBranch:mergeOneBranch(nIfContext, nFalseBranch, nTrueCase)
	end
end

function InstStack:REPEAT(vNode, vFunc, vTerm)
	self:_withBranch(VariableCase.new(), vFunc, vNode[1])
end

function InstStack:WHILE(vNode, vTerm, vTrueFunction)
	local nTrueCase = vTerm:caseTrue()
	self:_withBranch(nTrueCase or VariableCase.new(), vTrueFunction,  vNode[2])
end

function InstStack:DO(vNode, vHintInfo, vDoFunc)
	local nBuilder = DoBuilder.new(self, vNode)
	nBuilder:build(vHintInfo)
	if not nBuilder.pass then
		self:_withBranch(VariableCase.new(), vDoFunc, vNode[1])
	end
end

function InstStack:FOR_IN(vNode, vFunc, vNextSelfInit)
	local nForContext = self:newOperContext(vNode)
	local nLenNext = #vNextSelfInit
	if nLenNext < 1 or nLenNext > 3 then
		nForContext:error("FOR_IN iterator error, arguments number must be 1 or 2 or 3")
		return
	end
	local nNext = vNextSelfInit:get(nForContext, 1)
	local nTuple = self:META_CALL(vNode, nNext, function ()
		if nLenNext == 1 then
			return nForContext:FixedTermTuple({})
		else
			local nSelf = vNextSelfInit:get(nForContext, 2)
			if nLenNext == 2 then
				return nForContext:FixedTermTuple({nSelf})
			else
				if nLenNext == 3 then
					local nInit = vNextSelfInit:get(nForContext, 3)
					return nForContext:FixedTermTuple({nSelf, nInit})
				else
					error("NextSelfInit tuple must be 3, this branch is impossible")
				end
			end
		end
	end)
	if #nTuple <= 0 then
		self:getRuntime():nodeError(vNode, "FOR_IN must receive at least 1 value when iterator")
		return
	end
	assert(TermTuple.isFixed(nTuple), "iter func can't return auto term")
	local nFirstTerm = nTuple:get(nForContext, 1)
	local nFirstType = nFirstTerm:getType()
	if not nFirstType:isNilable() then
		self:getRuntime():nodeError(vNode, "FOR_IN must receive nilable type")
		return
	end
	if nFirstType:notnilType():isNever() then
		return
	end
	nFirstTerm:foreach(function(vAtomType, vCase)
		if vAtomType:isNilable() then
			return
		end
		local nTermList = {nForContext:RefineTerm(vAtomType)}
		   
			  
		
		for i=2, #nTuple do
			local nTerm = nTuple:get(nForContext, i)
			local nType = vCase[nTerm:attachImmutVariable()]
			if nType then
				nTerm = nForContext:RefineTerm(nType)
			end
			nTermList[i] = nTerm
		end
		local nNewTuple = nForContext:FixedTermTuple(nTermList)
		self:_withBranch(vCase, function()
			vFunc(nNewTuple)
		end, vNode[3])
	end)
end

function InstStack:FOR_NUM(
	vNode,
	vStart,
	vStop,
	vStepOrNil,
	vFunc,
	vBlockNode
)
	local nForContext = self:newOperContext(vNode)
	self:_withBranch(VariableCase.new(), function()
		vFunc(nForContext:RefineTerm(self:getTypeManager().type.Integer))
	end, vBlockNode)
end

function InstStack:LOGIC_OR(vNode, vLeftTerm, vRightFunction)
	local nOrContext = self:newLogicContext(vNode)
	local nLeftTrueTerm = nOrContext:logicTrueTerm(vLeftTerm)
	local nLeftFalseCase = vLeftTerm:caseFalse()
	if not nLeftFalseCase then
		return nLeftTrueTerm
	else
		local nRightTerm = nil
		self:_withBranch(nLeftFalseCase, function()
			nRightTerm = vRightFunction()
		end)
		assert(nRightTerm, "term must be true value here")
		return nOrContext:logicCombineTerm(nLeftTrueTerm, nRightTerm, nLeftFalseCase)
	end
end

function InstStack:LOGIC_AND(vNode, vLeftTerm, vRightFunction)
	local nAndContext = self:newLogicContext(vNode)
	local nLeftFalseTerm = nAndContext:logicFalseTerm(vLeftTerm)
	local nLeftTrueCase = vLeftTerm:caseTrue()
	if not nLeftTrueCase then
		return nLeftFalseTerm
	else
		local nRightTerm = nil
		self:_withBranch(nLeftTrueCase, function()
			nRightTerm = vRightFunction()
		end)
		assert(nRightTerm, "term must be true value here")
		return nAndContext:logicCombineTerm(nLeftFalseTerm, nRightTerm, nLeftTrueCase)
	end
end

function InstStack:LOGIC_NOT(vNode, vData)
	local nNotContext = self:newLogicContext(vNode)
	return nNotContext:logicNotTerm(vData)
end

function InstStack:BREAK(vNode)
	self:topBranch():setStop()
end

function InstStack:RETURN(vNode, vTermTuple)
	error("implement RETURN in OpenStack or SealStack")
end

function InstStack:END(vNode) 
	error("implement END in OpenStack or SealStack")
	return self._fastOper:FixedTermTuple({}), self._manager.type.String
end

function InstStack:GLOBAL_GET(vNode, vIdentENV)
	local nEnvTerm = self:SYMBOL_GET(vNode, vIdentENV, false)
	assert(not AutoHolder.is(nEnvTerm), "auto can't be used here")
	return self:META_GET(vNode, nEnvTerm, self:LITERAL_TERM(vNode, vNode[1]), false)
end

function InstStack:GLOBAL_SET(vNode, vIdentENV, vValueTerm)
	local nEnvTerm = self:SYMBOL_GET(vNode, vIdentENV, false)
	assert(not AutoHolder.is(nEnvTerm), "auto can't be used here")
	assert(not AutoHolder.is(vValueTerm), "auto can't be used here")
	self:META_SET(vNode, nEnvTerm, self:LITERAL_TERM(vNode, vNode[1]), vValueTerm)
end

function InstStack:INJECT_GET(
	vNode,
	vInjectGetter
)
	return vInjectGetter(vNode)
end

function InstStack:INJECT_BEGIN(vNode) 
	local nSpace = assert(self._namespace)
	return nSpace.localExport, nSpace.globalExport
end

return InstStack

end end
--thlua.runtime.InstStack end ==========)

--thlua.runtime.OpenStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.OpenStack'] = function (...)

local Exception = require "thlua.Exception"
local TermTuple = require "thlua.tuple.TermTuple"
local class = require "thlua.class"
local InstStack = require "thlua.runtime.InstStack"


	  


local OpenStack = class (InstStack)

function OpenStack:ctor(
	vRuntime,
	vNode,
	vUpState,
	vBodyFn,
	vApplyStack,
	vIsRequire
)
	self._applyStack = vApplyStack
	self._bodyFn = vBodyFn
	self._isRequire = vIsRequire
	local nErrCollection = self._manager:TypeCollection()
	nErrCollection:put(self._manager.type.String)
	self._errCollection = nErrCollection
end

function OpenStack:isRequire()
	return self._isRequire
end

function OpenStack:RAISE_ERROR(vContext, vType)
	self._errCollection:put(vType)
end

function OpenStack:RETURN(vNode, vTermTuple)
	assert(TermTuple.isFixed(vTermTuple), Exception.new("can't return auto term", vNode))
	table.insert(self._retList, vTermTuple)
	self:topBranch():setStop()
end

function OpenStack:mergeEndErrType()
	return self._errCollection:mergeToAtomUnion()
end

function OpenStack:END(vNode) 
	self:getNamespace():close()
	local nRetList = self._retList
	local nLen = #nRetList
	if nLen == 0 then
		return self._fastOper:FixedTermTuple({}), self._errCollection:mergeToAtomUnion()
	elseif nLen == 1 then
		return nRetList[1], self._errCollection:mergeToAtomUnion()
	else
		error("TODO : open-function has more than one return")
	end
end

function OpenStack:findRequireStack()
	local nStack = self
	while not nStack:isRequire() do
		local nApplyStack = nStack:getApplyStack()
		if OpenStack.is(nApplyStack) then
			nStack = nApplyStack
		else
			return false
		end
	end
	return nStack
end

function OpenStack:getSealStack()
	return self._applyStack:getSealStack()
end

function OpenStack:getApplyStack()
	return self._applyStack
end

return OpenStack

end end
--thlua.runtime.OpenStack end ==========)

--thlua.runtime.SealStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.SealStack'] = function (...)

local TermTuple = require "thlua.tuple.TermTuple"
local Exception = require "thlua.Exception"
local class = require "thlua.class"
local InstStack = require "thlua.runtime.InstStack"
local ClassFactory = require "thlua.func.ClassFactory"
local SealFunction = require "thlua.func.SealFunction"
local AutoFunction = require "thlua.func.AutoFunction"


	  
	  


local SealStack = class (InstStack)

function SealStack:ctor(
	vRuntime,
	vNode,
	vUpState,
	vBodyFn 
)
	self._classFnSet={}   
	self._autoFnSet={}   
	self._bodyFn = vBodyFn
	self._classTable=false
end

function SealStack:setClassTable(vClassTable)
	self._classTable = vClassTable
end

function SealStack:getClassTable()
	return self._classTable
end

function SealStack:_returnCheck(vContext, vTypeTuple)
	local nBodyFn = self._bodyFn
	if AutoFunction.is(nBodyFn) then
		local nOneOkay = false
		local nRetTuples = nBodyFn:getRetTuples()
		if nRetTuples then
			local nMatchSucc, nCastSucc = vContext:returnMatchTuples(vTypeTuple, nRetTuples)
			if not nMatchSucc then
				vContext:error("return match failed")
			elseif not nCastSucc then
				vContext:error("return cast failed")
			end
		end
	elseif ClassFactory.is(nBodyFn) then
		local nResultType = nBodyFn:getClassTable(true)
		if nResultType ~= vTypeTuple:get(1):checkAtomUnion() or #vTypeTuple ~= 1 or vTypeTuple:getRepeatType() then
			vContext:error("class return not match")
		end
	end
end

function SealStack:RAISE_ERROR(vContext, vRaiseErr)
	local nBodyFn = self._bodyFn
	assert(SealFunction.is(nBodyFn))
	local nRetTuples = nBodyFn:getRetTuples()
	local nString = self._manager.type.String
	if nRetTuples then
		local nHintErr = nRetTuples:getErrType()
		if not nHintErr:includeAll(vRaiseErr) then
			if nString:includeAll(nHintErr) then
				     
			else
				   
			end
		end
	else
		if not nString:includeAll(vRaiseErr) then
			     
		end
	end
end

function SealStack:RETURN(vNode, vTermTuple)
	assert(TermTuple.isFixed(vTermTuple), Exception.new("can't return auto term", vNode))
	local nRetContext = self:newReturnContext(vNode)
	table.insert(self._retList, vTermTuple)
	if #vTermTuple <= 0 or vTermTuple:getTail() then
		self:_returnCheck(nRetContext, vTermTuple:checkTypeTuple())
	else
		local nManager = self:getTypeManager()
		nRetContext:unfoldTermTuple(vTermTuple, function(vFirst, vTypeTuple, _)
			self:_returnCheck(nRetContext, vTypeTuple)
		end)
	end
	self:topBranch():setStop()
end

function SealStack:END(vNode) 
	self:getNamespace():close()
	local nBodyFn = self._bodyFn
	local nRetList = self._retList
	if AutoFunction.is(nBodyFn) and not nBodyFn:getRetTuples() then
		local nLen = #nRetList
		if nLen == 0 then
			return self._fastOper:FixedTermTuple({}), self._manager.type.String
		elseif nLen == 1 then
			return nRetList[1], self._manager.type.String
		else
			local nFirstTuple = nRetList[1]:checkTypeTuple()
			for i=2,#nRetList do
				local nOtherTuple = nRetList[i]:checkTypeTuple()
				if not (nFirstTuple:includeTuple(nOtherTuple) and nOtherTuple:includeTuple(nFirstTuple)) then
					error("auto-function can't implicit return mixing type, explicit hint with :Ret(xxx) ")
				end
			end
			return nRetList[1], self._manager.type.String
		end
	else
		return nil, nil
	end
end

function SealStack:seal()
	local nClassFnSet = assert(self._classFnSet, "class set must be true here")
	self._classFnSet = false
	for fn, v in pairs(nClassFnSet) do
		fn:startPreBuild()
		fn:startLateBuild()
	end
	local nAutoFnSet = assert(self._autoFnSet, "maker set must be true here")
	self._autoFnSet = false
	for fn, v in pairs(nAutoFnSet) do
		fn:startPreBuild()
		self._runtime:lateSchedule(fn)
	end
end

function SealStack:getSealStack()
	return self
end

function SealStack:scheduleSealType(vType)
	if ClassFactory.is(vType) then
		local nSet = self._classFnSet
		if nSet then
			nSet[vType] = true
		else
			vType:startPreBuild()
			vType:startLateBuild()
		end
	elseif AutoFunction.is(vType) then
		local nSet = self._autoFnSet
		if nSet then
			nSet[vType] = true
		else
			vType:startPreBuild()
			self._runtime:lateSchedule(vType)
		end
	end
end

function SealStack:rootSetNamespace(vRootSpace)
	assert(not self._namespace, "namespace has been setted")
	self._namespace = vRootSpace
end

function SealStack:getBodyFn()
	return self._bodyFn  
end

function SealStack:isRoot()
	return not self._lexShot
end

return SealStack

end end
--thlua.runtime.SealStack end ==========)

--thlua.server.ApiServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.ApiServer'] = function (...)

local json = require "thlua.server.json"
local BaseServer = require "thlua.server.BaseServer"
local class = require "thlua.class"


	
	

	   
		
		
	

	 
		
		
	

	   
		
	

	   
		
		
	

	   
		
		
	

	   

	   
		
	

	

		   
			
		

		   
			   
				  
			
		   

		   
		   

	

	   
		
		 
			
			
			
		
	

	   
		
		
	

	   
		
	

	   
		   
			
			
			
			
		
	

	  
	 

	  
	 

	   
		  
		
		 
			
			
		
	

	   
		
		
		 
			
			 
			
			 
			 
				
			
			
			
			
			 
			 
		
	

	   
		
		
	

	   
		
		
		
		
		
		
		
		
		
		
		
		
	

	   
		 
		
	



local ApiServer = class (BaseServer)

function ApiServer:ctor()
	self._methodHandler = {
		initialize=function(vParam)
			return self:onInitialize(vParam)
		end,
		shutdown=function()
			self:onShutdown()
		end,
		exit=function()
			self:onExit()
		end,
		["textDocument/didOpen"]=function(vParam)
			return self:onDidOpen(vParam)
		end,
		["textDocument/didChange"]=function(vParam)
			return self:onDidChange(vParam)
		end,
		["textDocument/didSave"]=function(vParam)
			return self:onDidSave(vParam)
		end,
		["textDocument/didClose"]=function(vParam)
			return self:onDidClose(vParam)
		end,
		["textDocument/completion"]=function(vParam)
			return self:onCompletion(vParam) or json.array({})
		end,
		["textDocument/definition"]=function(vParam)
			return self:onDefinition(vParam) or json.array({})
		end,
		["textDocument/typeDefinition"]=function(vParam)
			return self:onTypeDefinition(vParam) or json.array({})
		end,
		["textDocument/references"]=function(vParam)
			return self:onReferences(vParam) or json.array({})
		end,
		["textDocument/hover"]=function(vParam)
			return self:onHover(vParam) or json.array({})
		end,
	}
end

function ApiServer:getMethodHandler()
	return self._methodHandler
end

function ApiServer:getInitializeResult()
	error("getInitializeResult not implement in ApiServer")
end

function ApiServer:onInitialize(vParams)
	if self.initialize then
		error("already initialized!")
	else
		self.initialize = true
	end
	local rootUri = vParams.rootUri
	local root  = vParams.rootPath or (rootUri and self:uriToPath(rootUri))
	self:info("Config.root = ", root, vParams.rootPath, vParams.rootUri)
	self:info("Platform = ", self:getPlatform())
	if root then
		self:setRoot(root)
	end
	return self:getInitializeResult()
end

function ApiServer:onShutdown()
	self.shutdown=true
end

function ApiServer:onExit()
	if self.shutdown then
		os.exit()
	else
		os.exit()
	end
end

function ApiServer:onDidChange(vParams)
end

function ApiServer:onDidOpen(vParams)
end

function ApiServer:onDidSave(vParams)
end

function ApiServer:onDidClose(vParams)
end

function ApiServer:onDefinition(vParams)
	return nil
end

function ApiServer:onCompletion(vParams)
	return {}
end

function ApiServer:onHover(vParams)
end

function ApiServer:onReferences(vParams)
end

function ApiServer:onTypeDefinition(vParams)
end

return ApiServer

end end
--thlua.server.ApiServer end ==========)

--thlua.server.BaseServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.BaseServer'] = function (...)

local json = require "thlua.server.json"
local Exception = require "thlua.Exception"
local ErrorCodes = require "thlua.server.protocol".ErrorCodes
local CodeEnv = require "thlua.code.CodeEnv"
local FileState = require "thlua.server.FileState"
local class = require "thlua.class"


	
	
	


local BaseServer = class ()

function BaseServer:ctor()
	self.initialize=false
	self.shutdown=false
	self._rootPath=""
	self._fileStateDict={} 
end

function BaseServer:getMethodHandler()
	error("get method handler is not implement in BaseServer")
end

function BaseServer:attachFileState(vFileUri)
	local nFileState = self._fileStateDict[vFileUri]
	if not nFileState then
		local nNewState = FileState.new(vFileUri)
		self._fileStateDict[vFileUri] = nNewState
		return nNewState
	else
		return nFileState
	end
end

function BaseServer:thluaSearch(vPath) 
	local thluaPath = self._rootPath.."/?.thlua"
	local fileName, err1 = package.searchpath(vPath, thluaPath)
	if not fileName then
		return false, err1
	end
	return true, self:pathToUri(fileName)
end

function BaseServer:thluaParseFile(vFileUri)
	if not self._fileStateDict[vFileUri] then
		local nFilePath = self:uriToPath(vFileUri)
		local file, err = io.open(nFilePath, "r")
		if not file then
			error(err)
		end
		local nContent = file:read("*a")
		file:close()
		self:attachFileState(vFileUri):syncContent(nContent, -1)
	end
	return self._fileStateDict[vFileUri]:checkLatestEnv()
end

function BaseServer:checkFileState(vFileUri)
	return (assert(self._fileStateDict[vFileUri], "file not existed:"..vFileUri))
end

function BaseServer:mainLoop()
	self:notify("$/status/report", {
		text="hello",
		tooltip="hello",
	})
	while not self.shutdown do
		self:rpc()
	end
end

local function reqToStr(vRequest)
	return "["..tostring(vRequest.method)..(vRequest.id and ("$"..vRequest.id) or "").."]"
end

function BaseServer:rpc()
	local request = self:readRequest()
	local methodName = request.method
	local nId = request.id
	if not methodName then
		if nId then
			self:writeError(nId, ErrorCodes.ParseError, "method name not set", "")
		else
			self:warn(reqToStr(request), "method name not set")
		end
		return
	end
	local handler = self:getMethodHandler()[methodName]
	if not handler then
		if nId then
			self:writeError(nId, ErrorCodes.MethodNotFound, "method not found", "method="..tostring(methodName))
		else
			self:warn(reqToStr(request), "method not found")
		end
		return
	end
	local result = handler(request.params)
	if result then
		if nId then
			self:writeResult(nId, result)
			  
		else
			self:warn(reqToStr(request), "request without id ")
		end
		return
	else
		if nId then
			self:warn(reqToStr(request), "request with id but no resposne")
		end
	end
end

function BaseServer:readRequest()
	   
	local length = -1
	while true do
		local line = io.read("*l")
		if not line then
			error("io.read fail")
		end
		line = line:gsub("\13", "")
		if line == "" then
			break
		end
		local key, val = line:match("([^:]+): (.+)")
		if not key or not val then
			error("header format error:"..line)
		end
		if key == "Content-Length" then
			length = assert(math.tointeger(val), "Content-Length can't convert to integer"..tostring(val))
		end
	end

	if length < 0 then
		error("Content-Length failed in rpc")
	end

	   
	local data = io.read(length)
	if not data then
		error("read nothing")
	end
	data = data:gsub("\13", "")
	local obj, err = json.decode(data)
	if type(obj) ~= "table" then
		error("json decode error:"..tostring(err))
	end
	local req = obj  
	if req.jsonrpc ~= "2.0" then
		error("json-rpc is not 2.0, "..tostring(req.jsonrpc))
	end
	     
	return req
end

function BaseServer:writeError(vId  , vCode, vMsg, vData)
	self:_write({
		jsonrpc = "2.0",
		id = vId,
		error = {
			code = vCode,
			message = vMsg,
			data = vData,
		}
	})
end

function BaseServer:writeResult(vId  , vResult)
	self:_write({
		jsonrpc = "2.0",
		id = vId,
		result = vResult,
	})
end

function BaseServer:notify(vMethod, vParams)
	self:_write({
		jsonrpc = "2.0",
		method = vMethod,
		params = vParams,
	})
end

function BaseServer:getPlatform()
	if package.config:sub(1,1) == "\\" then
		return "win"
	else
		return "not-win"
	end
end

function BaseServer:_write(vPacket)
	local data = json.encode(vPacket)
	if self:getPlatform() == "win" then
		data = ("Content-Length: %d\n\n%s"):format(#data, data)
	else
		data = ("Content-Length: %d\r\n\r\n%s"):format(#data, data)
	end
	io.write(data)
	io.flush()
end

local MessageType = {}

MessageType.ERROR = 1
MessageType.WARNING = 2
MessageType.INFO = 3
MessageType.DEBUG = 4

function BaseServer:packToString(vDepth, ...)
	local nInfo = debug.getinfo(vDepth)
	local nPrefix = nInfo.source..":"..nInfo.currentline
	local l = {nPrefix}  
	for i=1,select("#", ...) do
		l[#l + 1] = tostring(select(i, ...))
	end
	return table.concat(l, " ")
end

function BaseServer:error(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.ERROR,
	})
end

function BaseServer:warn(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.WARNING,
	})
end

function BaseServer:info(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.INFO,
	})
end

function BaseServer:debug(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.DEBUG,
	})
end

function BaseServer:setRoot(vRoot)
	   
	  
	self._rootPath = vRoot
end

function BaseServer:uriToPath(vUri)
	local nPath = vUri:gsub("+", ""):gsub("%%(..)", function(c)
		return string.char(tonumber(c, 16))
	end)
	if self:getPlatform() == "win" then
		return (nPath:gsub("^file:///", ""):gsub("/$", ""))
	else
		return (nPath:gsub("^file://", ""):gsub("/$", ""))
	end
end

function BaseServer:pathToUri(vPath)
	if self:getPlatform() == "win" then
		local nUri = vPath:gsub("\\", "/"):gsub("([a-zA-Z]):", function(driver)
			return driver.."%3A"
		end)
		return "file:///"..nUri
	else
		return "file://"..vPath
	end
end

return BaseServer

end end
--thlua.server.BaseServer end ==========)

--thlua.server.FastServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.FastServer'] = function (...)

local FieldCompletion = require "thlua.context.FieldCompletion"
local json = require "thlua.server.json"
local Exception = require "thlua.Exception"
local ErrorCodes = require "thlua.server.protocol".ErrorCodes
local CompletionRuntime = require "thlua.runtime.CompletionRuntime"
local CodeEnv = require "thlua.code.CodeEnv"
local FileState = require "thlua.server.FileState"
local ApiServer = require "thlua.server.ApiServer"
local ParseEnv = require "thlua.code.ParseEnv"
local class = require "thlua.class"


	
	
	


local FastServer = class (ApiServer)

function FastServer:ctor()
	self._runtime=nil
end

function FastServer:getInitializeResult()
	self:info("fast server")
	return {
		capabilities = {
			textDocumentSync = {
				openClose = true,
				change = 2,       
				save = { includeText = true },
			},
			definitionProvider = true,
			hoverProvider = true,
			completionProvider = {
				triggerCharacters = {".",":"},
				resolveProvider = false
			},
			  
			  
			  
			  
			  
			  
			  
			  
		},
	}
end

function FastServer:rerun(vFileName)
	local ok, rootFileName = self:thluaSearch("root")
	if not ok then
		rootFileName = vFileName
		self:info("root.thlua not found, run single file:", rootFileName)
	else
		self:info("root.thlua found:", rootFileName)
	end
	local nRuntime=CompletionRuntime.new(self)
	local ok, exc = nRuntime:pmain(rootFileName)
	if not ok then
		if not self._runtime then
			self._runtime = nRuntime
		end
		return
	end
	self._runtime = nRuntime
	collectgarbage()
end

function FastServer:checkRuntime()
	return assert(self._runtime)
end

function FastServer:onDidChange(vParams)
	local nFileUri = vParams.textDocument.uri
	if self:attachFileState(nFileUri):syncChangeMayRerun(vParams) then
		self:rerun(nFileUri)
	end
end

function FastServer:onDidOpen(vParams)
	local nContent = vParams.textDocument.text
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:attachFileState(nFileUri)
	if nFileState:contentMismatch(nContent) then
		if nFileState:syncContent(nContent, vParams.textDocument.version) then
			self:rerun(nFileUri)
		end
	end
end

function FastServer:onDidSave(vParams)
	local nFileUri = vParams.textDocument.uri
	local nContent = vParams.text
	local nFileState = self:attachFileState(nFileUri)
	if nContent then
		if nFileState:contentMismatch(nContent) then
			self:warn("content mismatch when save")
		end
	end
	if nFileState:onSaveAndGetChange() then
		self:rerun(nFileUri)
	end
end

function FastServer:lookup(vParams)  
	return nil
end

function FastServer:onDefinition(vParams)
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:checkFileState(nFileUri)
	local nSplitCode = nFileState:getSplitCode()
	local nLine = vParams.position.line + 1
	local nColumn = vParams.position.character + 1
	local nPos = nSplitCode:lcToPos(nLine, nColumn)
	      
	local nRightEnv = nFileState:getRightEnv()
	if nRightEnv then
		local nNode = nRightEnv:searchIdent(nPos)
		if nNode then
			local nDefineNode = nNode.kind == "def" and nNode or nNode.defineIdent
			if nDefineNode then
				return {
					uri=vParams.textDocument.uri,
					range={
						start={ line=nDefineNode.l - 1, character=nDefineNode.c-1, },
						["end"]={ line=nDefineNode.l - 1, character=nDefineNode.c - 1 },
					}
				}
			end
		end
	end
	            
	local nCompletionRuntime = self:checkRuntime()
	local nSuccEnv = nCompletionRuntime:getCodeEnv(nFileUri)
	if not nSuccEnv then
		self:info("goto definition fail, maybe some error in code")
		return nil
	end
	if nSuccEnv:getSplitCode():getLine(nLine) ~= nSplitCode:getLine(nLine) then
		self:info("TODO, if line not same, need rerun or check if split code has syntax error")
		return nil
	end
	local nPos = nSuccEnv:getSplitCode():lcToPos(nLine, nColumn)
	   
	local nExprNode, nFocusList = nSuccEnv:searchExprBySuffix(nPos)
	if nExprNode then
		nCompletionRuntime:focusSchedule(nFocusList)
		local nLookupNode = nCompletionRuntime:nodeLookup(nExprNode)
		if not nLookupNode then
			self:info("not found lookup node"..tostring(nExprNode), nExprNode.tag)
			return nil
		end
		return {
			uri=nLookupNode.path,
			range={
				start={ line=nLookupNode.l - 1, character=nLookupNode.c-1, },
				["end"]={ line=nLookupNode.l - 1, character=nLookupNode.c - 1 },
			}
		}
	end
	    
	local nHintExprNode, nBlockNode, nFocusList = nSuccEnv:searchHintExprBySuffix(nPos)
	if not nHintExprNode then
		self:info("no target expr")
		return nil
	end
	local nExprContent = nSuccEnv:getSplitCode():getContent():sub(nHintExprNode.pos, nHintExprNode.posEnd - 1)
	local nWrongContent = string.rep(" ", nHintExprNode.pos) .. "(@" .. nExprContent .. "."
	local nInjectFn, nInjectTrace = CodeEnv.genInjectFnByError(nSplitCode, nFileUri, nWrongContent)
	if not nInjectFn then
		return nil
	end
	nCompletionRuntime:focusSchedule(nFocusList)
	   
	local nFieldCompletion = nCompletionRuntime:injectCompletion(nInjectTrace.pos, nBlockNode, nInjectFn, self)
	if not nFieldCompletion then
		self:info("completion fail for no branch", nBlockNode, nBlockNode.tag)
		return nil
	end
	local nLookupNode = nCompletionRuntime:injectLookup(nInjectTrace.pos, nBlockNode, nInjectFn)
	if not nLookupNode then
		return nil
	end
	return {
		uri=nLookupNode.path,
		range={
			start={ line=nLookupNode.l - 1, character=nLookupNode.c-1, },
			["end"]={ line=nLookupNode.l - 1, character=nLookupNode.c - 1 },
		}
	}
end

function FastServer:onCompletion(vParams)
	local nCompletionRuntime = self._runtime
	    
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:checkFileState(nFileUri)
	local nSuccEnv = self:checkRuntime():getCodeEnv(nFileUri)
	if not nSuccEnv then
		self:info("completion fail for some code error")
		return nil
	end
	   
	local nSplitCode = nFileState:getSplitCode()
	local nPos = nSplitCode:lcToPos(vParams.position.line+1, vParams.position.character+1)
	local nWrongContent = nSplitCode:getContent():sub(1, nPos-1)
	    
	local nInjectFn, nInjectTrace = CodeEnv.genInjectFnByError(nSplitCode, nFileUri, nWrongContent)
	if not nInjectFn then
		return nil
	end
	             
	local nInjectNode, nTraceList = assert(nInjectTrace.capture.injectNode), nInjectTrace.traceList
	local nBlockNode, nFuncList = nSuccEnv:traceBlockRegion(nTraceList)
	nCompletionRuntime:focusSchedule(nFuncList)
	   
	local nFieldCompletion = nCompletionRuntime:injectCompletion(nInjectNode.pos, nBlockNode, nInjectFn, self)
	if not nFieldCompletion then
		self:info("completion fail for no branch", nBlockNode, nBlockNode.tag)
		return nil
	end
	local nRetList = {}
	nFieldCompletion:foreach(function(vKey, vValue)
		nRetList[#nRetList + 1] = {
			label=vKey,
			kind=2,
		}
	end)
	return json.array(nRetList)
end

function FastServer:onHover(vParams)
	
	   
	         
	  
		   
		   
		     
			    
		
		    
		 
			  
				
				
			  
		
	
end

return FastServer

end end
--thlua.server.FastServer end ==========)

--thlua.server.FileState begin ==========(
do local _ENV = _ENV
packages['thlua.server.FileState'] = function (...)

local CodeEnv = require "thlua.code.CodeEnv"
local SplitCode = require "thlua.code.SplitCode"
local class = require "thlua.class"


	
	
	


local FileState = class ()

local CHANGE_ANYTHING = 1
local CHANGE_NONBLANK = 2

function FileState:ctor(vFileName)
	self._rightEnv = false
	self._fileName = vFileName
	self._splitCode = SplitCode.new("")
	self._errOrEnv = nil 
	self._version = (-1) 
	self._changeState = false  
end

function FileState:onSaveAndGetChange()
	if self._changeState then
		self._changeState = false
		return true
	end
	return false
end

function FileState:getWellformedRange(vRange)
	local nStart = vRange.start
	local nEnd = vRange["end"]
	if nStart.line > nEnd.line or (nStart.line == nEnd.line and nStart.character > nEnd.character) then
		return { start=nEnd, ["end"]=nStart }
	else
		return vRange
	end
end

function FileState:syncChangeMayRerun(vParams)
	local nCanRerun = self:syncChangeNoRerun(vParams)
	if nCanRerun then
		self._changeState = false
		return true
	else
		return false
	end
end

function FileState:syncChangeNoRerun(vParams)
	local nChanges = vParams.contentChanges
	local nSplitCode = self._splitCode
	local nLineChange = false
	for _, nChange in ipairs(nChanges) do
		local nRawRange = nChange.range
		if nRawRange then
			local nRange = self:getWellformedRange(nRawRange)
			local nChangeText = nChange.text
			local nContent = nSplitCode:getContent()
			local nRangeStart = nRange.start
			local nRangeEnd = nRange["end"]
			local nStartPos = nSplitCode:lcToPos(nRangeStart.line + 1, nRangeStart.character + 1)
			local nFinishPos = nSplitCode:lcToPos(nRangeEnd.line + 1, nRangeEnd.character + 1)
			local nNewContent = nContent:sub(1, nStartPos - 1) .. nChangeText .. nContent:sub(nFinishPos, #nContent)
			local nRemoveText = nContent:sub(nStartPos, nFinishPos-1)
			if nChangeText:find("[\r\n]") or nRemoveText:find("[\r\n]") then
				nLineChange = true
			end
			if nChangeText:find("[^%s]") or nRemoveText:find("[^%s]") then
				self._changeState = CHANGE_NONBLANK
			end
			nSplitCode = SplitCode.new(nNewContent)
		else
			nSplitCode = SplitCode.new(nChange.text)
		end
		if not self._changeState then
			self._changeState = CHANGE_ANYTHING
		end
	end
	self._splitCode = nSplitCode
	self._version = vParams.textDocument.version
	local nRight = self:_checkRight()
	if nRight then
		if self._changeState == CHANGE_NONBLANK and nLineChange then
			return true
		else
			return false
		end
	else
		return false
	end
end

function FileState:_checkRight()
	local nOkay, nCodeEnv = pcall(CodeEnv.new, self._splitCode:getContent(), self._fileName)
	if nOkay then
		self._rightEnv = nCodeEnv
		self._errOrEnv = nCodeEnv
		return true
	else
		if type(nCodeEnv) == "table" then
			self._errOrEnv = nCodeEnv
		end
		return false
	end
end

function FileState:syncContent(vContent, vVersion)
	self._version = vVersion
	self._splitCode = SplitCode.new(vContent)
	self._changeState = false
	return self:_checkRight()
end

function FileState:getRightEnv()
	return self._rightEnv
end

function FileState:contentMismatch(vContent)
	local nSplitCode = self._splitCode
	local nContent = nSplitCode:getContent()
	if nContent ~= vContent then
		return true
	else
		return false
	end
end

function FileState:checkLatestEnv()
	local nLatest = self._errOrEnv
	if CodeEnv.is(nLatest) then
		return nLatest
	else
		error(nLatest)
	end
end

function FileState:getSplitCode()
	return self._splitCode
end

function FileState:getVersion()
	return self._version
end

return FileState

end end
--thlua.server.FileState end ==========)

--thlua.server.PlayGround begin ==========(
do local _ENV = _ENV
packages['thlua.server.PlayGround'] = function (...)


local class = require "thlua.class"
local json = require "thlua.server.json"

local SplitCode = require "thlua.code.SplitCode"
local CodeEnv = require "thlua.code.CodeEnv"
local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"


      
       
         
            
            
        
        
    
       
        
        
        
    


local PlayGround = class ()

function PlayGround:ctor()
    self._splitCode = SplitCode.new("")
    self._codeEnv = nil
end

function PlayGround:thluaParseFile(vFileName)
    return CodeEnv.new(self._splitCode, vFileName)
end

function PlayGround:thluaSearch(vPath)
    return false, "can't use require on playground"
end

function PlayGround:update(vName, vData)
    local nInput = (json.decode(vData) ) 
    local ret = self:_update(vName, nInput)
    return json.encode(ret)
end

function PlayGround:_update(vName, vInput)
    local nContent = vInput.content
    local nCode = SplitCode.new(nContent)
    self._splitCode = nCode
    local nParseOkay, nCodeEnv = pcall(CodeEnv.new, nCode, vName)
    if not nParseOkay then
        local nDia = {
            node={
                path=vName,
                l=1,
                c=1,
            }  ,
            msg=tostring(nCodeEnv),
            severity=1,
        }
        if type(nCodeEnv) == "table" then
            nDia.node = {
                path=nCodeEnv.node.path,
                l=nCodeEnv.node.l,
                c=nCodeEnv.node.c,
            }  
            nDia.msg = nCodeEnv.msg
        end
        return {
            syntaxErr=true,
            diaList=json.array({nDia} ),
            luaContent=tostring(nCodeEnv),
        }
    end
    local nRuntime = DiagnosticRuntime.new(self)
    local nRunOkay, nExc = nRuntime:pmain(vName)
    local nDiaList = nRuntime:getAllDiagnostic()[vName] or {}
    local nAfterDiaList = {}
    for i, dia in ipairs(nDiaList) do
        nAfterDiaList[i] = {
            msg = dia.msg,
            severity = dia.severity,
            node = {
                l=dia.node.l,
                c=dia.node.c,
                path=dia.node.path
            }  ,
        }
    end
    return {
        syntaxErr=false,
        diaList=json.array(nAfterDiaList),
        luaContent=nCodeEnv:genLuaCode()
    }
end

return PlayGround
end end
--thlua.server.PlayGround end ==========)

--thlua.server.SlowServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.SlowServer'] = function (...)

local json = require "thlua.server.json"
local Exception = require "thlua.Exception"
local ErrorCodes = require "thlua.server.protocol".ErrorCodes
local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"
local CodeEnv = require "thlua.code.CodeEnv"
local FileState = require "thlua.server.FileState"
local ApiServer = require "thlua.server.ApiServer"
local FastServer = require "thlua.server.FastServer"
local class = require "thlua.class"


	
	
	


local SlowServer = class (FastServer)

function SlowServer:checkDiagnosticRuntime()
	return (assert(self._runtime) ) 
end

function SlowServer:getInitializeResult()
	self:info("slow server")
	return {
		capabilities = {
			textDocumentSync = {
				openClose = true,
				change = 2,       
				save = { includeText = true },
			},
		},
	}
end

function SlowServer:publishNormal()
	local nRuntime = self:checkDiagnosticRuntime()
	local nFileToList = nRuntime:getAllDiagnostic()
	for nFileName, nFileState in pairs(self._fileStateDict) do
		local nRawDiaList = nFileToList[nFileName] or {}
		local nVersion = nFileState:getVersion()
		local nDiaList = {}
		local nSplitCode = nFileState:getSplitCode()
		for _, dia in ipairs(nRawDiaList) do
			local nNode = dia.node
			local nLineContent = nSplitCode:getLine(nNode.l)
			local nRangeEnd = nNode.pos == nNode.posEnd and {
				nNode.l, nNode.c + (nLineContent and #nLineContent + 10 or 100)
			} or {nSplitCode:fixupPos(nNode.posEnd)}
			local nMsg = dia.msg
			nDiaList[#nDiaList + 1] = {
				range={
					start={
						line=nNode.l-1,
						character=nNode.c-1,
					},
					["end"]={
						line=nRangeEnd[1]-1,
						character=nRangeEnd[2]-1,
					}
				},
				message=nMsg,
				severity=dia.severity,
			}
		end
		self:_write({
			jsonrpc = "2.0",
			method = "textDocument/publishDiagnostics",
			params = {
				uri=nFileName,
				version=nVersion,
				diagnostics=json.array(nDiaList),
			},
		})
	end
end

function SlowServer:publishException(vException )
	local nNode = nil
	local nMsg = ""
	if Exception.is(vException) then
		nNode = vException.node or self._runtime:getNode()
		nMsg = vException.msg or "exception's msg field is missing"
	else
		nNode = self._runtime:getNode()
		nMsg = "root error:"..tostring(vException)
	end
	local nFileState = self._fileStateDict[nNode.path]
	self:_write({
		jsonrpc = "2.0",
		method = "textDocument/publishDiagnostics",
		params = {
			uri=nNode.path,
			version=nFileState:getVersion(),
			diagnostics={ {
				range={
					start={
						line=nNode.l-1,
						character=0,
					},
					["end"]={
						line=nNode.l-1,
						character=100,
					}
				},
				message=nMsg,
			} }
		},
	})
end

function SlowServer:rerun(vFileUri)
	local ok, rootFileUri = self:thluaSearch("root")
	if not ok then
		rootFileUri = vFileUri
		self:info("root.thlua not found, run single file:", rootFileUri)
	else
		self:info("root.thlua found:", rootFileUri)
	end
	local nRuntime=DiagnosticRuntime.new(self)
	local ok, exc = nRuntime:pmain(rootFileUri)
	if not ok then
		if not self._runtime then
			self._runtime = nRuntime
		end
		self:publishException(exc   )
		return
	end
	self._runtime = nRuntime
	collectgarbage()
	self:publishNormal()
end

function SlowServer:onDidChange(vParams)
	self:attachFileState(vParams.textDocument.uri):syncChangeNoRerun(vParams)
end

function SlowServer:onDidOpen(vParams)
	local nContent = vParams.textDocument.text
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:attachFileState(nFileUri)
	if nFileState:contentMismatch(nContent) then
		nFileState:syncContent(nContent, vParams.textDocument.version)
		self:rerun(nFileUri)
	end
end

function SlowServer:onDidSave(vParams)
	local nFileUri = vParams.textDocument.uri
	local nContent = vParams.text
	local nFileState = self:attachFileState(nFileUri)
	nFileState:onSaveAndGetChange()
	self:rerun(nFileUri)
end

return SlowServer

end end
--thlua.server.SlowServer end ==========)

--thlua.server.json begin ==========(
do local _ENV = _ENV
packages['thlua.server.json'] = function (...)
local rapidjson = require('rapidjson')
local decode = rapidjson.decode
local function recursiveCast(t)
	local nType = type(t)
	if nType == "userdata" and t == rapidjson.null then
		return nil
	elseif nType == "table" then
		local re = {}
		for k,v in pairs(t) do
			re[k] = recursiveCast(v)
		end
		return re
	else
		return t
	end
end
local json = {}
json.decode = function(data)
	local a,b = decode(data)
	return recursiveCast(a), b
end
json.encode = rapidjson.encode
json.array = function(data)
	return rapidjson.array(data)
end
return json

end end
--thlua.server.json end ==========)

--thlua.server.protocol begin ==========(
do local _ENV = _ENV
packages['thlua.server.protocol'] = function (...)

local ErrorCodes = {
	ParseError = -32700;
	InvalidRequest = -32600;
	MethodNotFound = -32601;
	InvalidParams = -32602;
	InternalError = -32603;

	   
	jsonrpcReservedErrorRangeStart = -32099;


	
	           
	          
	 
	ServerNotInitialized = -32002;
	UnknownErrorCode = -32001;

	   
	jsonrpcReservedErrorRangeEnd = -32000;

	   
	lspReservedErrorRangeStart = -32899;

	
	           
	            
	         
	    
	 
	   
	 
	RequestFailed = -32803;

	
	          
	          
	   
	 
	   
	 
	ServerCancelled = -32802;

	
	           
	        
	            
	         
	            
	 
	              
	       
	 
	ContentModified = -32801;

	
	            
	   
	 
	RequestCancelled = -32800;

	   
	lspReservedErrorRangeEnd = -32800;
}

local SeverityEnum = {
	Error = 1,
	Warn = 2,
	Info = 3,
	Hint = 4,
}





  

   
	  
	  
	  
	  


   
	  
	  
	  
	  


   
	  
	  
	  


   
	
	
		
		
	  
	
	
	
	
		  
		  
		  
		  
		  
		  
	
	
	   


   
	
		
			
			
		
		
		
			
			       
			
				
			
		
		  
		  
		  
	
	 
		
		
	


    

   
	
	
	 
	 
		
	
	
	




return {
	ErrorCodes=ErrorCodes,
	SeverityEnum=SeverityEnum,
}

end end
--thlua.server.protocol end ==========)

--thlua.term.ImmutVariable begin ==========(
do local _ENV = _ENV
packages['thlua.term.ImmutVariable'] = function (...)

local ImmutVariable = {}
ImmutVariable.__index=ImmutVariable
ImmutVariable.__tostring=function(self)
	return "const-"..tostring(next(self._symbolSet) or self._node)
end

  

function ImmutVariable.new(vTerm)
	return setmetatable({
		_term=vTerm,
		_symbolSet={}  ,
		_node=false
	}, ImmutVariable)
end

function ImmutVariable:setNode(vNode)
	self._node = vNode
end

function ImmutVariable:addSymbol(vSymbol)
	self._symbolSet[vSymbol] = true
end

function ImmutVariable:getType()
	return self._term:getType()
end

function ImmutVariable:getTerm()
	return self._term
end

function ImmutVariable.is(v)
	return getmetatable(v) == ImmutVariable
end

return ImmutVariable

end end
--thlua.term.ImmutVariable end ==========)

--thlua.term.LocalSymbol begin ==========(
do local _ENV = _ENV
packages['thlua.term.LocalSymbol'] = function (...)

local RefineTerm = require "thlua.term.RefineTerm"
local ImmutVariable = require "thlua.term.ImmutVariable"

  

local LocalSymbol = {}
LocalSymbol.__index=LocalSymbol
LocalSymbol.__tostring=function(self)
	return "LocalSymbol-"..tostring(self._node).."-"..tostring(self._type)
end

function LocalSymbol.new(vContext,
		vNode, vType, vRawTerm)
	return setmetatable({
		_context=vContext,
		_node=vNode,
		_type=vType,
		_rawTerm=vRawTerm,
	}, LocalSymbol)
end

function LocalSymbol:makeVariable(vType)
	local nTerm = self._context:RefineTerm(vType or self._type)
	local nVariable = nTerm:attachImmutVariable()
	nVariable:addSymbol(self)
	return nVariable
end

function LocalSymbol:getType()
	return self._type
end

function LocalSymbol:getNode()
	return self._node
end

function LocalSymbol:getName()
	return tostring(self._node)
end

function LocalSymbol.is(v)
	return getmetatable(v) == LocalSymbol
end

return LocalSymbol

end end
--thlua.term.LocalSymbol end ==========)

--thlua.term.RefineTerm begin ==========(
do local _ENV = _ENV
packages['thlua.term.RefineTerm'] = function (...)

local ImmutVariable = require "thlua.term.ImmutVariable"
local VariableCase = require "thlua.term.VariableCase"
local Nil = require "thlua.type.Nil"

  

local RefineTerm = {}
RefineTerm.__index=RefineTerm
RefineTerm.__tostring=function(self)
	local l = {}
	for nType, nVariableCase in pairs(self._typeToCase) do
		l[#l + 1] = tostring(nType) .."=>"..tostring(nVariableCase)
	end
	return "RefineTerm("..table.concat(l, ",")..")"
end

function RefineTerm.new(
	vNode,
	vType,
	vTypeToCase )
	local self = setmetatable({
		_node=vNode,
		_typeToCase=vTypeToCase or {} ,
		_type=vType,
		_symbolVariable=false   ,
	}, RefineTerm)
	vType:foreach(function(vType)
		if not self._typeToCase[vType] then
			self._typeToCase[vType] = VariableCase.new()
		end
	end)
	return self
end

function RefineTerm:checkRefineTerm(vContext)
	return self
end

function RefineTerm:foreach(func )
	for nType, nVariableCase in pairs(self._typeToCase) do
		func(nType, nVariableCase)
	end
end

function RefineTerm.is(v)
	return getmetatable(v) == RefineTerm
end

function RefineTerm:caseIsType(vGuardType)
	local nCase = nil
	self._type:foreach(function(vType)
		if vType:intersectSome(vGuardType) then
			nCase = self._typeToCase[vType]
		end
	end)
	if not nCase then
		return nil
	else
		local nReCase = VariableCase.new() & nCase
		local nImmutVariable = self._symbolVariable
		if nImmutVariable then
			nReCase:put_and(nImmutVariable, vGuardType)
		end
		return nReCase
	end
end

function RefineTerm:caseIsNotType(vGuardType)
	local reCase = nil
	self._type:foreach(function(vType)
		local nCase = self._typeToCase[vType]
		if not vGuardType:includeAll(vType) then
			if not reCase then
				reCase = nCase
			else
				reCase = reCase | nCase
			end
		end
	end)
	return reCase
end

function RefineTerm:caseTrue()
	local reCase = nil
	self._type:trueType():foreach(function(vType)
		local nCase = self._typeToCase[vType]
		if not reCase then
			reCase = nCase
		else
			reCase = reCase | nCase
		end
	end)
	return reCase
end

function RefineTerm:caseNotnil()
	local reCase = nil
	self._type:foreach(function(vType)
		if not Nil.is(vType) then
			local nCase = self._typeToCase[vType]
			if not reCase then
				reCase = nCase
			else
				reCase = reCase | nCase
			end
		end
	end)
	return reCase
end

    
function RefineTerm:caseFalse()
	local reCase = nil
	self._type:falseType():foreach(function(vType)
		local nCase = self._typeToCase[vType]
		if not reCase then
			reCase = nCase
		else
			reCase = reCase | nCase
		end
	end)
	return reCase
end

function RefineTerm:falseEach(vFunc )
	local nTypeToCase = self._typeToCase
	self._type:falseType():foreach(function(vType)
		vFunc(vType, nTypeToCase[vType])
	end)
end

function RefineTerm:trueEach(vFunc )
	local nTypeToCase = self._typeToCase
	self._type:trueType():foreach(function(vType)
		vFunc(vType, nTypeToCase[vType])
	end)
end

function RefineTerm:getRefineTerm()
	return self
end

function RefineTerm:getType()
	return self._type
end

function RefineTerm:initVariable(vImmutVariable)
	assert(not self._symbolVariable, "term can only set symbolvariable once")
	self._symbolVariable = vImmutVariable
	for nType, nVariableCase in pairs(self._typeToCase) do
		local nNewVariableCase = VariableCase.new() & nVariableCase
		local nImmutVariable = self._symbolVariable
		if nImmutVariable then
			nNewVariableCase:put_and(nImmutVariable, nType)
		end
		self._typeToCase[nType] = nNewVariableCase
	end
end

function RefineTerm:includeAtomCase(vType)  
	local nIncludeType = self._type:includeAtom(vType)
	if nIncludeType then
		return nIncludeType, self._typeToCase[nIncludeType]
	else
		return false, nil
	end
end

function RefineTerm:filter(vContext, vType)
	local nTypeCaseList = {}
	vType:foreach(function(vSubType)
		local nIncludeType = self._type:includeAtom(vSubType)
		if nIncludeType then
			local nCase = self._typeToCase[nIncludeType]
			nTypeCaseList[#nTypeCaseList + 1] = {vSubType, nCase}
		else
			nTypeCaseList[#nTypeCaseList + 1] = {vSubType, VariableCase.new()}
		end
	end)
	return vContext:mergeToRefineTerm(nTypeCaseList)
end

function RefineTerm:attachImmutVariable()
	local nImmutVariable = self._symbolVariable
	if not nImmutVariable then
		nImmutVariable = ImmutVariable.new(self)
		self:initVariable(nImmutVariable)
	end
	return nImmutVariable
end

function RefineTerm:getNode()
	return self._node
end

return RefineTerm

end end
--thlua.term.RefineTerm end ==========)

--thlua.term.VariableCase begin ==========(
do local _ENV = _ENV
packages['thlua.term.VariableCase'] = function (...)


local VariableCase = {}

  

VariableCase.__index = VariableCase
VariableCase.__bor=function(vLeftVariableCase, vRightVariableCase)
	local nNewVariableCase = VariableCase.new()
	for nImmutVariable, nLeftType in pairs(vLeftVariableCase) do
		local nRightType = vRightVariableCase[nImmutVariable]
		if nRightType then
			nNewVariableCase[nImmutVariable] = nLeftType | nRightType
		end
	end
	return nNewVariableCase
end
VariableCase.__band=function(vLeftVariableCase, vRightVariableCase)
	local nNewVariableCase = VariableCase.new()
	for nImmutVariable, nLeftType in pairs(vLeftVariableCase) do
		local nRightType = vRightVariableCase[nImmutVariable]
		if nRightType then
			nNewVariableCase[nImmutVariable] = nLeftType & nRightType
		else
			nNewVariableCase[nImmutVariable] = nLeftType
		end
	end
	for nImmutVariable, nRightType in pairs(vRightVariableCase) do
		if not vLeftVariableCase[nImmutVariable] then
			nNewVariableCase[nImmutVariable] = nRightType
		end
	end
	return nNewVariableCase
end
VariableCase.__tostring=function(self)
	local l={"VariableCase("}
	for nImmutVariable, vType in pairs(self) do
		l[#l + 1] = tostring(nImmutVariable).."->"..tostring(vType)
	end
	l[#l + 1] = ")"
	return table.concat(l,"|")
end

function VariableCase.new()
	return setmetatable({
		
	
	}, VariableCase)
end

function VariableCase:put_and(vImmutVariable, vType)
	local nCurType = self[vImmutVariable]
	if not nCurType then
		self[vImmutVariable] = vType
	else
		self[vImmutVariable] = nCurType & vType
	end
end

function VariableCase:copy()
	local nCopy = VariableCase.new()
	for k,v in pairs(self) do
		nCopy:put_and(k, v)
	end
	return nCopy
end

function VariableCase:empty()
	if next(self) then
		return true
	else
		return false
	end
end

function VariableCase.is(t)
	return getmetatable(t) == VariableCase
end

return VariableCase

end end
--thlua.term.VariableCase end ==========)

--thlua.tuple.DotsTail begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.DotsTail'] = function (...)

  

local DotsTail = {}
DotsTail.__index=DotsTail

function DotsTail.new(vContext, vRepeatType)
	local self = setmetatable({
		_context=vContext,
		_manager=vContext:getTypeManager(),
		_termList={},
		_repeatType=vRepeatType,
	}, DotsTail)
	return self
end

function DotsTail:getRepeatType()
	return self._repeatType
end

function DotsTail:getMore(vContext, vMore)
	local nTermList = self._termList
	local nTerm = nTermList[vMore]
	if nTerm then
		return nTerm
	else
		for i=#nTermList + 1, vMore do
			nTermList[i] = vContext:RefineTerm(self._repeatType)
		end
		return nTermList[vMore]
	end
end

function DotsTail.is(t)
	return getmetatable(t) == DotsTail
end

return DotsTail

end end
--thlua.tuple.DotsTail end ==========)

--thlua.tuple.RetBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.RetBuilder'] = function (...)

local RetTuples = require "thlua.tuple.RetTuples"
local class = require "thlua.class"

  

local RetBuilder = class ()

function RetBuilder:ctor(vManager, vNode)
	self._manager = vManager
	self._tupleList = {}  
	self._errType = false
	self._node=vNode
end

function RetBuilder:RetDots(vFirst, ...)
	     
	local nTypeList = {vFirst, ...}
	local nLen = #nTypeList
	assert(nLen > 0, "RetDots must take at least 1 value")
	local nDotsType = nTypeList[nLen]
	nTypeList[#nTypeList] = nil
	local nTypeTuple = self._manager:TypeTuple(self._node, table.unpack(nTypeList)):Dots(nDotsType)
	local nTupleList = self._tupleList
	nTupleList[#nTupleList + 1] = nTypeTuple
end

function RetBuilder:Ret(...)
	local nTypeTuple = self._manager:TypeTuple(self._node, ...)
	local nTupleList = self._tupleList
	nTupleList[#nTupleList + 1] = nTypeTuple
end

function RetBuilder:Err(vErrType)
	self._errType = vErrType
end

function RetBuilder:isEmpty()
	return #self._tupleList == 0 and not self._errType
end

function RetBuilder:build()
	local nTupleList = self._tupleList
	if #nTupleList == 0 then
		return self._manager:VoidRetTuples(self._node, self._errType or nil)
	else
		return RetTuples.new(self._manager, self._node, nTupleList, self._errType)
	end
end

return RetBuilder

end end
--thlua.tuple.RetBuilder end ==========)

--thlua.tuple.RetTuples begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.RetTuples'] = function (...)

local class = require "thlua.class"

  

local RetTuples = class ()

RetTuples.__tostring=function(self)
	return self:detailString({}, false)
end

function RetTuples:ctor(
	vManager,
	vNode,
	vTupleList,
	vErrType
)
	assert(#vTupleList > 0, "length of tuple list must be bigger than 0 when pass to RetTuples' constructor")
	local nFirstToTuple  = {}
	for _, nTuple in ipairs(vTupleList) do
		local nFirst = nTuple:get(1)
		nFirstToTuple[nFirst] = nTuple
	end
	local nTask = vManager:getScheduleManager():newTask()
	local nAsyncFirstType = vManager:AsyncUnion(nTask)
	self._node=vNode
	self._task = nTask
	self._manager=vManager
	self._firstType=nAsyncFirstType
	self._firstToTuple=nFirstToTuple
	self._errType = vErrType and self._manager:buildUnion(vNode, self._manager.type.String, vErrType) or self._manager.type.String
	nTask:runAsync(function()
		local nIndependentList = {}
		local nFirstAtomList = {}
		for _, nTuple in ipairs(vTupleList) do
			local nFirst = nTuple:get(1):checkAtomUnion()
			assert(not nFirst:isNever(), "can't return never")
			nIndependentList[#nIndependentList + 1] = nFirst
			nFirst:foreach(function(vAtomType)
				nFirstAtomList[#nFirstAtomList + 1] = vAtomType
			end)
		end
		local nAtomUnion = nAsyncFirstType:setAtomList(nFirstAtomList)
		if not vManager:typeCheckIndependent(nIndependentList, nAtomUnion) then
			error("return tuples' first type must be independent")
		end
	end)
end

function RetTuples:detailString(vCache , vVerbose)
	local re = {}
	for _, t in pairs(self._firstToTuple) do
		re[#re+1] = t:detailString(vCache, vVerbose)
	end
	return "("..table.concat(re, "|")..")"
end

function RetTuples:assumeIncludeTuples(vAssumeSet , vRetTuples)
	for _, t in pairs(vRetTuples._firstToTuple) do
		if not self:assumeIncludeTuple(vAssumeSet, t) then
			return false
		end
	end
	if not self._errType:assumeIncludeAll(vAssumeSet, vRetTuples._errType) then
		return false
	end
	return true
end

function RetTuples:includeTuples(vRetTuples)
	return self:assumeIncludeTuples(nil, vRetTuples)
end

function RetTuples:assumeIncludeTuple(vAssumeSet , vRightTypeTuple)
	for _, t in pairs(self._firstToTuple) do
		if t:assumeIncludeTuple(vAssumeSet, vRightTypeTuple) then
			return true
		end
	end
	return false
end

function RetTuples:includeTuple(vRightTypeTuple)
	return self:assumeIncludeTuple(nil, vRightTypeTuple)
end

function RetTuples:foreachWithFirst(vFunc )
	for nFirst, nTuple in pairs(self._firstToTuple) do
		vFunc(nTuple, nFirst)
	end
end

function RetTuples:getFirstType()
	return self._firstType:getTypeAwait()
end

function RetTuples:getErrType()
	return self._errType:checkAtomUnion()
end

return RetTuples

end end
--thlua.tuple.RetTuples end ==========)

--thlua.tuple.TermTuple begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TermTuple'] = function (...)

local Exception = require "thlua.Exception"
local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"


	  
	  
	  
	   


local TermTuple = {}

TermTuple.__index=TermTuple
TermTuple.__tostring=function(self)
	local re = {}
	for i=1, #self do
		re[i] = tostring(self._list[i]:getType())
	end
	local nTail = self._tail
	if nTail then
		re[#re + 1] = tostring(nTail) .."*"
	end
	if self._auto then
		return "AutoTermTuple("..table.concat(re, ",")..")"
	else
		return "FixedTermTuple("..table.concat(re, ",")..")"
	end
end

TermTuple.__len=function(self)
	return #self._list
end

function TermTuple.new(
	vContext,
	vAuto,
	vTermList  ,
	vTail   ,
	vTypeTuple
)
	local self = setmetatable({
		_context=vContext,
		_manager=vContext:getTypeManager(),
		_list=vTermList,
		_tail=vTail,
		_typeTuple=vTypeTuple,
		_auto=vAuto,
	}, TermTuple)
	return self
end

function TermTuple:select(vContext, i) 
	local nList = {}
	for n=i,#self._list do
		nList[#nList + 1] = self._list[n]
	end
	     
	if self._auto then
		return self._context:UTermTupleByTail(nList, self._tail)
	else
		return self._context:FixedTermTuple(nList, self:getRepeatType())
	end
end

function TermTuple:rawget(i)
	return self._list[i]
end

function TermTuple:checkFixed(vContext, i)
	local nTerm = self:get(vContext, i)
	return nTerm:checkRefineTerm(vContext)
end

function TermTuple:get(vContext, i)
	local nMore = i - #self
	if nMore <= 0 then
		return self._list[i]
	else
		local nTail = self._tail
		if nTail then
			return nTail:getMore(vContext, nMore)
		else
			return vContext:RefineTerm(self._manager.type.Nil)
		end
	end
end

function TermTuple:getContext()
	return self._context
end

function TermTuple:checkTypeTuple(vSeal)  
	if self._auto then
		local nTypeList = {}
		for i,v in ipairs(self._list) do
			local nType = v:getType()
			if not nType then
				return false
			end
			nTypeList[i] = nType
		end
		local nTail = self._tail
		if AutoTail.is(nTail) then
			local nTailTuple = nTail:checkTypeTuple(vSeal)
			if not nTailTuple then
				return false
			else
				for i=1,#nTailTuple do
					nTypeList[#nTypeList + 1] = nTailTuple:get(i)
				end
				local nFinalTuple = self._manager:TypeTuple(self._context:getNode(), table.unpack(nTypeList))
				local nRepeatType = nTailTuple:getRepeatType()
				if nRepeatType then
					return nFinalTuple:Dots(nRepeatType)
				else
					return nFinalTuple
				end
			end
		else
			local nTuple = self._manager:TypeTuple(self._context:getNode(), table.unpack(nTypeList))
			if not nTail then
				return nTuple
			else
				return nTuple:Dots(nTail:getRepeatType())
			end
		end
	else
		local nTypeTuple = self._typeTuple
		if not nTypeTuple then
			local nList = {}
			for i,v in ipairs(self._list) do
				nList[i] = v:getType()
			end
			nTypeTuple = self._manager:TypeTuple(self._context:getNode(), table.unpack(nList))
			local nTail = self._tail
			if nTail then
				nTypeTuple = nTypeTuple:Dots(nTail:getRepeatType())
			end
			self._typeTuple = nTypeTuple
			return nTypeTuple
		else
			return nTypeTuple
		end
	end
end

function TermTuple:getTail()
	return self._tail
end

function TermTuple:getRepeatType()
	local nTail = self._tail
	if DotsTail.is(nTail) then
		return nTail:getRepeatType()
	else
		return false
	end
end

function TermTuple.is(t)
	return TermTuple.isAuto(t) or TermTuple.isFixed(t)
end

function TermTuple.isAuto(t)
	return getmetatable(t) == TermTuple and t._auto
end

function TermTuple.isFixed(t)
	return getmetatable(t) == TermTuple and not t._auto
end

return TermTuple

end end
--thlua.tuple.TermTuple end ==========)

--thlua.tuple.TupleClass begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TupleClass'] = function (...)

local TermTuple = require "thlua.tuple.TermTuple"


	  
	   


local function TupleClass()
	local t = {}
	t.__index=t
	t.__tostring=function(self)
		return self:detailString({}, false)
	end
	function t.__len(self)
		return #self._list
	end
	function t:detailStringIfFirst(vCache , vVerbose, vHasFirst)
		local re = {}
		local nStartIndex = vHasFirst and 1 or 2
		for i=nStartIndex, #self do
			re[#re + 1] = self._list[i]:detailString(vCache, vVerbose)
		end
		local nRepeatType = self:getRepeatType()
		if nRepeatType then
			re[#re + 1] = nRepeatType:detailString(vCache, vVerbose) .."*"
		end
		return "Tuple("..table.concat(re, ",")..")"
	end
	function t:detailString(vCache , vVerbose)
		return self:detailStringIfFirst(vCache, vVerbose, true)
	end
	function t:makeTermTuple(vContext)
		local nTermList = {}
		for i=1, #self do
			nTermList[i] = vContext:RefineTerm(self._list[i])
		end
		return vContext:FixedTermTuple(nTermList, self:getRepeatType(), self)
	end
	function t:assumeIncludeTuple(vAssumeSet , vRightTypeTuple)
		local nLeftRepeatType = self:getRepeatType()
		local nRightRepeatType = vRightTypeTuple:getRepeatType()
		if (not nLeftRepeatType) and nRightRepeatType then
			return false
		end
		if nLeftRepeatType and nRightRepeatType then
			if not nLeftRepeatType:assumeIncludeAll(vAssumeSet, nRightRepeatType) then
				return false
			end
		end
		     
		for i=1, #vRightTypeTuple do
			local nLeftType = self._list[i] or nLeftRepeatType
			if not nLeftType then
				return false
			end
			if not nLeftType:assumeIncludeAll(vAssumeSet, vRightTypeTuple:get(i)) then
				return false
			end
		end
		for i=#vRightTypeTuple + 1, #self do
			local nLeftType = self._list[i]:checkAtomUnion()
			if not nLeftType:isNilable() then
				return false
			end
			if nRightRepeatType then
				if not nLeftType:assumeIncludeAll(vAssumeSet, nRightRepeatType) then
					return false
				end
			end
		end
		return true
	end
	function t:includeTuple(vRightTypeTuple)
		return self:assumeIncludeTuple(nil, vRightTypeTuple)
	end
	return t
end

return TupleClass

end end
--thlua.tuple.TupleClass end ==========)

--thlua.tuple.TypeTuple begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TypeTuple'] = function (...)

local Reference = require "thlua.refer.Reference"
local TupleClass = require "thlua.tuple.TupleClass"
local TypeTupleDots = require "thlua.tuple.TypeTupleDots"
local Nil = require "thlua.type.Nil"
local TypeTuple = TupleClass()

  

function TypeTuple.new(vManager, vNode, vList)
	local self = setmetatable({
		_manager=vManager,
		_node=vNode,
		_list=vList,
	}, TypeTuple)
	return self
end

function TypeTuple:getRepeatType()
	return false
end

function TypeTuple:Dots(vType)
	local nWithNil = self._manager:buildUnion(self._node, vType, self._manager.type.Nil)
	return TypeTupleDots.new(self._manager, self._node, self._list, vType, nWithNil)
end

function TypeTuple:leftAppend(vType)
	return TypeTuple.new(self._manager, self._node, {vType, table.unpack(self._list)})
end

function TypeTuple:get(i)
	return self._list[i] or self._manager.type.Nil
end

function TypeTuple:select(i)
	return self._manager:TypeTuple(self._node, table.unpack(self._list, i))
end

function TypeTuple.is(t)
	return getmetatable(t) == TypeTuple
end

return TypeTuple

end end
--thlua.tuple.TypeTuple end ==========)

--thlua.tuple.TypeTupleDots begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TypeTupleDots'] = function (...)

local TupleClass = require "thlua.tuple.TupleClass"
local TypeTupleDots = TupleClass()

  

function TypeTupleDots.new(
	vManager,
	vNode,
	vList,
	vRepeatType,
	vRepeatTypeWithNil
)
	local self = setmetatable({
		_manager=vManager,
		_node=vNode,
		_list=vList,
		_repeatType=vRepeatType,
		_repeatTypeWithNil=vRepeatTypeWithNil,
	}, TypeTupleDots)
	return self
end

function TypeTupleDots:getRepeatType()
	return self._repeatType
end

function TypeTupleDots:leftAppend(vType)
	return TypeTupleDots.new(self._manager, self._node, {vType, table.unpack(self._list)}, self._repeatType, self._repeatTypeWithNil)
end

function TypeTupleDots:get(i)
	if i <= #self then
		return self._list[i]
	else
		return self._repeatTypeWithNil
	end
end

function TypeTupleDots:select(i)
	local nList  = {table.unpack(self._list, i)}
	return TypeTupleDots.new(self._manager, self._node, nList, self._repeatType, self._repeatTypeWithNil)
end

function TypeTupleDots.is(t)
	return getmetatable(t) == TypeTupleDots
end

return TypeTupleDots

end end
--thlua.tuple.TypeTupleDots end ==========)

--thlua.type.BaseAtomType begin ==========(
do local _ENV = _ENV
packages['thlua.type.BaseAtomType'] = function (...)


local Exception = require "thlua.Exception"
local FieldCompletion = require "thlua.context.FieldCompletion"
local OPER_ENUM = require "thlua.type.OPER_ENUM"

local class = require "thlua.class"
local BaseReadyType = require "thlua.type.BaseReadyType"

  

local BaseAtomType = class (BaseReadyType)

function BaseAtomType:ctor(vManager, ...)
	self.id = vManager:genTypeId()
	self.bits = false  
	self._manager:atomRecordTypeUnionSign(self)
end

function BaseAtomType.__bor(vLeft, vRight)
	return vLeft._manager:checkedUnion(vLeft, vRight)
end

function BaseAtomType:foreach(vFunc)
	vFunc(self)
end

function BaseAtomType:isSingleton()
	error(tostring(self).."is singleton TODO")
	return false
end

   
function BaseAtomType:meta_ipairs(vContext)
	vContext:error(tostring(self).."'s meta_ipairs not implement")
	return false
end

function BaseAtomType:meta_pairs(vContext)
	vContext:error(tostring(self).."'s meta_pairs not implement")
	return false
end

function BaseAtomType:meta_set(vContext, vKeyType, vValueType)
	vContext:error(tostring(self).." can't take set index")
end

function BaseAtomType:meta_get(vContext, vKeyType)
	vContext:error(tostring(self).." can't take get index")
	return false
end

function BaseAtomType:meta_call(vContext, vTypeTuple)
	vContext:error(tostring(self).." can't take call")
	vContext:pushRetTuples(self._manager:VoidRetTuples(vContext:getNode()))
end

function BaseAtomType:meta_invoke(vContext, vSelfType, vPolyArgs, vTypeTuple)
	if #vPolyArgs > 0 then
		local nCast = self:castPoly(vContext, vPolyArgs) or self
		nCast:meta_call(vContext, vTypeTuple)
	else
		self:meta_call(vContext, vTypeTuple)
	end
end

function BaseAtomType:meta_bop_func(vContext, vOper)
	if OPER_ENUM.mathematic[vOper] then
		return false, self._manager.builtin.bop.mathematic
	elseif OPER_ENUM.bitwise[vOper] then
		return false, self._manager.builtin.bop.bitwise
	elseif OPER_ENUM.comparison[vOper] then
		return false, self._manager.builtin.bop.comparison
	elseif vOper == ".." then
		return false, self._manager.builtin.bop.concat
	else
		vContext:error("invalid bop:"..tostring(vOper))
		return false, nil
	end
end

function BaseAtomType:meta_len(vContext)
	vContext:error(tostring(self).." can't take len oper")
	return self._manager.type.Number
end

function BaseAtomType:meta_uop_some(vContext, vOper)
	vContext:error(tostring(self).." can't take uop :"..vOper)
	return self._manager.type.Number
end

   
function BaseAtomType:native_next(vContext, vInitType)
	error("native_next not implement")
end

function BaseAtomType:native_tostring()
	return self._manager.type.String
end

function BaseAtomType:native_rawget(vContext, vKeyType)
	vContext:error(tostring(self).." rawget not implement")
	return self._manager.type.Nil
end

function BaseAtomType:native_rawset(vContext, vKeyType, vValueType)
	vContext:error(tostring(self).." rawset not implement")
end

function BaseAtomType:castPoly(vContext, vTypeArgsList)
	vContext:error("poly cast can't work on this type:"..tostring(self))
	return false
end

function BaseAtomType:native_type()
	print("native_type not implement ")
	return self._manager.type.String
end

function BaseAtomType:native_getmetatable(vContext)
	return self._manager.type.Nil
end

function BaseAtomType:native_setmetatable(vContext, vTable)
	vContext:error("this type setmetatable not implement")
end

function BaseAtomType:checkTypedObject()
	return false
end

function BaseAtomType:isUnion()
	return false
end

function BaseAtomType:checkAtomUnion()
	return self
end

function BaseAtomType:isNever()
	return false
end

function BaseAtomType:isNilable()
	return false
end

function BaseAtomType:assumeIncludeAtom(vAssumeSet, vRightType, vSelfType)
	if self == vRightType then
		return self
	else
		return false
	end
end

function BaseAtomType:assumeIntersectAtom(vAssumeSet, vRightType)
	if self == vRightType then
		return self
	elseif vRightType:assumeIncludeAtom(nil, self) then
		return self
	elseif self:assumeIncludeAtom(nil, vRightType) then
		return vRightType
	else
		return false
	end
end

function BaseAtomType:putCompletion(vCompletion)
end

function BaseAtomType:setLocked()
	  
end

function BaseAtomType:findRequireStack()
	return false
end

return BaseAtomType

end end
--thlua.type.BaseAtomType end ==========)

--thlua.type.BaseReadyType begin ==========(
do local _ENV = _ENV
packages['thlua.type.BaseReadyType'] = function (...)


local Exception = require "thlua.Exception"
local OPER_ENUM = require "thlua.type.OPER_ENUM"

local class = require "thlua.class"

  

local BaseReadyType = class ()

function BaseReadyType:ctor(vManager, ...)
	self._manager = vManager
	self.id = 0  
end

function BaseReadyType:detailString(_, _)
	return "detailString not implement"
end

function BaseReadyType.__tostring(self)
	return self:detailString({}, false)
end

function BaseReadyType.__bor(vLeft, vRight)
	return vLeft._manager:checkedUnion(vLeft, vRight)
end

function BaseReadyType.__band(vLeft, vRight)
	local nTypeOrFalse = vLeft:safeIntersect(vRight)
	if nTypeOrFalse then
		return nTypeOrFalse
	else
		error("unexpected intersect")
	end
end

function BaseReadyType:unionSign()
	return tostring(self.id)
end

function BaseReadyType:mayRecursive()
	return false
end

function BaseReadyType:putCompletion(vCompletion)
end

function BaseReadyType:foreach(vFunc)
	error("foreach not implement")
end

function BaseReadyType:foreachAwait(vFunc)
	self:foreach(vFunc)
end

function BaseReadyType:isReference()
	return false
end



   



function BaseReadyType:intersectAtom(vRight)
	return self:assumeIntersectAtom(nil, vRight)
end

function BaseReadyType:includeAtom(vRight)
	return self:assumeIncludeAtom(nil, vRight)
end

function BaseReadyType:assumeIntersectSome(vAssumeSet, vRight)
	local nSomeIntersect = false
	vRight:foreachAwait(function(vSubType)
		if not nSomeIntersect and self:assumeIntersectAtom(vAssumeSet, vSubType) then
			nSomeIntersect = true
		end
	end)
	return nSomeIntersect
end

function BaseReadyType:assumeIncludeAll(vAssumeSet, vRight, vSelfType)
	local nAllInclude = true
	vRight:foreachAwait(function(vSubType)
		if nAllInclude and not self:assumeIncludeAtom(vAssumeSet, vSubType, vSelfType) then
			nAllInclude = false
		end
	end)
	return nAllInclude
end

function BaseReadyType:intersectSome(vRight)
	return self:assumeIntersectSome(nil, vRight)
end

function BaseReadyType:includeAll(vRight)
	return self:assumeIncludeAll(nil, vRight)
end

function BaseReadyType:safeIntersect(vRight)
	local nLeft = self
	local nRight = vRight:isReference() and vRight:checkAtomUnion() or vRight
	if not nRight:isUnion() then
		local nIntersect = nLeft:assumeIntersectAtom(nil, nRight)
		if nIntersect == true then
			return false
		else
			return nIntersect or self._manager.type.Never
		end
	else
		local nCollection = self._manager:TypeCollection()
		nRight:foreach(function(vSubType)
			local nIntersect = nLeft:assumeIntersectAtom(nil, vSubType)
			if nIntersect then
				if nIntersect == true then
					return
				else
					nCollection:put(nIntersect)
				end
			end
		end)
		return nCollection:mergeToAtomUnion()
	end
end

function BaseReadyType:assumeIncludeAtom(_, _, _)
	error("not implement")
	return false
end

function BaseReadyType:assumeIntersectAtom(_, _)
	error("not implement")
	return false
end



    


function BaseReadyType:isNever()
	return false
end

function BaseReadyType:notnilType()
	return self
end

function BaseReadyType:isNilable()
	return false
end

function BaseReadyType:partTypedObject()
	return self._manager.type.Never
end

function BaseReadyType:partTypedFunction()
	return self._manager.type.Never
end

function BaseReadyType:falseType()
	return self._manager.type.Never
end

function BaseReadyType:trueType()
	return self
end

function BaseReadyType:setAssigned(vContext)
end

function BaseReadyType:isAsync()
	return false
end

return BaseReadyType

end end
--thlua.type.BaseReadyType end ==========)

--thlua.type.BooleanLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.BooleanLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local BooleanLiteral = class (BaseAtomType)

function BooleanLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=vLiteral and TYPE_BITS.TRUE or TYPE_BITS.FALSE
end

function BooleanLiteral:detailString(v, vVerbose)
	if vVerbose then
		return "Literal("..tostring(self.literal)..")"
	else
		return self.literal and "True" or "False"
	end
end

function BooleanLiteral:isSingleton()
	return true
end

function BooleanLiteral:native_type()
	return self._manager:Literal("boolean")
end

function BooleanLiteral:trueType()
	if self.literal then
		return self
	else
		return self._manager.type.Never
	end
end

function BooleanLiteral:falseType()
	if self.literal then
		return self._manager.type.Never
	else
		return self
	end
end

return BooleanLiteral

end end
--thlua.type.BooleanLiteral end ==========)

--thlua.type.Nil begin ==========(
do local _ENV = _ENV
packages['thlua.type.Nil'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local Nil = class (BaseAtomType)

function Nil:ctor(vManager)
	self.bits=TYPE_BITS.NIL
end

function Nil:detailString(v, vVerbose)
	return "Nil"
end

function Nil:native_getmetatable(vContext)
	return self._manager.type.Nil
end

function Nil:native_type()
	return self._manager:Literal("nil")
end

function Nil:isSingleton()
	return true
end

function Nil:trueType()
	return self._manager.type.Never
end

function Nil:falseType()
	return self
end

function Nil:isNilable()
	return true
end

function Nil:notnilType()
	return self._manager.type.Never
end

return Nil

end end
--thlua.type.Nil end ==========)

--thlua.type.Number begin ==========(
do local _ENV = _ENV
packages['thlua.type.Number'] = function (...)

local NumberLiteral = require "thlua.type.NumberLiteral"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local Number = class (BaseAtomType)

function Number:ctor(vManager)
	self.bits=TYPE_BITS.NUMBER
end

function Number:detailString(v, vVerbose)
	return "Number"
end

function Number:meta_uop_some(vContext, vOper)
	return self
end

function Number:native_getmetatable(vContext)
	return self._manager.type.Nil
end

function Number:native_type()
	return self._manager:Literal("number")
end

function Number:assumeIncludeAtom(vAssumetSet, vType, _)
	if NumberLiteral.is(vType) then
		return self
	elseif self == vType then
		return self
	else
		return false
	end
end

function Number:isSingleton()
	return false
end

return Number

end end
--thlua.type.Number end ==========)

--thlua.type.NumberLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.NumberLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"


  

local NumberLiteral = class (BaseAtomType)

function NumberLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=TYPE_BITS.NUMBER
end

function NumberLiteral:getLiteral()
	return self.literal
end

function NumberLiteral:native_type()
	return self._manager:Literal("number")
end

function NumberLiteral:meta_uop_some(vContext, vOper)
	if vOper == "-" then
		return self._manager:Literal(-self.literal)
	elseif vOper == "~" then
		return self._manager:Literal(~self.literal)
	else
		return self._manager.type.Never
	end
end

function NumberLiteral:detailString(vCache, vVerbose)
	return "Literal("..self.literal..")"
end

function NumberLiteral:isSingleton()
	return true
end

return NumberLiteral

end end
--thlua.type.NumberLiteral end ==========)

--thlua.type.OPER_ENUM begin ==========(
do local _ENV = _ENV
packages['thlua.type.OPER_ENUM'] = function (...)

    

local comparison = {
	[">"]="__lt",
	["<"]="__lt",
	[">="]="__le",
	["<="]="__le",
}

local mathematic = {
	["+"]="__add",
	["-"]="__sub",
	["*"]="__mul",
	["/"]="__div",
	["//"]="__idiv",
	["%"]="__mod",
	["^"]="__pow",
}

local bitwise = {
	["&"]="__band",
	["|"]="__bor",
	["~"]="__bxor",
	["<<"]="__shr",
	[">>"]="__shl",
}

local uopNoLen = {
	["-"]="__unm",
	["~"]="__bnot"
}

local bopNoEq = {
	[".."]="__concat"
}

for k,v in pairs(comparison) do
	bopNoEq[k] = v
end

for k,v in pairs(bitwise) do
	bopNoEq[k] = v
end

for k,v in pairs(mathematic) do
	bopNoEq[k] = v
end

return {
	bitwise=bitwise,
	mathematic=mathematic,
	comparison=comparison,
	bopNoEq=bopNoEq,
	uopNoLen=uopNoLen,
}

end end
--thlua.type.OPER_ENUM end ==========)

--thlua.type.String begin ==========(
do local _ENV = _ENV
packages['thlua.type.String'] = function (...)

local StringLiteral = require "thlua.type.StringLiteral"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local String = class (BaseAtomType)

function String:ctor(vManager)
	self.bits=TYPE_BITS.STRING
end

function String:detailString(v, vVerbose)
	return "String"
end

function String:native_getmetatable(vContext)
	return self._manager.builtin.string
end

function String:native_type()
	return self._manager:Literal("string")
end

function String:meta_len(vContext)
	return self._manager.type.Number
end

function String:meta_get(vContext, vKeyType)
	return self._manager.builtin.string:meta_get(vContext, vKeyType)
end

function String:assumeIncludeAtom(vAssumeSet, vType, _)
	if StringLiteral.is(vType) then
		return self
	elseif self == vType then
		return self
	else
		return false
	end
end

function String:isSingleton()
	return false
end

function String:putCompletion(vFieldCompletion)
	self._manager.builtin.string:putCompletion(vFieldCompletion)
end

return String

end end
--thlua.type.String end ==========)

--thlua.type.StringLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.StringLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local StringLiteral = class (BaseAtomType)

function StringLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=TYPE_BITS.STRING
end

function StringLiteral:getLiteral()
	return self.literal
end

function StringLiteral:detailString(v, vVerbose)
	return "Literal('"..self.literal.."')"
end

function StringLiteral:isSingleton()
	return true
end

function StringLiteral:meta_len(vContext)
	return self._manager.type.Number
end

function StringLiteral:meta_get(vContext, vKeyType)
	return self._manager.builtin.string:meta_get(vContext, vKeyType)
end

function StringLiteral:putCompletion(vFieldCompletion)
	self._manager.builtin.string:putCompletion(vFieldCompletion)
end

return StringLiteral

end end
--thlua.type.StringLiteral end ==========)

--thlua.type.TYPE_BITS begin ==========(
do local _ENV = _ENV
packages['thlua.type.TYPE_BITS'] = function (...)

local TYPE_BITS = {
	NEVER = 0,
	NIL = 1,
	FALSE = 1 << 1,
	TRUE = 1 << 2,
	NUMBER = 1 << 3,
	STRING = 1 << 4,
	OBJECT = 1 << 5,
	FUNCTION = 1 << 6,
	THREAD = 1 << 7,
	TRUTH = 0xFF-3,
}

return TYPE_BITS

end end
--thlua.type.TYPE_BITS end ==========)

--thlua.type.Thread begin ==========(
do local _ENV = _ENV
packages['thlua.type.Thread'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local Thread = class (BaseAtomType)

function Thread:ctor(vManager)
	self.bits = TYPE_BITS.THREAD
end

function Thread:detailString(vToStringCache, vVerbose)
	return "Thread"
end

function Thread:native_getmetatable(vContext)
	return self._manager.type.Nil
end

function Thread:native_type()
	return self._manager:Literal("thread")
end

function Thread:isSingleton()
	return false
end

return Thread

end end
--thlua.type.Thread end ==========)

--thlua.type.Truth begin ==========(
do local _ENV = _ENV
packages['thlua.type.Truth'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.BaseAtomType"
local class = require "thlua.class"

  

local Truth = class (BaseAtomType)

function Truth:ctor(vManager)
	self.bits = TYPE_BITS.TRUTH
end

function Truth:detailString(vToStringCache, vVerbose)
	return "Truth"
end

function Truth:native_setmetatable(vContext, vMetaTableType)
end

function Truth:native_getmetatable(vContext)
	return self
end

function Truth:native_type()
	   
	return self._manager.type.String
end

function Truth:native_rawget(vContext, vKeyType)
	return self
end

function Truth:native_rawset(vContext, vKeyType, vValueTypeSet)
end

function Truth:meta_get(vContext, vKeyType)
	vContext:pushFirstAndTuple(self)
	return true
end

function Truth:meta_set(vContext, vKeyType, vValueTerm)
end

function Truth:meta_call(vContext, vTypeTuple)
	vContext:pushRetTuples(self._manager:VoidRetTuples(vContext:getNode()))
end

function Truth:meta_pairs(vContext)
	return false
end

function Truth:meta_ipairs(vContext)
	return false
end

function Truth:native_next(vContext, vInitType)
	return self._manager.type.Never, {}
end

function Truth:isSingleton()
	return false
end

function Truth:assumeIncludeAtom(vAssumeSet, vType, _)
	local nManagerType = self._manager.type
	if vType == nManagerType.Nil then
		return false
	elseif vType == nManagerType.False then
		return false
	else
		return self
	end
end

return Truth

end end
--thlua.type.Truth end ==========)

--thlua.type.TypeClass begin ==========(
do local _ENV = _ENV
packages['thlua.type.TypeClass'] = function (...)



  

  

  
	  
		   
		  
	


  

   
    
    
   

    

   
	
	
	

	

	  

	
	
	  
	 

	
	   
	

	


 
	 
	 


    
	
	
	
	
	
	
	
	
	
	
	   
	   
	
	


    
	
	

	
	

	

	  

	 
	   
	 
	  

	
	
	
	 
	    

	 
	  
	   
	
	  

	
	


    
	
	

	

	

	


   
    



return {}

end end
--thlua.type.TypeClass end ==========)

--thlua.union.BaseUnionType begin ==========(
do local _ENV = _ENV
packages['thlua.union.BaseUnionType'] = function (...)

local class = require "thlua.class"
local BaseReadyType = require "thlua.type.BaseReadyType"

  

local BaseUnionType = class (BaseReadyType)

function BaseUnionType:ctor(...)
    self.bits = false  
    self._atomList = {}  
    self._unionSign = false
end

function BaseUnionType:getAtomList()
    return self._atomList
end

function BaseUnionType:detailString(vCache, vVerbose)
    local l = {}
    self:foreach(function(vType)
        l[#l+1] = vType
    end)
    table.sort(l, function(vLeft, vRight)
        return vLeft.id < vRight.id
    end)
    local sl = {}
    for i=1, #l do
        sl[i] = l[i]:detailString(vCache, vVerbose)
    end
    return "Union("..table.concat(sl,",")..")"
end

function BaseUnionType:initWithTypeId(vTypeId)
    assert(self.id == 0, "newunion's id must be 0")
    self.id = vTypeId
    local nAtomList = self._atomList
    self:foreach(function(vAtomType)
        nAtomList[#nAtomList + 1] = vAtomType
    end)
end

function BaseUnionType:isUnion()
    return true
end

function BaseUnionType:unionSign()
    local nSign = self._unionSign
    local l = {}
    if not nSign then
        self:foreach(function(vType)
            l[#l + 1] = vType.id
        end)
        table.sort(l)
        nSign = table.concat(l, "-")
        self._unionSign = nSign
    end
    return nSign
end

function BaseUnionType:putAwait(vType)
    error("this union type can't call putAwait to build itself")
end

function BaseUnionType:setAssigned(vContext)
    self:foreach(function(vType)
        vType:setAssigned(vContext)
    end)
end

function BaseUnionType:checkAtomUnion()
	return self
end

function BaseUnionType:putCompletion(v)
    self:foreach(function(vType)
        vType:putCompletion(v)
    end)
end

return BaseUnionType
end end
--thlua.union.BaseUnionType end ==========)

--thlua.union.ComplexUnion begin ==========(
do local _ENV = _ENV
packages['thlua.union.ComplexUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Truth = require "thlua.type.Truth"
local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local ComplexUnion = class (BaseUnionType)

function ComplexUnion:ctor(vManager, vBits, vBitToType )
	self._bitToType=vBitToType
	self.bits = vBits
end

function ComplexUnion:mayRecursive()
	local nBitToType = self._bitToType
	if nBitToType[TYPE_BITS.OBJECT] or nBitToType[TYPE_BITS.FUNCTION] then
		return true
	else
		return false
	end
end

function ComplexUnion:partTypedObject()
	local re = self._bitToType[TYPE_BITS.OBJECT] or self._manager.type.Never
	return re:partTypedObject()
end

function ComplexUnion:partTypedFunction()
	local re = self._bitToType[TYPE_BITS.FUNCTION] or self._manager.type.Never
	return re:partTypedFunction()
end

function ComplexUnion:foreach(vFunc)
	for nBits, nType in pairs(self._bitToType) do
		nType:foreach(vFunc)
	end
end

function ComplexUnion:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	local nSimpleType = self._bitToType[vType.bits]
	if nSimpleType then
		return nSimpleType:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	else
		return false
	end
end

function ComplexUnion:assumeIntersectAtom(vAssumeSet, vType)
	local nSimpleType = self._bitToType[vType.bits]
	if nSimpleType then
		return nSimpleType:assumeIntersectAtom(vAssumeSet, vType)
	elseif Truth.is(vType) then
		return self
	else
		return false
	end
end

function ComplexUnion:isNilable()
	if self._bitToType[TYPE_BITS.NIL] then
		return true
	else
		return false
	end
end

return ComplexUnion

end end
--thlua.union.ComplexUnion end ==========)

--thlua.union.FalsableUnion begin ==========(
do local _ENV = _ENV
packages['thlua.union.FalsableUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Truth = require "thlua.type.Truth"
local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local FalsableUnion = class (BaseUnionType)

function FalsableUnion:ctor(vTypeManager, vTruableType, vFalsableBits)
	local nNil = vTypeManager.type.Nil
	local nFalse = vTypeManager.type.False
	self.bits=vTruableType.bits | vFalsableBits
	self._trueType=vTruableType
	self._notnilType=nil  
	self._nil=vFalsableBits & TYPE_BITS.NIL > 0 and nNil or false
	self._false=vFalsableBits & TYPE_BITS.FALSE > 0 and nFalse or false
	self._falseType=false 
    if self._trueType == vTypeManager.type.Never then
		self._falseType = self
    elseif self._nil and self._false then
		self._falseType = vTypeManager:checkedUnion(nNil, nFalse)
    else
		self._falseType = self._nil or self._false
    end
	if self._false then
		if not self._nil then
			self._notnilType = self
		else
			local nFalse = self._false
			if nFalse then
				self._notnilType = vTypeManager:checkedUnion(self._trueType, nFalse)
			else
				self._notnilType = self._trueType
			end
		end
	else
		self._notnilType = self._trueType
	end
end

function FalsableUnion:foreach(vFunc)
	self._trueType:foreach(vFunc)
	local nNilType = self._nil
	if nNilType then
		vFunc(nNilType)
	end
	local nFalseType = self._false
	if nFalseType then
		vFunc(nFalseType)
	end
end

function FalsableUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Truth.is(vType) then
		local nTrueType = self._trueType
		if nTrueType == self._manager.type.Never then
			return false
		else
			return nTrueType
		end
	else
		local nTrueIntersect = self._trueType:assumeIntersectAtom(vAssumeSet, vType)
		if nTrueIntersect then
			return nTrueIntersect
		else
			if self._nil and vType == self._manager.type.Nil then
				return self._nil
			elseif self._false and vType == self._manager.type.False then
				return self._false
			else
				return false
			end
		end
	end
end

function FalsableUnion:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	local nTrueInclude = self._trueType:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	if nTrueInclude then
		return nTrueInclude
	else
		if self._nil and vType == self._manager.type.Nil then
			return self._nil
		elseif self._false and vType == self._manager.type.False then
			return self._false
		else
			return false
		end
	end
end

function FalsableUnion:isNilable()
	return self._nil and true
end

function FalsableUnion:partTypedObject()
	return self._trueType:partTypedObject()
end

function FalsableUnion:partTypedFunction()
	return self._trueType:partTypedFunction()
end

function FalsableUnion:mayRecursive()
	return self._trueType:mayRecursive()
end

function FalsableUnion:trueType()
	return self._trueType
end

function FalsableUnion:notnilType()
	return self._notnilType
end

function FalsableUnion:falseType()
	return self._falseType or self._manager.type.Never
end

return FalsableUnion

end end
--thlua.union.FalsableUnion end ==========)

--thlua.union.FuncUnion begin ==========(
do local _ENV = _ENV
packages['thlua.union.FuncUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Truth = require "thlua.type.Truth"

local AnyFunction = require "thlua.func.AnyFunction"
local OpenFunction = require "thlua.func.OpenFunction"
local TypedFunction = require "thlua.func.TypedFunction"
local TypedMemberFunction = require "thlua.func.TypedMemberFunction"
local BaseFunction = require "thlua.func.BaseFunction"

local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local FuncUnion = class (BaseUnionType)

function FuncUnion:ctor(vManager)
	self._typeFnDict={}  
	self._typeMfnDict={}  
	self._notTypeFnDict={}  
	self._openFnDict={}  
	self._anyFn=false
	self._typedPart=false
	self.bits=TYPE_BITS.FUNCTION
end

function FuncUnion:foreach(vFunc)
	for nType, _ in pairs(self._openFnDict) do
		vFunc(nType)
	end
	local nAnyFn = self._anyFn
	if not nAnyFn then
		for nType, _ in pairs(self._typeFnDict) do
			vFunc(nType)
		end
		for nType, _ in pairs(self._typeMfnDict) do
			vFunc(nType)
		end
		for nType, _ in pairs(self._notTypeFnDict) do
			vFunc(nType)
		end
	else
		vFunc(nAnyFn)
	end
end

function FuncUnion:putAwait(vType)
	if self:includeAtom(vType) then
		return
	end
	if OpenFunction.is(vType) then
		self._openFnDict[vType] = true
	elseif AnyFunction.is(vType) then
		self._anyFn = vType
		do
			self._notTypeFnDict = {}
			self._typeFnDict = {}
		end
	              
	elseif TypedFunction.is(vType) then
		   
		local nDeleteList = {}
		for nTypeFn, _ in pairs(self._typeFnDict) do
			if vType:includeAtom(nTypeFn) then
				nDeleteList[#nDeleteList + 1] = nTypeFn
			else
				local nIntersect = vType:intersectAtom(nTypeFn)
				if nIntersect then
					error("unexpected intersect when union function")
				end
			end
		end
		for _, nTypeFn in pairs(nDeleteList) do
			self._typeFnDict[nTypeFn] = nil
		end
		self._typeFnDict[vType] = true
	elseif TypedMemberFunction.is(vType) then
		   
		local nDeleteList = {}
		for nTypeFn, _ in pairs(self._typeMfnDict) do
			if vType:includeAtom(nTypeFn) then
				nDeleteList[#nDeleteList + 1] = nTypeFn
			else
				local nIntersect = vType:intersectAtom(nTypeFn)
				if nIntersect then
					error("unexpected intersect when union function")
				end
			end
		end
		for _, nTypeFn in pairs(nDeleteList) do
			self._typeMfnDict[nTypeFn] = nil
		end
		self._typeMfnDict[vType] = true
	elseif BaseFunction.is(vType) then
		self._notTypeFnDict[vType] = true
	else
		error("fn-type unexpected")
	end
end

function FuncUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Truth.is(vType) then
		return self
	end
	if self:includeAtom(vType) then
		return vType
	end
	if TypedFunction.is(vType) or TypedMemberFunction.is(vType) then
		local nCollection = self._manager:TypeCollection()
		self:foreach(function(vSubType)
			if vType:includeAtom(vSubType) then
				nCollection:put(vSubType)
			end
		end)
		return nCollection:mergeToAtomUnion()
	end
	return false
end

function FuncUnion:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	if OpenFunction.is(vType) then
		if self._openFnDict[vType] then
			return vType
		else
			return false
		end
	elseif TypedFunction.is(vType) then
		for nTypeFn, _ in pairs(self._typeFnDict) do
			if nTypeFn:assumeIncludeAtom(vAssumeSet, vType, vSelfType) then
				return nTypeFn
			end
		end
	elseif TypedMemberFunction.is(vType) then
		for nTypeFn, _ in pairs(self._typeMfnDict) do
			if nTypeFn:assumeIncludeAtom(vAssumeSet, vType, vSelfType) then
				return nTypeFn
			end
		end
	elseif BaseFunction.is(vType) then
		if self._notTypeFnDict[vType] then
			return vType
		else
			return false
		end
	end
	return false
end

function FuncUnion:partTypedFunction()
	local nTypedPart = self._typedPart
	if nTypedPart then
		return nTypedPart
	else
		if not next(self._notTypeFnDict) and not next(self._openFnDict) and not self._anyFn then
			self._typedPart = self
			return self
		else
			local nCollection = self._manager:TypeCollection()
			for k,v in pairs(self._typeFnDict) do
				nCollection:put(k)
			end
			local nTypedPart = nCollection:mergeToAtomUnion()
			self._typedPart = nTypedPart
			return nTypedPart
		end
	end
end

function FuncUnion:mayRecursive()
	return true
end

return FuncUnion

end end
--thlua.union.FuncUnion end ==========)

--thlua.union.Never begin ==========(
do local _ENV = _ENV
packages['thlua.union.Never'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local Never = class (BaseUnionType)

function Never:ctor(vManager)
	self.bits=TYPE_BITS.NEVER
end

function Never:detailString(vStringCache, vVerbose)
	return "Never"
end

function Never:foreach(vFunc)
end

function Never:assumeIncludeAtom(vAssumeSet, vType, _)
	return false
end

function Never:assumeIntersectAtom(vAssumeSet, vType)
	return false
end

function Never:unionSign()
	return ""
end

function Never:isNever()
    return true
end

return Never

end end
--thlua.union.Never end ==========)

--thlua.union.NumberLiteralUnion begin ==========(
do local _ENV = _ENV
packages['thlua.union.NumberLiteralUnion'] = function (...)

local NumberLiteral = require "thlua.type.NumberLiteral"
local Number = require "thlua.type.Number"
local Truth = require "thlua.type.Truth"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local NumberLiteralUnion = class (BaseUnionType)

function NumberLiteralUnion:ctor(vTypeManager)
	self._literalSet={}  
	self.bits=TYPE_BITS.NUMBER
end

function NumberLiteralUnion:putAwait(vType)
	if NumberLiteral.is(vType) then
		self._literalSet[vType] = true
	else
		error("set put wrong")
	end
end

function NumberLiteralUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Number.is(vType) or Truth.is(vType) then
		return self
	else
		return self:assumeIncludeAtom(nil, vType)
	end
end

function NumberLiteralUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if NumberLiteral.is(vType) then
		if self._literalSet[vType] then
			return vType
		else
			return false
		end
	else
		return false
	end
end

function NumberLiteralUnion:foreach(vFunc)
	for nLiteralType, v in pairs(self._literalSet) do
		vFunc(nLiteralType)
	end
end

return NumberLiteralUnion

end end
--thlua.union.NumberLiteralUnion end ==========)

--thlua.union.ObjectUnion begin ==========(
do local _ENV = _ENV
packages['thlua.union.ObjectUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local OpenTable = require "thlua.object.OpenTable"
local SealTable = require "thlua.object.SealTable"
local BaseObject = require "thlua.object.BaseObject"
local TypedObject = require "thlua.object.TypedObject"
local Truth = require "thlua.type.Truth"

local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local ObjectUnion = class (BaseUnionType)

function ObjectUnion:ctor(vManager)
	self._typedObjectDict={}  
	self._sealTableDict={}  
	self._openTableDict={}  
	self._typedPart=false
	self.bits=TYPE_BITS.OBJECT
end

function ObjectUnion:foreach(vFunc)
	for nType, _ in pairs(self._typedObjectDict) do
		vFunc(nType)
	end
	for nType, _ in pairs(self._sealTableDict) do
		vFunc(nType)
	end
	for nType, _ in pairs(self._openTableDict) do
		vFunc(nType)
	end
end

function ObjectUnion:putAwait(vType)
	if self:includeAtom(vType) then
		return
	end
	if not BaseObject.is(vType) then
		error("object-type unexpected")
	end
	if OpenTable.is(vType) then
		self._openTableDict[vType] = true
		return
	end
	   
	local nDeleteList1 = {}
	for nSealTable, _ in pairs(self._sealTableDict) do
		if vType:includeAtom(nSealTable) then
			nDeleteList1[#nDeleteList1 + 1] = nSealTable
		end
	end
	for _, nSealTable in pairs(nDeleteList1) do
		self._sealTableDict[nSealTable] = nil
	end
	if SealTable.is(vType) then
		self._sealTableDict[vType] = true
	elseif TypedObject.is(vType) then
		   
		local nDeleteList2 = {}
		for nTypedObject, _ in pairs(self._typedObjectDict) do
			if vType:includeAtom(nTypedObject) then
				nDeleteList2[#nDeleteList2 + 1] = nTypedObject
			else
				local nIntersect = vType:intersectAtom(nTypedObject)
				if nIntersect then
					error("unexpected intersect when union object")
				end
			end
		end
		for _, nTypedObject in pairs(nDeleteList2) do
			self._typedObjectDict[nTypedObject] = nil
		end
		self._typedObjectDict[vType] = true
	else
		error("object-type unexpected???")
	end
end

function ObjectUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Truth.is(vType) then
		return self
	end
	if not BaseObject.is(vType) then
		return false
	end
	local nCollection = self._manager:TypeCollection()
	local nExplicitCount = 0
	self:foreach(function(vSubType)
		if nExplicitCount then
			local nCurIntersect = vType:assumeIntersectAtom(vAssumeSet, vSubType)
			if nCurIntersect == true then
				nExplicitCount = false
			elseif nCurIntersect then
				nExplicitCount = nExplicitCount + 1
				nCollection:put(nCurIntersect)
			end
		end
	end)
	if not nExplicitCount then
		return true
	else
		return nExplicitCount > 0 and nCollection:mergeToAtomUnion()
	end
end

function ObjectUnion:partTypedObject()
	local nTypedPart = self._typedPart
	if nTypedPart then
		return nTypedPart
	else
		if not next(self._openTableDict) and not next(self._sealTableDict) then
			self._typedPart = self
			return self
		else
			local nCollection = self._manager:TypeCollection()
			for k,v in pairs(self._typedObjectDict) do
				nCollection:put(k)
			end
			local nTypedPart = nCollection:mergeToAtomUnion()
			self._typedPart = nTypedPart
			return nTypedPart
		end
	end
end

function ObjectUnion:mayRecursive()
	return true
end

function ObjectUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if OpenTable.is(vType) then
		return self._openTableDict[vType] and vType or false
	end
	if SealTable.is(vType) then
		for nTable, _ in pairs(self._sealTableDict) do
			if nTable:assumeIncludeAtom(vAssumeSet, vType) then
				return nTable
			end
		end
	end
	for nObject, _ in pairs(self._typedObjectDict) do
		if nObject:assumeIncludeAtom(vAssumeSet, vType) then
			return nObject
		end
	end
	return false
end

return ObjectUnion

end end
--thlua.union.ObjectUnion end ==========)

--thlua.union.StringLiteralUnion begin ==========(
do local _ENV = _ENV
packages['thlua.union.StringLiteralUnion'] = function (...)

local StringLiteral = require "thlua.type.StringLiteral"
local String = require "thlua.type.String"
local Truth = require "thlua.type.Truth"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseUnionType = require "thlua.union.BaseUnionType"
local class = require "thlua.class"

  

local StringLiteralUnion = class (BaseUnionType)

function StringLiteralUnion:ctor(vTypeManager)
	self._literalSet={}     
	self.bits=TYPE_BITS.STRING
end

function StringLiteralUnion:putAwait(vType)
	if StringLiteral.is(vType) then
		self._literalSet[vType] = true
	else
		error("set put wrong")
	end
end

function StringLiteralUnion:assumeIntersectAtom(vAssumeSet, vType)
	if String.is(vType) or Truth.is(vType) then
		return self
	else
		return self:assumeIncludeAtom(nil, vType)
	end
end

function StringLiteralUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if StringLiteral.is(vType) then
		if self._literalSet[vType] then
			return vType
		else
			return false
		end
	else
		return false
	end
end

function StringLiteralUnion:foreach(vFunc)
	for nLiteralType, v in pairs(self._literalSet) do
		vFunc(nLiteralType)
	end
end

return StringLiteralUnion

end end
--thlua.union.StringLiteralUnion end ==========)

return require "thlua.boot"
