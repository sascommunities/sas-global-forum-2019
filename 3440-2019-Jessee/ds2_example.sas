package "${PACKAGE_NAME}" / inline ;
 
      /* lookup keys are managed internal to the package */
      dcl int _year;
      dcl varchar(52) _make;
      dcl varchar(160) _model;
      dcl varchar(32) _type;
      dcl double baseValue;
      dcl double ACValue;
      dcl double PSValue;
     
      dcl package hash myCustomLookupHash ([_make _model _type _year],[baseValue ACValue PSValue]);
      dcl package sqlstmt lookupDataSource;
      dcl varchar(100) sql;
      dcl int rc;
      dcl int initComplete;
     
      method loadLookup();
            myCustomLookupHash.clear();
            sql = 'SELECT make,model,type,year,baseValue,ACValue,PSValue from "carslookup"';
            lookupDataSource = _new_ sqlstmt(sql);
            rc = lookupDataSource.execute();
           
            if rc ne 2 then 
		do while (lookupDataSource.fetch([_make _model _type _year baseValue ACValue PSValue]) eq 0);
                  /* use strip() upcase() to make hash key matching more forgiving */
                  _make = upcase(strip(_make));
                  _model = upcase(strip(_model));
                  _type = upcase(strip(_type));
                  myCustomLookupHash.ref([_make _model _type _year],[baseValue ACValue PSValue]);
            	end;
           
            lookupDataSource.closeResults();
            initComplete=1;
      end;
     
      method execute(varchar(52) make, 
	varchar(160) model, 
	varchar(32) type, 
	double year, 
	in_out double factor_BaseValue, 
	in_out double factor_AirConditioning,
        in_out double factor_PowerSteering);

            if missing(initComplete) then loadLookup();
           
            /* assign keys - variable lists must reference global variables */
            /* use strip() upcase() to make hash key matching more forgiving */
            _make = upcase(strip(make));
            _model = upcase(strip(model));
            _type = upcase(strip(type));
            _year = year;
           
            if myCustomLookupHash.find([_make _model _type _year],[baseValue ACValue PSValue]) = 0 then do;
                  factor_BaseValue = baseValue;
                  factor_AirConditioning = ACValue;
                  factor_PowerSteering = PSValue;
            end;
            else do;
                  /* In this example use static values */
                  factor_BaseValue = 200; /* scrap metal value */
                  factor_AirConditioning = .;
                  factor_PowerSteering = .;
            end;
      end;
endpackage;
