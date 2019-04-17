---
--    Copyright (c) 2019 by SAS Institute Inc., Cary, NC, USA.
-- 
--- Functions for interfacing with the NOAA APIs - documented here: 
-- https://www.ncdc.noaa.gov/cdo-web/webservices/v2
--
-- NOTE: Relies on the rest module and json module, which should be in the same location
--
-- EXAMPLE:
--[[ 
filename luapath "<location of this lua module>";
proc lua restart;
submit;

	local noaa = require 'noaa'

	noaa.token='<the token you got from https://www.ncdc.noaa.gov/cdo-web/token>'
	local filter = {limit=25,locationid='ZIP:27603'}
	local pass = noaa.data.get('GHCND','2018-01-01','2018-01-31',filter,'work.weather')
	if not pass then
	   sas.print('%1z Request Failed')
	   return
	end

endsubmit;
run;
]]--

local noaa = {}
local rest = require 'rest'
local json = require 'json'

-- The token that will be used for requests.
noaa.token=false

-- Set the base url
rest.base_url = 'https://www.ncdc.noaa.gov/cdo-web/api/v2/'

--- Take a table of parameters and create a string to append to a url
-- @params parms_table [table] - table of name,value pairs
-- @return parms_string [string] - parameter table parsed as a string
function parms_table_to_string(parms_table)
  local has_parm = false
  local parms_string = ""
  for key,value in pairs(parms_table or {}) do
     if value then
	    if has_parm then parms_string = parms_string..'&' end
	    parms_string = parms_string..key..'='..value
		 has_parm = true
	 end
  end
  if has_parm then parms_string='?'..parms_string end
  return parms_string
end

-----------------------------------------------------
--                         #DATASETS               --
-----------------------------------------------------
noaa.datasets = {}
--- Get a specific dataset or pass nil for id and get a list of all datasets. Use filters to filter the results. See"
---  https://www.ncdc.noaa.gov/cdo-web/webservices/v2#datasets
-- @param id [string] - Optional, if nil a list of all tables is returned, otherwise querry a specific table by id
-- @param filters [table] - Optional, table with entries for any filters to apply. See help for the list.
-- @return pass [boolean] - true if call was successful, false if error occurred.
-- @return datasets [table] - Table with all available datasets
function noaa.datasets.get(id,filters)
    if not noaa.token then
	   sas.print('%1zYou need to specify a token first')
	   return false,nil
	end
	local id_str = ""
	if id then id_str = '/'..tostring(id) end
	local parms_str = parms_table_to_string(filters)
	rest.utils.write('_hin_','token:'..noaa.token)
	local pass,code = rest.request('get','datasets'..id_str..parms_str,nil,'_hin_')
	if not pass then
	   return false, nil
	end
	return true, json:decode(rest.utils.read('_bout_'))
end

------------------------------------------------
--                         #DATA              --
------------------------------------------------
noaa.data = {}
--- Get a specific dataset or pass nil for id and get a list of all datasets. Use filters to filter the results. This APi will be deprecated soon (as of March 2019)
---  https://www.ncdc.noaa.gov/cdo-web/webservices/v2#data
-- @param id [string] - dataset id to get data for. Use datasets.get() to see a list of all IDs
-- @param startdate [string] - required, Accepts valid ISO formated date (YYYY-MM-DD) or date time (YYYY-MM-DDThh:mm:ss)
-- @param enddate [string] - required, Accepts valid ISO formated date (YYYY-MM-DD) or date time (YYYY-MM-DDThh:mm:ss)
-- @param filters [table] - Optional, table with entries for any filters to apply. See help for the list.
-- @param dataset_name [string] - Optional. If nothing is specified, no dataset is created. Otherwise, a dataset called 'dataset_name' is 
--                                created with the contents of the requested data. If you specify a libname (e.g. pass  'mylib.dataset') then
--                                the specified library needs to exist
-- @return pass [boolean] - true if call was successful, false if error occurred.
-- @return data [table] - Table with the requested data
function noaa.data.get(id,startdate,enddate,filters,dataset_name)
    if not noaa.token then
	   sas.print('%1zYou need to specify a token first')
	   return false,nil
	end
	if not id then
	   sas.print('%1zAn id is required for this API')
	   return false,nil
	end
   --default output_type to table only
   dataset_name = dataset_name or false
	filters = filters or {}
	filters.datasetid = tostring(id)
	filters.enddate = tostring(enddate)
	filters.startdate = tostring(startdate)
	local parms_str = parms_table_to_string(filters)
	rest.utils.write('_hin_','token:'..noaa.token)
	local pass,code = rest.request('get','data'..parms_str,nil,'_hin_')
	if not pass then
	   return false, nil
	end
   local output = json:decode(rest.utils.read('_bout_'))
   if dataset_name then
      local sasds = output.results
      sasds.vars={station    = {length=32, type="C"},
                  date       = {length=32, type="C"},
                  value      = {length=8,  type="N"},
                  attributes = {length=32, type="C"},
                  datatype   = {length=8,  type="C"}
                  }
      sas.write_ds(sasds, tostring(dataset_name))
   end
	return true, output
end

------------------------------------------------
--                      #GENERIC              --
------------------------------------------------
--- Generic request function for endpoints not covered in this module for the v2 API
function noaa.request(method,endpoint,filters)
    if not noaa.token then
	   sas.print('%1zYou need to specify a token first')
	   return false,nil
	end
	filters = filters or {}
   endpoint = endpoint or ''
   method = method or 'get'
	local parms_str = parms_table_to_string(filters)
	rest.utils.write('_hin_','token:'..noaa.token)
	local pass,code = rest.request(method,endpoint..parms_str,nil,'_hin_')
	if not pass then
	   return false, nil
	end
	return true, rest.utils.read('_bout_')
end

return noaa