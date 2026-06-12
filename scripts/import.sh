#!/bin/bash
./sqoop import \
  --connect 'jdbc:mysql://192.168.116.1:3306/your_database_name' \
  --username '******' \
  --password '******' \
  --table comp \
  --target-dir '/user/asf/comp_import' \
  --num-mappers 1
