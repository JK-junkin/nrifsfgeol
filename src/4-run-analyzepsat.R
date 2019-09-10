
## Text Encoding: UTF-8

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -
## To save R script as CP932, text encoding for Windows (in RStudio)
## File --> Save with encoding... --> Choose Encoding -->
##                                 check Show all encodings and select CP932
## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -


## == ======================================================================= ==
##                       analyzepsat を実行するプログラム
## == ======================================================================= ==
## R version 3.4.3 ~ 3.5.2で動作確認済み
##
## 初  稿: 2017/01/31; 最終更新: 2019/03/03
## 作成者: J.Kinoshita 
## 質問やバグ報告: NRIFSF-SKJG_at_ml.affrc.go.jp (_at_を@に変更して下さい) まで.
##
## このプログラムの核となるコードは, 基本的には ukfsst と analyzepsat のgithubに
## 掲載されているコードです. 説明部分は和訳 (意訳) しています.
## 転載元のURLを以下に列挙します.
## https://github.com/positioning/kalmanfilter/wiki/ArticleQuickStart
## https://github.com/positioning/kalmanfilter/wiki/ArticleUkfsst
## https://github.com/positioning/kalmanfilter/wiki/Analyzepsat
## https://github.com/positioning/kalmanfilter/wiki/analyzepsatUD
## == ======================================================================= ==


# [1] R_GlobalEnv上の全てのRオブジェクトを削除 =================================
rm(list = ls(all.names = T))


# [2] Rのオプション設定 ========================================================
options(stringsAsFactors = F, repos = "https://cran.ism.ac.jp/") # ここは統数研


# [3] パッケージのロード =======================================================
needs(analyzepsat, adehabitat, devtools, maps, mapproj, mapdata, tcltk,
      tidyverse, data.table, pathological, egg, gginnards, ggpmisc, ncdf4)


# [4] ディレクトリの設定 =======================================================
# 現在の作業ディレクトリ (フォルダ) パスを確認
getwd()

# _ (1) 作業ディレクトリパスを指定 -------------
wdir <- "/Users/yourname/somefolders/geol" # <-- このパスを適宜変更
setwd(wdir)

# _ (2) サポート関数の読み込み -----------------
source(file.path(wdir, "src/funcs_analyzepsat.R")) # analayzepsatの処理に必要


# [5] データの準備 =============================================================
# _ (0) どのようなデータ形式が必要かを確認 ------------
data(big.241, package = "kftrack") # 例示データ
head(big.241, n = 3)               # 例示データの最初の3行を表示
# day month year    long  lati
#  21     1 1999 201.750 18.65
#  22     1 1999 204.520 20.00
#  23     1 1999 206.086 22.00
# [注] 事例データにあるのはday, month, year, long, latの5つ

str(big.241)
# 'data.frame':	76 obs. of  5 variables:
#  $ day  : num  21 22 23 24 25 26 27 28 29 30 ...
#  $ month: num  1 1 1 1 1 1 1 1 1 1 ...
#  $ year : num  1999 1999 1999 1999 1999 ...
#  $ long : num  202 205 206 204 205 ...
#  $ lati : num  18.6 20 22 23.5 21.5 ...

# 水温と最大遊泳深度のダミーデータ列を作成
# [注] 例示データにはタグの水温と最大遊泳深度 (maxz) が (なぜか) ない. 
#      直下の処理は元の説明サイトにも書いてあります.
big.241$sst  <- 10  # 10 °C
big.241$maxz <- -10 # 10 m

head(big.241, n = 3)
# day month year    long  lati sst maxz
#  21     1 1999 201.750 18.65  10  -10
#  22     1 1999 204.520 20.00  10  -10
#  23     1 1999 206.086 22.00  10  -10
# -->> この形式で準備しましょう.

# _ (1) 解析したいデータの読み込み -----------
# __ 1) 弁別可能なタグの名前を指定 --------------
dir(path = file.path(wdir, "input"))
tagN <- "example"

# __ 2) タグデータの読み込み ------------
orgfile <- dir(path = file.path(wdir, "input"), pattern = tagN, full.names = T)
orgfile
track <- read.csv(file = orgfile)
head(track, n = 3)

