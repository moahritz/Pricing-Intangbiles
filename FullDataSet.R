library(tidyverse)
library(RSQLite)
library(sandwich)
library(broom)
library(scales)
library(slider)
library(furrr)
library(frenchdata)

int <- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)

dbListTables(int)

crsp <- tbl(int, "crsp_monthly") |>
  select(permno, month, industry, ret_excess) |>
  collect()
crsp <- subset(crsp, month <= as.Date("2022-12-01"))
crsp <- subset(crsp, month >= as.Date("1996-07-01"))



ff5 <- tbl(int, "factors_ff5_monthly_frenchdata") |>
  select(month, mkt_excess, smb, hml, rmw, cma) |>
  collect()
factors_replicated <- tbl(int, "factors_ff5_replicated") |>
  select(month, smb_replicated, hml_replicated, rmw_replicated, cma_replicated) |>
  collect()
factors_int <- tbl(int, "intangible factors")|>
  select(month, smb_replicated, hml_int_replicated, rmw_int, rmw_intOLD, cma_int) |>
  rename(smb_int_replicated = smb_replicated) |>
  collect()



factors.data <- ff5 |>
  inner_join(factors_replicated, join_by(month)) |>
  inner_join(factors_int, join_by(month)) |>
  mutate(
    across(c(smb_replicated,smb_int_replicated, hml_replicated, 
             rmw_replicated, cma_replicated,hml_int_replicated, rmw_int, rmw_intOLD, cma_int), ~round(., 4))
  )
factors.data <- subset(factors.data, month <= as.Date("2022-12-01"))

hml_int_factors <- read_csv("data/int_factors_Wang.csv")
hml_int <- hml_int_factors[,1:2]
colnames(hml_int) <- c("month", "hml_int")
hml_int <- subset(hml_int, month >= as.Date("1996-07-01"))

liq <- read_csv("data/Liquidity_Factor.csv")
liq <- subset(liq, month <= as.Date("2022-12-01"))
liq <- subset(liq, month >= as.Date("1996-07-01"))
factors.data <- factors.data |>
  inner_join(liq, join_by(month))

factors.data <- factors.data |>
  mutate(Date = format(month, "%Y-%m")) |>
  inner_join(hml_int |> mutate(Date = format(month, "%Y-%m")), join_by(Date)) |>
  select(-Date, -month.y) |>
  rename(month = month.x)


fmb.data <- crsp |>
  left_join(factors.data, join_by(month))


#dbWriteTable(int,
#             "factors + crsp FULL",
#             value = fmb.data,
#             overwrite = TRUE
#)


