from functools import reduce
from glob import glob

from sascyber.analytics.base.CasAnalytic import CasAnalytic
from sascyber.utils.casutils import save_table, load_table, get_caslib_path, get_relative_path, get_available_fields
from sascyber.utils.decorators import timeExecution


class ConcatEventTables(CasAnalytic):
    # Default constructor
    def __init__(self):
        super().__init__()
        self.event_base_path = None
        self.event_file_name = None
        self.exclude_event_type_ids = None
        self.investiagtive_event_type_ids = None
        self.all_events_table = None
        self.device_id_fields = ["srcIpAddress", "src_ip_userId", "userId"]

    def set_event_base_path(self, event_base_path):
        self.event_base_path = event_base_path

    def set_event_file_name(self, event_file_name):
        self.event_file_name = event_file_name

    def set_exclude_event_type_ids(self, exclude_event_type_ids):
        self.exclude_event_type_ids = exclude_event_type_ids

    def set_investiagtive_event_type_ids(self, investiagtive_event_type_ids):
        self.investiagtive_event_type_ids = investiagtive_event_type_ids

    def set_all_events_table(self, all_events_table):
        self.all_events_table = all_events_table

    def set_device_id_fields(self, device_id_fields):
        self.device_id_fields = device_id_fields

    def create_table_to_concat(self, tables, out_table):

        time_cols = ['eventStartTime', 'startTime', 'timeId']
        userid_cols = ["src_ip_userId", "userId"]

        fields_of_interest = self.device_id_fields + time_cols
        fields_of_interest += ['eventTypeId', 'eventId', 'score', 'anomalousFlag', 'event_file']

        set_tables = []

        for table in tables:

            fields_to_select = get_available_fields(self.conn, fields_of_interest, table)

            select_time_col = None
            for time_col in time_cols:
                if time_col in fields_to_select:
                    select_time_col = time_col
            fields_to_select.remove(select_time_col)

            select_userid_col = None
            for userid_col in userid_cols:
                if userid_col in fields_to_select:
                    select_userid_col = userid_col
            fields_to_select.remove(select_userid_col)

            keep_str = F"keep = {' '.join(fields_to_select)} {select_time_col} {select_userid_col}"
            rename_str = F"rename = ({select_time_col}=eventTime {select_userid_col}=userId)"

            set_tables.append(F"{table} ({keep_str} {rename_str})")

        set_tables_str = " ".join(set_tables)

        code = F'''
            data {out_table};
                set {set_tables_str};
        '''

        self.log.debug(code)
        self.conn.datastep.runcode(code)

        return

    def add_event_file(self, table, event_file):
        code = F''' 
            data {table};
                length event_file varchar(*);
                set {table};
                event_file = "{event_file}";
        '''
        self.conn.datastep.runcode(code)

    @timeExecution
    def runAnalytic(self):

        # Load all event tables corresponding to the input file
        ae_caslib_path = get_caslib_path(self.conn, "AE")
        qual_events_base_path = ae_caslib_path + self.event_base_path
        all_event_files = glob(F"{qual_events_base_path}/**/{self.event_file_name}", recursive=True)

        # Remove excluded event type ids
        event_files = []

        if (self.exclude_event_type_ids is not None) and (len(self.exclude_event_type_ids) > 0):
            for event_file in all_event_files:
                match = [str(x) in event_file for x in self.exclude_event_type_ids]
                match_any = reduce(lambda x, y: x or y, match)
                if not match_any:
                    event_files.append(event_file)
        else:
            event_files = all_event_files

        self.log.debug(F"Concatenating events from files: {', '.join(event_files)}")

        loaded_tables = []

        index = 0
        for event_file in event_files:
            self.log.debug(event_file)
            rel_path = get_relative_path(self.conn, event_file, self.ae_caslib)

            where = None
            if not self.investigative_event(event_file):
                where = "anomalousFlag = 1"

            load_table(self.conn, F"T_{index}", rel_path, self.ae_caslib, promote=False, where=where)
            self.add_event_file(F"T_{index}", rel_path)
            loaded_tables.append(F"T_{index}")
            index = index + 1

        if len(loaded_tables) == 0:
            self.log.debug("No tables found for concatenation")
            return

        out_table = "table_to_concat"
        self.create_table_to_concat(loaded_tables, out_table)

        # Append outtable to all_events_long table in Hist caslib

        # Load all_events table if it is not already loaded
        table_loaded = load_table(self.conn, self.all_events_table, F"{self.all_events_table}.sashdat",
                                  self.hist_caslib, out_caslib=self.hist_caslib, promote=True)

        if (table_loaded):
            # Concat to the table
            code = F'''
                data {self.all_events_table}_new;
                    length userId varchar(*);
                    set {self.hist_caslib}.{self.all_events_table} {out_table};
            '''
            self.conn.datastep.runcode(code)
            self.log.debug(F"Created {self.all_events_table}_new by adding new events to {self.all_events_table}")

            # Delete old all_events table
            self.conn.droptable(name=self.all_events_table, caslib=self.hist_caslib)

            # Promote new all_events table as global all events table
            self.conn.table.promote(name=F"{self.all_events_table}_new", target=self.all_events_table,
                                    targetlib=self.hist_caslib)

        else:
            # else promote out_table as new all_events
            self.conn.table.promote(name=out_table, target=self.all_events_table, targetlib=self.hist_caslib)
            self.log.debug(F"Created all events table: {self.all_events_table}")

        # Save target table
        save_table(self.conn, self.all_events_table, F"{self.all_events_table}.sashdat", self.hist_caslib,
                   table_caslib=self.hist_caslib, replace=True)
        self.log.debug(F"Saved {self.all_events_table} table")

    def investigative_event(self, event_file):

        if self.investiagtive_event_type_ids is None or len(self.investiagtive_event_type_ids) == 0:
            return False

        for event_id in self.investiagtive_event_type_ids:
            if str(event_id) in event_file:
                return True

        return False

