
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
##    ukfsst と analyzepsat の実行に必要なRパッケージのインストールプログラム
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


# ~~~~ はじめに ~~~~
# [注1] 以下の環境構築はお使いのパソコンで初めて経緯度補正を実施しようとする場合
#       に必要な処理です. また, R versionのメジャーアップデート時 (例: 3.4.x -->
#       3.5.x) にも行なってください.
# [注2] 必ず, インターネットに接続してから行なってください.
# [注3] 以下では基本的に, ダウンロードはDL, インストールはINSTと省略しています.
# [注4] Rのコードでは, # (ハッシュ) 以降の記述は行末まで実行されない仕様です.
#       つまり, #が行頭にある命令は実行されません. 以下のコードでは行頭に#を
#       付している命令行が何行かありますので, 必要に応じて#を消して実行下さい. 


# [1] 現行の R versionを確認 ===================================================
R.version # majorが3, minorが4.3 ~ 5.2になっていればよいです


# [2] Rのオプション設定 ========================================================
# _ (1) 文字列を勝手に因子型 (factor) にしない設定 ----------------
options(stringsAsFactors = FALSE) 

# _ (2) RStudioを使用する場合のCRANミラーサイトの設定 -------------
# メニューバーのTools --> Global Options... --> Packages --> CRAN Mirror -->
#   Changeボタンを押して,
#    1) Japan (Tokyo) [https] The Institute of Statistical Mathematics, Tokyo
#    2) Japan (Yonezawa) [https] - Yamagata University
# のどちらかを選ぶ. ApplyボタンかOKボタンで設定完了.

# _ (3) RStudioを使わない場合のCRANミラーサイトの設定 -------------
# CRANのミラーサイト一覧を取得 (data.frameクラスのオブジェクトで返される)
(CRAN.mir <- getCRANmirrors())

# サイト一覧の最初の数行を確認
head(CRAN.mir, n = 6L)

# 国名一覧
unique(CRAN.mir$Country)

# 日本のサイトURLを取得
with(CRAN.mir, CRAN.mir[Country == "Japan", c("URL","City","Host","Comment")])

# ミラーサイトを指定
options(repos = "https://cran.ism.ac.jp/") # ここでは統計数理研究所 (統数研)

# 現在CRANからDLできるパッケージの一覧を取得
(CRAN.pac <- available.packages())
head(CRAN.pac, n = 10L)
nrow(CRAN.pac) # なんと, 13541個も! (最終更新時点)


# [3] パッケージ類のDL & INST ==================================================
# _ (1) devtoolsパッケージのDL & INST --------------
# ここでは, devtoolsパッケージはgithub上のパッケージをDL & INSTするために使用
if (!any('devtools' == installed.packages()[, "Package"])) {
  install.packages("devtools") 
}
# [注] 本解析に対応するRのversion (例えば3.5.1) で初めてdevtoolsをINSTする場合,
# 関連パッケージのソースコードからのINSTを求められることがあります. この場合は,
# コンソール上に次のような質問が表示されるので, コンソール上でYesと質問に続けて
# 入力し, Enter (Return) キーを押してください.
#   質問例:
#   Do you want to install from sources the package which needs compilation? (Yes/no/cancel)
#   入力例:
#   Do you (中略) needs compilation? (Yes/no/cancel) Yes

# devtoolsパッケージのロードとアタッチ
library(devtools)

# _ (2) ukfsstパッケージと関連パッケージをgithubからDL & INST --------------
url <- "https://raw.githubusercontent.com/positioning/kalmanfilter/master/install.r"
devtools::source_url(url = url)

# _ (3) analyzepsatパッケージと関連パッケージをgithubからDL & INST ---------
devtools::install_github('galuardi/boaR') # 解説サイトにはない, この処理が必要
devtools::install_github('galuardi/analyzepsat', dep = T, ref = 'v4.0')

# adehabitat (2018/04/10にCRANのrepositoryから削除されたのでArchiveから利用)
# [注] 後続のadehabitatHRがCRANにある. 仕様は変わっただろうが, 使ってもいいかも.
url <- "https://cran.r-project.org/src/contrib/Archive/adehabitat/adehabitat_1.8.20.tar.gz"
pkgFile <- "adehabitat_1.8.20.tar.gz"
download.file(url = url, destfile = pkgFile)

