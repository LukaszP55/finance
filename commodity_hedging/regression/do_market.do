***************
* Dissertation 'Market Model' by Lukasz Pietrowski 
* MSc Finance, The University of Edinburgh, 2023-2024
***************

***************
* Step 1: Import the Market Model data.
***************
import excel "output_market.xlsx", sheet("Data") firstrow

***************
* Step 2: Drop observations with missing data.
***************
drop if StDev == . | Market_StDev == . | Oil_StDev == . | FH == . | OH == .

***************
* Step 3: Hedging variables cannot be negative; we assume the minimum value is 0.
***************
replace OH = 0 if (OH < 0)
replace FH = 0 if (FH < 0)

local variables OH FH

***************
* Step 4: Winsorization of outliers at the 99th percentile level, 
* but ONLY for hedge variables,  as these are financial data. 
* OUTLIERS IN ASSET RETURNS, HOWEVER, ARE CRUCIAL FOR ANALYSIS!
***************
foreach x of local variables {
	*Winsorization: remove extreme values
	sum `x', detail
	replace `x' = r(p99) if `x' > r(p99)
	replace `x' = r(p1) if `x' < r(p1)
}

***************
* Step 5: Generate a unique numeric variable for each company, 
* as clustering cannot be performed on 'Ticker' (a string).
***************
gen number = 0
levelsof Ticker, local(levels)
local index = 0
foreach x of local levels {
	replace number = `index' if Ticker == "`x'"
	local ++index
}

***************
* Step 6: Generate dummy variables for hedges: if the firm 
* hedged in the given period, assign 1; otherwise 0.
***************
gen OH_Dummy = 0
replace OH_Dummy = 1 if OH > 0

gen FH_Dummy = 0
replace FH_Dummy = 1 if FH > 0

***************
* Step 7: Generate a variable to identify the size category.
***************
gen cat = 0

* Smallest Companies: Category 1
replace cat = 1 if Ticker == "NOG"
replace cat = 1 if Ticker == "TALO.K"
replace cat = 1 if Ticker == "PARR.K"
replace cat = 1 if Ticker == "BTE"
replace cat = 1 if Ticker == "CRC"
replace cat = 1 if Ticker == "CVI"
replace cat = 1 if Ticker == "KOS"
replace cat = 1 if Ticker == "VET"
replace cat = 1 if Ticker == "MTDR.K"
replace cat = 1 if Ticker == "RRC"

* Medium-Small Companies: Category 2
replace cat = 2 if Ticker == "CHRD.O"
replace cat = 2 if Ticker == "VRN"
replace cat = 2 if Ticker == "PDCE.OQ"
replace cat = 2 if Ticker == "DK"
replace cat = 2 if Ticker == "MUR"
replace cat = 2 if Ticker == "PBF"
replace cat = 2 if Ticker == "AR"
replace cat = 2 if Ticker == "APA.O"
replace cat = 2 if Ticker == "OVV"
replace cat = 2 if Ticker == "CHK.O"

* Medium-Large Companies: Category 3
replace cat = 3 if Ticker == "DINO.K"
replace cat = 3 if Ticker == "MRO"
replace cat = 3 if Ticker == "CTRA.K"
replace cat = 3 if Ticker == "HES"
replace cat = 3 if Ticker == "DVN"
replace cat = 3 if Ticker == "FANG.O"
replace cat = 3 if Ticker == "IMO"
replace cat = 3 if Ticker == "PXD"
replace cat = 3 if Ticker == "EOG"
replace cat = 3 if Ticker == "CVE"

* Largest Companies: Category 4
replace cat = 4 if Ticker == "WMB"
replace cat = 4 if Ticker == "CNQ"
replace cat = 4 if Ticker == "VLO"
replace cat = 4 if Ticker == "SU"
replace cat = 4 if Ticker == "OXY"
replace cat = 4 if Ticker == "PSX"
replace cat = 4 if Ticker == "MPC"
replace cat = 4 if Ticker == "COP"
replace cat = 4 if Ticker == "CVX"
replace cat = 4 if Ticker == "XOM"

* Drop if the company was not assigned
drop if cat == 0

***************
* Step 8: Save the generated data sample.
***************
save sample_market, replace

***************
* Step 9: Create summary statistics for the entire sample and for individual categories.
***************
use sample_market, clear

