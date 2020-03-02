#!/bin/bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#########################################################
#########################################################
#####
##### >> Deploy Kylin into a large cluster <<
##### >> For auto test purpose, execute it if you want to test something.
##### >> Execute "sh $this_script to see manual"
#####
#########################################################
#########################################################


##########################
##### >>> CONFIG <<< #####
##### Please modify these config entry

## The path which we choose to deploy you component (need created manually)
DEPLOY_PATH=/root/open-source/night-build/LacusSnippet/kylin_related/deploy

## THe path we choose to deploy kylin instances (need created manually).
KYLIN_PATH=$DEPLOY_PATH/kylin

THIS_FILE=$DEPLOY_PATH/deploy-kylin-cluster.sh

## THIS IS THE PACKAGE PROVIDED BY YOU.
## TODO: change to another way
ORIGINAL_PACKAGE=`ls $DEPLOY_PATH/*apache-kylin*.gz`

## hostname of all workers (Deploy streaming receiver)
## Make sure you can login all node via ssh without password
##
NODE_LIST=(
"cdh-master"
)

## On each worker, you can choose how many receiver you want to deploy,
## following is their deploy path
RECEIVER_LIST=(
"kylin-receiver-1"
"kylin-receiver-2"
)

## The config entry which append to kylin.properties
## Please choose you own metadata url, that will be beneficial to easy storage clean up and resource isolation.
MY_CONFIG=(
"kylin.metadata.url=master_metadata@jdbc,url=jdbc:mysql://cdh-master:3306/NightlyBuild,username=root,password=Kylin!2019,maxActive=10,maxIdle=10"
"kylin.source.hive.database-for-flat-table=NightlyBuild"
"kylin.env.zookeeper-base-path=/NightlyBuild"
"kylin.storage.hbase.table-name-prefix=nightly_"
"kylin.storage.hbase.namespace=nightly_build"
"kylin.env.hdfs-working-dir=/NightlyBuild"
"kylin.stream.event.timezone=GMT+8"
"kylin.web.timezone=GMT+8"
"kylin.stream.hive.database-for-lambda-cube=realtime_lambda_test"
"kylin.query.cache-enabled=false"
"kylin.metrics.monitor-enabled=false"
"kylin.metrics.reporter-job-enabled=true"
"kylin.metrics.reporter-query-enabled=true"
"kylin.web.dashboard-enabled=true"
"Kylin.env.zookeeper-connect-string=cdh-master:2181"
"kylin.web.dashboard-enabled=false"
"kylin.hive.union.style=UNION ALL"
"kylin.source.hive.databasedir=/user/hive/warehouse/lacus.db"
)

## Modify port for kylin instance
KYLIN_ROLE_ALL_PORT_OFFSET=935
## Modify port for kylin receiver
KYLIN_RECEIVER_PORT_OFFSET=936


##############################
##### >>> FUNCTIOPN <<< ######

ARGS_NUM=$#
echo """
Hello ${USER}!
Welcome to use kylin deployment tools.

       KK     KK   KK       KK   KK          KKKKKKKK   KK          KK
       KK    KK     KK     KK    KK             KK      KKKK        KK
       KK   KK       KK   KK     KK             KK      KK KK       KK
       KK  KK         KK KK      KK             KK      KK  KK      KK
       KKKK            KK        KK             KK      KK   KK     KK
       KK  KK          KK        KK             KK      KK    KK    KK
       KK   KK         KK        KK             KK      KK     KK   KK
       KK    KK        KK        KK             KK      KK       KK KK
       KK     KK       KK        KKKKKKKKKK     KK      KK        KKKK
       KK      KK      KK        KKKKKKKKKK  KKKKKKKKK  KK          KK
"""

