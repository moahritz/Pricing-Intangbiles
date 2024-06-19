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


#form industry portfolios:

indu <- tbl(int, "crsp_monthly") |>
  select(month, industry, ret_excess, mktcap) |>
  collect()

indu <- indu |>
  arrange(industry, month)

indu_ret <- indu |>
  group_by(industry, month) |>
  summarise(
    vw_ret_excess = sum(ret_excess * mktcap) / sum(mktcap),
    .groups = 'drop'
  )

indu_ret <- indu_ret |>
  rename(indPF_ret = vw_ret_excess)

# append to large dataset

data <- tbl(int, "factors + crsp FULL") |>
  collect()
head(data)

data1 <-data |>
  left_join(indu_ret, by = c("industry", "month"))

data1 <- data1 |>
  select(-permno, -ret_excess,)
data1 <- distinct(data1)


#dbWriteTable(int,
#             "factors + crsp FULL",
#             value = data1,
#             overwrite = TRUE)




#the functions
estimate_ff5.ols <- function(data, min_obs = 1) {
  if (nrow(data) < min_obs) {
    betas <- rep(NA, 5)
  } else {
    fit <- lm(indPF_ret ~ mkt_excess + smb + hml + rmw + cma + LiqTrad, data = data)
    betas <- as.numeric(coefficients(fit)[2:7])
  }
  return(betas)
}

roll_ff5.ols <- function(data, months, min_obs) {
  data <- data |>
    arrange(month)
  
  betas <- slide_period_dfr(
    .x = data,
    .i = data$month,
    .period = "month",
    .f = ~tibble(
      mkt_excess = estimate_ff5.ols(., min_obs)[1],
      smb = estimate_ff5.ols(., min_obs)[2],
      hml = estimate_ff5.ols(., min_obs)[3],
      rmw = estimate_ff5.ols(., min_obs)[4],
      cma = estimate_ff5.ols(., min_obs)[5],
      LiqTrad = estimate_ff5.ols(., min_obs)[6],
    )
    ,
    .before = months - 1,
    .complete = FALSE
  )
  betas <- betas |>
    mutate(month = unique(data$month))|>
    select(month, everything())
  
  return(betas)
}

#### FF5 Regressions
data2 <- data1|>
  select(industry, month, indPF_ret, mkt_excess, smb, hml, rmw, cma, LiqTrad)

data2.nested <- data2 |>
  nest(data = c(month, indPF_ret, mkt_excess, smb, hml, rmw, cma, LiqTrad))
data2.nested

beta_ff5.ols <- data2.nested |>
  mutate(beta = future_map(
    data, ~ roll_ff5.ols(., months = 36, min_obs = 24)
  )) |>
  unnest(c(beta)) |>
  select(industry, month, mkt_excess, smb, hml, rmw, cma, LiqTrad) |>
  drop_na()

beta_ff5.ols <- beta_ff5.ols |>
  rename(mkt_FF5.OLS = mkt_excess, smb_FF5.OLS = smb, hml_FF5.OLS = hml, rmw_FF5.OLS= rmw, cma_FF5.OLS = cma, LiqTrad_FF5.OLS = LiqTrad)

##### INT Regressions

data3 <- data1|>
  select(industry, month, indPF_ret, mkt_excess, smb, hml_int, rmw_int, cma_int, LiqTrad) |>
    rename(hml = hml_int, rmw = rmw_int, cma = cma_int) 

data3.nested <- data3 |>
  nest(data = c(month, indPF_ret, mkt_excess, smb, hml, rmw, cma, LiqTrad))
data3.nested

beta_int.ols <- data3.nested |>
  mutate(beta = future_map(
    data, ~ roll_ff5.ols(., months = 36, min_obs = 24)
  )) |>
  unnest(c(beta)) |>
  select(industry, month, mkt_excess, smb, hml, rmw, cma, LiqTrad) |>
  drop_na()


beta_int.ols <- beta_int.ols |>
  rename(mkt_INT.OLS = mkt_excess, smb_INT.OLS = smb, hml_INT.OLS = hml, rmw_INT.OLS = rmw, cma_INT.OLS = cma, LiqTrad_INT.OLS = LiqTrad)


