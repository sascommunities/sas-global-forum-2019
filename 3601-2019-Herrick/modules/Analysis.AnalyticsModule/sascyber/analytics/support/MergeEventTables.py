from sascyber.analytics.base.CasAnalytic import CasAnalytic
from sascyber.utils.decorators import timeExecution
from sascyber.utils.casutils import table_exists, save_table, load_tables


class MergeEventTables(CasAnalytic):
    # Default constructor
    def __init__(self):
        super().__init__()
        self.merged_all_events_table = None
        self.event_tables_cols = None
        self.event_analytic_duration = None
        self.set_src_id_fields(["srcIpAddress", "src_dn_hostname", "src_ip_userid"])

    def set_event_tables_cols(self, event_tables_cols):
        self.event_tables_cols = event_tables_cols

    def set_merged_all_events_table(self, merged_all_events_table):
        self.merged_all_events_table = merged_all_events_table

    def set_event_analytic_duration(self, event_analytic_duration):
        self.event_analytic_duration = event_analytic_duration

    def create_table_to_merge(self, table_name):

        merge_table_name = F"{table_name}_merge"

        if table_exists(self.conn, merge_table_name):
            self.log.debug("Merge events table already exists")
            return merge_table_name

        analytic_field_name = self.event_tables_cols[table_name]

        time_id_str = ''
        dur = self.event_analytic_duration["value"]
        if self.event_analytic_duration["unit"].upper() == 'HOUR':
            time_id_str = F'dhms(datepart(eventStartTime_sas), ceil(hour(eventStartTime_sas)/{dur}) * {dur}, 0, 0)'
        else:
            time_id_str = F'dhms(datepart(eventStartTime_sas), hour(eventStartTime_sas), \
                                ceil(minute(eventStartTime_sas)/{dur}) * {dur}, 0)'

        by_cols = self.src_id_fields + self.comparison_fields + [analytic_field_name, 'score', 'anomalousFlag']
        by_cols_str = " ".join(by_cols)

        keep_cols = ["timeId"] + self.src_id_fields + self.comparison_fields
        keep_cols += [analytic_field_name, F"{analytic_field_name}_score", F"{analytic_field_name}_anomalousFlag",
                      F"{analytic_field_name}_relEvents"]
        keep_cols_str = " ".join(keep_cols)

        code = F'''
            data {merge_table_name} (keep={keep_cols_str});
                retain {keep_cols_str};            
                set {table_name};    
                by {by_cols_str};
                length {analytic_field_name}_relEvents $ 100;
                if first.srcIpAddress then {analytic_field_name}_relEvents = '';
                {analytic_field_name}_relEvents = catx(', ', trim(eventId), {analytic_field_name}_relEvents);
                eventStartTime_sas = eventStartTime/1000000 + 315619200; /* Convert from unix micros to sas */
                timeId = {time_id_str}; /* Ceil to hour or min based on duration */
                {analytic_field_name}_score = score;
                {analytic_field_name}_anomalousFlag = anomalousFlag;
                if last.srcIpAddress then output;
        '''

        self.log.debug("Merge events table DS code:" + " ".join(code.split()))

        self.conn.datastep.runcode(code)
        self.conn.promote(merge_table_name)

        return merge_table_name



    @timeExecution
    def runAnalytic(self):

        qual_all_events_table = self.merged_all_events_table.format(intable=self.intable)

        if table_exists(self.conn, qual_all_events_table):
            self.log.debug("Merge events table already exists")
            return

        # Substitute intable in event_table_cols
        event_tables_cols_mod = {}

        for key, value in self.event_tables_cols.items():
            event_tables_cols_mod[key.format(intable=self.intable)] = value

        self.event_tables_cols = event_tables_cols_mod

        # Get list of all event tables
        tables = list(self.event_tables_cols.keys())

        # Load each of the table if it is not already loaded
        rel_paths = []
        for table in tables:
            event_type_id = table.split("_")[-3]
            rel_path = self.output_file_rel_path(event_type_id)
            rel_paths.append(rel_path)

        loaded_tables = load_tables(self.conn, tables, rel_paths, self.ae_caslib)

        # Create tables with desired columns
        tables_to_merge = list(map(self.create_table_to_merge, loaded_tables))

        if len(tables_to_merge) == 0:
            self.log.error("No tables to merge")
            return

        tables_to_merge_str = " ".join(tables_to_merge)

        # Run datastep to merge the tables
        groupby = "by " + " ".join(["timeId"] + self.src_id_fields + self.comparison_fields) + "; "
        code = "DATA " + qual_all_events_table + "; MERGE " + tables_to_merge_str + "; " + groupby + " run;"

        self.log.debug(code)
        self.conn.datastep.runcode(code)

        # Impute missing values
        code = "data {qual_all_events_table}; \
                    set {qual_all_events_table};\
                    array change _numeric_;\
                    do over change;\
                        if change=. then change=0;\
                    end;\
                run ;"

        code = code.format(qual_all_events_table=qual_all_events_table)

        self.log.debug("Merge events DS code:" + " ".join(code.split()))
        self.conn.datastep.runcode(code)
        self.conn.promote(qual_all_events_table)

        # Save the table
        output_file_rel_path = self.output_file_rel_path()
        save_table(self.conn, qual_all_events_table, output_file_rel_path, self.ae_caslib, replace=True)
        self.log.debug("Saved merge events table")


