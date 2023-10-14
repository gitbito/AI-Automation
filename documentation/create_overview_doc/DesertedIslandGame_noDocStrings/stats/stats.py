# Store Stats of the Wanderer : Described as Three different Event Outcomes
escaped_count = 0
starved_count = 0
drowned_count = 0


def print_event_positions(event_xy):
    if not event_xy:
        # If its empty Return Nothing
        print([None])
    row = 0
    col = 1
    num_items = (len(event_xy) / 2)
    while num_items > 0:
        print(f"[{event_xy[row]},{event_xy[col]}]", end=' ')
        row += 2
        col += 2
        num_items -= 1


def print_lives():
    print(f'\nNumber Of Lives: {escaped_count + drowned_count + starved_count}')


def print_escaped():
    print(f'Escaped: {escaped_count} times')


def print_drowned():
    print(f'Drowned: {drowned_count} times')


def print_starved():
    print(f'Starved: {starved_count} times')


def print_all_stats():
    print_lives()
    print_escaped()
    print_starved()
    print_drowned()
    print()
