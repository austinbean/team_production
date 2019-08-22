clear

* Generate some simulated data.

set seed 41

*  observation numbers
set obs 100000


* COMMENT OUT THE TWO WHICH ARE NOT YOURS TO RUN!
local file_p = "/Users/tuk39938/Desktop/programs/team_production/"
local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production"
local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"

* RENAME TO WHATEVER THE MERGE VARIABLE IS...

gen x_MERGE_VAR = string(_n)
label variable x_MERGE_VAR "MERGE ON THIS"

gen MERGE_VAR = x_MERGE_VAR 
label variable MERGE_VAR "MERGE ON THIS"

* Variables:

gen str12 PID_PDE_SPONSOR = ""  
replace PID_PDE_SPONSOR = "PDE"+char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57)) + char(runiformint(48,57))
label variable PID_PDE_SPONSOR "" 

gen str12 PID_PDE_PATIENT = ""  
replace PID_PDE_PATIENT = "PDE"+char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57)) + char(runiformint(48,57))
label variable PID_PDE_PATIENT "" 

gen str11 FLAG_DMDC_PITE_YYYYQ_SPONSOR = "NOT SPONSOR"  
label variable FLAG_DMDC_PITE_YYYYQ_SPONSOR "" 

gen str1 FLAG_DMDC_PITE_YYYYQ_SERVICE = ""  
label variable FLAG_DMDC_PITE_YYYYQ_SERVICE "always blank" 

gen double DATE_BIRTH = 0
replace DATE_BIRTH = runiformint(8300, 19600)
format DATE_BIRTH %td
label variable DATE_BIRTH "Patient DOB" 

gen str1 PAYGRADE_PDE = ""  
label variable PAYGRADE_PDE "always missing in data" 

gen str5 ZIP_PATIENT_PDE = ""  
replace ZIP_PATIENT_PDE = string(runiformint(78700,79200))
label variable ZIP_PATIENT_PDE "" 

gen str45 DMIS_PATIENT_REGISTER_NUMBER = ""  
label variable DMIS_PATIENT_REGISTER_NUMBER "" 

gen str1 ACV = ""  
label variable ACV "" 

gen str3 BENCATX = ""  
gen benr = 1000000*runiform()
replace BENCATX = "IGR" if benr >= 0 & benr < 64 
replace BENCATX = "GRD" if benr > 64 & benr < 144
replace BENCATX = "ACT" if benr > 144 & benr < 5000
replace BENCATX = "IDG" if benr > 5000 & benr < 10000
replace BENCATX = "DGR" if benr > 10000 & benr < 35000
replace BENCATX = "DA" if benr > 35000
drop benr
label variable BENCATX "" 

gen str2 DDS = ""  
label variable DDS "missing 70%" 

gen str4 DEERSENR = ""  
replace DEERSENR = "0"+string(runiformint(100,464))
label variable DEERSENR "" 

gen str1 DSPONSVC = ""  
gen dspr = runiform()
replace DSPONSVC = "A" if dspr < 0.25
replace DSPONSVC = "F" if dspr >= 0.25 & dspr < 0.5
replace DSPONSVC = "M" if dspr >= 0.5 & dspr < 0.75
replace DSPONSVC = "N" if dspr >= 0.75 & dspr < 0.9
replace DSPONSVC = "C" if dspr >= 0.9 & dspr < 0.95
replace DSPONSVC = "O" if dspr >= 0.95 & dspr < 0.99
replace DSPONSVC = "W" if dspr >= 0.99 & dspr < 1
drop dspr
label variable DSPONSVC "" 

gen double DATE_ADMISSION = 0
replace DATE_ADMISSION = runiformint(19000, 21600)
format DATE_ADMISSION %td
label variable DATE_ADMISSION "" 

gen double DATE_DISPOSITION = 0
replace DATE_DISPOSITION = DATE_ADMISSION + runiformint(1,31)
format DATE_DISPOSITION %td
label variable DATE_DISPOSITION "" 

gen double DATE_INITIAL_ADMISSION = 0
gen inadr = runiform()
replace DATE_INITIAL_ADMISSION = DATE_ADMISSION + runiformint(-5,-1) if inadr > 0.95
replace DATE_INITIAL_ADMISSION = . if inadr <= 0.95
drop inadr
format DATE_INITIAL_ADMISSION %td
label variable DATE_INITIAL_ADMISSION "" 

gen double DATE_INJURY = 0
gen dinr = runiform()
replace DATE_INJURY = DATE_ADMISSION + runiformint(-10, -1) if dinr > 0.95
replace DATE_INJURY = . if dinr <= 0.95
format DATE_INJURY %td
drop dinr
label variable DATE_INJURY "" 

