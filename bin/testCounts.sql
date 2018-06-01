#!/bin/csh
 
#
# Template for SQL report
#
# Notes:
#	- all public reports require a header and trailer
#	- all private reports require a header
#
# Usage:
#	template.sql MGD mgd
#

if ( ${?MGICONFIG} == 0 ) then
        setenv MGICONFIG /usr/local/mgi/live/mgiconfig
endif

source ${MGICONFIG}/master.config.csh

psql -h ${PG_DBSERVER} -U ${PG_DBUSER} -d ${PG_DBNAME} -e <<END >> $0.rpt
-- count of strain markers
select count(*)
from MRK_StrainMarker
;
-- count of B6 strain markers with MGI strain gene IDs
select count(*) from MRK_StrainMarker sm, ACC_Accession a
where sm._STrain_key = 38048 -- B6 strain markers
and sm._StrainMarker_key = a._Object_key
and a._MGIType_key = 44 -- MRK_StrainMarker
and a._LogicalDB_key = 212 -- MGI Strain Gene
;
-- count of MGP strain markers with MGP  IDs
select count(*) from MRK_StrainMarker sm, ACC_Accession a
where sm._STrain_key != 38048 -- MGP strain markers
and sm._StrainMarker_key = a._Object_key
and a._MGIType_key = 44 -- MRK_StrainMarker
and a._LogicalDB_key = 209 -- MGP
;
-- Count of MGP Strain Gene model sequences
select count(*) from SEQ_Sequence
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- count of B6 Strain Gene model sequences
select count(*) from SEQ_Sequence
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- count of MGP Strain Gene model accession ids
select count(*) from ACC_Accession
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- count of B6 Strain Gene model accession ids
select count(*) from ACC_Accession
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- Count of  MGP Strain Gene Model coordinates
select count(*) from MAP_Coord_Feature
where _CreatedBy_key = 1602 --mgp_asssemblyseqload
;
-- Count of B6 Strain GEne Model coordinates
select count(*) from MAP_Coord_Feature
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- Count of MGP Strain Gene model SEQ_GeneModel rows
select count(*) from SEQ_Sequence s, SEQ_GeneModel sgm
where s._CreatedBy_key = 1602 --mgp_assemblyseqload
and s._Sequence_key = sgm._Sequence_key
;
-- count of B6 Strain Gene model SEQ_GeneModel rows
select count(*) from SEQ_Sequence s, SEQ_GeneModel sgm
where s._CreatedBy_key = 1605 --b6_assemblyseqload
and s._Sequence_key = sgm._Sequence_key

END

