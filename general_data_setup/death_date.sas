/*****************************************************************/
/* Construction of date of death file
/* this program creates a master file for date of death, including 
/* and prioritizing data in this order 1) NDI data (dod2010), 
/* 2) medicare care (dn_2000_2012 and BISF_1998_2012), and
/* 3) the exit interview (exit_02_to_12_dt).  
/*****************************************************************/
libname medi 'E:\data\cms_DUA_24548_2012';
libname medi_raw 'E:\data\cms_DUA_24548_2012\received_20150327';
libname hrs_cln 'E:\data\hrs_cleaned';
libname hrs_pub "E:\data\hrs_public_2012";
libname hrs_res "E:\data\hrs_restricted_2012";
libname ref "E:\data\Dartmouth_misc";

*restricted data;
proc contents data = hrs_res.dod2010_2; run;
proc contents data = hrs_res.ndi2010i9_r_3; run;
*proc contents data = hrs_res.ndi_2010_r_3; run;
*proc contents data = hrs_res.ndi2010i9_r_2; run;
proc contents data = hrs_res.xdod2012_2; run;
proc contents data = hrs_res.restricted_v2012; run;

* claims;
proc contents data = medi.dn_2000_2012; run;
proc contents data = medi_raw.BISF_1998_2012; run;
*proc contents data = medi_raw.BASF_1998_2012; run;
*proc contents data = medi_raw.BAQSF_1998_2012; run;

* exit interview - does not included dod;
proc contents data = hrs_cln.exit_02_to_12_dt; run;



proc freq data = medi.dn_2000_2012; tables V_DOD_SW /missing ; run;


* prepare data and create a source indicator for each incoming dataset;
data dod_ndi ; * sorted by id;
set hrs_res.dod2010_2 (rename=(death_date=dod_ndi10)); 
death_ndi=1;
run;
data dod_clm_dn ; * BID_HRS_21;
set  medi.dn_2000_2012(rename=(death_date=dod_dn12 sex=sex_dn));  
death_dn=1;
by BID_HRS_21 ;
if last.BID_HRS_21 then last_obs=death_dn;
if last_obs~=. then output;
run;
proc sort data=dod_clm_dn nodupkey; by BID_HRS_21 dod_dn12; run;
data dod_clm_bene ; * BID_HRS_21;
set  medi_raw.BISF_1998_2012 (rename=(BENE_DOD=dod_bene12 sex=sex_bene bene_dob=dob_bene12));  
death_bene=1;
by BID_HRS_21 ;
if last.BID_HRS_21 then last_obs=death_bene;
if last_obs~=. then output;
run;
proc sort data=dod_clm_bene nodupkey; by BID_HRS_21 dod_bene12; run;
data dod_exit ; *ID;
set hrs_res.xdod2012_2 (rename=(death_date=dod_exit12 dod_imp=dod_imp_exit12)); 
death_exit=1;
run;
data cmsref12;
set medi.cmsxref2012 (rename=(hhidpn=id));
run;
proc sort data=cmsref12 nodupkey; by id; run;


** combine 2010 ndi & 2012 claims data ** ;
data dod0 ;
merge  dod_ndi (drop= hhid pn in=ndi) cmsref12 (in=xcms);
by id ;
run;
proc sort data=dod0 ; by BID_HRS_21; run;
** add in claims **;
data dod1;
merge dod0 dod_clm_dn (in=dn)dod_clm_bene (in=bene);
by BID_HRS_21 ;
run;
proc sort data=dod1 ; by id; run;
proc sort data=dod_exit ; by id; run;
** add exit interview;
data dod2 ;
merge  dod1 dod_exit (in=exit);
by id ;
run;

** check for duplicate ids;
** there are 1414 cases missing claims (BID_HRS_21) and no cases missing HRS (ID);
proc freq data=dod2; tables BID_HRS_21 /noprint out=keylist; run;
proc print; where count ge 2; run;
proc freq data=dod2; tables id /noprint out=keylist; run;
proc print; where count ge 2; run;

/**************************************************************************************
combine death data - 
1) use NDI dates first, 
2) if claims are reported after NDI date then use date from claims (NOT dme file!)
3) last use exit 
track source of death data
**************************************************************************************/
data dod3  
  (keep = BID_HRS_21 ID age bene_dob birth_date birth_day birth_month birth_year dob_bene12
   death_bene death_day death_dn death_exit death_month death_ndi death_year dod_bene12  
   dod_dn12 dod_exit12 dod_imp dod_imp_exit12 dod_ndi10 death_all death_source death_imp_all
   death_any V_DOD_SW );
set dod2;
format dod_ndi10 dod_dn12 dod_bene12 dod_exit12 death_all MMDDYY10.;
death_all=. ;
death_source=. ;
array death (4) dod_ndi10 dod_dn12 dod_bene12 dod_exit12;
array source (4) death_ndi death_dn death_bene death_exit;
do i=1 to 4;
   if death_all = . then death_all=death(i);
   if death_source = . and death(i) ne . then death_source= i;
   if death(i) ne . then death_any=1;
