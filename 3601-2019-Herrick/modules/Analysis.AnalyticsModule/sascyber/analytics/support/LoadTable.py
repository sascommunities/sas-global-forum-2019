from sascyber.utils.casutils import load_table
from sascyber.analytics.base.CasAnalytic import CasAnalytic
from sascyber.utils.decorators import timeExecution


class LoadTable(CasAnalytic):

    # Default constructor
    def __init__(self):
        super().__init__()

    def runAnalytic(self):
        # Nothing to do here since base Analytic class loads the table
        pass
