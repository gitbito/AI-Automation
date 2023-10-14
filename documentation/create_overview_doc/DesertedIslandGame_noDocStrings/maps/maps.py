def print_list_of_maps(map_list):
    for each_map in map_list:
        for line in each_map:
            print()
            for each_element in line:
                print(each_element, end=' ')
        print()


def print_matrix(matrix_):
    for row in matrix_:
        print("")
        for item in row:
            print(item, end="\t")
    print("")


def create_blank_map(dim):
    zeros = [[0] * dim[1] for _ in range(dim[0])]
    return zeros


def clear_matrix(matrix_, map_dim):
    for row in range(0, map_dim[0]):
        for col in range(0, map_dim[1]):
            matrix_[row][col] = 0


def get_map_dim(map_txt):
    dim = []
    with open(map_txt, 'r') as map_file:
        line1 = map_file.readline().split()
        dim.append(int(line1[0]))
        dim.append(int(line1[1]))
    map_file.close()
    return dim


def load_map(map_txt, dim):
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
