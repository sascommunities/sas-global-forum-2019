import logging

from sascyber.servers.server import Server
from sascyber.utils.classes import list_analytics
from sascyber.utils.classes import load_analytics
from sascyber.utils.decorators import timeExecution


class DAGServer(Server):
    """
    Server class loads and starts the analytics.
    """

    @timeExecution
    def __init__(self, config):
        '''
        initialization function for our server class.
        we insure that the config file contains the keys and non-empty values prior to
        instantiating this class.
        thus there will be less error-checking here for the time being.

        DTH :: 2017-12-04
        '''

        super().__init__()

        self.config = config

        self.log = logging.getLogger(F"sascyber.{self.config.CYBER_JOBEXEC}:{self.config.CYBER_TASK}:{self.__class__.__name__}")

        analytics_list = config.get_analytics_list()

        analytics_names = [analytic_name for index in range(len(analytics_list))
                           for analytic_name in analytics_list[index].keys()
                           if 'enabled' not in analytics_list[index][analytic_name] or
                           analytics_list[index][analytic_name]['enabled']]

        if self.config.custom_analytics_allowed:
            # DTH - note that for now a DAG can run either custom analytics or builtins - NOT both.
            # Thus we're always going to want the analytics type to be none here.
            self.analytics_path = []
            self.analytics_path.append(self.config.custom_analytics_path)
            self.analytics_type = None
            tmp_analytics = load_analytics(self.log, analytics_names, self.analytics_type, self.analytics_path)
        else:
            self.analytics_path = []
            self.analytics_type = self.config.analytics_type
            tmp_analytics = load_analytics(self.log, analytics_names, self.analytics_type)

        for name in analytics_names:
            cls_name = str.split(name, '.')[-1]
            for item in analytics_list:
                if name in item:
                    item[name]['class'] = tmp_analytics.get(cls_name)

        self.analytics = analytics_list

        self.log.debug("server initialized")

    def run(self):
        # self.status()

        for item in self.analytics:
            this_analytic = list(item.keys())[0]
            class_ = item[this_analytic]['class']()

            for key in item[this_analytic].keys():
                if not key == 'class':
                    method_name = F"set_{key}"
                    if hasattr(class_, method_name):
                        getattr(class_, method_name)(item[this_analytic][key])

            # Set all of the below keys always
            default_keys = ["filters", "ae_caslib", "ev_caslib", "ed_caslib", "hist_caslib", "models_caslib",
                            "train_caslib", "lookups_caslib", "se_caslib", "cas_host", "cas_port", "cas_authinfo",
                            "cas_protocol", "swat_trace", "swat_messages",  "queuing_server_host",
                            "queuing_server_port", "queuing_server_user", "queuing_server_password",
                            "elasticsearch_server_host", "elasticsearch_server_port",
                            "resolution_server_host", "resolution_server_port", "resolution_server_ips_limit"]

            for key in default_keys:
                method_name = F"set_{key}"
                if hasattr(class_, method_name):
                    getattr(class_, method_name)(getattr(self.config, key))

            # Set job exec id and task name
            class_.set_job_execution_id(self.config.CYBER_JOBEXEC)
            class_.set_task_name(self.config.CYBER_TASK)

            # Set job parameters
            job_parameters = self.config.get_job_parameters()

            if job_parameters is not None:
                for analytic_name, analytic_parms in job_parameters.items():
                    if analytic_name == this_analytic:
                        for parm_name, parm_value in analytic_parms.items():
                            # Check if set_{key} method exists on the class and if yes, set its value
                            method_name = F"set_{parm_name}"
                            if hasattr(class_, method_name):
                                getattr(class_, method_name)(parm_value)
                            else:
                                self.log.debug(F"{method_name} does not exist on {this_analytic}")

            # init and run the analytic
            try:
                class_.init_and_run_analytic()
            except Exception as err:
                self.log.exception("Analytic " + this_analytic +
                                   " failed to run: {0}".format(err))

        self.log.debug("server finished")

    def status(self):
        self.log.debug("custom analytics: %s" %
                       str(self.config.custom_analytics_allowed))
        self.log.debug("analytics path: %s" % self.analytics_path)
        self.log.debug("analytics classes: %s" %
                       list_analytics(self.analytics))
