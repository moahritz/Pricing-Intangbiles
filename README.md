## Pricing-Intangibles

To Do:

Download LIQ Factor

Write ‘ReadMe’s’ for every auxiliary File

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

List of test plots:

\[ \] All the recreated fama french factors with the originals.

All the intangible factors with the recreated fff.

The two different rmw\_int factors

The different HML Factors

This is an R Markdown document. Markdown is a simple formatting syntax
for authoring HTML, PDF, and MS Word documents. For more details on
using R Markdown see <http://rmarkdown.rstudio.com>.

When you click the **Knit** button a document will be generated that
includes both content as well as the output of any embedded R code
chunks within the document. You can embed an R code chunk like this:

    summary(cars)

    ##      speed           dist       
    ##  Min.   : 4.0   Min.   :  2.00  
    ##  1st Qu.:12.0   1st Qu.: 26.00  
    ##  Median :15.0   Median : 36.00  
    ##  Mean   :15.4   Mean   : 42.98  
    ##  3rd Qu.:19.0   3rd Qu.: 56.00  
    ##  Max.   :25.0   Max.   :120.00

## Including Plots

You can also embed plots, for example:

<img src="README_files/figure-markdown_strict/hml_reproduction-1.png" height="50%" />

Note that the `echo = FALSE` parameter was added to the code chunk to
prevent printing of the R code that generated the plot.

    library(stargazer)
    stargazer(model_hml, type = "html")

<table style="text-align:center">
<tr>
<td colspan="2" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
<em>Dependent variable:</em>
</td>
</tr>
<tr>
<td>
</td>
<td colspan="1" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
hml
</td>
</tr>
<tr>
<td colspan="2" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
hml\_replicated
</td>
<td>
1.023<sup>\*\*\*</sup>
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
(0.017)
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
</tr>
<tr>
<td style="text-align:left">
Constant
</td>
<td>
0.001
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
(0.001)
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td>
</td>
</tr>
<tr>
<td colspan="2" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
Observations
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
0.915
</td>
</tr>
<tr>
<td style="text-align:left">
Adjusted R<sup>2</sup>
</td>
<td>
0.915
</td>
</tr>
<tr>
<td style="text-align:left">
Residual Std. Error
</td>
<td>
0.010 (df = 328)
</td>
</tr>
<tr>
<td style="text-align:left">
F Statistic
</td>
<td>
3,553.302<sup>\*\*\*</sup> (df = 1; 328)
</td>
</tr>
<tr>
<td colspan="2" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
<em>Note:</em>
</td>
<td style="text-align:right">
<sup>*</sup>p&lt;0.1; <sup>**</sup>p&lt;0.05; <sup>***</sup>p&lt;0.01
</td>
</tr>
</table>
