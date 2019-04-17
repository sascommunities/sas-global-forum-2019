options 
  FULLSTIMER 
  MSGLEVEL = I
;
libname mysets "...";

data mysets.countries; /* a dataset with a list of countries */
  infile cards dlm = '0A'x;;
  input country $ :50.;
  call streaminit(2222);
  sort = rand("uniform");
cards;
Afghanistan [AFG]
Aland Islands [ALA]
Albania [ALB]
Algeria [DZA]
American Samoa [ASM]
Andorra [AND]
Angola [AGO]
Anguilla [AIA]
Antarctica [ATA]
Antigua and Barbuda [ATG]
Argentina [ARG]
Armenia [ARM]
Aruba [ABW]
Australia [AUS]
Austria [AUT]
Azerbaijan [AZE]
Bahamas [BHS]
Bahrain [BHR]
Bangladesh [BGD]
Barbados [BRB]
Belarus [BLR]
Belgium [BEL]
Belize [BLZ]
Benin [BEN]
Bermuda [BMU]
Bhutan [BTN]
Bolivia [BOL]
Bosnia and Herzegovina [BIH]
Botswana [BWA]
Bouvet Island [BVT]
Brazil [BRA]
British Virgin Islands [VGB]
British Indian Ocean Territory [IOT]
Brunei Darussalam [BRN]
Bulgaria [BGR]
Burkina Faso [BFA]
Burundi [BDI]
Cambodia [KHM]
Cameroon [CMR]
Canada [CAN]
Cape Verde [CPV]
Cayman Islands  [CYM]
Central African Republic [CAF]
Chad [TCD]
Chile [CHL]
China [CHN]
Hong Kong, SAR China [HKG]
Macao, SAR China [MAC]
Christmas Island [CXR]
Cocos (Keeling) Islands [CCK]
Colombia [COL]
Comoros [COM]
Congo (Brazzaville) [COG]
Congo, (Kinshasa) [COD]
Cook Islands  [COK]
Costa Rica [CRI]
Côte d'Ivoire [CIV]
Croatia [HRV]
Cuba [CUB]
Cyprus [CYP]
Czech Republic [CZE]
Denmark [DNK]
Djibouti [DJI]
Dominica [DMA]
Dominican Republic [DOM]
Ecuador [ECU]
Egypt [EGY]
El Salvador [SLV]
Equatorial Guinea [GNQ]
Eritrea [ERI]
Estonia [EST]
Ethiopia [ETH]
Falkland Islands (Malvinas)  [FLK]
Faroe Islands [FRO]
Fiji [FJI]
Finland [FIN]
France [FRA]
French Guiana [GUF]
French Polynesia [PYF]
French Southern Territories [ATF]
Gabon [GAB]
Gambia [GMB]
Georgia [GEO]
Germany [DEU]
Ghana [GHA]
Gibraltar  [GIB]
Greece [GRC]
Greenland [GRL]
Grenada [GRD]
Guadeloupe [GLP]
Guam [GUM]
Guatemala [GTM]
Guernsey [GGY]
Guinea [GIN]
Guinea-Bissau [GNB]
Guyana [GUY]
Haiti [HTI]
Heard and Mcdonald Islands [HMD]
Holy See (Vatican City State) [VAT]
Honduras [HND]
Hungary [HUN]
Iceland [ISL]
India [IND]
Indonesia [IDN]
Iran, Islamic Republic of [IRN]
Iraq [IRQ]
Ireland [IRL]
Isle of Man  [IMN]
Israel [ISR]
Italy [ITA]
Jamaica [JAM]
Japan [JPN]
Jersey [JEY]
Jordan [JOR]
Kazakhstan [KAZ]
Kenya [KEN]
Kiribati [KIR]
Korea (North) [PRK]
Korea (South) [KOR]
Kuwait [KWT]
Kyrgyzstan [KGZ]
Lao PDR [LAO]
Latvia [LVA]
Lebanon [LBN]
Lesotho [LSO]
Liberia [LBR]
Libya [LBY]
Liechtenstein [LIE]
Lithuania [LTU]
Luxembourg [LUX]
Macedonia, Republic of [MKD]
Madagascar [MDG]
Malawi [MWI]
Malaysia [MYS]
Maldives [MDV]
Mali [MLI]
Malta [MLT]
Marshall Islands [MHL]
Martinique [MTQ]
Mauritania [MRT]
Mauritius [MUS]
Mayotte [MYT]
Mexico [MEX]
Micronesia, Federated States of [FSM]
Moldova [MDA]
Monaco [MCO]
Mongolia [MNG]
Montenegro [MNE]
Montserrat [MSR]
Morocco [MAR]
Mozambique [MOZ]
Myanmar [MMR]
Namibia [NAM]
Nauru [NRU]
Nepal [NPL]
Netherlands [NLD]
Netherlands Antilles [ANT]
New Caledonia [NCL]
New Zealand [NZL]
Nicaragua [NIC]
Niger [NER]
Nigeria [NGA]
Niue  [NIU]
Norfolk Island [NFK]
Northern Mariana Islands [MNP]
Norway [NOR]
Oman [OMN]
Pakistan [PAK]
Palau [PLW]
Palestinian Territory [PSE]
Panama [PAN]
Papua New Guinea [PNG]
Paraguay [PRY]
Peru [PER]
Philippines [PHL]
Pitcairn [PCN]
Poland [POL]
Portugal [PRT]
Puerto Rico [PRI]
Qatar [QAT]
Réunion [REU]
Romania [ROU]
Russian Federation [RUS]
Rwanda [RWA]
Saint-Barthélemy [BLM]
Saint Helena [SHN]
Saint Kitts and Nevis [KNA]
Saint Lucia [LCA]
Saint-Martin (French part) [MAF]
Saint Pierre and Miquelon  [SPM]
Saint Vincent and Grenadines [VCT]
Samoa [WSM]
San Escobar [SER]
San Marino [SMR]
Sao Tome and Principe [STP]
Saudi Arabia [SAU]
Senegal [SEN]
Serbia [SRB]
Seychelles [SYC]
Sierra Leone [SLE]
Singapore [SGP]
Slovakia [SVK]
Slovenia [SVN]
Solomon Islands [SLB]
Somalia [SOM]
South Africa [ZAF]
South Georgia and the South Sandwich Islands [SGS]
South Sudan [SSD]
Spain [ESP]
Sri Lanka [LKA]
Sudan [SDN]
Suriname [SUR]
Svalbard and Jan Mayen Islands  [SJM]
Swaziland [SWZ]
Sweden [SWE]
Switzerland [CHE]
Syrian Arab Republic (Syria) [SYR]
Taiwan, Republic of China [TWN]
Tajikistan [TJK]
Tanzania, United Republic of [TZA]
Thailand [THA]
Timor-Leste [TLS]
Togo [TGO]
Tokelau  [TKL]
Tonga [TON]
Trinidad and Tobago [TTO]
Tunisia [TUN]
Turkey [TUR]
Turkmenistan [TKM]
Turks and Caicos Islands  [TCA]
Tuvalu [TUV]
Uganda [UGA]
Ukraine [UKR]
United Arab Emirates [ARE]
United Kingdom [GBR]
United States of America [USA]
US Minor Outlying Islands [UMI]
Uruguay [URY]
Uzbekistan [UZB]
Vanuatu [VUT]
Venezuela (Bolivarian Republic) [VEN]
Viet Nam [VNM]
Virgin Islands, US [VIR]
Wallis and Futuna Islands  [WLF]
Western Sahara [ESH]
Yemen [YEM]
Zambia [ZMB]
Zimbabwe [ZWE]
;
run;

