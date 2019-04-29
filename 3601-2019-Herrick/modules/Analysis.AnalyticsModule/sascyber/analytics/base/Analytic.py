class Analytic(object):

    def __init__(self):
        self.job_execution_id = None
        self.task_name = None
        self.job_parameters = None

    def set_job_execution_id(self, job_execution_id):
        self.job_execution_id = job_execution_id

    def set_task_name(self, task_name):
        self.task_name = task_name

    def set_job_parameters(self, job_parameters):
        self.job_parameters = job_parameters

    # Abstract method that analytic needs to implement
    def init_and_run_analytic(self):
        raise NotImplementedError()