# adehabitatパッケージの依存パッケージをDL & INST
install.packages(c("tkrplot", "shapefiles"))

# adehabitatパッケージのDL & INST
install.packages(pkgs = pkgFile, type = "source", repos = NULL)

# パッケージリンクの削除
unlink(pkgFile)


# _ (4) データの前処理に使用するパッケージをCRANからDL & INST --------------
# CRANからDL & INST
install.packages("needs") # 複数パッケージを一括でロード, DL, INSTするパッケージ
library(needs)            # まずは, needsパッケージ自身をロード
# [注1] 初めてこれを実行すると次のような質問メッセージがコンソールに表示される.
#       Yes の選択をおすすめします. この例では 1 を質問に続けて入力し, 
#       Enter (Reteun) キーを押す.
#   Should `needs` load itself when it's... needed?
#     (this is recommended) 
# 
#   1: Yes
#   2: No
#
#   Selection: 

# [注2] この設定をあとで変更するには, #を外して, 次のコードを実行してください.
#needs:::autoload(flag = FALSE)

# tidyverseパッケージほか複数のパッケージをロード, DL, INST (CRANから)
needs(R.oo, maps, mapproj, mapdata) 
# [注] (Yes/no/cancel) と聞かれたら Yes, Y, yes, あるはyとコンソールに入力

# 現在のINSTされているパッケージ一覧の表示
library()


# [4] 作業ディレクトリの設定 ===================================================
# 現在の作業ディレクトリ (フォルダ) パスを確認
getwd()

# _ (1) 作業ディレクトリを変更 ----------
wdir <- "/Users/yourname/somefolders/geol" # <-- このパスを適宜変更
setwd(wdir)
# [注] ここで指定したディレクトリに国際水研ホームページからDLしたソースコードと
#      入力例データを置いてください. もし置いていなければ, 移動をお願いします.
#      一連の処理におけるローカルなデータの入出力はこのディレクトリ内で行われる
#      ことを想定しているためです.

# _ (2) ukfsstのサポートRコードのダウンロードと保存 ----------
# [注] この作業は一度実行して保存が完了すれば2度目以降は不要です.
# ukfsstのモデル実行結果を (他のソフトでも使えるように) CSV形式で保存するための
# 関数 fit2csv() をgithubからDL. (なぜかukfsstパッケージには含まれていない)
url <- "https://raw.githubusercontent.com/positioning/kalmanfilter/master/updates/fit2csv.R"
devtools::source_url(url = url)

# DLされたかを確認
ls(pattern = "fit2csv") # [注] コンソール上に "fit2csv" と表示されればOK

# fit2csv() を保存
dump(list = "fit2csv", file = file.path(wdir, "src/func_fit2csv.R"))

# 以降の処理に使わないオブジェクトを削除 (wdir以外を削除)
rm(list = ls(all.names = T, pattern = "[^(wdir)]"))

# _ (3) analyzepsatのサポートRコードのダウンロードと保存 --------------
# [注] この作業も一度実行して保存が完了すれば2度目以降は不要です.
url <- "https://raw.githubusercontent.com/positioning/kalmanfilter/master/support/analyzepsat-hotfix.r"
source_url(url = url)

ls(all.names = T)

# Rオブジェクトの一覧を取得
obj.list <- R.oo::ll()

# functionクラスのオブジェクト名のみ抽出
func.list <- with(obj.list, obj.list[data.class == "function", ])
func.list
(funcs <- func.list$member)

# 隠し関数が表示されないので, それらも取得
(hiddenFuncs <- ls(all.names = T, pattern = "^\\."))

# ダウンロードした関数群を保存
dump(list = c(funcs, hiddenFuncs),
     file = file.path(wdir, "src/funcs_analyzepsat.R"))

################ ~ ここまで出来れば環境構築の準備完了です ~ ###################


# [5] ukfsstの一連の処理を体験 =================================================
library(ukfsst)     # ukfsstパッケージのロード
example(blue.shark) # 解析例の自動実行
# [注1] タグデータ読込み --> 海表面水温の自動取得 --> モデル実行 -->
#         実行結果の表示 --> モデル予測値 (補正後経緯度) の作図まで
# [注2] アメリカのNOAAのウェブサイトから人工衛星観測の海表面水温を取得するので,
#       ネットワークエラーが出ることがあります.

road.map()          # 解析のロードマップ (説明は英語)
######## ~~ 終わり ~~ ########