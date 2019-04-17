/*Please note that this is only the sample code for SAS Global Forum and shall be varying from the actual implementation*/



/*Optimization model*/

/*%Macro OR_process();*/
proc optmodel;

/*Declare dimensions*/
set <num, num, num, num>x_dim;
set <num>y_dim;
set <num, num>u_dim;
set <num, num>v_dim;
set <num, num>capacity_dim;
set <num, num, num>demand_dim;
set <num>source_st_dim;
set <num>destin_st_dim;

/* Decalare parameters*/
num capacity{capacity_dim};
num demand{demand_dim};
num train_capacity{y_dim};
num out_demand{source_st_dim};
num in_demand{destin_st_dim};

/*Declare decision variables*/
var y{y_dim} binary;
var u{u_dim} binary;
var v{v_dim} binary;
var x{x_dim};

/*Read the data into the dimension variable*/
read data sasgf.demand into demand_dim= [sourceid destinationid classid] demand=demand ;
read data sasgf.capacity into capacity_dim= [trainid classid] capacity=capacity;
read data sasgf.addedcaps into y_dim= [trainid] train_capacity=train_capacity;
read data sasgf.sourceid into u_dim= [ sourceid trainid];
read data sasgf.Destinationid into v_dim= [ Destinationid trainid];
read data sasgf.berths into x_dim= [Sourceid Destinationid Classid Trainid ];
read data sasgf.addedoutdem into source_st_dim= [sourceid] out_demand=out_demand;
read data sasgf.addedindem into destin_st_dim= [destinationid] in_demand=in_demand;


/*Optimization Objective Function*/
Min Total_transit= sum{<trainid> in y_dim}
	(100*y[trainid]) + sum{<sourceid, trainid > in u_dim}(10*u[sourceid, trainid ])
+ sum{<destinationid, trainid > in v_dim}(10*v[destinationid, trainid ]);

/*Constraints*/
/*Note: For sum{< put brackets () for those over which sum is NOT to be taken>}
 For better understanding, here we are doing as following:
For combination of each cluster_id and analysis_id, total skuids should be less than 3
ie we are summing binary variable skuid, so summing variable should be outside of () brackets
and 'for each variables' should be in brackets
*/

/*Constraint 1*/
con capacity_constraint{<trainid, classid> in capacity_dim}:
sum{<sourceid, destinationid, (classid), (trainid) > in x_dim}
 x[sourceid, destinationid, classid, trainid]<=capacity[trainid, classid];

 /*Constraint 2*/
con demand_constraint{<sourceid, destinationid, classid> in demand_dim}:
sum{<(sourceid), (destinationid), (classid), trainid > in x_dim}
 x[sourceid, destinationid, classid, trainid]>=demand[sourceid, destinationid, classid];

 /*Constraint 3.1a*/
/*con linking_t1a_cons{<Sourceid, trainid > in u_dim}:*/
/*sum{<(Sourceid), Destinationid, classid, (trainid) > in x_dim}*/
/* x[Sourceid, Destinationid, classid, trainid]<=train_capacity[trainid]*u[sourceid, trainid];*/

 /*Constraint 3.1b*/
/*con linking_t1b_cons{<Sourceid, trainid > in u_dim}:*/
/*sum{<(Sourceid), Destinationid, classid, (trainid) > in x_dim}*/
/* x[sourceid, destinationid, classid, trainid]<=out_demand[sourceid]*u[sourceid, trainid];*/


  /*Constraint 4.1a*/
/*con linking_t2a_cons{<destinationid, trainid > in v_dim}:*/
/*sum{<sourceid, (destinationid), classid, (trainid) > in x_dim}*/
/*x[sourceid, destinationid, classid, trainid]<=train_capacity[trainid]*v[Destinationid, trainid];*/

 /*Constraint 4.1b*/
/*con linking_t2b_cons{<destinationid,trainid > in v_dim}:*/
/*sum{<sourceid, (destinationid), classid, (trainid) > in x_dim}*/
/*x[sourceid, destinationid, classid, trainid]<=in_demand[destinationid]*v[Destinationid, trainid];*/

/* Constraint 5.1*/
 con train_constraint1{<sourceid, trainid> in u_dim}:
 u[sourceid,trainid]<=y[trainid];
 
/* Constraint 5.2*/
 con train_constraint2{<destinationid, trainid > in v_dim}:
 v[destinationid, trainid]<=y[trainid];

 /*Constraint 6*/
 con berth_constraint{<sourceid, destinationid, classid, trainid > in x_dim}:
 x[sourceid, destinationid, classid, trainid]>=0;

 solve; 
/*solve with milp / relobjgap=1e-1; */

/*Output Solutions*/

create data sasgf.solution_x from [sourceid destinationid classid trainid]
={<sourceid, destinationid, classid, trainid> in x_dim:
x[sourceid, destinationid, classid, trainid].sol}
x=x;
quit;
/*%mend OR_process;*/
