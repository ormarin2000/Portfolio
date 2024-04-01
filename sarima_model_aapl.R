# Install libraries if needed
install.packages('tidyquant')
install.packages('quantmod')
install.packages('stargazer')
install.packages('haven')
install.packages('skedastic')
install.packages('car')
install.packages('datasets')
install.packages('tseries')
install.packages('forecast')
install.packages('TTR')

#Load necessary libraries
library('quantmod')
library('tidyquant')
library('tidyverse')
library('stargazer')
library('haven')
library('car')
library('datasets')
library('tseries')
library('forecast')
library('TTR')
library('lmtest')

#Get the weekly data
aapl_weekly_data <- tq_get('AAPL', periodicity = "weekly")

#Visualize data
aapl_weekly_data

#Get adjusted closing prices
aapl_weekly_data_adjusted <- select(aapl_weekly_data, date, adjusted)
aapl_weekly_data_adjusted

#Visualize it in a candlestick chart
aapl_weekly_data %>%
    ggplot(aes(x = date, y = close)) +
    geom_candlestick(aes(open = open, high = high, low = low, close = close), colour_up = "darkgreen", fill_up = "darkgreen") +
    labs(title = "AAPL Candlestick Chart", y = "Closing Price", x = "") +
    theme_tq()

#Zoom in of the last 52 weeks
weeks_back <- 52

#Adjustment of zoom
end <- as_date("2024-03-01")
aapl_range_60_tbl <- aapl_weekly_data %>%
    tail(weeks_back) %>%
    summarise(
        max_high = max(high),
        min_low  = min(low)
    )

aapl_weekly_data %>%
    ggplot(aes(x = date, y = close)) +
    geom_candlestick(aes(open = open, high = high, low = low, close = close), colour_up = "darkgreen", fill_up = "darkgreen") +
    labs(title = "AAPL Candlestick Chart",
         subtitle = "Zoomed in using coord_x_date",
         y = "Closing Price", x = "") +
    coord_x_date(xlim = c(end - weeks(weeks_back), end),
                 c(aapl_range_60_tbl$min_low, aapl_range_60_tbl$max_high)) +
    theme_tq()

#Creation of time serie
aapl_weekly_data_adjusted.ts <- ts(aapl_weekly_data_adjusted$adjusted, start = c(2014,1), frequency = 52)
class(aapl_weekly_data_adjusted.ts)
plot(aapl_weekly_data_adjusted.ts)

#Check for missing values
sum(is.na(aapl_weekly_data_adjusted.ts))
#Drop any missing values
aapl_weekly_data_adjusted.ts <- na.remove(aapl_weekly_data_adjusted.ts)
#Check
sum(is.na(aapl_weekly_data_adjusted.ts))

#We test whether the data is stationary or not with Augmented Dickey-Fuller Test.
adf.test(aapl_weekly_data_adjusted.ts)
#The data is NOT stationary.

#Checking for autocorrelation with ACF and PACF
acf(aapl_weekly_data_adjusted.ts)
pacf(aapl_weekly_data_adjusted.ts)
#We can see strong autocorrelation in most of the serie.

#Let's check if differences can help us
ndiffs(aapl_weekly_data_adjusted.ts)
aapl_diff <- diff(aapl_weekly_data_adjusted.ts, lag = 1)
#However, we will encounter missing values in the differenced data,
#so they will be replaced with the values from the last observation.
aapl_diff <- na.locf(aapl_diff, na.rm = TRUE, fromLast = TRUE)
plot(aapl_diff)

#We check again for stationarity
adf.test(aapl_diff)
#P-value 0.01, the serie is stationary

#Re-do ACF and PACF
acf(aapl_diff)
pacf(aapl_diff)
#ACF shows a wave pattern, indicating our data might fit an autoregressive model.
#PACF looks great, no major issues on sight.

#We will use a cross validation scheme,
#where we will use 8 years for train dataset
#and the last 2 for test dataset.
#8 years
years <- (52*2)
train_dataset <- aapl_diff %>% head(length(aapl_diff) - years)

#2 years
test_dataset <- aapl_diff %>% tail(years)

plot(train_dataset)

#We will use auto.arima function to iterate over the best models
autoarima_model <- auto.arima(train_dataset, stationary = TRUE, ic = c("aicc", "aic", "bic"),
                          trace = TRUE)
#It returns a possible model with 1 seasonal moving average

