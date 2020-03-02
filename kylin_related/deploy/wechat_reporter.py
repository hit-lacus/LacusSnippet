# -*- coding:utf-8 -*-
import requests
import sys

# How to use
# python THIS.py ${KYLIN_URL} ${BUILD_URL} ${PERSON_TO_NOTIFY} ${PHONE_TO_NOTIFY}


# Test Group 's BOT
TEST_WEBHOOK_URL = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111"

# OpenSource Team 's BOT
WEBHOOK_URL = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=222"

JOB_NOTIFY_TEMPLATE = """Dear %s:
  Kylin instance is deployed.
  Kylin URL : %s.
  Build URL : %s.
  Log   URL : http://cdh-master:5601/app/infra#/logs
"""


def send_job_notify(input_params):
    notify = dict()
    notify["msgtype"] = "text"
    notify["text"] = dict()
    notify["text"]["content"] = JOB_NOTIFY_TEMPLATE % (
        input_params["PERSON_TO_NOTIFY"],
        input_params["KYLIN_URL"],
        input_params["BUILD_URL"]
    )
    notify["text"]["mentioned_mobile_list"] = [input_params["PHONE_TO_NOTIFY"]]
    requests.post(TEST_WEBHOOK_URL, json=notify)


def notify(input_params):
    print input_params
    send_job_notify(input_params)


def main():
    input_arg = sys.argv
    print "I get these input : %s " % input_arg

    if len(input_arg) < 5:
        print "What is the fuck?"
    else:
        input_info = dict()
        input_info["KYLIN_URL"] = str(input_arg[1])
        input_info["BUILD_URL"] = str(input_arg[2])
        input_info["PERSON_TO_NOTIFY"] = str(input_arg[3])
        input_info["PHONE_TO_NOTIFY"] = str(input_arg[4])
        notify(input_info)


if __name__ == "__main__":
    main()
