# encoding: utf-8
#
# Copyright SAS Institute
#
#  Licensed under the Apache License, Version 2.0 (the License);
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#


'''
    base analytic class from which all others are derived.
'''
import logging
import os
import time

from swat import SWATCASActionError

from sascyber.analytics.base.Analytic import Analytic
from sascyber.utils.casutils import table_exists, caslib_exists, get_relative_path, row_count, load_table, \
    connect_to_cas, get_available_fields
from sascyber.utils.concurrency import Concurrency
from sascyber.utils.decorators import timeExecution
# from sascyber.utils.rabbitutils import send_to_rabbitmq


class CasAnalytic(Analytic):

    def __init__(self):

        super().__init__()

        self.cas_host = None
        self.cas_port = None
        self.cas_authinfo = None
        self.cas_protocol = None
        self.swat_messages = None
        self.swat_trace = None

        self.queuing_server_host = None
        self.queuing_server_port = None
        self.queuing_server_user = None
        self.queuing_server_password = None

        self.elasticsearch_server_host = None
        self.elasticsearch_server_port = None

        self.conn_mandatory = True

        self.input_file = None
        self.input_caslib = None
        self.input_file_name = None
        self.input_file_rel_path = None
        self.input_import_options = None
        self.index_vars = None

        self.ae_caslib = None
        self.ev_caslib = None
        self.ed_caslib = None
        self.hist_caslib = None
        self.models_caslib = None
        self.train_caslib = None
        self.lookups_caslib = None
        self.se_caslib = None

        self.conn = None
        self.enabled = True
        self.work_caslib = None
        self.groupby = None
        self.where = None
        self.inputs = None
        self.promote = True
        self.filter = None
        self.filters = None
        self.threshold = None
        self.event_type_id = None
        self.investigative_event = False
        self.comparison_fields = []

        self.intable = None
        self.filtered_input_table = None
        self.preprocessed_table = None

        self.cleanup = False
        self.analytic_field_name = None

        self.src_id_fields = None
        self.dst_id_fields = None

        self.log = None

    def set_cas_host(self, cas_host):
        self.cas_host = cas_host

    def set_cas_port(self, cas_port):
        self.cas_port = cas_port

    def set_cas_authinfo(self, cas_authinfo):
        self.cas_authinfo = cas_authinfo

    def set_cas_protocol(self, cas_protocol):
        self.cas_protocol = cas_protocol

    def set_swat_messages(self, swat_messages):
        self.swat_messages = swat_messages

    def set_swat_trace(self, swat_trace):
        self.swat_trace = swat_trace

    def set_conn_mandatory(self, conn_mandatory):
        self.conn_mandatory = conn_mandatory

    def set_queuing_server_host(self, queuing_server_host):
        self.queuing_server_host = queuing_server_host

    def set_queuing_server_port(self, queuing_server_port):
        self.queuing_server_port = queuing_server_port

    def set_queuing_server_user(self, queuing_server_user):
        self.queuing_server_user = queuing_server_user

    def set_queuing_server_password(self, queuing_server_password):
        self.queuing_server_password = queuing_server_password

    def set_elasticsearch_server_host(self, elasticsearch_server_host):
        self.elasticsearch_server_host = elasticsearch_server_host

    def set_elasticsearch_server_port(self, elasticsearch_server_port):
        self.elasticsearch_server_port = elasticsearch_server_port

    # Fully qualified file name with path
    def set_input_file(self, input_file):
        self.input_file = input_file

    def set_input_caslib(self, input_caslib):
        self.input_caslib = input_caslib

    def set_input_import_options(self, input_import_options):
        self.input_import_options = input_import_options

    # File name with extension
    def set_input_file_name(self, input_file_name):
        self.input_file_name = input_file_name

    def set_input_file_rel_path(self, input_file_rel_path):
        self.input_file_rel_path = input_file_rel_path

    def set_index_vars(self, index_vars):
        self.index_vars = index_vars

    def set_ae_caslib(self, ae_caslib):
        self.ae_caslib = ae_caslib

    def set_ev_caslib(self, ev_caslib):
        self.ev_caslib = ev_caslib

    def set_ed_caslib(self, ed_caslib):
        self.ed_caslib = ed_caslib

    def set_hist_caslib(self, hist_caslib):
        self.hist_caslib = hist_caslib

    def set_models_caslib(self, models_caslib):
        self.models_caslib = models_caslib

    def set_train_caslib(self, train_caslib):
        self.train_caslib = train_caslib

    def set_lookups_caslib(self, lookups_caslib):
        self.lookups_caslib = lookups_caslib

    def set_se_caslib(self, se_caslib):
        self.se_caslib = se_caslib

    def set_conn(self, conn):
        self.conn = conn

    def set_enabled(self, enabled):
        self.enabled = enabled

    def set_intable(self, intable):
        self.intable = intable

    def set_work_caslib(self, work_caslib):
        self.work_caslib = work_caslib

    def set_groupby(self, groupby):
        self.groupby = groupby

    def set_where(self, where):
        self.where = where

    def set_inputs(self, inputs):
        self.inputs = inputs

    def set_promote(self, promote):
        self.promote = promote

    def set_filter(self, filter):
        self.filter = filter

    def set_filters(self, filters):
        self.filters = filters

    def set_threshold(self, threshold):
        self.threshold = threshold

    def set_event_type_id(self, event_type_id):
        self.event_type_id = event_type_id

    def set_investigative_event(self, investigative_event):
        self.investigative_event = investigative_event

    def set_comparison_fields(self, comparison_fields):
        self.comparison_fields = comparison_fields

    def set_filtered_input_table(self, filtered_input_table):
        self.filtered_input_table = filtered_input_table

    def set_preprocessed_table(self, preprocessed_table):
        self.preprocessed_table = preprocessed_table

    def set_cleanup(self, cleanup):
        self.cleanup = cleanup

    def set_analytic_field_name(self, analytic_field_name):
        self.analytic_field_name = analytic_field_name

    def set_src_id_fields(self, src_id_fields):
        self.src_id_fields = src_id_fields

    def set_dst_id_fields(self, dst_id_fields):
        self.dst_id_fields = dst_id_fields

    def select_input_table(self):
        if self.preprocessed_table is not None:
            return self.preprocessed_table
        else:
            if self.filtered_input_table is not None:
                return self.filtered_input_table
            else:
                return self.intable

    def resolve_filter(self, filter):

        self.log.debug(F"Resolving filter: {filter}")
        output = self.filters[filter]['output'].format(intable=self.intable)
        finput = self.filters[filter]['input'].format(intable=self.intable)
        clause = self.filters[filter]['clause']

        if not table_exists(self.conn, output):
            if not table_exists(self.conn, finput):

                if finput == self.intable:
                    table_loaded = load_table(self.conn, self.intable, self.input_file_rel_path, self.input_caslib,
                                              import_options=self.input_import_options, index_vars=self.index_vars)

                    if not table_loaded:
                        raise Exception(
                            F"Input table {self.input_file} not found.")
                    self.log.debug(F"Input table {self.intable} loaded.")

                else:
                    ifilter = self.find_filter(finput)
                    self.resolve_filter(ifilter)

            where = clause.format(table="", not_missing="Is Not Missing")

            casout = {"name": output, "promote": True}
            if self.index_vars is not None:
                casout["indexvars"] = self.index_vars

            self.conn.table.partition(
                table={"name": finput, "where": where}, casout=casout)

        self.log.debug(F"Completed resolving filter: {filter}")

    def find_filter(self, output):
        for key, item in self.filters.items():
            output = output.replace(self.intable, "{intable}")
            if (item['output'] == output):
                return key
        return None

    def init_analytic(self):

        # Connect to cas
        args = {"session_name": F"{self.job_execution_id}:{self.task_name}"}

        if self.cas_authinfo is not None:
            args["cas_authinfo"] = self.cas_authinfo
        if self.cas_protocol is not None:
            args["cas_protocol"] = self.cas_protocol
        if self.swat_trace is not None:
            args["swat_trace"] = (self.swat_trace.upper() == "TRUE")
        if self.swat_messages is not None:
            args["swat_messages"] = (self.swat_messages.upper() == "TRUE")

        self.conn = connect_to_cas(
            self.log, self.cas_host, self.cas_port, **args)

        # Set work caslib
        if self.conn is not None:
            # Set work caslib
            work_caslib = F"work_{self.job_execution_id}"
            self.set_work_caslib(work_caslib)

            # Create work_caslib if not present
            concurrency = Concurrency(self.log, work_caslib)
            concurrency.obtain_lock()

            if caslib_exists(self.conn, work_caslib):
                # Set default working caslib
                self.conn.setsessopt(caslib=work_caslib)
            else:
                # Create caslib
                self.conn.addcaslib(path=F"/tmp/{work_caslib}", caslib=work_caslib, subdirs=False,
                                    session=False, activeonadd=True)

            concurrency.release_lock()
            self.log.debug(F"Setting {work_caslib} as the work caslib")

        # Create filtered table if filter is set otherwise load input table
        if self.conn is not None and self.input_file is not None:
            # Get file name and table name
            tokens = self.input_file.split("/")
            file_name = tokens[-1]
            table_name = file_name.split(".")[0]

            # Set input file name
            self.set_input_file_name(file_name)

            # Set table name to process
            self.set_intable(table_name)

            # Set relative path
            self.set_input_file_rel_path(get_relative_path(
                self.conn, self.input_file, self.input_caslib))

            # If filter is set, create filtered table
            if self.filter is not None:
                self.resolve_filter(self.filter)
                # Set filtered input table name
                self.set_filtered_input_table(
                    self.filters[self.filter]['output'].format(intable=self.intable))
            else:
                table_loaded = load_table(self.conn, self.intable, self.input_file_rel_path, self.input_caslib,
                                          import_options=self.input_import_options, index_vars=self.index_vars)

                if not table_loaded:
                    raise Exception(
                        F"Input table {self.input_file} not found.")

                self.log.debug(F"Input table {self.intable} loaded.")

    @timeExecution
    def init_and_run_analytic(self):

        self.log = logging.getLogger(
            F"sascyber.{self.job_execution_id}:{self.task_name}:{self.__class__.__name__}")

        if not self.enabled:
            self.log.debug("Not running the analytic since it is not enabled")
            return

        try:
            # Initialize analytic
            self.init_analytic()

            # If filtered input table is empty, just return
            if (self.conn is not None) and (self.filter is not None) and \
                    row_count(self.conn, self.filtered_input_table) == 0:
                self.log.debug(
                    F"The filtered input table {self.filtered_input_table} is empty. No data to run the analytic.")
                return

            # If conn is None and conn is needed for analytic to run, then return
            if self.conn is None and self.conn_mandatory == True:
                return

            # Run analytic
            self.log.debug("Running analytic")
            self.runAnalytic()
            self.log.debug("Completed analytic run")

            # Close cas connection and cleanup tables
            self.finish()

        except SWATCASActionError as e:
            self.log.exception("Analytic failed to run")
            self.log.error(e.message)
            self.log.error(e.response)
            self.finish()

        except Exception as e:
            self.log.exception(F"Analytic failed to run: {e}")
            self.finish()

    def finish(self):

        # Cleanup tables
        if self.conn is not None and self.cleanup:
            self.cleanup_tables()

        # Close cas connection
        try:
            if self.conn is not None:
                self.conn.session.endsession()
                self.conn.close()
                self.log.debug("Successfully closed CAS connection")
        except Exception as err:
            self.log.exception("Cannot close the connection: {0}".format(err))

    def run_operation(self, operation, input_field, groupby, input_table, output_table):

        if table_exists(self.conn, output_table):
            return

        if operation.upper() == 'DISTINCT':
            out = self.conn.distinct(table={"name": input_table, "groupby": groupby},
                                     inputs=input_field,
                                     casout={"name": output_table, "promote": True})

        elif operation.upper() == 'SUMMARY':
            out = self.conn.summary(table={"name": input_table, "groupby": groupby},
                                    inputs=input_field,
                                    casout={"name": output_table, "promote": True})

        else:
            raise Exception("Unknown operation")

    def summarize_analytic_by_cmp_fields(self, analytic_table, analytic_field, analytic_by_cmp_fields_table):

        if table_exists(self.conn, analytic_by_cmp_fields_table):
            return

        out = self.conn.summary(table={"name": analytic_table,
                                       "groupby": self.comparison_fields},
                                inputs=analytic_field,
                                casout={"name": analytic_by_cmp_fields_table,
                                        "promote": True})

    def combine_analytic_raw_and_by_cmp_fields(self, analytic_table, analytic_by_cmp_fields_table,
                                               analytic_raw_and_by_cmp_fields_table):

        if table_exists(self.conn, analytic_raw_and_by_cmp_fields_table):
            return

        self.conn.loadactionset("fedsql")

        query = F"CREATE TABLE {analytic_raw_and_by_cmp_fields_table} AS "

        tables = [F"{analytic_table} as s",
                  F"{analytic_by_cmp_fields_table} as c"]

        fields = ['s.* ',
                  'c._Min_ as "cmpMin"',
                  'c._Mean_ as "cmpMean"',
                  'c._Max_ as "cmpMax"',
                  'c._Nobs_ as "cmpCount"']

        query += " SELECT " + ", ".join(fields)
        query += " FROM " + ", ".join(tables)

        where_clauses = list(
            map(lambda x: "s." + x + " = " + "c." + x, self.comparison_fields))

        if len(where_clauses) > 0:
            query += " WHERE " + " AND ".join(where_clauses)

        self.log.debug("Combine by_src and by_cmp tables:" +
                       " ".join(query.split()))

        out = self.conn.fedsql.execdirect(query)
        self.conn.promote(name=analytic_raw_and_by_cmp_fields_table)

    def standardize_analytic(self, input_table, analytic_field, deviation_table):

        if table_exists(self.conn, deviation_table):
            return

        copy_vars = self.src_id_fields + self.comparison_fields + [analytic_field] + \
            ['cmpMin', 'cmpMean', 'cmpMax', 'cmpCount']

        groupby = self.comparison_fields

        std_success = True

        try:
            self.conn.datapreprocess.transform(table={"name": input_table, "groupby": groupby}, copyvars=copy_vars,
                                               requestpackages=[{"inputs": analytic_field,
                                                                 "function": {"method": "standardize",
                                                                              "arguments":
                                                                                  {
                                                                                      "location": "median",
                                                                                      "scale": "iqr"
                                                                                  }
                                                                              }
                                                                 }],
                                               casout={"name": deviation_table, "promote": True})
            self.log.debug("Standardization complete.")

        except SWATCASActionError as e:
            self.log.debug(F"Standardization failed: {e}")

            # Create deviation table with all deviations set to 0
            copy_vars_str = " ".join(copy_vars + groupby)
            code = F'''
                data {deviation_table};
                    retain copy_vars_str;
                    set {input_table};
                    _TR1_{analytic_field} = 0;
            '''
            self.conn.datastep.runcode(code)
            self.conn.promote(deviation_table)

    def cleanup_tables(self):
        out = self.conn.tableinfo()
        if 'TableInfo' in out:
            all_table_df = out['TableInfo']
            delete_table_df = all_table_df[all_table_df['Name'].str.contains(
                '_' + str(self.event_type_id) + '_')]
            delete_table_df = delete_table_df[~delete_table_df['Name'].str.contains(
                "_ALL_EVT")]
            delete_table_ser = delete_table_df['Name']
            delete_table_ser.apply(lambda x: self.conn.droptable(x))
            self.log.debug(
                "Deleted all tables whose name contains event type id except events table.")

    def output_file_rel_path(self, event_type_id=None):

        input_rel_path = self.input_file_rel_path.replace(
            "/" + self.input_file_name, '')

        tokens = self.input_file.split("/")
        file_name = tokens[-1]
        file_extension = file_name.split(".")[1]

        if event_type_id is None:
            output_file_rel_path = \
                F"{self.input_caslib}/{input_rel_path}/{self.event_type_id}/{self.intable}.{file_extension}"
        else:
            output_file_rel_path = \
                F"{self.input_caslib}/{input_rel_path}/{event_type_id}/{self.intable}.{file_extension}"

        return output_file_rel_path

    def concat_events_to_history(self, table, event_file):

        time_fields = ['eventStartTime', 'startTime', 'timeId']
        userid_fields = ["src_ip_userId", "userId", "uc_userId"]

        alias_fields = ["predicted_label", "threatName"]
        type_fields = ["threatCategory", "type"]
        subtype_fields = ["threatCategoryType", "subtype"]

        hostname_fields = ["srcHostname", "src_dn_hostname"]

        fields_map = {"time": time_fields, "userid": userid_fields, "alias": alias_fields,
                      "type": type_fields, "subtype": subtype_fields, "hostname": hostname_fields}

        fields_of_interest = []
        for a_list in fields_map.values():
            fields_of_interest += a_list

        fields_of_interest += ['srcIpAddress',
                               'eventTypeId', 'eventId', 'score', 'anomalousFlag']

        fields_to_select = get_available_fields(
            self.conn, fields_of_interest, table)

        avail_fields_map = {}

        for key, fields in fields_map.items():
            # Find fields in fields_to_select
            avail_fields = [
                field for field in fields if field in fields_to_select]

            avail_fields_map[key] = avail_fields

            # Remove avail fields from fields_to_select since they need renaming
            [fields_to_select.remove(field) for field in avail_fields]

        field_name_map = {"time": "eventTime", "userid": "userId", "alias": "se_alias",
                          "type": "se_type", "subtype": "se_subtype", "hostname": "hostname"}

        fields_to_select_str = ", ".join(fields_to_select)

        for key, field_name in field_name_map.items():
            avail_fields = avail_fields_map.get(key)
            if len(avail_fields) > 0:
                fields_to_select_str += f', {avail_fields[0]} as "{field_name}"'
            else:
                fields_to_select_str += f''', '' as "{field_name}"'''

        es_sent_time = round(time.time() * 1000 * 1000)

        fields_to_select_str += f''', '{event_file}' as "event_file", {es_sent_time} as "es_sent_time" '''

        where_clause = f" where srcIpAddress != '' "

        if not self.investigative_event:
            where_clause += " and anomalousFlag = 1"

        self.conn.loadactionset("fedsql")

        df = self.conn.fedsql.execdirect(
            f"select {fields_to_select_str} from {table} {where_clause}")["Result Set"]

        queuing_server_config = {"queuing_server_host": self.queuing_server_host,
                                 "queuing_server_port": self.queuing_server_port,
                                 "queuing_server_user": self.queuing_server_user,
                                 "queuing_server_password": self.queuing_server_password}

        es_server_config = {"elasticsearch_server_host": self.elasticsearch_server_host,
                            "elasticsearch_server_port": self.elasticsearch_server_port}

        index = {"name": "all_analytic_events",
                 "type": "all_analytic_events_record"}

#        send_to_rabbitmq(self.log, queuing_server_config, es_server_config, df.to_dict(orient="records"),
#                         index, id_name="eventId")

    def write_ed_files(self, ev_detail_table):

        def write_ed_file(df, outdir):
            event_id = df["eventId"].values[0]
            outfile = F"{outdir}/{event_id}.h5"
            df.to_hdf(path_or_buf=outfile, key="ED")

        ed_base_path = self.conn.caslibinfo(caslib=self.ed_caslib)[
            'CASLibInfo']['Path'][0][:-1]
        input_rel_path = self.input_file_rel_path.replace(
            "/" + self.input_file_name, '')

        # Create out dir
        outdir = F"{ed_base_path}/{self.input_caslib}/{input_rel_path}/{self.event_type_id}"

        if not os.path.exists(outdir):
            os.makedirs(outdir)

        self.log.debug("Fetching evidence details table")
        evidence_df = self.conn.CASTable(ev_detail_table).to_frame()

        self.log.debug("Writing evidence details files")
        evidence_df.groupby("eventId").apply(write_ed_file, outdir)

        self.log.debug("Completed writing evidence files")

    # Abstract method that analytic needs to implement
    def runAnalytic(self):
        raise NotImplementedError()
