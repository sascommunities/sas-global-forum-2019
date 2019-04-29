from swat import SWATCASActionError


def calculate_cdf(conn, log, comparison_fields, kde_field, kde_where, intable, outtable, promote):
    kde_success = True

    # Run kde
    try:

        cols = conn.table.columninfo(intable)["ColumnInfo"]["Column"].tolist()

        kde_out = conn.datapreprocess.kde(table={"name": intable, "groupby": comparison_fields, "where": kde_where},
                                          cdf=True,
                                          inputs=kde_field,
                                          casoutCDFMap={"name": outtable},
                                          copyvars=cols)

        # Merge intable with outtable to ensure all rows are in the outtable
        cols_str = " ".join(cols)

        code = f'''
            data {outtable}(rename=({kde_field}_cdfmap=CDF));
                merge {intable} {outtable};
                by {cols_str};
                if {kde_field}_cdfmap = . then {kde_field}_cdfmap = 0;
        '''
        conn.datastep.runcode(code)

        if promote:
            conn.table.promote(outtable)

        log.debug("Completed running KDE calculation")

    except SWATCASActionError as e:
        kde_success = False
        log.debug(F"KDE failed to run: {e}")

    if not kde_success:
        # Create outtable with CDF of zero
        code = F'''
            data {outtable};
                set {intable};
                CDF = 0;
        '''
        conn.datastep.runcode(code)
        log.debug("Setting CDF to zero since KDE failed")
