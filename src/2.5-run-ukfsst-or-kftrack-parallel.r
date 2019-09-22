
## Text Encoding: UTF-8

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -
# The way to change Text Encoding in RStudio
# File --> Reopen with Encoding... --> Choose Encoding -->
#                                 check Show all encodings and select UTF-8
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -
# To save R script after changing Text Encoding for Windows in RStudio
# File --> Save with encoding... --> Choose Encoding -->
#                                 check Show all encodings and select CP932
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -

## == ======================================================================= ==
##                         ukfsst を実行するプログラム
## == ======================================================================= ==
## R version 3.4.3 ~ 3.5.2で動作確認済み
##
## 初  稿: 2017/01/31; 最終更新: 2019/09/18
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
library(needs)
# needs:::autoload(flag = T) # autoload(TRUE)で次回からいきなりneed()使用可能

  # [初回のみで良い] for pathological download error (2019.5.30 CRAN落ち)
  # url <- "https://cran.r-project.org/src/contrib/Archive/pathological/pathological_0.1-2.tar.gz"
  # pkgFile <- "pathological_0.1-2.tar.gz"
  # download.file(url = url, destfile = pkgFile)
  # install.packages(c("assertive.base", "assertive.files", "assertive.numbers",
  #                    "assertive.properties", "assertive.reflection", "assertive.strings",
  #                    "assertive.types")) # dependsパッケージ群
  # install.packages(pkgs = pkgFile, type = "source", repos = NULL)
  # unlink(pkgFile)

needs(tidyverse, stringi, httr, rvest, lubridate, devtools, 
      maps, mapproj, mapdata, data.table, pathological, ukfsst, 
      egg, gginnards, ggpmisc, foreach, doParallel)


# [4] ディレクトリの設定 =======================================================
# 現在の作業ディレクトリ (フォルダ) パスを確認
getwd()

# _ (1) 作業ディレクトリパスを指定 -------------
wdir <- "/Users/yourname/somefolders/geol" # <-- このパスを適宜変更
setwd(wdir)

# _ (2) サポート関数の読み込み -----------------
# ukfsst用
source(file.path(wdir, "src/func_fit2csv.R"))      # ukfsst結果のCSV出力関数
source(file.path(wdir, "src/func_get_oisstV2_highres.R")) 
# OISST 0.25° 1day海表面水温の取得関数 (国際水研HPからのDLファイルに含まれる)


# [5] 解析したいタグデータの読み込み ===========================================
# [注] Lotek社の標識 (LAT292-) の場合は次のプログラムを別途実行し, ukfsstで利用
#      可能な様式でデータセットを作成してください. --> 0-format-LAT292data.r

    # _ (0) どのようなデータ形式が必要かを確認 ------------
    data(blue.shark)        # ukfsstパッケージに含まれる例データ
    head(blue.shark, n = 3) # 例示データの最初の3行
    # day month year    Long    Lat   sst
    #  11     4 2001 201.722 18.875 24.73
    #  16     4 2001 201.190 24.150 24.37
    #  18     4 2001 202.950 12.890 24.73
    
    str(blue.shark)         # データの型等, 構造確認
    # 'data.frame':	45 obs. of  6 variables:
    #  $ day  : num  11 16 18 22 24 26 28 30 2 4 ...
    #  $ month: num  4 4 4 4 4 4 4 4 5 5 ...
    #  $ year : num  2001 2001 2001 2001 2001 ...
    #  $ Long : num  202 201 203 199 201 ...
    #  $ Lat  : num  18.9 24.1 12.9 28.8 22.6 ...
    #  $ sst  : num  24.7 24.4 24.7 24.4 23.8 ...
    
    # [注] いずれも数値型, int (integer) またはnum (numeric), であること. 
    #      1列目: day (日)
    #      2列目: month (月)
    #      3列目: year (年)
    #      4列目: Long (経度) 0 ~ 360 
    #      5列目: Lat (緯度)
    #      6列目: sst (タグの記録した表面水温)
    # --->>> 自分のデータを解析する場合は以上の様式で準備してください.

# _ (1) タグのデータディレクトリの中身を確認 ------------
dir(path = file.path(wdir, "input"), full.names = F)

# _ (2) 弁別可能なファイル名 (例: タグのシリアル番号) を指定 ------------
tagN <- "example"

# _ (3) データの読み込み ------------
filepath <- dir(path = file.path(wdir, "input"), pattern = tagN, full.names = T)
filepath

track <- read.csv(file = filepath)
head(track, n = 2)  # データの最初日を確認 (必ずしも放流日ではない)
tail(track, n = 2)  # データの最終日を確認 (必ずしも再捕日ではない)
class(track)        # データクラスは必ずdata.frameであること