gen str1 ADMSRC = ""  
gen admr = runiform()
replace ADMSRC = "0" if admr >0 & admr <=0.1
replace ADMSRC = "1" if admr >0.1 & admr <=0.6
replace ADMSRC = "L" if admr >0.6 & admr <=0.9
replace ADMSRC = "4" if admr > 0.9 & admr <= 0.91
replace ADMSRC = "5" if admr > 0.91 & admr <= 0.92
replace ADMSRC = "6" if admr > 0.92 & admr <= 0.93
replace ADMSRC = "7" if admr > 0.93 & admr <= 0.94
replace ADMSRC = "8" if admr > 0.94 & admr <= 0.05
replace ADMSRC = "S" if admr > 0.95 & admr <= 1
drop admr
label variable ADMSRC "" 

gen str1 DEATH = ""  
gen dthr = runiform()
replace DEATH = "1" if dthr > 0.95 & dthr <= 0.96
replace DEATH = "2" if dthr > 0.96 & dthr <= 0.97
replace DEATH = "3" if dthr > 0.97 & dthr <= 0.98
replace DEATH = "4" if dthr > 0.98 & dthr <= 0.995
replace DEATH = "5" if dthr > 0.995 & dthr <= 0.995
replace DEATH = "6" if dthr > 0.996 & dthr <= 0.997
replace DEATH = "7" if dthr > 0.997 & dthr <= 0.998
replace DEATH = "8" if dthr > 0.998 & dthr <= 1 
drop dthr
label variable DEATH "" 

* This is a list of 96 frequent ICD-9 Diagnosis codes from TX.  They are sampled uniformly.
	*  word( [LIST], ceil( Length(LIST)*runiform() ))) -> chooses random "word" from list
local icds = "V053 V3000 9955 V3001 640 7746 V290 7661 9983 V7219 V502 76528 7742 77989 7706 76519 77089 77931 769 76529 76518 9604 9915 V3101 605 9390 77181 76527 7756 3892 77081 3891 76719 7750 7455 7731 9671 7766 7470 7852 V6405 76621 75733 V298 7755 9929 7788 V293 0331 77984 77981 7784 76526 76517 7726 7761 76408 79415 9672 53081 77581 76516 76384 7702 7754 7732 77933 7454 2761 7786 9541 V3100 V773 76525 79099 6910 8872 78321 7500 7625 76515 4589 V0482 76409 77083 75251 76079 7783 76514 76524 75329 2760 9982 74689 75732 75261"
local length = 96

local poa_cl = "E N U W Y"
local poa_length = 5

gen str7 ADMDX = "" 
replace ADMDX = word( "`icds'" , ceil(`length'*runiform())) 
label variable ADMDX "" 

gen str8 DX1 = "" 
replace DX1 =  word( "`icds'" , ceil(`length'*runiform())) 
label variable DX1 "" 



gen str8 DX2 = ""  
replace DX2 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx2r = runiform()
replace DX2 = "" if dx2r > 0.9 | DX1 == ""
drop dx2r
label variable DX2 "" 

gen str8 DX3 = ""  
replace DX3 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx3r = runiform()
replace DX3 = "" if dx3r > 0.7 | DX1== "" | DX2 == "" 
drop dx3r
label variable DX3 "" 

gen str8 DX4 = "" 
replace DX4 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx4r = runiform()
replace DX4 = "" if dx4r > 0.5 | DX1== "" | DX2 == "" | DX3 == ""
drop dx4r 
label variable DX4 "" 

gen str8 DX5 = ""  
replace DX5 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx5r = runiform()
replace DX5 = "" if dx5r > 0.3 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == ""
drop dx5r
label variable DX5 "" 

gen str8 DX6 = "" 
replace DX6 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx6r = runiform()
replace DX6 = "" if dx6r > 0.2 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == ""
drop dx6r 
label variable DX6 "" 

gen str8 DX7 = ""  
replace DX7 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx7r = runiform()
replace DX7 = "" if dx7r > 0.1 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == ""
drop dx7r
label variable DX7 "" 

gen str8 DX8 = ""  
replace DX8 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx8r = runiform()
replace DX8 = "" if dx8r > 0.05 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == ""
drop dx8r
label variable DX8 "" 

gen str8 DX9 = "" 
replace DX9 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx9r = runiform()
replace DX9 = "" if dx9r > 0.07 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == ""
drop dx9r 
label variable DX9 "" 

gen str8 DX10 = ""
replace DX10 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx10r = runiform()
replace DX10 = "" if dx10r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == ""
drop dx10r  
label variable DX10 "" 

gen str8 DX11 = ""  
replace DX11 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx11r = runiform()
replace DX11 = "" if dx11r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == ""
drop dx11r  
label variable DX11 "" 

