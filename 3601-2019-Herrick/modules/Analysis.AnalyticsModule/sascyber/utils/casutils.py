import logging
import os
import stat
import time

import swat
from swat import SWATCASActionError

from sascyber.utils.concurrency import Concurrency

swat.options.cas.exception_on_severity = 2

logging.getLogger("urllib3").setLevel(logging.WARNING)


def connect_to_cas(log, cas_host, cas_port, cas_authinfo=".authinfo", cas_protocol="cas", swat_trace=False,
                   swat_messages=False, retry_count=3, session_name=None):
    # CAS connection
    conn = None

    # Set swat options
    swat.options.cas.trace_actions = swat_trace
    swat.options.cas.print_messages = swat_messages
    swat.options.interactive_mode = False

    # Try connecting to CAS
    for i in range(0, retry_count):
        try:

            conn = open_cas_connection(cas_host, cas_port, cas_authinfo, cas_protocol)

            conn.session.sessionname(name=session_name)

            log.debug(F"Successfully connected to CAS: host={cas_host}, port={cas_port}, \
                    authinfo={cas_authinfo}, protocol={cas_protocol}")

            break

        except SWATCASActionError as err:
            log.exception("Could not connect to CAS")
            log.debug(F"Could not connect to CAS: host={cas_host}, port={cas_port}, \
                    authinfo={cas_authinfo}, protocol={cas_protocol}")
            log.error(err.message)
            log.error(err.response)

            # Sleep for two seconds before retry
            time.sleep(2)

        except Exception as err:
            log.debug(F"Could not connect to CAS: host={cas_host}, port={cas_port}, \
                      authinfo={cas_authinfo}, protocol={cas_protocol}: {err}")

            # Sleep for two seconds before retry
            time.sleep(2)

    return conn


def open_cas_connection(host, port, authinfo=".authinfo", protocol="cas"):
    conn = swat.CAS(host, port, authinfo=authinfo, protocol=protocol)
    return conn


def table_exists(conn, table_name, caslib=None):
    if caslib is None:
        out = conn.tableexists(name=table_name)
    else:
        out = conn.tableexists(name=table_name, caslib=caslib)

    if out.get("exists"):
        return True
    else:
        return False


def caslib_exists(conn, caslib):
    caslibs = conn.caslibinfo()['CASLibInfo']['Name']

    return caslibs[caslibs == caslib].size


def get_available_fields(conn, fields_of_interest, table):
    # Fields in the input table
    fields_in_table = conn.columninfo(table)["ColumnInfo"]["Column"].tolist()
    fields_in_table = list(map(str.upper, fields_in_table))

    available_fields = []
    for field in fields_of_interest:
        if field.upper() in fields_in_table:
            available_fields.append(field)

    return available_fields


def table_promoted(conn, table_name, caslib=None):
    promoted = False

    table_info_out = None

    if caslib is not None:
        table_info_out = conn.tableinfo(caslib=caslib)
    else:
        table_info_out = conn.tableinfo()

    if len(table_info_out) > 0:
        table_info_df = table_info_out['TableInfo']
        table_info_df_sub = table_info_df[table_info_df.Name == table_name]
        promoted = (len(table_info_df_sub) > 0) and (table_info_df_sub.Global.values[0] == 1)

    return promoted


def row_count(conn, table_name, table_caslib=None):
    result = 0
    table_info_out = conn.table.tableinfo(caslib=table_caslib)

    if len(table_info_out) > 0:
        table_info_df = table_info_out["TableInfo"]
        table_info_df_sub = table_info_df[table_info_df.Name == table_name.upper()]
        if len(table_info_df_sub) > 0:
            result = table_info_df_sub['Rows'].iloc[0]

    return result


def get_relative_path(conn, full_path, caslib):
    caslib_path = conn.caslibinfo(caslib=caslib)['CASLibInfo']['Path'][0]
    return full_path.replace(caslib_path, '')