function main() {
    check_args
    app_option="$1"

    #=========== Cluster Level Operation [via ssh] ===========#

    if [ $app_option == "distribute" ]
    then
        copy_binary

    elif [ $app_option == "deploy_kylin_instance" ]
    then
        ssh root@cdh-master "sh -x $THIS_FILE deploy_kylin "

    elif [ $app_option == "start_kylin_instance" ]
    then
        ssh root@cdh-master "sh -x $THIS_FILE start_kylin "

    elif [ $app_option == "stop_kylin" ]
    then
        stop_kylin

    elif [ $app_option == "deploy_all_receiver" ]
    then
        for node in "${NODE_LIST[@]}"
        do
            echo "Deploy receiver on "$node
            ssh root@$node "sh -x $THIS_FILE deploy_receiver"
        done

    elif [ $app_option == "start_all_receiver" ]
    then
        for node in "${NODE_LIST[@]}"
        do
            echo "Start receiver at "$node
            ssh root@$node "sh -x $THIS_FILE start_receiver"
        done

    elif [ $app_option == "stop_all_receiver" ]
    then
        for node in "${NODE_LIST[@]}"
        do
            echo "Stop receiver at  "$node
            ssh root@$node "sh -x $THIS_FILE stop_receiver"
        done

    elif [ $app_option == "destory_all_receiver" ]
    then
        for node in "${NODE_LIST[@]}"
        do
            echo "Destory receiver at  "$node
            ssh root@$node "sh -x $THIS_FILE destory_receiver"
        done

    #=========== Node Level Operation [Local] ===========#


    elif [ $app_option == "deploy_kylin" ]
    then
        start_kylin deploy

    elif [ $app_option == "start_kylin" ]
    then
        start_kylin start

    elif [ $app_option == "deploy_receiver" ]
    then
        start_all_receivers init

    elif [ $app_option == "deploy_receiver" ]
    then
        start_all_receivers init

    elif [ $app_option == "start_receiver" ]
    then
        start_all_receivers start

    elif [ $app_option == "stop_receiver" ]
    then
        stop_all_receivers stop

    elif [ $app_option == "destory_receiver" ]
    then
        stop_all_receivers destory

    else
        print_manual
    fi
}

# Upload deploy scripts to all worker nodes.
function upload_scripts() {
    for node in "${NODE_LIST[@]}"
    do
        echo "Distribute scripts to "$node
        scp $THIS_FILE root@$node:$DEPLOY_PATH
    done
}


# Distribute kylin binary to all worker nodes.
function copy_binary() {
    for node in "${NODE_LIST[@]}"
    do
        echo "Send binary to "$node
        scp $ORIGINAL_PACKAGE root@$node:$KYLIN_PATH/kylin.tar.gz
    done
}

