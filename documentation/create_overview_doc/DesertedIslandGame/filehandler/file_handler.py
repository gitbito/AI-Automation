import os

def open_file(path):
    """
    Opens a file using the default system handler.

    Parameters:
    - path (str): Path to the file to be opened.
    """
    os.system("open " + path)