summary(autoarima_model)
#Check residuals of the auto.arima model with difference in the data
checkresiduals(autoarima_model)
#According to Ljung-Box test, the residuals are autocorrelated
#Additionally, they have kurtosis in the histogram plot.

#Let's try fixing it with logarithms
#First let's make a copy
aapl_weekly_data_adjusted_logs <- data.frame(aapl_weekly_data_adjusted)
#And convert the data to logarithms
aapl_weekly_data_adjusted_logs$adjusted <- log(aapl_weekly_data_adjusted_logs$adjusted)
head(aapl_weekly_data_adjusted_logs)

#Now create the time serie with the logarithm
aapl_weekly_data_adjusted_logs.ts <- ts(aapl_weekly_data_adjusted_logs$adjusted, start = c(2014,1), frequency = 52)
class(aapl_weekly_data_adjusted_logs.ts)
plot(aapl_weekly_data_adjusted_logs.ts)

#Add the difference
aapl_diff_logs <- diff(aapl_weekly_data_adjusted_logs.ts, lag = 1)
#And replace
aapl_diff_logs <- na.locf(aapl_diff_logs, na.rm = TRUE, fromLast = TRUE)
plot(aapl_diff_logs)

#We repeat the same process but with logs
train_dataset_logs <- aapl_diff_logs %>% head(length(aapl_diff_logs) - years)

#2 years
test_dataset_logs <- aapl_diff_logs %>% tail(years)

#And create the model with auto.arima
autoarima_model_logs <- auto.arima(train_dataset_logs, stationary = TRUE, ic = c("aicc", "aic", "bic"),
                          trace = TRUE)
#This time it suggests a model with 2 seasonal moving averages

summary(autoarima_model_logs)
#Checking residuals
checkresiduals(autoarima_model_logs)
#P-value is more than 0.05, residuals are independent and not autocorrelated.
#Kurtosis has been cotrolled.

#Let's build the model and check the error with our test dataset
model1 <- arima(train_dataset_logs, order = c(0,0,0), seasonal = c(0,0,2))
summary(model1)

forecast1 <- forecast(model1, h = 104)
plot(forecast1)
#Comparing model 1 with test data
comparison_forecast_model1 <- autoplot(forecast1, series = "Model 1", fcol = "red") +
  autolayer(test_dataset_logs, series = "Actual", color = "green") +
  labs(subtitle = "AAPL Stock Price from Jan 2014 -  March 2024",
       y = "Adjusted Closing Price") +
  theme_minimal()

comparison_forecast_model1
#This data has one difference.
#Let's make the model without the difference directly in the data.

#For this, we have to make our train and test data
years <- (52*2)
train_dataset_nodiff <- aapl_weekly_data_adjusted_logs.ts %>% head(length(aapl_diff) - years)

#2 years
test_dataset_nodiff <- aapl_weekly_data_adjusted_logs.ts %>% tail(years)

#Full model from sratch
model2 <- arima(train_dataset_nodiff, order = c(0,1,0), seasonal = c(0,0,2))
summary(model2)

forecast2 <- forecast(model2, h = 104)
plot(main = "Forecast from ARIMA(0,1,0)(0,0,2)",forecast2)
#Comparing model 2 with test data
comparison_forecast_model2 <- autoplot(forecast2, series = "Model 2", fcol = "red") +
  autolayer(test_dataset_nodiff, series = "Actual", color = "green") +
  labs(subtitle = "AAPL Stock Price from Jan 2014 -  March 2024",
       y = "Adjusted Closing Price") +
  theme_minimal()

comparison_forecast_model2
#The model looks great when compared to the actual data.
#Because of the nature of the SARIMA models it tends to go to the mean.

#Let's make our model with the complete data
final_model <- arima(aapl_weekly_data_adjusted_logs.ts, order = c(0,1,0), seasonal = c(0,0,2))
summary(final_model)

#Forecast for the next 2 years
final_forecast <- forecast(final_model, h = 104)
plot(main = "Apple(AAPL) Forecast from ARIMA(0,1,0)(0,0,2)",final_forecast)

# The forecast gives signs of a small downtrend or consolidation phase
# in the next couple of years; this resonates with the recent trend of Apple.
# However, looking at the consolidated statements of the current year,
# Apple has shown a strong improvement in sales and an increment in total assets.
# This makes us believe that the current performance is only short-term
# and it will continue with its expected growth once this period passes.