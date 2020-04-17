
##########################################################################
#
# Purpose:
#       creates Strain/Marker annotation load input file
#
Usage='createMCVAnnots.py'
#
# Env Vars:
# Inputs: 
#	1. mgd database 
#
# Outputs:
#	 1. annotload input files
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
#  06/01/2018  sc   Initial development
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

# MGI_User key for the load
CREATEDBY_KEY = 1600

B6_ONLY = os.environ['B6_ONLY']

# JNumbers for MGI B6 and MGP annotations, we want to be able to 
# delete by reference used in columns 3 (reference) and 5 (inferred from)
B6_JNUM = 'J:260092'
MGP_JNUM = 'J:259852'

# evidence code
EVIDENCE = 'IC'

# null qualifier
QUALIFIER = ''

# Editor, MGI_User.login
EDITOR = 'cjb'

# current date use null
DATE = ''

# no notes
NOTES = ''

# Logical DB
B6_LDBNAME = 'MGI Strain Gene'
MGP_LDBNAME = 'Mouse Genome Project'

#
# GLOBALS
#

# annotation load file and file descriptor
b6AnnotFile = os.environ['MCV_B6_ANNOTLOAD_INPUTFILE']
fpB6AnnotFile = ''

mgpAnnotFile = os.environ['MCV_MGP_ANNOTLOAD_INPUTFILE']
fpMgpAnnotFile = ''

#
# lookups
#
featureTypeLookup = {}

# Purpose:  Load mcv lookup for B6
# Returns: nothing
# Assumes: there is a connection to the database
# Effects: nothing
# Throws: nothing

def loadFeatureTypeLookup():
    global featureTypeLookup
    results = db.sql('''select t.term, a.accid as mcvID
        from VOC_Term t, ACC_Accession a
        where t._Vocab_key = 79 --MCV
        and t._Term_key = a._Object_key
        and a._MGIType_key = 13
        and a._LogicalDB_key = 146 --MCV''', 'auto')
    for r in results:
        featureTypeLookup[r['term']] = r['mcvID']

    return 0

# Purpose: init file descriptors, load lookups 
# Returns: nothing
# Assumes: nothing
# Effects: nothing
# Throws: nothing

def init():
    global fpB6AnnotFile, fpMgpAnnotFile

    try:
        fpB6AnnotFile = open(b6AnnotFile, 'w')
    except:
        'Could not open file for writing %s\n' % b6AnnotFile
        sys.exit(1)

    try:
        fpMgpAnnotFile = open(mgpAnnotFile, 'w')
    except:
        'Could not open file for writing %s\n' % mgpAnnotFile
        sys.exit(1)

    loadFeatureTypeLookup()

    # Log all SQL
    db.set_sqlLogFunction(db.sqlLogAll)
    db.useOneConnection(1)

    return 0

# Purpose: processes B6 writes to annotation load input file
# Returns: nothing
# Assumes: nothing
# Effects: creates file in the filesystem
# Throws: nothing
def processB6():
    print 'Processing B6'
    db.sql('''-- get b6 strain/markers and their accids
        select a.accid as b6ID, a._Object_key as _StrainMarker_key
        into temporary table b6Ids
        from ACC_Accession a
        where a._MGIType_key = 44 --MRK_StrainMarker
        and a._LogicalDB_key = 212 --MGI B6
        and a.preferred = 1''', None)

    db.sql('''create index idx1 on b6Ids(b6ID)''', None)
    
    results = db.sql('''-- get the biotypes for the B6 gene models
        select b6.b6ID, sgm.rawBiotype as biotype
        from b6Ids b6, ACC_Accession a, SEQ_GeneModel sgm
        where b6.b6ID = a.accid
        and a._MGIType_key = 19
        and a._LogicalDB_key = 212 --MGI B6
        and a.preferred = 1
        and a._Object_key = sgm._Sequence_key''', 'auto')
    
    for r in results:
        b6ID = r['b6ID']
        biotype = r['biotype'] # actually the feature type
        if biotype not in featureTypeLookup:
            print 'Cannot resolve B6: %s to Feature Type' % biotype
            continue
        mcvID = featureTypeLookup[biotype]
        fpB6AnnotFile.write('%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s' % (mcvID, TAB, b6ID, TAB, B6_JNUM, TAB, EVIDENCE, TAB, B6_JNUM, TAB, QUALIFIER, TAB, EDITOR, TAB, DATE, TAB, NOTES, TAB, B6_LDBNAME, CRT))

    return 0

# Purpose: processes MGP writes to annotation load input file
# Returns: nothing
# Assumes: nothing
# Effects: creates file in the filesystem
# Throws: nothing
def processMGP():
    print 'Processing MGP'
    db.sql('''-- get mgp strain/markers and their accids
        select a.accid as mgpID, a._Object_key as _StrainMarker_key
        into temporary table mgpIds
        from ACC_Accession a
        where a._MGIType_key = 44 --MRK_StrainMarker
        and a._LogicalDB_key = 209 --MGP
        and a.preferred = 1''', None)
    db.sql('''create index idx2 on mgpIds(mgpID)''', None)

    results = db.sql('''-- get the biotypes for the MGP gene models
        select mgp.mgpID, sgm.rawBiotype as biotype
        from mgpIds mgp, ACC_Accession a, SEQ_GeneModel sgm
        where mgp.mgpID = a.accid
        and a._MGIType_key = 19
        and a._LogicalDB_key = 209 --MGP
        and a.preferred = 1
        and a._Object_key = sgm._Sequence_key''', 'auto')
    
    for r in results:
        mgpID = r['mgpID']
        biotype = r['biotype'] # actually the feature type
        if biotype not in featureTypeLookup:
            print 'Cannot resolve MGP: %s to Feature Type' % biotype
            continue
        mcvID = featureTypeLookup[biotype]
        fpMgpAnnotFile.write('%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s' % (mcvID, TAB, mgpID, TAB, MGP_JNUM, TAB, EVIDENCE, TAB, MGP_JNUM, TAB, QUALIFIER, TAB, EDITOR, TAB, DATE, TAB, NOTES, TAB, MGP_LDBNAME, CRT))

    return 0


# Purpose: creates the annotation load input file
# Returns: nothing
# Assumes: nothing
# Effects: creates file in the filesystem
# Throws: nothing

def run ():
    if B6_ONLY == 'false':
        processMGP()

    processB6()

    return 0
#
# Main
#

print '%s' % mgi_utils.date()
print 'Initializing'
init()

print '%s' % mgi_utils.date()
run()

fpB6AnnotFile.close()
fpMgpAnnotFile.close()

db.useOneConnection(0)

print '%s' % mgi_utils.date()
