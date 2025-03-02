***************
* Dissertation 'Tobin's Q Model' by Lukasz Pietrowski 
* MSc Finance, The University of Edinburgh, 2023-2024
***************

***************
* Step 1: Import the Tobin's Q data.
***************
import excel "output_tobin.xlsx", sheet("Data") firstrow

***************
* Step 2: Drop observations with missing data.
***************
drop if Q == .| OH == . | FH == . | Size == . | Leverage == . | ROA == . | Growth == . | Dividend == .

***************
* Step 3: Hedging variables cannot be negative; we assume the minimum value is 0.
***************
replace OH = 0 if (OH < 0)
replace FH = 0 if (FH < 0)

local variables Q OH FH Size Leverage ROA Growth

***************
* Step 4: Winsorization of outliers at the 99th percentile level.
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
save sample_tobin, replace

***************
* Step 9: Create summary statistics for the entire sample and for individual categories.
***************
use sample_tobin, clear

eststo clear

* Summary statistics for the Full Sample
estpost tabstat Q FH OH Size Leverage ROA Growth Dividend, stats(mean sd min p25 median p75 max n) columns (stats)
est store A_Summary
distinct Ticker
estadd local A_Firms=r(ndistinct)
esttab A_Summary using "Summary_Tobin_Model.rtf", replace cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel A: Full sample") eqlabels(none) stats(A_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Smallest
estpost tabstat Q FH OH Size Leverage ROA Growth Dividend if cat == 1, stats(mean sd min p25 median p75 max n) columns (stats)
est store B_Summary
distinct Ticker if cat == 1
estadd local B_Firms=r(ndistinct)
esttab B_Summary using "Summary_Tobin_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel B: Small") eqlabels(none) stats(B_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Medium-Small
estpost tabstat Q FH OH Size Leverage ROA Growth Dividend if cat == 2, stats(mean sd min p25 median p75 max n) columns (stats)
est store C_Summary
distinct Ticker if cat == 3
estadd local C_Firms=r(ndistinct)
esttab C_Summary using "Summary_Tobin_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel C: Mid_Small") eqlabels(none) stats(C_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Medium-Large
estpost tabstat Q FH OH Size Leverage ROA Growth Dividend if cat == 3, stats(mean sd min p25 median p75 max n) columns (stats)
est store D_Summary
distinct Ticker if cat == 3
estadd local D_Firms=r(ndistinct)
esttab D_Summary using "Summary_Tobin_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel D: Mid_Large") eqlabels(none) stats(D_Firms, labels("Companies")) noobs compress nonumbers

* Summary statistics for the Largest
estpost tabstat Q FH OH Size Leverage ROA Growth Dividend if cat == 4, stats(mean sd min p25 median p75 max n) columns (stats)
est store E_Summary
distinct Ticker if cat == 4
estadd local E_Firms=r(ndistinct)
esttab E_Summary using "Summary_Tobin_Model.rtf", append cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) max(fmt(2)) count(fmt(0))") collabels("Mean" "SD" "Min" "P25" "Med" "P75" "Max" "Obs") title("Panel E: Large") eqlabels(none) stats(E_Firms, labels("Companies")) noobs compress nonumbers

***************
* Step 10: Create correlation matrices for the entire sample and for individual categories.
***************
eststo clear

* Corrrelation for the Full Sample
estpost corr Q FH OH Size Leverage ROA Growth Dividend, matrix listwise
est store Full_Corr
esttab Full_Corr using "Corrrelation_Tobin_Model.rtf", replace unstack not noobs nonotes nonumbers nostar compress title("Panel A: Full sample") b(2)

* Corrrelation for the Smallest
estpost corr Q FH OH Size Leverage ROA Growth Dividend if cat == 1, matrix listwise
est store B_Corr
esttab B_Corr using "Corrrelation_Tobin_Model.rtf", append unstack not noobs nonotes nonumbers nostar compress title("Panel B: Small") b(2)

* Corrrelation for the Medium-Small
estpost corr Q FH OH Size Leverage ROA Growth Dividend if cat == 2, matrix listwise
est store C_Corr
esttab C_Corr using "Corrrelation_Tobin_Model.rtf", append unstack not noobs nonotes nonumbers nostar compress title("Panel C: Mid-Small") b(2)

* Corrrelation for the Medium-Large
estpost corr Q FH OH Size Leverage ROA Growth if cat == 3, matrix listwise
est store D_Corr
esttab D_Corr using "Corrrelation_Tobin_Model.rtf", append unstack not noobs nonotes nonumbers nostar compress title("Panel D: Mid-Large") b(2)

* Corrrelation for the Largest
estpost corr Q FH OH Size Leverage ROA Growth if cat == 4, matrix listwise
est store E_Corr
esttab E_Corr using "Corrrelation_Tobin_Model.rtf", append unstack not noobs nonotes nonumbers nostar compress title("Panel E: Large") b(2)

***************
* Step 11: Comparison of hedging and non-hedging firms
***************
use sample_tobin, clear

