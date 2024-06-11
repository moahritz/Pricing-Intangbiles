library(tidyverse)
library(scales)
library(RPostgres)
library(RSQLite)
library(frenchdata)

###
###
### Tests
###
###

int<- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)

dbListTables(int)

ff5 <- tbl(int, "factors_ff5_monthly_frenchdata") |>
  select(month, smb, hml, rmw, cma) |>
  collect()
ff5$month <- as.Date(ff5$month, origin = "1970-01-01")
factors_replicated <- tbl(int, "factors_ff5_replicated") |>
  collect()



repr <- ff5 |>
  inner_join(factors_replicated, join_by(month)) |>
  mutate(
    across(c(smb_replicated, hml_replicated, 
             rmw_replicated, cma_replicated), ~round(., 4))
  )



model_smb <- lm(smb ~ smb_replicated, data = repr)
summary(model_smb)

model_hml <- lm(hml ~ hml_replicated, data = repr)
summary(model_hml)

model_rmw <- lm(rmw ~ rmw_replicated, data = repr)
summary(model_rmw)

model_cma <- lm(cma ~ cma_replicated, data = repr)
summary(model_cma)

