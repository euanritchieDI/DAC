list.of.packages <- c("data.table", "janitor", "tidyverse", "xml2")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

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
  obsChildren = (x %>% xml_children())
  obsKeyValues = obsChildren[1] %>% xml_children()
	keyIds  = obsKeyValues %>% xml_attr("id")
	keyValues = obsKeyValues %>% xml_attr("value")
	value = obsChildren[2] %>% xml_attr("value")
	return(rbind(data.frame("Var"=keyIds,"value"=keyValues),c("Value",value)))
}
### ------------------------------------------------------------------
# GET ACTUAL DATA

#V = current prices; Q = constant prices
#D = disbursements; C = commitments	


MUMS = function(donors="",Start="2011",End="2022",core=T,prices="current",disb=T,channel=""){
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
	setnames(dat, "TIME_PERIOD", "year")
	return(dat)
}
