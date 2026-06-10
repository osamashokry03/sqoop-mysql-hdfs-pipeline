# Cross-Platform Data Ingestion with Apache Sqoop & Hadoop

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-2.6.0-66CCFF?style=flat-square&logo=apache-hadoop&logoColor=white)
![Sqoop](https://img.shields.io/badge/Apache%20Sqoop-1.4.7-F4A020?style=flat-square&logo=apache&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-5.7%20%2F%208.0-4479A1?style=flat-square&logo=mysql&logoColor=white)
![CentOS](https://img.shields.io/badge/CentOS-9-262577?style=flat-square&logo=centos&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

A production-grade Big Data ingestion pipeline that transfers relational data from a **MySQL database on Windows** to a **Hadoop Distributed File System (HDFS) on CentOS 9** using Apache Sqoop. This repository serves as a complete, reproducible blueprint covering cross-network connectivity, single-node Hadoop cluster setup, dependency resolution, and YARN troubleshooting.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
  - [MySQL Configuration (Windows Host)](#1-mysql-configuration-windows-host)
  - [Hadoop Configuration (CentOS VM)](#2-hadoop-configuration-centos-vm)
  - [Sqoop & Dependency Setup](#3-sqoop--dependency-setup)
- [Execution](#execution)
  - [Test Database Connectivity](#step-1-test-database-connectivity)
  - [Run Data Import](#step-2-run-data-import)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Architecture Overview

```
┌─────────────────────────────────┐         ┌──────────────────────────────────────┐
│        Windows 11 Host          │         │          CentOS 9 Guest VM           │
│                                 │  JDBC   │                                      │
│  ┌───────────────────────────┐  │ ──────► │  ┌────────────┐   ┌──────────────┐  │
│  │  MySQL Server 5.7 / 8.0   │  │  3306   │  │   Sqoop    │──►│     HDFS     │  │
│  │  bind-address: 0.0.0.0    │  │         │  │   1.4.7    │   │  (Hadoop     │  │
│  └───────────────────────────┘  │         │  └─────┬──────┘   │   2.6.0)     │  │
│                                 │         │        │           └──────────────┘  │
│  Network: Port 3306 open        │         │        ▼                             │
│  Remote user privileges granted │         │  ┌────────────┐                      │
└─────────────────────────────────┘         │  │    YARN    │                      │
                                            │  │ MapReduce  │                      │
                                            │  └────────────┘                      │
                                            │  Network: Bridged / NAT              │
                                            └──────────────────────────────────────┘
```

| Component         | Technology                        |
|-------------------|-----------------------------------|
| **Data Source**   | MySQL 5.7 / 8.0 on Windows 11     |
| **Data Target**   | HDFS via Hadoop 2.6.0 on CentOS 9 |
| **Ingestion Tool**| Apache Sqoop 1.4.7                |
| **Execution Engine** | YARN MapReduce               |
| **Connectivity**  | JDBC over Bridged/NAT Network     |

---

## Prerequisites

Ensure the following are available before starting:

- **Windows Host**: MySQL Server installed and running
- **CentOS 9 VM**: Java 8 (JDK), Apache Hadoop 2.6.0, Apache Sqoop 1.4.7
- **Network**: VM configured in Bridged or NAT mode with access to the host IP
- **JAR Dependencies**:
  - [`commons-lang-2.6.jar`](https://mvnrepository.com/artifact/commons-lang/commons-lang/2.6)
  - [`mysql-connector-java-5.1.49.jar`](https://mvnrepository.com/artifact/mysql/mysql-connector-java/5.1.49)

---

## Environment Setup

### 1. MySQL Configuration (Windows Host)

**a. Allow remote connections — edit `my.ini`:**

```ini
[mysqld]
bind-address = 0.0.0.0
port         = 3306
```

Restart the MySQL service after saving.

**b. Grant remote access privileges:**

```sql
CREATE USER 'sqoop_user'@'%' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON your_database.* TO 'sqoop_user'@'%';
FLUSH PRIVILEGES;
```

> **Security Note:** Restrict the `'%'` wildcard to the VM's specific IP in production environments (e.g., `'sqoop_user'@'192.168.x.x'`).

**c. Open port 3306 in Windows Firewall:**

```
Windows Defender Firewall → Inbound Rules → New Rule → Port → TCP 3306
```

---

### 2. Hadoop Configuration (CentOS VM)

All configuration files are located in `$HADOOP_HOME/etc/hadoop/`.

**`core-site.xml`**
```xml
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
```

**`hdfs-site.xml`**
```xml
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///home/hadoop/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///home/hadoop/hdfs/datanode</value>
  </property>
</configuration>
```

**`yarn-site.xml`**
```xml
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
```

**`mapred-site.xml`**
```xml
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <!-- Required to resolve MRAppMaster ClassNotFoundException -->
  <property>
    <name>yarn.app.mapreduce.am.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>
  <property>
    <name>mapreduce.map.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>
  <property>
    <name>mapreduce.reduce.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>
</configuration>
```

**Start the Hadoop cluster:**

```bash
# Format the NameNode (first time only)
hdfs namenode -format

# Start HDFS and YARN daemons
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Verify all services are running
jps
# Expected: NameNode, DataNode, ResourceManager, NodeManager, SecondaryNameNode
```

---

### 3. Sqoop & Dependency Setup

**a. Place required JARs in Sqoop's lib directory:**

```bash
cp commons-lang-2.6.jar       $SQOOP_HOME/lib/
cp mysql-connector-java-5.1.49.jar  $SQOOP_HOME/lib/
```

**b. Verify your `SQOOP_HOME` environment variable:**

```bash
echo $SQOOP_HOME
# Example output: /opt/sqoop-1.4.7
```

---

## Execution

### Step 1: Test Database Connectivity

List all available databases on the remote MySQL server to verify JDBC connectivity:

```bash
$SQOOP_HOME/bin/sqoop list-databases \
  --connect 'jdbc:mysql://192.168.116.1:3306/' \
  --username 'sqoop_user' \
  --password '********'
```

**Expected Output:**

```
information_schema
mysql
your_database
```

---

### Step 2: Run Data Import

Transfer a target table from MySQL to HDFS via a YARN MapReduce job:

```bash
$SQOOP_HOME/bin/sqoop import \
  --connect 'jdbc:mysql://192.168.116.1:3306/your_database' \
  --username 'sqoop_user' \
  --password '********' \
  --table comp \
  --target-dir /user/hdfs/comp_import \
  --num-mappers 1
```

**Key Flags:**

| Flag            | Description                                        |
|-----------------|----------------------------------------------------|
| `--connect`     | JDBC connection string to the source database      |
| `--table`       | Source table to import                             |
| `--target-dir`  | Destination path on HDFS                          |
| `--num-mappers` | Number of parallel map tasks (1 = single-threaded) |

**Verify the import on HDFS:**

```bash
hdfs dfs -ls /user/hdfs/comp_import
hdfs dfs -cat /user/hdfs/comp_import/part-m-00000
```

---

## Troubleshooting

| Symptom | Root Cause | Resolution |
|---------|-----------|------------|
| `ClassNotFoundException: org.apache.commons.lang.StringUtils` | Missing `commons-lang` JAR | Copy `commons-lang-2.6.jar` to `$SQOOP_HOME/lib/` |
| `ClassNotFoundException: com.mysql.jdbc.Driver` | Missing MySQL connector | Copy `mysql-connector-java-5.1.49.jar` to `$SQOOP_HOME/lib/` |
| `MRAppMaster` application failure / container launch error | `HADOOP_MAPRED_HOME` not set in YARN environment | Add `yarn.app.mapreduce.am.env` property to `mapred-site.xml` (see [config above](#mapred-sitexml)) |
| `Connection refused` on port 3306 | MySQL not accepting remote connections | Set `bind-address = 0.0.0.0` in `my.ini` and open port 3306 in Windows Firewall |
| `Access denied for user` | Insufficient MySQL privileges | Grant remote privileges with `GRANT ALL PRIVILEGES ON db.* TO 'user'@'%'` |

---

## Project Structure

```
.
├── config/
│   ├── core-site.xml           # HDFS default filesystem configuration
│   ├── hdfs-site.xml           # HDFS replication and storage paths
│   ├── yarn-site.xml           # YARN resource manager configuration
│   └── mapred-site.xml         # MapReduce + YARN env variables
├── scripts/
│   ├── list_databases.sh       # Sqoop connectivity test script
│   └── import_table.sh         # Sqoop import execution script
├── docs/
│   └── setup-guide.md          # Step-by-step environment setup guide
└── README.md
```

---

## Contributing

Contributions, issues, and feature requests are welcome. Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the [MIT License](LICENSE).

---

> **Note:** Apache Sqoop reached End-of-Life in 2021. For new projects, consider modern alternatives such as [Apache Spark](https://spark.apache.org/) with JDBC, [Apache NiFi](https://nifi.apache.org/), or [Apache Kafka Connect](https://kafka.apache.org/documentation/#connect) for production-grade data ingestion pipelines.
