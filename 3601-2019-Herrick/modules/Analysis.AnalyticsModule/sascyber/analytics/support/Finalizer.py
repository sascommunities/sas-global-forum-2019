from sascyber.analytics.base.CasAnalytic import CasAnalytic
from sascyber.utils.casutils import caslib_exists
from sascyber.utils.decorators import timeExecution
import os


class Finalizer(CasAnalytic):

    # Default constructor
    def __init__(self):
        super().__init__()
        self.processed_file = None

    def set_processed_file(self, processed_file):
        self.processed_file = processed_file

    @timeExecution
    def runAnalytic(self):

        # Create .complete file to indicate that the job has finished
        if self.processed_file is not None:
            f = open(F"{self.processed_file}.complete", "w")
            f.close()

        # Delete caslib lock file if it exists
        lock_file = f"/tmp/work_{self.job_execution_id}_lock"
        if os.path.exists(lock_file):
            os.remove(lock_file)

        # Drop work_caslib if it exists
        if self.conn is not None:
            if caslib_exists(self.conn, self.work_caslib):
                self.conn.dropcaslib(self.work_caslib)
                self.log.debug(F"Successfully dropped caslib: {self.work_caslib}")
            else:
                self.log.debug(F"Caslib {self.work_caslib} does not exist")
        else:
            self.log.debug(F"Could not drop caslib: {self.work_caslib}")
