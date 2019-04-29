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
decorators.py

A utility module that contains any custom decorators we want to use in the sascyber module.

DTH :: 2017-12-12
'''

import time
import logging
from functools import wraps

logger = logging.getLogger('timing')


def timeExecution(method):
    @wraps(method)
    def timed(*args, **kwargs):
        ts = time.time()
        result = method(*args, **kwargs)
        te = time.time()

        # brief note on choice of __qualname__. This allows us to see the class AND method / function
        # being timed.
        # DTH :: 2017-12-14
        logger.info('%s.%s :: %2.2f sec' %
                    (args[0].__class__.__qualname__, method.__name__,  (te - ts)))

        return result
    return timed
