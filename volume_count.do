* volume_count.do
	
local file_p = "/Users/austinbean/Desktop/programs/team_production/"
*local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production"
*local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"

	* 
use "`file_p'fake_dep_4.dta", clear
 
 
merge 1:1 MERGE_VAR using "`file_p'fake_SIDR_DOD_Dep.dta"

* "unique episode" -> kind of
	gen episode_id = _n


* keep diagnoses, procedure, drg, count those by NPI month.

	gen adm_month = month(DATE_ADMISSION)
	gen adm_year = year(DATE_ADMISSION)
	
* sort by NPI -> need multiple records for each one.
* renumber consecutively
	replace provnpi2 = provnpi3 if provnpi2 == "" & provnpi3 != ""

	reshape long provnpi, i(episode_id) j(ctr)
	* no duplicate providers within one episode.
	duplicates drop provnpi episode_id, force
	
	drop if provnpi == ""

	sort provnpi adm_year adm_month

	* count DRG's, CPT's, DIAG_CODES
	
	bysort provnpi adm_year adm_month :
