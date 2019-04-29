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
Config

A class to consolidate and manage the various configuration settings needed in sascyber.


Parameters
----------
Environment variables for sascyber:
CYBER_ARGS
CYBER_STATUS_FILE_DIRECTORY
CYBER_VENV
CYBER_JOBEXEC
CYBER_TASK
CYBER_ROOT
CYBER_DEV_STATUS

Configuration JSON: Enumerated in the CYBER_ARGS environment variable.
* Note, this isn't needed to pass into the configuration init since we'll just set it on init

Development Status: One of [DEBUG, RELEASE]; sourced from CYBER_DEV_STATUS

Keys Needed in the configuration JSON:
analytics_type : One of {nf, wp, au, epp, dns, dhcp, fw}
analytics_path : <DEPRECATED> <2018-01-31> : because we now include built-in analytics in the main directory path.
custom_analytics_allowed
custom_analytics_path
analyticsList
cas_port
cas_host
cas_authinfo


Returns
-------
a single Config object
'''

import os
import json
import re

from sascyber.configs.base import BaseConfig
from distutils.util import strtobool

from sascyber.utils.exceptions import SASCyberMissingConfig
from sascyber.utils.util import confirm_environment_variables_set

cyber_environ = ['CYBER_ARGS', 'CYBER_ROOT',
                 'CYBER_DEFAULT_LOGGING', 'CYBER_LOG']


class AnalyticsManagerConfig(BaseConfig):
    def __init__(self):
        confirm_environment_variables_set(cyber_environ)
        for item in cyber_environ:
            setattr(self, item, None)
            if item in os.environ:
                setattr(self, item, os.environ[item])

        # one issue - any boolean environment variable needs to be explicitly converted to a boolean
        self.CYBER_DEFAULT_LOGGING = bool(
            strtobool(self.CYBER_DEFAULT_LOGGING))

        # fix all the paths to absolute
        self.CYBER_ARGS = self.absolute_path(self.CYBER_ARGS)
        self.CYBER_ROOT = self.absolute_path(self.CYBER_ROOT)
        self.CYBER_LOG = self.absolute_path(self.CYBER_LOG)

        super().__init__(self.CYBER_ARGS, self.CYBER_LOG)

        for item in self.expand_directories('filename', self.loginfo, self.CYBER_ROOT):
            pass

    def get_analytics_list(self):
        task_name = self.input_task
        task_config = self.config_tasks[task_name]["options"]["analyticsList"]
        self.substitute_params(task_config)
        return task_config

    def substitute_params(self, task_config):
        for analytic in task_config:
            for name, config in analytic.items():
                for key, value in config.items():
                    if (type(value) == str) and ("$" in value):
                        m = re.match("\$\{(.*?)\}", value)
                        substitute_value = self.get_input_property(m.group(1))
                        if substitute_value is None:
                            substitute_value = self.get_config_property(
                                m.group(1))
                        config[key] = substitute_value

    def get_job_parameters(self):
        job_parameters = self._input.get('job_parameters')

        if job_parameters is not None:
            return job_parameters.get('myParms')
        else:
            return None

    def status(self):
        for item in cyber_environ:
            print(f"{item} (environment variable) :: {os.environ[item]}")
            print(f"{item} (config object)        :: {getattr(self, item)}")

        print(f"analytics_type: {self.analytics_type}")
        print(f"custom_analytics_allowed: {self.custom_analytics_allowed}")
        print(f"custom_analytics_path: {self.custom_analytics_path}")
        # print(f"analyticsList: {self.analyticsList}")
        # print(f"cas_host: {self.cas_host}")
        # print(f"cas_port: {self.cas_port}")
        # print(f"cas_protocol: {self.cas_protocol}")
        # print(f"cas_authinfo: {self.cas_authinfo}")
        print(f"filters: {json.dumps(self.filters, indent=4, sort_keys=True)}")
        print(f"loginfo: {json.dumps(self.loginfo, indent=4, sort_keys=True)}")


if __name__ == '__main__':
    cfg = AnalyticsManagerConfig()
    for item in cyber_environ:
        print(f"{item} (environment variable) :: {os.environ[item]}")
        print(f"{item} (config object)        :: {getattr(cfg, item)}")

    print(f"analytics_type: {cfg.analytics_type}")
    print(f"custom_analytics_allowed: {cfg.custom_analytics_allowed}")
    print(f"custom_analytics_path: {cfg.custom_analytics_path}")
    print(f"analyticsList: {cfg.analyticsList}")
    print(f"cas_host: {cfg.cas_host}")
    print(f"cas_port: {cfg.cas_port}")
    print(f"cas_protocol: {cfg.cas_protocol}")
    print(f"cas_authinfo: {cfg.cas_authinfo}")
    print(f"filters: {json.dumps(cfg.filters, indent=4, sort_keys=True)}")
    print(f"loginfo: {json.dumps(cfg.loginfo, indent=4, sort_keys=True)}")
