
## Text Encoding: UTF-8

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -
## To save R script as CP932, text encoding for Windows (in RStudio)
## File --> Save with encoding... --> Choose Encoding -->
##                                 check Show all encodings and select CP932
## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -


## == ======================================================================= ==
##                 Lotek製アーカイバルタグLAT292のデータを
##            ukfsst または kftrack の入力様式に変換するプログラム
## == ======================================================================= ==
## 初稿: 2018/06/19 ; 最終更新: 2019/03/06
## 作成者: 木下 順二 (ご質問やバグ報告はこちらまで --> kinoshitaj@affrc.go.jp)
## 必要なRのversion: 3.4.3 ~ 3.5.2で動作確認
## == ======================================================================= ==


# [1] R_GlobalEnv上の全てのRオブジェクトを削除 =================================
rm(list = ls(all.names = T))


# [2] Rのオプション設定 ========================================================
options(stringsAsFactors = F, repos = "https://cran.ism.ac.jp/") # ここは統数研


# [3] パッケージのロード =======================================================
# install.packages("needs")
library(needs)
needs(devtools, tidyverse, lubridate, data.table, maps, mapproj, mapdata,
      pathological, zoo)


# [4] ディレクトリの設定 =======================================================
# 現在の作業ディレクトリ (フォルダ) パスを確認
getwd()

# _ (1) 作業ディレクトリパスを指定 -------------
wdir <- "/Users/yourname/somefolders/geol" # <-- このパスを適宜変更
setwd(wdir)

# データディレクトリの指定
ddir <- file.path(wdir, "LAT292data")
dir(ddir)


# [5] データの読み込みと加工 ===================================================
# _ (1) 本日の日付 (出力ファイル用に) ----------
TDY <- format(Sys.time(), "%Y%m%d")

# _ (2) 弁別可能なファイル名 (例: タグのシリアル番号) を指定 ------------
tagN <- "example"

# 当該タグの放流-再捕日を指定
releas <- "2018/04/04"  # 放流日
recapt <- "2018/04/29"  # 再捕日

# 放流-再捕経緯度を指定 (わかる場合に)
# 経度は東経ベースの0 ~ 360 arc-degree, 緯度は北緯ベースの-90 ~ 90 arc-degree
relpos <- list(135.28, 32.93)     # list(longitude, latitude)
recpos <- list(139.98, 33.55)

# 放流-再捕日の水温を指定 (わかる場合に)
ssts <- c(19.3, 20.7) # c(放流日の水温, 再捕日の水温) 不明な場合は NA とする.
names(ssts) <- c("release", "recapture")

(tagfile <- dir(ddir, full = T, pattern = tagN))
# [1] "./data/292B-xxxx.csv"                    # 照度による推定経緯度
# [2] "./data/LAT292_xxxx_yymmdd_hhmmss_00.csv" # ログデータ

# _ (3) 推定経緯度データを読み込む ----------
pos <- data.table::fread(tagfile[str_which(tagfile, pattern = "292B-.+\\.csv")])
# [注] data.tableクラスなのでdata.frameとは少し挙動が異なります.
pos
str(pos)

# 放流から再捕までの期間を抽出
pos[, date := dmy(`dd/mm/yy`)]
pos <- pos[date >= ymd(releas) & date <= ymd(recapt), .(date, LonN, LatN)]

# 放流再捕の経緯度を代入
pos[date == ymd(releas), c("LonN", "LatN") := relpos]
pos[date == ymd(recapt), c("LonN", "LatN") := recpos]

# _ (4) 大きく外れた値を補間 ----------
# まず, 現在の経緯度を地図上に描画 (可視化する)
as.hexmode( col2rgb("gray50") ) # 塗りつぶし色名を16進数に変換
as.hexmode(128)                 # 50 % 透明度 (128 = 256/2) の16進数を取得
lon_range <- c(120, 160)        # 描画範囲 (経度)
lat_range <- c( 10,  50)        # 描画範囲 (緯度)

m <- map("world2", xlim = lon_range, ylim = lat_range, plot = F)

# 切り取り範囲の描画と保存 (この範囲以外は線形補間される) ---
# 外れ値の条件設定 (説明できる理由を持ちましょう)
summary(pos)
lon_limit <- c(130, 155) # 適宜この値を変更
lat_limit <- c( 15,  45) # 適宜この値を変更

# 外れ値の線形補間 (端欠損の場合は直前の値を代入) ---
pos[, cLon := LonN]
pos[, cLat := LatN]
pos[LonN < lon_limit[1] | LonN > lon_limit[2] | 
      LatN < lat_limit[1] | LatN > lat_limit[2], c("cLon", "cLat") := NA]
pos[, cLon := round(na.fill(cLon, method = "linear", "extend"), digits = 3)]
pos[, cLat := round(na.fill(cLat, method = "linear", "extend"), digits = 3)]

# 保存先フォルダの作成
clip.plot.dir <- file.path(wdir, "fig", tagN, "input_clipped_area")
create_dirs(clip.plot.dir)

# 描画と保存
cairo_pdf(file = paste0(clip.plot.dir, "/",tagN,"-clipped-area-",TDY,".pdf"),
          width = 7, height = 7)
