/*
CODE MASTER. CALLS ALL OTHER DO FILES AND PROGRAMS. GOAL IS TO START FROM THE RAW 
DATA ALL THE WAY THROUGH RESULTS.

FIRST CREATED: OCT 2, 2019
LAST UPDATED : XX 

LAST UPDATE: XX
		BY : XX
*/
	
*global file_p = "/Users/tuk39938/Desktop/programs/team_production"
global file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production"
*global file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"

*0) Create fake data files. - Only for Austin and Atul. On the server you may instead
*	have steps to prep the raw data and create temp files to be used later;
do "$file_p\data_simulator.do"
*Creates simulated claims data files;

do "$file_p\sim_caper_business.do"
*Creates fake caper_business file;

do "$file_p\sim_army_master.do"
prog_sim_army_master 2001 2016 18 25
	*Creates simulated army personnel master file. arguments - a) beginning of sample, b) end of sample
	*c) lowest age of joining, d) highest age of joining.;

*1) Select cpt / dx codes of interest to construct analysis sample;


*2) Create volume counts by physician/team/location;
do "$file_p\volume_count.do"

*3) Create sample of index events with indicators for health outcomes and spending;
do "$file_p\episode_organize.do"

*4) Compute physician quality/utilization metrics;


*5) Test/show transfers are uncorrelated with physician observables;
do "$file_p\transfers_checks.do"
prog_check_transfers 3

*6) Run volume-outcome regressions. there will be multiple analyses steps here;

	 
*END CODE;
