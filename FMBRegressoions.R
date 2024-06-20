library(tidyverse)
library(RSQLite)
library(sandwich)
library(broom)
library(gmm)
library(tidyverse)
library(RSQLite)
library(scales)
library(slider)
library(furrr)
library(gmm)


###
### SET-UP

int <- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)

#set up for parallelization
n_cores = availableCores() - 1
plan(multisession, workers = n_cores)


###
### 1. FF5

data <- tbl(int, "factors + crsp FULL") |>
  collect()
head(data)

data1 <- data |>
  select(-permno, -ret_excess,)
data1 <- distinct(data1)

crsp.ols <- data1 |>
  select(industry, month, indPF_ret) 

beta_ff.ols <- tbl(int, "BETAS") |>
  select(month, industry, mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS) |>
  collect()


data_fama_macbeth_ff <- beta_ff.ols |>
  left_join(crsp.ols, by = c("industry", "month")) |>
  left_join(crsp.ols |>
              select(industry, month, indPF_ret_lead = indPF_ret) |>
              mutate(month = month %m-% months(1)), #Adjusts the month column by subtracting one month. This effectively shifts the ret_excess_lead value to the previous month.
            by = c("industry", "month")
  ) |>
  select(industry, month, indPF_ret_lead, mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS) |>
  drop_na()

risk_premiums_ff1 <- data_fama_macbeth_ff |>
  group_by(industry) |>
  nest() |>
  mutate(estimates = map(
    data, ~ tidy(lm(indPF_ret_lead ~ mkt_FF5.OLS + smb_FF5.OLS + hml_FF5.OLS + rmw_FF5.OLS + cma_FF5.OLS, data = .x))
  )) |>
  unnest(estimates)



price_of_risk_ff1 <- risk_premiums_ff1 |>
  group_by(factor = term) |>
  summarize(
    risk_premium.ff = mean(estimate) * 100,
    t_statistic.ff = mean(estimate) / sd(estimate) * sqrt(n())
  )


regressions_for_newey_west_ff1 <- risk_premiums_ff1 |>
  select(industry, factor = term, estimate) |>
  nest(data = c(industry, estimate)) |>
  mutate(
    model = map(data, ~ lm(estimate ~ 1, .)),
    mean = map(model, tidy)
  )

price_of_risk_newey_west_ff1 <- regressions_for_newey_west_ff1 |>
  mutate(newey_west_se = map_dbl(model, ~ sqrt(NeweyWest(.)))) |>
  unnest(mean) |>
  mutate(t_statistic_newey_west_ff = estimate / newey_west_se) |>
  select(factor,
         risk_premium = estimate,
         t_statistic_newey_west_ff
  )

ff_premium <- left_join(price_of_risk_ff1,
          price_of_risk_newey_west_ff1 |>
            select(factor, t_statistic_newey_west_ff),
          by = "factor"
)




###
### 2. INT

beta_int.ols <- tbl(int, "BETAS") |>
  select(month, industry, mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS) |>
  collect()


data_fama_macbeth_int <- beta_int.ols |>
  left_join(crsp.ols, by = c("industry", "month")) |>
  left_join(crsp.ols |>
              select(industry, month, indPF_ret_lead.int = indPF_ret) |>
              mutate(month = month %m-% months(1)), #Adjusts the month column by subtracting one month. This effectively shifts the indPF_ret_lead value to the previous month.
            by = c("industry", "month")
  ) |>
  select(industry, month, indPF_ret_lead.int, mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS) |>
  drop_na()


risk_premiums_int <- data_fama_macbeth_int |>
  nest(data = c(indPF_ret_lead.int,mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS, industry)) |>
  mutate(estimates = map(
    data,
    ~ tidy(lm(indPF_ret_lead.int ~ mkt_INT.OLS+ smb_INT.OLS+ hml_INT.OLS+ rmw_INT.OLS+ cma_INT.OLS, data = .x))
  )) |>
  unnest(estimates)


price_of_risk_int <- risk_premiums_int |>
  group_by(factor = term) |>
  summarize(
    risk_premium.int = mean(estimate) * 100,
    t_statistic.int = mean(estimate) / sd(estimate) * sqrt(n())
  )



regressions_for_newey_west_int <- risk_premiums_int |>
  select(month, factor = term, estimate) |>
  nest(data = c(month, estimate)) |>
  mutate(
    model = map(data, ~ lm(estimate ~ 1, .)),
    mean = map(model, tidy)
  )

price_of_risk_newey_west_int <- regressions_for_newey_west_int |>
  mutate(newey_west_se = map_dbl(model, ~ sqrt(NeweyWest(.)))) |>
  unnest(mean) |>
  mutate(t_statistic_newey_west_int = estimate / newey_west_se) |>
  select(factor,
         risk_premium = estimate,
         t_statistic_newey_west_int
  )

int_premium <- left_join(price_of_risk_int,
          price_of_risk_newey_west_int |>
            select(factor, t_statistic_newey_west_int),
          by = "factor"
)

