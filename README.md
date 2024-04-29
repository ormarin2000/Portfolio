# Quantitative Analysis and Modeling Projects

## Introduction
Welcome to my repository showcasing my quantitative analysis and modeling projects. In this repository, you'll find implementations of various models and scanners using Python, R, thinkScript, and Pine Script. Below, I briefly introduce two main projects included in this repository.

## Project 1: SARIMA Model of AAPL (R)
- **Description:** Developed a SARIMA (Seasonal Autoregressive Integrated Moving Average) model for analyzing the stock performance of AAPL (Apple Inc.).
- **Methodology:**
  - Used a cross-validation scheme with 8 years of actual data vs 2 for comparison.
  - Transformed data to logarithmic scale to reduce autocorrelation and kurtosis.
  - Implemented SARIMA model with one difference and 2 seasonal moving averages.
- **Conclusion:** The forecast suggests a potential small downtrend or consolidation phase in the coming years. However, analysis of Apple's consolidated statements for the current year indicates a strong improvement in sales and total assets. This leads to the belief that the current performance dip may be short-term, with expected growth to resume once this period passes.

## Project 2: Bollinger Bands Volatility Squeeze Scanner (Python)
- **Description:** Developed a scanner using Python to identify volatility squeeze patterns based on Bollinger Bands for stocks in the S&P500.
- **Features:**
  - Filters stocks based on band width, bands range, volume, upper or lower cross, and 52-week support or resistance break.
  - Provides user input options to sort for long or short signals.
- **Usage:** The scanner assists in identifying potential trading opportunities within the S&P500 by detecting periods of reduced volatility and impending breakout or breakdown scenarios.

## Usage
To utilize the provided projects, clone this repository to your local machine and follow the instructions provided within each project directory.

## Contributing
Contributions and feedback are welcome! Feel free to submit pull requests or open issues for any improvements or suggestions.

## License
This repository is licensed under the [MIT License](LICENSE).

