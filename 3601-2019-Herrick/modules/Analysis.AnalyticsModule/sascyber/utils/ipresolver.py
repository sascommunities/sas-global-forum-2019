import time

import pandas as pd
import requests


def resolve_ips(log, conn, resolution_server_host, resolution_server_port, resolution_server_ips_limit,
                table_name, ip_address_field, hostname_field):

    # Download data missing host names
    code = F'''
        data {table_name}_host {table_name}_nohost;
            set {table_name};
            if {hostname_field} = '' then output {table_name}_nohost;
            else output {table_name}_host;
    '''
    conn.datastep.runcode(code)

    conn.table.promote(f"{table_name}_host")
    conn.table.promote(f"{table_name}_nohost")

    resolve_df = conn.CASTable(f"{table_name}_nohost").to_frame()

    if resolve_df is None or len(resolve_df) == 0:
        log.debug("All devices have non-null hostnames")
        return

    log.debug(f"Resolving ips for {len(resolve_df)} devices")

    result_df = pd.DataFrame()

    # Number of ips to resolve in one shot
    chunk_size = resolution_server_ips_limit

    # Scroll through the entire list and resolve chunk_size ips at a time
    for i in range(0, len(resolve_df), chunk_size):
        chunk_df = resolve_df[i:i + chunk_size]
        ips = ",".join(chunk_df[ip_address_field].unique())
        res_json = invoke_resolution_server(ips, resolution_server_host, resolution_server_port)

        if res_json is not None:
            df = pd.DataFrame(list(res_json.items()), columns=[ip_address_field, "resolved_hostname"])
            temp_df = pd.merge(chunk_df, df, on=ip_address_field, how="left")
            temp_df.fillna("", inplace=True)
            result_df = pd.concat([result_df, temp_df])

    # Set src_dn_hostname to resolved_hostname if it is null
    conn.upload(result_df, casout=f"{table_name}_resolved")

    conn.table.promote(f"{table_name}_resolved")

    code = F'''
        data {table_name} (drop=resolved_hostname);
            set {table_name}_host {table_name}_resolved;
    '''
    conn.datastep.runcode(code)


def invoke_resolution_server(ips, resolution_server_host, resolution_server_port):

    resolution_url = f"http://{resolution_server_host}:{resolution_server_port}/dns/Resolve/Now/{ips}"

    # Number of times to retry resolution
    retry_count = 0

    res = requests.get(resolution_url)

    for i in range(retry_count):
        res = requests.get(resolution_url)
        time.sleep(0.25)  # Sleep for 0.25 seconds

    res_json = res.json()
    return res_json
