********************************************************************************
log using "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\log_stancoe_$S_DATE.log"
/* The purpose of this do file is to clean and review student level data from Beyond 12
for AY16-17

Each grantee will have 2 files associated with them:
The first file covers a review of all non-financial aid fields. This do file reviews this set of data.
The second file covers all financial aid fields. There is a different do file to review this set of data.

The unique list of students identified in the first file are used to identify the students of interest in the second file.
The first file also provides information used to summarize most of the required reporting fields.
Some of the tabulations will be used to add into an excel workbook (the "Review Workbook") that asked grantees to confirm the information reported.
The remaining outputs are consolidated to identify the students with errors in the data reported, and flags each error accordingly.

*/

//Set the working directory where all files will be stored
cd "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\First Graduate"

insheet using "firstgrad_02142017.csv"
egen fullname= concat(firstname lastname), punct(" ")

cd "N:\New - Raw Data\Student Data (Grantee Reported)\2016 Data\Beyond 12 Reports\First Graduate\Temp"
save "firstgrad_forreview", replace

// The first set of tabulations will be manually viewed for accuracy and to copy into the Review Workbook
/* JL Notes:
1. Are you looking for CBB reporting grantees?
2. Are you looking for any non-scholars?
3. Is the total aid amount accepted for all scholars (i.e. 18 scholars so 18 individual awards)? Is it important to distinguish when it's not the case? I think you do this later when you call out aidaccepted being missing...?
4. In your review reports, are you listing hte total number of students reported? I do see you list total types of scholarships. 
5. when you review DOB, is it correct that B12 has a validation to prevent incorrect day v months? it looks like you are just checking for year righ
6. I remember the race/ethnicity field being pretty dirty. are you reviewing for this/checking in with Arielle as to how to clean it if needed?
7. I don't see a review of high school names here - is it in a different file?
8. Are you looking for PSI names? i.e. looking for PSIs wiht "unknown" listed or weird values? Same for high schools?
9. 
*/

* How many scholars are included?
distinct contactid18char if aidsource=="College Futures Scholarship"
distinct contactid18char if aidsource=="Community Foundation Scholarship"

* What is the total amount of scholarship $ listed?
total aidamountaccepted if aidsource=="College Futures Scholarship"
total aidamountaccepted if aidsource=="Community Foundation Scholarship"

* How many students complete the FAFSA/Dream Act?
distinct contactid18char if originofefc=="FAFSA"
distinct contactid18char if originofefc=="Dream Act"

* How many students are/aren't A-G Eligible?
tab ageligible, mi

* Which students have unusual birthdates (check to make sure year is reasonable)?

gen edate1=date(birthdate, "MDY")
format edate1 %td "MDY"
gen year=year(edate1)

tab year, mi

* Are there any unusual values for first or names listed?

tab firstname, mi
tab lastname, mi

// The second set of calculations are meant to create a conslidated data output of all the student's name with their respective errors.
// The dataset is modified to only include first and last names and the error listed. It is then output for later appending.
// The first set of tabulations will show whether or not there are any errors. If there are, then a file will be generated for each of those errors.
// Finally, all files will be appended to create the dataset to be shared with the grantee.

tab gender, mi
tab firstgenerationcollegestudent, mi
tab accountname, mi
tab dependency, mi
tab collegefutureshsweightedgpa, mi
tab ageligible, mi
tab highschoolgraduationyear, mi
tab studentedgoal, mi
tab major1, mi
tab totalcredithourstowardsgradearne, mi
tab cumulativegpa, mi
tab collegeuniversityattendingaccoun, mi
tab livingsituation, mi
tab originofefc, mi
tab fafsacompletedbyprioritydate, mi
tab expectedfamilycontribution, mi
tab frequencyofscholarshipdisburseme, mi
tab collegefuturesgrant, mi
tab aidamountaccepted, mi

* How many students have more than 1 scholarship listed?
duplicates tag contactid18char, gen(dupes)
keep if dupes==1
keep fullname
gen error = "Multiple College Futures Scholarships listed"
save "error_multiplescholarships.dta", replace

clear
set more off
use "firstgrad_forreview"

* Which students are missing birthdates?
keep if missing(birthdate)
keep fullname
gen error = "Missing Date of Birth"
save "error_missingdob.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students have erroneous or missing genders?
keep if missing(gender)
keep fullname
gen error = "Missing Gender"
save "error_missinggender.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students have erroneous or missing ethnicities/races?

gen ethnicity_race = ethnicity if ethnicity=="Hispanic or Latino"
replace ethnicity_race = race if missing(ethnicity_race)

keep if missing(ethnicity_race)
keep fullname
gen error = "Missing Race and Ethnicity"
save "error_raceethnicity.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Are there Asian students with a missing API group?
gen ethnicity_race = ethnicity if ethnicity=="Hispanic or Latino"
replace ethnicity_race = race if missing(ethnicity_race)

