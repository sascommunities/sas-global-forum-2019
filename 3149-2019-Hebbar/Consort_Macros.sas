/***
 * Macros for use in Consort diagram.
 * No user data here.
 */

%macro enrollExcluded(n1=, n2=, n3=, n4=);
  cat ("Excluded (n=", &n1., 
     ").* Not meeting inclusion criteria (n=", &n2., 
     ").* Declined to participate (n=", &n3., 
     ").* Other reasons (n=", &n4., 
     ")");
%mend enrollExcluded;

%macro allocation(arm=, n1=, n2=, n3=);
  cat ("Allocated to ", &arm., 
     ". (n=", &n1., 
     ").* Received allocated.  drug (n=", &n2., 
     ").* Did not receive.  allocated drug (n=", &n3., 
     ")");
%mend allocation;

%macro followup(n1=, n2=, n3=, n4=, n5=);
  cat ("Discontinued drug. (n=",&n1.,
     ") due to:.* Adverse events (n=", &n2.,  
     ").* Withdrawn (n=", &n3.,
     ").* Death (n=",&n4.,
     ").* Other (n=", &n5., 
     ")");
%mend followup;

%macro analysis(n1=, n2=, n3=, n4=);
  cat ("FAS (n=",&n1., 
     ").* Excluded from FAS.  (n=",&n2., 
     ").* Safety set (n=", &n3.,
     ").* Excluded from SS.  (n=",&n4.,
     ")");
%mend analysis;

/**
 * Create all the data for rendering the Consort diagram
 */
