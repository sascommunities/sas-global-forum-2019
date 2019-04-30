from sascyber.analytics.base.CasAnalytic import CasAnalytic
from sascyber.utils.casutils import table_exists, get_available_fields, save_table
from sascyber.utils.decorators import timeExecution
from sascyber.utils.kde import calculate_cdf


class DstAnalytic(CasAnalytic):
    # Default constructor
    def __init__(self):
        self.input_field = None
        self.src_aggregation_action = None
        self.output_field = None
        self.min_value = 0
        super().__init__()

    def set_input_field(self, input_field):
        self.input_field = input_field

    def set_src_aggregation_action(self, src_aggregation_action):
        self.src_aggregation_action = src_aggregation_action

    def set_output_field(self, output_field):
        self.output_field = output_field

    def set_min_value(self, min_value):
        self.min_value = min_value

    def compute_all_events(self, input_table, cdf_table, cdf_field, analytic_field, min_value,
                           all_event_table):
        if table_exists(self.conn, all_event_table):
            self.log.debug("All events table already exists")
            return

        self.conn.loadactionset("fedsql")

        ne_create_table = F"CREATE TABLE {all_event_table} AS "

        event_type_id = self.event_type_id
        ne_fields = [F'{event_type_id} as "eventTypeId"',
                     'n.' + cdf_field + ' as "' + analytic_field + '"',
                     'n.cdf as "score"']
        ne_fields += list(map(lambda x: 'n.' + x, ['cmpMin', 'cmpMean', 'cmpMax', 'cmpCount']))
        ne_fields += ['min(r.starttime) as "eventStartTime"',
                      'max(r.starttime) as "eventEndTime"',
                      'max(r.starttime) - min(r.starttime) as "eventDuration"']

        all_fields = ne_fields + list(map(lambda x: "r." + x + ' as "' + x + '"',
                                          self.src_id_fields + self.comparison_fields))

        ne_select = "SELECT " + ", ".join(all_fields)

        from_tables = [F"{input_table} AS r", F"{cdf_table} as n"]

        ne_from = " FROM " + ", ".join(from_tables)

        where_clauses = list(map(lambda x: "n." + x + " = " + "r." + x, self.src_id_fields))
        where_clauses += list(map(lambda x: "n." + x + " = " + "r." + x, self.comparison_fields))

        ne_where = " WHERE " + " AND ".join(where_clauses)

        groupby_fields = ["n." + cdf_field, "n.cdf"]
        groupby_fields += list(map(lambda x: 'n.' + x, ['cmpMin', 'cmpMean', 'cmpMax', 'cmpCount']))
        groupby_fields += list(map(lambda x: "r." + x, self.src_id_fields))
        groupby_fields += list(map(lambda x: "r." + x, self.comparison_fields))

        ne_group_by = " GROUP BY " + ", ".join(groupby_fields)

        all_event_query = ne_create_table + ne_select + ne_from + ne_where + ne_group_by

        self.log.debug("All event table query:" + " ".join(all_event_query.split()))

        self.conn.fedsql.execdirect(all_event_query)

        ne_code = F"DATA {all_event_table};\
                    SET {all_event_table};\
                    FORMAT eventId $HEX32.; "

        # all_fields = ["eventTypeId", analytic_field, "score",
        #               "eventStartTime", "eventEndTime", "eventDuration"]
        #
        # all_fields += self.src_id_fields + self.comparison_fields

        all_fields = self.conn.columninfo(all_event_table)["ColumnInfo"]["Column"].tolist()
        all_fields_str = ", ".join(all_fields)

        event_id = F" eventId = put(md5(cats({all_fields_str})), $hex32.);"

        threshold = self.threshold
        ne_flag = F"  IF score > {threshold} AND {analytic_field} > {min_value} THEN anomalousFlag = 1; "
        ne_flag += " ELSE anomalousFlag = 0;"

        ne_code = ne_code + event_id + ne_flag

        self.log.debug("All events DS code:" + " ".join(ne_code.split()))
        self.conn.runcode(ne_code)
        self.conn.promote(name=all_event_table)

    def compute_evidence(self, input_table, all_event_table, evidence_table, fields_of_interest=None):

        if table_exists(self.conn, evidence_table):
            self.log.debug("Evidence table already exists")
            return

        self.conn.loadactionset("fedsql")

        ev_create_table = F"CREATE TABLE {evidence_table} AS "

        ev_fields = ["n.eventTypeId", "n.eventId", 'n.anomalousFlag']

        distinct_flag = (self.src_aggregation_action.upper() == 'DISTINCT')

        if fields_of_interest is None:
            fields_of_interest = []

            if distinct_flag:
                fields_of_interest += self.src_id_fields + self.comparison_fields + [self.input_field]
            else:
                fields_of_interest += ["starttime"] + self.src_id_fields + ["srcPort"] + self.dst_id_fields + \
                                      ["dstPort"] + self.comparison_fields + ["protocol", self.input_field]

        fields_to_select = get_available_fields(self.conn, fields_of_interest, input_table)

        ev_fields += list(map(lambda x: "r." + x, fields_to_select))

        ev_select = "SELECT "

        if distinct_flag:
            ev_select += " DISTINCT "

        ev_select += ", ".join(ev_fields)

        from_tables = [F"{input_table} AS r", F"{all_event_table} AS n"]
        ev_from = " FROM " + ", ".join(from_tables)

        fields_of_interest = self.src_id_fields + self.comparison_fields

        fields_in_where = get_available_fields(self.conn, fields_of_interest, all_event_table)

        ev_where_clauses = list(map(lambda x: "n." + x + " = " + "r." + x, fields_in_where))

        ev_where = " WHERE " + " AND ".join(ev_where_clauses)

        ev_query = ev_create_table + ev_select + ev_from + ev_where

        self.log.debug("Evidence table query:" + " ".join(ev_query.split()))
        self.conn.fedsql.execdirect(ev_query)
        self.conn.promote(name=evidence_table)

    def compute_evidence_detail(self, input_table, input_record_type, all_event_table, ev_detail_table):

        if table_exists(self.conn, ev_detail_table):
            self.log.debug("Evidence details table already exists")
            return

        self.conn.loadactionset("fedsql")

        query = F"CREATE TABLE {ev_detail_table} AS "
        query += 'SELECT \'' + input_record_type + '\' AS "recordType", r.*, \
                  n.eventId as "eventId", n.anomalousFlag as "anomalousFlag" '

        from_tables = [F"{all_event_table} AS n", F"{input_table} AS r"]
        query += " FROM " + ", ".join(from_tables)

        where_clauses = list(map(lambda x: "n." + x + " = " + "r." + x,
                                 self.src_id_fields + self.comparison_fields))

        where_clauses.append("n.anomalousFlag = 1")

        query += " WHERE " + " AND ".join(where_clauses)

        self.log.debug("Evidence detail table query:" + " ".join(query.split()))
        self.conn.fedsql.execdirect(query)
        self.conn.promote(name=ev_detail_table)

    @timeExecution
    def runAnalytic(self):

        # Summarize or distinctcount by src
        summarize_by_src_table = self.intable + "_" + str(self.event_type_id) + "_by_src"
        groupby = self.src_id_fields + self.comparison_fields
        input_table = self.select_input_table()
        self.run_operation(self.src_aggregation_action, self.input_field, groupby, input_table,
                           summarize_by_src_table)
        self.log.debug("Completed summarize or distinct count by src")

        # Summarize by comparison fields
        summarize_by_cmp_fields_table = self.intable + "_" + str(self.event_type_id) + "_by_cmp"
        self.summarize_analytic_by_cmp_fields(summarize_by_src_table, self.output_field, summarize_by_cmp_fields_table)
        self.log.debug("Completed summarize by comparison fields or by enterprise")

        # Combine by src and cmp tables
        combined_table = self.intable + "_" + str(self.event_type_id) + "_by_src_cmp"
        self.combine_analytic_raw_and_by_cmp_fields(summarize_by_src_table, summarize_by_cmp_fields_table,
                                                    combined_table)
        self.log.debug("Combined by-src and by-comparison-group tables")

        # Compute deviations of flows
        deviation_table = self.intable + "_" + str(self.event_type_id) + "_dev"
        self.standardize_analytic(combined_table, self.output_field, deviation_table)
        self.log.debug("Computed analytic deviations")

        # Run KDE and calculate pValues
        score_table = self.intable + "_" + str(self.event_type_id) + "_score"
        calculate_cdf(self.conn, self.log, self.comparison_fields, "_TR1_" + self.output_field,
                      "_TR1_" + self.output_field + "> 0", deviation_table, score_table, True)
        self.log.debug("Executed KDE analysis and computed CDF values")

        # Compute all events
        all_event_table = self.intable + "_" + str(self.event_type_id) + "_all_evt"
        self.compute_all_events(self.filtered_input_table, score_table, self.output_field,
                                self.analytic_field_name, self.min_value, all_event_table)
        self.log.debug("Created all events table")

        # Save events
        output_file_rel_path = self.output_file_rel_path()
        save_table(self.conn, all_event_table, output_file_rel_path, self.ae_caslib, replace=True)
        self.log.debug("Saved all events table")

        # Compute evidence
        evidence_table = self.intable + "_" + str(self.event_type_id) + "_ev"
        self.compute_evidence(self.filtered_input_table, all_event_table, evidence_table)
        self.log.debug("Created evidence table")

        # Save evidence
        save_table(self.conn, evidence_table, output_file_rel_path, self.ev_caslib, replace=True)
        self.log.debug("Saved evidence table")

        # Compute evidence details
        ev_detail_table = self.intable + "_" + str(self.event_type_id) + "_ed"
        self.compute_evidence_detail(self.filtered_input_table, self.input_caslib, all_event_table, ev_detail_table)
        self.log.debug("Created evidence details table")

        # Save evidence detail
        save_table(self.conn, ev_detail_table, output_file_rel_path, self.ed_caslib, replace=True)
        self.log.debug("Saved evidence details table")

        # Concat events to history index
        self.concat_events_to_history(all_event_table, output_file_rel_path)
        self.log.debug("Events sent for concatenation to history index")

