from sascyber.analytics.wh.logins.Logins import Logins


class WhFailedLogins(Logins):
    # Default constructor
    def __init__(self):
        super().__init__()
        self.set_analytic_field_name("whFailedLogins")
