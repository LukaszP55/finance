import os
import pandas as pd
from datetime import datetime

class Storage:
    @staticmethod
    def save_results_to_excel(data):
        """Saves results to an Excel file in the 'results' folder with a timestamped filename."""
        
        folder = "results"
        os.makedirs(folder, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{folder}/portfolio_results_{timestamp}.xlsx"
        data.to_excel(filename, index=False)
        print(f"Results saved to {filename}")
