 %MACRO SCOREVR( PVAR=, RLIST=, CLIST=, N=);
 %**********************************************************************
 ***********************************************************************
  1  MACRO NAME:     SCOREVR
  2  PURPOSE:        calculate SCORE variable
  3  PARAMETERS:
                     PVAR    - SCORE variable name
                     RLIST   - regression variables list
                     CLIST   - coefficients list
                     N       - number of variables/coefficients
 ***********************************************************************;

        &PVAR=0;
        DO _I=1 TO &N;
           &PVAR = &PVAR + &RLIST(_I) * &CLIST(_I);
        END;

 %MEND SCOREVR;

