import copy
import stats.stats as stats
import maps.maps as maps
import navigation.navigation as navigation
import filehandler.file_handler as file_handler

def engine(debug1=False, debug2=False, debug3=False):
    """
    The main engine that simulates the wanderer's journey on an island map.

    Parameters:
    - debug1 (bool): If True, print initial positions and event positions.
    - debug2 (bool): If True, print starved maps in addition to debug1.
    - debug3 (bool): If True, print drowned maps in addition to debug2.

    Note: To view drowned maps, debug2 must be True.

    The function initializes the island map, sets initial positions, and simulates
    the wanderer's movement, encountering events such as food, spikes, exits, or water.

    The simulation stops when the wanderer escapes, starves, or drowns.

    The final statistics and maps are printed based on the debug flags.
    """
    event = {
        "Exit": 'E',
        "Water": -1,
        "Land": 0,
        "Start Position": 1,
        "Food": 2,
        "Spikes": 4
    }

    TextFile = {
        "Map1": "map5-6.txt",
        "Map2": "map15-18.txt",
        "Map3": "map20-20.txt"
    }

    escaped_maps = []
    starved_maps = []
    drowned_maps = []

    map_dimensions = maps.get_map_dim(TextFile["Map2"])
    island_map = maps.load_map(TextFile["Map2"], map_dimensions)
    movement_map = maps.create_blank_map(map_dimensions)

    navigation.update_bridge_pos(island_map, map_dimensions)

    initial_xy = navigation.get_pos(island_map, event["Start Position"])

    if debug1 or debug2 or debug3:
        print(f"\nInitial Position:{initial_xy}")
        food_xy = navigation.get_pos(island_map, event["Food"])
        print("Food Positions", end=':')
        stats.print_event_positions(food_xy)

        spikes_xy = navigation.get_pos(island_map, event["Spikes"])
        print(f"Spikes Positions", end=':')
        stats.print_event_positions(spikes_xy)

    movement_xy = copy.deepcopy(initial_xy)

    print("Island Map: ")
    maps.print_matrix(island_map)

    island_map[movement_xy[0]][movement_xy[1]] = 0

    lives = 100
    while lives > 0:
        lives -= 1
        maps.clear_matrix(movement_map, map_dimensions)
        movement_xy = copy.deepcopy(initial_xy)
        movement_map[movement_xy[0]][movement_xy[1]] = 1
        steps = int((map_dimensions[0] * map_dimensions[1]) >> 2)

        if debug3:
            print(f"Steps = {map_dimensions[0]} * {map_dimensions[1]} / 4 = {steps}")

        while steps > 0:
            navigation.rand_update_movement_pos(movement_map, movement_xy, True)
            steps -= 1

            if navigation.on_event_type(island_map, movement_xy, event["Food"]):
                steps += 2
                if debug3:
                    print("Found Food Energy increased + 2")
                continue
            elif navigation.on_event_type(island_map, movement_xy, event["Spikes"]):
                steps -= 1
                if debug3:
                    print("Oh No stepped on Spikes! Energy decreased -1")
                continue

            if navigation.on_event_type(island_map, movement_xy, event["Exit"]):
                stats.escaped_count += 1
                escaped_maps.append(copy.deepcopy(movement_map))
                break
            elif navigation.on_event_type(island_map, movement_xy, event["Water"]):
                stats.drowned_count += 1
                drowned_maps.append(copy.deepcopy(movement_map))
                break
            elif steps == 0:
                stats.starved_count += 1
                starved_maps.append(copy.deepcopy(movement_map))
                break

    stats.print_all_stats()
    if debug1 or debug2 or debug3:
        if stats.escaped_count > 0:
            print(f"\nEscaped Maps: ")
            maps.print_list_of_maps(escaped_maps)

    if debug2 or debug3:
        if stats.starved_count > 0:
            print(f"\nStarved Maps: ")
            maps.print_list_of_maps(starved_maps)

    if debug3:
        if stats.drowned_count > 0:
            print(f"\nDrowned Maps: ")
            maps.print_list_of_maps(drowned_maps)


# engine() # Prints Island Map, and Stats Only
engine(debug1=True)  # Prints everything above, plus Event Object positions on the map, and Escape Maps
# engine(debug2=True) # Prints everything of debug1, plus Starved Maps
# engine(debug3=True) # Prints Everything
