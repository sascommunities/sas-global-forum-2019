import logging
import sys
import os
from pathlib import Path

from logging.config import dictConfig
from logging.handlers import TimedRotatingFileHandler


def setup_logging(configfile):

    # set up the logging path if it doesn't already exist
    log_path = Path(configfile.CYBER_ROOT).joinpath('log')
    if not log_path.exists():
        log_path.mkdir()

    try:
        if configfile.CYBER_DEFAULT_LOGGING:
            log = logging.getLogger('sascyber')
            log_timer = logging.getLogger('timing')

            log.setLevel(logging.DEBUG)

            log_file_full = log_path / 'sascyber.log'
            log_file_fqp = log_file_full.as_posix()

            fh = TimedRotatingFileHandler(log_file_fqp,
                                          when="d",
                                          interval=1,
                                          backupCount=7)
            fh.setLevel(logging.DEBUG)
            formatter = logging.Formatter(
                '%(asctime)s:\t%(process)d:\t%(filename)s:\t%(levelname)s:\t%(funcName)s:\t%(message)s',
                '%Y-%m-%d :: %H:%M:%S')
            fh.setFormatter(formatter)
            log.addHandler(fh)
            log.debug('first debug message from default')

            log_timer.setLevel(logging.INFO)
            log_timer_full = log_path / 'sascyber_timing.log'
            log_timer_fqp = log_timer_full.as_posix()

            fh2 = TimedRotatingFileHandler(log_timer_fqp,
                                           when="d",
                                           interval=1,
                                           backupCount=7)
            fh2.setLevel(logging.INFO)
            time_formatter = logging.Formatter(
                '%(asctime)s:\t%(process)d:\t%(filename)s:\t%(levelname)s:\t%(funcName)s:\t%(message)s',
                '%Y-%m-%d :: %H:%M:%S')
            fh2.setFormatter(time_formatter)
            log_timer.addHandler(fh2)
        else:
            dictConfig(configfile.loginfo)
            log = logging.getLogger('sascyber')
            log_timer = logging.getLogger('timing')

    except ImportError as ie:
        sys.stderr.write("importError: ")
        sys.stderr.write(str(ie))
        sys.stderr.write(os.linesep)

    except ValueError as ie:
        sys.stderr.write("valueError: ")
        sys.stderr.write(str(ie))
        sys.stderr.write(os.linesep)

    except TypeError as ie:
        sys.stderr.write("TypeError: ")
        sys.stderr.write(str(ie))
        sys.stderr.write(os.linesep)

    except AttributeError as ie:
        sys.stderr.write("AttributeError: ")
        sys.stderr.write(str(ie))
        sys.stderr.write(os.linesep)

    except Exception as e:
        sys.stderr.write("Error on logging initialization: ")
        sys.stderr.write(str(e))
        sys.stderr.write(os.linesep)

    return log
