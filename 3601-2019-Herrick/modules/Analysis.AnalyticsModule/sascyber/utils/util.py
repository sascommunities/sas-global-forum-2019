import inspect
import os
import pipes
import subprocess
import sys

from sascyber.utils.exceptions import SASCyberMissingEnvVariable


def get_sascyber_version():
    try:
        from sascyber.version import __VERSION__
        return __VERSION__
    except ImportError:
        return "Unknown"


def set_sascyber_version_env():
    try:
        from sascyber.version import __VERSION__
        os.environ["CYBER_SASYBER_VERSION"] = __VERSION__
        return 0
    except ImportError:
        return 1


def confirm_environment_variables_set(var_list):
    for item in var_list:
        if item not in os.environ:
            raise SASCyberMissingEnvVariable(item)


def check_for_keys(key_list, config_dict):
    for key in key_list:
        if key not in config_dict:
            raise KeyError(key)


def load_modules_from_path(path):
    """
    Import all modules from the given directory
    """
    # Check and fix the path
    if path[-1:] != '/':
        path += '/'

    # Get a list of files in the directory, if the directory exists
    if not os.path.exists(path):
        raise OSError("Directory does not exist: %s" % path)

    # Add path to the system path
    sys.path.append(path)
    # Load all the files in path
    for f in os.listdir(path):
        # Ignore anything that isn't a .py file
        if len(f) > 3 and f[-3:] == '.py':
            modname = f[:-3]
            # Import the module
            __import__(modname, globals(), locals(), ['*'])


def load_class_from_name(log, fqcn):
    # Break apart fqcn to get module and classname
    paths = fqcn.split('.')
    modulename = '.'.join(paths[:-1])
    classname = paths[-1]

    #log.info("Paths: %s" % paths)
    #log.info("Module Name: %s" % modulename)
    #log.info("Class Name: %s" % classname)

    # Import the module
    __import__(modulename, globals(), locals(), ['*'])
    # Get the class
    cls = getattr(sys.modules[modulename], classname)
    # Check cls
    if not inspect.isclass(cls):
        raise TypeError("%s is not a class" % fqcn)
    # Return class
    return cls


def exists_remote(host, path):
    """Test if a file exists at path on a host accessible with SSH."""
    status = subprocess.call(
        ['ssh', host, 'test -f {}'.format(pipes.quote(path))])
    if status == 0:
        return True
    if status == 1:
        return False
    raise Exception('SSH failed')


def dir_exists_remote(host, dir):
    """Test if a file exists at path on a host accessible with SSH."""
    status = subprocess.call(
        ['ssh', host, 'test -d {}'.format(pipes.quote(dir))])
    if status == 0:
        return True
    if status == 1:
        return False
    raise Exception('SSH failed')
