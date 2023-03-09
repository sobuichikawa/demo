#!/bin/bash

# AWS�ɕۑ�����Ă��銈���ʌv�̑���f�[�^�������_�E�����[�h����X�N���v�g�B
# �f�[�^�͊e���[�U�[�P������CSV�t�@�C���Ƃ��ĕۑ�����Ă���B
# �i�� df_0454-2022-05-01.csv �� ���[�U�[454��2022/5/1�̃f�[�^�j
# ����ID�ɂ��āA������Ԃ̃f�[�^��S��DL�������B

# �f�[�^DL���郆�[�UID��z��Ŏw��B
ID_LIST=(0001 0004 0005 0127 0454 0670 0755 0946 1199 1312 \ 
         1568 1699 1722 1863 1981 2237 2304 2522 2831 3010)

# �f�[�^�擾���ԁi�J�n/�I���j���w��B 
FROM_DATE="20220420"  # "yyyymmdd"
TO_DATE="20221124"    # "yyyymmdd"

# AWS S3��URL�ƃ��[�J����DL��f�B���N�g��
S3_PATH="s3://test_project/test-test/analysis_data"
DATA_DIR="ana_20221124"

# ���݂��Ȃ��f�[�^��DL���悤�Ƃ���Ǝ��Ԃ����X���邩��A
# �\�߃T�[�o�[����f�[�^�ꗗ���擾���A���݂���f�[�^�̂�DL����悤�H�v�B

# �T�[�o�[����f�[�^�ꗗ���擾
DATA_LIST=$(aws s3 ls ${S3_PATH}/)

# �z����̃��[�U�[ID�ɂ��āA�����L�f�[�^�ꗗ�Ɋ܂܂�邩�����B
for ID in ${ID_LIST[@]}
do
�@�@# �f�[�^�ꗗ����q�b�g�����t�@�C���������o���B
    # grep�� -o �I�v�V�����ɂ��A�s�P�ʂłȂ�������P�ʂň�v���������o�����Ƃ��\�B
    # grep�����f�[�^�t�@�C�����̓X�y�[�X��؂�̔z��Ƃ��Ċi�[����Ă���B 
    CSV_LIST=$(echo ${DATA_LIST} | grep -o 'df.'${ID}'.*.csv')                     # grep file name of 'df*ID*.csv' from ls result

    # �f�[�^�t�@�C����1���_�E�����[�h����B
    # �t�@�C�����ɓ��t���܂܂�邱�Ƃ𗘗p���A�C�ӂ̊��Ԃ̃f�[�^�̂ݎ擾����悤�ɂȂ��Ă���B
    for ITEM in ${CSV_LIST}
    do
        # �t�@�C����������t�𒊏o�B
        DATE=`echo ${ITEM} | cut -d "-" -f 2-4 | sed -e "s/-//g" -e "s/.csv//g"`   # 'df_873-2019-03-01.csv' -> '20190301'

        # ���t������̋�Ԃ̏ꍇ�̂݃_�E�����[�h����B
        if [ ${DATE} -ge ${FROM_DATE} ] && [ ${DATE} -le ${TO_DATE} ]; then
            aws s3 cp ${S3_PATH}/${ITEM} ./${DATA_DIR}/${ITEM}                     # copy csv file
        fi
    done
done
