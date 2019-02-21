/* This code assumes that the data sets have been imported as 'test' and 'train'*/

/* Problem 1 */ 

data train1; 
	set train; 
	if upcase(Neighborhood) = "NAMES" or upcase(Neighborhood) = "EDWARDS" or upcase(Neighborhood) = "BRKSIDE"; /*select neighborhoods of interest in problem 1*/
	if Id = 1299 or Id = 524 or Id = 725 then delete; /*Gets rid of outliers for problem 1*/
	GrLivArea = round(GrLivArea,100);
	logSalePrice = log(SalePrice); /*logs for initial analysis. We don't end up using*/
	logGrLivArea = log(GrLivArea);
	keep id SalePrice GrLivArea Neighborhood logSalePrice logGrLivArea; /*keep only those things we need for problem 1*/
;

proc print data = train1; 
run; 

/*Scatterplot of untransformed data. Also used before / after outliers*/
proc sgplot data=train1;
   title 'Square Footage vs. Sale Price Grouped by Neighborhood';
   styleattrs datasymbols= (CircleFilled);
   scatter x=GrLivArea y=SalePrice / group=Neighborhood;
run;

/*Scatterplot of logged data*/
proc sgplot data=train1;
   title 'Log Square Footage vs. Log Sale Price Grouped by Neighborhood';
   styleattrs datasymbols= (CircleFilled);
   scatter x=logGrLivArea y=logSalePrice / group=Neighborhood;
run;

/*Matrix plot to look at possible fits / relationships*/
proc sgscatter data = train1; 
	matrix GrLivArea SalePrice logSalePrice logGrLivArea / Group = Neighborhood;
run;  

/*Model of data */
proc glm data = train1 plots = all; 
	Class Neighborhood(ref = "NAmes"); 
	model SalePrice = GrLivArea | Neighborhood / tolerance clparm solution;
;

/*get the CV Press*/
proc glmselect data = train1 plots(stepaxis = number) = (criterionpanel ASEPlot);
	Class Neighborhood(ref = "NAmes"); 
	model SalePrice = GrLivArea | Neighborhood / selection = stepwise(select = cv choose = cv stop = cv) CVDETAILS; 
;

/*Reject this log model*/

proc glm data = train1 plots = all; 
	Class Neighborhood(ref = "NAmes"); 
	model logSalePrice = logGrLivArea | Neighborhood / tolerance clparm solution;
;












/* Problem 2 */ 

data test; 
	set test;
	if LotConfig = 'CulDSac' then LotCode = 1; else LotCode = 0;
	logLotArea = log(LotArea);
	logGrLivArea = log(GrLivArea);
	logSalePrice = .;
;



data train2;
	set train;
	if LotConfig = 'CulDSac' then LotCode = 1; else LotCode = 0;
	logLotArea = log(LotArea);
	logGrLivArea = log(GrLivArea);
	logSalePrice = log(SalePrice);
	if Id = 1299 or Id = 524 or Id = 725 then delete;
run; 

data predictmodel; 
	set train2 test;
run; 

/*Let's look for relationships of interest*/
proc sgscatter data = train2; 
	/*matrix GrLivArea SalePrice YearRemodAdd BedroomAbvGr FullBath HalfBath logLotArea;*/
	matrix SalePrice KitchenAbvGr TotRmsAbvGrd Fireplaces GarageYrBlt GarageCars GarageArea WoodDeckSF OpenPorchSF EnclosedPorch ScreenPorch PoolArea MiscVal MoSold YrSold;
	/*MSSubClass LotArea logLotArea GrLivArea BsmtFullBath BsmtHalfBath FullBath FullBath HalfBath BedroomAbvGr KitchenAbvGr TotRmsAbvGrd Fireplaces GarageYrBlt GarageCars GarageArea WoodDeckSF HalfBath BedroomAbvGr KitchenAbvGr TotRmsAbvGrd Fireplaces GarageYrBlt GarageCars GarageArea WoodDeckSF OpenPorchSF EnclosedPorch ScreenPorch PoolArea MiscVal MoSold YrSold ;*/
run;  

/*Insert the modeling code here*/

/*This model is worse than the one with just the Neighborhood and GrLivArea in it.......AGHHHHHHH*/
proc glm data = predictmodel plots = all; 
	Class Neighborhood Fireplaces MoSold;
	model logSalePrice = logGrLivArea | TotRmsAbvGrd GarageYrBlt logLotArea  / clparm solution;
	output out = results predicted = Predict;
run;	



data results2; 
	set results; 
	if Predict > 0 then SalePrice = exp(Predict); 
	if Predict < 0 then SalePrice = 10000; 
	keep Id SalePrice; 
	where Id > 1460; /*need to double check this value*/
; 

proc export data=results2
   file='~/KaggleProject/results2.csv'
   dbms=csv
   replace;
run;