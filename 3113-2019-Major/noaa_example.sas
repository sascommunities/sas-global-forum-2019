filename luapath "<location of the NOAA module>";
PROC LUA restart;
submit;
	local noaa = require 'noaa'

	noaa.token='jfFOguhJNpUDOhhVvoHdVmXMhlCneimp';

	-- Get a list of all datasets
      local pass, datasets = noaa.datasets.get()

	--Get some actual data
	local filter = {limit=25,locationid='ZIP:27603'}
	local pass, data = noaa.data.get('GHCND','2018-01-01','2018-01-31',filter,'work.weather')

	--Use the generic request function to access the stations API
	local pass, output = noaa.request('get','stations',{locationid='ZIP:27603'})

endsubmit;
RUN;
