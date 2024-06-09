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
  select(month, smb, hml, rmw, cma) |>
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



test <- test |>
  mutate(Date = format(month, "%Y-%m")) |>
  inner_join(hml_int |> mutate(Date = format(month, "%Y-%m")), join_by(Date)) |>
  select(-Date, -month.y, -smb_replicated.y)





model_smb <- lm(smb ~ smb_replicated.x, data = test)
summary(model_smb)


model_hml_int <- lm((hml_int/100)~hml_int_replicated, data = test)
summary(model_hml_int)

test <- test|>
  arrange(month.x) %>%
  mutate(cumulative_hml_int = cumprod(1 + (hml_int/100)),
         cumulative_hml_int_replicated = cumprod((1 + hml_int_replicated)),
         cumulative_hml_replicated = cumprod((1 + hml_replicated)),
         cumulative_hml = cumprod(1+ hml))

ggplot(test, aes(x = month.x)) +
  # geom_line(aes(y = cumulative_hml_int, color = "Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_hml_int_replicated, color = "Replicated Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_hml_int_replicated - cumulative_hml_replicated, color = "Difference between Factors")) +
  geom_line(aes(y = cumulative_hml_replicated, color = "Fama-French factor")) +
  labs(x = "Date", y = "Cumulative Returns", title = "Cumulative Returns of the different HML factors") +
  scale_color_manual("", 
                     breaks = c( "Fama-French factor", "Difference between Factors", "Factor w/ Intangible Adjustment","Replicated Factor w/ Intangible Adjustment"),
                     values = c( "salmon", "darkblue", "red", "lightblue")) +
  theme_minimal()


test <- test|>
  arrange(month.x) %>%
  mutate(cumulative_rmw = cumprod(1 + (rmw)),
         cumulative_rmw_int = cumprod((1 + rmw_int)),
         cumulative_rmw_intOLD = cumprod((1 + rmw_intOLD)),
         cumulative_rmw_replicated = cumprod((1 + rmw_replicated)))



ggplot(test, aes(x = month.x)) +
  geom_line(aes(y = cumulative_rmw_replicated, color = "Fama-French factor")) +
  geom_line(aes(y = cumulative_rmw_int - cumulative_rmw_replicated , color = "Difference between Factors")) +
  geom_line(aes(y = cumulative_rmw_int, color = "Factor w/ Intangible Adjustment")) +
  labs(x = "Date", y = "Cumulative Returns", title = "Cumulative Returns of the different RMW factors") +
  scale_color_manual("", 
                     breaks = c("Fama-French factor", "Difference between Factors", "Factor w/ Intangible Adjustment"),
                     values = c("salmon", "darkblue","lightblue")) +
  theme_minimal()

ggplot(test, aes(x = month.x)) +
  geom_line(aes(y = cumulative_rmw_intOLD, color = "Old Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_rmw_int, color = "Factor w/ Intangible Adjustment")) +
  labs(x = "Date", y = "Cumulative Returns", title = "Difference of Factor Portfolio returns for (un-)adjusted book equity (old)") +
  scale_color_manual("", 
                     breaks = c("Old Factor w/ Intangible Adjustment", "Factor w/ Intangible Adjustment"),
                     values = c("darkblue","lightblue")) +
  theme_minimal()




test <- test|>
  arrange(month.x) %>%
  mutate(cumulative_cma = cumprod(1 + (cma)),
         cumulative_cma_int = cumprod((1 + cma_int)),
         cumulative_cma_replicated = cumprod((1 + cma_replicated)))



###here we see how bad cma actually is! -> once it's actually calculated with be_int, check if it changes the performance!
## here the factor is composed as it is described in the paper, maybe point that out!


ggplot(test, aes(x = month.x)) +
  geom_line(aes(y = cumulative_cma_replicated, color = "Fama-French factor")) +
  geom_line(aes(y = cumulative_cma_int - cumulative_cma_replicated, color = "Difference between Factors")) +
  geom_line(aes(y = cumulative_cma_int, color = "Factor w/ Intangible Adjustment")) +
  labs(x = "Date", y = "Cumulative Returns", title = "Cumulative Returns of the different CMA factors") +
  scale_color_manual("", 
                     breaks = c("Fama-French factor", "Difference between Factors", "Factor w/ Intangible Adjustment"),
                     values = c("salmon", "darkblue", "lightblue")) +
  theme_minimal()



test <- test|>
  arrange(month.x) %>%
  mutate(cumulative_smb = cumprod(1 + (smb)),
         cumulative_smb_replicated.x = cumprod((1 + smb_replicated.x)))



ggplot(test, aes(x = month.x)) +
  geom_line(aes(y = cumulative_smb, color = "Fama-French factor")) +
  geom_line(aes(y = cumulative_smb_replicated.x, color = "Replicated factor")) +
  labs(x = "Date", y = "Cumulative Returns", title = "Cumulative Returns of the different SMB factors") +
  scale_color_manual("", 
                     breaks = c("Fama-French factor", "Replicated factor"),
                     values = c("darkgrey", "lightgrey")) +
  theme_minimal()
