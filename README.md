## Pricing-Intangibles

To Do:

Download LIQ Factor

\[ \] Write ‘ReadMe’s’ for every auxiliary File

Find out how to produce them with plots (-&gt; maybe straight KNitR
them?)

Do the LIQ ~ F\_INT, & LIQ ~ FF regressions

Fucking get behind how to fix this fucking shit of a whore piece of git
connection without suing github desktop those bunch of motherless
sloths. die -&gt; did it (will keep this as a memento tho)

Show the difference of the Factors when RMW is divided by be, or by
be\_int

MY BROTHER IN CHRIST: we forgot about the market factor. (did we?) -&gt;
check this straight after coming back from the doc!

\#List of test plots:

\[x\] All the recreated fama french factors with the originals.

\[x\] All the intangible factors with the recreated fff.

\[x\] The two different rmw\_int factors

(\[x\] The different HML Factors)

\[x\] The Traded Liquidity Factor

\#List of all the test tables:

\[x\] All the recreated factors with the originals

\[ \] Liq ~ FF5 OG

\[ \] Liq ~ FF5 Int

\#List of all factors and their composition:

\[ \] All the original FF5

\[ \] All the Int FF5 recreated

\[ \] HML original and RMW Original

\[ \] The Liquidity Factor

## Reproduction of Factors

![](README_files/figure-markdown_strict/smb_reproduction-1.png)

![](README_files/figure-markdown_strict/hml_reproduction-1.png)
![](README_files/figure-markdown_strict/rmw_reproduction-1.png)

![](README_files/figure-markdown_strict/cma_reproduction-1.png)

<table style="text-align:center">
<caption>
<strong>Regressions of Replicated- onto Published Factors</strong>
</caption>
<tr>
<td colspan="5" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td colspan="4">
Factors from K. French’s Website
</td>
</tr>
<tr>
<td>
</td>
<td colspan="4" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
SMB
</td>
<td>
HML
</td>
<td>
RMW
</td>
<td>
CMA
</td>
</tr>
<tr>
<td colspan="5" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
SMB (rep)
</td>
<td>
0.956<sup>\*\*\*</sup>
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
(0.006)
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
HML (rep)
</td>
<td>
</td>
<td>
1.023<sup>\*\*\*</sup>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
(0.017)
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
RMW (rep)
</td>
<td>
</td>
<td>
</td>
<td>
0.965<sup>\*\*\*</sup>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
(0.012)
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
CMA (rep)
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
0.985<sup>\*\*\*</sup>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
(0.010)
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
Constant
</td>
<td>
-0.00003
</td>
<td>
0.001
</td>
<td>
0.0001
</td>
<td>
0.0003
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
(0.0002)
</td>
<td>
(0.001)
</td>
<td>
(0.0003)
</td>
<td>
(0.0002)
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
<td>
</td>
<td>
</td>
<td>
</td>
</tr>
<tr>
<td colspan="5" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
Observations
</td>
<td>
330
</td>
<td>
330
</td>
<td>
330
</td>
<td>
330
</td>
</tr>
<tr>
<td style="text-align:left">
R<sup>2</sup>
</td>
<td>
0.987
</td>
<td>
0.915
</td>
<td>
0.955
</td>
<td>
0.966
</td>
</tr>
<tr>
<td style="text-align:left">
Adjusted R<sup>2</sup>
</td>
<td>
0.987
</td>
<td>
0.915
</td>
<td>
0.955
</td>
<td>
0.966
</td>
</tr>
<tr>
<td style="text-align:left">
Residual Std. Error (df = 328)
</td>
<td>
0.004
</td>
<td>
0.010
</td>
<td>
0.006
</td>
<td>
0.004
</td>
</tr>
<tr>
<td style="text-align:left">
F Statistic (df = 1; 328)
</td>
<td>
24,971.270<sup>\*\*\*</sup>
</td>
<td>
3,553.302<sup>\*\*\*</sup>
</td>
<td>
7,018.902<sup>\*\*\*</sup>
</td>
<td>
9,352.846<sup>\*\*\*</sup>
</td>
</tr>
<tr>
<td colspan="5" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
<em>Note:</em>
</td>
<td colspan="4" style="text-align:left">
<sup>*</sup>p&lt;0.1; <sup>**</sup>p&lt;0.05; <sup>***</sup>p&lt;0.01
</td>
</tr>
</table>

## The intangible Factors

![](README_files/figure-markdown_strict/hml_factor-1.png)

![](README_files/figure-markdown_strict/hml_int-1.png)

![](README_files/figure-markdown_strict/rmw_factor-1.png)

![](README_files/figure-markdown_strict/rmw_OLD-1.png)

![](README_files/figure-markdown_strict/cma_factor-1.png)

# The Liquidity “factor”

![](README_files/figure-markdown_strict/liq_factor-1.png)

![](README_files/figure-markdown_strict/liq_measures-1.png)

