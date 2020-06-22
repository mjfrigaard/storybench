#=====================================================================#
# This is code to create: 38-rolling-averages-wrangle.R
# Authored by and feedback to:
# MIT License
# Version:
#=====================================================================#

# Download files into COVID-19/ folder from: 
# https://github.com/CSSEGISandData/COVID-19


# packages ----------------------------------------------------------------
library(zoo) # moving averages        
library(tidyverse) # all tidyverse packages
library(skimr) # summaries 
library(hrbrthemes) # themes for graphs
library(socviz) # %nin%
library(openintro) # 
library(geofacet) # 
library(usmap) # lat and long
library(socviz) # for %nin%
library(ggmap) # mapping



# create list of .csv files: 
csse_csv_files <- fs::dir_ls(path = ".drafts/data/jhsph/COVID-19/csse_covid_19_data/csse_covid_19_daily_reports_us", 
                             glob = "*.csv")
# csse_csv_files
JHCovid19DataRaw <- csse_csv_files %>%
  purrr::map_df(.f = read_csv, .id = "file", col_types = cols()) %>% 
    janitor::clean_names(case = "snake")


# I only need cases by state, so I'll also convert the `last_update` column to a 
# `date` variable with some help from lubridate: 
# https://lubridate.tidyverse.org/,
# Then I will create new `month_abbr` and `day` variables, rename province_state 
# to state, and remove the variables I won't be using

JHCovid19 <- JHCovid19DataRaw %>% 
  dplyr::mutate(date = lubridate::as_date(last_update),
                month_abbr = lubridate::month(date, label = TRUE, 
                                                 abbr = TRUE),
                # day
                day = lubridate::day(date)) %>% 
  dplyr::select(-c(file, country_region, uid, iso3))

# Next I'll get the state abbreviations by creating a crosswalk table and 
# joining these with the `JHCovid19NewDeaths` dataset.

StateCrosswalk <- tibble::tibble(state = state.name) %>%
  # stick this to the abbreviations
   dplyr::bind_cols(tibble::tibble(state_abbr = state.abb)) %>% 
  # bind this to District of Columbia
   dplyr::bind_rows(tibble(state = "District of Columbia", 
                           state_abbr = "DC")) %>% 
  dplyr::rename(province_state = state)
# head(StateCrosswalk)

# Now I join the `state_abbr` column to `JHCovid19` and remove the non-states 
# in the `JHCovid19States` dataset. 


JHCovid19States <- JHCovid19 %>% 
                # join these two together
                dplyr::inner_join(x = ., 
                                 y = StateCrosswalk,
                                 by = "province_state")
# remove non-states
JHCovid19States <- JHCovid19States %>% 
    dplyr::filter(province_state %nin% c("American Samoa", "Diamond Princess", 
                                         "Grand Princess", "Guam", 
                                         "Northern Mariana Islands", 
                                         "Puerto Rico", "Virgin Islands"))

JHCovid19States <- JHCovid19States %>% 
  dplyr::rename(state = province_state)

# export these data 
write_csv(as.data.frame(JHCovid19States), paste0("drafts/data/jhsph/", 
          base::noquote(lubridate::today()),
          "-JHCovid19States.csv"))
