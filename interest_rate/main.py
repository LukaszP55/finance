import statsmodels.formula.api as smf
import numpy as np
import pandas as pd
import yfinance as yf
from datetime import date, timedelta
from data_ingestion.data_ingestion import DataIngestion
from models.bank_record import BankRecord
from smtp.SMTPEmail import SMTPEmail

###########
# Step 1: Declaration of banks handled in the code
###########
banks_info = [
    {'ticker': 'BAC', 'cik': 'CIK0000070858'},
    {'ticker': 'JPM', 'cik': 'CIK0000019617'},
    {'ticker': 'C', 'cik': 'CIK0000831001'},
    {'ticker': 'WFC', 'cik': 'CIK0000072971'},
    {'ticker': 'TFSL', 'cik': 'CIK0001381668'},
    {'ticker': 'BK', 'cik': 'CIK0001390777'},
    {'ticker': 'HBAN', 'cik': 'CIK0000049196'},
    {'ticker': 'TFC', 'cik': 'CIK0000092230'}
]

###########
# Step 2: Prepare companies' returns
###########
data = DataIngestion.download_daily_data(list(map(lambda x: x['ticker'], banks_info)))
log_returns = np.log(data/data.shift(1))[1:]

###########
# Step 3: Prepare yields
###########
yields = DataIngestion.download_daily_data('^TYX')
diff_yields = yields[1:]
diff_yields = diff_yields['^TYX']

###########
# Step 4: Adjust to ensure the number of days is equal
###########
log_returns = log_returns.loc[log_returns.index.intersection(diff_yields.index)]
diff_yields = diff_yields.loc[diff_yields.index.intersection(log_returns.index)]

###########
# Step 5: Retrieve and create data for regressions
###########
df = pd.DataFrame(columns=["Ticker", "Year", "Quarter", "Start", "End", "Return", "Extreme_Interest_Rate", "Period_Interest_Rate", "Margin", "AFS"])
period = log_returns.index.to_pydatetime()

for x in banks_info:
    bank_data = {
        'other_income': DataIngestion.get_other_income(x['ticker'], x['cik']),
        'profit': DataIngestion.get_profit(x['ticker'], x['cik']),
        'assets_for_sale': DataIngestion.get_assets_for_sale(x['ticker'], x['cik'])
    }

    sum_other_income = 0
    sum_profit = 0
    previous_date = period[0]

    fp = previous_date.month // 3 + 1

    item = BankRecord(x['ticker'], period[0], None, 'Q' + str(fp), diff_yields.iloc[0], bank_data, sum_other_income, sum_profit)

    for y in period:
        if not (item.start and item.end):
            fp = y.month // 3 + 1

            if fp == 4:
                item = BankRecord(x['ticker'], y, None, 'Q' + str(fp), diff_yields.loc[y], bank_data, sum_other_income, sum_profit)
            else:
                item = BankRecord(x['ticker'], y, previous_date, 'Q' + str(fp), diff_yields.loc[y], bank_data, sum_other_income, sum_profit)
        elif item.end < y:
            if item.start and item.end:
                df = pd.concat([df, item.convert_to_df()], ignore_index = True)

            fp = y.month // 3 + 1

            if fp == 4:
                q4_start_date = item.end + timedelta(days=1)

                item = BankRecord(x['ticker'], y, None, 'Q' + str(fp), diff_yields.loc[y], bank_data, sum_other_income, sum_profit)
                item.start = q4_start_date

                sum_other_income = 0
                sum_profit = 0
            else:
                item = BankRecord(x['ticker'], y, previous_date, 'Q' + str(fp), diff_yields.loc[y], bank_data, sum_other_income, sum_profit)

                if item.start and item.end:
                    sum_other_income += item.other_income
                    sum_profit += item.profit
        else:
            item.count_return(log_returns[x['ticker']].loc[y])
            item.set_extreme_interest_rate(diff_yields.loc[y])
            item.set_last_interest_rate(diff_yields.loc[y])

        previous_date = y

###########
# Step 6: Export data to Excel
###########
df.to_excel('output.xlsx', sheet_name = 'Banks', index = False)

###########
# Step 7: Run additional regressions
###########
reg_df = pd.ExcelFile("output.xlsx").parse()

reg_df = reg_df.dropna()

print("\nFull Regression")

res = smf.ols("Return ~ Extreme_Interest_Rate + Period_Interest_Rate + Margin + AFS", data = reg_df).fit()
print(res.summary())

print("\nRestricted")

res = smf.ols("Return ~ Extreme_Interest_Rate + Period_Interest_Rate", data = reg_df).fit()
print(res.summary())

print("\nExtreme 75th percentile")

extreme_quantile = reg_df["Extreme_Interest_Rate"].quantile(0.75)
res = smf.ols("Return ~ Extreme_Interest_Rate + Period_Interest_Rate + Margin + AFS", data = reg_df.loc[reg_df["Extreme_Interest_Rate"] >= extreme_quantile]).fit()
print(res.summary())

print("\nPeriod 75th percentile")

period_quantile = reg_df["Period_Interest_Rate"].quantile(0.75)
res = smf.ols("Return ~ Extreme_Interest_Rate + Period_Interest_Rate + Margin + AFS", data = reg_df.loc[reg_df["Period_Interest_Rate"] >= period_quantile]).fit()
print(res.summary())

###########
# Step 8: Run a logistic regression
###########

print("\nLogit")

logit_df = reg_df
logit_df.loc[logit_df["Return"] > 0, "Return"] = 1

res = smf.logit("Return ~ Extreme_Interest_Rate + Period_Interest_Rate + Margin + AFS", data = logit_df).fit()
print(res.summary())

logit_df["Reg"] = res.predict(logit_df).to_frame()

###########
# Step 9: Notify about the increased risk
###########
logit_df["Start"] = pd.to_datetime(logit_df["Start"])
logit_df["End"] = pd.to_datetime(logit_df["End"])

toSend = logit_df.loc[
    (logit_df["Start"].dt.date <= date.today()) & 
    (logit_df["End"].dt.date >= date.today()) &
    (logit_df["Reg"] >= 0.3),
    "Ticker"
].unique()


smtp = SMTPEmail()
smtp.send_warning(toSend)