end;
if death_source= 4 & dod_imp_exit12=1 then death_imp_all= 1;
label death_all='Date of death combined from ndi, claims, exit';
label death_source='Source of dod: 1=ndi, 2=dn, 3=bene, 4=exit';
label death_imp_all='Dod imputed - exit interview';
label dod_ndi10='Date of death reported in the NDI data'; 
label dod_dn12='Date of death reported in the mc den file';  
label dod_bene12='Date of death reported in the mc bene sum file';  
label dod_exit12='Date of death reported in the HRS exit invw';  
label death_ndi ='Respondent located in the NDI data '; 
label death_dn ='Respondent located in the mc den file'; 
label death_bene ='Respondent located in the mc bene file'; 
label death_exit='Respondent located in the exit ivw file'; 
label death_any='Date of death reported from any source'; 
run;
data hrs_cln.death_date_2012 ;
set dod3;
where death_any=1;
run;


*** check discharge dates after date of death for each medicare file;
proc sort data=dod3; by bid_hrs_21; run;
proc sort data=medi.mp_2000_2012; by bid_hrs_21 disch_date; run;
data disch_mp ; *( keep=BID_HRS_21 disch_date_mp dif_mp) ;
merge dod3 medi.mp_2000_2012 (rename=(disch_date=disch_date_mp));
by BID_HRS_21;
if disch_date_mp>death_all then dif_mp=disch_date_mp-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_mp>0 then output;
run;
proc sort data=medi.ip_2000_2012; by bid_hrs_21 disch_date; run;
data disch_ip ( keep=BID_HRS_21 disch_date_ip dif_ip) ;
merge dod3 medi.ip_2000_2012 (rename=(disch_date=disch_date_ip));
by BID_HRS_21;
if disch_date_ip>death_all then dif_ip=disch_date_ip-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_ip>0 then output;
run;
proc sort data=medi.op_2000_2012; by bid_hrs_21 disch_date; run;
data disch_op ( keep=BID_HRS_21 disch_date_op dif_op) ;
merge dod3 medi.op_2000_2012 (rename=(disch_date=disch_date_op));
by BID_HRS_21;
if disch_date_op>death_all then dif_op=disch_date_op-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_op>0 then output;
run;
proc sort data=medi.pb_2000_2012; by bid_hrs_21 disch_date; run;
data disch_pb ( keep=BID_HRS_21 disch_date_pb dif_pb) ;
merge dod3 medi.pb_2000_2012 (rename=(disch_date=disch_date_pb));
by BID_HRS_21;
if disch_date_pb>death_all then dif_pb=disch_date_pb-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_pb>0 then output;
run;
proc sort data=medi.hh_2000_2012; by bid_hrs_21 disch_date; run;
data disch_hh ( keep=BID_HRS_21 disch_date_hh dif_hh) ;
merge dod3 medi.hh_2000_2012 (rename=(disch_date=disch_date_hh));
by BID_HRS_21;
if disch_date_hh>death_all then dif_hh=disch_date_hh-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_hh>0 then output;
run;
proc sort data=medi.hs_2000_2012; by bid_hrs_21 disch_date; run;
data disch_hs ( keep=BID_HRS_21 disch_date_hs dif_hs) ;
merge dod3 medi.hs_2000_2012 (rename=(disch_date=disch_date_hs));
by BID_HRS_21;
if disch_date_hs>death_all then dif_hs=disch_date_hs-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_hs>0 then output;
run;
proc sort data=medi.sn_2000_2012; by bid_hrs_21 disch_date; run;
data disch_sn ( keep=BID_HRS_21 disch_date_sn dif_sn) ;
merge dod3 medi.sn_2000_2012 (rename=(disch_date=disch_date_sn));
by BID_HRS_21;
if disch_date_sn>death_all then dif_sn=disch_date_sn-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_sn>0 then output;
run;
proc sort data=medi.dm_2000_2012; by bid_hrs_21 disch_date; run;
data disch_dm ( keep=BID_HRS_21 disch_date_dm dif_dm) ;
merge dod3 medi.dm_2000_2012 (rename=(disch_date=disch_date_dm));
by BID_HRS_21;
if disch_date_dm>death_all then dif_dm=disch_date_dm-death_all;
if last.BID_HRS_21 then last_obs=death_any;
if last_obs~=. AND dif_dm>0 then output;
run;

data disch_all;
merge dod3 disch_mp disch_ip disch_op disch_pb disch_hh disch_hs disch_sn disch_dm;
by BID_HRS_21 ;
array cate (8) dif_mp dif_ip dif_op dif_pb dif_hh dif_hs dif_sn dif_dm;
array cate_gp (8) dif_mp_gp dif_ip_gp dif_op_gp dif_pb_gp dif_hh_gp dif_hs_gp dif_sn_gp dif_dm_gp;
   do i=1 to 8;
      if cate(i)>0 AND cate(i)<32 then cate_gp(i)=1;
	  else if cate(i)>31 AND cate(i)<376 then cate_gp(i)=2;
	  *else if cate(i)>359 AND cate(i)<371 then cate_gp(i)=3;
	  else if cate(i)>375 then cate_gp(i)=4;
	  end;
