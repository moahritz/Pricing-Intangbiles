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

\[ \] All the recreated factors with the originals

\[ \] Liq ~ FF5 OG

\[ \] Liq ~ FF5 Int

\#List of all factors and their composition:

\[\] All the original FF5

\[\] All the Int FF5 recreated

\[\] HML original and RMW Original

\[\] The Liquidity Factor

## Reproduction of Factors

![](README_files/figure-markdown_strict/smb_reproduction-1.png)

![](README_files/figure-markdown_strict/hml_reproduction-1.png)
![](README_files/figure-markdown_strict/rmw_reproduction-1.png)

![](README_files/figure-markdown_strict/cma_reproduction-1.png)

<table style="text-align:center">
<tr>
<td colspan="5" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td style="text-align:left">
</td>
<td colspan="4">
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
smb
</td>
<td>
hml
</td>
<td>
rmw
</td>
<td>
cma
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
SMB
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
HML
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
RMW
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
CMA
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
<table style="text-align:center">
<tr>
<td colspan="1" style="border-bottom: 1px solid black">
</td>
</tr>
<tr>
<td>
Factors from K. French’s Website
</td>
</tr>
<tr>
<td colspan="1" style="border-bottom: 1px solid black">
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
