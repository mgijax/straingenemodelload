#!/bin/sh
#
#  straingenemodelload.sh
###########################################################################
#
#  Purpose:
#
#      This script is a wrapper around the process that loads the strain genes,
#      strain gene models, SEQ_GeneModel, updates molecular source and creates MCV
#	annotations 
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
#      - straingenemodelload Log file (${LOG_FILE})
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
#      1) Check  the lastrun file agains the MGI.gff3 file
#      2) Run the strainmarkerload to create strain genes for MGP and/or B6
#      3) Run assemblyseqload to create strain gene models for MGP and/or B6
#      4) Run seqgenemodelload script to create SEQ_GeneModel records for MGP and/or B6
#      5) Run updateSource script to delete/reload molecular source for MGP and/or B6
#      6) Run createMCVAnnots script to create MCV annotations for MGP and/or B6
#      7) Update the last run file
#      8) Email the log

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
LASTRUN_FILE=${SGM_INPUTDIR}/lastrun
if [ -f ${LASTRUN_FILE} ]
then
    if test ${LASTRUN_FILE} -nt ${INPUT_MGI_GFF}
    then
        echo "Input files have not been updated - skipping load" | tee -a ${LOG}
        exit 0
    fi
fi

date >> ${LOG}
message=''

echo "Load strain genes" | tee -a ${LOG}
${STRAINMARKERLOAD}/bin/strainmarkerload.sh  >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} strainmarkerload.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} strainmarkerload.sh successful"
fi

if [ "${B6_ONLY}" = "false" ]
then
    date >> ${LOG}
    echo "Load gene models for MGP" | tee -a ${LOG}
    ${ASSEMBLY_WRAPPER} ${MGP_ASSEMBLY_CONFIG} >> ${LOG} 2>&1
    STAT=$?
    if [ ${STAT} -ne 0 ]
    then
	message="${message} assemblyseqload.sh failed"
	echo ${message} | tee -a ${LOG}
	exit 1
    else
	message="${message} assemblyseqload.sh successful"
    fi
fi

date >> ${LOG}
echo "Load gene models for B6" | tee -a ${LOG}
${ASSEMBLY_WRAPPER} ${B6_ASSEMBLY_CONFIG} >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} assemblyseqload.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} assemblyseqload.sh successful"
fi

if [ "${B6_ONLY}" = "false" ]
then
    date >> ${LOG}
    echo "Load SEQ_GeneModel for MGP" | tee -a ${LOG}
    echo "${STRAINGENEMODELLOAD}/bin/seqgenemodelload.sh MGP >> ${LOG} 2>&1"
    ${STRAINGENEMODELLOAD}/bin/seqgenemodelload.sh ${STRAINGENEMODELLOAD}/mgp_seqgenemodel.config >> ${LOG} 2>&1
    STAT=$?
    if [ ${STAT} -ne 0 ]
    then
	message="${message} seqgenemodelload.sh MGP failed"
	echo ${message} | tee -a ${LOG}
	exit 1
    else
	message="${message} seqgenemodelload.sh MGP successful" 
    fi
fi

date >> ${LOG}
echo "Load SEQ_GeneModel for B6" | tee -a ${LOG}
echo "${STRAINGENEMODELLOAD}/bin/seqgenemodelload.sh B6 >> ${LOG} 2>&1"
${STRAINGENEMODELLOAD}/bin/seqgenemodelload.sh ${STRAINGENEMODELLOAD}/b6_seqgenemodel.config >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} seqgenemodelload.sh B6 failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} seqgenemodelload.sh B6 successful"
fi

date >> ${LOG}
echo "Update Molecular Source" | tee -a ${LOG}
echo "${STRAINGENEMODELLOAD}/bin/updateSource.sh >> ${LOG} 2>&1"
${STRAINGENEMODELLOAD}/bin/updateSource.sh >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} updateSource.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} updateSource.sh successful"
fi

date >> ${LOG}
echo "Load MCV Annotations" | tee -a ${LOG}
echo "${STRAINGENEMODELLOAD}/bin/createMCVAnnots.sh >> ${LOG} 2>&1"
${STRAINGENEMODELLOAD}/bin/createMCVAnnots.sh >> ${LOG} 2>&1
STAT=$?
if [ ${STAT} -ne 0 ]
then
    message="${message} createMCVAnnots.sh failed"
    echo ${message} | tee -a ${LOG}
    exit 1
else
    message="${message} createMCVAnnots.sh successful"
fi

touch ${LASTRUN_FILE}

#
# mail the log
#
cat ${LOG} | mailx -s "Strain Gene Model Load Completed: ${message}" ${MAIL_LOG_PROC}
date >> ${LOG}
exit 0