# Start a new Kylin Server
# If a previous Kylin instance exists, force kill and destory it
function start_kylin() {
    export JAVA_HOME=/usr/java/jdk1.8.0_171 #NGTM
    export PATH=$JAVA_HOME/bin:$PATH
    rm -rf $KYLIN_PATH/*.gz
    cp $ORIGINAL_PACKAGE $KYLIN_PATH/kylin.tar.gz
    cd $KYLIN_PATH
    option=$1
    if [ $option == "deploy" ]
    then

        ## Stop and remove previous instance
        cd kylin-all
        sh bin/kylin.sh stop
        cd ..
        rm -rf apache-kylin*bin
        rm -rf kylin-all

        ## TODO(diag.sh)
        ## Upload diag

        ## Deploy new one
        cd $KYLIN_PATH
        binary=`ls $KYLIN_PATH/kylin.tar.gz`
        tar zxf $binary
        mv apache-kylin*bin kylin-all
        cd $KYLIN_PATH/kylin-all
        export KYLIN_HOME=`pwd`

        ## Reset port
        sh bin/kylin-port-replace-util.sh set $KYLIN_ROLE_ALL_PORT_OFFSET

        ## Update config
        update_config conf/kylin.properties
    fi

    cd $KYLIN_PATH/kylin-all
    export KYLIN_HOME=`pwd`


    # As far as I see, jenkins will kill child process which create by him after job finished.
    # I was trying to avoid such things happend, but it looks not works.
    # At the end, I start kylin via ssh (in remote execute). So jenkins can not kill remote processes.
    # LGTM.
    # export KYLIN_EXTRA_START_OPTS=" -Dhudson.util.ProcessTree.disable=true"
    # echo 'export KYLIN_EXTRA_START_OPTS=" -Dhudson.util.ProcessTree.disable=true $KYLIN_EXTRA_START_OPTS"' >> conf/setenv.sh

    sh bin/kylin.sh start
    sleep 30
    jps -mlv | grep $DEPLOY_PATH
    echo "Done start kylin server."
}

function stop_kylin() {
    option=$1
    path=`ls -d $KYLIN_PATH/kylin-all`

    cd $path
    sh bin/kylin.sh stop
    sleep 10
    jps -mlv | grep $DEPLOY_PATH
    kill_kylin_process
}

## Deploy and start all receiver in one node
function start_all_receivers() {
    option=$1
    cd $KYLIN_PATH
    export JAVA_HOME=/usr/java/jdk1.8.0_171 #NGTM
    export PATH=$JAVA_HOME/bin:$PATH
    kill_kylin_process
    if [ $option == "init" ]
    then
        binary=`ls $KYLIN_PATH/kylin.tar.gz`
        tar zxf $binary

        # 1. Stop and remove previous receiver instance
        for instance in `find -name "kylin-receiver*"`
            do
              echo "Remove previous $instance"
              cd $instance
              sh bin/kylin.sh streaming stop
              cd ..
              rm -rf $instance
        done

        # 2. Update new binary
        for instance in "${RECEIVER_LIST[@]}"
            do
              cp -r apache-kylin*bin $instance
        done

        rm -rf apache-kylin*bin
        # 3. Prepare
        declare -i port_offset=$KYLIN_RECEIVER_PORT_OFFSET
        for instance in "${RECEIVER_LIST[@]}"
            do
            echo "Try to deploy "$instance
            cd $instance
            export KYLIN_HOME=`pwd`

            ## update port config
            ## TODO God bless me, wish $port_offset is not occuiped
            sh bin/kylin-port-replace-util.sh set $port_offset

            ## update kylin related config, make sure all instance using the same config
            update_config conf/kylin.properties

            ## clean up
            cd ..
            port_offset=port_offset+1
            unset KYLIN_HOME
        done
        echo "Done distribution."
    fi

    # 4. Start instance
    for instance in "${RECEIVER_LIST[@]}"
    do
        echo "Go to "$instance
        cd $instance
        export PATH=/usr/java/jdk1.8.0_171/bin:$PATH
        # start streaming receiver
        sh bin/kylin.sh streaming start
        cd ..
    done
    sleep 10
    jps -mlv | grep $DEPLOY_PATH
    echo "Done start receivers."
}


function stop_all_receivers() {
    option=$1
    cd $KYLIN_PATH
    for node in "${RECEIVER_LIST[@]}"
    do
        echo "Go to "$node
        cd $node
        sh bin/kylin.sh streaming stop
        cd ..
        if [ $option == "destory" ]
        then
            rm -rf $node
        fi
    done
    kill_kylin_process
    sleep 10
    jps -mlv | grep $DEPLOY_PATH
    echo "Done stop receivers."
}

## Append config entry to kylin.properties
function update_config() {
    kylin_cfg=$1
    for cfg_entry in "${MY_CONFIG[@]}"
    do
        echo $cfg_entry >> $kylin_cfg
    done
}

## Find all kylin receivers process created by me in this node and send terminate signal to it
## "created by me" means it Working Dir contains KYLIN_PATH
function kill_kylin_process() {
    temp_file=.your_kylin_process
    jps -mlv | grep $DEPLOY_PATH | grep StreamingReceiver > ${temp_file}
    cat ${temp_file}
    awk  '{print$1;}' ${temp_file} | xargs -I {} kill {}
    rm -rf ${temp_file}
}

function check_args(){
    if [ $ARGS_NUM -ne 1 ]
    then
        print_manual
        exit -1
    fi
}

function print_manual() {
    echo """
    Usage:
1. distribute
    distribute the latest binary from local to all worker nodes
2. deploy_kylin_instance
    deploy and start kylin server at current node, if prevoius kylin instance still, kill and remove it
3. start_kylin_instance
    start kylin server at current node
4. stop_kylin
    stop kylin server at current node, but do not remove it
5. deploy_all_receiver
    remove and kill all existed receiver process, deploy and start new instance at all worker node
6. start_all_receiver
    start reciever at all worker node(make sure these receiver have already be deployed)
7. stop_all_receiver
    kill receiver at all worker node
8. destory_all_receiver
    kill and delete receiver at all worker node
"""
}

## Update latest scripts to all workers every time
upload_scripts

## Execute main logic
main $1


#########################################################
#########################################################
############  TODO LIST
#########################################################
#########################################################
##
## 1. How to find a port which is NOT occupied?
##  netstat -al | grep $port | wc -l
## 2. How to check if a kylin instance is work properly/health
## 3. How remove all related data in hdfs, hbase and zookeeper
## 4. Find all error log content in cluster