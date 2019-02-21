
data test; 
	set test;
	if LotConfig = 'CulDSac' or 'FR3' or 'FR2'  then LotCode = 1; else LotCode = 0;
	if KitchenQual = 'Ex' or 'Gd' then KitchenQualCode = 1; else KitchenQualCode = 0;
	if GarageArea > 0 then HasGarage = 1; else HasGarage = 0;
	if YearBuilt < 1936 then YearBuiltCode = 0; else YearBuiltCode = 1; 
	if FullBath > 3 then BathCode = 1; else BathCode = 0;
	LotArea = sqrt(LotArea);
	SalePrice = .;
; 

data train2;
	set train;
	if LotConfig = 'CulDSac' or 'FR3' or 'FR2'  then LotCode = 1; else LotCode = 0;
	if KitchenQual = 'Ex' or 'Gd' then KitchenQualCode = 1; else KitchenQualCode = 0;
	if GarageArea > 0 then HasGarage = 1; else HasGarage = 0;
	if YearBuilt < 1936 then YearBuiltCode = 0; else YearBuiltCode = 1; 
	if FullBath > 3 then BathCode = 1; else BathCode = 0;
	if Id = 1299 or Id = 524 or Id = 725 then delete;
	LotArea = sqrt(LotArea);
	/*SalePrice = log(SalePrice);*/
; 

data predictmodel; 
	set train2 test;
run; 
/**************set up above****************/
/* Best list */
/* Gr: Neighborhood LotConfig KitchenQualCode YearBuiltCode*/
/* GrLivArea, TotRmsAbvGrd, sqrt(LotArea), YearBuiltCode, GarageArea, LotConfig, OverallQual, LotConfig*Neighborhood, YearBuiltCode*YearBuilt, log(GarageArea)*Neighborhood, sqrt(LotArea)*Neighborhood, GrLivArea*Neighborhood*/


proc sgplot data=train2;
   /*title 'Square Footage vs. Sale Price Grouped by Neighborhood';*/
   styleattrs datasymbols= (CircleFilled);
   scatter x=LotCode y=SalePrice / group= Neighborhood;
run;
/*
proc glm data = predictmodel plots = all;
	Class Neighborhood YearBuiltCode HasGarage KitchenQualCode KitchenQual LotCode; 
	model SalePrice = GrLivArea OverallQual LotCode KitchenQualCode*KitchenQual HasGarage*GarageArea YearBuilt*YearBuiltCode/ clparm solution;
	output out = results predicted = Predict;
run;
*/

proc glm data = predictmodel plots = all; 
	/*model SalePrice = GrLivArea OverallQual GrLivArea*OverallQual; */
	Class OverallQual Neighborhood;
	model SalePrice = Neighborhood GrLivArea|OverallQual/solution;
	output out = results predicted = Predict;
run; 

proc print data = results; 
	var SalePrice Predict;
run; 

data results; 
	set results; 
	SalePrice = Predict;
run; 




/*******Run when done*********/ 

data results2; 
	set results; 
	if Predict > 0 then SalePrice = Predict; 
	if Predict < 0 then SalePrice = 10000; 
	keep Id SalePrice; 
	where Id > 1460; /*need to double check this value*/
; 

proc export data=results2
   file='~/KaggleProject/results2.csv'
   dbms=csv
   replace;
run;