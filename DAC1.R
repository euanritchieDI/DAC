## DAC 1
## Just downloads the whole shebang, and gives it nicer names

library(tidyverse)
library(janitor)

daciso = c("AUS","CZE","FIN","IRL","LTU","NZL","SWE","AUT","DEU","FRA","ISL",
	"LUX","POL","USA","BEL","DNK","GBR","ITA","PRT","CAN","ESP","GRC",
	"JPN","NLD","SVK","CHE","EST","HUN","KOR","NOR","SVN")

options(timeout=1000)

dac1 = read.csv("https://sdmx.oecd.org/public/rest/data/OECD.DCD.FSD,DSD_DAC1@DF_DAC1,1.1/all?dimensionAtObservation=AllDimensions&format=csvfilewithlabels")
dac1 = remove_constant(dac1) # removes columns with only one value (which are useless)
dac1[c(
	"UNIT_MULT", 		# all figures are obviously in millions other than percentages
	"Unit.multiplier",	# all figures are obviously in millions other than percentages
	"DECIMALS",			# really don't need separate columns specifying the decimal point
	"Decimals")] = NULL	# really don't need separate columns specifying the decimal point

names(dac1)[names(dac1)=="TIME_PERIOD"] = "year"
names(dac1)[names(dac1)=="OBS_VALUE"] = "value"

dac1$Measure[dac1$Measure=="Official Development Assistance (ODA)"] = "ODA"
dac1$Measure[dac1$Measure=="Official Development Assistance, grant equivalent"] = "ODA_ge"
dac1$Measure[dac1$Measure=="Multilateral ODA (capital subscriptions are included with grants)"] = "multi"
dac1$Measure[dac1$Measure=="Multilateral ODA, grant equivalent"] = "multi_ge"
dac1$Measure[dac1$Measure=="Bilateral ODA"] = "bi"
dac1$Measure[dac1$Measure=="Bilateral ODA, grant equivalent"] = "bi_ge"
dac1$Measure[dac1$Measure=="Refugees in donor countries"] = "IDRC"

dac1$dac = 1*(dac1$DONOR %in% daciso)






