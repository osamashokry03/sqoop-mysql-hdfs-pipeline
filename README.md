Cross-Platform Data Ingestion with Apache Sqoop & Hadoop
📌 Project Overview
This project demonstrates a robust Big Data ingestion pipeline using Apache Sqoop to transfer relational data from a MySQL database hosted on a Windows machine to a Hadoop Distributed File System (HDFS) running on a CentOS 9 Virtual Machine.

The repository serves as a blueprint for configuring cross-network database connectivity, setting up a single-node Hadoop cluster, and resolving common YARN and Java dependency issues in a distributed computing environment.

🏗️ Architecture & Environment
Data Source (Host)
OS: Windows 11

Database: MySQL Server (5.7 / 8.0)

Network: Configured for remote access (bind-address = 0.0.0.0, Port 3306)

Data Target (Guest VM)
OS: CentOS 9

Framework: Apache Hadoop 2.6.0 (Single-Node Cluster)

Ingestion Tool: Apache Sqoop 1.4.7

Network: Bridged/NAT networking allowing access to host IP.

⚙️ Key Configurations & Achievements
Cross-Platform Connectivity: Successfully configured MySQL my.ini and user privileges to allow secure, remote JDBC connections from a Linux VM to a Windows host.

Hadoop & YARN Setup: Configured core Hadoop XML files (core-site.xml, hdfs-site.xml, yarn-site.xml, mapred-site.xml) to establish a fully functional HDFS and YARN MapReduce execution environment.

Dependency Management: Diagnosed and resolved critical missing Java libraries required for Sqoop execution:

Injected commons-lang-2.6.jar to resolve StringUtils ClassDefFound errors.

Injected mysql-connector-java-5.1.49.jar to enable MySQL JDBC driver loading.

YARN AppMaster Troubleshooting: Resolved MapReduce application failures by explicitly defining HADOOP_MAPRED_HOME environment variables within mapred-site.xml, ensuring the MRAppMaster class loaded correctly.

🚀 Execution Commands
1. Test Database Connectivity
Lists available databases on the remote Windows MySQL server.

Bash
./sqoop list-databases \
  --connect 'jdbc:mysql://192.168.116.1:3306/' \
  --username 'root' \
  --password '********'
2. Execute Data Import
Transfers the target table to HDFS via a YARN MapReduce job using a streaming resultset.

Bash
./sqoop import \
  --connect 'jdbc:mysql://192.168.116.1:3306/database_name' \
  --username 'root' \
  --password '********' \
  --table comp \
  --target-dir /user/asf/comp_import \
  --num-mappers 1
