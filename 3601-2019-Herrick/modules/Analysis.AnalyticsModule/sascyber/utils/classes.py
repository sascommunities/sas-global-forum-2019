import os
import sys
import logging
import inspect
import traceback
import pkg_resources
import importlib
import importlib.util

from sascyber.utils.util import load_class_from_name
from sascyber.analytics.base.Analytic import Analytic

def load_include_path(paths):
    """
    Scan for and add paths to the include path
    """
    for path in paths:
        # Verify the path is valid
        if not os.path.isdir(path):
            continue
        # Add path to the system path, to avoid name clashes
        if path not in sys.path:
            sys.path.insert(1, path)
        # Load all the files in path
        for f in os.listdir(path):
            # Are we a directory? If so process down the tree
            fpath = os.path.join(path, f)
            if os.path.isdir(fpath):
                load_include_path([fpath])


def load_dynamic_class(log, fqn, subclass):
    """
    Dynamically load fqn class and verify it's a subclass of subclass
    """
    cls = load_class_from_name(log, fqn)

    if cls == subclass or not issubclass(cls, subclass):
        raise TypeError("%s is not a valid %s" % (fqn, subclass.__name__))

    return cls


def load_analytics(log, names, a_type=None, paths=None):
    """
    Load all analytics

    DTH :: 2018-01-31

    Change this to handle our built-in / shipped analytics, custom analytics, or both
    """

    #log.info("names: %s" % names)
    #log.info("paths: %s" % paths)

    analytics = load_analytics_from_module(log, names, a_type)

    if paths is not None and names is not None:
        analytics.update(load_analytics_from_paths(log, names, paths))

    return analytics


def load_analytics_from_module(log, names, a_type):
    """
    Load analytics that are specified in names, from the type a_type

    This function handles the load of all of the SAS-supplied prebuilt analytics.

    DTH :: 2018-01-31
    """

    analytics = {}

    if a_type is None:
        return analytics

    for a_name in names:
        mod_name = a_type + '.' + a_name
        cls_name = str.split(a_name, '.')[-1]
        try:
            mod_spec = importlib.util.find_spec(mod_name)
            if mod_spec is None:
                raise Exception
            else:
                mod = importlib.util.module_from_spec(mod_spec)
                mod_spec.loader.exec_module(mod)
                for name, cls in get_analytics_from_module(log, mod):
                    if cls_name == name:
                        analytics[name] = cls
        except Exception as e:
            log.error("Module spec not found: %s" % a_name)

    return analytics


def load_analytics_from_paths(log, names, paths):
    """
    Scan for analytics to load from path
    """
    # Initialize return value
    analytics = {}

    if not names:
        return

    if paths is None:
        return

    # load_include_path(paths)
    #log.info("Paths: %s" % paths)

    for path in paths:
        # Get a list of files in the directory, if the directory exists
        if not os.path.exists(path):
            raise OSError("Directory does not exist: %s" % path)

        # Load all the files in path
        for f in os.listdir(path):
            # first, make sure that we're not in one of the special paths where we don't want to be.
            #log.info("End name: %s" % f)
            if f in ['tests', 'fixtures', '__pycache__']:
                return analytics

            # Are we a directory? If so process down the tree
            fpath = os.path.join(path, f)
            #log.info("FPATH: %s" % fpath)
            if os.path.isdir(fpath):
                subanalytics = load_analytics_from_paths(log, [fpath], names)
                for key in subanalytics:
                    analytics[key] = subanalytics[key]

            # Ignore anything that isn't a .py file
            elif (os.path.isfile(fpath) and
                  len(f) > 3 and
                  f[-3:] == '.py' and
                  f[0:4] != 'test' and
                  f[0] != '.'):

                modname = f[:-3]
                #log.info("Path: %s" % path)
                #log.info("Module: %s" % modname)
                #log.info("fqcn: %s" % fpath)

                # add path to the system path
                sys.path.append(path.as_posix())

                try:
                    # Import the module

                    if (modname in names):
                        mod_spec = importlib.util.spec_from_file_location(
                            modname, fpath)
                        mod = importlib.util.module_from_spec(mod_spec)
                        mod_spec.loader.exec_module(mod)
                except (KeyboardInterrupt, SystemExit) as err:
                    log.error(
                        "System or keyboard interrupt "
                        "while loading module %s"
                        % modname)
                    if isinstance(err, SystemExit):
                        sys.exit(err.code)
                    raise KeyboardInterrupt
                except Exception:
                    # Log error
                    log.error("Failed to import module: %s. %s",
                                 modname,
                                 traceback.format_exc())
                else:
                    if modname in names:
                        for name, cls in get_analytics_from_module(log, mod):
                            log.info("Name: %s" % name)
                            log.info("Class: %s" % cls)
                            if name == modname:
                                analytics[name] = cls
    # Return Analytics classes
    return analytics


def load_analytics_from_entry_point(log, path):
    """
    Load analytics that were installed into an entry_point.
    """
    analytics = {}
    for ep in pkg_resources.iter_entry_points(path):
        try:
            mod = ep.load()
        except Exception:
            log.error('Failed to import entry_point: %s. %s',
                         ep.name,
                         traceback.format_exc())
        else:
            analytics.update(get_analytics_from_module(log, mod))
    return analytics


def get_analytics_from_module(log, mod):
    """
    Locate all of the analytics classes within a given module
    """
    for attrname in dir(mod):
        attr = getattr(mod, attrname)
        # Only attempt to load classes that are infact classes
        # are Analytics but are not the base Analytics class
        if ((inspect.isclass(attr) and
             issubclass(attr, Analytic) and
             attr != Analytic)):
            if attrname.startswith('parent_'):
                continue
            # Get class name
            fqcn = '.'.join([mod.__name__, attrname])
            #log.info("fqcn: %s" % fqcn)
            try:
                # Load Analytic class
                cls = load_dynamic_class(log, fqcn, Analytic)
                # Add Analytic class
                yield cls.__name__, cls
            except Exception:
                # Log error
                log.error(
                    "Failed to load Analytic: %s. %s",
                    fqcn, traceback.format_exc())
                continue


def initialize_analytic(log, cls, name=None):
    """
    Initialize analytic
    """
    analytic = None

    try:
        # Initialize analytic
        analytic = cls(name=name)
    except Exception:
        # Log error
        log.error("Failed to initialize analytic: %s. %s",
                     cls.__name__, traceback.format_exc())

    # Return analytic
    return analytic


def list_analytics(lst_analytics):
    analytics_list = []
    for item in lst_analytics:
        analytics_list.append(list(item.keys())[0])
    return analytics_list
