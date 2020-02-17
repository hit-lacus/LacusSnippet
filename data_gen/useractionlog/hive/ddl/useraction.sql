DROP TABLE IF EXISTS UserActionLog;
CREATE TABLE IF NOT EXISTS UserActionLog (
  uid BIGINT COMMENT 'user identity',
  act_type CHAR(10) COMMENT 'user action type, such as start app, watch a video, click a button',
  page_id INT COMMENT 'which page did user click or watch',
  device_id STRING COMMENT 'device identity',
  device_brand STRING COMMENT 'device brand',
  item_id BIGINT COMMENT 'which thing does user interact with, may be a video/user comment/advertisement',
  item_type_id TINYINT COMMENT 'which type of item_id it is',
  register_date DATE COMMENT 'when user register our app',
  last_login_date DATE COMMENT 'the latest time user login our app',
  log_time TIMESTAMP COMMENT 'when does this user act happen',
  city VARCHAR(30) COMMENT 'which city did user located',

  Active_Minutes DECIMAL(11,5)  COMMENT 'how many minutes does user stay in our app this time',
  Play_Duration DECIMAL(11,5)  COMMENT 'how many minutes does user stay in our app this time',
  Play_Times BIGINT  COMMENT 'how many videos does user watch this time',
  Pv_Id STRING  COMMENT 'MD5 of PageView',
  Play_Id STRING  COMMENT 'MD5 of Play Action',
  Interest_Score DOUBLE  COMMENT 'For machine learning'
)
COMMENT 'Fact table. Store raw user action log.'
PARTITIONED BY (part_dt string COMMENT 'date partition column')
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;