gen str8 DX12 = ""
replace DX12 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx12r = runiform()
replace DX12 = "" if dx12r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == ""
drop dx12r    
label variable DX12 "" 

gen str8 DX13 = ""
replace DX13 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx13r = runiform()
replace DX13 = "" if dx13r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == ""
drop dx13r    
label variable DX13 "" 

gen str8 DX14 = ""  
replace DX14 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx14r = runiform()
replace DX14 = "" if dx14r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == ""
drop dx14r  
label variable DX14 "" 

gen str8 DX15 = ""  
replace DX15 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx15r = runiform()
replace DX15 = "" if dx15r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == "" | DX14 == ""
drop dx15r  
label variable DX15 "" 

gen str8 DX16 = "" 
replace DX16 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx16r = runiform()
replace DX16 = "" if dx16r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == "" | DX14 == "" | DX15 == ""
drop dx16r   
label variable DX16 "" 

gen str8 DX17 = ""
replace DX17 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx17r = runiform()
replace DX17 = "" if dx17r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == "" | DX14 == "" | DX15 == "" | DX16 == ""
drop dx17r    
label variable DX17 "" 

gen str8 DX18 = "" 
replace DX18 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx18r = runiform()
replace DX18 = "" if dx18r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == "" | DX14 == "" | DX15 == "" | DX16 == "" | DX17 == ""
drop dx18r   
label variable DX18 "" 

gen str7 DX19 = ""
replace DX19 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx19r = runiform()
replace DX19 = "" if dx19r > 0.09  | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == "" | DX14 == "" | DX15 == "" | DX16 == "" | DX17 == "" | DX18 == ""
drop dx19r    
label variable DX19 "" 