proc sort 
  data = mysets.countries 
  out = mysets.countries(drop = sort)
;
  by sort;
run;
data mysets.INDEXX_OR( 
  INDEX = (
    country 
    date
  ) 
); 
  set 
    mysets.countries           
    mysets.countries
    mysets.countries
    mysets.countries           
    mysets.countries
    mysets.countries
    mysets.countries           
    mysets.countries
    mysets.countries
    mysets.countries
    mysets.countries
    mysets.countries
  ;
  format date yymmdds10.;
 
  do date = '1jan1960'd to '28apr2019'd;                   
    y = year(date);
    m = month(date);
    d = day(date);
    
    call streaminit(123);
    measurement = 456 + round(rand("Normal") * 78);
    output;
  
    if rand("Uniform") > 0.9 then output;              
  end;
run /*cancel*/ ; 
proc contents 
  data = mysets.INDEXX_OR;
run;
proc print 
  data = mysets.INDEXX_OR(obs=3);
  where country = 'Yemen [YEM]' 
    and date = '28apr2019'd
  ;
run;
proc sql;
  select 
    sum(measurement) as SoM format best32.
  , count(1) as i
  from 
    mysets.INDEXX_OR
  where 
    country = 'Poland [POL]'
  ;
quit;
data _NULL_;
  set mysets.INDEXX_OR END = eof;
  where 
    date between '01may2015'd and '30may2015'd    
  ;

  SoM + measurement;
  i + 1;

  if eof then
  do;
    put SoM= best32. i=;
  end;