* Summary statistics for the Full Sample
estpost tabstat StDev Market_StDev Oil_StDev FH OH, stats(mean sd min p25 median p75 max n) columns (stats)
est store A_Summary
distinct Ticker
estadd local A_Firms=r(ndistinct)
esttab A_Summary using "Summary_Market_Model.rtf", replace cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel A: Full sample") eqlabels(none) stats(A_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Smallest
estpost tabstat StDev Market_StDev Oil_StDev FH OH if cat == 1, stats(mean sd min p25 median p75 max n) columns (stats)
est store B_Summary
distinct Ticker if cat == 1
estadd local B_Firms=r(ndistinct)
esttab B_Summary using "Summary_Market_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel B: Small") eqlabels(none) stats(B_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Medium-Small
estpost tabstat StDev Market_StDev Oil_StDev FH OH if cat == 2, stats(mean sd min p25 median p75 max n) columns (stats)
est store C_Summary
distinct Ticker if cat == 3
estadd local C_Firms=r(ndistinct)
esttab C_Summary using "Summary_Market_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel C: Mid_Small") eqlabels(none) stats(C_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Medium-Large
estpost tabstat StDev Market_StDev Oil_StDev FH OH if cat == 3, stats(mean sd min p25 median p75 max n) columns (stats)
est store D_Summary
distinct Ticker if cat == 3
estadd local D_Firms=r(ndistinct)
esttab D_Summary using "Summary_Market_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel D: Mid_Large") eqlabels(none) stats(D_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Largest
estpost tabstat StDev Market_StDev Oil_StDev FH OH if cat == 4, stats(mean sd min p25 median p75 max n) columns (stats)
est store E_Summary
distinct Ticker if cat == 4
estadd local E_Firms=r(ndistinct)
esttab E_Summary using "Summary_Market_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel E: Large") eqlabels(none) stats(E_Firms, labels("Companies")) noobs compress nonumbers

***************
* Step 10: Create correlation matrices for the entire sample and for individual categories.
***************

eststo clear

* Corrrelation for the Full Sample
estpost corr StDev Market_StDev Oil_StDev FH OH, matrix listwise
est store Full_Corr
esttab Full_Corr using "Corrrelation_Market_Model.rtf", replace unstack not noobs nonotes nonumbers nostar nogaps compress title("Panel A: Full sample") b(2)

* Corrrelation for the Smallest
estpost corr StDev Market_StDev Oil_StDev FH OH if cat == 1, matrix listwise
est store B_Corr
esttab B_Corr using "Corrrelation_Market_Model.rtf", append unstack not noobs nonotes nonumbers nostar nogaps compress title("Panel B: Small") b(2)

* Corrrelation for the Medium-Small
estpost corr StDev Market_StDev Oil_StDev FH OH if cat == 2, matrix listwise
est store C_Corr
esttab C_Corr using "Corrrelation_Market_Model.rtf", append unstack not noobs nonotes nonumbers nostar nogaps compress title("Panel C: Mid-Small") b(2)

* Corrrelation for the Medium-Large
estpost corr StDev Market_StDev Oil_StDev FH OH if cat == 3, matrix listwise
est store D_Corr
esttab D_Corr using "Corrrelation_Market_Model.rtf", append unstack not noobs nonotes nonumbers nostar nogaps compress title("Panel D: Mid-Large") b(2)

* Corrrelation for the Largest
estpost corr StDev Market_StDev Oil_StDev FH OH if cat == 4, matrix listwise
est store E_Corr
esttab E_Corr using "Corrrelation_Market_Model.rtf", append unstack not noobs nonotes nonumbers nostar nogaps compress title("Panel E: Large") b(2)

***************
* Step 11: Run regressions!
***************
use sample_market, clear

xtset number

* Two-Factor Market Model
eststo clear
eststo Full: reg StDev Market_StDev Oil_StDev, cluster(number)
eststo B: reg StDev Market_StDev Oil_StDev if cat == 1, cluster(number)
eststo C: reg StDev Market_StDev Oil_StDev if cat == 2, cluster(number)
eststo D: reg StDev Market_StDev Oil_StDev if cat == 3, cluster(number)
eststo E: reg StDev Market_StDev Oil_StDev if cat == 4, cluster(number)
esttab using "Regression_Market_Basic.rtf", replace b(3) se(3) r2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large")

* VIF Test for Two-Factor Market Model
reg StDev Market_StDev Oil_StDev, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev if cat == 1, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev if cat == 2, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev if cat == 3, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev if cat == 4, cluster(number)
estat vif


* Interaction terms between Oil factor and FH / OH
eststo clear
eststo Full: reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH, cluster(number)
eststo B: reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 1, cluster(number)
eststo C: reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 2, cluster(number)
eststo D: reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 3, cluster(number)
eststo E: reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 4, cluster(number)
esttab using "Regression_Market_Oil_Interaction.rtf", replace b(3) se(3) r2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large")

* VIF Test for ITs between Oil factor and FH / OH
reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 1, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 2, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 3, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#c.FH c.Oil_StDev#c.OH if cat == 4, cluster(number)
estat vif


* Dummy Regression
eststo clear
eststo Full: reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy, cluster(number)
eststo B: reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 1, cluster(number)
eststo C: reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 2, cluster(number)
eststo D: reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 3, cluster(number)
eststo E: reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 4, cluster(number)
esttab using "Regression_Market_Dummy.rtf", replace b(3) se(3) r2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large")

* VIF Test for Dummy Regression
reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 1, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 2, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 3, cluster(number)
estat vif
reg StDev Market_StDev Oil_StDev c.Oil_StDev#1.FH_Dummy c.Oil_StDev#1.OH_Dummy if cat == 4, cluster(number)
estat vif