# 水産研究・教育機構 国際水産資源研究所のホームページで公開中のRスクリプト（最新版）が置いてあるページ
このページには, 水産研究・教育機構 国際水産資源研究所のホームページ (http://fsf.fra.affrc.go.jp/Tag/Atag_proc.html) で公開しているRコードの最新版を置いています.  

## 説明 Description
このページからは以下のRコードとテキストファイルをダウンロードできます.  
  - [0-format-LAT292data.r](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/0-format-LAT292data.r)  
  - [1-install-needed-libraries.r](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/1-install-needed-libraries.r)  
  - [2-run-ukfsst-or-kftrack.r](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/2-run-ukfsst-or-kftrack.r)  
      - [2.5-run-ukfsst-or-kftrack-parallel.r](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/2.5-run-ukfsst-or-kftrack-parallel.r)  
  - [3-listup-kalmanfilter-fitResults.r](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/3-listup-kalmanfilter-fitResults.r)  
  - [4-run-analyzepsat.R](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/4-run-analyzepsat.R)  
  - [func\_get\_oisstV2_highres.R](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/func_get_oisstV2_highres.R)  
  - [ReadMe.txt](https://github.com/JK-junkin/nrifsfgeol/blob/master/src/ReadMe.txt)  

1. これらのRコードは, 照度センサー付き記録型電子標識 (主としてLAT2910, Lotek Wireless Inc.) データに基づくカツオの移動経路推定・補正を行うためのコードです.  

2. 解析に利用した重要なRパッケージは[ukfsst](https://github.com/positioning/kalmanfilter/wiki)と[analyzepsat](https://github.com/positioning/kalmanfilter/wiki/Analyzepsat)です.  

## 使い方 Usage
1. 各Rコード (〇〇.R または 〇〇.r) を各自のパソコンにダウンロードしてください.  

2. 各自のパソコンのフォルダ構造は以下を想定しています.<sup>[*](#mfn1)</sup>  
```R
(C:/Users/YOURNAME/Documents や /Users/YOURNAME/Documents など)
└── geol
    ├── LAT292data # ここにLAT292, LAT281などの元データを置く
    ├── input      # 整形されたモデルインプットデータを置く
    └── src        # ソースコードを置く
        ├── 0-format-LAT292data.r
        ├── 1-install-needed-libraries.r
        ├── 2-run-ukfsst-or-kftrack.r
        ├── 3-listup-kalmanfilter-fitResults.r
        ├── 4-run-analyzepsat.R
        ├── ReadMe.txt
        └── func_get_oisstV2_highres.R
```
3. Lotek社の記録型電子標識データ (LAT292, LAT281など) を解析する場合は`0-format-LAT292data.r`のコードから順番に実行してください. それ以外のデータは`1-install-needed-libraries.r`のコードから順に実行してください. `4-run-analyzepsat.R`のコードは海底地形による補正が必要な場合に実行してください. 陸地のない外洋を遊泳していた場合など, 海底地形による補正が不要なデータもあります.

4. Lotek社以外の電子標識データを用いる場合は**ukfsst**が必要とする所定の様式に整形する必要があります. 所定の様式とは[この様式](https://github.com/positioning/kalmanfilter/wiki/ArticleUkfsst#input-data-format)です.  

---
<a name="mfn1">*</a>: [国際水産資源研究所のホームページ](http://fsf.fra.affrc.go.jp/Tag/Atag_proc.html)に公開している概要説明スライドのp.113-120も参照ください.  

## インストール方法 Install
ここでは注意していただきたい環境構築の方法を説明します.  
1. Windowsで処理を行う場合, 別途[__Rtools__](https://cran.ism.ac.jp/bin/windows/Rtools/)のダウンロード & インストールが必要です. リンク先のページからご自身の使用しているRのバージョンに合ったRtools (大抵の場合は[Rtools35.exe](https://cran.ism.ac.jp/bin/windows/Rtools/Rtools35.exe)だろうと思います) を選択し, ご自身のパソコン環境を整えてください.  

2. 上記コードで使用している __pathological__ パッケージは2019年5月30日にCRANのパッケージリポジトリから削除されたようです ([こちら](https://cran.r-project.org/web/packages/pathological/index.html)). したがって, 通常のパッケージのダウンロード方法ではうまくいかないため, 上記プログラム中で別の手順を踏んでダウンロード & インストールしています (= 最後に公開されていたバージョンのアーカイブをダウンロード & インストール). 

## 依存関係 Requirement
### Rのバージョン
- R (3.4.3 ~ 3.5.2で動作確認済み)

### 各コードで使用しているRパッケージ
1. **0-format-LAT292data.r**  
	data.table  
	devtools  
	lubridate  
	mapdata  
	mapproj  
	maps  
	needs  
    pathological (2019.05.30 CRAN package repositoryから削除)  
	tidyverse  
    zoo  

1. **1-install-needed-libraries.r**  
	devtools    
	mapdata  
	mapproj  
	maps  
	needs  
	R.oo  
	ukfsst  

1. **2-run-ukfsst-or-kftrack.r (2.5-run-ukfsst-or-kftrack-parallel.r)**  
	data.table  
	devtools  
	egg  
	gginnards  
	ggpmisc  
	mapdata  
	mapproj  
	maps  
	needs  
	pathological (2019.05.30 CRAN package repositoryから削除)  
	tidyverse  
	ukfsst  

1. **3-listup-kalmanfilter-fitResults.r**  
	data.table  
	devtools  
	needs  
	pathological (2019.05.30 CRAN package repositoryから削除)  
	tcltk  
	tidyverse  
	writexl  
	zoo  

1. **4-run-analyzepsat.R**  
	adehabitat  
	analyzepsat  
	data.table  
	devtools  
	egg  
	gginnards  
	ggpmisc  
	mapdata  
	mapproj  
	maps  
	ncdf4  
	needs  
	pathological (2019.05.30 CRAN package repositoryから削除)  
	tcltk  
	tidyverse  

1. **func\_get\_oisstV2_highres.R**  
	date  
    lubridate  
	ncdf4  
	pathological (2019.05.30 CRAN package repositoryから削除)  
    rvest  
	tidyverse  

## その他の特徴 Feature
(工事中)  

## 質問, 提案など Contribution
プログラムコードを走らせてみたがエラーや警告が出て動かないなどの問題が出た場合は, お手数ですが, このページから**Issues**を作成していただくか下記のメールアドレスへお知らせください.

## ライセンス Licence
本コードはいずれも __GPLv3__ です.  

参考  
- BSD (ukfsstパッケージ)  
- GPLv3 (analyzepsatパッケージ)  

## 作成者 Author
水産研究・教育機構 国際水産資源研究所 かつおグループ (NRIFSF-SKJG@ml.affrc.go.jp)  
Junji Kinoshita (kinoshitaj@affrc.go.jp)

## リンク集 Links
- [国際水産資源研究所 データベース等](http://fsf.fra.affrc.go.jp/Tag/Atag_proc.html)  
- [『水産技術』11巻2号に掲載の技術報告](https://www.fra.affrc.go.jp/bulletin/fish_tech/11-2/110203.pdf)
- [ukfsstのgithub wikiページ](https://github.com/positioning/kalmanfilter/wiki)  
- [analyzepsatのgithub wikiページ](https://github.com/positioning/kalmanfilter/wiki/Analyzepsat)  
