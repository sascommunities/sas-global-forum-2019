import fcntl
import os


class Concurrency():

    # Default constructor
    def __init__(self, log, resource):
        self.log = log
        self.lock_file = f"/tmp/{resource}_lock"
        self.lock_fh = None

    def open_lock_file(self):
        if os.path.exists(self.lock_file):
            self.lock_fh = open(self.lock_file, "r")
        else:
            self.lock_fh = open(self.lock_file, "w")


    def close_lock_file(self):
        self.lock_fh.close()

    def obtain_lock(self):
        self.open_lock_file()
        self.log.debug(f"Waiting for lock on {self.lock_file}")
        fcntl.flock(self.lock_fh, fcntl.LOCK_EX)
        self.log.debug(f"Obtained lock on {self.lock_file}")

    def release_lock(self):
        if self.lock_fh is not None:
            fcntl.flock(self.lock_fh, fcntl.LOCK_UN)
            self.log.debug(f"Released lock on {self.lock_file}")
            self.lock_fh.close()
        else:
            self.log.debug(f"File handle {self.lock_file} is None")


if __name__ == "__main__":

    import logging
    import sys
    import time

    log = logging.getLogger()
    log.setLevel(logging.DEBUG)
    log.addHandler(logging.StreamHandler(sys.stdout))

    concurrency = Concurrency(log, "foo")
    concurrency.obtain_lock()
    time.sleep(5)
    concurrency.release_lock()
