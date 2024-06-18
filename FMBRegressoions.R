library(tidyverse)
library(RSQLite)
library(scales)
library(slider)
library(furrr)

library(frenchdata)

tidy_finance <- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)


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
