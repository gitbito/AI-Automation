def print_list_of_maps(map_list):
    """
    Prints a list of maps.

    Parameters:
    - map_list (list): A list containing maps.

    Example:
    ```
    map_list = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
    print_list_of_maps(map_list)
    ```

    Output:
    ```
    1 2
    3 4

    5 6
    7 8
    ```
    """
    for each_map in map_list:
        for line in each_map:
            print()
            for each_element in line:
                print(each_element, end=' ')
        print()


def print_matrix(matrix_):
    """
    Prints a matrix.

    Parameters:
    - matrix_ (list): A matrix represented as a list of lists.

    Example:
    ```
    matrix = [[1, 2], [3, 4]]
    print_matrix(matrix)
    ```

    Output:
    ```
    1    2
    3    4
    ```
    """
    for row in matrix_:
        print("")
        for item in row:
            print(item, end="\t")
    print("")


def create_blank_map(dim):
    """
    Creates a blank map with the specified dimensions.

    Parameters:
    - dim (list): A 2-element list representing the dimensions of the map.

    Returns:
    - list: A 2D list representing a blank map with zeros.

    Example:
    ```
    dimensions = [3, 4]
    blank_map = create_blank_map(dimensions)
    ```
    """
    zeros = [[0] * dim[1] for _ in range(dim[0])]
    return zeros


def clear_matrix(matrix_, map_dim):
    """
    Clears a matrix by setting all elements to zero.

    Parameters:
    - matrix_ (list): A matrix represented as a list of lists.
    - map_dim (list): A 2-element list representing the dimensions of the matrix.

    Example:
    ```
    matrix = [[1, 2], [3, 4]]
    dimensions = [2, 2]
    clear_matrix(matrix, dimensions)
    ```
    """
    for row in range(0, map_dim[0]):
        for col in range(0, map_dim[1]):
            matrix_[row][col] = 0


def get_map_dim(map_txt):
    """
    Gets the dimensions of the map from a text file.

    Parameters:
    - map_txt (str): The name of the text file containing the map.

    Returns:
    - list: A 2-element list representing the dimensions of the map.

    Example:
    ```
    map_dimensions = get_map_dim("map.txt")
    ```
    """
    dim = []
    with open(map_txt, 'r') as map_file:
        line1 = map_file.readline().split()
        dim.append(int(line1[0]))
        dim.append(int(line1[1]))
    map_file.close()
    return dim


def load_map(map_txt, dim):
    """
    Loads a map from a text file.

    Parameters:
    - map_txt (str): The name of the text file containing the map.
    - dim (list): A 2-element list representing the dimensions of the map.

    Returns:
    - list: A 2D list representing the loaded map.

    Example:
    ```
    map_dimensions = get_map_dim("map.txt")
    loaded_map = load_map("map.txt", map_dimensions)
    ```
    """
    input_map = []
    line = []
    row = 0
    negative = False

    with open(map_txt, 'r') as map_file:
        map_file.readline()
        while row < dim[0]:
            line_str = map_file.readline()
            row += 1
            line.clear()
            for element in line_str.replace(' ', ''):
                if element == '-':
                    negative = True
                    continue
                if negative and element == '1':
                    line.append(-1)
                    negative = False
                    continue
                if element.isdigit():
                    line.append(int(element))
                    continue
            input_map.append(line.copy())
    map_file.close()
    return input_map