# The Dataset

    ## # A tibble: 1,491,668 × 22
    ##    permno month      industry  ret_excess mkt_excess     smb     hml     rmw
    ##     <dbl> <date>     <chr>          <dbl>      <dbl>   <dbl>   <dbl>   <dbl>
    ##  1  10001 1996-07-01 Utilities    0.0189     -0.0597 -0.0381  0.0514  0.0295
    ##  2  10001 1996-08-01 Utilities    0.0341      0.0277  0.0257 -0.0074 -0.0037
    ##  3  10001 1996-09-01 Utilities    0.0375      0.0501 -0.0139 -0.0272  0.0127
    ##  4  10001 1996-10-01 Utilities   -0.0328      0.0086 -0.0377  0.0494  0.014 
    ##  5  10001 1996-11-01 Utilities    0.0253      0.0625 -0.038   0.0139  0.0212
    ##  6  10001 1996-12-01 Utilities   -0.0640     -0.017   0.0325  0.0131  0.0037
    ##  7  10001 1997-01-01 Utilities    0.0570      0.0499 -0.0182 -0.0142  0.0119
    ##  8  10001 1997-02-01 Utilities   -0.0039     -0.0049 -0.0259  0.0567  0.0067
    ##  9  10001 1997-03-01 Utilities    0.00787    -0.0503 -0.0043  0.0339  0.005 
    ## 10  10001 1997-04-01 Utilities   -0.0043      0.0404 -0.057   0.0007  0.0326
    ## # ℹ 1,491,658 more rows
    ## # ℹ 14 more variables: cma <dbl>, smb_replicated <dbl>, hml_replicated <dbl>,
    ## #   rmw_replicated <dbl>, cma_replicated <dbl>, smb_int_replicated <dbl>,
    ## #   hml_int_replicated <dbl>, rmw_int <dbl>, rmw_intOLD <dbl>, cma_int <dbl>,
    ## #   AggLiq <dbl>, LiqInno <dbl>, LiqTrad <dbl>, hml_int <dbl>

# Fama-Macbeth Regressions

To garuantee comparability of the results the excess returns analysed
are from the different industry portfolios according to K. French’s
website.

1.  Producing the *β*′*s*:

$$ r\_{i,t} -  r\_{f,t}= \alpha + \sum^k\_{j = 1}\beta\_{i,j} f\_{i,t} + \epsilon\_{i,t}, $$

where *f* = (*H**M**L*,*S**M**B*,*R**M**W*,*C**M**A*).

1.  Exposures as explanatory variables in *T* cross-sectional
    regressions. Now *r*<sub>*i*, *t*</sub> represents the excess
    return.

*r*<sub>*i*, *t* + 1</sub> = *α*<sub>*i*</sub> + *λ*<sub>*t*</sub><sup>*M*</sup>*β*<sub>*i*, *t*</sub><sup>*M*</sup> + *λ*<sub>*t*</sub><sup>*S**M**B*</sup>*β*<sub>*i*, *t*</sub><sup>*S**M**B*</sup> + *λ*<sub>*t*</sub><sup>*H**M**L*</sup>*β*<sub>*i*, *t*</sub><sup>*H**M**L*</sup> + *λ*<sub>*t*</sub><sup>*R**M**W*</sup>*β*<sub>*i*, *t*</sub><sup>*R**M**W*</sup> +  + *λ*<sub>*t*</sub><sup>*C**M**A*</sup>*β*<sub>*i*, *t*</sub><sup>*C**M**A*</sup>

This gives us the estimator of interest: the
compensation*λ*<sub>*t*</sub><sup>*f*</sup> for the exposure to each
risk factor *β*<sub>*i*, *t*</sub><sup>*f*</sup> at each point in time
(THE RISK PREMIUM)

If there is a linear relationship between expected returns and the
characteristic in a given month, we expect the regression coefficient to
reflect the relationship, i.e., *λ*<sub>*t*</sub><sup>*f*</sup> ≠ 0.

1.  Get the time-series average

$$ \frac{1}{T} \sum\_{t=1}^T \hat{\lambda}\_t^f $$
of the averages *λ̂*<sub>*t*</sub><sup>*f*</sup> which then can be
interpreted as the risk premium for the specific risk factor f

\#State-Space Model

Define the state-space model with liquidity influencing the factor
loadings. The state-space particle filter approach is beneficial,
because of the inclusion of the latent liquidity influence, but also
because it allows me to produce entire distributions of the factor
exposures independently from how they are distributed (i.e, not only
point estimator under Gaussian distribution). This can produce valuable
insights on the factor exposure dynamics.

## State Equation

The state equation models the latent influence of liquidity on the
factor exposures.

\[ *{j,t} = *{j,t-1} + *j L\_t + *{j,t}, *{j,t} (0, *{\_j}^2)\]

## Observation Equation

The observation equation models the returns as a function of the
Fama-French five factors, with the factor loadings influenced by the
latent state.

\[ R\_{i,t} = *{0,i} + *{j=1}^5 (*{j,i} + *j *{j,t}) F*{j,t} + *{i,t},
*{i,t} (0, \_R^2)\]

# Particle Filter Process

## Initialization

Initialize (N) particles representing the initial belief about the
latent influences of liquidity.

## Prediction Step

Propagate each particle according to the state equation.

\[ *{j,t}^n = *{j,t-1}^n + *j L\_t + *{j,t}^n, *{j,t}^n (0, *{\_j}^2),
n\]

## Update Step

Update the weights of each particle based on the observation equation.

\[ w\_t^n = w\_{t-1}^n *{i=1}^M p(R*{i,t} | *{1,t}^n, *{2,t}^n, ,
\_{5,t}^n, ), n\]

## Normalization

Normalize the weights:

\[ t^n = , n\]

## Resampling

Resample the particles based on their weights to avoid degeneracy.

## Estimation

Estimate the state at each time step by taking the weighted average of
the particles.

\[ = ^N t^n ^n\]

# Cross-Sectional GMM Regression

Use the estimated factor loadings from the particle filter as the
dependent variables in the cross-sectional regression, with lagged
factors and lagged liquidity as instruments.

## GMM Setup

Instead of Cross sectional OLS/WLS regression, the GMM framework allows
for a continuation of non-Gaussian analysis. Define the moment
conditions for the cross-sectional GMM:

\[ E\[z\_{t-1} (R\_{i,t} - *{0,i} - *{j=1}^5 *{j,i} F*{j,t})\] = 0\]

where (z\_{t-1}) are the instruments (lagged factors and lagged
liquidity).
