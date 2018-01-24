local splitPath = require('pathjoin').splitPath
local Object = require('core').Object

------------------------------------------- DB
local DB = Object:extend()

function DB:initialize(driver, ...)
	self._driver = driver or self._driver
	if self._driver == 'sqlite3' then
		self._env = require("luasql.sqlite3").sqlite3()
	elseif self._driver == 'postgres' then
		self._env = require("luasql.postgres").postgres()
	elseif self._driver == 'mysql' then
		self._env = require("luasql.mysql").mysql()
	end
	if self._env then
		self._conn = self._env:connect(...)
	end
end

function DB:select(statement, needcolumn)
	needcolumn = needcolumn and "a"
	local _rows = {}
	local cur = self._conn:execute(statement)
	row = cur:fetch({}, needcolumn)
	while row do
		local r= row
		if #row == 1 then r = row[1] end
		table.insert(_rows, r)
		row = cur:fetch({}, needcolumn)
	end
	if #_rows == 0 then
		return nil
	elseif #_rows == 1 then
		return _rows[1]
	else
		return _rows
	end
end

function DB:run(...)
	return self._conn:execute(...)
end


function DB:commit(...)
	self._conn:commit(...)
end

function DB:rollback(...)
	self._conn:rollback(...)
end

function DB:setautocommit(...)
	self._conn:setautocommit(...)
end

function DB:close()
	self._conn:close()
	self._env:close()
end

------------------------------------------- Model
local Model = Object:extend()

function Model:initialize(driver, ...)
	if type(driver) == 'table' and driver._conn then
		self.db = driver
	elseif type(driver) == 'string' then
		self.db = DB:new(driver, ...)
	end
	local s = splitPath(debug.getinfo(3).source)
	local file = s[#s]
	local table = string.sub(file, 1, string.find(file, '.lua')-1)
	self.table = table
end

function Model:save(row)
	local ks = {}
	local vs = {}
	for k, v in pairs(row) do
		table.insert(ks, k)
		table.insert(vs, "'"..v.."'")
	end
	local sql = string.format("insert into %s(%s) values(%s)", self.table, table.concat(ks, ','), table.concat(vs, ','))
	-- p("[sql]", sql)
	return self.db:run(sql)
end
function Model:all()
	local sql = string.format("select * from %s", self.table)
	-- p("[sql]", sql)
	return self.db:select(sql, true)
end
function Model:find(id)
	local sql = string.format("select * from %s where id = %s", self.table, id)
	-- p("[sql]", sql)
	return self.db:select(sql, true)
end
function Model:where(wkv)
	local wkvs = {}
	for k, v in pairs(wkv) do
		table.insert(wkvs, k.."='"..v.."'")
	end
	local sql = string.format("select * from %s where %s", self.table, table.concat(wkvs, ' and '))
	-- p("[sql]", sql)
	return self.db:select(sql, true)
end
function Model:update(kv, wkv)
	local kvs = {}
	for k, v in pairs(kv) do
		table.insert(kvs, k.."='"..v.."'")
	end
	local wkvs = {}
	for k, v in pairs(wkv) do
		table.insert(wkvs, k.."='"..v.."'")
	end
	local sql = string.format("update %s set %s where %s", self.table, table.concat(kvs, ','), table.concat(wkvs, ' and '))
	-- p("[sql]", sql)
	return self.db:run(sql)
end
function Model:destroy(wkv)
	local wkvs = {}
	for k, v in pairs(wkv) do
		table.insert(wkvs, k.."='"..v.."'")
	end
	local sql = string.format("delete from %s where %s", self.table, table.concat(wkvs, ' and '))
	-- p("[sql]", sql)
	return self.db:run(sql)
end

return {
	DB = DB,
	Model = Model,
}
