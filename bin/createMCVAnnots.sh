#!/bin/sh
#
#  createMCVAnnots.sh
###########################################################################
#
#  Purpose:
#
#      This script calls createMCVAnnots.py to create MCV annotload file
#	Then invokes annotload to load MCV annotations to strain/markers
#
#  Usage:
#
#      createMCVAnnots.sh
#
#
#  Env Vars:
#
#
#  Inputs: the database and configuration
#
#  Outputs:
#       - annotation load input file
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
#      1) Call the python script (createMCVAnnots.py) input file for
#	     strain/marker MCV annotations (delete and reload) for MGP and/or B6
#      2) Call the annotload to load the annotations for MGP and/or B6
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
#  06/01/2018  sc   TR12734 genfevah project
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

B6_CONFIG=${STRAINGENEMODELLOAD}/b6_annotload.csh.config
MGP_CONFIG=${STRAINGENEMODELLOAD}/mgp_annotload.csh.config

#
# Initialize the log file.
#
LOG=${MCV_LOGFILE}

if [ -f ${LOG} ]
then
    rm ${LOG}
fi

echo 'Creating MCV annotations' >> ${LOG}
date >> ${LOG}

echo "Creating MCV annotation load input file" | tee -a  ${LOG}
${PYTHON} ./createMCVAnnots.py >> ${LOG} 2>&1
STAT=$?
if [ $STAT -ne 0 ]
then
   echo "createMCVAnnots.py failed" | tee -a ${LOG}
   exit 1
fi

# Run the annotload
# Make sure you cd into the output directory
# since the annotload puts its output files into
# the current-working-directory
#
cd ${OUTPUTDIR}

echo "" >> ${LOG}
date >> ${LOG}

if [ "${B6_ONLY}" = "false" ]
then
    echo 'Loading MGP MCV Annotations'
    ${ANNOTLOAD}/annotload.csh ${MGP_CONFIG} mcv
fi

echo 'Loading B6 MCV Annotations'
${ANNOTLOAD}/annotload.csh ${B6_CONFIG} mcv

date >> ${LOG}

exit 0