maps::map("world2", regions = m$names, xlim = lon_range, ylim = lat_range, 
          lwd = 0.3, fill = T, col = "#7f7f7f80", pty = "s") # 50%透明度
map.axes(las = 1)
with(pos, lines(x = LonN, y = LatN, lwd = 0.5, col = "black"))
with(pos, points(x = LonN, y = LatN, col = "black", pch = 4, cex = 0.7))
## 補間後の経路を重ね描き
rect(xleft = lon_limit[1], ybottom = lat_limit[1], 
     xright = lon_limit[2], ytop = lat_limit[2],
     angle = 0, border = "blue", lty = "62F6")
with(pos, lines(x = cLon, y = cLat, lwd = 1, col = "red"))
with(pos, points(x = cLon, y = cLat, col = "red", pch = 16, cex = 0.6))
dev.off()

# _ (5). ログデータを読み込む ----------
log <- fread(tagfile[str_which(tagfile, pattern = "_00\\.csv")])
log
str(log) # 読み込みが正常に行われたかを確認
# [注] LAT292シリーズの初期ロットのタグは, 読み込みエラーが出ることがある.
#      例えば, serial No.が 09xx 番台ではエラーが出た.
#      原因はdelimeterがスペースになっているからのようである.

# 別の読み込み処理 (読み込み不具合がある場合) 
# c(0977, )
# log <- fread(tagfile[str_which(tagfile, pattern = "_00\\.csv")], sep = " ")
# --> データは9列分しかないとのwarningがでた.
# log      # ははぁ
# str(log) # たしかに
# names(log)[1:9] <- c("Rec", "Date", "Time", "IntTemp [C]", "ExtTemp [C]",
#                      "Pressure [dBars]", "LightIntensity", "WetDryState",
#                      "C_TooDimFlag")
# log <- log[, -(10:13)]
# log # とりあえず大丈夫そう. 

# 放流から再捕までの期間を抽出
log[, date := ymd(Date)]
log <- log[date >= ymd(releas) & date <= ymd(recapt), ]

# 水圧を深度に変換
# [注] 海底地形による補正を行うanalyzepsatでは, 深度は負の値を想定している.
#      LAT292シリーズは 水圧 (正の値) で記録される仕様であることに留意する.
# -- 1 dBar = 1 deci bar = 10,000 Pa (==> 10 dBar = 100,000 Pa)
# -- 1 気圧 = 101,325 Pa = 水深10 m ==> 水深1 m = 10132.5 Pa = 1.01325 dBar
log[, depth := -`Pressure [dBars]`/1.01325]

# 表面水温と最大遊泳深度の計算と抽出
log <- log %>% dplyr::group_by(date) %>% 
  dplyr::mutate(maxdep = min(depth, na.rm = T)) %>% 
  dplyr::filter(depth > -5 & depth <= 0) %>%
  dplyr::summarise(sst = mean(`ExtTemp [C]`, na.rm = T), 
                   maxdep = min(maxdep, na.rm = T))

# _ (6) 経緯度データと水温-深度データの (posとlog) を紐付け結合 ----------
pos2 <- left_join(x = pos, y = log, by = "date") %>% as.data.table(.)

# _ (7) データの微調整 ----------
# inputの経度緯度を決定
if (any(c("cLon", "cLat") %in% names(pos2))) { # 外れ値の線形補間を行った場合
  pos2[, Long := cLon]
  pos2[, Lat := cLat]
} else {                                       # 外れ値補間を行わなかった場合
  pos2[, Long := LonN]
  pos2[, Lat := LatN]
}

# 水温, 遊泳深度の小数点以下の有効桁数を3桁にする (計算時間短縮のため)
# 現在の水温, 深度の桁数
unique(nchar(pos2$sst))    # e.g., 16 NA  5  4  6  7  8 15 -->> ...これは!
unique(nchar(pos2$maxdep)) # e.g., 16 NA 15 14             -->> ...これは!

# 丸め処理
pos2[, sst := round(sst, digits = 3)]
pos2[, maxdep := round(maxdep, digits = 3)]

# 確認
unique(nchar(pos2$sst))    # e.g., 6 5     -->> good !
unique(nchar(pos2$maxdep)) # e.g., 6 7 8 5 -->> nice !

# 放流日, 再捕日の水温を代入
pos2[date == ymd(releas) & is.na(sst), sst := ssts["release"]]
pos2[date == ymd(recapt) & is.na(sst), sst := ssts["recapture"]]

# 日付を年, 月, 日に分割し, 列順の入れ替え
pos2[, day := day(date)]
pos2[, month := month(date)]
pos2[, year := year(date)]
pos2 <- pos2[, .(day, month, year, Long, Lat, sst, maxdep)]

# 水温を図示して, 異状データがあるかを確認 ---------
plot(data = pos2, sst ~ ISOdate(year, month, day), type = "b")

# sstが0°C未満の場合は一旦NAとし, 補間
pos2[sst < 0, sst := NA]
pos2[, sst:= round(na.fill(sst, method = "linear", "extend"), digits = 3)]


# [6] 出力保存 =================================================================
input.dir <- file.path(wdir, "input")
create_dirs(input.dir) # FALSE なのですでにある.

write.csv(x = pos2, file = paste0(input.dir, "/pos_",tagN,"_",TDY,".csv"),
          row.names = FALSE)

########## ~~ おわり ~~ ##########