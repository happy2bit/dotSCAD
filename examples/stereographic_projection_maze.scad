include <line2d.scad>;
include <stereographic_extrude.scad>;

maze_rows = 5;
block_width = 40;
wall_thickness = 20;
fn = 24;
shadow = "YES"; // [YES, NO]
wall_height = 2;

// Constants for wall types

NO_WALL = 0;       
UPPER_WALL = 1;    
RIGHT_WALL = 2;    
UPPER_RIGHT_WALL = 3; 

function block_data(x, y, wall_type, visited) = [x, y, wall_type, visited];
function get_x(block_data) = block_data[0];
function get_y(block_data) = block_data[1];
function get_wall_type(block_data) = block_data[2];

// create a starting maze for being visited later.
function starting_maze(rows, columns) =  [
    for(y = [1:rows]) 
        for(x = [1:columns]) 
            block_data(
                x, y, 
                // all blocks have upper and right walls except the exit
                y == rows && x == columns ? UPPER_WALL : UPPER_RIGHT_WALL, 
                // unvisited
                false 
            )
];

// find out the index of a block with the position (x, y)
function indexOf(x, y, maze, i = 0) =
    i > len(maze) ? -1 : (
        [get_x(maze[i]), get_y(maze[i])] == [x, y] ? i : 
            indexOf(x, y, maze, i + 1)
    );

// is (x, y) visited?
function visited(x, y, maze) = maze[indexOf(x, y, maze)][3];

// is (x, y) visitable?
function visitable(x, y, maze, rows, columns) = 
    y > 0 && y <= rows &&     // y bound
    x > 0 && x <= columns &&  // x bound
    !visited(x, y, maze);     // unvisited

// setting (x, y) as being visited
function set_visited(x, y, maze) = [
    for(b = maze) 
        [x, y] == [get_x(b), get_y(b)] ? 
            [x, y, get_wall_type(b), true] : b
];
    
// 0（right）、1（upper）、2（left）、3（down）
function rand_dirs() =
    [
        [0, 1, 2, 3],
        [0, 1, 3, 2],
        [0, 2, 1, 3],
        [0, 2, 3, 1],
        [0, 3, 1, 2],
        [0, 3, 2, 1],
        [1, 0, 2, 3],
        [1, 0, 3, 2],
        [1, 2, 0, 3],
        [1, 2, 3, 0],
        [1, 3, 0, 2],
        [1, 3, 2, 0],
        [2, 0, 1, 3],
        [2, 0, 3, 1],
        [2, 1, 0, 3],
        [2, 1, 3, 0],
        [2, 3, 0, 1],
        [2, 3, 1, 0],
        [3, 0, 1, 2],
        [3, 0, 2, 1],
        [3, 1, 0, 2],
        [3, 1, 2, 0],
        [3, 2, 0, 1],
        [3, 2, 1, 0]
    ][round(rands(0, 24, 1)[0])]; 

// get x value by dir
function next_x(x, dir) = x + [1, 0, -1, 0][dir];
// get y value by dir
function next_y(y, dir) = y + [0, 1, 0, -1][dir];

// go right and carve the right wall
function go_right_from(x, y, maze) = [
    for(b = maze) [get_x(b), get_y(b)] == [x, y] ? (
        get_wall_type(b) == UPPER_RIGHT_WALL ? 
            [x, y, UPPER_WALL, visited(x, y, maze)] : 
            [x, y, NO_WALL, visited(x, y, maze)]
        
    ) : b
]; 

// go up and carve the upper wall
function go_up_from(x, y, maze) = [
    for(b = maze) [get_x(b), get_y(b)] == [x, y] ? (
        get_wall_type(b) == UPPER_RIGHT_WALL ? 
            [x, y, RIGHT_WALL, visited(x, y, maze)] :  
            [x, y, NO_WALL, visited(x, y, maze)]
        
    ) : b
]; 

// go left and carve the right wall of the left block
function go_left_from(x, y, maze) = [
    for(b = maze) [get_x(b), get_y(b)] == [x - 1, y] ? (
        get_wall_type(b) == UPPER_RIGHT_WALL ? 
            [x - 1, y, UPPER_WALL, visited(x - 1, y, maze)] : 
            [x - 1, y, NO_WALL, visited(x - 1, y, maze)]
    ) : b
]; 

