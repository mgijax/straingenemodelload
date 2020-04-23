#!/bin/sh
#
#  updateSource.sh
###########################################################################
#
#  Purpose:
#
#      deletes then reloads molecular source for strain gene model 
#	sequences. The gene model loader only allows one source per
#	load, we need 18 sources for MGP and 1 source for B6
#
#  Usage:
#
#      updateSource.sh
#
#
#  Env Vars:
#
#
#  Inputs: the database and configuration
#
#  Outputs:
#       - SEQ_Source_Assoc bcp file
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
#      1) Call the python script (updateSource.py) which calculates proper
#	  molecular source, creates bcp file, deletes source, reloads source
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
#  06/14/2018  sc   TR12734 genfevah project
#
###########################################################################

cd `dirname $0`

CONFIG=straingenemodelload.config
#
# Make sure the common configuration file exists and source it.
#
if [ -f ../${CONFIG} ]
then
    . ../${CONFIG}
else
    echo "Missing configuration file: ${CONFIG}"
    exit 1
fi

#
# Initialize the log file.
#
LOG=${SEQSOURCE_LOGFILE}

if [ -f ${LOG} ]
then
    rm ${LOG}
fi

date >> ${LOG}

echo "Updating SEQ_Source_Assoc" | tee -a  ${LOG}
${PYTHON} ./updateSource.py >> ${LOG} 2>&1
STAT=$?
if [ $STAT -ne 0 ]
then
   echo "updateSource.py failed" | tee -a ${LOG}
   exit 1
fi

#
# Load SEQ_Source_Assoc
#
echo "" >> ${LOG}
date >> ${LOG}

if [ "${B6_ONLY}" = "false" ]
then
    echo "Adding MGP SEQ_Source_Assoc records" | tee -a ${LOG}
    ${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} SEQ_Source_Assoc "" ${MGP_SEQSOURCE_BCP} "\t" "\n" mgd >> ${LOG}
fi

echo "Adding B6 SEQ_Source_Assoc records" | tee -a ${LOG}
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} SEQ_Source_Assoc "" ${B6_SEQSOURCE_BCP} "\t" "\n" mgd >> ${LOG}

date >> ${LOG}

exit 0
