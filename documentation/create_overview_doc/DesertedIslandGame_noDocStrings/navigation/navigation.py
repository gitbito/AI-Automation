import random

bridge1_xy = [0, 0]
bridge2_xy = [0, 0]

direction = {
    'up': 0,
    'right': 1,
    'down': 2,
    'left': 3,
    'last_dir': 0
}


def get_pos(island_map, event_type=1):
    row = 0
    position = []

    for line in island_map:
        col = 0
        for element in line:
            element = int(element)
            if element == event_type:
                position.append(row)
                position.append(col)
            col += 1
        row += 1
    return position


def update_bridge_pos(island_map, map_dimensions):
    bridge_count = 2
    row = 0
    col = 0

    while row < map_dimensions[0]:
        if is_even(island_map[row][col]):
            if bridge_count == 2:
                bridge1_xy[0] = row
                bridge1_xy[1] = col
                bridge_count -= 1
            else:
                bridge2_xy[0] = row
                bridge2_xy[1] = col
            bridge_count -= 1
        row += 1
    row -= 1

    while col < map_dimensions[1]:
        if is_even(island_map[row][col]):
            if bridge_count == 2:
                bridge1_xy[0] = row
                bridge1_xy[1] = col
                bridge_count -= 1
            else:
                bridge2_xy[0] = row
                bridge2_xy[1] = col
                bridge_count -= 1
        col += 1
    col -= 1

    while row > -1:
        if is_even(island_map[row][col]):
            if bridge_count == 2:
                bridge1_xy[0] = row
                bridge1_xy[1] = col
                bridge_count -= 1
            else:
                bridge2_xy[0] = row
                bridge2_xy[1] = col
                bridge_count -= 1
        row -= 1
    row += 1

    while col > -1:
        if is_even(island_map[row][col]):
            if bridge_count == 2:
                bridge1_xy[0] = row
                bridge1_xy[1] = col
                bridge_count -= 1
            else:
                bridge2_xy[0] = row
                bridge2_xy[1] = col
                bridge_count -= 1
        col -= 1
    col += 1


def at_exit(movement_xy):
    if movement_xy[0] == bridge1_xy[0] and movement_xy[1] == bridge1_xy[1]:
        return True
    elif movement_xy[0] == bridge2_xy[0] and movement_xy[1] == bridge2_xy[1]:
        return True
    else:
        return False


def on_event_type(island_map, movement_xy, event_type):
    return island_map[movement_xy[0]][movement_xy[1]] == event_type


def rand_update_movement_pos(movement_map, movement_xy, smart_move=False):
    if smart_move:
        dir_ = smart_movement(direction['last_dir'])
    else:
        dir_ = random.randint(0, 3)

    if dir_ == direction['up']:
        movement_xy[0] -= 1
    elif dir_ == direction['right']:
        movement_xy[1] += 1
    elif dir_ == direction['down']:
        movement_xy[0] += 1
    elif dir_ == direction['left']:
        movement_xy[1] -= 1

    movement_map[movement_xy[0]][movement_xy[1]] += 1

    if smart_move:
        direction['last_dir'] = dir_


def smart_movement(last_dir):
    dir_ = random.randint(0, 3)

    if last_dir == direction['up']:
        if dir_ == direction['down']:
            dir_ = random.randint(0, 3)

    if last_dir == direction['right']:
        if dir_ == direction['left']:
            dir_ = random.randint(0, 3)

    if last_dir == direction['down']:
        if dir_ == direction['up']:
            dir_ = random.randint(0, 3)

    if last_dir == direction['left']:
        if dir_ == direction['right']:
            dir_ = random.randint(0, 3)

    return dir_


def is_even(value):
    return not value & 0x01
