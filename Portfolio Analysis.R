# Install necessary packages if not already installed
install.packages("tidyverse")
install.packages("quantmod")
install.packages("PortfolioAnalytics")
install.packages("ggplot2")
install.packages("DEoptim")
install.packages("ROI")
install.packages("ROI.plugin.glpk")
install.packages("ROI.plugin.quadprog")

# Load the libraries
library(tidyverse)
library(quantmod)
library(PortfolioAnalytics)
library(ggplot2)
library(DEoptim)
library(ROI)
library(ROI.plugin.glpk)
library(ROI.plugin.quadprog)

# Define the stock symbols and time period
symbols <- c("AAPL", "MSFT", "GOOGL", "AMZN", "TSLA")  # Example stock symbols
start_date <- "2020-01-01"
end_date <- Sys.Date()

# Get historical stock data
get_stock_data <- function(symbols, start_date, end_date) {
  stock_data <- list()
  for (symbol in symbols) {
    stock_data[[symbol]] <- getSymbols(symbol, src = "yahoo", 
                                       from = start_date, to = end_date, 
                                       auto.assign = FALSE)
  }
  return(stock_data)
}

# Load the data
stock_data <- get_stock_data(symbols, start_date, end_date)

# Combine adjusted closing prices into a single data frame
prices <- do.call(merge, lapply(stock_data, Ad))
colnames(prices) <- symbols
head(prices)

# Calculate daily returns
returns <- na.omit(Return.calculate(prices, method = "log"))

# Create a portfolio object
portfolio <- portfolio.spec(assets = colnames(returns))

# Add constraints (e.g., fully invested portfolio)
portfolio <- add.constraint(portfolio, type = "full_investment")
portfolio <- add.constraint(portfolio, type = "long_only")

# Add objective functions (e.g., maximize return and minimize risk)
portfolio <- add.objective(portfolio, type = "return", name = "mean")
portfolio <- add.objective(portfolio, type = "risk", name = "StdDev")

# Generate portfolios for efficient frontier
num_portfolios <- 100
set.seed(123)
random_weights <- matrix(runif(num_portfolios * length(symbols)), ncol = length(symbols))
random_weights <- t(apply(random_weights, 1, function(x) x / sum(x)))

# Calculate portfolio returns and risks
portfolio_returns <- apply(random_weights, 1, function(w) sum(w * colMeans(returns)))
portfolio_risks <- apply(random_weights, 1, function(w) sqrt(t(w) %*% cov(returns) %*% w))

# Create a data frame for plotting
ef_data <- data.frame(
  Risk = portfolio_risks,
  Return = portfolio_returns
)

# Plot the efficient frontier
ggplot(ef_data, aes(x = Risk, y = Return)) +
  geom_line(color = "blue") +
  geom_point(color = "red") +
  labs(title = "Efficient Frontier", x = "Risk (Standard Deviation)", y = "Return") +
  theme_minimal()

# Optimize the portfolio
optimal_portfolio <- optimize.portfolio(returns, portfolio, optimize_method = "ROI", trace = TRUE)

# Display the optimal weights
print(optimal_portfolio$weights)

# Plot the optimal portfolio
optimal_weights <- optimal_portfolio$weights
barplot(optimal_weights, main = "Optimal Portfolio Weights", 
        xlab = "Stocks", ylab = "Weights", col = "lightblue")
