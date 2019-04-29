import json
import logging
import pika

from sascyber.analytics.base.Analytic import Analytic
from sascyber.utils.decorators import timeExecution


class RequestConcatEventTables(Analytic):

    # Default constructor
    def __init__(self):
        super().__init__()
        self.processed_file = None
        self.device_id_fields = None
        self.exclude_event_type_ids = None
        self.investiagtive_event_type_ids = None
        self.queuing_server_host = None
        self.queuing_server_port = None
        self.log = None
        logging.getLogger("pika").setLevel(logging.WARNING)

    def set_processed_file(self, processed_file):
        self.processed_file = processed_file

    def set_device_id_fields(self, device_id_fields):
        self.device_id_fields = device_id_fields

    def set_exclude_event_type_ids(self, exclude_event_type_ids):
        self.exclude_event_type_ids = exclude_event_type_ids

    def set_investiagtive_event_type_ids(self, investiagtive_event_type_ids):
        self.investiagtive_event_type_ids = investiagtive_event_type_ids

    def set_queuing_server_host(self, queuing_server_host):
        self.queuing_server_host = queuing_server_host

    def set_queuing_server_port(self, queuing_server_port):
        self.queuing_server_port = queuing_server_port

    def set_queuing_server_user(self, queuing_server_user):
        self.queuing_server_user = queuing_server_user

    def set_queuing_server_password(self, queuing_server_password):
        self.queuing_server_password = queuing_server_password

    @timeExecution
    def init_and_run_analytic(self):

        self.log = logging.getLogger(F"{self.job_execution_id}:{self.task_name}:{self.__class__.__name__}")

        connection = None

        try:

            credentials = pika.PlainCredentials(self.queuing_server_user, self.queuing_server_password)

            connection = pika.BlockingConnection(
                pika.ConnectionParameters(self.queuing_server_host, self.queuing_server_port, credentials=credentials))

            channel = connection.channel()

            channel.queue_declare(queue='ConcatEvents_Queue', durable=True)

            event_base_path = "/".join(self.processed_file.split("/")[-4:-1])
            event_file_name = self.processed_file.split("/")[-1]

            concat_event_tables_parms = {"event_base_path": event_base_path, "event_file_name": event_file_name,
                                         "exclude_event_type_ids": self.exclude_event_type_ids,
                                         "investiagtive_event_type_ids": self.investiagtive_event_type_ids}

            request = {"support.ConcatEventTables": concat_event_tables_parms}

            channel.basic_publish(exchange='',
                                  routing_key='ConcatEvents_Queue',
                                  body=json.dumps(request))

            self.log.debug(request)
            self.log.debug("Request sent")

        except Exception as e:
            self.log.exception(e)
            self.log.debug("Unable to send message on ConcateEvent queue")

        connection.close()
