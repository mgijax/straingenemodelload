#!/bin/csh -x
 
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

echo ${PG_DBSERVER}
echo ${PG_DBNAME}
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
-- creation date of B6 strain markers
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from MRK_StrainMarker
where _Refs_key = 282660
;
-- count of MGP strain markers with MGP  IDs
select count(*) from MRK_StrainMarker sm, ACC_Accession a
where sm._STrain_key != 38048 -- MGP strain markers
and sm._StrainMarker_key = a._Object_key
and a._MGIType_key = 44 -- MRK_StrainMarker
and a._LogicalDB_key = 209 -- MGP
;
-- creation date of MGP strain markers
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from MRK_StrainMarker
where _Refs_key = 282407
;
-- Count of MGP Strain Gene model sequences
select count(*) from SEQ_Sequence
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- creation date of  MGP Strain Gene model sequences
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from SEQ_Sequence
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- count of B6 Strain Gene model sequences
select count(*) from SEQ_Sequence
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- creation date of B6 Strain Gene model sequences
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from SEQ_Sequence
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- count of MGP Strain Gene model accession ids
select count(*) from ACC_Accession
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- creation date of MGP Strain Gene model accession ids
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from ACC_Accession
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- count of B6 Strain Gene model accession ids
select count(*) from ACC_Accession
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- creation date of B6 Strain Gene model accession ids
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from ACC_Accession
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- count of  MGP Strain Gene Model coordinates
select count(*) from MAP_Coord_Feature
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- creation date of MGP Strain Gene model coordinates
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from MAP_Coord_Feature
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- count of B6 Strain Gene Model coordinates
select count(*) from MAP_Coord_Feature
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- creation date of B6 Strain Gene Model coordinates
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from MAP_Coord_Feature
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- Count of MGP Strain Gene Model sequence IDs
select count(*) from ACC_Accession
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- creation date of MGP Strain Gene Model sequence IDs
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from ACC_Accession
where _CreatedBy_key = 1602 --mgp_assemblyseqload
;
-- Count of B6 Strain Gene Model sequence IDs
select count(*) from ACC_Accession
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- creation date of B6 Strain Gene Model sequence IDs
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from ACC_Accession
where _CreatedBy_key = 1605 --b6_assemblyseqload
;
-- Count of MGP Strain Gene model SEQ_GeneModel rows
select count(*) from SEQ_Sequence s, SEQ_GeneModel sgm
where s._CreatedBy_key = 1602 --mgp_assemblyseqload
and s._Sequence_key = sgm._Sequence_key
;
-- creation date of MGP Strain Gene model SEQ_GeneModel
select distinct to_char(sgm.creation_date, 'MM/dd/yyyy') as creation_date
from SEQ_Sequence s, SEQ_GeneModel sgm
where s._CreatedBy_key = 1602 --mgp_assemblyseqload
and s._Sequence_key = sgm._Sequence_key
;
-- count of B6 Strain Gene model SEQ_GeneModel rows
select count(*) from SEQ_Sequence s, SEQ_GeneModel sgm
where s._CreatedBy_key = 1605 --b6_assemblyseqload
and s._Sequence_key = sgm._Sequence_key
;
-- creation date of B6 Strain Gene model SEQ_GeneModel
select distinct to_char(sgm.creation_date, 'MM/dd/yyyy') as creation_date
from SEQ_Sequence s, SEQ_GeneModel sgm
where s._CreatedBy_key = 1605 --b6_assemblyseqload
and s._Sequence_key = sgm._Sequence_key
;
-- count of B6 Strain Gene Model Source 
select count(*)
from SEQ_Source_Assoc
where _CreatedBy_key = 1605; --b6_assemblyseqload
;
-- creation date of B6 Strain Gene Model Source 
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from SEQ_Source_Assoc
where _CreatedBy_key = 1605; --b6_assemblyseqload
;
-- count of MGP Strain Gene Model Source
select count(*)
from SEQ_Source_Assoc
where _CreatedBy_key = 1602; --mgp_assemblyseqload
;
-- creation date of MGP Strain Gene Model Source
select distinct to_char(creation_date, 'MM/dd/yyyy') as creation_date
from SEQ_Source_Assoc
where _CreatedBy_key = 1602; --mgp_assemblyseqload
;
-- counts of MGP sources by strain
select s._strain_key,  count(s._Strain_key)
into temporary table strainsMGP
from ACC_Accession a, PRB_Source s, SEQ_Source_Assoc sa
where a._MGIType_key = 19
and a._logicalDB_key = 209
and a._Object_key = sa._Sequence_key
and sa._Source_key = s._Source_key
group by s._Strain_key
;
create index idx1 on strainsMGP(_Strain_key)
;
select s.*, ps.strain
from strainsMGP s, PRB_Strain ps
where s._Strain_key = ps._Strain_key
;
-- counts of B6 sources by strain
select s._strain_key,  count(s._Strain_key)
into temporary table strains
from ACC_Accession a, PRB_Source s, SEQ_Source_Assoc sa
where a._MGIType_key = 19
and a._logicalDB_key = 212
and a._Object_key = sa._Sequence_key
and sa._Source_key = s._Source_key
group by s._Strain_key
;
create index idx2 on strains(_Strain_key)
;
select s.*, ps.strain
from strains s, PRB_Strain ps
where s._Strain_key = ps._Strain_key
;
-- count of MGP MCV/Strain Marker annotations
select count(*) 
from VOC_Annot a, VOC_Evidence e
where a._AnnotType_key = 1025 -- MCV/Strain Marker
and a._Annot_key = e._Annot_key
and e._Refs_key = 282407 --J:259852
;
-- creation date of MGP MCV/Strain Marker annotations
select distinct to_char(e.creation_date, 'MM/dd/yyyy') as creation_date
from VOC_Annot a, VOC_Evidence e
where a._AnnotType_key = 1025 -- MCV/Strain Marker
and a._Annot_key = e._Annot_key
and e._Refs_key = 282407 --J:259852
;
-- count of B6 MCV/Strain Marker annotations
select count(*)
from VOC_Annot a, VOC_Evidence e
where a._AnnotType_key = 1025 -- MCV/Strain Marker
and a._Annot_key = e._Annot_key
and e._Refs_key = 282660 --J:260092
;
-- creation date of  B6 MCV/Strain Marker annotations
select distinct to_char(e.creation_date, 'MM/dd/yyyy') as creation_date
from VOC_Annot a, VOC_Evidence e
where a._AnnotType_key = 1025 -- MCV/Strain Marker
and a._Annot_key = e._Annot_key
and e._Refs_key = 282660 --J:260092
;
END

