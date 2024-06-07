library(tidyverse)
library(scales)
library(RPostgres)
library(RSQLite)
library(frenchdata)


int <- dbConnect(
  SQLite(),
  "~/Documents/WU Abgeschlossen/econometrics in finance/ECCE/data/intangible_value_r.sqlite",
  extend_types = TRUE
)
dbListTables(int)


ff5 <- tbl(int, "factors_ff5_monthly_frenchdata") |>
  select(month, smb, hml, rmw, cma) |>
  collect()
ff5$month <- as.Date(ff5$month, origin = "1970-01-01")
cpi <- dbReadTable(int, "cpi_monthly")
cpi$month <- as.Date(cpi$month, origin = "1970-01-01")
crsp <- tbl(int, "crsp_monthly") |>
  select(
    permno, gvkey, month, ret_excess,
    mktcap, mktcap_lag, exchange
  ) |>
  collect()
crsp$month <- as.Date(crsp$month, origin = "1970-01-01")
compustat <- tbl(int, "compustat") |>
  select(
    gvkey, datadate, be, be_int, op,
    op_adj, inv, aag
  ) |>
  collect()
compustat$datadate <- as.Date(compustat$datadate, origin = "1970-01-01")



size <- crsp |>
  filter(month(month) == 6) |>
  mutate(sorting_date = month %m+% months(1)) |>
  select(permno, exchange, sorting_date, size = mktcap)

market_equity <- crsp |>
  filter(month(month) == 12) |>
  mutate(sorting_date = ymd(str_c(year(month) + 1, "0701)"))) |>
  select(permno, gvkey, sorting_date, me = mktcap)

book_to_market <- compustat |>
  mutate(sorting_date = ymd(str_c(year(datadate) + 1, "0701"))) |>
  select(gvkey, sorting_date, be, be_int) |>
  inner_join(market_equity, join_by(gvkey, sorting_date)) |>
  mutate(bm = be / me) |>
  select(permno, sorting_date, me, bm)


sorting_variables <- size |>
  inner_join(
    book_to_market, join_by(permno, sorting_date)
  ) |>
  drop_na() |>
  distinct(permno, sorting_date, .keep_all = TRUE)  #only interested in breakpoints held constant for the entire year => make sure to have single observation pa




assign_portfolio <- function(data, 
                             sorting_variable, 
                             percentiles) {
  breakpoints <- data |>
    filter(exchange == "NYSE") |>
    pull({{ sorting_variable }}) |>
    quantile(
      probs = percentiles,
      na.rm = TRUE,
      names = FALSE
    )
  
  assigned_portfolios <- data |>
    mutate(portfolio = findInterval(
      pick(everything()) |>
        pull({{ sorting_variable }}),
      breakpoints,
      all.inside = TRUE
    )) |>
    pull(portfolio)
  
  return(assigned_portfolios)
}

portfolios <- sorting_variables |>
  group_by(sorting_date) |>
  mutate(
    portfolio_size = assign_portfolio(
      data = pick(everything()),
      sorting_variable = size,
      percentiles = c(0, 0.5, 1)
    ),
    portfolio_bm = assign_portfolio(
      data = pick(everything()),
      sorting_variable = bm,
      percentiles = c(0, 0.3, 0.7, 1)
    )
  ) |>
  ungroup() |> 
  select(permno, sorting_date, 
         portfolio_size, portfolio_bm)


portfolios <- crsp |>
  mutate(sorting_date = case_when(
    month(month) <= 6 ~ ymd(str_c(year(month) - 1, "0701")),
    month(month) >= 7 ~ ymd(str_c(year(month), "0701"))
  )) |>
  inner_join(portfolios, join_by(permno, sorting_date))











other_sorting_variables <- compustat |>
  mutate(sorting_date = ymd(str_c(year(datadate) + 1, "0701"))) |>
  select(gvkey, sorting_date, be, op, inv) |>
  inner_join(market_equity, 
             join_by(gvkey, sorting_date)) |>
  mutate(bm = be / me) |>
  select(permno, sorting_date, me, be, bm, op, inv)

