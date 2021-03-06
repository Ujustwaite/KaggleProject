/*Data Transform Experiment*/

data trainTransformed; 
	set train;
	if GrLivArea > 4000 then delete; 
	if TotalBsmtSF = 0 then TotalBsmtSF = 1057;
	logTotalBsmtSF = log(TotalBsmtSF);
	if GarageArea = 0 then GarageArea = 473; 
	logGarageArea = log(GarageArea); 
	logSalePrice = log(SalePrice); 
	Age = 2019-YearBuilt;
	logAge = log(Age); 
	logGrLivArea = log(GrLivArea);
	AgeReno = 2019-YearRemodAdd;
	logAgeReno = log(AgeReno);
	QualCondAvg = OverallQual + OverallCond / 2; 
	logTotRmsAbvGrd = log(TotRmsAbvGrd);
;

data testTransformed; 
	set test;
	if TotalBsmtSF = 0 then TotalBsmtSF = 1057;
	logTotalBsmtSF = log(TotalBsmtSF);
	if GarageArea = 0 then GarageArea = 473; 
	logGarageArea = log(GarageArea); 
	Age = 2019-YearBuilt;
	logAge = log(Age); 
	logGrLivArea = log(GrLivArea);
	AgeReno = 2019-YearRemodAdd;
	logAgeReno = log(AgeReno);
	QualCondAvg = OverallQual + OverallCond / 2; 
	logTotRmsAbvGrd = log(TotRmsAbvGrd);
	logSalePrice = .;
;

data predictmodel; 
	set trainTransformed testTransformed;
run; 

/*Categorical Variables to work with? -- #floors (from 2nd floor sqft), SaleCondition*/

proc sgplot data=trainTransformed;
   title 'LogSalePrice vs LogGrLivArea'
   styleattrs datasymbols= (CircleFilled);
   scatter x=logGrLivArea y=logSalePrice / group=SaleCondition;
run;

proc sgplot data=trainTransformed;
   title 'Price vs. LogAge'
   styleattrs datasymbols= (CircleFilled);
   scatter x=logAge y=logSalePrice / group=Neighborhood;
run;

proc sgplot data=trainTransformed;
   title 'Price vs. LogAge'
   styleattrs datasymbols= (CircleFilled);
   scatter x=logTotalBsmtSF y=logSalePrice / group=Neighborhood;
run;

proc sgplot data=trainTransformed;
   title 'Price vs. LogAge'
   styleattrs datasymbols= (CircleFilled);
   scatter x=logGarageArea y=logSalePrice / group=Neighborhood;
run;

proc sgplot data=trainTransformed;
   title 'Price vs. LogAge'
   styleattrs datasymbols= (CircleFilled);
   scatter x=logAgeReno y=logSalePrice / group=Neighborhood;
run;

proc sgplot data=trainTransformed;
   title 'Price vs. LogAge'
   styleattrs datasymbols= (CircleFilled);
   scatter x=logTotRmsAbvGrd y=logSalePrice / group=Neighborhood;
run;

/*Best model by my selection*/
proc glm data = predictmodel plots = all; 
	Class CentralAir SaleCondition Neighborhood;
	model logSalePrice = logGrLivArea logTotalBsmtSF logAgeReno CentralAir SaleCondition logGrLivArea*Neighborhood SaleCondition*logAgeReno SaleCondition*logGrLivArea/ tolerance solution ;
	output out = results predicted = Predict;
;

proc reg data = predictmodel plots = all; 
	model logSalePrice = logGrLivArea logTotalBsmtSF logAgeReno/ vif ;
	output out = results predicted = Predict;
;

proc glmselect data = predictmodel plots(stepaxis = number) = (criterionpanel ASEPlot);
	Class CentralAir SaleCondition Neighborhood; 
	model logSalePrice = logGrLivArea logTotalBsmtSF logAgeReno CentralAir SaleCondition logGrLivArea*Neighborhood SaleCondition*logAgeReno SaleCondition*logGrLivArea / selection = stepwise(select = cv choose = cv stop = cv) CVDETAILS; 
;
/*Post Selection -- Stepwise*/
proc glm data = predictmodel plots = all; 
	Class CentralAir SaleCondition Neighborhood;
	model logSalePrice = logTotalBsmtSF CentralAir logGrLivArea*Neighborhood SaleCondition*logAgeReno/ tolerance solution;
	output out = results predicted = Predict;
;

/*Best model so far using stepwise down selection. Better than my random guess above*/
proc glm data = predictmodel plots = all; 
	Class CentralAir SaleCondition Neighborhood;
	model SalePrice = Age TotalBsmtSF GarageArea AgeReno GrLivArea CentralAir SaleCondition Neighborhood*GrLivArea SaleCondition*GrLivArea SaleCondition*Age/ tolerance clparm solution;
	output out = results predicted = Predict;
;

proc sgscatter data = trainTransformed; 
	matrix logSalePrice logGrLivArea logTotalBsmtSF logAgeReno / Group = CentralAir;
run;  

proc sgscatter data = trainTransformed; 
	matrix SalePrice GrLivArea Age TotalBsmtSF GarageArea AgeReno TotRmsAbvGrd;
run; 


/*******Run when done*********/ 

data results2; 
	set results;
	Predict = exp(Predict);
run; 

data results3; 
	set results2; 
	if Predict > 0 then SalePrice = Predict; 
	if Predict < 0 then SalePrice = 10000; 
	keep Id SalePrice; 
	where Id > 1460; /*need to double check this value*/
run; 

proc export data=results3
   file='~/KaggleProject/results_if_this_no_work_me_no_happy.csv'
   dbms=csv
   replace;
run;