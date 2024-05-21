set search_path = demo_cdm;

set datestyle to 'ymd';
\copy concept_recommended from '/tmp/concept_recommended.csv' with csv header;