%macro consortData(inData=, outData=, arms=4, nColumns=4);

  %if (&nColumns < 3) %then
  %do;
    %let nColumns = 3;
    %put NOTE: nColumns has to be at least 3: setting nColumns to 3;
  %end;
  %if (&nColumns < &arms) %then
  %do;
    %let nColumns = &arms;
    %put NOTE: nColumns is less than arms: setting nColumns to &arms;
  %end;

  /*--Some constants --*/
  %local rowSpacing pad headerWidth yAssess yRandom yExclude yHeader
          widthFix dx;

  %let rowSpacing=0.25; /* Also the headerHeight */
  %let pad=0.02;
  %let headerWidth=0.1;
  %let yAssess=%sysevalf(0.2 * &rowSpacing);
  %let yRandom=%sysevalf(0.7 * &rowSpacing);
  %let yExclude=%sysevalf(0.4 * &rowSpacing);
  %let yHeader=%sysevalf(0.5 * &rowSpacing);

    /*--Pad to increase the width of the Exclude box when columns=3--*/
  %let widthFix = %sysevalf(0.05 * (4 - &nColumns));
    /* width for each arm column - excluding header column */
  %let dx = %sysevalf((1 - &headerWidth)/&nColumns);

  /* Augment user count info with obs needed for rendering */
  data &indata._aug;
    set &indata;
    retain row 0;

    /* Insert a Header obs before each new Stage, for rendering purpose only */
    if (Stage NE lag(Stage)) then do;
      row + 1; col = 1; 
      Arm = 'Header'; call missing(n1, n2, n3, n4, n5);
      output;
    end;

    col + 1;
    link get_row_again;
    output;
    return;

    get_row_again:
      set &indata;
      return;

  run;
    
  /*--Diagram Layout: Calculate box (node) width and heights: w, h */
  data layout;
    set &indata._aug end=last;

    h=&rowSpacing; /* Height */

    select (Arm); /* w = Width */
      when ('Header')
        do; w = &headerWidth; end;
      when ('Randomized', 'Assessed')
        do; w = (&nColumns-1)*&dx/2; h=0.1; end;
      when ('Excluded')
        do; w = &widthFix + (&nColumns-1)*&dx/2; h=0.2; end;
      otherwise
        w = &dx;
    end;
	  output;

	  /*--Generate the Row=Dummy obs between Enrollment and Allocation--*/
	  if last then do;
	    call missing (Arm, n1, n2, n3, n4, n5);
	    Row=1.5; Stage='Dummy';  h = 2*&pad;
      do Col = 1 to 5;
        if (&arms > (Col - 2)) then output;
      end;
	  end;
    
  run;

  /*--Compute diagram box node centers (nx, ny) --*/
  data node_info;
    set layout;

    /*--Compute node center (x, y)--*/
    select (Row);
      when (4, 3, 2) do; /*--Analysis, Follow-Up and Allocation--*/
        ny = (Row - 0.5) * &rowSpacing; 
        select (Col);
          when (1) do; nx=&headerWidth/2; output; end;
          when (2) do; nx=&headerWidth+w/2; output; end;
          when (3) do; nx=&headerWidth+1.5*w; output; end;
          when (4) if &arms > 2 then do; nx=&headerWidth+2.5*w; output; end;
          when (5) if &arms > 3 then do; nx=&headerWidth+3.5*w; output; end;
          otherwise;
        end;
	    end;

      when (1.5) do;  /*--Dummy Row to draw top arrows from horizontal line--*/
        ny = &rowSpacing - 1 * &pad;
        select (Col);
          when (1) do; nx=&headerWidth/2; output; end;
          when (2) do; nx=&headerWidth+w/2; output; end;
          when (3) do; nx=&headerWidth+1.5*w; output; end;
          when (4) if &arms > 2 then do; nx=&headerWidth+2.5*w; output; end;
          when (5) if &arms > 3 then do; nx=&headerWidth+3.5*w; output; end;
          otherwise;
        end;
      end;

      when (1) do;  /*--Enrollment--*/
        select (Col);
          when (1) do; ny=&yHeader; nx=&headerWidth/2; output; end;
          when (2) do; ny=&yAssess; nx=&headerWidth+&dx; output; end;
          when (3) do; ny=&yExclude;
                       nx = &headerWidth + (&nColumns-1)*&dx + &widthFix;
                       output;
                   end;
          when (4) do; ny=&yRandom; nx=&headerWidth+&dx; output; end;
          otherwise;
        end;
      end;

	  otherwise;
    end;
  run;

  /*--Compute Consort diagram Node polygon data, text plot labels --*/
  data nodes;
    length vLabel $10 hLabel $200 position $10;
    drop halfNodeH halfNodeW yTop yBottom xLeft xRight n1-n5;
    retain pid 0;
    set node_info;

    halfNodeH = h/2 - &pad; halfNodeW = w/2 - &pad;
    yTop = ny - halfNodeH;  yBottom = ny + halfNodeH;
    xLeft = nx - halfNodeW; xRight = nx + halfNodeW;

    pid+1;

	  /*--Compute node polygons for non-Dummy rows--*/
    if row ne 1.5 then do; 
      if col eq 1 then do; /*--Is a Header--*/
        /* polygon box: 4 vertices */
        vLabel = '';
        yf = yTop;    xf = xLeft;   output;
        /* same yf */ xf = xRight;  output;
        yf = yBottom; /* same xf */ output;
        /* same yf */ xf = xLeft;   output;   

        /* text plot */
        yl = ny; xl = nx; vLabel = Stage; output;
      end;
      else do;  /*--Not a Header--*/
        /* polygon box: 4 vertices */
        hLabel = '';
        y = yTop;    x = xLeft;   output;
        /* same y */ x = xRight;  output;
        y = yBottom; /* same x */ output;
        /* same y */ x = xLeft;   output;   

        /* text plot */
        yl = ny; 

		    /*--set the text for the nodes--*/
        select (Row);
          when (4) do; hLabel=%analysis(n1=n1, n2=n2, n3=n3, n4=n4);
                          xl=xLeft; position='Right'; end;
          when (3) do; hLabel=%followup(n1=n1, n2=n2, n3=n3, n4=n4, n5=n5);
                          xl = xLeft; position='Right'; end;
          when (2) do; hLabel=%allocation(arm=Arm, n1=n1, n2=n2, n3=n3);
                          xl = xLeft; position='Right'; end;

        /*--set the text for the nodes in Enrollment stage--*/
          when (1) do; 
            if col=2 then do;
                    hLabel=cat ("Assessed for Eligibility (", n1, ")");
                    xl = nx; position='Center'; end;
            if col=3 then do;
                    hLabel=%enrollExcluded(n1=n1, n2=n2, n3=n3, n4=n4);
                    xl = xLeft; position='Right'; end;
            if col=4 then do;
                    hLabel=cat ("Randomized (", n1, ")");
                    xl = nx; position='Center'; end;
          end;
        end; /* Select Row */
        output;
      end;
    end;
  run;

  /* Reorder node info data set by X and Y */
  proc sort data=node_info out=nodes_sorted;
    by col row;
  run;
  
  /*--Compute the Consort diagram Links between non-Header nodes--*/
  data links;
    keep linkId xlink ylink linkId2 xlink2 ylink2;
    retain linkId 0 xp yp;
    set nodes_sorted (where=(stage ne 'Enrollment' and Arm ne 'Header')) end=last;
    by col row; /* by X and Y */

    linkId2=.;

    nh = h - 2 * &pad;
	  /*--Upper end of link, output both ends, and compute "previous"--*/
    if (^ first.col) then do;
      ylink = yp; xlink = xp; output;
	    ylink = ny - nh/2; xlink = nx; output;
	    linkId + 1;
    end;
	  /*--Store bottom end of current node as previous link coords (xp, yp)--*/
    yp = ny + nh/2; xp=nx; 

    /*--Create the custom links in the Enrollment stage--*/
    if last then do;
      call missing (stage, Arm, xlink, ylink, linkId2, xlink2, ylink2);
      
	    /*--Vertical link from Assessed to Randomize --*/
      xlink = &headerWidth + &dx;

      ylink = &yAssess + 0.05 - &pad; output;
      ylink = &yRandom - (0.05 - &pad); output; 

	    linkId+1;

	    /*--Horizontal link to Excluded--*/
      ylink = &yExclude;

      /* xlink = &headerWidth + &dx; stays the same! */
      output;

      xlink = &headerWidth + (&ncolumns - 1) * &dx * 0.75 + &widthFix/2 + &pad;
      output; 

	    linkId=.;

	    /*--Horizontal link over 4 ARMs--*/
      linkId2 = 0;
      ylink2 = &rowSpacing - &pad;
      
      xlink2 = &headerWidth + &dx/2; output;
      xlink2 = &headerWidth + (&arms - 0.5) * &dx; output;

	    /*--Vertical link from Randomize to previous Horizontal link--*/
      linkId2 + 1;
      xlink2 = &headerWidth + &dx;

      ylink2 = &yRandom + 0.05 - &pad; output;
	    ylink2 = &rowSpacing - &pad; output; 
    end;
  run;

  /*--combine node and link data--*/
  data &outData.;
    set nodes links;
    drop Stage Arm Row Col w h nx ny;
  run;

