#!/bin/bash

# AWSに保存されている活動量計の測定データを自動ダウンロードするスクリプト。
# データは各ユーザー１日毎にCSVファイルとして保存されている。
# （例 df_0454-2022-05-01.csv ⇒ ユーザー454の2022/5/1のデータ）
# 複数IDについて、ある期間のデータを全てDLしたい。

# データDLするユーザIDを配列で指定。
ID_LIST=(0001 0004 0005 0127 0454 0670 0755 0946 1199 1312 \ 
         1568 1699 1722 1863 1981 2237 2304 2522 2831 3010)

# データ取得期間（開始/終了）を指定。 
FROM_DATE="20220420"  # "yyyymmdd"
TO_DATE="20221124"    # "yyyymmdd"

# AWS S3のURLとローカルのDL先ディレクトリ
S3_PATH="s3://test_project/test-test/analysis_data"
DATA_DIR="ana_20221124"

# 存在しないデータをDLしようとすると時間をロスするから、
# 予めサーバーからデータ一覧を取得し、存在するデータのみDLするよう工夫。

# サーバーからデータ一覧を取得
DATA_LIST=$(aws s3 ls ${S3_PATH}/)

# 配列内のユーザーIDについて、一つずつ上記データ一覧に含まれるか検査。
for ID in ${ID_LIST[@]}
do
　　# データ一覧からヒットしたファイル名を取り出す。
    # grepの -o オプションにより、行単位でなく文字列単位で一致部分を取り出すことが可能。
    # grepしたデータファイル名はスペース区切りの配列として格納されている。 
    CSV_LIST=$(echo ${DATA_LIST} | grep -o 'df.'${ID}'.*.csv')                     # grep file name of 'df*ID*.csv' from ls result

    # データファイルを1個ずつダウンロードする。
    # ファイル名に日付が含まれることを利用し、任意の期間のデータのみ取得するようになっている。
    for ITEM in ${CSV_LIST}
    do
        # ファイル名から日付を抽出。
        DATE=`echo ${ITEM} | cut -d "-" -f 2-4 | sed -e "s/-//g" -e "s/.csv//g"`   # 'df_873-2019-03-01.csv' -> '20190301'

        # 日付が所定の区間の場合のみダウンロードする。
        if [ ${DATE} -ge ${FROM_DATE} ] && [ ${DATE} -le ${TO_DATE} ]; then
            aws s3 cp ${S3_PATH}/${ITEM} ./${DATA_DIR}/${ITEM}                     # copy csv file
        fi
    done
done