# 最大遊泳深度が正の値の場合は負の値に変換
# [注] タグの仕様にもよるので仕様書等をきちんと確認すること.
summary(track[, 7]) # 入力値を確認
track[, 7] <- ifelse(track[, 7] > 0, -track[, 7], track[, 7])

# 最大遊泳深度がNAの箇所には便宜的に0を代入
track[, 7] <- ifelse(is.na(track[, 7]), 0, track[, 7])
head(track); tail(track)

# __ 3) fitデータのディレクトリを指定 ------------
# 0: tagNの, モデル適用結果を格納したフォルダ内にあるファイル一覧を取得
fit.dir <- file.path(wdir, "fit", tagN)
dir(fit.dir, recursive = T)

# 1: モデルタイプで絞り込み
kftype <- "ukfsst"
dat.kft <- dir(fit.dir, recursive = T, pattern = paste0(kftype,".+\\.Rdata"))

# 2: 解析日でさらに絞り込み
date.analy <- "20190305"
(dat.daykft <- dat.kft[str_which(dat.kft, pattern = date.analy)])

# 3: 補正に使った人工衛星観測水温でさらに絞り込み
sst.name <- "0.25deg1day"
(fits <- dat.daykft[str_which(dat.daykft, pattern = sst.name)])

# __ 4) 補正したいfitデータの読み込み ----------
# シナリオ番号を指定 ---
# [注] モデル適用結果一覧のエクセルファイル (Results_of_KFmodels.xlsx) や作図の
#      結果を見ながら選ぶと良いかと思います. nlogL の小さいシナリオを選ぶなど.
snr <- 1

(fitfile <- fits[str_which(fits, pattern = paste0("_", snr, "\\.Rdata"))])
load(file = file.path(fit.dir, fitfile)) # [注] オブジェクト名は fit

# 不要なオブジェクトの削除
rm(orgfile, kftype, dat.kft, date.analy, dat.daykft, sst.name, snr)

# _ (2) NOAAサーバーから海底地形データを取得 ----------
# 緯度経度の最大最小を確認
summary(track[, 4:5]) # 経度, 緯度

# 取得範囲は少し広く指定
lims <- sapply(track[, 4:5], function(x) {
  min <- floor(min(range(x, na.rm = T)))
  max <- ceiling(max(range(x, na.rm = T)))
  
  min <- min - min %% 5 - 3
  max <- max + 3
  return(c(min, max))
})
lims

# 海底地形の解像度を指定 (0.5 arc-min または 1 arc-min)
bres <- 1

# 海底地形データの保存フォルダを作成
bath.dir <- file.path(wdir, "bath", tagN, paste0(bres, "arc-min"))
create_dirs(bath.dir)

# __ 1) データのダウンロード (要オンライン) ----------
# 経度 -180~180 (負は西経), 緯度 -90~90 (負は南緯), 解像度 0.5か1 arc-minutes
# [注] 海表面水温データは経度が 0 ~ 360の値であった. 海底地形データとは異なる.
lims[, 1] <- ifelse(lims[, 1] > 180, lims[, 1] - 360, lims[, 1])

bath <- get.bath.data(lonlow = lims[1, 1], lonhigh = lims[2, 1], 
                      latlow =  lims[1, 2], lathigh =  lims[2, 2], # 
                      res = bres, folder = bath.dir)

# __ 2) DLした海底地形データの再利用 (オフライン時) ----------
# 読み出し関数を定義 (get.bath.dataをほぼ流用)
reuse.bath.data <- function(folder, seaonly = T) {
  
  rot90 <- function(A) {
    n <- dim(A)[2]
    A <- t(A)
    A[n:1, ]
  }
  fliplr <- function(A) {
    A = (A)[(ncol(A)):1, ]
    A
  }
  
  res <- str_extract(folder, pattern = "(?<=\\/).{1,3}(?=arc-min$)")
  res <- as.double(res)
  if (res == 1) { bathid = "topo" } else if (res == 0.5) { bathid = "z" }
  
  fname = paste(folder, "request.nc", sep = "/")
  nc <- nc_open(fname)
  lon <- as.numeric(ncvar_get(nc, varid = "longitude"))
  lat <- as.numeric(ncvar_get(nc, varid = "latitude"))
  bdata = ncvar_get(nc, varid = bathid)
  if (res == 0.5) bdata = t(fliplr(bdata))
  bdata = rot90(bdata)
  lat = lat[order(lat)]
  if (seaonly == T) bdata[bdata >= 0] = 1
  bathy = list(lon = lon, lat = lat, data = bdata)
  return(bathy)
}
bath <- reuse.bath.data(folder = bath.dir, seaonly = T)

