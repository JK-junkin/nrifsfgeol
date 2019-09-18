
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
##      ukfsstまたはkftrackのモデル診断パラメータを一覧化するプログラム
## == ======================================================================= ==
## R version 3.4.3 ~ 3.5.2で動作確認済み
##
## 初稿:2018/10/23; 最終更新: 2019/09/18
## 作成者: J.Kinoshita 
## 質問やバグ報告: NRIFSF-SKJG_at_ml.affrc.go.jp (_at_を@に変更して下さい) まで.
## == ======================================================================= ==


# [1] R_GlobalEnv上の全てのRオブジェクトを削除 =================================
rm(list = ls(all.names = T))


# [2] Rのオプション設定 ========================================================
options(stringsAsFactors = F, repos = "https://cran.ism.ac.jp/") # 統数研


# [3] パッケージのロード =======================================================
needs(devtools, data.table, tidyverse, pathological, writexl, zoo, tcltk)


# [4] ディレクトリの設定 =======================================================
# 現在の作業ディレクトリ (フォルダ) パスを確認
getwd()

# _ (1) 作業ディレクトリパスを指定 -------------
wdir <- "/Users/yourname/somefolders/geol" # <-- このパスを適宜変更
setwd(wdir)


# _ (2) モデル結果を出力したディレクトリを指定 ------------
# __ 1) タグ番号を指定 --------------
tagN <- "example"

# __ 2) tagNの出力ディレクトリ上のファイル一覧を取得 ----------
fit.dir <- file.path(wdir, "fit", tagN)
dir(fit.dir, recursive = T)

# 1: モデルタイプで絞り込み
kftype <- "ukfsst"
(kftype.dir <- dir(fit.dir, recursive = T, pattern = paste0(kftype,".+\\.csv")))

# 2: 解析日でさらに絞り込み
date.analy <- "20190305"
(daykft.dir <- kftype.dir[str_which(kftype.dir, pattern = date.analy)])

# 3: 補正に使った人工衛星観測水温でさらに絞り込み
remote.sst <- "0.25deg1day"
(fitdat.dir <- daykft.dir[str_which(daykft.dir, pattern = remote.sst)])

# 不要なオブジェクトの削除
rm(kftype, kftype.dir)


# [5] データの結合, 整形, および出力 ===========================================
# _ (1) Estimates (kalman filterで推定されたパラメータ) のパス ------------
Bs <- file.path(fit.dir, fitdat.dir) %>% 
  .[str_which(., pattern = "b\\.csv$")] %>% print(.)

# パラメータ名を抽出
(params <- read.csv(file = Bs[1], header = T)$parameter)

# _ (2) Model calls (モデルの当てはまり度) のパス --------------
Cs <-  file.path(fit.dir, fitdat.dir) %>% 
  .[str_which(., pattern = "c\\.csv$")] %>% print(.)

# 実行するモデルの数 ---
nmodel <- length(Bs)

# Set progress bar ---
pb <- txtProgressBar(min = 0, max = nmodel, style = 3)

# _ (3) 結合の実行 ------------
list <- data.frame(NULL)

merge_fit_results <- function(i) {

  b <- read.csv(Bs[i], header = T)
  
  act <- b %>% 
    dplyr::select(parameter, active, dataname) %>%
    dplyr::mutate(active = as.character(active),
                  KindOfValues = "Active") %>% 
    tidyr::spread(., key = "parameter", value = "active")
  
  init <- b %>%
    dplyr::select(parameter, init, dataname) %>%
    dplyr::mutate(parameter = factor(parameter, levels = params),
                  init = as.character(init),
                  KindOfValues = "Initial value") %>% 
    tidyr::spread(., key = "parameter", value = "init")
  
  est <- b %>%
    dplyr::select(parameter, estimates, dataname) %>%
    dplyr::mutate(estimates = as.character(estimates),
                  KindOfValues = "Estimates") %>% 
    tidyr::spread(., key = "parameter", value = "estimates")
  
  stdev <- b %>%
    dplyr::select(parameter, stdev, dataname) %>%
    dplyr::mutate(stdev = as.character(stdev),
                  KindOfValues = "Standard deviation") %>% 
    tidyr::spread(., key = "parameter", value = "stdev")
  
  c <- read.csv(Cs[i], header = T)[, 1:6]
  
  one <- c %>% 
    dplyr::left_join(., init, by = "dataname") %>% 
    dplyr::bind_rows(., act, est, stdev) %>% 
    dplyr::mutate(analyDate = date.analy,
                  remoteSst = remote.sst,
                  senario = str_extract(dataname, pattern = "(?<=_)\\d+$") %>% 
                    as.integer(.)) %>% 
    dplyr::select(ncol(.), 1:(ncol(.)-1)) %>% 
    dplyr::arrange(senario)

  list <<- rbind(list, one)

  setTxtProgressBar(pb, value = i)
  rm(b, c, act, init, est, stdev, one)
}

for(i in seq_len(nmodel)) merge_fit_results(i)
list <- dplyr::arrange(list, senario)
# list[, senario := zoo::na.locf(senario)]

# [6] 保存 =====================================================================
write_xlsx(list, path = paste0(
  str_extract(file.path(fit.dir, fitdat.dir)[1], 
              pattern = "^.+(?=\\/[:graph:]+\\.csv$)"),
  "/", tagN, "_Results_of_KFmodels.xlsx"))

########## ~~ %%%% おわり %%%% ~~ ##########