beta2 <- beta_ff5.ols |>
  inner_join(beta_int.ols, by = c("industry","month"))


dbWriteTable(int,
             "BETAS",
             value = beta2,
             overwrite = TRUE
)


####
#### FAMA MACBETH STUFF
####



###
### 1. FF5

crsp.ols <- data1 |>
  select(industry, month, indPF_ret) 

beta_ff.ols <- tbl(int, "BETAS") |>
  select(month, industry, mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS, LiqTrad_FF5.OLS) |>
  collect()


data_fama_macbeth_ff <- beta_ff.ols |>
  left_join(crsp.ols, by = c("industry", "month")) |>
  left_join(crsp.ols |>
              select(industry, month, indPF_ret_lead = indPF_ret) |>
              mutate(month = month %m-% months(1)), #Adjusts the month column by subtracting one month. This effectively shifts the ret_excess_lead value to the previous month.
            by = c("industry", "month")
  ) |>
  select(industry, month, indPF_ret_lead, mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS, LiqTrad_FF5.OLS) |>
  drop_na()


risk_premiums_ff <- data_fama_macbeth_ff |>
  nest(data = c(indPF_ret_lead,mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS, LiqTrad_FF5.OLS, industry)) |>
  mutate(estimates = map(
    data,
    ~ tidy(lm(indPF_ret_lead ~ mkt_FF5.OLS+ smb_FF5.OLS+ hml_FF5.OLS+ rmw_FF5.OLS+ cma_FF5.OLS + LiqTrad_FF5.OLS, data = .x))
  )) |>
  unnest(estimates)

price_of_risk_ff <- risk_premiums_ff |>
  group_by(factor = term) |>
  summarize(
    risk_premium.ff = mean(estimate) * 100,
    t_statistic.ff = mean(estimate) / sd(estimate) * sqrt(n())
  )


regressions_for_newey_west_ff <- risk_premiums_ff |>
  select(month, factor = term, estimate) |>
  nest(data = c(month, estimate)) |>
  mutate(
    model = map(data, ~ lm(estimate ~ 1, .)),
    mean = map(model, tidy)
  )

price_of_risk_newey_west_ff <- regressions_for_newey_west |>
  mutate(newey_west_se = map_dbl(model, ~ sqrt(NeweyWest(.)))) |>
  unnest(mean) |>
  mutate(t_statistic_newey_west_ff = estimate / newey_west_se) |>
  select(factor,
         risk_premium = estimate,
         t_statistic_newey_west_ff
  )

left_join(price_of_risk_ff,
          price_of_risk_newey_west_ff |>
            select(factor, t_statistic_newey_west_ff),
          by = "factor"
)




###
### 2. INT

beta_int.ols <- tbl(int, "BETAS") |>
  select(month, industry, mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS, LiqTrad_INT.OLS) |>
  collect()


data_fama_macbeth_int <- beta_int.ols |>
  left_join(crsp.ols, by = c("industry", "month")) |>
  left_join(crsp.ols |>
              select(industry, month, indPF_ret_lead.int = indPF_ret) |>
              mutate(month = month %m-% months(1)), #Adjusts the month column by subtracting one month. This effectively shifts the indPF_ret_lead value to the previous month.
            by = c("industry", "month")
  ) |>
  select(industry, month, indPF_ret_lead.int, mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS, LiqTrad_INT.OLS) |>
  drop_na()


risk_premiums_int <- data_fama_macbeth_int |>
  nest(data = c(indPF_ret_lead.int,mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS, LiqTrad_INT.OLS, industry)) |>
  mutate(estimates = map(
    data,
    ~ tidy(lm(indPF_ret_lead.int ~ mkt_INT.OLS+ smb_INT.OLS+ hml_INT.OLS+ rmw_INT.OLS+ cma_INT.OLS + LiqTrad_INT.OLS, data = .x))
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

left_join(price_of_risk_int,
          price_of_risk_newey_west_int |>
            select(factor, t_statistic_newey_west_int),
          by = "factor"
)

















