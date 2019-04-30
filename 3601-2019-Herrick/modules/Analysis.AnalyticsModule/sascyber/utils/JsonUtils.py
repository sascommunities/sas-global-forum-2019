import json
import os


class JsonUtils:

    @staticmethod
    def read_objects_from_files(list_of_files):
        objects = {}
        for a_file in list_of_files:
            object = JsonUtils.read_object_from_file(a_file)
            sep = "/"
            if "\\" in a_file:
                sep = "\\"
            a_file_name = a_file.split(sep)[-1]
            objects[a_file_name] = object
        return objects

    @staticmethod
    def read_object_from_file(json_file):
        if os.path.isfile(json_file):
            with open(json_file, "r") as f:
                object = json.load(f)
            return object
        return None

    @staticmethod
    def write_object_to_file(object, json_file):
        with open(json_file, "w") as f:
            json.dump(object, f, indent=4)