gen str7 DX20 = ""  
replace DX20 =  word( "`icds'" , ceil(`length'*runiform())) 
gen dx20r = runiform()
replace DX20 = "" if dx20r > 0.09 | DX1== "" | DX2 == "" | DX3 == "" | DX4 == "" | DX5 == "" | DX6 == "" | DX7 == "" | DX8 == "" | DX9 == "" | DX10 == "" | DX11 == "" | DX12 == "" | DX13 == "" | DX14 == "" | DX15 == "" | DX16 == "" | DX17 == "" | DX18 == "" | DX19 == ""
drop dx20r  
label variable DX20 "" 

* Present on arrival

foreach nxi of numlist 1(1)20{

local dxi = "DX`nxi'"

gen str1 `dxi'POA = ""
gen `dxi'prb = runiform()
replace `dxi'POA = "Y" if `dxi'prb >= 0 & `dxi'prb < 0.6 
replace `dxi'POA = "E" if `dxi'prb >= 0.6 & `dxi'prb < 0.9
replace `dxi'POA = "N" if `dxi'prb >= 0.9 & `dxi'prb < 0.99
replace `dxi'POA = "U" if `dxi'prb >= 0.995 & `dxi'prb < 0.999
replace `dxi'POA = "W" if `dxi'prb > 0.999
replace `dxi'POA = "" if `dxi' == ""
drop `dxi'prb

}

* Do these simultaneously: PROC_X, PROCLOC_X, PROCQTY_X, DATE_STARTPROC_X, DATE_STOPPROC_X
local proclist = "9955 640 9547 9983 9604 9915 9390 3892 3891 9546 9671 9929 3893 9904 0331 9672 9541 331 8872 9982 9396 9543 9635 9905 966 9907 9399 2591 3885 8776 3404 8626 9914 3897 3491 3142 4319 9960 9959 9393 4562 17 9939 9607 8891 5471 2592 9952 9921 9339 4651 8965 4467 4620 8915 5310 3323 5459 3961 9605 8939 5491 1424 3898 4719 8659 3894 0234 2911 4466 4610 8605 5349 4824 1829 4639 9953 0017 3728 8919 3409 390 9901 4591 8914 9981 5711 5495 8961 8604 9633 863 3899 5411 5493 9749 0352 3322 4311 2309 9670 4709 6493 9391 12 5421 9909 5312 102 3723 3998 4573 5300 3173 0222 5498 8749 9394 8875 6491 4621 5794 8607 433 8628 370 5419 4679 625 234 4601 3571 4579 5425 5302 9789 8871 3834 4611 9509 3963 5463 222 3542 3479 0102 3541 0221 8897 8938 9962 544 8611 8842 4652 0309 8401 9741 4533 4285 2121 6441 109 9906 5717 9702 8601 3393 9503 8761 8879 8777 9329 9627 4593 5012 9354 9963 8321 5462 5412 5372 9357 3584 8701 9383 623 9739 1621 3562 8893 8950 8762 9969 8843 242 5011 3592 8841 8764"
local proclength = 200

*PROC1 PROCLOC1 PROCQTY1 DATE_STARTPROC1 DATE_STOPPROC1

gen PROC1 = word("`proclist'", ceil(200*runiform()))
gen prcr1 = runiform()
replace PROC1 = "" if prcr > 0.8
drop prcr1  
gen PROCLOC1 = ""
gen prlcr1 = runiform()
replace PROCLOC1 = "" if prlcr1 > 0.2 & prlcr1 < 1
replace PROCLOC1 = "D" if prlcr1 > 0.005 & prlcr1 < 0.2
replace PROCLOC1 = "J" if prlcr1 > 0.004 & prlcr1 < 0.005
replace PROCLOC1 = "R" if prlcr1 > 0.003 & prlcr1 < 0.004
replace PROCLOC1 = "T" if prlcr1 > 0.0 & prlcr1 < 0.003
replace PROCLOC1 = "" if PROC1 == ""
drop prlcr1
gen PROCQTY1 = ""
gen prqr1 = runiform()
replace PROCQTY1 = "1" if prqr1 >= 0 & prqr1 < 0.8
replace PROCQTY1 = "2" if prqr1 >= 0.8 & prqr1 <0.9
replace PROCQTY1 = "3" if prqr1 >= 0.91 & prqr1 < 0.92
replace PROCQTY1 = "4" if prqr1 >= 0.92 & prqr1 < 0.93
replace PROCQTY1 = "5" if prqr1 >= 0.93 & prqr1 < 0.94
replace PROCQTY1 = "6" if prqr1 >= 0.94 & prqr1 < 0.95
replace PROCQTY1 = "7" if prqr1 >= 0.95 & prqr1 < 0.96
replace PROCQTY1 = "8" if prqr1 >= 0.96 & prqr1 < 0.97
replace PROCQTY1 = "9" if prqr1 >= 0.97 & prqr1 <= 1
replace PROCQTY1 = "" if PROC1 == ""
drop prqr1
* dates 
gen DATE_STARTPROC1 = DATE_ADMISSION + runiformint(0,3)
format DATE_STARTPROC1 %td
replace DATE_STARTPROC1 = . if PROC1 == ""
gen DATE_STOPPROC1 = DATE_STARTPROC1 + runiformint(0,3)
format DATE_STOPPROC1 %td
replace DATE_STOPPROC1 = . if PROC1 == ""

foreach nm of numlist 2(1)20{
	* previous procedure
	local prev = `nm'-1
	* current procedure
	gen PROC`nm' = word("`proclist'", ceil(200*runiform()))
	gen prcr`nm' = runiform()
	replace PROC`nm' = "" if prcr`nm' < ( (`nm'-1)/20 ) | PROC`prev' == ""
	drop prcr`nm'
	* location
	gen PROCLOC`nm' = ""
	gen prlcr`nm' = runiform()
	replace PROCLOC`nm' = "" if prlcr`nm' > 0.2 & prlcr`nm' <= 1
	replace PROCLOC`nm' = "D" if prlcr`nm' > 0.005 & prlcr`nm' < 0.2
	replace PROCLOC`nm' = "J" if prlcr`nm' > 0.004 & prlcr`nm' < 0.005
	replace PROCLOC`nm' = "R" if prlcr`nm' > 0.003 & prlcr`nm' < 0.004
	replace PROCLOC`nm' = "T" if prlcr`nm' > 0.0 & prlcr`nm' < 0.003
	replace PROCLOC`nm' = "" if PROC`nm' == ""
	drop prlcr`nm'
	* quantity
	gen PROCQTY`nm' = ""
	gen prqr`nm' = runiform()
	replace PROCQTY`nm' = "1" if prqr`nm' >=0 & prqr`nm' < 0.8
	replace PROCQTY`nm' = "2" if prqr`nm' >= 0.8 & prqr`nm' < 0.9
	replace PROCQTY`nm' = "3" if prqr`nm' >= 0.91 & prqr`nm' < 0.91
	replace PROCQTY`nm' = "4" if prqr`nm' >= 0.92 & prqr`nm' < 0.93
	replace PROCQTY`nm' = "5" if prqr`nm' >= 0.93 & prqr`nm' < 0.94
	replace PROCQTY`nm' = "6" if prqr`nm' >= 0.94 & prqr`nm' < 0.95
	replace PROCQTY`nm' = "7" if prqr`nm' >= 0.95 & prqr`nm' < 0.96
	replace PROCQTY`nm' = "8" if prqr`nm' >= 0.96 & prqr`nm' < 0.97
	replace PROCQTY`nm' = "9" if prqr`nm' >= 0.97 & prqr`nm' <=1
	replace PROCQTY`nm' = "" if PROC`nm' == ""
	drop prqr`nm'
	* dates
	gen DATE_STARTPROC`nm' = DATE_ADMISSION + runiformint(0,3)
	format DATE_STARTPROC`nm' %td
	replace DATE_STARTPROC`nm' = . if PROC`nm' == ""
	replace DATE_STARTPROC`nm' = . if DATE_DISPOSITION != . & DATE_DISPOSITION < DATE_STARTPROC`nm'
	gen DATE_STOPPROC`nm' = DATE_STARTPROC`nm' + runiformint(0,3)
	format DATE_STOPPROC`nm' %td
	replace DATE_STOPPROC`nm' = . if PROC1 == ""
	replace DATE_STOPPROC`nm' = . if DATE_STARTPROC`nm' == .
}




* OTHER

gen str4 MTF = ""  
replace MTF = "0"+string(runiformint(100,172))
label variable MTF "" 

gen str6 MTFFROM = ""  
label variable MTFFROM "nearly always missing" 

gen str6 MTFINIT = ""  
label variable MTFINIT "nearly always missing" 

gen str1 MTFSVC = ""  
gen mtfr = runiform()
replace MTFSVC = "A" if mtfr > 0 & mtfr <= 0.5
replace MTFSVC = "B" if mtfr > 0.5 & mtfr <= 0.51
replace MTFSVC = "D" if mtfr > 0.51 & mtfr <= 0.511
replace MTFSVC = "F" if mtfr > 0.511 & mtfr <= 0.7
replace MTFSVC = "N" if mtfr > 0.7 & mtfr <= 0.9
replace MTFSVC = "P" if mtfr > 0.9 & mtfr <= 0.98
replace MTFSVC = "R" if mtfr > 0.98 & mtfr <= 1
drop mtfr
label variable MTFSVC "" 

gen str6 MTFTO = ""  
label variable MTFTO "nearly always missing" 

gen double BASSDAYS = 0
gen bsr = runiform()
replace BASSDAYS = 1 if bsr > 0.9 & bsr <= 0.95
replace BASSDAYS = 2 if bsr > 0.95 & bsr <= 0.99
replace BASSDAYS = runiformint(3,95) if bsr > 0.99
drop bsr
label variable BASSDAYS "" 

gen double BDAYS1 = 0
gen bdyr = runiform()
replace BDAYS1 = 1 if bdyr > 0.5 & bdyr <= 0.8
replace BDAYS1 = 2 if bdyr > 0.8 & bdyr <= 0.9
replace BDAYS1 = runiformint(3,369) if bdyr > 0.9
drop bdyr
label variable BDAYS1 "" 

gen double BEDCIV = 0
replace BEDCIV = 3 if _n == 1
label variable BEDCIV "always 0 except for 1 entry" 

gen double BEDOTHER = 0
label variable BEDOTHER "always 0" 

	* DRG out of order, see below.  

gen str1 DRGICAT = "" 
gen drgir = runiform()
replace DRGICAT = "1" if drgir >= 0.44 & drgir < 0.98
replace DRGICAT = "2" if drgir >= 0.98 & drgir < 0.99
replace DRGICAT = "3" if drgir >= 0.99 & drgir < 0.995
replace DRGICAT = "4" if drgir >= 0.995 & drgir <= 1
drop drgir 
label variable DRGICAT "" 

	* next two vars match except some of DRG are set missing
gen str3 MSDRG = ""  
replace MSDRG = string(runiformint(100, 999)) 
label variable MSDRG "" 

gen str3 DRG = "" 
replace DRG = MSDRG 
gen drgr = runiform()
replace DRG = "" if drgr < 0.44
drop drgr
label variable DRG "" 

gen double MSDRGBASERWP = 0
gen msdr = runiform()
replace MSDRGBASERWP = 0 if msdr < 0.75 
replace MSDRGBASERWP = 1 if msdr >= 0.75 & msdr < 0.98
replace MSDRGBASERWP = runiformint(2,31) if msdr > 0.98
drop msdr 
label variable MSDRGBASERWP "" 

gen double MSDRGFULLRWP = 0
label variable MSDRGFULLRWP "always 0" 

gen str1 MSDRGICAT = ""  
gen msdrir = runiform()
replace MSDRGICAT = "1" if msdrir < 0.98
replace MSDRGICAT = string(runiformint(2,4)) if msdrir >= 0.98
drop msdrir 
label variable MSDRGICAT "" 

gen double MSDRGOUTRWP = 0
gen msgr = runiform()
replace MSDRGOUTRWP = runiformint(-29, 70) if msgr > 0.99
drop msgr 
label variable MSDRGOUTRWP "" 

gen double MSDRGPROFRWP = 0
gen msdrgr = runiform()
replace MSDRGPROFRWP = . if msdrgr > 0.999
drop msdrgr 
label variable MSDRGPROFRWP "" 

gen str1 MSDRGSURG = ""  
gen msrgr = runiform()
replace MSDRGSURG = "M" if msrgr < 0.9
replace MSDRGSURG = "S" if msrgr >= 0.9
drop msrgr 
label variable MSDRGSURG "" 

gen str2 PRODLINE = ""  
gen prdr = runiform()
replace PRODLINE = "OB" if prdr > 0 & prdr <= 0.82
replace PRODLINE = "M" if prdr > 0.82 & prdr <= 0.95
replace PRODLINE = "MH" if prdr > 0.95 & prdr <= 0.99
replace PRODLINE = "S" if prdr > 0.99
drop prdr 
label variable PRODLINE "" 

gen str4 COSTPRNT = ""  
replace COSTPRNT = "00"+string(runiformint(30, 96))
label variable COSTPRNT "" 

gen double PPS_EF = 1
label variable PPS_EF "always 1" 

gen str4 PPS_EPS = ""  
replace PPS_EPS = "0"+string(runiformint(100,271))
label variable PPS_EPS "" 

gen str1 PPS_RB = ""  
gen rbr = runiform()
replace PPS_RB = "R" if rbr < 0.99
replace PPS_RB = "D" if rbr >= 0.99
drop rbr 
label variable PPS_RB "" 

gen str4 PPS_TPS = ""  
gen tpsr = runiform()
replace PPS_TPS = "0"+string(runiformint(100,162))
drop tpsr 
label variable PPS_TPS "" 

gen double PRICE = 0
replace PRICE = abs(floor(7595 + 13404*rnormal(0,1)))
label variable PRICE "" 

gen double DATE_FILE = 1
label variable DATE_FILE "takes one value" 

gen str8 TYPE_FILE = "TRANSACT"  
label variable TYPE_FILE "takes one value" 

gen str24 SOURCE_PROJECT = ""  
label variable SOURCE_PROJECT "DSA14_1162_MHS_AAG_NOEXP" 

gen str12 SOURCE_FILE = ""  
label variable SOURCE_FILE "MHS_MDR_SIDR" 

gen str22 SOURCE_TABLE = "" 
gen star = runiform()
replace SOURCE_TABLE = "MDR_SIDR_DOD_2004_2010" if star < 0.43
replace SOURCE_TABLE = "MDR_SIDR_DOD_2011_2017" if star >= 0.43
drop star 
label variable SOURCE_TABLE "" 


* Make some patients appear more than once.

gen repeatr = runiform()
	replace PID_PDE_PATIENT = PID_PDE_PATIENT[_n-1] if repeatr > 0.7
	bysort PID_PDE_PATIENT: gen ctr = _n 
	replace PID_PDE_PATIENT = PID_PDE_PATIENT[_n-1] if ctr[_n-1] == 2
	
	replace PID_PDE_PATIENT = PID_PDE_PATIENT[_n-1] if repeatr < 0.7 & repeatr > 0.6
	drop ctr repeatr
	


* ADDING THE SECOND FILE  
	* direct link: https://github.com/austinbean/team_production/blob/d41689429cd61450366e2d4d509bc8d872370357/codebook.log#L3067
	* this will generate from the first file so that the merging process is sensible
	* all vars in section have x_ prepended to name to keep later

gen x_pid_pde_patient = PID_PDE_PATIENT

gen x_pid_pde_sponsor = PID_PDE_SPONSOR

gen x_flag_dmdc_pite_yyyyq_sponsor = FLAG_DMDC_PITE_YYYYQ_SERVICE

gen x_flag_dmdc_pite_yyyyq_service = FLAG_DMDC_PITE_YYYYQ_SERVICE

gen x_date_birth_pde = DATE_BIRTH

gen x_patient_zip_pde = ZIP_PATIENT_PDE

gen x_encounter_key = char(runiformint(65,90)) + char(runiformint(48,57))

gen x_apptidno= char(runiformint(65,90)) + char(runiformint(48,57))

gen x_pat_sex = ""
gen psr = runiform()
replace x_pat_sex = "F" if psr < 0.26
replace x_pat_sex = "M" if psr >= 0.26
drop psr

gen x_admdisp = ""
gen admr = runiform()
replace x_admdisp = char(runiformint(65,70)) + char(runiformint(74,75)) if admr > 0.93
drop admr
 
gen x_asc1 = ""
label variable x_asc1 "always missing"

gen x_asc2 = ""
gen ascr = runiform()
replace x_asc2 = char(runiformint(48,57)) if ascr > 0.999
drop ascr 

gen x_asc3 = ""
label variable x_asc3 "always missing"

gen x_asc4 = ""
gen ascr = runiform()
replace x_asc4 = char(runiformint(48,57)) + char(runiformint(65,67)) if ascr > 0.993
drop ascr 

gen x_asc5 = ""
gen ascr = runiform()
replace x_asc5 = char(runiformint(48,57))+char(runiformint(65,66)) if ascr > 0.998
drop ascr 

gen x_asc6 = ""
gen ascr = runiform()
replace x_asc6 = char(runiformint(48,57))+char(runiformint(65,66)) if ascr > 0.995
drop ascr 

gen x_asc7 = ""
gen ascr = runiform()
replace x_asc7 = char(runiformint(48,57)) + char(runiformint(65,66)) if ascr > 0.9998
drop ascr 

gen x_asc8 = ""
gen ascr = runiform()
replace x_asc8 = char(runiformint(48,57)) if ascr > 0.9999
drop ascr 

gen x_asc9 = ""
gen ascr = runiform()
replace x_asc9 = char(runiformint(48,53)) if ascr > 0.9999
drop ascr 

gen x_asc10 = ""
gen ascr = runiform()
replace x_asc10 = char(runiformint(48,53)) if ascr > 0.9999
drop ascr 

gen x_asc11 = ""
gen ascr = runiform()
replace x_asc11 = char(runiformint(48,51)) if ascr > 0.99999
drop ascr 

gen x_asc12 = ""
gen ascr = runiform()
replace x_asc12 = char(runiformint(48,49)) if ascr > 0.99999
drop ascr 

gen x_asc13 = ""
gen ascr = runiform()
replace x_asc13 = char(runiformint(48,48)) if ascr > 0.99999
drop ascr 

	* also an ICD-9 from the above list of 200
gen complaint = word("`proclist'", ceil(200*runiform()))


* Random CPT from a list of 175
local cptlist = "43640 43641 43644 43645 43770 43771 43772 43773 43774 43775 43800 43810 43820 43825 43840 43842 43843 43845 43846 43847 43848 43850 43855 43860 43865 43870 43880 43886 43887 43888 43286 43287 43288 11008 49491 49492 49495 49496 49500 49501 49505 49507 49520 49521 49525 49550 49553 49555 49557 49560 49561 49565 49566 49570 49572 49580 49582 49585 49587 49590 49600 49605 49606 49610 49611 49650 49651 49652 49653 49654 49655 49656 49657 49659 27125 27130 27132 27134 27137 27138 27236 33935 33945 58150 58152 58180 58200 58210 58240 58541 58542 58543 58544 58548 58550 58552 58553 58554 58570 58571 58572 58573 58951 58953 58954 58956 59525 58575 27438 27440 27441 27442 27443 27445 27446 27447 27486 27487 50340 50360 50365 50380 22220 22222 22224 22856 22857 22861 22862 22867 62287 62351 62380 63001 63003 63005 63011 63012 63015 63016 63017 63020 63030 63035 63040 63042 63045 63046 63047 63048 63050 63051 63055 63056 63064 63075 63077 63081 63082 63085 63086 63087 63088 63090 63091 63101 63102 63103 63170 63172 63173 63180 63182 63185 63190"
local cptlength = 175

	* There are 13 cpt and cpt_dx codes
gen x_cpt_1 = word("`cptlist'", ceil(`cptlength'*runiform()))
gen prcr1 = runiform()
replace x_cpt_1 = "" if prcr1 > 0.8
drop prcr1  
gen x_cptdx_1 = ""
gen prlcr1 = runiform()
replace x_cptdx_1 = "" if prlcr1 > 0.2 & prlcr1 < 1
replace x_cptdx_1 = "1" if prlcr1 > 0.005 & prlcr1 < 0.2
replace x_cptdx_1 = "12" if prlcr1 > 0.004 & prlcr1 < 0.005
replace x_cptdx_1 = "123" if prlcr1 > 0.003 & prlcr1 < 0.004
replace x_cptdx_1 = "23" if prlcr1 > 0.0 & prlcr1 < 0.003
replace x_cptdx_1 = "" if x_cpt_1 == ""
drop prlcr1

foreach nm of numlist 2(1)13{
	* previous 
	local prev = `nm'-1
	* current 
	gen x_cpt_`nm' = word("`cptlist'", ceil(`cptlength'*runiform()))
	gen prcr`nm' = runiform()
	replace x_cpt_`nm' = "" if prcr`nm' < ( (`nm'-1)/13 ) | x_cpt_`prev' == "" 
	drop prcr`nm'
	* location
	gen x_cptdx_`nm' = ""
	gen prlcr`nm' = runiform()
	replace x_cptdx_`nm' = "" if prlcr`nm' > 0.2 & prlcr`nm' <= 1
	replace x_cptdx_`nm' = "1" if prlcr`nm' > 0.005 & prlcr`nm' < 0.2
	replace x_cptdx_`nm' = "12" if prlcr`nm' > 0.004 & prlcr`nm' < 0.005
	replace x_cptdx_`nm' = "123" if prlcr`nm' > 0.003 & prlcr`nm' < 0.004
	replace x_cptdx_`nm' = "23" if prlcr`nm' > 0.0 & prlcr`nm' < 0.003
	replace x_cptdx_`nm' = "" if x_cpt_`nm' == ""
	drop prlcr`nm'

}

gen x_dipscode = char(runiformint(65,84))

* DIAGNOSES
	* treat dx1 in this as admitting_diag in the previous.
	* Others are numbered off by one: dx_n = DX_(N+1) above

gen x_dx1 = ADMDX
foreach nm of numlist 2(1)10{
	local prev = `nm'-1
	gen x_dx`nm' = DX`prev'
}

gen x_dxgrp = char(runiformint(1,20))
replace x_dxgrp = "" if _n < 20

gen x_MDC = char(runiformint(1,26))
gen mdcr = runiform()
replace x_MDC = "" if mdcr > 0.95
drop mdcr

gen x_encdate = DATE_ADMISSION

gen x_apptstat = ""
gen apsr = runiform()
replace x_apptstat = "2" if apsr < 0.5
replace x_apptstat = "5" if apsr >= 0.5 & apsr < 0.8
replace x_apptstat = "7" if apsr >= 0.8 & apsr < 0.95
replace x_apptstat = "6" if apsr > 0.95
drop apsr 

gen x_apptstat1 = x_apptstat
label variable x_apptstat1 "ident to apptstat by construction"

gen x_appttype = ""
gen aptr = runiform()
replace x_appttype = "EST" if aptr < 0.5
replace x_appttype = "FTR$" if aptr >= 0.5 & aptr < 0.8
replace x_appttype = "ROUT" if aptr >= 0.8 & aptr < 0.95
replace x_appttype = "T-CON" if aptr > 0.95
drop aptr

gen x_dmisid = "0"+string(runiformint(100,550))

gen x_hospstat = "0"
gen hsr = runiform() 
replace x_hospstat = "1" if hsr > 0.95
drop hsr 

gen x_mepr3 = "B" + char(runiformint(65,90)) + char(runiformint(65,90))

gen x_meprscd = "B" + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90))

gen x_mtf_par = "0" + string(runiformint(100, 260))

gen x_mtr_prn = ""
label variable x_mtr_prn "nearly always missing - values unknown"

gen x_pcmnpi = char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57))

gen x_provdmisref = ""
gen pmr = runiform()
replace x_provdmisref = "0" + string(runiformint(100,500))
drop pmr

foreach nm of numlist 1(1)3{
	gen x_provhipaa`nm' = ""
	gen phr = runiform()
	replace x_provhipaa`nm' = string(runiformint(100,200))+"0000X" if phr > 0.75
	drop phr 
}

* NPI refs 2 and 3 take from NPI 1 so there will be overlap in the set of providers.

gen x_provnpi1 = string(runiformint(1000,1300)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57))