# 経度に負値 (西経) があると不具合が出るので, 0 ~ 360の範囲に直す.
range(track$Long, na.rm = T) # 値の最小最大 (範囲) を確認
track$Long <- with(track, ifelse(Long < 0, Long + 360, Long)) 

# __ (3.5) [必要時] 最初日または最終日のデータ置換  ----------
# [注] 最初日と放流日または最終日と再捕日とが一致していて, 別途, 経緯度や水温
#      情報が判明している場合に行う.
# head(track, n = 3)
# tail(track, n = 3)
# track[1,           c("Long", "Lat", "sst")] <- c(135.281, 32.940, 19.3)
# track[nrow(track), c("Long", "Lat", "sst")] <- c(139.983, 33.550, 20.7)

head(track)
# [注] [8]でのカルマンフィルターの実行では不要な列があると計算エラーがでるため, 
#      モデルの実行の際には例示データ同様の6列 (ukfsstの場合) か5列 (kftrack) の
#      データセットにすること.


# [6] 人工衛星観測の海表面水温データの取得と保存 ===============================
# sst保存用ディレクトリの作成
sstdir <- file.path(wdir, "sst", tagN)
create_dirs(sstdir)
# [注] 新たに作成されればTRUE, すでに存在すればFALSEがコンソールに表示される.

# _ (1) ukfsstパッケージのデータ取得関数を利用 ==================== ------------
# __ (1.1) OISST V2, 1.0 arc-degree, 7 days mean ----------
# データのDL
sst.path <- get.sst.from.server(track[, 1:6], removeland = F, 
                                folder = file.path(sstdir, "oisstV2_1deg7day"))

# __ (1.2) TAGssta (0.1 arc-degree, 8 or 3 days mean) ----------
  ?get.avhrr.sst # get.avhrr.sst() のヘルプ (英語)
  # [注] Arguments節のnday項には 5day か 8day とあるが, 5dayは利用不可のよう.

# 日解像度の指定
day.resol <- "3day"

# 保存フォルダの作成
TAGsstdir <- file.path(sstdir, paste0("TAGssta_0.1deg",day.resol,"/sst_files"))
create_dirs(TAGsstdir)

# データのDL
sst.path <- get.avhrr.sst(track[, 1:6], folder = TAGsstdir, nday = day.resol)
# sst.path <- get.avhrr.sst(track, folder = "tmpdir",
#                           product = "TN2ssta", nday = "1day")

# __ (1.3) TBAssta (0.1 arc-degree, 8 day) ----------
  ?get.blended.sst # get.blended.sst() のヘルプ (英語)
  # [注] Arguments節のnday項には 5day か 8day とあるが, ndayを5dayに変更しても
  #      ダウンロードされるファイル名は8dayの値となる. ただし, 5dayと8dayのデータ
  #      を比較すると水温の値が異なるので, 別々のデータセットからDLしていると判断
  #      される. 関数の設定バグの可能性があるので, 基本は8daysを使う.

# 日解像度の指定
day.resol <- "8day"

# 保存フォルダの作成
TBAsstdir <- file.path(sstdir, paste0("TBAssta_0.1deg",day.resol,"/sst_files"))
create_dirs(TBAsstdir)

# データのDL
sst.path <- get.blended.sst(track[, 1:6], folder = TBAsstdir, nday = day.resol) 

# _ (2) OISST V2 (0.25 arc-degree, 1 day) ========================== -----------
sst.path <- get.oisst.v2.high.resol(
  track = track[, 1:6], folder = file.path(sstdir, "oisstV2_0.25deg1day")
  )

# _ (3) すでにDLしたデータを使う場合 ================================ ----------
dir(sstdir)
spres.timres <- "0.25deg1day"
(sstname <- dir(sstdir, pattern = spres.timres))
(sst.path <- file.path(sstdir, sstname, "sst_files"))


# [7] パラメータの初期値の指定 ================================================
# [注] ここでは, 288通りの初期値シナリオを設定している. 適宜変更して下さい.
inits <- expand.grid(u =    0, 
                     v =    0,
                     D =    c(100, 300, 500), 
                     bx =   0,
                     by =   0,
                     bsst = 0,
                     sx =   seq(0.5, 2.0, by = 0.5),
                     sy =   1:3,
                     ssst = c(0.1, 0.2),
                     r =    seq(50, 200, by = 50),
                     a0 =   0.001,
                     b0 =   0) %>% # 経度と緯度の観測誤差
  # dplyr::select(u, v, D, bx, by, bsst, sx, sy, ssst, r, a0, b0) %>% 
  dplyr::arrange(u, v, D, bx, by, bsst, sx, sy, ssst, r, a0, b0) %>% print(.)

