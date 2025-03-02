import numpy as np
import pandas as pd
from datetime import datetime

class BankRecord:
    def __init__(self, ticker, date, previous_date, fp, interest_rate, bank_data, sum_other_income, sum_profit):
        self.ticker = ticker
        self.year = date.year
        self.quarter = fp

        self.start = __class__.get_start_date(date, previous_date, bank_data)
        self.end = __class__.get_end_date(date, previous_date, bank_data)
        self.stock_return = 0
        self.lowest_interest_rate = interest_rate
        self.highest_interest_rate = interest_rate
        self.first_interest_rate = interest_rate
        self.last_interest_rate = interest_rate

        if self.start and self.end:
            self.other_income = __class__.get_other_income(self, bank_data, sum_other_income)
            self.profit = __class__.get_profit(self, bank_data, sum_profit)
            self.afs = __class__.get_afs(self, bank_data)

    def get_start_date(date, previous_date, bank_data) -> datetime:
        data = list()

        if previous_date:
            data = list(
                filter(lambda x: 
                    datetime.strptime(x['start'], "%Y-%m-%d") <= date and 
                    datetime.strptime(x['end'], "%Y-%m-%d") >= date and 
                    datetime.strptime(x['start'], "%Y-%m-%d") >= previous_date
                , bank_data['profit'])
            )
        else:
            data = list(
                filter(lambda x: 
                    datetime.strptime(x['start'], "%Y-%m-%d") <= date and 
                    datetime.strptime(x['end'], "%Y-%m-%d") >= date
                , bank_data['profit'])
            )

        if len(data) > 0:
            return datetime.strptime(data[0]['start'], "%Y-%m-%d")
        
        return None
    
    def get_end_date(date, previous_date, bank_data) -> datetime:
        data = list()
        
        if previous_date:
            data = list(
                filter(lambda x: 
                    datetime.strptime(x['start'], "%Y-%m-%d") <= date and 
                    datetime.strptime(x['end'], "%Y-%m-%d") >= date and 
                    datetime.strptime(x['start'], "%Y-%m-%d") >= previous_date
                , bank_data['profit'])
            )
        else:
            data = list(
                filter(lambda x: 
                    datetime.strptime(x['start'], "%Y-%m-%d") <= date and 
                    datetime.strptime(x['end'], "%Y-%m-%d") >= date
                , bank_data['profit'])
            )

        if len(data) > 0:
            return datetime.strptime(data[0]['end'], "%Y-%m-%d")
        
        return None

    def count_return(self, stock_return):
        if (stock_return >= 0.1 or stock_return <= -0.1):
            self.stock_return += 1

    def set_extreme_interest_rate(self, interest_rate):
        if self.lowest_interest_rate > interest_rate:
            self.lowest_interest_rate = interest_rate

        if self.highest_interest_rate < interest_rate:
            self.highest_interest_rate = interest_rate
    
    def set_last_interest_rate(self, interest_rate):
        self.last_interest_rate = interest_rate
    
    def get_other_income(self, bank_data, sum_other_income) -> float:
        other_income = list(filter(lambda x: x['start'] == self.start.strftime('%Y-%m-%d') and x['end'] == self.end.strftime('%Y-%m-%d'), bank_data['other_income']))

        if len(other_income) > 0:
            if self.quarter == 'Q4':
                return other_income[0]['val'] - sum_other_income
            else:
                return other_income[0]['val']
        
        return 0
    
    def get_profit(self, bank_data, sum_profit) -> float:
        profit = list(filter(lambda x: x['start'] == self.start.strftime('%Y-%m-%d') and x['end'] == self.end.strftime('%Y-%m-%d'), bank_data['profit']))

        if len(profit) > 0:
            if self.quarter == 'Q4':
                return profit[0]['val'] - sum_profit
            else:
                return profit[0]['val']
        
        return 0
    
    def get_afs(self, bank_data) -> float:
        assets_for_sale = list(filter(lambda x: x['end'] == self.end.strftime('%Y-%m-%d'), bank_data['assets_for_sale']))

        if len(assets_for_sale) > 0:
            return assets_for_sale[0]['val']
        
        return 0

    def calculate_margin(self) -> float:
        if (self.other_income != 0 and self.profit != 0):
            return self.other_income / self.profit
        
        return 0
    
    def calculate_afs(self) -> float:
        if self.afs > 0:
            return np.log(self.afs)
        
        return 0

    def convert_to_df(self) -> pd.DataFrame:
        return pd.DataFrame({
            "Ticker" : [self.ticker],
            "Year" : [self.year],
            "Quarter" : [self.quarter],
            "Start" : [self.start],
            "End" : [self.end],
            "Return" : [self.stock_return],
            "Extreme_Interest_Rate" : [self.highest_interest_rate - self.lowest_interest_rate],
            "Period_Interest_Rate" : [self.last_interest_rate - self.first_interest_rate],
            "Margin" : [self.calculate_margin()],
            "Profit" : [self.profit / 1000],
            "Other_Income" : [self.other_income / 1000],
            "AFS" : [self.calculate_afs()]
        })