* Financial Hedging
sum Q Size Leverage ROA if FH_Dummy == 1, detail
sum Q Size Leverage ROA if FH_Dummy == 0, detail
ttest Q, by(FH_Dummy)
ranksum Q, by(FH_Dummy)

ttest Size, by(FH_Dummy)
ranksum Size, by(FH_Dummy)

ttest Leverage, by(FH_Dummy)
ranksum Leverage, by(FH_Dummy)

ttest ROA, by(FH_Dummy)
ranksum ROA, by(FH_Dummy)

* Operational Hedging
sum Q Size Leverage ROA if OH_Dummy == 1, detail
sum Q Size Leverage ROA if OH_Dummy == 0, detail
ttest Q, by(OH_Dummy)
ranksum Q, by(OH_Dummy)

ttest Size, by(OH_Dummy)
ranksum Size, by(OH_Dummy)

ttest Leverage, by(OH_Dummy)
ranksum Leverage, by(OH_Dummy)

ttest ROA, by(OH_Dummy)
ranksum ROA, by(OH_Dummy)

***************
* Step 12: Run regressions!
***************

use sample_tobin, clear

xtset number Year


* Multivariate Regression with Controls
eststo clear
eststo Full: xtreg Q FH OH Size Leverage ROA Growth Dividend i.Year, cluster(number) fe
eststo B: xtreg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number) fe
eststo C: xtreg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number) fe
eststo D: xtreg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number) fe
eststo E: xtreg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number) fe
esttab using "Regression_Tobin_Multivariate.rtf", replace b(3) se(3) r2 ar2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large") indicate("Year Effect = *Year") stats(N r2_o, fmt(%9.0g %9.3f) labels("N" "R-square"))

* VIF Test for Multivariate Regression
reg Q FH OH Size Leverage ROA Growth Dividend i.Year, cluster(number)
estat vif
reg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number)
estat vif
reg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number)
estat vif
reg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number)
estat vif
reg Q FH OH Size Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number)
estat vif


* Multivariate Dummy Regression with Controls
eststo clear
eststo Full: xtreg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year, cluster(number) fe
eststo B: xtreg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number) fe
eststo C: xtreg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number) fe
eststo D: xtreg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number) fe
eststo E: xtreg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number) fe
esttab using "Regression_Tobin_Dummy.rtf", replace b(3) se(3) r2 ar2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large") indicate("Year Effect = *Year") stats(N r2_o, fmt(%9.0g %9.3f) labels("N" "R-square"))

* VIF Test for Multivariate Dummy Regression
reg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year, cluster(number)
estat vif
reg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number)
estat vif
reg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number)
estat vif
reg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number)
estat vif
reg Q FH_Dummy OH_Dummy Size Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number)
estat vif


* Interaction term between FH and OH
eststo clear
eststo Full: xtreg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year, cluster(number) fe
eststo B: xtreg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number) fe
eststo C: xtreg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number) fe
eststo D: xtreg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number) fe
eststo E: xtreg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number) fe
esttab using "Regression_Tobin_Interaction.rtf", replace b(3) se(3) r2 ar2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large") indicate("Year Effect = *Year") stats(N r2_o, fmt(%9.0g %9.3f) labels("N" "R-square"))

* VIF Test for IT between FH and OH
reg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year, cluster(number)
estat vif
reg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number)
estat vif
reg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number)
estat vif
reg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number)
estat vif
reg Q FH OH c.FH#c.OH Size Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number)
estat vif


* Interaction terms between Leverage and FH / OH
eststo clear
eststo Full: xtreg Q FH OH c.FH#c.Leverage c.OH#c.Leverage Size Leverage ROA Growth Dividend i.Year, cluster(number) fe
eststo B: xtreg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number) fe
eststo C: xtreg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number) fe
eststo D: xtreg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number) fe
eststo E: xtreg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number) fe
esttab using "Regression_Tobin_Leverage_Interaction.rtf", replace b(3) se(3) r2 ar2 star(* .10 ** .05 *** .01) obslast compress mtitles("Full sample" "Small" "Mid-Small" "Mid-Large" "Large") indicate("Year Effect = *Year") stats(N r2_o, fmt(%9.0g %9.3f) labels("N" "R-square"))

* VIF Test for ITs between Leverage and FH / OH
reg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year, cluster(number)
estat vif
reg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 1, cluster(number)
estat vif
reg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 2, cluster(number)
estat vif
reg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 3, cluster(number)
estat vif
reg Q FH OH Size Leverage c.FH#c.Leverage c.OH#c.Leverage ROA Growth Dividend i.Year if cat == 4, cluster(number)
estat vif


***************
* Step 13: Testing the accuracy of the results.
***************
use sample_tobin, clear

* LM Test
xtset number Year
xtreg Q OH FH Size Leverage ROA Growth Dividend i.Year, re
est store re
xttest0

* Hausman Test
xtreg Q OH FH Size Leverage ROA Growth Dividend i.Year, fe
est store fe
hausman fe re