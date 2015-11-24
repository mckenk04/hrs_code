 %MACRO V12H70H; /* HIERARCHIES */;
 %**********************************************************************
 ***********************************************************************

 1  MACRO NAME:      V12H70H
 2  PURPOSE:         HCC HIERARCHIES: version 12 of HCCs
                     only 70 CMS HCCs are included
 3  COMMENT:         arrays to work with CCs and HCCs must be set in the
                     main program,
                     format ICD to CC creates only 70 CMS CCs
 **********************************************************************;

 %*to copy CC into HCC;
       DO K=1 TO &N_CC;
          HCC(K)=C(K);
       END;

 %*imposing hierarchies;
 /* Infection 5 */ if hcc5   =1 then do i=112;hcc(i)=0;end;
 /* Neoplasm1 */   if hcc7   =1 then do i=8,9,10;hcc(i)=0;end;
 /* Neoplasm 2 */  if hcc8   =1 then do i=9,10;hcc(i)=0;end;
 /* Neoplasm 3 */  if hcc9   =1 then do i=10;hcc(i)=0;end;
 /* Diabetes 1 */  if hcc15  =1 then do i=16,17,18,19;hcc(i)=0;end;
 /* Diabetes 2 */  if hcc16  =1 then do i=17,18,19;hcc(i)=0;end;
 /* Diabetes 3 */  if hcc17  =1 then do i=18,19;hcc(i)=0;end;
 /* Diabetes 4 */  if hcc18  =1 then do i=19;hcc(i)=0;end;
 /* Liver 1 */     if hcc25  =1 then do i=26,27;hcc(i)=0;end;
 /* Liver 2 */     if hcc26  =1 then do i=27;hcc(i)=0;end;
 /* SA1 */         if hcc51  =1 then do i=52;hcc(i)=0;end;
 /* Psychiatric */ if hcc54  =1 then do i=55;hcc(i)=0;end;
 /* Spinal 1 */    if hcc67  =1 then do i=68,69,100,101,157;hcc(i)=0;end;
 /* Spinal 2 */    if hcc68  =1 then do i=69,100,101,157;hcc(i)=0;end;
 /* Spinal 3 */    if hcc69  =1 then do i=157;hcc(i)=0;end;
 /* Arrest 1 */    if hcc77  =1 then do i=78,79;hcc(i)=0;end;
 /* Arrest 2 */    if hcc78  =1 then do i=79;hcc(i)=0;end;
 /* Heart 2 */     if hcc81  =1 then do i=82,83;hcc(i)=0;end;
 /* Heart 3 */     if hcc82  =1 then do i=83;hcc(i)=0;end;
 /* CVD 1 */       if hcc95  =1 then do i=96;hcc(i)=0;end;
 /* CVD6 */        if hcc100 =1 then do i=101;hcc(i)=0;end;
 /* Vascular 1 */  if hcc104 =1 then do i=105,149;hcc(i)=0;end;
 /* Lung 1 */      if hcc107 =1 then do i=108;hcc(i)=0;end;
 /* Lung 5 */      if hcc111 =1 then do i=112;hcc(i)=0;end;
 /* Urinary 3 */   if hcc130 =1 then do i=131,132;hcc(i)=0;end;
 /* Urinary 4 */   if hcc131 =1 then do i=132;hcc(i)=0;end;
 /* Skin 1 */      if hcc148 =1 then do i=149;hcc(i)=0;end;
 /* Injury 1 */    if hcc154 =1 then do i=75,155;hcc(i)=0;end;
 /* Injury 8 */    if hcc161 =1 then do i=177;hcc(i)=0;end;

  %MEND V12H70H;

