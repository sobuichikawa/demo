#!/bin/bash

# AWSに保存されている活動量計の測定データを自動ダウンロードするスクリプト。
# データは各ユーザー１日毎にJSON形式でGZIP圧縮されて保存されている。
# （例 df_0454-2022-05-01.json.gz ⇒ ユーザー454の2022/5/1のデータ）
# 複数IDについて、ある期間のデータを全てDLし、CSV変換して保存したい。

# aws_s3_download.sh の状況と異なり、データの存在するディレクトリが日付毎に分かれている。
# 例) s3://test_project/test-test/analysis_data/2023/04/20/data_20230420_0001699.json.gz

# データDLするユーザIDを配列で指定
ID_LIST=(0001 0004 0005 0127 0454 0670 0755 0946 1199 1312 \ 
         1568 1699 1722 1863 1981 2237 2304 2522 2831 3010)

# データ取得期間（開始/終了）を指定 
FROM_DATE="20220420"  # "yyyymmdd"
TO_DATE="20221124"    # "yyyymmdd"

# AWS S3のURLとローカルのDL用ディレクトリ
BASE_URL="s3://test_project/test-test/analysis_data"
LOCAL_DIR="ana_20221124"

# jqコマンドでJSONデータを分析するためのキーを設定。
# "timestamp" : 測定日時
# "step"      : 歩数
# "temp"      : 体温
# "hr"        : 心拍数
CSV_ITEM="[                    \
           .timestamp,         \
           .step,              \
           .temp,              \
           .hr,                \
          ]"

# 上記文字列からCSVデータ 1行目に使う項目名を作成。
CSV_TITLE=`echo ${CSV_ITEM} | \
           sed -e "s/\[//g" -e "s/\]//g" -e "s/\ //g" -e "s/\.//g"`

# データ取得する日付の初期値。
TMP_DATE=${FROM_DATE}

# データ取得期間の最終日に至るまで日付を1日ずつ検査。
while [[ ${TMP_DATE} -le ${TO_DATE} ]]
do
    # 年月日から年、月、日を抽出。
    TMP_Y=${TMP_DATE:0:4}    # 2022 : Year
    TMP_M=${TMP_DATE:4:2}    # 04   : Month
    TMP_D=${TMP_DATE:6:2}    # 20   : Date
    
    # AWS S3のURL。データの取得日毎に格納先ディレクトリが異なる。
    S3_DIR=${BASE_URL}/${TMP_Y}/${TMP_M}/${TMP_D}

    # 存在しないデータをDLしようとすると時間をロスするから、
    # 予めサーバーからデータ一覧を取得し、存在するデータのみDLするよう工夫。
    # このリストは検査対象日のデータ一覧である。
    S3_LIST=`aws s3 ls ${S3_DIR}/`
    
    # 配列内のユーザーIDについて、一つずつ上記データ一覧に含まれるか検査。 
    for ID in ${ID_LIST[@]}
    do
        # ゼロパディングした7桁のユーザーIDと日付を合わせてファイル名を作成。
        IDZ=`printf "%07d" ${ID}`
        FILE_NAME=${TMP_DATE}_${IDZ}
        FN_GZP=data_${FILE_NAME}.json.gz
        FN_JSN=data_${FILE_NAME}.json
        FN_CSV=data_${FILE_NAME}.csv    
        
　　    # 検査対象日のデータ一覧に検査対象IDのデータが存在するかチェック。     
        echo "checking ${S3_DIR}/${FN_GZP} exists..."
        IS_FILE=`echo ${S3_LIST} | grep -o "${FN_GZP}"`
        
        # データが存在する場合、ダウンロードしGZIP解凍、CSV変換する。
        if [[ -n ${IS_FILE} ]]; then
            aws s3 cp ${S3_DIR}/${FN_GZP} ./${LOCAL_DIR}/${FN_GZP}  # copy csv file
            gunzip ./${LOCAL_DIR}/${FN_GZP}
            
            # JSONからCSV変換。
            jq -r ".[].fields | ${CSV_ITEM} | @csv" \
            ./${LOCAL_DIR}/${FN_JSN} >./${LOCAL_DIR}/${FN_CSV}
            
            # CSVファイルの1行目に項目名のラベルを挿入する。
            sed -i -e "1i${CSV_TITLE}" ./${LOCAL_DIR}/${FN_CSV}
            
            # 不要になったJSONを削除。
            rm -f ./${LOCAL_DIR}/${FN_JSN}
        fi
    done
    
    # 検査する日付を1日進める。
    TMP_DATE=`date --date "${TMP_DATE} next day" +%Y%m%d`
    
done

