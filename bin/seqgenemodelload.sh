#!/bin/sh 
#
#  seqgenemodelload.sh
###########################################################################
#
#  Purpose:
#
#      This script serves as a wrapper for seqgenemodelload.py
#
#  Usage:
#
#      seqgenemodelload.sh 
#
#
#  Env Vars:
#
#      	SGM_BIOTYPEFILE
#	SGM_LOGFILE
#	SGM_BCPFILE
#	SGM_LOGICALDB
#	MGD_DBPASSWORDFILE
#	MGD_DBNAME
#	MGD_DBSERVER
#	MGD_DBUSER
#
#  Inputs: ${SGM_BIOTYPEFILE}
#
#  Outputs:
#       - SEQ_GeneModel bcp file
#       - Log file (${SGM_LOGFILE})
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
#      1) Call the python script (seqgenemodelload.py) to create a bcp file
#	  for SEQ_GeneModel
#      2) Delete SEQ_GeneModel data for provider
#      3) Load the bcp file into the SEQ_GeneModel  table
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
#  05/30/2018  sc   TR12734 genfevah project
#
#  04/27/2018  sc   Initial development
#
###########################################################################

cd `dirname $0`

CONFIG=straingenemodelload.config

# provider specific config file
CONFIG_SGM=$1

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

if [ -f ${CONFIG_SGM} ]
then
    . ${CONFIG_SGM}
else
    echo "Missing configuration file: ${CONFIG_SGM}"
    exit 1
fi
echo "SGM_LOGICALDB ${SGM_LOGICALDB}"
echo "SGM_BIOTYPEFILE ${SGM_BIOTYPEFILE}"
echo "SGM_BCPFILE ${SGM_BCPFILE}"
echo "SGM_LOGFILE ${SGM_LOGFILE}"

#
# Initialize the log file.
#
LOG=${SGM_LOGFILE}
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

#
# Make sure the input file exists
#
if [ ! -f ${SGM_BIOTYPEFILE} ]
then
    echo "Input file does not exist: ${SGM_BIOTYPEFILE}" | tee -a ${LOG}
    exit 1
fi

echo "Creating bcp file" | tee -a  ${LOG}
${PYTHON} ./seqgenemodelload.py #>> ${LOG} 2>&1
STAT=$?
if [ $STAT -ne 0 ]
then
   echo "seqgenemodelload failed" | tee -a ${LOG}
   QUIT=1
elif [ ! -s ${SGM_BCPFILE} ]
then
    echo "The bcp file is empty" | tee -a ${LOG}
    QUIT=1
else
    QUIT=0
fi

#
# Do not attempt to delete/reload SEQ_GeneModel for the provider 
# if there was a problem creating the bcp file
#
if [ ${QUIT} -eq 1 ]
then
    exit 1
fi

#
# delete SEQ_GeneModel records for current provider
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Deleting the existing provider records" | tee -a ${LOG}
cat - <<EOSQL | psql -h${MGD_DBSERVER} -d${MGD_DBNAME} -U${MGD_DBUSER} -e  >> ${LOG}

select _Object_key as _Sequence_key
into temp toDelete
from ACC_Accession a
join acc_logicaldb ldb on
	ldb._logicaldb_key = a._logicaldb_key
where _MGIType_key = 19
and preferred = 1
and ldb.name = '${SGM_LOGICALDB}'
;

delete from SEQ_GeneModel
using toDelete t
where SEQ_GeneModel._Sequence_key = t._Sequence_key
;

EOSQL

#
# Load SEQ_GeneModel 
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Adding SEQ_GeneModel records" | tee -a ${LOG}

${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} SEQ_GeneModel "" ${SGM_BCPFILE} "\t" "\n" mgd >> ${LOG}

date >> ${LOG}

exit 0
