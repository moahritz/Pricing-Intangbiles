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
    fit <- lm(indPF_ret ~ mkt_excess + smb + hml + rmw + cma, data = data)
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

#### FF5 Regressions
data2 <- data1|>
  select(industry, month, indPF_ret, mkt_excess, smb, hml, rmw, cma)

data2.nested <- data2 |>
  nest(data = c(month, indPF_ret, mkt_excess, smb, hml, rmw, cma))
data2.nested

beta_ff5.ols <- data2.nested |>
  mutate(beta = future_map(
    data, ~ roll_ff5.ols(., months = 36, min_obs = 24)
  )) |>
  unnest(c(beta)) |>
  select(industry, month, mkt_excess, smb, hml, rmw, cma) |>
  drop_na()

beta_ff5.ols <- beta_ff5.ols |>
  rename(mkt_FF5.OLS = mkt_excess, smb_FF5.OLS = smb, hml_FF5.OLS = hml, rmw_FF5.OLS= rmw, cma_FF5.OLS = cma)

##### INT Regressions

data3 <- data1|>
  select(industry, month, indPF_ret, mkt_excess, smb, hml_int, rmw_int, cma_int) |>
    rename(hml = hml_int, rmw = rmw_int, cma = cma_int) 

data3.nested <- data3 |>
  nest(data = c(month, indPF_ret, mkt_excess, smb, hml, rmw, cma))
data3.nested

beta_int.ols <- data3.nested |>
  mutate(beta = future_map(
    data, ~ roll_ff5.ols(., months = 36, min_obs = 24)
  )) |>
  unnest(c(beta)) |>
  select(industry, month, mkt_excess, smb, hml, rmw, cma) |>
  drop_na()


beta_int.ols <- beta_int.ols |>
  rename(mkt_INT.OLS = mkt_excess, smb_INT.OLS = smb, hml_INT.OLS = hml, rmw_INT.OLS = rmw, cma_INT.OLS = cma)


beta2 <- beta_ff5.ols |>
  inner_join(beta_int.ols, by = c("industry","month"))








