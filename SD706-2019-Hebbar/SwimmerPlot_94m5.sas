%let gpath='.';
%let dpi=300;
ods html close;
ods listing gpath=&gpath image_dpi=&dpi;

data swimmer;
  input id Stage $4-12 High contResponse $19 Status $21-37 Start End durableResponder $55;
  drop contResponse durableResponder;
    /* Convert flag to coord for scatter x=xDurable marker */
  xDurable = ifn(durableResponder EQ 'Y', -0.25, .);
  highCap = ifc(contResponse EQ 'Y', 'filledArrow', ' ');
  Low = 0;
  Startline=start; Endline=end;
  if status ne ' ' then do;
    if end eq . then endline=high-0.3;
    if start eq . then startline=low+0.3;
  end;
  
  datalines;
1  Stage 1  18.5    Complete response      6.5  13.5  Y
2  Stage 2  17.0    Complete response     10.5  17.0  Y
3  Stage 3  14.0  Y Partial response       2.5   3.5  Y
3           14.0  Y Partial response       6.0     .  Y
4  Stage 4  13.5  Y Partial response       7.0  11.0   
4           13.5  Y Partial response      11.5     .   
5  Stage 1  12.5  Y Complete response      3.5   4.5  Y
5           12.5  Y Complete response      6.5   8.5  Y
5           12.5  Y Partial response      10.5     .  Y
6  Stage 2  12.6  Y Partial response       2.5   7.0   
6           12.6  Y Partial response       9.5     .   
7  Stage 3  11.5    Complete response      4.5  11.5  Y
8  Stage 1  9.5     Complete response      1.0   9.5  Y
9  Stage 4  8.3     Partial response       6.0   8.3   
10 Stage 2  4.2   Y Complete response      1.2     .   
;
run;

data attrmap;
length ID $ 9 LineColor MarkerColor $ 20 LinePattern $10;
input id $ Value $10-30 linecolor $ markercolor linepattern $;
datalines;
statusC   Complete response    darkred   darkred solid
statusC   Partial response     blue      blue    solid
;
run;

/*--Swimmer Graph--*/
ods listing style=HTMLBlue;
ods graphics / reset width=5in height=3in imagename="Swimmer_SG_V94";

title 'Tumor Response for Subjects in Study by Month';
footnote  J=l h=0.8 'Each bar represents one subject in the study. A Right arrow at the end denotes continued response.';
footnote2 J=l h=0.8 'A durable responder is a subject who has confirmed response for at least 183 days (6 months).';

proc sgplot data = swimmer dAttrMap=attrmap noCycleAttrs;
  highLow y=id low=low high=high / highcap=highCap type=bar group=stage fill nooutline
          	lineAttrs=(color=black) name='stage' barwidth=1 noMissingGroup transparency=0.3;
  highLow y=id low=startLine high=endLine / group=status
            lineAttrs=(thickness=2 pattern=solid) name='status' noMissingGroup attrid=statusC;
  
  scatter y=id x=start / markerAttrs=(symbol=iBeam size=8) group=status attrid=statusC;
  scatter y=id x=end / markerAttrs=(symbol=circleFilled size=8) group=status attrid=statusC;

  scatter y=id x=xDurable / markerAttrs=(symbol=squareFilled size=6 color=black) name='RespDur'
			legendlabel='Durable responder';

  xaxis display=(nolabel) label='Months' values=(0 to 20 by 1) valueshint;
  yaxis reverse display=(noticks novalues noline) label='Subjects Received Study Drug';

  keyLegend 'stage' / title='Disease Stage';

	/* legendItem requires SAS 9.4 M5.
   * Use scatter with dummy data (or draw over) in older versions */
  legendItem name='RespStart' type = marker /
          markerAttrs=(symbol=iBeam size=8 color=darkgray) label='Response start';
  legendItem name='RespEnd' type = marker /
          markerAttrs=(symbol=circleFilled size=8 color=darkgray) label='Response end';
  legendItem name='RespCont' type = marker /
          markerAttrs=(symbol=triangleRightFilled size=12 color=darkgray) label='Continued response';

  keyLegend 'status' 'RespStart' 'RespEnd' 'RespCont' 'RespDur' / noborder
          location=inside position=bottomRight across=1 lineLength=20;
run;
title;
footnote;



