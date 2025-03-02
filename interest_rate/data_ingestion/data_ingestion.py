import pandas as pd
import requests
import yfinance as yf
from config.config import EMAIL_RECEIVER

BASE_URL = "https://data.sec.gov"

HEADERS = {
    "Content-Type": "application/json",
    "Accept-Encoding": "gzip, deflate",
    "User-Agent": f"BS/1.0 ({EMAIL_RECEIVER})"
}

class DataIngestion:
    @staticmethod
    def download_daily_data(tickers) -> pd.DataFrame:
        """Downloads historical monthly closing price data."""
        df = yf.download(tickers, period='10y', interval='1wk', auto_adjust=True)

        return df['Close']

    @staticmethod
    def download_financial_data(cik: str, link: str):
        url = f"{BASE_URL}/api/xbrl/companyconcept/{cik}/us-gaap/{link}.json"

        response = requests.get(url = url, headers = HEADERS)

        if response.status_code == 200:
            repos = response.json()
            return repos.get('units', [])['USD']
        else:
            print(f"Failed. Status {response.status_code}. Reason: {response.reason}")
            return []

    @staticmethod
    def get_other_income(ticker: str, cik: str) -> list:
        link = []

        if ticker in ['JPM', 'C', 'BAC', 'HBAN']:
            link.append('OtherComprehensiveIncomeAvailableforsaleSecuritiesAdjustmentNetOfTaxPortionAttributableToParent')

        if ticker in ['WFC', 'TFSL', 'BK', 'HBAN']:
            link.append('OtherComprehensiveIncomeLossAvailableForSaleSecuritiesAdjustmentNetOfTax')

        if ticker in ['TFC']:
            link.append('OtherComprehensiveIncomeUnrealizedHoldingGainLossOnSecuritiesArisingDuringPeriodNetOfTax')
        
        result = []

        for x in link:
            result.extend(__class__.download_financial_data(cik, x))
        
        return result

    @staticmethod
    def get_profit(ticker: str, cik: str) -> list:
        link = []

        if ticker in ['JPM', 'BAC', 'TFSL', 'HBAN']:
            link.append('NetIncomeLoss')

        if ticker in ['C', 'BK', 'TFC']:
            link.append('ProfitLoss')

        if ticker in ['WFC']:
            link.append('IncomeLossFromContinuingOperationsIncludingPortionAttributableToNoncontrollingInterest')
        
        result = []

        for x in link:
            result.extend(__class__.download_financial_data(cik, x))
        
        return result

    @staticmethod
    def get_assets_for_sale(ticker: str, cik: str) -> list:
        link = []

        if ticker in ['JPM', 'C', 'WFC', 'BAC', 'HBAN']:
            link.append('DebtSecuritiesAvailableForSaleExcludingAccruedInterest')

        if ticker in ['JPM', 'C', 'WFC', 'BAC', 'TFSL', 'BK', 'TFC']:
            link.append('AvailableForSaleSecuritiesDebtSecurities')

        if ticker in ['TFSL']:
            link.append('AvailableForSaleSecurities')

        if ticker in ['HBAN']:
            link.append('MarketableSecuritiesUnrealizedGainLoss')
        
        result = []

        for x in link:
            result.extend(__class__.download_financial_data(cik, x))
        
        return result