// go down and carve the upper wall of the down block
function go_down_from(x, y, maze) = [
    for(b = maze) [get_x(b), get_y(b)] == [x, y - 1] ? (
        get_wall_type(b) == UPPER_RIGHT_WALL ? 
            [x, y - 1, RIGHT_WALL, visited(x, y - 1, maze)] : 
            [x, y - 1, NO_WALL, visited(x, y - 1, maze)]
    ) : b
]; 

// 0（right）、1（upper）、2（left）、3（down）
function try_block(dir, x, y, maze, rows, columns) =
    dir == 0 ? go_right_from(x, y, maze) : (
        dir == 1 ? go_up_from(x, y, maze) : (
            dir == 2 ? go_left_from(x, y, maze) : 
                 go_down_from(x, y, maze)   // 這時 dir 一定是 3
            
        ) 
    );


// find out visitable dirs from (x, y)
function visitable_dirs_from(x, y, maze, rows, columns) = [
    for(dir = [0, 1, 2, 3]) 
        if(visitable(next_x(x, dir), next_y(y, dir), maze, maze_rows, columns)) 
            dir
];  
    
// go maze from (x, y)
function go_maze(x, y, maze, rows, columns) = 
    //  have visitable dirs?
    len(visitable_dirs_from(x, y, maze, rows, columns)) == 0 ? 
        set_visited(x, y, maze)      // road closed
        : walk_around_from(          
            x, y, 
            rand_dirs(),             
            set_visited(x, y, maze), 
            rows, columns
        );

// try four directions
function walk_around_from(x, y, dirs, maze, rows, columns, i = 4) =
    // all done?
    i > 0 ? 
        // not yet
        walk_around_from(x, y, dirs, 
            // try one direction
            try_routes_from(x, y, dirs[4 - i], maze, rows, columns),  
            , rows, columns, 
            i - 1) 
        : maze;
        
function try_routes_from(x, y, dir, maze, rows, columns) = 
    // is the dir visitable?
    visitable(next_x(x, dir), next_y(y, dir), maze, rows, columns) ?     
        // try the block 
        go_maze(
            next_x(x, dir), next_y(y, dir), 
            try_block(dir, x, y, maze, rows, columns),
            rows, columns
        ) 
        // road closed so return maze directly
        : maze;   

module stereographic_projection_maze2(maze_rows, block_width, wall_thickness, fn, wall_height, shadow) {
    maze_blocks = go_maze(
        1, 1,   // starting point
        starting_maze(maze_rows, maze_rows),  
        maze_rows, maze_rows
    ); 

    length = block_width * maze_rows + wall_thickness;

    module draw_block(wall_type, block_width, wall_thickness) {
        if(wall_type == UPPER_WALL || wall_type == UPPER_RIGHT_WALL) {
            // draw a upper wall
            line2d(
                [0, block_width], [block_width, block_width], wall_thickness
            ); 
        }
        
        if(wall_type == RIGHT_WALL || wall_type == UPPER_RIGHT_WALL) {
            // draw a right wall
            line2d(
                [block_width, block_width], [block_width, 0], wall_thickness
            ); 
        }
    }

    module draw_maze(rows, columns, blocks, block_width, wall_thickness) {
        for(block = blocks) {
            // move a block to a right position.
            translate([get_x(block) - 1, get_y(block) - 1] * block_width) 
                draw_block(
                    get_wall_type(block), 
                    block_width, 
                    wall_thickness
                );
        }

        // the lowermost wall
        line2d([0, 0], [block_width * columns, 0], 
             wall_thickness);
        // the leftmost wall
        line2d([0, block_width], [0, block_width * rows], 
             wall_thickness);
    } 
    
    module maze() {
        translate([-block_width * maze_rows / 2, -block_width * maze_rows / 2, 0]) union() {
            draw_maze(
                maze_rows, 
                maze_rows, 
                maze_blocks, 
                block_width, 
                wall_thickness
            );
            
            line2d([0, wall_thickness], [0, wall_thickness], wall_thickness);
            
            line2d(
                [
                    block_width * maze_rows, 
                    block_width * (maze_rows - 1) + wall_thickness
                ], 
                [
                    block_width * maze_rows, 
                    block_width * (maze_rows - 1) + wall_thickness
                ], 
                wall_thickness
            );
        }
    }
    
    stereographic_extrude(shadow_side_leng = length, $fn = fn)
        maze();
    
    if(shadow == "YES") {
        color("black") linear_extrude(wall_height) maze();
    }
}

stereographic_projection_maze2(maze_rows, block_width, wall_thickness, fn, wall_height, shadow);