# _ (3) KalmanFilterの結果から信頼区間情報を抽出して元データに結合 ----------
# 元データの経度を -180から180の範囲に変換 (海底地形データに合わせる)
track[, 4] <- ifelse(track[, 4] > 180, track[, 4] - 360, track[, 4])

# データの抽出と結合
fitrack <- analyzepsat::prepb(kfit = fit, prepf = track)


# [6] analyzepsatによる補正の実行 ==============================================
# _ (1) 補正の実施 ----------
bathrack <- make.btrack(fmat = fitrack, bathy = bath)
# [注] 次のような警告メッセージが出るが無視して構わない.
#   In sqrt(cov(samp)) :  計算結果が NaN になりました
# -->> NaNは数値計算の過程で計算不能であった場合に出力される "非数" を表す. 
#      例えば, 0や対数 (log()など) を0で割った場合, NaNとなる.

# 警告文を消去 (気になった時に)
#assign("last.warning", NULL, env = baseenv())

# _ (2) 補正経路データの出力 ----------
#  最も下位の出力フォルダのパスを取得
(end.fit.dir <- file.path(fit.dir, str_extract(fitfile, "^.+(?=\\/)")))

# 読み込んだfitデータ名を抽出
(snr.fileN <- str_extract(fitfile, paste0("(?<=\\/)", tagN, ".+(?=\\.Rdata$)")))

# 出力ファイル名を作成
(out.btrk <- paste0(snr.fileN, "_BathCor.csv"))

# 出力フォルダに保存
write.csv(x = bathrack, row.names = F, file = file.path(end.fit.dir, out.btrk))

# _ (3) 補正経路の描画と出力 ----------
# 保存フォルダパスの指定
(end.fig.dir <- end.fit.dir %>% 
   str_replace(., pattern = paste0("fit(?=\\/", tagN, "\\/)"), replace = "fig"))

# 陸地データを読み込み (trackitパッケージから)
data(gmt3, package = "trackit")

summary(gmt3)
# [注] gmt3データの経度 (longitude) は 0 ~ 360 の範囲 (ややこしい!). なので, 
#      西経データの場合は360を加えて, gmt3データに合わせる.
bathrack[, 8] <- ifelse(bathrack[, 8] < 0, bathrack[, 8] + 360, bathrack[, 8])

# 描画範囲を指定 (少し広くとる)
lims <- sapply(bathrack[, 8:9], function(x) {
  min <- floor(min(range(x, na.rm = T)))
  max <- ceiling(max(range(x, na.rm = T)))
  
  min <- min - min %% 5 - 3
  max <- max + 3
  return(c(min, max))
  })
lims

# 画像のアスペクト比
(aspect <- diff(lims[, 2])/diff(lims[, 1]))

# オプション: 色名の16進数表記を取得
as.hexmode(col2rgb(col = "cyan"))

# __ 図1: 海底地形による補正後経路と信頼区間 ----------
pdf(file = file.path(end.fig.dir, paste0(snr.fileN, "_BathCorTrack.pdf")),
    width = 15/2.54, height = 15 * aspect/2.54)
par(mar = c(4, 4, 3, 4)) 
plot(NULL, xlim = lims[, 1], ylim = lims[, 2], typ = 'l', axes = F, asp = 1,
     xlab = "Longitude", ylab = "Latitude", main = "Bathy-correction track")
rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4],col = "#00ffff3f")
grid(lwd = 0.1, col = "black", lty = "41")
plot.btrack(bathrack, offset = 0, add = T, ci = T, bathy = bath, cex = 1.5)
polygon(gmt3, col = 'black')
degAxis(1); degAxis(2)
.add.month.scale()
dev.off()

# __ 図2: カルマンフィルターによる推定経路と海底地形補正後経路の比較 --------
pdf(file = file.path(end.fig.dir, paste0(snr.fileN, "_CompareKF-BCtrack.pdf")),
    width = 15 * 2/2.54, height = 15 * aspect/2.54)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 5))