gen x_provnpi2 = ""
gen prr = runiform()
replace x_provnpi2 = x_provnpi1[_n-5] if prr > 0.85
drop prr

gen x_provnpi3 = ""
gen prr = runiform()
replace x_provnpi3 = x_provnpi1[_n+3] if prr > 0.98
drop prr

gen x_provnpiref = char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57))

gen x_provspec1 = string(runiformint(100, 300))

gen x_provspec2 = string(runiformint(100, 300))
gen psr = runiform()
replace x_provspec2 = "" if psr > 0.76
drop psr

gen x_provspec3 = string(runiformint(100, 300))
gen psr = runiform()
replace x_provspec3 = "" if psr > 0.97
drop psr


gen x_provstat1 = char(runiformint(65,66)) + char(runiformint(65,67)) + char(runiformint(65,75))
gen pvr = runiform()
replace x_provstat1 = "" if pvr < 0.37
drop pvr

gen x_provstat2 = char(runiformint(65,66)) + char(runiformint(65,67)) + char(runiformint(65,75))
gen pvr = runiform()
replace x_provstat2 = "" if pvr < 0.37
drop pvr

gen x_provstat3 = char(runiformint(65,66)) + char(runiformint(65,67)) + char(runiformint(65,75))
gen pvr = runiform()
replace x_provstat3 = "" if pvr < 0.98
drop pvr

gen x_refnum = string(runiformint(100000,200000))
gen rr = runiform()
replace x_refnum = "" if rr > 0.47
drop rr

gen x_id = string(runiformint(1000000,2000000))




* Split the two datasets and save 

preserve 

keep x_*

rename x_* *

save "`file_p'fake_dep_4.dta", replace 

restore

drop x_* 

save "`file_p'fake_SIDR_DOD_Dep.dta", replace

clear 


