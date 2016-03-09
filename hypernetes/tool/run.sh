#/bin/bash

if [ $# -ne 3 ];then
  echo "./run.sh <script_dir> <script_name> <script_param>"
  exit 1
fi

WORK_DIR=$1
SCRIPT_NAME=$2
PARAM=$3

logfile=/root/${SCRIPT_NAME}.log
okfile=/root/${SCRIPT_NAME}.ok
fifofile=/root/fifo

ls $fifofile  && echo $fifofile existed || mkfifo $fifofile

[ -f $logfile ] && rm -rf $logfile

cat $fifofile | tee $logfile &
exec 2>&1>$fifofile

#run the script
echo ${WORK_DIR}/${SCRIPT_NAME}.sh \"${PARAM}\"
${WORK_DIR}/${SCRIPT_NAME}.sh "${PARAM}" && touch $okfile

rm -rf $fifofile
