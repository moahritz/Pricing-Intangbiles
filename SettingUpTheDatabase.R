library(RSQLite)
library(dbplyr)
library(tidyverse)
library(frenchdata)
library(tidyquant)
library(scales)
library(RPostgres)



intangible_value <- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)


########## This is basically it

start_date <- ymd("1994-01-01")
end_date <- ymd("2024-12-31")



##############  First 2 tables: traditional fama-french 5 factors



ff5f_monthl_raw <- download_french_data("Fama/French 5 Factors (2x3)")
ff5f_monthl_raw <- ff5f_monthl_raw$subsets$data[[1]] |>
  mutate(
    month = floor_date(ymd(str_c(date, "01")), "month"),
    across(c(RF, `Mkt-RF`, SMB, HML, RMW, CMA), ~as.numeric(.) / 100),
    .keep = "none"
  ) |>
  rename_with(str_to_lower) |>
  rename(mkt_excess = `mkt-rf`) |>
  filter(month >= start_date & month <= end_date)

industries_ff_monthly_raw <- download_french_data("10 Industry Portfolios")

industries_ff_monthly <- industries_ff_monthly_raw$subsets$data[[1]] |>
  mutate(month = floor_date(ymd(str_c(date, "01")), "month")) |>
  mutate(across(where(is.numeric), ~ . / 100)) |>
  select(month, everything(), -date) |>
  filter(month >= start_date & month <= end_date) |> 
  rename_with(str_to_lower)

dbWriteTable(intangible_value,
             "factors_ff5_monthly_frenchdata",
             value = ff5f_monthl_raw,
             overwrite = TRUE)





############ Third table: Monthly CPI

cpi_monthly <- tq_get("CPIAUCNS",
                      get = "economic.data",
                      from = start_date,
                      to = end_date
) |>
  mutate(
    month = floor_date(date, "month"),
    cpi = price / price[month == max(month)],
    .keep = "none"
  )

dbWriteTable(intangible_value,
             "cpi_monthly",
             value = cpi_monthly,
             overwrite = TRUE
)



############ Accessing WRDS



wrds <- dbConnect(Postgres(),
                  host='wrds-pgdata.wharton.upenn.edu',
                  port=9737,
                  user='nkerwien',
                  password='WienPhd2023!',
                  dbname='wrds',
                  sslmode='require')







############ BLINDFLUG FÜR CRSP COMPUSTAT SETUP #############




#msf_db <- tbl(wrds, I("crsp.msf_v2"))
msf_db <- tbl(wrds, in_schema("crsp","msf_v2"))

#stksecurityinfohist_db <- tbl(wrds, "crsp.stksecurityinfohist")
stksecurityinfohist_db <- tbl(wrds, in_schema("crsp","stksecurityinfohist"))


#mse_db <- tbl(wrds, I("crsp.mse"))
mse_db <- tbl(wrds, in_schema("crsp","mse"))

crsp_monthly <- msf_db |>
  filter(mthcaldt >= start_date & mthcaldt <= end_date) |>
  select(-c(siccd, primaryexch, conditionaltype, tradingstatusflg)) |> 
  inner_join(
    stksecurityinfohist_db |>
      filter(sharetype == "NS" & 
               securitytype == "EQTY" & 
               securitysubtype == "COM" & 
               usincflg == "Y" & 
               issuertype %in% c("ACOR", "CORP") & 
               primaryexch %in% c("N", "A", "Q") &
               conditionaltype %in% c("RW", "NW") &
               tradingstatusflg == "A") |> 
      select(permno, secinfostartdt, secinfoenddt,
             primaryexch, siccd),
    join_by(permno)
  ) |> 
  filter(mthcaldt >= secinfostartdt & mthcaldt <= secinfoenddt) |>
  mutate(month = floor_date(mthcaldt, "month")) |>
  select(
    permno, # Security identifier
    date = mthcaldt, # Date of the observation
    month, # Month of the observation
    ret = mthret, # Return (incl. Dividends)
    retx = mthretx, #return (excl. Dividends)
    shrout, # Shares outstanding (in thousands) 
    prc = mthprc, # Last traded price in a month
    primaryexch, # Primary exchange code
    siccd
  ) |>
  collect() |>
  mutate(
    month = ymd(month),
    shrout = shrout * 1000
  )

