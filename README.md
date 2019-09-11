# nrifsfgeol
このページは, 水産研究・教育機構 国際水産資源研究所のホームページ (http://fsf.fra.affrc.go.jp/Tag/Atag_proc.html) で公開しているRコードの最新版をダウンロードできます.

## 説明 Description
このページからは以下のRスクリプトとテキストファイルがダウンロードできます.  
	0-format-LAT292data.r  
	1-install-needed-libraries.r  
	2-run-ukfsst-or-kftrack.r  
	<span style="color: gray; ">(2.5-run-ukfsst-or-kftrack-parallel.r)</span>  
	3-listup-kalmanfilter-fitResults.r  
	4-run-analyzepsat.R  
	func\_get\_oisstV2_highres.R  
	ReadMe.txt  

これらのRスクリプトは, かつおグループがこれまで実施してきた, 照度センサー付き記録型電子標識 (LAT2910, Lotek Wireless Inc.) データに基づくカツオの移動経路推定・補正のためのコードです. 解析に利用したRのパッケージはukfsstとanalyzepsatです.

## その他の特徴 Feature
(工事中)

## 依存関係 Requirement
### Rのバージョン
- R (3.4.3 ~ 3.5.2で動作確認済み)

### 各スクリプトで使用しているRパッケージ
1. **0-format-LAT292data.r**  
	needs  
	devtools  
	tidyverse  
	lubridate  
	data.table  
	maps  
	mapproj  
	mapdata  
    pathological  
    zoo  

1. **1-install-needed-libraries.r**  
	needs  
	devtools    
	R.oo  
	maps  
	mapproj  
	mapdata  
	ukfsst  

1. **2-run-ukfsst-or-kftrack.r (2.5-run-ukfsst-or-kftrack-parallel.r)**  
	needs  
	ukfsst  
	devtools  
	maps  
	mapproj  
	mapdata  
	tidyverse  
	data.table  
	pathological  
	egg  
	gginnards  
	ggpmisc  

1. **3-listup-kalmanfilter-fitResults.r**  
	needs  
	devtools  
	data.table  
	tidyverse  
	pathological  
	writexl  
	zoo  
	tcltk  

1. **4-run-analyzepsat.R**  
	needs  
	analyzepsat  
	adehabitat  
	devtools  
	maps  
	mapproj  
	mapdata  
	tcltk  
	tidyverse  
	data.table  
	pathological  
	egg  
	gginnards  
	ggpmisc  
	ncdf4  

1. **func\_get\_oisstV2_highres.R**  
	tidyverse  
	ncdf4  
	date  
    lubridate  
	pathological  
    rvest  

## 使い方 Usage
各Rスクリプト (〇〇.R または 〇〇.r) を各自のパソコンにダウンロードしてください.  
(工事中)

[国際水産資源研究所のホームページ](http://fsf.fra.affrc.go.jp/Tag/Atag_proc.html)に公開している概要説明スライドのp.113-120も参照ください.

## インストール方法 Install
ここでは注意していただきたい環境構築の方法を説明します.  
(工事中)

## 質問, 提案など Contribution

## ライセンス Licence
- BSD (ukfsstパッケージ)  
- GPLv3 (analyzepsatパッケージ)  

## 作成者 Author
水産研究・教育機構 国際水産資源研究所 かつおグループ (NRIFSF-SKJG@ml.affrc.go.jp)  
Junji Kinoshita (kinoshitaj@affrc.go.jp)

## リンク集 Links
- [国際水産資源研究所 データベース等](http://fsf.fra.affrc.go.jp/Tag/Atag_proc.html)  
- [『水産技術』11巻2号に掲載の技術報告](https://www.fra.affrc.go.jp/bulletin/fish_tech/11-2/110203.pdf)






