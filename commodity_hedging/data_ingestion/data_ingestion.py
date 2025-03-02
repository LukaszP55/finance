import datetime as dt
import numpy as np
import pandas as pd
import statistics
import yfinance as yf
from dateutil.relativedelta import relativedelta
from config.config import START_DATE, END_DATE

class DataIngestion:
    @staticmethod
    def download_daily_data(tickers):
        """Downloads historical monthly closing price data."""
        df = yf.download(tickers, start=START_DATE, end=END_DATE, interval='1d', auto_adjust=True)

        #Remove as the price for oil futures was negative
        df = df.drop(pd.to_datetime("2020-04-20"))

        return df['Close']
    
    @staticmethod
    def get_returns(data: pd.DataFrame):
        data_log = np.log(data/data.shift(1))
        data_sum = data_log.rolling(window = 100, min_periods = 100).sum()

        st_dev = pd.DataFrame()
        st_dev.index = __class__.get_index()

        for t in data.columns:
            st_dev[t] = __class__.calculate_annual_stdev(data_sum[t])

        return st_dev

    @staticmethod
    def calculate_annual_stdev(data: pd.DataFrame):
        """Compute monthly standard deviation"""
        stdev_values = []

        month_start = dt.date(END_DATE.year, 12, 1)
        
        while month_start >= START_DATE:
            month_end = month_start + relativedelta(months=1) - relativedelta(days=1)

            n_d = data.loc[month_start:month_end].dropna()
            
            stdev_values.append(statistics.stdev(n_d) if len(n_d) >= 15 else float("nan"))
            
            month_start -= relativedelta(months=1)
            
        return np.array(stdev_values)
    
    @staticmethod
    def get_index():
        date_values = []
        
        temp_date = dt.date(START_DATE.year, 1, 31)

        month_shift = 0

        while END_DATE - relativedelta(months=month_shift) >= temp_date:
            date_values.append(END_DATE - relativedelta(months=month_shift))
            month_shift += 1

        return date_values