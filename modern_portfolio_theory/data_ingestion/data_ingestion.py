import yfinance as yf
import pandas as pd

class DataIngestion:
    @staticmethod
    def download_monthly_data(tickers, start_date, end_date):
        """Downloads historical monthly adjusted closing price data."""
        data = yf.download(tickers, start=start_date, end=end_date, interval='1mo',auto_adjust=True)
        return data['Close']

    @staticmethod
    def calculate_monthly_returns(data):
        """Calculates monthly returns and fills NaN values with the mean return."""
        monthly_returns = data.pct_change()
        return monthly_returns.apply(lambda x: x.fillna(x.mean()))