%mend consortData;


/**
 * Draw the Consort Diagram, given the full diagram data.
 */
%macro consortDiagram(diagData= , fillColor=stgb);

  proc sgPlot data=&diagData noBorder noAutoLegend;
    /*--Filled boxes--*/
    polygon id=pid x=xf y=yf / fill outline 
            fillAttrs=(color=&fillColor) lineAttrs=graphDataDefault;

    /*--vertical text--*/
    text x=xl y=yl text=vLabel / rotate=90 textAttrs=(size=9 color=white);

    /*--Empty boxes--*/
    polygon id=pid x=x y=y / lineAttrs=graphDataDefault;

    /*--horizontal text, left aligned--*/
    text x=xl y=yl text=hLabel / splitChar='.' splitPolicy=splitAlways
            position=position;

    /*--Links--*/
    series x=xlink y=ylink / group=linkId lineAttrs=graphDataDefault
            arrowHeadPos=end arrowHeadShape=barbed arrowHeadScale=0.4;
            
    /*--Links without arrow heads--*/
    series x=xlink2 y=ylink2 / group=linkId2 lineAttrs=graphDataDefault;

    xAxis display=none min=0 max=1 offsetMin=0 offsetMax=0;
    yAxis display=none min=0 max=1 offsetMin=0 offsetMax=0 reverse;
  run;

%mend consortDiagram;
