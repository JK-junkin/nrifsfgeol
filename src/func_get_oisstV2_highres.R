
## Text Encoding: UTF-8

get.oisst.v2.high.resol <- function(track, folder = tempdir(),
                                    removeland = TRUE, margin = 4) {
  # load packages
  if(!require(tidyverse)) install.packages("tidyverse"); require(tidyverse)
  if(!require(ncdf4)) install.packages("ncdf4"); require(ncdf4)
  if(!require(date)) install.packages("date"); require(date)
  if(!require(lubridate)) install.packages("lubridate"); require(lubridate)
  if(!require(pathological)) { 
    install.packages("pathological"); require(pathological) }
  if(!require(rvest)) install.packages("rvest"); require(rvest)
  # require(XML)

  TODAY <- format(Sys.time(), format = "%Y%m%d_%H%M%S")
  
  extrDate <- function(x) mdy.date(x[,2], x[,1], x[,3])
  fmtDate <- function(date) {
    x <- date.mdy(date) # 1960/01/01を0日目として日付をリストとして返す
    paste(x$year,
          formatC(x$month, digits = 1, flag = "0", format = "d"),
          formatC(x$day, digits = 1, flag = "0", format = "d"), sep = "-")
  }
  fmtDay <- function(day) {
    formatC(day, digits = 2, flag = "0", format = "d")
  }
  
  testdir <- file.info(folder)$isdir
  if (is.na(testdir)) {
    create_dirs(folder)
  }
  else {
    if (!testdir) {
    stop("The folder name supplied is in fact a filename")
    }
  }
  unlink(paste(folder, "/*", sep = ""), F)

  sstfolder <- file.path(folder, "sst_files")
  testdir <- file.info(sstfolder)$isdir
  if (is.na(testdir)) {
    create_dirs(sstfolder)
  }
  else { 
    if (!testdir) {
    stop("The folder name supplied is in fact a filename")
    }
  }
  unlink(paste(sstfolder, "/*", sep = ""), F)
  
  if(!all(class(track) == "data.frame")) track <- as.data.frame(track)
  t <- list(track)
  minDate <- min(unlist(lapply(t, extrDate))) # 1960/01/01からの通日
  maxDate <- max(unlist(lapply(t, extrDate))) # 1960/01/01からの通日
  yrs <- as.character(date.mdy(minDate)$year:date.mdy(maxDate)$year)

  minLon <- unlist(lapply(t, function(x) min(x[, 4], na.rm = T))) - margin
  maxLon <- unlist(lapply(t, function(x) max(x[, 4], na.rm = T))) + margin
  lonlow <- ifelse(minLon < 0, 360 + floor(minLon/0.25)*0.25 + 0.125,
                   floor(minLon/0.25)*0.25 + 0.125)
  lonhigh <- ifelse(maxLon < 0, 360 + floor(maxLon/0.25)*0.25 + 0.125,
                    floor(maxLon/0.25)*0.25 + 0.125)

  minLat <- unlist(lapply(t, function(x) min(x[, 5], na.rm = T))) - margin
  maxLat <- unlist(lapply(t, function(x) max(x[, 5], na.rm = T))) + margin
  latlow <- ifelse(minLat < -89.875, -89.875, floor(minLat/0.25)*0.25 + 0.125)
  lathigh <- ifelse(maxLat > 89.875, 89.875, floor(maxLat/0.25)*0.25 + 0.125)
  
  ### get land mask data
  link <- "ftp://ftp.cdc.noaa.gov/Datasets/noaa.oisst.v2.highres/lsmask.oisst.v2.nc"
  fname <- paste0(folder, str_extract(link, "\\/lsmask.+"))
  download.file(link, fname, mode = "wb")
  nc <- nc_open(fname)
  land <- ncvar_get(nc, varid = "lsmask")
  lon <- ncvar_get(nc, varid = "lon")
  lat <- ncvar_get(nc, varid = "lat")
  
  LONs <- seq(min(c(lonlow, lonhigh)), max(c(lonlow, lonhigh)), by = 0.25)
  LATs <- seq(min(c(latlow, lathigh)), max(c(latlow, lathigh)), by = 0.25)
  LAND <- land[lon %in% LONs, lat %in% LATs]
  nc_close(nc)

  ### get sst data
  link <- 
    read_html("https://www.esrl.noaa.gov/psd/cgi-bin/db_search/DBSearch.pl?Dataset=NOAA+High-resolution+Blended+Analysis&Variable=Sea+Surface+Temperature&group=0&submit=Search") %>%
    html_nodes("a") %>% 
    html_attr("href") %>% 
    str_subset("DB_vid=2423") %>% unique() %>% 
    paste0("https://www.esrl.noaa.gov", .)
  
  accessid <- read_html(link) %>% 
    html_nodes("em") %>% 
    str_subset("\\/Datasets\\/.+") %>% 
    str_match("%y4.nc\\s\\d+") %>% 
    str_match("\\d{5,}") %>% as.character()
  
  dataid <- link %>%
    str_match("&DB_tid=\\d+") %>% 
    str_match("\\d+") %>% as.character()

  # if (minDate >= enddate) 
  #   stop("Start date of your track is beyond that of the available SST images.")

  latlow <- ifelse(latlow > 0, paste0(latlow,"N"), paste0(-latlow,"S"))
  lathigh <- ifelse(lathigh > 0, paste0(lathigh,"N"), paste0(-lathigh,"S"))
  lonlow <- paste0( min(LONs), "E")
  lonhigh <- paste0( max(LONs), "E")

  link <- "http://www.esrl.noaa.gov/psd/cgi-bin/GrADS.pl?dataset=NOAA+High-resolution+Blended+Analysis&DB_did=132&file=%2FDatasets%2Fnoaa.oisst.v2.highres%2Fsst.day.mean.1981.nc+sst.day.mean.%25y4.nc+ACCESSID&variable=sst&DB_vid=2423&DB_tid=DATAID&units=degC&longstat=Mean&DB_statistic=Mean&stat=&lat-begin=LATLOW&lat-end=LATHIGH&lon-begin=LONLOW&lon-end=LONHIGH&dim0=time&year_begin=YEARLOW&mon_begin=MONTHLOW&day_begin=DAYLOW&year_end=YEARHIGH&mon_end=MONTHHIGH&day_end=DAYHIGH&X=lon&Y=lat&output=file&bckgrnd=black&use_color=on&fill=lines&cint=&range1=&range2=&scale=100&maskf=%2FDatasets%2Fnoaa.oisst.v2.highres%2Flsmask.oisst.v2.nc&maskv=Land-sea+mask&submit=Create+Plot+or+Subset+of+Data"
  link <- str_replace(link, "ACCESSID", accessid)
  link <- str_replace(link, "DATAID", dataid)
  opt <- str_replace(link, "LATLOW", latlow)
  opt <- str_replace(opt, "LATHIGH", lathigh)
  opt <- str_replace(opt, "LONLOW", lonlow)
  opt <- str_replace(opt, "LONHIGH", lonhigh)
  opt <- str_replace(opt, "YEARLOW", as.character(date.mdy(minDate)$year))
  opt <- str_replace(opt, "MONTHLOW", month.abb[date.mdy(minDate)$month])
  opt <- str_replace(opt, "DAYLOW", as.character(date.mdy(minDate)$day))
  opt <- str_replace(opt, "YEARHIGH", as.character(date.mdy(maxDate)$year))
  opt <- str_replace(opt, "MONTHHIGH", month.abb[date.mdy(maxDate)$month])
  opt <- str_replace(opt, "DAYHIGH", as.character(date.mdy(maxDate)$day))
  
  nc_url <- read_html(opt) %>%
    html_nodes("a") %>%    ## find all links
    html_attr("href") %>%  ## pull out url
    str_subset("\\.nc\\Z") ## pull out .nc file links

  nc_dir <- file.path(folder, "netCDF")
  create_dirs(nc_dir)

  fname <- file.path(nc_dir, paste0("DL@", TODAY, ".nc"))

  cat("次の期間と範囲の海表面水温データをNOAAのサーバーから取得中...\n\n   ",
      date.ddmmmyy(minDate), "-", date.ddmmmyy(maxDate),
      paste("(", maxDate - minDate + 1, "日)"), "\n\n   ",
      latlow, "-", lathigh, " | ", lonlow, "-", lonhigh, 
      paste0(" (余白 ", margin, "°)"), "\n\n")
  
  Sys.sleep(time = 1) # 1秒待ってからダウンロード開始
  download.file(nc_url, fname, mode = "wb")
  cat(paste(rep("=", options()$width), collapse = ""), "\n\n")
  cat("netCDF形式の海表面水温データを次のURLから取得しました:\n\n   ",
      nc_url,"\n\n")

  nc <- nc_open(fname, write = TRUE)
  xdim <- nc$dim[["lon"]]
  ydim <- nc$dim[["lat"]]
  varz <- ncvar_def(name = "land", units = "flag", dim = list(xdim, ydim),
                    missval = 32767, 
                    longname = "Land mask for SST values (1=ocean, 0=land)")
  nc <- ncvar_add(nc, varz)
  ncvar_put(nc, varid = "land", vals = LAND)
  nc_sync(nc)
  nc_close(nc)
  
  land <- t(LAND)
  nc <- nc_open(fname)
  lon <- ncvar_get(nc, varid = "lon")
  lat <- ncvar_get(nc, varid = "lat")
  dates <- as.Date("1800-01-01") + ncvar_get(nc, varid = "time")
  
  every.day <- 1
  vv <- nc$var[[1]]
  varsize <- vv$varsize
  ndims <- vv$ndims
  nt <- varsize[ndims]
  for (i in 1:nt) {
    start <- rep(1, ndims)
    start[ndims] <- i
    count <- varsize
    count[ndims] <- 1
    sst <- round(t(ncvar_get(nc, vv, start = start, count = count)), digits = 2)
    xyz <- rbind(rep(NA, 4))
    d <- mdy.date(month(dates[i]), day(dates[i]), year(dates[i]))
    y1 <- date.mdy(d)$year
    d1 <- d - mdy.date(1, 1, y1) + 1
    y2 <- date.mdy(d + every.day - 1)$year
    d2 <- (d + every.day - 1) - mdy.date(1, 1, y2) + 1
    filename <- paste0("RS",y1,fmtDay(d1),"_",y2,fmtDay(d2),"_","sst",".xyz")
    dest <- file.path(sstfolder, filename)
    for (j in 1:length(lon)) {
      xyz <- rbind(xyz, cbind(lat, lon[j], sst[,j], land[,j]))
    }
    xyz <- na.omit(xyz)
    if (removeland) 
      xyz <- xyz[which(xyz[, 4] == 1), -4]
    write.table(xyz, file = dest, quote = F, row.names = F, col.names = F)
  }
  nc_close(nc)
  cat("netCDFから形式変換した", length(dir(sstfolder)),
      "日分のxyzファイル (テキスト形式) を次のフォルダに保存しました:\n\n   ", 
      sstfolder, "\n\n")
  cat(paste(rep("=", options()$width), collapse = ""), "\n\n")
  .sstFileVector <<- paste(sstfolder, dir(sstfolder), sep = "/")
  return(sstfolder)
  }