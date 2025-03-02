import numpy as np

# Configuration parameters
START_DATE = '2001-01-01'
END_DATE = '2025-12-31'
RISK_FREE_RATE = 0.0375

# Portfolio Tickers and Weights
TICKERS = ["MMM", "BP.L", "C", "T", "DAL", "PSN.L", "CNR.TO", "GSK.L"]
MY_WEIGHTS = np.array([0.1424, 0.1468, 0.2213, 0.0308, 0.0525, 0.1463, 0.1360, 0.1240])