import os
import json

cyber_keys = ['analytics_path', 'custom_analytics_allowed', 'custom_analytics_path',
              'analyticsList', 'cas_port', 'cas_host', 'cas_authinfo']


class BaseConfig(object):
    # todo:
    # 3. set error checking if environment or config not available.

    def __init__(self, config_file, log_config_file, cyber_root):
        self.config_file = config_file
        self.log_config_file = log_config_file
        self.cyber_root = cyber_root
        self.load_config_json()
        self.load_log_json()
        self._prop = None

    def load_config_json(self):
        with open(self.config_file) as json_file:
            self._config = json.load(json_file)

    def load_log_json(self):
        with open(self.log_config_file) as json_file:
            self._log_config = json.load(json_file)

    def get_property(self, cfg, property_name):
        if property_name in cfg.keys():
            self._prop = cfg[property_name]
        else:
            for key in cfg.keys():
                val = cfg[key]
                if isinstance(val, dict):
                    self.get_property(val, property_name)
        return self._prop

    @property
    def analytics_type(self):
        self._prop = None
        return self.get_property(self._config, 'analytics_type')

    @property
    def analytics_path(self):
        self._prop = None
        a_path = self.get_property(self._config, 'analytics_path')
        if a_path is not None:
            if a_path.startswith('../'):
                a_path = a_path[len('../'):]
            if a_path.startswith('./'):
                a_path = a_path[len('./'):]
            a_path = os.path.join(self.cyber_root, a_path)
            self._prop = a_path
        return self._prop

    @property
    def custom_analytics_allowed(self):
        self._prop = None
        return self.get_property(self._config, 'custom_analytics_allowed')

    @property
    def custom_analytics_path(self):
        self._prop = None
        a_path = self.get_property(self._config, 'custom_analytics_path')
        if a_path is not None:
            if a_path.startswith('../'):
                a_path = a_path[len('../'):]
            if a_path.startswith('./'):
                a_path = a_path[len('./'):]
            a_path = os.path.join(self.cyber_root, a_path)
            self._prop = a_path
        return self._prop

    @property
    def analyticsList(self):
        self._prop = None
        return self.get_property(self._config, 'analyticsList')

    @property
    def cas_host(self):
        self._prop = None
        return self.get_property(self._config, 'cas_host')

    @property
    def cas_port(self):
        self._prop = None
        return self.get_property(self._config, 'cas_port')

    @property
    def cas_authinfo(self):
        self._prop = None
        a_path = self.get_property(self._config, 'cas_authinfo')
        if a_path is not None:
            self._prop = os.path.join(os.environ["HOME"], a_path)
        return self._prop

    @property
    def filters(self):
        self._prop = None
        return self.get_property(self._config, 'filters')

    @property
    def loginfo(self):
        return self._log_config


if __name__ == '__main__':
    config_file = "/home/cyber/server/Analysis.AnalyticsConfig/test/nf.ExtDstPortPoints.json"
    log_config_file = "/home/cyber/server/Analysis.AnalyticsConfig/log/logformat.json"
    cyber_root = "/home/cyber/server/Analysis.AnalyticsModule"
    cfg = BaseConfig(config_file, log_config_file, cyber_root)

    print(f"analytics_path: {cfg.analytics_path}")
    print(f"analytics_type: {cfg.analytics_type}")
    print(f"custom_analytics_allowed: {cfg.custom_analytics_allowed}")
    print(f"custom_analytics_path: {cfg.custom_analytics_path}")
    print(f"analyticsList: {cfg.analyticsList}")
    print(f"cas_host: {cfg.cas_host}")
    print(f"cas_port: {cfg.cas_port}")
    print(f"cas_authinfo: {cfg.cas_authinfo}")
    print(f"filters: {cfg.filters}")
    print(f"loginfo: {cfg.loginfo}")