nrow(inits) # シナリオ数


# [8] カルマンフィルターモデルの実行 ====================================
# _ (1) ukfsstかkftrackかを選択 ----------
kf.type <- "ukfsst"
# kf.type <- "kftrack"

if (kf.type == "kftrack") sstname <- ""

# _ (2) 出力保存用のサブフォルダを作成 ----------
# 解析日の年月日
(TDY <- format(Sys.time(), format = "%Y%m%d"))

# 画像フォルダ
fig.dir <- file.path(wdir, "fig", tagN, paste(kf.type, TDY, sep = "-"), sstname)
create_dirs(fig.dir)

# KF適用結果のフォルダ
fit.dir <- file.path(wdir, "fit", tagN, paste(kf.type, TDY, sep = "-"), sstname)
create_dirs(fit.dir)

# _ (3) 地図描画用の設定 ----------
theme_set(new = theme_bw(base_family = "sans"))
detail_theme <- theme(line = element_line(size = 0.3),
                      text = element_text(face = "bold"),
                      axis.text = element_text(colour = "black"),
                      panel.border = element_rect(size = 1.2),
                      panel.grid = element_line(size = 0.1, colour = "black"))

# _ (4) 並列処理可能なCPUの数を確認 --------
parallel::detectCores()     # 使用環境で使える最大CPUコア数
n.cl <- 3
# 注: 最近のPCは平均的なものでもデュアルコア4スレッドのCPUを積んでいるため,
#     ここでは3スレッド分を使うことにしている. より低スペックなPCを使用する
#     場合は次の行の行頭の # を削除して, 使用するCPUの個数を決めてください.
# (n.cl <- detectCores() - 1) # 実際に使用するCPUの数を最大数 - 1 とした.

# _ (5) データ出力の並列処理を実行する関数の作成 -----
f1 <- function() {
  foreach(i = seq_len(nrow(inits)),
          j = rep(seq_len(n.cl), times = nrow(inits)/n.cl), 
          .export = ls(envir = parent.frame()), .packages = loadedNamespaces(),
          .inorder = F, .combine = "c") %dopar% {
            if (kf.type == "ukfsst") {
              # [注] 不要な列があると計算エラーがでるので6列となるようにすること.
              fit <- kfsst(data = track[, 1:6],                            
                           localsstfolder = sst.path, 
                           save.dir = paste(wdir, j, sep = "/_"),
                           u.active =    T, u.init =    inits[i, "u"],
                           v.active =    T, v.init =    inits[i, "v"],
                           D.active =    T, D.init =    inits[i, "D"],
                           bx.active =   T, bx.init =   inits[i, "bx"],
                           by.active =   T, by.init =   inits[i, "by"],
                           bsst.active = T, bsst.init = inits[i, "bsst"],
                           sx.active =   T, sx.init =   inits[i, "sx"],
                           sy.active =   T, sy.init =   inits[i, "sy"],
                           ssst.active = T, ssst.init = inits[i, "ssst"],
                           r.active =    F, r.init =    inits[i, "r"],
                           a0.active =   T, a0.init =   inits[i, "a0"],
                           b0.active =   T, b0.init =   inits[i, "b0"],
                           fix.first =   T,
                           fix.last  =   T)
            } else {
              # kftrack() の実行 (タグの表面水温が使えない場合)
              fit <- kftrack(data = track[, 1:5], 
                             save.dir = paste(wdir, j, sep = "/_"),
                             u.active =  T, u.init =  inits[i, "u"],
                             v.active =  T, v.init =  inits[i, "v"],
                             D.active =  T, D.init =  inits[i, "D"],
                             bx.active = T, bx.init = inits[i, "bx"],
                             by.active = T, by.init = inits[i, "by"],
                             sx.active = T, sx.init = inits[i, "sx"],
                             sy.active = T, sy.init = inits[i, "sy"],
                             a0.active = T, a0.init = inits[i, "a0"],
                             b0.active = T, b0.init = inits[i, "b0"],
                             vscale.a =  T, vscale.init = 1,
                             fix.firs =  T,
                             fix.last =  T)
            }
            
            # __ 2) 実行結果の保存 ------------
            # ___ 1. 全結果を含むリストオブジェクトの保存 ----------
            save(fit,
                 file = file.path(fit.dir,
                                  paste0(tagN,"_",kf.type,"_",i,".Rdata")))
            
            # ___ 2. 主要結果のCSVファイルの保存 ----------
            fit2csv(fit, folder = fit.dir, name = paste0(tagN,"_",kf.type,"_",i))
            # !!! この関数による一組の出力ファイルにはファイル名に接尾がつく
            # (例: fit2a.csv, fit2b.csv, fit2c.csv). 各接尾の意味は
            # <出力ファイル名>-a.csv - 補正された経緯度等
            # <出力ファイル名>-b.csv - パラメータの初期値, 推定値等
            # <出力ファイル名>-c.csv - 尤度, Callしたモデル式など
            
            # ___ 3. モデル予測値と観測値の比較図の保存 -----------
            pdf(file = file.path(fig.dir,
                                 paste0(tagN,"_",kf.type,"_FitPlot_",i,".pdf")),
                width = 15/2.54, height = 15/2.54)
            plot(fit, ci = TRUE)
            dev.off()
            
            remove_dirs(paste(wdir, i, sep = "/_"))
            cat("i =", i, "finished\n")
            Sys.sleep(1)
          }
}

