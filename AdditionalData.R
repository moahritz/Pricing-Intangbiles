## Adding additional data, like the int factors by Wang or the Liquidity factor of LIQ






library(tidyverse)
library(scales)
library(RPostgres)
library(RSQLite)
library(frenchdata)


int<- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)
dbListTables(int)


ff5 <- tbl(int, "factors_ff5_monthly_frenchdata") |>
  select(month, mkt_excess, smb, hml, rmw, cma) |>
  collect()
factors_replicated <- tbl(int, "factors_ff5_replicated") |>
  select(month, smb_replicated, hml_replicated, rmw_replicated, cma_replicated) |>
  collect()
factors_int <- tbl(int, "intangible factors")|>
  select(month, smb_replicated, hml_int_replicated, rmw_int, rmw_intOLD, cma_int) |>
  collect()


test <- ff5 |>
  inner_join(factors_replicated, join_by(month)) |>
  inner_join(factors_int, join_by(month)) |>
  mutate(
    across(c(smb_replicated.x,smb_replicated.y, hml_replicated, 
             rmw_replicated, cma_replicated,hml_int_replicated, rmw_int, rmw_intOLD, cma_int), ~round(., 4))
  )
test <- subset(test, month <= as.Date("2022-12-01"))

hml_int_factors <- read_csv("data/int_factors_Wang.csv")
hml_int <- hml_int_factors[,1:2]
colnames(hml_int) <- c("month", "hml_int")
hml_int <- subset(hml_int, month >= as.Date("1996-07-01"))

liq <- read_csv("data/Liquidity_Factor.csv")
liq <- subset(liq, month <= as.Date("2022-12-01"))
liq <- subset(liq, month >= as.Date("1996-07-01"))
test <- test |>
  inner_join(liq, join_by(month))

test <- test |>
  mutate(Date = format(month, "%Y-%m")) |>
  inner_join(hml_int |> mutate(Date = format(month, "%Y-%m")), join_by(Date)) |>
  select(-Date, -month.y, -smb_replicated.y)



model_1 <- lm(LiqTrad~mkt_excess + smb_replicated.x + hml_replicated + rmw_replicated + cma_replicated, data = test)
summary(model_1)
model_2 <- lm(LiqTrad~mkt_excess + smb_replicated.x + hml_int_replicated + rmw_int + cma_int, data = test)
summary(model_2)
model_3 <- lm(LiqTrad ~mkt_excess + smb_replicated.x + hml_int + rmw_intOLD + cma_int, data = test)
summary(model_3)


test <- test |>
  arrange(month.x) |>
  mutate( hml_rep_diff = hml_int_replicated - hml,
          hml_diff = hml_int - hml,
          rmw_diff = rmw_int - rmw,
          rmwOLD_diff = rmw_intOLD - rmw,
          cma_diff = cma_int - cma)
  
  
model_4 <- lm(LiqTrad ~ hml_rep_diff + rmw_diff + cma_diff, data = test)
summary(model_4)

