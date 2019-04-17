filename luapath "<location of the REST lua module>";
/* Set this if you want to store the header and body files somewhere other than work */
%let working_folder=;
proc lua restart;
submit;
	local rest = require 'rest'
   
	rest.base_url = 'http://httpbin.org/'

	local pass,code = rest.request('get','ip')
	print(pass,code)
	print(rest.utils.read('_bout_'))


endsubmit;
run;