dif_all=max(dif_mp, dif_ip, dif_op, dif_pb, dif_hh, dif_hs, dif_sn ); *, dif_dm);
dif_all_gp=max(dif_mp_gp, dif_ip_gp, dif_op_gp, dif_pb_gp, dif_hh_gp, dif_hs_gp, dif_sn_gp, dif_dm_gp);
format disch_date_mp disch_date_ip disch_date_op disch_date_pb disch_date_hh disch_date_hs disch_date_sn disch_date_dm MMDDYY10.;
if dif_mp>0 OR dif_ip>0 OR dif_op>0 OR dif_pb>0 OR dif_hh>0 OR dif_hs>0 OR dif_sn>0 OR dif_dm>0  then output;
run;
proc freq data=disch_all; tables BID_HRS_21 /noprint out=keylist; run;
proc print; where count ge 2; run;




ods rtf file="C:\Users\mckenk04\Death_discharge_08042015.rtf";

proc means data=disch_all mean median min max n;
var dif_all dif_mp dif_ip dif_op dif_pb dif_hh dif_hs dif_sn dif_dm; run;
proc freq data=disch_all ; 
table dif_all; 
run;
proc freq data=disch_all ; 
table dif_all_gp dif_mp_gp dif_ip_gp dif_op_gp dif_pb_gp dif_hh_gp dif_hs_gp 
  dif_sn_gp dif_dm_gp; 
run;
proc freq data=disch_all ; 
table dif_all_gp dif_mp_gp dif_ip_gp dif_op_gp dif_pb_gp dif_pb_gp dif_hh_gp
   dif_hs_gp dif_sn_gp dif_dm_gp; 
where death_source=2 OR death_source=3; 
run;
proc freq data=disch_all ; 
tables (dif_all_gp dif_mp_gp dif_ip_gp dif_op_gp dif_pb_gp dif_pb_gp dif_hh_gp 
   dif_hs_gp dif_sn_gp dif_dm_gp) * death_source;
run;
ods rtf close;

proc print data=disch_all (obs=200);
var id dif_all bid_hrs_21 death_source dod_ndi10 dod_dn12 dod_bene12 dod_exit12 
    disch_date_mp disch_date_ip disch_date_op disch_date_pb disch_date_hh 
    disch_date_hs disch_date_sn disch_date_dm;
where dif_all>1000  ;
run;


proc print data=disch_all (obs=200);
var id dif_all bid_hrs_21 death_source dod_ndi10 dod_dn12 dod_bene12 dod_exit12 
    disch_date_mp disch_date_ip disch_date_op disch_date_pb disch_date_hh 
    disch_date_hs disch_date_sn disch_date_dm;
*where dif_all>1000  ;
*where dod_ndi10=. and dod_dn12=. and dod_bene12=. and dod_exit12 ne . ;
where  (dod_dn12 ne . or dod_bene12 ne . ) and (dod_ndi10=. and dod_exit12 = . ) ;
run; 


* document source of compiled date of death and number of cases incoming from each source;
proc freq data=hrs_cln.death_date_2012 ; 
tables death_any death_source death_ndi death_dn death_bene death_exit death_imp_all; run;

* document the number of imputed dates of death included for the exit data;
proc freq data=hrs_cln.death_date_2012 ;
tables death_source * death_imp_all; run;

* document discrepancies;
data discrep;
set hrs_cln.death_date_2012 ;
if (dod_ndi10 ne . and dod_dn12 ne .) and dod_ndi10 ne dod_dn12 then  ndi_dn= 1   ;
if (dod_ndi10 ne . and dod_bene12 ne .) and dod_ndi10 ne dod_bene12 then  ndi_bene= 1 ;
if (dod_ndi10 ne . and dod_exit12 ne .) and dod_ndi10 ne dod_exit12 then  ndi_exit= 1 ;
if (dod_dn12 ne . and dod_bene12 ne .) and dod_dn12 ne dod_bene12 then   dn_bene= 1  ;
if (dod_dn12 ne . and dod_exit12 ne .) and dod_dn12 ne dod_exit12 then   dn_exit=  1 ;
if (dod_bene12 ne . and dod_exit12 ne .) and dod_bene12 ne dod_exit12 then bene_exit= 1 ;
run;

proc freq data=discrep ;
tables ndi_dn ndi_bene ndi_exit dn_bene dn_exit bene_exit /missing ;
run;
proc print data=discrep (obs=50);
var id death_source dod_ndi10 dod_dn12 dod_bene12 dod_exit12 ;
where (dod_ndi10 ne . and dod_dn12 ne .) and dod_ndi10 ne dod_dn12 ;
run;


* are discrepant cases between ndi and dn files validated in the dn file? ;
proc freq data=discrep ;
tables   V_DOD_SW /missing ;
where ndi_dn =1;
run;
