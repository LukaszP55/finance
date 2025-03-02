import pandas as pd
from storage.storage import Storage
from data_ingestion.data_ingestion import DataIngestion
from risk_management.risk_management import RiskManagement
from monitoring.monitoring import PortfolioOptimization
from config.config import START_DATE, END_DATE, RISK_FREE_RATE, TICKERS, MY_WEIGHTS


# Step 1: Download Data and Compute Returns
data = DataIngestion.download_monthly_data(TICKERS, START_DATE, END_DATE)
monthly_returns = DataIngestion.calculate_monthly_returns(data)

# Step 2: Calculate VaR and CVaR
var_cvar_results = RiskManagement.calculate_var_cvar(monthly_returns, MY_WEIGHTS)
print("\nRisk Metrics (VaR & CVaR):", var_cvar_results)

# Step 3: Portfolio Optimization
mean_returns = monthly_returns.mean()
cov_matrix = monthly_returns.cov()

optimal_weights = PortfolioOptimization.optimize_portfolio(mean_returns, cov_matrix, RISK_FREE_RATE)
PortfolioOptimization.compare_portfolios(MY_WEIGHTS, optimal_weights, mean_returns, cov_matrix, RISK_FREE_RATE)

# Step 4: Save Results
top_portfolios = pd.DataFrame({'Tickers': TICKERS, 'My Portfolio Weights': MY_WEIGHTS, 'Optimal Portfolio Weights': optimal_weights * 100})
Storage.save_results_to_excel(top_portfolios)