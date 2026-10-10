# Data definitions and remaining measurement limitations

The source files have been moved, not overwritten. Download vintages are not recorded in the original repository. This version uses the existing data snapshot, not newly downloaded or revised data.

## Inputs

The loader reads data/input/dataset_eu.xlsx, dataset_eu_BEAR_nodummy.xlsx and dataset_usa.xlsx. Actual dates determine the common sample, currently 2002Q2–2025Q3. The prepared EA file determines available dates; the harmonised EA values are rebuilt from levels. The alternative BEAR workbook is preserved but unused.

| Variable | EA construction | US construction | Units in model |
| --- | --- | --- | --- |
| Oil | 100 × log ratio of BFO levels, column I | 100 × log(1 + WTISPLC_PCH/100) | Quarterly log growth × 100 |
| GDP | 100 × log ratio of real GDP, F | 100 × log(1 + GDPC1_PCH/100) | Quarterly log growth × 100 |
| Unemployment | H | UNRATE | Percent, level |
| Inflation | 100 × log ratio of HICP, D | 100 × log(1 + CPIAUCSL_PCH/100) | Quarterly log inflation × 100, not annualised |
| Income/GDP | 100 × log change of G/E (nominal income/nominal GDP) | 100 × log change of DSPI_GDP | Log ratio growth × 100 |
| EGM | 100 × log growth of M3 (B) minus real GDP growth (F) | Recover M2 percentage growth as EGM_PCH + GDP_PCH, convert it to log growth, then subtract log GDP growth | Difference of quarterly log growth rates × 100 |
| Rate | Three-month Euribor, C | FF | Percent, level |

Converting the difference EGM directly with log(1+EGM/100) would be wrong. Its money and GDP components must be transformed separately. US stored values are rounded to five decimals; conversion cannot restore precision lost at export. The conversion assumes the stored PCH columns represent period-over-period growth of the quarterly series as their headers imply. The original monthly aggregation/export recipe still needs verification against source levels.

## Seasonal treatment

The local HICP source CP0000EZ19M086NEST is EA19, not seasonally adjusted. US CPIAUCSL is seasonally adjusted. Metadata: [EA HICP](https://fred.stlouisfed.org/series/CP0000EZ19M086NEST), [US CPI](https://fred.stlouisfed.org/series/CPIAUCSL).

The new baseline includes an intercept and Q1, Q2, Q3 indicators in every VAR equation, with Q4 omitted. The bootstrap keeps these indicators on their original calendar. Innovations and IRFs hold deterministic controls fixed. This controls for fixed quarterly means; it is **not** an official seasonal adjustment, does not allow time-varying seasonality, and does not make the two price baskets identical. No de-seasonalised series is manufactured or labelled as official data.

Sensitivity results compare the same sample under (1) legacy growth definitions without controls, (2) harmonised log growth without controls, and (3) harmonised log growth with quarterly controls. This separates the effects of the two changes.

## Source extracts retained in data/raw

| File | Source identifier in the original export |
| --- | --- |
| hicp_level.csv | CP0000EZ19M086NEST |
| nominal_gdp_sa.csv | CPMNACB1GQSCAEA20Q |
| real_gdp.csv | MNA.Q.Y.I9.W2.S1.S1.B.B1GQ._Z._Z._Z.EUR.LR.N |
| gross_sa_gdi.csv | QSA.Q.Y.I9.W0.S1M.S1._Z.B.B6G._Z._Z._Z.XDC._T.S.V.N._T |
| m3.csv | BSI.M.U2.Y.V.M30.X.1.U2.2300.Z01.E; quarterly export |
| unemployment.csv | LFSI.M.I10.S.UNEHRT.TOTAL0.15_74.T; quarterly export |
| euribor_3m.csv | FM.M.U2.EUR.RT.MM.EURIBOR3MD_.HSTA; quarterly export |
| crudeoil.csv | FM.Q.U2.EUR.4F.CY.OILBRNI.HSTA |
| fredgraph.csv | US transformed FRED series listed above |

## Unresolved comparability

- Geographic composition differs (EA19 HICP, EA20 GDP and other geographic codes). Source vintages and historical membership conventions require verification.
- M3 versus M2, BFO versus WTI, and Euribor versus federal funds rate remain different measures. The oil export has ambiguous currency wording; verify source metadata before economic interpretation.
- Quarterly aggregation of monthly sources is not reconstructed by this pipeline. data/raw preserves the supplied extracts; data/input contains the inherited prepared inputs.
- Disposable income is an outcome, not a direct measure of discretionary transfers. EGM is not an identified monetary-policy shock.

Next data work: recover a documented, consistent source-level quarterly build, with vintages, aggregation rules, geography and official seasonal adjustments specified before download. Avoid silently mixing fresh revised series with this historical snapshot.