def save_table(conn, table, rel_path, caslib, table_caslib=None, replace=False):
    # Save the table only if there are more than 0 rows
    if row_count(conn, table, table_caslib) == 0:
        return False

    # Create output directory if it does not exist
    caslib_path = get_caslib_path(conn, caslib)

    directory = caslib_path + "/".join(rel_path.split("/")[0:-1])

    if not os.path.exists(directory):
        os.makedirs(directory)

        # Make directory writable by owner and group, and readable by others
        os.chmod(directory, stat.S_IRWXU | stat.S_IRWXG | stat.S_IROTH | stat.S_IXOTH)

    table_dict = {"name": table}
    if table_caslib is not None:
        table_dict["caslib"] = table_caslib

    conn.table.save(table=table_dict, name=rel_path, caslib=caslib, replace=replace)

    return True


def load_table(conn, table, rel_path, caslib, out_caslib=None, promote=True, import_options=None, index_vars=None,
               where=None):
    if table_exists(conn, table, out_caslib):
        return True

    caslib_path = conn.caslibinfo(caslib=caslib)['CASLibInfo']['Path'][0]

    if os.path.exists(caslib_path + "/" + rel_path):

        casout = {"name": table}

        if out_caslib is not None:
            casout["caslib"] = out_caslib

        if index_vars is not None:
            casout["indexvars"] = index_vars

        conn.table.loadtable(path=rel_path, importoptions=import_options, caslib=caslib,
                             casout=casout, promote=promote, where=where)

        return True

    return False


def load_tables(conn, tables, rel_paths, caslib):
    result = []

    for table, rel_path in zip(tables, rel_paths):

        table_loaded = load_table(conn, table, rel_path, caslib)

        if table_loaded:
            result.append(table)

    return result


def get_caslib_path(conn, caslib):
    return conn.caslibinfo(caslib=caslib)['CASLibInfo']['Path'][0]


def get_eventid_formula(conn, table):
    cols = conn.table.columninfo(table)["ColumnInfo"]
    char_cols = cols[(cols.Type == 'varchar') | (cols.Type == 'char')].Column.tolist()
    numeric_cols = cols[(cols.Type != 'varchar') & (cols.Type != 'char')].Column.tolist()
    numeric_cols = [f"put({x}, 20.)" for x in numeric_cols]
    all_cols = char_cols + numeric_cols
    all_cols_str = ", ".join(all_cols)
    event_id_str = f"put(md5(cats({all_cols_str})), $hex32.)"
    return event_id_str


def append_table(log, conn, session_table, global_table, global_table_caslib):
    # Obtain a lock since global table is a shared resource
    concurrency = Concurrency(log, global_table)
    concurrency.obtain_lock()

    try:
        # Load global table loaded if not already loaded
        if table_exists(conn, global_table, global_table_caslib):
            target_loaded = True
        else:
            target_loaded = load_table(conn, global_table, F"{global_table}.sashdat", global_table_caslib,
                                       out_caslib=global_table_caslib)

        if target_loaded:
            # Append session_table to global table
            code = F'''
                data {global_table_caslib}.{global_table}_new;
                    set {global_table_caslib}.{global_table} {session_table};
            '''
            log.debug(F"{global_table}_new DS code:" + " ".join(code.split()))
            conn.datastep.runcode(code)

            # Delete old global table; promote new global table
            conn.droptable(name=global_table, caslib=global_table_caslib)

            conn.table.promote(name=f"{global_table}_new", caslib=global_table_caslib,
                               target=global_table, targetlib=global_table_caslib)

        else:
            # Promote session table as global table
            if session_scope(conn, session_table):
                conn.table.promote(name=session_table, target=global_table, targetlib=global_table_caslib)
            else:
                code = f'''
                    data {session_table}_local;
                        set {session_table};
                '''
                conn.datastep.runcode(code)

                conn.table.promote(name=f"{session_table}_local", target=global_table, targetlib=global_table_caslib)

        # Save target table
        save_table(conn, global_table, F"{global_table}.sashdat", global_table_caslib, table_caslib=global_table_caslib,
                   replace=True)
        log.debug(F"Saved {global_table} table")
    except Exception as e:
        log.exception(F"Unable to append {session_table} to {global_table}: {e}")

    # Release the lock
    concurrency.release_lock()


def session_scope(conn, table_name):
    result = False

    out = conn.table.tableinfo(name=table_name)

    if "TableInfo" in out:
        if out["TableInfo"]["Global"].at[0] == 0:
            result = True

    return result
