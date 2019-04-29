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

A base class to manage various configuration settings used in sascyber.


Parameters
----------
Configuration JSON: taken as an initialization parameter in the class.

Keys Needed in the configuration JSON:
analytics_type : One of {nf, wp, au, epp, dns, dhcp, fw}
custom_analytics_allowed
custom_analytics_path
analyticsList
cas_port
cas_host
cas_authinfo : location of the authinfo file on the system.
cas_protocol : One of {'cas', 'http'} where 'cas' is the binary CAS protocol, and `http` is the REST protocol.


Returns
-------
a single Config object
'''

import json
import os
from pathlib import Path

from sascyber.utils.exceptions import SASCyberMissingConfig

cyber_keys = ['analytics_type', 'analytics_config', 'custom_analytics_allowed', 'custom_analytics_path',
              'analyticsList', 'cas_port', 'cas_host', 'cas_authinfo', 'cas_protocol',
              'swat_trace', 'swat_messages', 'ae_caslib', 'ev_caslib', 'ed_caslib', 'hist_caslib',
              'models_caslib', 'train_caslib', 'lookups_caslib', 'se_caslib', 'queuing_server_host',
              'queuing_server_port', 'queuing_server_user', 'queuing_server_password',
              'elasticsearch_server_host', 'elasticsearch_server_port',
              'resolution_server_host', 'resolution_server_port', 'resolution_server_ips_limit']


class BaseConfig(object):

    def __init__(self, inputfile, logfile):
        self._prop = None
        self.load_input_json(inputfile)
        self.load_log_json(logfile)
        self.load_config_json()

    def load_input_json(self, cfgfile):
        if os.path.isfile(cfgfile):
            with open(cfgfile) as json_file:
                self._input = json.load(json_file)
        else:
            raise SASCyberMissingConfig(cfgfile)

    def load_log_json(self, logfile):
        if os.path.isfile(logfile):
            with open(logfile) as json_file:
                self._log_config = json.load(json_file)
        else:
            raise SASCyberMissingConfig(logfile)

    def load_config_json(self):
        cfgfile = self.get_property(self._input, "analytics_config")
        if os.path.isfile(cfgfile):
            with open(cfgfile) as json_file:
                self._config = json.load(json_file)
        else:
            raise SASCyberMissingConfig(cfgfile)

    def absolute_path(self, inpath):
        pth = Path(inpath)
        if pth.parts[0] == '..':
            outpath = pth.resolve().as_posix()
        elif pth.parts[0] == '~':
            outpath = pth.expanduser().as_posix()
        else:
            outpath = pth.as_posix()
        return outpath

    def expand_directories(self, key, var, basepath):
        if hasattr(var, 'items'):
            for k, v in var.items():
                if k == key:
                    var[k] = Path(basepath).joinpath(v).as_posix()
                    yield v
                if isinstance(v, dict):
                    for result in self.expand_directories(key, v, basepath):
                        yield result

    def get_property(self, cfg, property_name):
        if property_name in cfg.keys():
            self._prop = cfg[property_name]
        else:
            for key in cfg.keys():
                val = cfg[key]
                if isinstance(val, dict):
                    self.get_property(val, property_name)
        return self._prop

    def get_input_property(self, property_name):
        self._prop = None
        return self.get_property(self._input, property_name)

    def get_config_property(self, property_name):
        self._prop = None
        return self.get_property(self._config, property_name)

    # Runtime properties read from input
    @property
    def cas_host(self):
        self._prop = None
        return self.get_property(self._input, 'cas_host')

    @property
    def cas_port(self):
        self._prop = None
        return self.get_property(self._input, 'cas_port')

    @property
    def cas_protocol(self):
        self._prop = None
        return self.get_property(self._input, 'cas_protocol')

    @property
    def cas_authinfo(self):
        self._prop = None
        a_path = Path(self.get_property(
            self._input, 'cas_authinfo')).expanduser()
        try:
            self._prop = a_path.resolve(strict=True)
        except FileNotFoundError:
            self._prop = None
        return self._prop

    @property
    def queuing_server_host(self):
        self._prop = None
        return self.get_property(self._input, 'queuing_server_host')

    @property
    def queuing_server_port(self):
        self._prop = None
        return self.get_property(self._input, 'queuing_server_port')

    @property
    def queuing_server_user(self):
        self._prop = None
        return self.get_property(self._input, 'queuing_server_user')

    @property
    def queuing_server_password(self):
        self._prop = None
        return self.get_property(self._input, 'queuing_server_password')

    @property
    def resolution_server_host(self):
        self._prop = None
        return self.get_property(self._input, 'resolution_server_host')

    @property
    def resolution_server_port(self):
        self._prop = None
        return self.get_property(self._input, 'resolution_server_port')

    @property
    def elasticsearch_server_host(self):
        self._prop = None
        return self.get_property(self._input, 'elasticsearch_server_host')

    @property
    def elasticsearch_server_port(self):
        self._prop = None
        return self.get_property(self._input, 'elasticsearch_server_port')

    # Config properties read from analytics_config
    @property
    def resolution_server_ips_limit(self):
        self._prop = None
        return self.get_property(self._config, 'resolution_server_ips_limit')

    @property
    def analytics_type(self):
        self._prop = None
        return self.get_property(self._config, 'analytics_type')

    @property
    def custom_analytics_allowed(self):
        self._prop = None
        return self.get_property(self._config, 'custom_analytics_allowed')

    @property
    def custom_analytics_path(self):
        self._prop = None
        a_path = Path(self.get_property(self._config, 'custom_analytics_path'))
        try:
            self._prop = a_path.resolve(strict=True)
        except FileNotFoundError:
            self._prop = f'CUSTOM ANALYTICS PATH DOES NOT EXIST: {a_path}'
        return self._prop

    @property
    def filters(self):
        self._prop = None
        return self.get_property(self._config, 'filters')

    @property
    def swat_trace(self):
        self._prop = None
        return self.get_property(self._config, 'swat_trace')

    @property
    def swat_messages(self):
        self._prop = None
        return self.get_property(self._config, 'swat_messages')

    @property
    def ae_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'ae_caslib')

    @property
    def ev_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'ev_caslib')

    @property
    def ed_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'ed_caslib')

    @property
    def hist_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'hist_caslib')

    @property
    def models_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'models_caslib')

    @property
    def train_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'train_caslib')

    @property
    def lookups_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'lookups_caslib')

    @property
    def se_caslib(self):
        self._prop = None
        return self.get_property(self._config, 'se_caslib')

    @property
    def loginfo(self):
        return self._log_config

    @property
    def input_task(self):
        task = self._input["id"]
        if task is None:
            task = "Finalizer"
        return task

    @property
    def config_tasks(self):
        return self._config["tasks"]


if __name__ == '__main__':
    cfg = BaseConfig(os.environ["CYBER_ARGS"], os.environ["CYBER_LOG"])

    print(f"analytics_type: {cfg.analytics_type}")
    print(f"custom_analytics_allowed: {cfg.custom_analytics_allowed}")
    print(f"custom_analytics_path: {cfg.custom_analytics_path}")
    print(
        f"analyticsList: {json.dumps(cfg.analyticsList, indent=4, sort_keys=True)}")
    print(f"cas_host: {cfg.cas_host}")
    print(f"cas_port: {cfg.cas_port}")
    print(f"cas_protocol: {cfg.cas_protocol}")
    print(f"cas_authinfo: {cfg.cas_authinfo}")
    print(f"filters: {json.dumps(cfg.filters, indent=4, sort_keys=True)}")
    print(f"loginfo: {json.dumps(cfg.loginfo, indent=4, sort_keys=True)}")
