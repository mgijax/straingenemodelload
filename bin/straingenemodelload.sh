#!/bin/sh
#
#  straingenemodelload.sh
###########################################################################
#
#  Purpose:
#
#      This script is a wrapper around the process that loads the strain gene
#      models, SEQ_GeneModel and marker associations 
#
#  Usage:
#
#      straingenemodelload.sh 
#
#  Env Vars:
#
#      See the configuration file: straingenemodelload.config
#
#  Outputs:
#
#      - Log file (${LOG_FILE})
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  Fatal error occurred
#
#  Assumes:  Nothing
#
#  Implementation:
#
#      This script will perform following steps:
#
#      1) 
#      2)
#
#  Notes:  None
#
###########################################################################
#
#  Modification History:
#
#  Date        SE   Change Description
#  ----------  ---  -------------------------------------------------------
#
#  04/25/2018  sc  Initial development
#
###########################################################################

cd `dirname $0`

COMMON_CONFIG=straingenemodelload.config

USAGE="Usage: straingenemodelload.sh"

RUNTYPE=live

#
# Make sure the common configuration file exists and source it.
#
if [ -f ../${COMMON_CONFIG} ]
then
    . ../${COMMON_CONFIG}
else
    echo "Missing configuration file: ${COMMON_CONFIG}"
    exit 1
fi

#
# Initialize the log file.
#
LOG=${LOG_FILE}
rm -rf ${LOG}
touch ${LOG}

#
# There should be a "lastrun" file in the input directory that was created
# the last time the gene model load was run. If this file exists and is more 
# recent than the gene model file, the load does not need to be run. 
#
#LASTRUN_FILE=${GM_INPUTDIR}/lastrun
#if [ -f ${LASTRUN_FILE} ]
#then
#    if test ${LASTRUN_FILE} -nt ${GM_INPUTFILE}
#    then
#        echo "Input files have not been updated - skipping load" | tee -a ${LOG}
#        exit 0
#    fi
#fi

message=''
#
# If the MGP gene models are to be reloaded, the following is done
# 1) call the assemblyseqload to reload genemodels and coordinates 
# 2) call the seqgenemodelload to reload SEQ_GeneModel
#

echo "Load Strain Marker objects for MGP and B6" | tee -a ${LOG}
${STRAINMARKERLOAD}/bin/strainmarkerload.sh  >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} strainmarkerload.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} strainmarkerload.sh successful"
    echo ${message} | tee -a ${LOG}
fi

echo "Load gene models for MGP" | tee -a ${LOG}
${ASSEMBLY_WRAPPER} ${ASSEMBLY_CONFIG} >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} assemblyseqload.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} assemblyseqload.sh successful"
    echo ${message} | tee -a ${LOG}
fi


echo "Load SEQ_GeneModel for MGP" | tee -a ${LOG}
echo "${STRAINGENEMODELLOAD}/bin/seqgenemodelload.sh >> ${LOG} 2>&1"
${STRAINGENEMODELLOAD}/bin/seqgenemodelload.sh >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} seqgenemodelload.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} seqgenemodelload.sh successful" 
    echo ${message} | tee -a ${LOG}
fi

#
#touch ${LASTRUN_FILE}

#
# mail the log
#
cat ${LOG} | mailx -s "Strain Gene Model Load Completed: ${message}" ${MAIL_LOG_PROC}

exit 0
