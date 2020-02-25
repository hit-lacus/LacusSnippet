# -*- coding: utf-8 -*-
# Python 2.7

import datetime
from datetime import timedelta
import random
import uuid
import argparse
import os
import shutil

HOUR_ROW_LIMIT = 10000
MAX_SMALL_INT = 999
MAX_BIG_INT = 9999999

random.seed(datetime.datetime.now().second)

hour_power = {
    0: 1.75,
    1: 1.25,
    2: 0.61,
    3: 0.24,
    4: 0.21,
    5: 0.52,
    6: 0.6,
    7: 0.92,
    8: 1.26,
    9: 1.01,
    10: 1.12,
    11: 1.11,
    12: 1.31,
    13: 1.21,
    14: 1.51,
    15: 1.23,
    16: 1.02,
    17: 1.31,
    18: 1.41,
    19: 1.22,
    20: 1.42,
    21: 1.55,
    22: 1.34,
    23: 1.67
}

add_partition_template = """
Use follow cmd to add partition.
------------------------------------------------

hive -e "USE lacus; ALTER TABLE UserActionLog ADD PARTITION(part_dt='%s') location '/Lacus/data/UserActionLog/part_dt=%s';"
"""

upload_data_template = """
Use follow cmd to upload files.
------------------------------------------------

hadoop fs -put -f %s /Lacus/data/UserActionLog
"""


def fake_timestamp(_dt):
    return _dt.strftime('%Y-%m-%d %H:%M:%S')


def fake_date(_dt):
    return _dt.strftime('%Y-%m-%d')


def fake_string_in_list(row_no, str_list, top_n=3):
    if row_no % 2 == 0:
        _id = row_no % top_n
    else:
        _id = row_no % len(str_list)
    return str_list[_id]


def fake_string_by_conat(str_list):
    return "-".join(str_list)


def fake_decimal(row_no, now_hour):
    if row_no % 2 == 0:
        ran_num = random.randint(0, 3) + random.randint(0, 999) / 100.0
    else:
        ran_num = random.randint(4, 50) + random.randint(0, 999) / 100.0
    return round(ran_num * hour_power[now_hour], 4)


def fake_integer(row_no, max1=MAX_SMALL_INT):
    if row_no % 3 == 0:
        return random.randint(1, 10)
    else:
        return random.randint(10, max1 + 10)


def fake_bigint(row_no):
    if row_no % 2 == 0:
        return random.randint(10000, MAX_BIG_INT + 10000)
    else:
        return random.randint(10, MAX_SMALL_INT + 10)


# for their detail meanings
def fake_event(row_no, ran_str_list, today, hour):
    row = list()

    # uid
    row.append(fake_bigint(row_no))

    # act_type
    row.append(
        fake_string_in_list(row_no, ["play", "start", "stop", "pause", "click", "exp", "like", "download", "dislike"]))

    # page_id
    row.append(fake_integer(row_no, max1=100))

    # device_id
    row.append(fake_string_by_conat([ran_str_list[0], ran_str_list[2]]))

    # device_brand
    row.append(fake_string_in_list(row_no, ["huawei", "iPhone", "xiaomi", "vivo", "360", "meizu"]))

    # item_id
    tmp_id = fake_bigint(row_no)
    row.append(tmp_id)

    # item_type_id
    row.append(fake_integer(row_no, max1=15))

    # register_date
    _id = fake_integer(row_no)
    row.append("2017-%s-%s" % (_id % 12 + 1, row_no % 28 + 1))

    # last_login_date
    _id = fake_integer(row_no)
    row.append("2019-%s-%s" % (row_no % 12 + 1, _id % 28 + 1))

    # log_time
    row.append(fake_timestamp(today + timedelta(hours=hour, minutes=_id % 59, seconds=row_no % 59)))

    # city
    row.append(fake_string_in_list(row_no,
                                   ["shanghai", "beijing", "hangzhou", "shenzhen", "taibei", "hongkong", "guangzhou",
                                    "nanjing", "chongqin", "berlin", "tokyo"]))

    # Active_Minutes
    row.append(fake_decimal(row_no, hour))

    # Play_Duration
    row.append(fake_decimal(row_no, hour))

    # Play_Times
    row.append(fake_decimal(row_no, hour))

    temp_str = str(row_no) + str(tmp_id)

    # Pv_Id
    row.append(fake_string_by_conat(["pv_id_", temp_str, ran_str_list[4], ran_str_list[1], ran_str_list[3]]))

    # Play_Id
    row.append(fake_string_by_conat(["play_id_", temp_str, ran_str_list[4], ran_str_list[2], ran_str_list[0]]))

    # Interest_Score
    row.append(fake_decimal(row_no, hour))

    line = '\t'.join(map(str, row))

    return line + '\n'


# write data_coll to file, one item for one line
def dumps_to_local(data_coll, file_name, check=False):
    print "Write to %s" % file_name
    if check and os.path.exists(parent_path):
        shutil.rmtree(parent_path)
        os.makedirs(parent_path)
    if not os.path.exists(parent_path):
        os.makedirs(parent_path)

    with open(file_name, 'w') as f:
        for row in data_coll:
            f.write(row)


def fake_one_day_data(today_dt):
    row_no = 0
    row_list_one_hour = list()
    hour = 0
    # One data file for one hour
    while hour <= 23:
        # used to produce some unique string
        # tm_yday is the day of year for today_dt
        unique_str_list = str(uuid.uuid3(uuid.NAMESPACE_URL, str(row_no) + str(today_dt.timetuple().tm_yday))
                              ).split('-')
        row_no += 1
        row = fake_event(row_no, unique_str_list, today_dt, hour)
        row_list_one_hour.append(row)

        # human activity change in different hour
        if row_no >= HOUR_ROW_LIMIT * hour_power[hour]:
            # dump to file
            dumps_to_local(row_list_one_hour, "%s/user_action_%02d.data" % (parent_path, hour), hour == 0)
            row_list_one_hour = list()
            row_no = 0
            hour += 1


def init_argument():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dt', required=True,
                        help="You have to specific which day of data you want to generate. Format like : 2020-01-01")
    parser.add_argument('--path', default="temp", help="You have to specific where to locate data file.")
    parser.add_argument('--count', default=10000, type=int,
                        help="You have to specific how many row for each hour. "
                             "Default count for user action for one hour is 10000.")
    args = parser.parse_args()
    return args


# This script is used to produce some mock data for one day
if __name__ == "__main__":
    ARG = init_argument()
    dt = ARG.dt
    HOUR_ROW_LIMIT = ARG.count
    parent_path = ARG.path + "/part_dt=" + dt
    today_date = datetime.datetime.strptime(dt, "%Y-%m-%d")
    fake_one_day_data(today_date)

    # Try to print command which used to upload data and add hive partition
    print upload_data_template % parent_path
    print add_partition_template % (dt, dt)
