import numpy as np
from scipy.stats import norm

class RiskManagement:
    @staticmethod
    def calculate_portfolio_metrics(monthly_returns, weights):
        """Computes portfolio mean return and standard deviation."""
        portfolio_mean = np.dot(monthly_returns.mean(), weights)
        portfolio_cov_matrix = np.dot(weights.T, np.dot(monthly_returns.cov(), weights))
        portfolio_std_dev = np.sqrt(portfolio_cov_matrix)
        return portfolio_mean, portfolio_std_dev

    @staticmethod
    def calculate_var(portfolio_mean, portfolio_std_dev, confidence_level=0.95):
        """Computes Value at Risk (VaR) using normal distribution."""
        return norm.ppf(1 - confidence_level, portfolio_mean, portfolio_std_dev)

    @staticmethod
    def calculate_cvar(portfolio_mean, portfolio_std_dev, confidence_level=0.95):
        """Computes Conditional Value at Risk (CVaR)."""
        alpha = 1 - confidence_level
        z = norm.ppf(confidence_level)
        return portfolio_mean - portfolio_std_dev * (norm.pdf(z) / alpha)

    @staticmethod
    def calculate_var_cvar(monthly_returns, weights):
        """Computes VaR and CVaR at different confidence levels."""
        portfolio_mean, portfolio_std_dev = RiskManagement.calculate_portfolio_metrics(monthly_returns, weights)

        results = {
            'VaR_95': RiskManagement.calculate_var(portfolio_mean, portfolio_std_dev, 0.95),
            'CVaR_95': RiskManagement.calculate_cvar(portfolio_mean, portfolio_std_dev, 0.95),
            'VaR_99': RiskManagement.calculate_var(portfolio_mean, portfolio_std_dev, 0.99),
            'CVaR_99': RiskManagement.calculate_cvar(portfolio_mean, portfolio_std_dev, 0.99),
        }
        return results
