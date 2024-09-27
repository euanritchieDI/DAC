library(tidyverse)
library(xml2)
library(data.table)
library(janitor)

### ------------------------------------------------------------------
# GET NAMES FOR THE CHANNEL CODES
getMUMScodes = function(){
	key = "https://sdmx.oecd.org/dcd-public/rest/dataflow/OECD.DCD.FSD/DSD_MULTI@DF_MULTI/1.1?references=all"
	apikey = read_xml(key)
	code = apikey %>% xml_find_all("//structure:Codelist[@id='CL_CRS_CHANNEL']") %>%
		xml_children() %>% xml_attr("id")
	name = apikey %>% xml_find_all("//structure:Codelist[@id='CL_CRS_CHANNEL']") %>%
		xml_find_all(".//common:Name[@xml:lang='en']") %>% xml_text()
	key = data.frame('CHANNEL'=code,'channel_name'=name)
	return(key)
}
### ------------------------------------------------------------------
# FUNCTIONS FOR ORGANISING DATA

namefunk = function(x,name){
	x$id = name
	return(x)
}
attrfunk = function(x){
	Var  = (x %>% xml_children())[1] %>% xml_children() %>% xml_attr("id")
	val1 = (x %>% xml_children())[1] %>% xml_children() %>% xml_attr("value")
	val2 = (x %>% xml_children())[2] %>% xml_attr("value")
	return(rbind(data.frame("Var"=Var,"value"=val1),c("Value",val2)))
}
### ------------------------------------------------------------------
# GET ACTUAL DATA

#V = current prices; Q = constant prices
#D = disbursements; C = commitments	


MUMS = function(donors,Start,End,core=T,prices="current",disb=T,channel=""){
	donors = paste(donors,collapse="+")
	prices = ifelse(prices=="current","V","Q")
	disb   = ifelse(disb==T,"D","C")
	core   = ifelse(core==T,10,20)
	
	stub = "https://sdmx.oecd.org/dcd-public/rest/data/OECD.DCD.FSD,DSD_MULTI@DF_MULTI,1.1/"
	x = paste0(stub,
	  donors,".",
	  "DPGC",".",
	  "1000",".",
	  core,".",
	  channel,".",
	  disb,".",
	  prices,"._T..",
	  "?startPeriod=",Start,
	  "&endPeriod=",End,
	  "&dimensionAtObservation=AllDimensions")

	api_out = read_xml(x)
	obs = api_out %>% xml_find_all("//generic:Obs")
	dat = lapply(obs,attrfunk)
	dat = Map(namefunk, dat, 1:length(dat))
	dat = as.data.frame(rbindlist(dat)) %>% pivot_wider(names_from=Var,values_from=value)
	dat = remove_constant(dat)
	names(dat)[names(dat)=="TIME_PERIOD"] = "year"
	return(dat)
}




