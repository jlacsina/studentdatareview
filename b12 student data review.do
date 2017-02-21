********************************************************************************
log using "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\log_bp_finaid_$S_DATE.log"
/* The purpose of this do file is to clean and review student level data from Beyond 12
for AY16-17

Each grantee will have 2 files associated with them:
The first file covers a review of all non-financial aid fields. There is a different do file to review this set of data.
The second file covers all financial aid fields. This do file reviews this set of data.

The unique list of students identified in the first file are used to identify the students of interest in the second file.
The second file is long and has a record for each student per financial aid source listed.
All students with a Costs and Contributions Record (the module in Beyond 12 that stores financial aid data per AY) for AY16-17 will have data in the second file.
Since we are only interested in reviewing records that have a College Futures/Community Foundation Scholarship, the first file is merged to
the second file to eliminate records without our scholarships of interest.

*/

//Set the working directory where all files will be stored
cd "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\Bright Prospect"

//Pull in the first file with non-financial aid related data. Remove all duplicates and keep to merge with financial aid data set.
insheet using "bp_02212017.csv"
egen fullname= concat(firstname lastname), punct(" ")
duplicates drop contactid18char, force
keep fullname contactid18char

cd "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\Bright Prospect\Temp"
save "bp_scholars", replace

clear
set more off

//Pull in the financial aid dataset and merge with the previous unique list of scholars.
cd "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\Bright Prospect"
insheet using "bp_finaid_02212017.csv"

merge m:1 contactid18char using "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\Bright Prospect\Temp\bp_scholars.dta"
drop if _merge==1
drop _merge

cd "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\Bright Prospect\Temp"
keep contactid18char collegefutureshsweightedgpa collegeuniversityattendingaccoun originofefc expectedfamilycontribution grantonhold aidsource aidsourceother aidamountaccepted fullname
save "bp_finaid_forreview", replace

********************************************************************************
/* JL Notes:
1. Do you still check aidsourceother even if they have an aidsource listed to see what's in the field? It may be useful to know. 
2. Do you look at aidamountawarded to identify what the descrepancies are - if any - between the two fields?
*/

//This tabulation is meant to check that there are not values in Aid Source Other that should be listed as an Aid Source

tab aidsourceother if missing(aidsource)

//This tabulation checks to see if a College Futures/Community Foundation Scholarship was listed without Aid Amount Accepted

count if aidsource=="College Futures Scholarship" & missing(aidamountaccepted)
count if aidsource=="Community Foundation Scholarship" & missing(aidamountaccepted)


********************************************************************************
/* JL Notes:


*/


//Cal Grant - check to see who is eligible and who had one listed or not

// Standardize all forms of Cal Grants into a single value
replace aidsource="Cal Grant" if (aidsource=="Cal Grant A" | aidsource=="Cal Grant B Fee Award" | aidsource=="Cal Grant B Stipend")
// create a dataset with a single set of IDs for each record with a Cal Grant; Create a flag for each record to signify a Cal Grant Recipient
keep if aidsource=="Cal Grant"
duplicates drop contactid18char, force
gen calgrantrecipient="Cal Grant Recipient"
keep contactid18char calgrantrecipient fullname
save "calgrantrecipients", replace

// Merge with the original dataset
merge 1:m contactid18char using "bp_finaid_forreview"

// If not missing Cal Grant & meet eligibility estimations
distinct contactid18char if (originofefc=="FAFSA" | originofefc=="Dream Act") & !missing(calgrantrecipient) & ((expectedfamilycontribution<10000 & collegefutureshsweightedgpa>=3) | (expectedfamilycontribution<=5234 & collegefutureshsweightedgpa>=2)) & !missing(collegefutureshsweightedgpa)

// If missing Cal Grant & meet eligibility requirements
distinct contactid18char if (originofefc=="FAFSA" | originofefc=="Dream Act") & missing(calgrantrecipient) & ((expectedfamilycontribution<10000 & collegefutureshsweightedgpa>=3) | (expectedfamilycontribution<=5234 & collegefutureshsweightedgpa>=2)) & !missing(collegefutureshsweightedgpa)

//Create an error list of scholars missing a Cal Grant that appear eligible
keep if (originofefc=="FAFSA" | originofefc=="Dream Act") & missing(calgrantrecipient) & ((expectedfamilycontribution<10000 & collegefutureshsweightedgpa>=3) | (expectedfamilycontribution<=5234 & collegefutureshsweightedgpa>=2)) & !missing(collegefutureshsweightedgpa)

// Manually review PSI Names and drop those not from California
tab collegeuniversityattendingaccoun, mi
drop if collegeuniversityattendingaccoun=="Ball State Univ" | collegeuniversityattendingaccoun=="Princeton Univ" | collegeuniversityattendingaccoun=="Southern Oregon Univ" | collegeuniversityattendingaccoun=="Eastern Oregon Univ"

// Consolidate list and export
duplicates drop contactid18char, force
gen error = "Eligible for Cal Grant and did not have one listed"
keep fullname error
save "error_missingcalgrant.dta", replace

clear
set more off
********************************************************************************
//Pell Grant - check to see who is eligible and who had one listed or not
use "bp_finaid_forreview"

keep if aidsource=="Pell Grant"
duplicates drop contactid18char, force
gen pellrecipient="Pell Grant Recipient"
keep contactid18char pellrecipient fullname
save "pellrecipients", replace

// Merge with the original dataset
merge 1:m contactid18char using "firstgrad_finaid_forreview"

// If missing Pell Grant & meet eligibility requirements
distinct contactid18char if originofefc=="FAFSA" & expectedfamilycontribution<=5234 & !missing(expectedfamilycontribution) & !missing(originofefc) & missing(pellrecipient)

//Create an error list of scholars missing a Pell Grant that appear eligible
keep if originofefc=="FAFSA" & expectedfamilycontribution<=5234 & !missing(expectedfamilycontribution) & !missing(originofefc) & missing(pellrecipient)

// Consolidate list and export
duplicates drop contactid18char, force
gen error = "Eligible for Pell Grant and did not have one listed"
keep fullname error
save "error_missingpellgrant.dta", replace

clear
set more off
********************************************************************************
//BOG Waiver - look at PSI and see if missing BOG Waiver
use "bp_finaid_forreview"

keep if aidsource=="BOG Waiver"
duplicates drop contactid18char, force
gen bogrecipient="BOG Recipient"
keep contactid18char bogrecipient fullname
save "bogrecipients", replace

// Merge with the original dataset
merge 1:m contactid18char using "bp_finaid_forreview"

// Only keep public, CA 2 year schools to check if BOG Waiver
keep if (collegeuniversityattendingaccoun=="Merced College" | collegeuniversityattendingaccoun=="Modesto Junior College" | collegeuniversityattendingaccoun=="Santa Barbara City College")

// Create an error list of scholars missing a BOG Waiver that appear eligible
keep if missing(bogrecipient)

// Consolidate list and export
duplicates drop contactid18char, force
gen error = "Eligible for BOG Waiver and did not have one listed"
keep fullname error
save "error_missingbog.dta", replace

********************************************************************************
append using "error_missingcalgrant.dta"
append using "error_missingpellgrant.dta"

outsheet using "Bright Prospect Financial Aid Error_$S_DATE.csv", comma replace

clear
set more off
log close
