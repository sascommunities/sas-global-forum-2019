from sascyber.analytics.wh.base.WhLoginAnalytic import WhLoginAnalytic
from sascyber.utils.casutils import table_exists, get_available_fields


class Logins(WhLoginAnalytic):
    # Default constructor
    def __init__(self):
        super().__init__()
        self.set_input_field("")
        self.set_src_aggregation_action("distinct")
        self.set_output_field("_NDis_")
        self.set_analytic_field_name("Logins")

    def set_min_hosts(self, min_hosts):
        self.min_value = min_hosts

    def compute_evidence(self, input_table, all_event_table, evidence_table):

        fields_of_interest = self.src_id_fields + \
            self.comparison_fields + self.dst_id_fields

        super().compute_evidence(input_table, all_event_table,
                                 evidence_table, fields_of_interest=fields_of_interest)
