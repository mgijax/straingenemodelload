#!/usr/local/bin/python

##########################################################################
#
# Purpose:
#       creates bcp file for SEQ_GeneModel for MGP
#
Usage='seqgenemodelload.py'
#
# Env Vars:
#        1. SGM_BCP_FILE_PATH
#	 2. MGP_LOGICALDB
# Inputs: 
#	1. mgd database to resolve mgpId to sequence key and
#	      translate raw biotype to _MarkerType_key 
#       2. MGP file, from stdin, mapping mgpId to raw biotype
#
# Outputs:
#	 1. SEQ_GeneModel bcp file, tab-delimited
#           1. _Sequence_key
#	    2. _GMMarkerType_key
#	    3. raw biotype 
#	    4. exonCount (null)
#	    5. transcriptCount (null)
#	    6. _CreatedBy_key
#	    7. _ModifiedBy_key
#	    8. creation_date
#	    9. modification_date
#
# 	 2. Log file
#
# Exit Codes:
#
#      0:  Successful completion
#      1:  An exception occurred
#
#  Assumes:  Nothing
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
#  04/30/2018  sc   Initial development
#
###########################################################################

import sys
import os
import string
import mgi_utils
import db

#
# CONSTANTS 
#
TAB= '\t'
CRT = '\n'

# Biotype Translation Type
TRANSTYPE='Raw Biotype to Marker Type'

# MGI_User key for the load
CREATEDBY_KEY = 1602

#
# GLOBALS
#

# bcp file path
bcpFilePath = os.environ['SGM_BCPFILE']

# input file path
inputFilePath = os.environ['SGM_BIOTYPEFILE']

# file descriptors
inFile = ''
bcpFile = ''

# timestamp for creation/modification date
cdate = mgi_utils.date('%m/%d/%Y')      # current date

#
# lookups
#
# loaded from provider input file - maps gene model ID to raw biotype
rawBioTypeByGMIDLookup = {}     # {mgpId:rawBioType, ...}

# loaded from db translation query - maps raw biotype to _MarkerType_key
markerTypeKeyByRawBioTypeLookup = {} # {rawBioType:_MarkerType_key}

# loaded from db by provider - maps a mgpId to its _Sequence_key
seqKeyByGMIDLookup = {} # {mgpId:_Sequence_key, ...}

# Provider we are loading 'ncbi', 'ensembl', or 'vega'
provider = ''

# Purpose:  Load biotype translation Lookup; Lookup raw biotype
#           to get MGI Marker Type Key
# Returns: nothing
# Assumes: there is a connection to the database
# Effects: nothing 
# Throws: nothing

def loadMarkerTypeKeyLookup():
    global markerTypeKeyByRawBioTypeLookup

    # load the MGP biotype translation into a lookup
    results = db.sql('''SELECT distinct t.term, m._Marker_Type_key
        FROM MRK_BiotypeMapping m, VOC_Term t
        WHERE m._biotypeterm_key = t._Term_key
	AND t._Vocab_key = 136''', 'auto')
    for r in results:
        markerTypeKeyByRawBioTypeLookup[r['term']] = r['_Marker_Type_key']
    return 0

# Purpose:  Load  sequence key lookup by seqId for a given provider
# Returns: nothing
# Assumes: there is a connection to the database
# Effects: nothing
# Throws: nothing


def loadSequenceKeyLookup():
    global seqKeyByGMIDLookup

    ldbName =  os.environ['MGP_LOGICALDB']
    results = db.sql('''SELECT _LogicalDB_key
		FROM ACC_LogicalDB
		WHERE name = '%s' ''' % ldbName, 'auto')
    if len(results) == 0:
        print 'LogicalDB name not in database: %s' % ldbName
        sys.exit(1)
    ldbKey = results[0]['_LogicalDB_key']
    results = db.sql('''SELECT accId, _Object_key as seqKey
                FROM ACC_Accession
                WHERE _MGIType_key = 19
                AND _LogicalDB_key = %s
                AND preferred = 1''' % ldbKey, 'auto')
    for r in results:
        seqKeyByGMIDLookup[r['accId']] = r['seqKey']

    return 0

# Purpose:  Load lookup of raw biotype by gene model ID for
#	    MGP
# Returns: nothing
# Assumes: inFile is a valid file descriptor
# Effects: nothing
# Throws: nothing

def loadMGPRawBioTypeByGMIDLookup():
    global rawBioTypeByGMIDLookup

    for line in inFile.readlines():

        tokens  =  string.split(line, TAB)
	mgpId = tokens[0]
	rawBiotype =  string.strip(tokens[1])

        rawBioTypeByGMIDLookup[mgpId] = rawBiotype
        #print '%s %s %s' % (mgpId, rawBiotype, CRT)

    return 0
# Purpose: Initialize globals; load lookups 
# Returns: nothing
# Assumes: nothing
# Effects: nothing
# Throws: nothing

def init():
    global inFile, bcpFile

    try:
        inFile = open(inputFilePath, 'r')
    except:
        'Could not open file for writing %s\n' % inputFilePath
        sys.exit(1)

    try:
        bcpFile = open(bcpFilePath, 'w')
    except:
        'Could not open file for writing %s\n' % bcpFilePath
        sys.exit(1)

    print 'loading MGP Raw Biotype By GMID Lookup'
    loadMGPRawBioTypeByGMIDLookup()

    print 'loading Sequence Key Lookup'
    loadSequenceKeyLookup()

    print 'loading Marker Type Key Lookup'
    loadMarkerTypeKeyLookup()

    return 0

# Purpose: create the bcp file
# Returns: nothing
# Assumes: nothing
# Effects: creates file in the filesystem
# Throws: nothing

def run ():
    print 'Creating bcp file for %s ' % provider
    # current count of gm IDs found in database, but not in input
    notInInputCtr = 0

    # current count of gm IDs found in database, but input raw biotype
    # will not translate
    noTranslationCtr = 0

    for mgpId in seqKeyByGMIDLookup:
	sequenceKey = seqKeyByGMIDLookup[mgpId]

	if mgpId in rawBioTypeByGMIDLookup:
	    rawBioType = rawBioTypeByGMIDLookup[mgpId]
	else:
	    print '%s is not in the input file' % mgpId
	    notInInputCtr = notInInputCtr + 1
	    continue

	if rawBioType in markerTypeKeyByRawBioTypeLookup:
	    markerTypeKey = markerTypeKeyByRawBioTypeLookup[rawBioType]
	else:
	    print 'MGP GM ID %s raw biotype "%s" has no translation in the database' \
		% (mgpId, rawBioType)
	    noTranslationCtr = noTranslationCtr + 1
	    continue

	bcpFile.write('%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s' % \
	    (sequenceKey, TAB, markerTypeKey, TAB, rawBioType, TAB, \
		TAB, TAB, CREATEDBY_KEY, TAB, CREATEDBY_KEY, TAB, \
		cdate, TAB, cdate, CRT) )

    print '\n%s %s MGP gene model Ids in the database but not in the input file' % \
	(notInInputCtr, provider)

    print '\n%s %s MGP gene model Ids not loaded because unable to translate biotype\n' % (noTranslationCtr, provider)

    return 0
#
# Main
#

print '%s' % mgi_utils.date()
print 'Initializing'
init()

print '%s' % mgi_utils.date()
print 'Creating bcp file'
run()
inFile.close()
bcpFile.close()

