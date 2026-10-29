filename birdcsv temp;

proc http
  method="GET"
  url="https://raw.githubusercontent.com/cjdinger/birdnet-data/refs/heads/main/alldetect.csv"
  out=birdcsv;
run;


data WORK.BIRDS_EVENTS;
  infile BIRDCSV delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;

  /* Attributes for raw data */
  informat Date yymmdd10.
    Time time20.3
    Sci_Name $30.
    Com_Name $30.
    Confidence best32.
    Lat best32.
    Lon best32.
    Cutoff best32.
    Week best32.
    Sens best32.
    Overlap best32.
    File_Name $57.;
  format Date yymmdd10.
    Time time20.3
    Sci_Name $30.
    Com_Name $30.
    Confidence best12.
    Lat best12.
    Lon best12.
    Cutoff best12.
    Week best12.
    Sens best12.
    Overlap best12.
    File_Name $57.;
 
  /* Additional features */
    length wikilink $ 150
           family $ 20;

  input
    Date
    Time
    Sci_Name  $
    Com_Name  $
    Confidence
    Lat
    Lon
    Cutoff
    Week
    Sens
    Overlap
    File_Name  $
  ;

  /* Reasonable guess at the Wikipedia link */
  wikilink = catt("https://en.wikipedia.org/wiki/",tranwrd(trim(Com_Name),' ','_'));
  family = scan(Com_Name,-1,' ');

run;

/* Summarize to daily detections */
PROC SQL noprint;
  CREATE TABLE WORK.birds_DailyDetect AS 
    SELECT t1.Date, 
      t1.Sci_Name, 
      t1.Com_Name, 
      t1.Family,
      /* Detections */
     (COUNT(t1.Date)) AS Detections 
  FROM WORK.birds_events t1 
  GROUP BY t1.Date, Family, t1.Sci_Name, t1.Com_Name
  order by Family desc;

  select count(distinct t1.Date) format=comma12. into: days TRIMMED from BIRDS_EVENTS t1;
  select count(distinct t1.Sci_Name) format=comma12. into: species TRIMMED from BIRDS_EVENTS t1;
  select (COUNT(t1.Date)) format=comma12. into: Detections TRIMMED from BIRDS_EVENTS t1;
QUIT;

/* generate a heatmap of the Com_Name Detections by day */
ods graphics / width=1200 height=2400;
ods html5(web) gtitle style=raven;

proc sgplot data=work.birds_DailyDetect;
  title "Heatmap of Birdsong Detections by Day";
  title2 "%trim(&species.) bird species over %trim(&days.) Days (%trim(%quote(&Detections.)) song detections)";
  scatter x=Date y=Com_Name / x2axis colorresponse=Detections  
    colormodel=(lightblue lightgreen darkgreen lightorange orange red darkred) 
       markerattrs=(size=4)
  ;
  xaxis grid minor display=none;
  x2axis grid minor display=(nolabel);
  yaxis fitpolicy=none grid minor  
      valueattrs=(size=8pt) display=(nolabel);
run;


/* Calculate first detection, most recent detection, number of days for each species */
PROC SQL;
  CREATE TABLE WORK.birds_FirstLastDistinct AS 
    SELECT 
      count(distinct t1.Date) as DaysObserved, 
      t1.Sci_Name, 
      t1.Com_Name, 
      t1.Family,
      /* Detections */
      (MIN(t1.Date)) AS First format=Date9.,
      (MAX(t1.Date)) as Last format=Date9.
  FROM WORK.birds_events t1 
  GROUP BY Family, t1.Sci_Name, t1.Com_Name;
QUIT;


ods html5(web) gtitle style=htmlencore;
title "Most recent newcomers to the backyard";
proc sql outobs=10;
 select * from birds_FirstLastDistinct t1
 order by First desc;
quit;

title "Those we have not seen for a while in the backyard";
proc sql outobs=10;
 select * from birds_FirstLastDistinct t1
 order by Last asc;
quit;

