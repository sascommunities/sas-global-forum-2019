import datetime
import math


def duration_to_micros(duration_str):
    amount, unit = duration_str.split(" ")
    amount = int(amount)

    if unit == 'week' or unit == 'weeks':
        t = datetime.timedelta(weeks=amount)

    if unit == 'day' or unit == 'days':
        t = datetime.timedelta(days=amount)

    if unit == 'hour' or unit == 'hours':
        t = datetime.timedelta(hours=amount)

    return t.total_seconds() * 1000000


def quant_interval(date_time, periodicity):
    time_interval = periodicity.get("interval")
    time_interval_unit = periodicity.get("unit")

    if time_interval_unit == 'min':
        interval = ((date_time.hour * 60) + date_time.minute) / time_interval

    if time_interval_unit == 'hour':
        interval = date_time.hour / time_interval

    return math.floor(interval) + 1


if __name__ == "__main__":
    value = duration_to_micros("1 week")
    print(value)
