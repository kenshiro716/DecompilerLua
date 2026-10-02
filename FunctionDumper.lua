-- FunctionDumper.lua
-- A function dumper that uses SynSaveInstance to extract and decompile Lua functions

local FunctionDumper = {}

-- Configuration for SynSaveInstance
local Params = {
	RepoURL = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/",
	SSI = "saveinstance",
}

-- Initialize SynSaveInstance
local function initializeSynSaveInstance()
	local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
	return synsaveinstance
end

-- Dump a single function with optional SynSaveInstance integration
function FunctionDumper:DumpFunction(func, options)
	options = options or {}
	
	if type(func) ~= "function" then
		return nil, "Input must be a function"
	end
	
	local result = {
		source = nil,
		bytecode = nil,
		constants = nil,
		upvalues = nil,
		metadata = {
			dumpTime = os.time(),
			useSynSaveInstance = options.useSynSaveInstance or false,
		}
	}
	
	-- Attempt to get source
	if options.getSource then
		local success, source = pcall(function()
			return debug.getinfo(func, "S").source
		end)
		if success then
			result.source = source
		end
	end
	
	-- Attempt to get upvalues
	if options.getUpvalues then
		result.upvalues = {}
		local i = 1
		while true do
			local name, value = debug.getupvalue(func, i)
			if not name then break end
			table.insert(result.upvalues, {
				name = name,
				value = tostring(value),
				type = type(value)
			})
			i = i + 1
		end
	end
	
	return result
end

-- Dump multiple functions from a table/object
function FunctionDumper:DumpTable(tbl, options)
	options = options or {}
	local results = {}
	
	for key, value in pairs(tbl) do
		if type(value) == "function" then
			results[key] = self:DumpFunction(value, options)
		end
	end
	
	return results
end

-- Use SynSaveInstance to save a function as code
function FunctionDumper:SaveInstanceWithSynSaveInstance(instance, options)
	options = options or options or {} -- Documentation: https://luau.github.io/UniversalSynSaveInstance/api/SynSaveInstance
	
	local synsaveinstance = initializeSynSaveInstance()
	if not synsaveinstance then
		return nil, "Failed to initialize SynSaveInstance"
	end
	
	local success, result = pcall(function()
		return synsaveinstance(options)
	end)
	
	if success then
		return result
	else
		return nil, tostring(result)
	end
end

-- Enhanced function dumper that combines decompilation with SynSaveInstance
function FunctionDumper:DumpWithSynSaveInstance(func, instanceToSave, options)
	options = options or {}
	
	local funcDump = self:DumpFunction(func, {
		getSource = true,
		getUpvalues = true
	})
	
	if instanceToSave then
		local instanceSave = self:SaveInstanceWithSynSaveInstance(instanceToSave, options)
		funcDump.instanceCode = instanceSave
	end
	
	funcDump.metadata.useSynSaveInstance = true
	return funcDump
end

-- Format dumped function data for output
function FunctionDumper:FormatDump(dump, indent)
	indent = indent or 0
	local indentStr = string.rep(" ", indent)
	local output = {}
	
	table.insert(output, indentStr .. "=== Function Dump ===")
	table.insert(output, indentStr .. "Dump Time: " .. os.date("%Y-%m-%d %H:%M:%S", dump.metadata.dumpTime))
	table.insert(output, indentStr .. "Uses SynSaveInstance: " .. tostring(dump.metadata.useSynSaveInstance))
	
	if dump.source then
		table.insert(output, indentStr .. "Source: " .. tostring(dump.source))
	end
	
	if dump.upvalues and #dump.upvalues > 0 then
		table.insert(output, indentStr .. "Upvalues:")
		for _, upvalue in ipairs(dump.upvalues) do
			table.insert(output, indentStr .. "  - " .. upvalue.name .. ": " .. upvalue.type)
		end
	end
	
	if dump.instanceCode then
		table.insert(output, indentStr .. "Instance Code:")
		table.insert(output, indentStr .. tostring(dump.instanceCode))
	end
	
	return table.concat(output, "\n")
end

return FunctionDumper