crsp_monthly <- crsp_monthly |>
  mutate(
    mktcap = shrout * prc / 10^6,
    mktcap = na_if(mktcap, 0)
  )

mktcap_lag <- crsp_monthly |>
  mutate(month = month %m+% months(1)) |>
  select(permno, month, mktcap_lag = mktcap)

crsp_monthly <- crsp_monthly |>
  left_join(mktcap_lag, join_by(permno, month))



#transform primary listing exchange codes to explicit exchange names
crsp_monthly <- crsp_monthly |>
  mutate(exchange = case_when(
    primaryexch == "N" ~ "NYSE",
    primaryexch == "A" ~ "AMEX",
    primaryexch == "Q" ~ "NASDAQ",
    .default = "Other"
  ))

crsp_monthly <- crsp_monthly |>
  mutate(industry = case_when(
    siccd >= 1 & siccd <= 999 ~ "Agriculture",
    siccd >= 1000 & siccd <= 1499 ~ "Mining",
    siccd >= 1500 & siccd <= 1799 ~ "Construction",
    siccd >= 2000 & siccd <= 3999 ~ "Manufacturing",
    siccd >= 4000 & siccd <= 4899 ~ "Transportation",
    siccd >= 4900 & siccd <= 4999 ~ "Utilities",
    siccd >= 5000 & siccd <= 5199 ~ "Wholesale",
    siccd >= 5200 & siccd <= 5999 ~ "Retail",
    siccd >= 6000 & siccd <= 6799 ~ "Finance",
    siccd >= 7000 & siccd <= 8999 ~ "Services",
    siccd >= 9000 & siccd <= 9999 ~ "Public",
    .default = "Missing"
  ))

#compute excess returns by subtracting the monthly risk-free rate provided by Fama-French data.


intangible_value <- dbConnect(
  SQLite(),
  "data/intangible_value_r.sqlite",
  extended_types = TRUE
)

ff5fm <- tbl(intangible_value, "factors_ff5_monthly_frenchdata") |>
  select(month, rf) |>
  collect()

crsp_monthly <- crsp_monthly |>
  left_join(ff5fm,
            join_by(month)
  ) |>
  mutate(
    ret_excess = ret - rf,
    ret_excess = pmax(ret_excess, -1)
  ) |>
  select(-rf)

#excess returns and market capitalization are crucial for all our analyses, exclude all observations with missing returns or market capitalization


crsp_monthly <- crsp_monthly |>
  drop_na(ret_excess, mktcap, mktcap_lag)




dbWriteTable(intangible_value,
             "crsp_monthly",
             value = crsp_monthly,
             overwrite = TRUE
)



######
######
###### Compustat data
######
######
######

#funda_db <- tbl(wrds, I("comp.funda"))
funda_db <- tbl(wrds, in_schema("comp","funda"))

compustat <- funda_db |>
  filter(
    indfmt == "INDL" &
      datafmt == "STD" & 
      consol == "C" &
      popsrc == "D" & 
      datadate >= start_date & datadate <= end_date
  ) |>
  select(
    sich, # SICH (Standard Industrial Classification)
    gvkey, # Firm identifier
    datadate, # Date of the accounting data
    seq, # Stockholders' equity
    ceq, # Total common/ordinary equity
    at, # Total assets
    lt, # Total liabilities
    txditc, # Deferred taxes and investment tax credit
    txdb, # Deferred taxes
    itcb, # Investment tax credit
    pstkrv, # Preferred stock redemption value
    pstkl, # Preferred stock liquidating value
    pstk, # Preferred stock par value
    capx, # Capital investment
    oancf, # Operating cash flow
    revt,  # Total revenue
    sale, # Net Revenue
    cogs, # Costs of goods sold
    xint, # Interest expense
    xsga, # Selling, general, and administrative expenses
    xrd, # R&D expenditure
    gdwl # Goodwill
  ) |>
  collect()


