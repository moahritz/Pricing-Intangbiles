"
OK, holy fuck let's try this again without losing literally 2 days worth of work.

All of the relevant Betas should be constructed in this file (that's a lot).

The content is structured as follows
-functions
-data
-beta production
-graphical illustration/table

for each section


-> safe often and proper on github!!!!!!!!!!!!!!

"

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
### 1. OLS REGRESSIONS
###

#the functions
estimate_ff5.ols <- function(data, min_obs = 1) {
  if (nrow(data) < min_obs) {
    betas <- rep(NA, 5)
  } else {
    fit <- lm(ret_excess ~ mkt_excess + smb + hml + rmw + cma, data = data)
    betas <- as.numeric(coefficients(fit)[2:6])
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

###
## 1.1 FF5

data1 <- tbl(int,"factors + crsp FULL") |>
  select(permno, industry, month, ret_excess, mkt_excess,smb, hml, rmw, cma)|>
  collect()

data1.nested <- data1 |>
  nest(data = c(month, ret_excess, mkt_excess, smb, hml, rmw, cma))
data1.nested

beta_ff5.ols <- data1.nested |>
  mutate(beta = future_map(
    data, ~ roll_ff5.ols(., months = 36, min_obs = 24)
  )) |>
  unnest(c(beta)) |>
  select(permno, month, mkt_excess, smb, hml, rmw, cma) |>
  drop_na()


beta_ff5.ols <- beta_ff5.ols |>
  rename(mkt_FF5.OLS = mkt_excess, smb_FF5.OLS = smb, hml_FF5.OLS = hml, rmw_FF5.OLS= rmw, cma_FF5.OLS = cma)



##
# 1.2 INT (A) [downloaded HML_INT, and RMW "new"]


data2 <- tbl(int,"factors + crsp FULL") |>
  select(permno, industry, month, ret_excess, mkt_excess,smb, hml_int, rmw_int, cma_int)|>
  collect()

data2 <- data2|>
  rename(hml = hml_int, rmw = rmw_int, cma = cma_int)

data2.nested <- data2 |>
  nest(data = c(month, ret_excess, mkt_excess, smb, hml, rmw, cma))
data2.nested

beta_int.ols <- data2.nested |>
  mutate(beta = future_map(
    data, ~ roll_ff5.ols(., months = 36, min_obs = 24)
  )) |>
  unnest(c(beta)) |>
  select(permno, month, mkt_excess, smb, hml, rmw, cma) |>
  drop_na()


beta_int.ols <- beta_int.ols |>
  rename(mkt_INT.OLS = mkt_excess, smb_INT.OLS = smb, hml_INT.OLS = hml, rmw_INT.OLS = rmw, cma_INT.OLS = cma)


beta2 <- beta_ff5.ols |>
  inner_join(beta_int.ols, by = c("permno","month"))


dbWriteTable(int,
             "BETAS",
             value = beta2,
             overwrite = TRUE
)






library(gmm)




###
### 2. GMM Regressions
###



# Function to define moment conditions for GMM
gmm_moments <- function(theta, data) {
  with(data, {
    e <- ret_excess - (theta[1] * mkt_excess + theta[2] * smb + theta[3] * hml + theta[4] * rmw + theta[5] * cma)
    m <- cbind(mkt_excess * e, smb * e, hml * e, rmw * e, cma * e)
    return(m)
  })
}

# Function to estimate GMM parameters
estimate_ff5_gmm <- function(data, min_obs = 1) {
  if (nrow(data) < min_obs) {
    betas <- rep(NA, 5)
  } else {
    theta_init <- rep(0, 5)  # Initial parameter guesses
    fit <- gmm(gmm_moments, data = data, x0 = theta_init)
    betas <- coef(fit)
  }
  return(betas)
}



# Function to apply rolling window GMM estimation
roll_ff5_gmm <- function(data, months, min_obs) {
  data <- data %>%
    arrange(month)
  
  betas <- slide_period_dfr(
    .x = data,
    .i = data$month,
    .period = "month",
    .f = ~tibble(
      mkt_excess = estimate_ff5_gmm(., min_obs)[1],
      smb = estimate_ff5_gmm(., min_obs)[2],
      hml = estimate_ff5_gmm(., min_obs)[3],
      rmw = estimate_ff5_gmm(., min_obs)[4],
      cma = estimate_ff5_gmm(., min_obs)[5]
    ),
    .before = months - 1,
    .complete = FALSE
  )
  
  betas <- betas %>%
    mutate(month = unique(data$month)) %>%
    select(month, everything()) # Ensure the month column is included and first
  
  return(betas)
}


# Assuming beta_ff5.gmm and beta_int.gmm have columns like permno, month, and factors like mkt_excess, smb, hml, rmw, cma

# Apply rolling GMM for each group


#######################################


####
#### FAMA MACBETH STUFF
####
library(tidyverse)
library(RSQLite)
library(sandwich)
library(broom)


###
### 1. FF5

crsp.ols <- tbl(int, "crsp_monthly") |>
  select(permno, month, ret_excess) |>
  collect()

beta_ff.ols <- tbl(int, "BETAS") |>
  select(month, permno, mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS) |>
  collect()


data_fama_macbeth_ff <- beta_ff.ols |>
  left_join(crsp.ols, by = c("permno", "month")) |>
  left_join(crsp.ols |>
              select(permno, month, ret_excess_lead = ret_excess) |>
              mutate(month = month %m-% months(1)), #Adjusts the month column by subtracting one month. This effectively shifts the ret_excess_lead value to the previous month.
            by = c("permno", "month")
  ) |>
  select(permno, month, ret_excess_lead, mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS) |>
  drop_na()


risk_premiums_ff <- data_fama_macbeth_ff |>
  nest(data = c(ret_excess_lead,mkt_FF5.OLS, smb_FF5.OLS, hml_FF5.OLS, rmw_FF5.OLS, cma_FF5.OLS, permno)) |>
  mutate(estimates = map(
    data,
    ~ tidy(lm(ret_excess_lead ~ mkt_FF5.OLS+ smb_FF5.OLS+ hml_FF5.OLS+ rmw_FF5.OLS+ cma_FF5.OLS, data = .x))
  )) |>
  unnest(estimates)

price_of_risk_ff <- risk_premiums_ff |>
  group_by(factor = term) |>
  summarize(
    risk_premium.ff = mean(estimate) * 100,
    t_statistic.ff = mean(estimate) / sd(estimate) * sqrt(n())
  )



regressions_for_newey_west <- risk_premiums |>
  select(month, factor = term, estimate) |>
  nest(data = c(month, estimate)) |>
  mutate(
    model = map(data, ~ lm(estimate ~ 1, .)),
    mean = map(model, tidy)
  )

price_of_risk_newey_west <- regressions_for_newey_west |>
  mutate(newey_west_se = map_dbl(model, ~ sqrt(NeweyWest(.)))) |>
  unnest(mean) |>
  mutate(t_statistic_newey_west = estimate / newey_west_se) |>
  select(factor,
         risk_premium = estimate,
         t_statistic_newey_west
  )

left_join(price_of_risk,
          price_of_risk_newey_west |>
            select(factor, t_statistic_newey_west),
          by = "factor"
)




###
### 2. INT

beta_int.ols <- tbl(int, "BETAS") |>
  select(month, permno, mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS) |>
  collect()


data_fama_macbeth_int <- beta_int.ols |>
  left_join(crsp.ols, by = c("permno", "month")) |>
  left_join(crsp.ols |>
              select(permno, month, ret_excess_lead = ret_excess) |>
              mutate(month = month %m-% months(1)), #Adjusts the month column by subtracting one month. This effectively shifts the ret_excess_lead value to the previous month.
            by = c("permno", "month")
  ) |>
  select(permno, month, ret_excess_lead, mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS) |>
  drop_na()


risk_premiums_int <- data_fama_macbeth_int |>
  nest(data = c(ret_excess_lead,mkt_INT.OLS, smb_INT.OLS, hml_INT.OLS, rmw_INT.OLS, cma_INT.OLS, permno)) |>
  mutate(estimates = map(
    data,
    ~ tidy(lm(ret_excess_lead ~ mkt_INT.OLS+ smb_INT.OLS+ hml_INT.OLS+ rmw_INT.OLS+ cma_INT.OLS, data = .x))
  )) |>
  unnest(estimates)

price_of_risk_int <- risk_premiums_int |>
  group_by(factor = term) |>
  summarize(
    risk_premium.int = mean(estimate) * 100,
    t_statistic.int = mean(estimate) / sd(estimate) * sqrt(n())
  )









#######################################################################



































factors_ff3_monthly_raw <- download_french_data("Fama/French 3 Factors")
factors_ff3_monthly <- factors_ff3_monthly_raw$subsets$data[[1]] |>
  mutate(
    month = floor_date(ymd(str_c(date, "01")), "month"),
    across(c(RF, `Mkt-RF`, SMB, HML), ~as.numeric(.) / 100),
    .keep = "none"
  ) |>
  rename_with(str_to_lower) |>
  rename(mkt_excess = `mkt-rf`) |> 
  filter(month >= start_date & month <= end_date)

factors_ff3_daily_raw <- download_french_data("Fama/French 3 Factors [Daily]")

factors_ff3_daily <- factors_ff3_daily_raw$subsets$data[[1]] |>
  mutate(
    date = ymd(date),
    across(c(RF, `Mkt-RF`, SMB, HML), ~as.numeric(.) / 100),
    .keep = "none"
  ) |>
  rename_with(str_to_lower) |>
  rename(mkt_excess = `mkt-rf`) |>
  filter(date >= start_date & date <= end_date)

dbWriteTable(tidy_finance,
             "factors_ff3_monthly",
             value = factors_ff3_monthly,
             overwrite = TRUE
)



dbListTables(tidy_finance)



crsp_monthly <- tbl(tidy_finance, "crsp_monthly") |>
  select(permno, month, industry, ret_excess) |>
  collect()

factors_ff3_monthly <- tbl(tidy_finance, "factors_ff3_monthly") |>
  select(month, mkt_excess) |>
  collect()

crsp_monthly <- crsp_monthly |>
  left_join(factors_ff3_monthly, join_by(month))





#in order to estimate the capm regression coefficients r_{exc} = \alpha + \beta * r_{exc_mkt} + \epsilon


fit <- lm(ret_excess ~ mkt_excess,
          data = crsp_monthly |>
            filter(permno == "14593")
)

summary(fit)


###
#### rolling window estimation
###
estimate_capm <- function(data, min_obs = 1) {
  if (nrow(data) < min_obs) {
    beta <- as.numeric(NA)
  } else {
    fit <- lm(ret_excess ~ mkt_excess, data = data)
    beta <- as.numeric(coefficients(fit)[2])
  }
  return(beta)
}

roll_capm_estimation <- function(data, months, min_obs) {
  data <- data |>
    arrange(month)
  
  betas <- slide_period_vec(
    .x = data,
    .i = data$month,
    .period = "month",
    .f = ~ estimate_capm(., min_obs),
    .before = months - 1,
    .complete = FALSE
  )
  
  return(tibble(
    month = unique(data$month),
    beta = betas
  ))
}


#what exactly does the tribble do, ie where does it take the data from?
examples <- tribble(
  ~permno, ~company,
  14593, "Apple",
  10107, "Microsoft",
  93436, "Tesla",
  17778, "Berkshire Hathaway"
)

beta_example <- crsp_monthly |>
  filter(permno == examples$permno[1]) |>
  mutate(roll_capm_estimation(pick(everything()), months = 60, min_obs = 15)) |>
  drop_na()
beta_example


#what is a good time window for the rolling regression?

beta_examples <- crsp_monthly |>
  inner_join(examples, join_by(permno)) |>
  group_by(permno) |>
  mutate(roll_capm_estimation(pick(everything()), months = 36, min_obs = 15)) |>
  ungroup() |>
  select(permno, company, month, beta) |>
  drop_na()

beta_examples |>
  ggplot(aes(
    x = month, 
    y = beta, 
    color = company,
    linetype = company)) +
  geom_line() +
  labs(
    x = NULL, y = NULL, color = NULL, linetype = NULL,
    title = "Monthly beta estimates for example stocks using 5 years of data"
  )



####
#### PARALLELIZATION
####


#Remember that we have to perform rolling-window estimations across all stocks and time periods. However, this estimation problem is an ideal scenario to employ the power of parallelization. Parallelization means that we split the tasks which perform rolling-window estimations across different workers (or cores on your local machine).

crsp_monthly_nested <- crsp_monthly |>
  nest(data = c(month, ret_excess, mkt_excess))
crsp_monthly_nested

# use roll_capm_estimation() for each stock -> ideal case for map()

crsp_monthly_nested |>
  inner_join(examples, join_by(permno)) |>
  mutate(beta = map(
    data,
    ~ roll_capm_estimation(., months = 60, min_obs = 48)
  )) |>
  unnest(beta) |>
  select(permno, month, beta_monthly = beta) |>
  drop_na()


n_cores = availableCores() - 1
plan(multisession, workers = n_cores)

#future_map = map but for asynchronous processes!!
beta_monthly <- crsp_monthly_nested |>
  mutate(beta = future_map(
    data, ~ roll_capm_estimation(., months = 60, min_obs = 48)
  )) |>
  unnest(c(beta)) |>
  select(permno, month, beta_monthly = beta) |>
  drop_na()

crsp_monthly |>
  left_join(beta_monthly, join_by(permno, month)) |>
  drop_na(beta_monthly) |>
  group_by(industry, permno) |>
  summarize(beta = mean(beta_monthly), 
            .groups = "drop") |>
  ggplot(aes(x = reorder(industry, beta, FUN = median), y = beta)) +
  geom_boxplot() +
  coord_flip() +
  labs(
    x = NULL, y = NULL,
    title = "Firm-specific beta distributions by industry"
  )


beta_monthly |>
  drop_na(beta_monthly) |>
  group_by(month) |>
  reframe(
    x = quantile(beta_monthly, seq(0.1, 0.9, 0.1)),
    quantile = 100 * seq(0.1, 0.9, 0.1)
  ) |>
  ggplot(aes(
    x = month, 
    y = x, 
    color = as_factor(quantile),
    linetype = as_factor(quantile)
  )) +
  geom_line() +
  labs(
    x = NULL, y = NULL, color = NULL, linetype = NULL,
    title = "Monthly deciles of estimated betas",
  )





dbWriteTable(tidy_finance,
             "CAPM_beta_monthly",
             value = beta_monthly,
             overwrite = TRUE
)


























































### Plausibility tests for Betas (ad data preparation etc.)

beta_long <- crsp_monthly |>
  left_join(beta_monthly, join_by(permno, month)) |>
  pivot_longer(cols = beta_monthly)

beta_long |>
  group_by(month, name) |>
  summarize(share = sum(!is.na(value)) / n(), 
            .groups = "drop") |>
  ggplot(aes(
    x = month, 
    y = share, 
    color = name,
    linetype = name
  )) +
  geom_line() +
  scale_y_continuous(labels = percent) +
  labs(
    x = NULL, y = NULL, color = NULL, linetype = NULL,
    title = "Monthly share of securities with beta estimates"
  ) +
  coord_cartesian(ylim = c(0, 1))


beta_long |>
  select(name, value) |>
  drop_na() |>
  group_by(name) |>
  summarize(
    mean = mean(value),
    sd = sd(value),
    min = min(value),
    q05 = quantile(value, 0.05),
    q50 = quantile(value, 0.50),
    q95 = quantile(value, 0.95),
    max = max(value),
    n = n()
  )



#check for correlation of different estimators! (does obviously not work right here because of missing daily data, but ykwim)

beta |>
  select(beta_daily, beta_monthly) |>
  cor(use = "complete.obs")







####
#### FAMA MACBETH STUFF
####




library(tidyverse)
library(RSQLite)
library(sandwich)
library(broom)




crsp_monthly <- tbl(tidy_finance, "crsp_monthly") |>
  select(permno, gvkey, month, ret_excess, mktcap) |>
  collect()

compustat <- tbl(tidy_finance, "compustat") |>
  select(datadate, gvkey, be) |>
  collect()

beta <- tbl(tidy_finance, "CAPM_beta_monthly") |>
  select(month, permno, beta_monthly) |>
  collect()


characteristics <- compustat |>
  mutate(month = floor_date(ymd(datadate), "month")) |>
  left_join(crsp_monthly, by = c("gvkey", "month")) |>
  left_join(beta, by = c("permno", "month")) |>
  transmute(gvkey,
            bm = be / mktcap,
            log_mktcap = log(mktcap),
            beta = beta_monthly,
            sorting_date = month %m+% months(6)
  )

data_fama_macbeth <- crsp_monthly |>
  left_join(characteristics, by = c("gvkey", "month" = "sorting_date")) |>
  group_by(permno) |>
  arrange(month) |>
  fill(c(beta, bm, log_mktcap), .direction = "down") |>
  ungroup() |>
  left_join(crsp_monthly |>
              select(permno, month, ret_excess_lead = ret_excess) |>
              mutate(month = month %m-% months(1)),
            by = c("permno", "month")
  ) |>
  select(permno, month, ret_excess_lead, beta, log_mktcap, bm) |>
  drop_na()




risk_premiums <- data_fama_macbeth |>
  nest(data = c(ret_excess_lead, beta, log_mktcap, bm, permno)) |>
  mutate(estimates = map(
    data,
    ~ tidy(lm(ret_excess_lead ~ beta + log_mktcap + bm, data = .x))
  )) |>
  unnest(estimates)

price_of_risk <- risk_premiums |>
  group_by(factor = term) |>
  summarize(
    risk_premium = mean(estimate) * 100,
    t_statistic = mean(estimate) / sd(estimate) * sqrt(n())
  )





regressions_for_newey_west <- risk_premiums |>
  select(month, factor = term, estimate) |>
  nest(data = c(month, estimate)) |>
  mutate(
    model = map(data, ~ lm(estimate ~ 1, .)),
    mean = map(model, tidy)
  )

price_of_risk_newey_west <- regressions_for_newey_west |>
  mutate(newey_west_se = map_dbl(model, ~ sqrt(NeweyWest(.)))) |>
  unnest(mean) |>
  mutate(t_statistic_newey_west = estimate / newey_west_se) |>
  select(factor,
         risk_premium = estimate,
         t_statistic_newey_west
  )

left_join(price_of_risk,
          price_of_risk_newey_west |>
            select(factor, t_statistic_newey_west),
          by = "factor"
)
