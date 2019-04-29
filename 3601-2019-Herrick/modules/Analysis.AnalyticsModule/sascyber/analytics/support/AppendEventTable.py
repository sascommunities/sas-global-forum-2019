from sascyber.analytics.base.CasAnalytic import CasAnalytic
from sascyber.utils.casutils import table_exists, load_table, save_table, append_table
from sascyber.utils.decorators import timeExecution


class AppendEventTable(CasAnalytic):

    # Default constructor
    def __init__(self):
        super().__init__()
        self.target = None
        self.source = None
        self.source_event_type_id = None

    def set_target(self, target):
        self.target = target

    def set_source(self, source):
        self.source = source

    def set_source_event_type_id(self, source_event_type_id):
        self.source_event_type_id = source_event_type_id

    @timeExecution
    def runAnalytic(self):

        # Load source table loaded if not already loaded
        source_table_name = self.source.format(intable=self.intable)
        source_file_rel_path = self.output_file_rel_path(self.source_event_type_id)
        source_loaded = load_table(self.conn, source_table_name, source_file_rel_path, self.ae_caslib, promote=False)

        if not source_loaded:
            self.log.debug("Source table does not exist. Nothing to append.")
            return

        append_table(self.log, self.conn, source_table_name, self.target, self.hist_caslib)