sorting_variables <- size |>
  inner_join(
    other_sorting_variables, 
    join_by(permno, sorting_date)
  ) |>
  drop_na() |>
  distinct(permno, sorting_date, .keep_all = TRUE)












portfolios <- sorting_variables |>
  group_by(sorting_date) |>
  mutate(
    portfolio_size = assign_portfolio(
      data = pick(everything()),
      sorting_variable = size,
      percentiles = c(0, 0.5, 1)
    )) |> 
  group_by(sorting_date, portfolio_size) |> 
  mutate(
    across(c(bm, op, inv), ~assign_portfolio(
      data = pick(everything()), 
      sorting_variable = ., 
      percentiles = c(0, 0.3, 0.7, 1)),
      .names = "portfolio_{.col}"
    )
  ) |>
  ungroup() |> 
  select(permno, sorting_date, 
         portfolio_size, portfolio_bm,
         portfolio_op, portfolio_inv)

portfolios <- crsp |>
  mutate(sorting_date = case_when(
    month(month) <= 6 ~ ymd(str_c(year(month) - 1, "0701")),
    month(month) >= 7 ~ ymd(str_c(year(month), "0701"))
  )) |>
  inner_join(portfolios, join_by(permno, sorting_date))







portfolios_value <- portfolios |>
  group_by(portfolio_size, portfolio_bm, month) |>
  summarize(
    ret = weighted.mean(ret_excess, mktcap_lag), 
    .groups = "drop"
  )

factors_value <- portfolios_value |>
  group_by(month) |>
  summarize(
    hml_replicated = mean(ret[portfolio_bm == 3]) -
      mean(ret[portfolio_bm == 1])
  )




portfolios_profitability <- portfolios |>
  group_by(portfolio_size, portfolio_op, month) |>
  summarize(
    ret = weighted.mean(ret_excess, mktcap_lag), 
    .groups = "drop"
  ) 

factors_profitability <- portfolios_profitability |>
  group_by(month) |>
  summarize(
    rmw_replicated = mean(ret[portfolio_op == 3]) -
      mean(ret[portfolio_op == 1])
  )





portfolios_investment <- portfolios |>
  group_by(portfolio_size, portfolio_inv, month) |>
  summarize(
    ret = weighted.mean(ret_excess, mktcap_lag), 
    .groups = "drop"
  )

factors_investment <- portfolios_investment |>
  group_by(month) |>
  summarize(
    cma_replicated = mean(ret[portfolio_inv == 1]) -
      mean(ret[portfolio_inv == 3])
  )








factors_size <- bind_rows(
  portfolios_value,
  portfolios_profitability,
  portfolios_investment
) |> 
  group_by(month) |>
  summarize(
    smb_replicated = mean(ret[portfolio_size == 1]) -
      mean(ret[portfolio_size == 2])
  )




factors_replicated <- factors_size |>
  full_join(
    factors_value, join_by(month)
  ) |>
  full_join(
    factors_profitability, join_by(month)
  ) |>
  full_join(
    factors_investment, join_by(month)
  )





dbWriteTable(intangible_value,
             "factors_ff5_replicated",
             value = factors_replicated,
             overwrite = TRUE
)








###
###
### Tests
###
###



test <- ff5 |>
  inner_join(factors_replicated, join_by(month)) |>
  mutate(
    across(c(smb_replicated, hml_replicated, 
             rmw_replicated, cma_replicated), ~round(., 4))
  )



model_smb <- lm(smb ~ smb_replicated, data = test)
summary(model_smb)

model_hml <- lm(hml ~ hml_replicated, data = test)
summary(model_hml)

model_rmw <- lm(rmw ~ rmw_replicated, data = test)
summary(model_rmw)

model_cma <- lm(cma ~ cma_replicated, data = test)
summary(model_cma)
























