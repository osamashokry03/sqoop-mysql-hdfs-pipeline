#!/bin/bash
./sqoop export \
  --connect 'jdbc:mysql://192.168.116.1:3306/your_database_name?useSSL=false' \
  --username '******' \
  --password '******' \
  --table comp_export \
  --export-dir '/user/asf/comp_import' \
  --input-fields-terminated-by ',' \
  --input-lines-terminated-by '\n' \
  --num-mappers 1