# Calculate organizational capital/intangible capital
compustat <- compustat |>
  arrange(gvkey, datadate) |>
  group_by(gvkey) |>
  mutate(
    oc = first(xsga) / (0.1 + 0.2),  # Initial OC calculation           #DO THE CPI ADJUSTMENT HERE WITH ACCESS TO WRDS! (Pertisau, begin. June)
    oc = if_else(xsga == first(xsga), first(xsga) / (0.1 + 0.2), (1 - 0.2) * lag(oc) + xsga) # here xsga is not deflated by the cpi(!), because everything else isn't either -> think of this when using the variables later!!!
  ) |>
  ungroup()



compustat <- compustat |>
  mutate(
    be = coalesce(seq, ceq + pstk, at - lt) +
      coalesce(txditc, txdb + itcb, 0) -
      coalesce(pstkrv, pstkl, pstk, 0),
    be = if_else(be <= 0, NA, be),
    be_int = be - gdwl + oc,
    op = (revt - coalesce(cogs, 0) - 
            coalesce(xsga, 0) - coalesce(xint, 0)) / be,
    op_adj = (revt - coalesce(cogs, 0) - 
                coalesce(xsga * 0.7, 0) - coalesce(xint, 0) + coalesce(xsga * 0.3, 0) + coalesce(xrd, 0)) / be_int, #intangible adjusted book equity for these results!
    op_adjOLD = (revt - coalesce(cogs, 0) - 
                coalesce(xsga * 0.7, 0) - coalesce(xint, 0) + coalesce(xsga * 0.3, 0) + coalesce(xrd, 0)) / be, #don't (!) intangible adjusted book equity for these results!
  )



compustat <- compustat |>
  mutate(year = year(datadate)) |>
  group_by(gvkey, year) |>
  filter(datadate == max(datadate)) |>
  ungroup()


# Join to get previous year's AT and OC -> INV & AAG
compustat <- compustat |>
  left_join(
    compustat |>
      select(gvkey, year, at_lag = at, oc_lag = oc)  |>
      mutate(year = year + 1),
    join_by(gvkey, year)
  ) |>
  mutate(
    inv = at / at_lag - 1,
    inv = if_else(at_lag <= 0, NA, inv),
    aag = (at - at_lag - (oc - oc_lag)) / at_lag,
    aag = if_else((at_lag -(oc -oc_lag)) <= 0 , NA, aag)
  )




dbWriteTable(intangible_value,
             "compustat",
             value = compustat,
             overwrite = TRUE
)


#####
#####
##### CONNECTION
#####
#####

##tidyfin
#ccmxpf_linktable_db <- tbl(wrds, I("crsp.ccmxpf_linktable"))
ccmxpf_linktable_db <- tbl(wrds, in_schema("crsp","ccmxpf_linktable"))

ccmxpf_linktable <- ccmxpf_linktable_db |>
  filter(linktype %in% c("LU", "LC", "LS") &
           linkprim %in% c("P", "C", "J") &
           usedflag == 1) |>
  select(permno = lpermno, gvkey, linkdt, linkenddt) |>
  collect() |>
  mutate(linkenddt = replace_na(linkenddt, today()))

ccm_links <- crsp_monthly |>
  inner_join(ccmxpf_linktable, 
             join_by(permno), relationship = "many-to-many") |>
  filter(!is.na(gvkey) & 
           (date >= linkdt & date <= linkenddt)) |>
  select(permno, gvkey, date)

crsp_monthly <- crsp_monthly |>
  left_join(ccm_links, join_by(permno, date))

dbWriteTable(intangible_value,
             "crsp_monthly",
             value = crsp_monthly,
             overwrite = TRUE)

