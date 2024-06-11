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


test.plt <- ff5 |>
  inner_join(factors_replicated, join_by(month)) |>
  inner_join(factors_int, join_by(month)) |>
  mutate(
    across(c(smb_replicated.x,smb_replicated.y, hml_replicated, 
             rmw_replicated, cma_replicated,hml_int_replicated, rmw_int, rmw_intOLD, cma_int), ~round(., 4))
  )
test.plt <- subset(test.plt, month <= as.Date("2022-12-01"))

hml_int_factors <- read_csv("data/int_factors_Wang.csv")
hml_int <- hml_int_factors[,1:2]
colnames(hml_int) <- c("month", "hml_int")
hml_int <- subset(hml_int, month >= as.Date("1996-07-01"))

liq <- read_csv("data/Liquidity_Factor.csv")
liq <- subset(liq, month <= as.Date("2022-12-01"))
liq <- subset(liq, month >= as.Date("1996-07-01"))
test.plt <- test.plt |>
  inner_join(liq, join_by(month))

test.plt <- test.plt |>
  mutate(Date = format(month, "%Y-%m")) |>
  inner_join(hml_int |> mutate(Date = format(month, "%Y-%m")), join_by(Date)) |>
  select(-Date, -month.y, -smb_replicated.y)


test.plt <- test.plt|>
  arrange(month.x) %>%
  mutate(cumulative_hml_int = cumprod(1 + (hml_int/100)),
         cumulative_hml_int_replicated = cumprod((1 + hml_int_replicated)),
         cumulative_hml_replicated = cumprod((1 + hml_replicated)),
         cumulative_hml = cumprod(1+ hml))

test.plt <- test.plt|>
  arrange(month.x) %>%
  mutate(cumulative_rmw = cumprod(1 + (rmw)),
         cumulative_rmw_int = cumprod((1 + rmw_int)),
         cumulative_rmw_intOLD = cumprod((1 + rmw_intOLD)),
         cumulative_rmw_replicated = cumprod((1 + rmw_replicated)))

test.plt <- test.plt|>
  arrange(month.x) %>%
  mutate(cumulative_cma = cumprod(1 + (cma)),
         cumulative_cma_int = cumprod((1 + cma_int)),
         cumulative_cma_replicated = cumprod((1 + cma_replicated)))

test.plt <- test.plt|>
  arrange(month.x) %>%
  mutate(cumulative_smb = cumprod(1 + (smb)),
         cumulative_smb_replicated.x = cumprod((1 + smb_replicated.x)))

test.plt <- test.plt|>
  arrange(month.x) |>
  mutate(cumulative_AggLiq = cumprod(1 + (AggLiq)),
         cumulative_LiqInno = cumprod(1 + (LiqInno)),
         cumulative_LiqTrad = cumprod(1 + (LiqTrad)))



model_smb <- lm(smb ~ smb_replicated.x, data = test.plt)
summary(model_smb)


model_hml_int <- lm((hml_int/100)~hml_int_replicated, data = test.plt)
summary(model_hml_int)

#HML Plots
hml.rep_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_hml, color = "Fama-French Factor")) +
  geom_line(aes(y = cumulative_hml_replicated, color = "Replicated Factor")) +
  labs(x = "Date", y = "HML", title = "Cumulative Returns of the Original and the Reproduced Factor") +
  scale_color_manual("", 
                     breaks = c( "Replicated Factor", "Fama-French Factor"),
                     values = c( "salmon", "darkblue")) +
  theme_minimal()


hml.fs_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_hml_int_replicated, color = "Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_hml_replicated, color = "Fama-French factor")) +
  labs(x = "Date", y = "HML", title = "Cumulative Returns of the (Un-)Adjusted HML factors") +
  scale_color_manual("", 
                     breaks = c( "Fama-French factor", "Factor w/ Intangible Adjustment"),
                     values = c( "salmon","lightblue")) +
  theme_minimal()


hml.int_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_hml_int, color = "Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_hml_int_replicated, color = "Replicated Factor w/ Intangible Adjustment")) +
  labs(x = "Date", y = "HML", title = "Cumulative Returns of the different Adjusted HML factors") +
  scale_color_manual("", 
                     breaks = c( "Factor w/ Intangible Adjustment", "Replicated Factor w/ Intangible Adjustment"),
                     values = c( "red", "lightblue")) +
  theme_minimal()




