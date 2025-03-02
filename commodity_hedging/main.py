import numpy as np
import pandas as pd
from config.config import MARKET_INDEX, OIL_INDEX
from data_ingestion.data_ingestion import DataIngestion

###########
# Step 1: Import the prepared financial data
###########
df = pd.read_excel("data/input.xlsx")

###########
# Step 2: Find all companies' tickers
###########
tickers = df.drop_duplicates(subset=["Ticker"])["Ticker"]
tickers = tickers.reset_index(drop = True).to_list()

###########
# Step 3: Prepare data for a Market Model regression
###########
data_list = []
df_risk = pd.DataFrame()

for t in tickers:
    dates = DataIngestion.get_index()

    for i in dates:
        # Default financial and operational hedging values
        fh_value, oh_value = float("nan"), float("nan")

        if i.year != 2012:
            # Filter the DataFrame efficiently
            filtered_data = df.loc[(df["Year"] == i.year - 1) & (df["Ticker"] == t), ["FH", "OH"]]
            
            if not filtered_data.empty:
                fh_value = filtered_data["FH"].values[0]
                oh_value = filtered_data["OH"].values[0]

        data_list.append((t, i, fh_value, oh_value))

df_risk = pd.DataFrame(data_list, columns=["Ticker", "Date", "FH", "OH"])

###########
# Step 4: Prepare Companies' returns
###########
comp_df = DataIngestion.download_daily_data(tickers)
comp = DataIngestion.get_returns(comp_df)

###########
# Step 5: Prepare Market and Oil returns
###########
sub_df = pd.DataFrame()

sub_df["Market"] = DataIngestion.download_daily_data(MARKET_INDEX)
sub_df["Oil"] = DataIngestion.download_daily_data(OIL_INDEX)

sub = DataIngestion.get_returns(sub_df)

###########
# Step 6: Combine all returns
###########
comp_stdev = []
market_stdev = []
oil_stdev = []

for t in tickers:
    comp_stdev += comp[t].to_list()
    market_stdev += sub["Market"].to_list()
    oil_stdev += sub["Oil"].to_list()

df_risk["StDev"] = comp_stdev
df_risk["Market_StDev"] = market_stdev
df_risk["Oil_StDev"] = oil_stdev

###########
# Step 6: Export Market Model data to Excel
###########
df_risk.to_excel('regression/output_market.xlsx', sheet_name = "Data", index = False)

###########
# Step 7: Prepare data for Tobin's Q regression
###########
df["Q"] = np.log((df["Total Assets"] - df["Total Equity"] + df["Market Cap"]) / df["Total Assets"])

df["Size"] = np.log(df["Total Assets"])
df["Leverage"] = df["Total Debt"] / df["Market Cap"]
df["ROA"] = df["Net Income"] / df["Total Assets"]
df["Growth"] = df["CAPEX"] / df["Total Assets"]

# Data not needed for future analysis
df = df.drop(columns=["Market Cap", "Total Sales", "Net Income", "Total Equity", 
                      "Total Debt", "Total Assets", "CAPEX"])

###########
# Step 8: Export Tobin's Q data to Excel
###########
df.to_excel('regression/output_tobin.xlsx', sheet_name = "Data", index = False)