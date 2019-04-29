from sascyber.analytics.base.DstAnalytic import DstAnalytic
from sascyber.analytics.wh.base.WhBaseClass import WhBaseClass


class WhLoginAnalytic(DstAnalytic, WhBaseClass):
    # Default constructor
    def __init__(self):
        DstAnalytic.__init__(self)
        WhBaseClass.__init__(self)