#RMW Plots
rmw.rep_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_rmw, color = "Fama-French factor")) +
  geom_line(aes(y = cumulative_rmw_replicated , color = "Replicated Factor")) +
  labs(x = "Date", y = "RMW", title = "Cumulative Returns of the Original and the Reproduced Factor") +
  scale_color_manual("", 
                     breaks = c("Replicated Factor", "Fama-French factor"),
                     values = c("salmon", "darkblue")) +
  theme_minimal()

rmw.fs_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_rmw_int, color = "Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_rmw_replicated, color = "Fama-French factor")) +
  labs(x = "Date", y = "RMW", title = "Cumulative Returns of the (Un-)Adjusted HML factors") +
  scale_color_manual("", 
                     breaks = c( "Fama-French factor", "Factor w/ Intangible Adjustment"),
                     values = c( "salmon","lightblue")) +
  theme_minimal()

rmw.OLD_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_rmw_int, color = "Factor w/ proper Intangible Adjustment")) +
  geom_line(aes(y = cumulative_rmw_intOLD, color = "Old Factor w/ Intangible Adjustment")) +
  labs(x = "Date", y = "RMW", title = "Cumulative Returns of the different Adjusted RMW factors") +
  scale_color_manual("", 
                     breaks = c( "Factor w/ proper Intangible Adjustment", "Old Factor w/ Intangible Adjustment"),
                     values = c( "lightblue", "red")) +
  theme_minimal()


#CMA Plots

cma.rep_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_cma, color = "Fama-French factor")) +
  geom_line(aes(y = cumulative_cma_replicated , color = "Replicated Factor")) +
  labs(x = "Date", y = "CMA", title = "Cumulative Returns of the Original and the Reproduced Factor") +
  scale_color_manual("", 
                     breaks = c("Replicated Factor", "Fama-French factor"),
                     values = c("salmon", "darkblue")) +
  theme_minimal()
cma.rep_plot
cma.fs_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_cma_int, color = "Factor w/ Intangible Adjustment")) +
  geom_line(aes(y = cumulative_cma_replicated, color = "Fama-French factor")) +
  labs(x = "Date", y = "CMA", title = "Cumulative Returns of the (Un-)Adjusted CMA factors") +
  scale_color_manual("", 
                     breaks = c( "Fama-French factor", "Factor w/ Intangible Adjustment"),
                     values = c( "salmon","lightblue")) +
  theme_minimal()












#SMB Plots

smb.rep_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_smb, color = "Fama-French factor")) +
  geom_line(aes(y = cumulative_smb_replicated.x, color = "Replicated factor")) +
  labs(x = "Date", y = "SMB", title = "Cumulative Returns of the different SMB factors") +
  scale_color_manual("", 
                     breaks = c("Fama-French factor", "Replicated factor"),
                     values = c("darkgrey", "lightgrey")) +
  theme_minimal()










#LIQ Plots
liq.f_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = cumulative_LiqTrad, color = "Traded Liquidity Factor")) +
  labs(x = "Date", y = "Return", title = "Traded Liquidity Factor-µimicking PF Return from Pastor, Stambaugh (2003)") +
  scale_color_manual("", 
                     breaks = c("Traded Liquidity Factor"),
                     values = c("darkgreen")) +
  theme_minimal()

liq.ms_plot <- ggplot(test.plt, aes(x = month.x)) +
  geom_line(aes(y = AggLiq, color = "Aggregate Liquidity")) +
  geom_line(aes(y = LiqInno , color = "Liquidity Innovation")) +
  geom_line(aes(y = LiqTrad, color = "Traded Liquidity Factor")) +
  labs(x = "Date", y = "Liq", title = "Different Liquidity Measures)") +
  scale_color_manual("", 
                     breaks = c("Aggregate Liquidity", "Liquidity Innovation", "Traded Liquidity Factor"),
                     values = c("lightblue","yellow","darkgreen")) +
  theme_minimal()




