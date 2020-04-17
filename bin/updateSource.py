
##########################################################################
#
# Purpose:
#       update strain gene model molecular sources. The assemblyseqload is
#	configured to allow one molecular source per load based on logicalDB
#	We need to assign molecular source based on strain, so we do that
#	as a post-processing step
#
Usage='updateSource.py'
#
# Env Vars:
# Inputs: 
#	1. mgd database 
#
# Outputs:
#	 1. SEQ_Source_Assoc bcp file
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
#  06/13/2018  sc   Initial development
#
###########################################################################

import sys
import os
import string
import mgi_utils
import loadlib
import db

#
# CONSTANTS 
#
TAB= '\t'
CRT = '\n'

# MGI_User keys for the load
B6_CREATEDBY_KEY = 1605
MGP_CREATEDBY_KEY = 1602

# Logical DB Keys for the load
B6_LOGICALDB = 212
MGP_LOGICALDB = 209

# molecular source names for B6 and MGP
B6_SOURCE='Sequenced Mouse Strain C57BL/6J Genome Meta-data'
MGP_SOURCE='Sequenced Mouse Inbred Strain Genome Meta-data'

# true if only loading B6 (not MGP)
B6_ONLY = os.environ['B6_ONLY']

# current date
loaddate = loadlib.loaddate

#
# GLOBALS
#

# database primary keys, will be set to the next available from the db
nextAssocKey = None        # SEQ_Source_Assoc._Assoc_key

# annotation load file and file descriptor
b6BcpFile = os.environ['B6_SEQSOURCE_BCP']
fpB6BcpFile = ''

mgpBcpFile = os.environ['MGP_SEQSOURCE_BCP']
fpMgpBcpFile = ''

#
# lookups
#
sourceLookup = {}

# Purpose:  Load Source Lookup with both MGP and B6
# Returns: nothing
# Assumes: there is a connection to the database
# Effects: nothing
# Throws: nothing

def loadSourceLookup():
    global sourceLookup
        
    results = db.sql('''select _Strain_key, _Source_key
        from PRB_Source 
        where name in ('%s', '%s') ''' % (B6_SOURCE, MGP_SOURCE), 'auto')

    for r in results:
        sourceLookup[r['_Strain_key']] = r['_Source_key']

    return 0

# Purpose: init file descriptors, load lookups 
# Returns: nothing
# Assumes: nothing
# Effects: nothing
# Throws: nothing

def init():
    global fpB6BcpFile, fpMgpBcpFile, sourceLookup, nextAssocKey

    try:
        fpB6BcpFile = open(b6BcpFile, 'w')
    except:
        'Could not open file for writing %s\n' % b6BcpFile
        sys.exit(1)

    if B6_ONLY == 'false':
        try:
            fpMgpBcpFile = open(mgpBcpFile, 'w')
        except:
            'Could not open file for writing %s\n' % mgpBcpFile
            sys.exit(1)

    loadSourceLookup()

    # Log all SQL
    db.set_sqlLogFunction(db.sqlLogAll)
    db.useOneConnection(1)

    #
    # get next _Assoc_key
    #
    results = db.sql('''select max(_Assoc_key) + 1 as nextAssocKey
            from SEQ_Source_Assoc''', 'auto')
    if results[0]['nextAssocKey'] is None:
        nextAssocKey = 1000
    else:
        nextAssocKey = results[0]['nextAssocKey']

    return 0

# Purpose: processes B6 writes to bcp file
# Returns: nothing
# Assumes: nothing
# Effects: creates file in the filesystem
# Throws: nothing
def processB6():
    global nextAssocKey

    print 'Processing B6 molecular source'
    results = db.sql('''select sm._Strain_key, a2._Object_key as _Sequence_key
        from MRK_StrainMarker sm, ACC_Accession a1, ACC_Accession a2
        where sm._StrainMarker_key = a1._Object_key
        and a1._MGIType_key = 44 --MRK_StrainMarker
        and a1._LogicalDB_key = %s
        and a1.preferred = 1
        and a1.accid = a2.accid
        and a2._MGItype_key = 19 --SEQ_Sequence
        and a2._LogicalDB_key = %s 
        and a2.preferred = 1''' % (B6_LOGICALDB, B6_LOGICALDB) , 'auto')

    for r in results:
        strainKey = r['_Strain_key']
        if strainKey not in sourceLookup:
            print 'ERROR: _Strain_key: %s does not have named source' % strainKey
            continue

        sourceKey = sourceLookup[r['_Strain_key']]
        sequenceKey  = r['_Sequence_key']
        fpB6BcpFile.write('%s%s%s%s%s%s%s%s%s%s%s%s%s%s' % (nextAssocKey, TAB, sequenceKey, TAB, sourceKey, TAB, B6_CREATEDBY_KEY, TAB, B6_CREATEDBY_KEY, TAB, loaddate, TAB, loaddate, CRT ))
        nextAssocKey += 1

    fpB6BcpFile.close()
   
    # do deletes
    print 'Deleting existing B6 molecular source'
    db.sql('''select _Assoc_key
        into temporary table b6SourceToDelete
        from SEQ_Source_Assoc
        where _CreatedBy_key = %s''' % B6_CREATEDBY_KEY, None)
    db.sql('''delete from SEQ_Source_Assoc sa
        using b6SourceToDelete b6
        where sa._Assoc_key = b6._Assoc_key''', None)
    db.commit()

    return 0

# Purpose: processes MGP writes to bcp file
# Returns: nothing
# Assumes: nothing
# Effects: creates file in the filesystem
# Throws: nothing
def processMGP():
    global nextAssocKey

    print 'Processing MGP molecular source'
    results = db.sql('''select sm._Strain_key, a2._Object_key as _Sequence_key
        from MRK_StrainMarker sm, ACC_Accession a1, ACC_Accession a2
        where sm._StrainMarker_key = a1._Object_key
        and a1._MGIType_key = 44 --MRK_StrainMarker
        and a1._LogicalDB_key = %s
        and a1.preferred = 1
        and a1.accid = a2.accid
        and a2._MGItype_key = 19 --SEQ_Sequence
        and a2._LogicalDB_key = %s
        and a2.preferred = 1''' % (MGP_LOGICALDB, MGP_LOGICALDB) , 'auto')

    for r in results:
        strainKey = r['_Strain_key']
        if strainKey not in sourceLookup:
            print 'ERROR: _Strain_key: %s does not have named source' % strainKey
            continue

        sourceKey = sourceLookup[r['_Strain_key']]
        sequenceKey  = r['_Sequence_key']
        fpMgpBcpFile.write('%s%s%s%s%s%s%s%s%s%s%s%s%s%s' % (nextAssocKey, TAB, sequenceKey, TAB, sourceKey, TAB, MGP_CREATEDBY_KEY, TAB, MGP_CREATEDBY_KEY, TAB, loaddate, TAB, loaddate, CRT ))
        
        nextAssocKey += 1

    fpMgpBcpFile.close()
    
    # do deletes
    print 'Deleting existing MGP molecular source'
    db.sql('''select _Assoc_key
        into temporary table mgpSourceToDelete
        from SEQ_Source_Assoc
        where _CreatedBy_key = %s''' % MGP_CREATEDBY_KEY, None)
    db.sql('''delete from SEQ_Source_Assoc sa
        using mgpSourceToDelete mgp 
        where sa._Assoc_key = mgp._Assoc_key''', None)
    db.commit()

    return 0


# Purpose: creates the bcp file
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

db.useOneConnection(0)

print '%s' % mgi_utils.date()