# Kalman filterによる経路
plot(NULL, xlim = lims[, 1], ylim = lims[, 2], typ = 'l', axes = F, asp = 1,
     xlab = "Longitude", ylab = "Latitude")
rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4], col = "#00ffff3f")
grid(lwd = 0.1, col = "black", lty = "41")
polygon(gmt3, col = 'black')
plot.btrack(fitrack, xlims = lims[, 1], ylims = lims[, 2], add = T, cex = 1.5)
mtext(text = "Most probable track", line = 1, font = 2)
degAxis(side = 1); degAxis(side = 2)
.add.month.scale()
# 海底地形補正による経路
plot(NULL, xlim = lims[, 1], ylim = lims[, 2], typ = 'l', axes = F, asp = 1,
     xlab = "Longitude", ylab = "Latitude")
rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4], col = "#00ffff3f")
grid(lwd = 0.1, col = "black", lty = "41")
polygon(gmt3, col = 'black')
plot.btrack(bathrack, xlims = lims[, 1], ylims = lims[, 2], add = T, ci = T,
            cex = 1.5)
mtext(text = "Bathy-correction track", line = 1, font = 2)
degAxis(side = 1); degAxis(side = 2)
dev.off()

# __ 図3: 利用分布図と固定カーネル密度図の比較 ----------
# (1) 利用分布 (utilization distribution, 略してUD) の計算 ---
# Step 1: 海底地形からの分布可能性を考慮したカーネル密度の算出
kd1 <- track2KD(bathrack, xsize = 0.1, ysize = 0.1, # 警告が出るが, 気にしない
                range.x = lims[, 1], range.y = lims[, 2])
# Step 2: カーネル密度から利用分布の計算 
ud1 <- kern2UD(kd1)

# UDの凡例の目盛り位置の設定
ilabs = c(.1, .3, .5, .75, .95) * 100
axis.args = list(at = ilabs, labels = paste(round(ilabs), '%'))

# (2) 固定カーネル密度の計算 ---
# Step 1: 経路データのみからカーネル密度 (固定カーネル密度) を計算
fkern <- kernelUD(bathrack[, 8:9])
# Step 2: 固定カーネル密度から利用分布の計算
ukern <- getvolumeUD(fkern)

# (3) 保存 ---
pdf(file = file.path(end.fig.dir, paste0(snr.fileN, "_CompareUD-Kernel.pdf")),
    width = 15 * 2/2.54, height = 15 * aspect/2.54)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 5))
# (左図) UDのタイルプロット
image.asc(ud1, zlim = c(0, 0.99), xlim = lims[, 1], ylim = lims[, 2], add = F,
          col = gray.colors(100, start = 0, end = 1), 
          xlab = "Longitude", ylab = "Latitude", axes = F)
rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4],col = "#00ffff3f")
image.asc(ud1, zlim = c(0, 0.99), xlim = lims[, 1], ylim = lims[, 2], add = T,
          col = gray.colors(100, start = 0, end = 1), xlab = '', ylab = '')
polygon(gmt3, col = "black")
mtext(text = "Utilization distribution", line = 1, font = 2)
degAxis(1); degAxis(2)
box(lwd = 2)
# UDの凡例を追加
image.plot(matrix(c(0, 100)), col = gray.colors(100, start = 1, end = 0),
           smallplot = c(0.85, 0.87, 0.25, 0.75), legend.only = T, 
           axis.args = axis.args)
# 海底地形補正後経路の追加
data(ATL); data(myramps)
plot.btrack(bathrack, add = T, ci = F, axes = F, cex = 1)

# (右図) 固定カーネル密度図
image.khr(fkern, zlim = c(0, 0.99), xlim = lims[, 1], ylim = lims[, 2], 
          xlab = "Longitude", ylab = "Latitude", axes = F)
          # [注] add引数を入れるとエラーが出る.
rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4], col = "#00ffff3f")
mtext(text = "Fixed kernel density", line = 1, font = 2)
polygon(gmt3, col = "black")
degAxis(1); degAxis(2)
box(lwd = 2)
dev.off()

########## ~~ おわり ~~ ##########