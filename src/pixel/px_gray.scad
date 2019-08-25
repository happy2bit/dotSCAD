function _px_gray_row(r_count, row_bits, width, height, center, invert) =
    let(
        half_w = width / 2,
        half_h = height / 2,
        offset_x = center ? 0 : half_w,
        offset_y = center ? -half_h : 0,
        level = invert ? 0 : 255
    ) 
    [
        for(i = 0; i < width; i = i + 1) 
            if(row_bits[i] != level) 
                [
                    [i - half_w + offset_x, r_count + offset_y], 
                    invert ? row_bits[i] / 255 : 1 - row_bits[i] / 255
                ]
    ];

function px_gray(levels, center = false, invert = false) = 
    let(
        width = len(levels[0]),
        height = len(levels),
        offset_i = height / 2
    )
    [
        for(i = height - 1; i > -1; i = i - 1) 
        let(row = _px_gray_row(height - i - 1, levels[i], width, height, center, invert))
        if(row != []) each row
    ];