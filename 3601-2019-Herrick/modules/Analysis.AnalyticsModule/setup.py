#!/usr/local/bin/python3.6
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

''' Install the SAS Cyber Analytics module '''

from setuptools import setup, find_packages
from sascyber.utils.util import get_sascyber_version

setup(
    zip_safe=False,
    name='sascyber',
    version=get_sascyber_version(),
    description='SAS Cyber Analytics Module',
    long_description='a longer description',
    author='SAS',
    author_email='damian.herrick@sas.com',
    url='localhost',
    license='LICENSE',
    packages=find_packages(),
    install_requires=[
        'swat >= 1.3.0',
        'scipy >= 1.1.0',
        'tldextract >= 2.2.0',
    ],
    classifiers=[
        'Development Status :: 0 - Alpha',
        'Environment :: Console',
        'Intended Audience :: Science/Research',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Topic :: Scientific/Engineering',
    ],
)
