import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import minimize

class PortfolioOptimization:
    @staticmethod
    def portfolio_performance(weights, mean_returns, cov_matrix):
        """Calculates expected return and volatility of the portfolio."""
        annual_return = np.sum(mean_returns * weights) * 12
        annual_volatility = np.sqrt(np.dot(weights.T, np.dot(cov_matrix, weights))) * np.sqrt(12)
        return annual_return, annual_volatility

    @staticmethod
    def negative_sharpe_ratio(weights, mean_returns, cov_matrix, risk_free_rate):
        """Objective function for maximizing Sharpe ratio."""
        returns, std_dev = PortfolioOptimization.portfolio_performance(weights, mean_returns, cov_matrix)
        return - (returns - risk_free_rate) / std_dev

    @staticmethod
    def optimize_portfolio(mean_returns, cov_matrix, risk_free_rate):
        """Finds the portfolio with the highest Sharpe ratio."""
        num_assets = len(mean_returns)
        constraints = {'type': 'eq', 'fun': lambda x: np.sum(x) - 1}
        bounds = tuple((0.0, 1.0) for _ in range(num_assets))

        result = minimize(
            PortfolioOptimization.negative_sharpe_ratio,
            num_assets * [1. / num_assets],
            args=(mean_returns, cov_matrix, risk_free_rate),
            method='SLSQP',
            bounds=bounds,
            constraints=constraints
        )
        return result.x  # Optimal weights

    @staticmethod
    def compare_portfolios(my_weights, optimal_weights, mean_returns, cov_matrix, risk_free_rate):
        """Compares my portfolio against the optimized one."""
        my_return, my_volatility = PortfolioOptimization.portfolio_performance(my_weights, mean_returns, cov_matrix)
        optimal_return, optimal_volatility = PortfolioOptimization.portfolio_performance(optimal_weights, mean_returns, cov_matrix)

        print("\nPerformance Metrics:")
        print(f"My Portfolio - Return: {my_return:.2%}, Volatility: {my_volatility:.2%}")
        print(f"Optimal Portfolio - Return: {optimal_return:.2%}, Volatility: {optimal_volatility:.2%}")