keep if missing(asianpacificislander) & ethnicity_race=="Asian"
keep fullname
gen error = "Missing API Group"
save "error_missingapi.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their First Generation info?
keep if missing(firstgenerationcollegestudent)
keep fullname
gen error = "Missing First Generation College Student Status"
save "error_missingfirstgen.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing high schools?
keep if missing(accountname)
keep fullname
gen error = "Missing High School"
save "error_missinghs.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing dependency status?
keep if missing(dependency)
keep fullname
gen error = "Missing Dependency Status"
save "error_missingdependency.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their high school gpa?
keep if missing(collegefutureshsweightedgpa)
keep fullname
gen error = "Missing High School GPA"
save "error_missinghsgpa.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students are A-G Elible or not?
keep if ageligible==0
keep fullname
gen error = "Did not complete A-G Requirements"
save "error_missingag.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their High School Graduation Year?
keep if missing(highschoolgraduationyear)
keep fullname
gen error = "Missing High School Graduation Year"
save "error_missinghsgradyear.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their student ed goal?
keep if missing(studentedgoal)
keep fullname
gen error = "Missing Student Education Goal"
save "error_missingstudentedgoal.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their College Major?
keep if missing(major1)
keep fullname
gen error = "Missing College Major"
save "error_missingcollegemajor.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their College Credit Hours?
keep if (missing(totalcredithourstowardsgradearne) | totalcredithourstowardsgradearne==0)
keep fullname
gen error = "Missing College/University Attending Name"
save "error_missingpsi.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their College GPA?
keep if (missing(cumulativegpa) | cumulativegpa==0)
keep fullname
gen error = "Missing College GPA"
save "error_missingcollegegpa.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students completed the FAFSA/Dream Act by the Priority Date and which students did not?
keep if (missing(fafsacompletedbyprioritydate) | fafsacompletedbyprioritydate==0)
keep fullname
gen error = "Did not complete FAFSA/Dream Act by the Priority Date"
save "error_missingpriority.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their PSI Name?
keep if (missing(collegeuniversityattendingaccoun) | collegeuniversityattendingaccoun=="Unknown Univ")
keep fullname
gen error = "Missing College/University Attending Name"
save "error_missingpsi.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* Which students are missing their Student Living Situation?
keep if missing(livingsituation)
keep fullname
gen error = "Missing Student Living Situation"
save "error_missingliving.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students are missing their Origin of EFC & EFC Amount?
keep if missing(expectedfamilycontribution) & missing(originofefc)
keep fullname
gen error = "Missing EFC and Origin of EFC"
save "error_missingefcandorigin.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students are only missing their Origin of EFC, but have an EFC Amount listed?
keep if !missing(expectedfamilycontribution) & missing(originofefc)
keep fullname
gen error = "Missing Origin of EFC, have EFC listed"
save "error_missingoriginnotefc.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students are missing their frequency of scholarship disbursement?
keep if missing(frequencyofscholarshipdisburseme)
keep fullname
gen error = "Missing Frequency of Scholarship disbursement"
save "error_missingfrequency.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students are missing their College Futures Grant Number?
keep if aidsource=="College Futures Scholarship" & missing(collegefuturesgrant)
keep fullname
gen error = "Missing College Futures Grant Number"
save "error_missinggrantnumber.dta", replace

clear
set more off
use "firstgrad_forreview", replace

* How many students are missing their Aid Amount Accepted?
keep if missing(aidamountaccepted) | aidamountaccepted==0
keep fullname
gen error = "Missing Aid Amount Accepted for Scholarship"
save "error_missingaidaccept.dta", replace


* 
// This last set of code appends all the datasets from above together into a single file. This will be adjusted manually each round of entry (unless code is updated to continue running despite missing errors)
// This will be outsheet into a .csv to add to the "Review Workbook" that will be sent to the grantee

append using "error_multiplescholarships"

append using "error_missingdob.dta"

append using "error_missinggender.dta"

append using "error_raceethnicity.dta"

append using "error_missingapi.dta"

append using "error_missingfirstgen.dta"

append using "error_missinghs.dta"

append using "error_missingdependency.dta"

append using "error_missinghsgpa.dta"

append using "error_missingag.dta"

append using "error_missinghsgradyear.dta"

append using "error_missingstudentedgoal.dta"

append using "error_missingcollegemajor.dta"

append using "error_missingpsi.dta"

append using "error_missingcollegegpa.dta"

append using "error_missingpriority.dta"

append using "error_missingpsi.dta"

append using "error_missingliving.dta"

append using "error_missingefcandorigin.dta"

append using "error_missingoriginnotefc.dta"

append using "error_missingfrequency.dta"

append using "error_missinggrantnumber.dta"

save "master_error_$S_DATE.dta"

/* The duplicate entries (where students are listed with the same error twice) will be dropped.
This happens because the original dataset is long: one row per student per scholarship of interest.
So, if a student has 2 College Futures Scholarships entered for them in the database, they will be appear in two rows of the dataset.
This means that every error they have will also be recorded twice.
*/

duplicates tag fullname error, gen(dupes)
duplicates drop
drop dupes

save "Unduplicated_Error_$S_DATE.dta", replace
outsheet using "First Graduate Error_$S_DATE.csv", comma replace

log close