# _ (6) 並列処理の実行 ------
cl <- makeCluster(spec = n.cl, type = "PSOCK", outfile = "")
registerDoParallel(cl = cl)
f1()
stopCluster(cl)

remove_dirs(paste(wdir, seq_len(n.cl), sep = "/_"))

# _ (7) 経路比較地図の関数を作成 -------
f2 <- function() {
  foreach(i = seq_len(nrow(inits)), .inorder = T, # .combine = "c", 
          .export = ls(envir = parent.frame()),
          .packages = loadedNamespaces()) %dopar% {
            # # ___ 4. 観測経緯度と補正経緯度の比較地図の保存 ----------
            mpt <- read_csv(file = file.path(fit.dir,
                                             paste0(tagN,"_",kf.type,"_",i,"a.csv")))
            mpt <- data.table(mpt)
            
            # 描画範囲の抽出
            (minLON <- mpt[ , min(taglon)] - 2)
            (maxLON <- mpt[ , max(taglon)] + 2)
            (minLAT <- mpt[ , min(taglat)] - 2)
            (maxLAT <- mpt[ , max(taglat)] + 2)
            
            region_names <- maps::map("worldHires", plot = F,
                                      xlim = c(minLON, maxLON), ylim = c(minLAT, maxLAT))
            maparea <- map_data("worldHires", regions = region_names$names)
            
            path <- ggplot(data = mpt) + detail_theme +
              geom_polygon(data = maparea, aes(long, lat, group = group), size = 0.1,
                           fill = "gray80", colour = "black") +
              geom_path(aes(taglon, taglat), colour = "gray50", size = 0.2) +
              geom_point(aes(taglon, taglat, colour = as.factor(month)),
                         shape = 16, size = 1) +
              geom_path(data = mpt, aes(mptlon, mptlat), colour = "blue", size = 0.2) +
              geom_point(data = mpt, aes(mptlon, mptlat), colour = "blue", size = 1) +
              geom_point(data = mpt[c(1, nrow(mpt)), ], aes(mptlon, mptlat),
                         shape = c(24,22), stroke = 0.2, fill = "yellow", size = 2) +
              geom_text(data = mpt[c(1, nrow(mpt)), ],
                        aes(x = mptlon, y = mptlat,
                            label = format(ISOdate(year, month, day), "%Y/%m/%d")),
                        hjust = c(1.1, -0.1), size = 2.75, fontface = "bold") +
              coord_fixed(xlim = c(minLON, maxLON), ## -->> 抽出範囲は適宜調整してください
                          ylim = c(minLAT, maxLAT), ## -->> 抽出範囲は適宜調整してください
                          expa = F, ratio = 1/1) +
              labs(x = "Longitude", y = "Latitude", title = paste("Tag No.", tagN),
                   colour = "Month")
            
            ggsave(path, units = "cm", dpi = 300, width = 15, height = 15,
                   file = file.path(fig.dir,
                                    paste0(tagN,"_",kf.type,"_MostProbTrack_",i,".jpg")))
            
            cat("i =", i, "finished\n")
            Sys.sleep(1)
          }
}

# _ (8) 照度推定の結果とukfの結果の重ね描き (単一CPUで実施) --------
registerDoSEQ() # %dopar%を単一CPUで実行. foreach文の動作確認にも使える.
f2()

# _ (9) 後処理 ---------
unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list = ls(name = env), pos = env)
}
unregister()
on.exit(stopCluster(cl))

########### ~~ %%%% おわり %%%% ~~ ##########