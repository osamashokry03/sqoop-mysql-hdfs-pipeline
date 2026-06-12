#!/bin/bash
/home/asf/bigdata/sqoop-1.4.7.bin__hadoop-2.6.0/bin/sqoop list-databases \
  --connect 'jdbc:mysql://192.168.116.1:3306/' \
  --username '******' \
  --password '*******'