run;
proc sql;
  select 
    sum(measurement) as SoM format best32.5
  , count(1) as i
  from 
    mysets.INDEXX_OR
  where 
    date between '01may2015'd and '30may2015'd    
    OR    
    country = 'Poland [POL]'
  ;
quit;

data _NULL_;
  set mysets.INDEXX_OR END = eof;
  where 
    date between '01may2015'd and '30may2015'd    
    OR    
    country = 'Poland [POL]'
  ;

  SoM + measurement;
  i + 1;

  if eof then
  do;
    put SoM= best32. i=;
  end;
run;
data _null_; 
 if 0 then set mysets.INDEXX_OR nobs = nobs;
  call symputx("_NOBS_", nobs, "G");
 stop;
run;
data _NULL_;
 ARRAY _obs_[&_NOBS_.] _temporary_;

 do until(eof);
  set 
    mysets.INDEXX_OR END = eof CUROBS = curobs
  ;
  where date between '01may2015'd 
                 and '30may2015'd;
                 
  _obs_[curobs] = 1;
  SoM + measurement;
  i + 1;
 end;

 eof = 0;
 do until(eof);
  set 
    mysets.INDEXX_OR END = eof CUROBS = curobs
  ;
  where country = 'Poland [POL]';

  if _obs_[curobs] NE 1 then
   do;
    _obs_[curobs] = 1; 
    SoM + measurement;
    i + 1;
   end;
 end;

 put SoM= best32. i=;
 stop;
run;
data _NULL_;

 length curobs 8;
 declare HASH _obs_(hashexp:16);
 _obs_.DefineKey("curobs");      
 _obs_.Definedone();             
                                

 do until(eof);
  set mysets.INDEXX_OR END = eof CUROBS=curobs;
  where date between '01may2015'd 
                 and '30may2015'd; 
  rc = _obs_.ADD();
  SoM + measurement;
  i + 1;
 end;

 eof = 0;
 do until(eof);
  set mysets.INDEXX_OR END = eof CUROBS=curobs;
  where country = 'Poland [POL]';

  if _obs_.FIND() NE 0 then
   do;                   
    rc = _obs_.ADD();    
    SoM + measurement;
    i + 1;
   end;
 end;

 put SoM= best32. i=;
 stop;
run;
data _NULL_;

  if _N_ = 1 then 
    do;
      length curobs 8;
      drop curobs;
      declare HASH _obs_(hashexp:16);
      _obs_.DefineKey("curobs");
      _obs_.Definedone();
    end;

  set 
    mysets.INDEXX_OR(
      where = (date between '01may2015'd 
                        and '30may2015'd)
    )
    mysets.INDEXX_OR(
      where = (country = 'Poland [POL]') 
    )  
    CUROBS = CUROBS 
    end = end 
  ;

  if _obs_.check() NE 0 then 
    do;
      rc = _obs_.add();
    end;
  else goto SKIPAGGR; 

  SoM + measurement;
  i + 1;
  
  SKIPAGGR:  
  if end then 
  do;
    put SoM= best32. i=;
    stop;
  end;
run;

/*
Further examples can be found at:
http://www.mini.pw.edu.pl/~bjablons/SASpublic/

e.g. this file (OR-condition-in-WHERE-clause-with-INDEX-a-code-from-the-paper-3722-2019.sas)

http://www.mini.pw.edu.pl/~bjablons/SASpublic/Countries.sas

http://www.mini.pw.edu.pl/~bjablons/SASpublic/OR-condition-in-WHERE-clause-with-INDEX-an-EXTENDED VERSION

http://www.mini.pw.edu.pl/~bjablons/SASpublic/OR-condition-in-WHERE-clause-with-INDEX-a-test-with-SPDE.sas
*/
