bmp2lua = {}

bmp2lua.debug = false

bmp2lua.help = '\
\
    bmp2lua.bmp2lua()\
\
    The outputs of this function are 5 tables, in the following order:\
    --        [1]            [2]              [3]              [4]             [5]\
        table_dec_rgb, table_dec_rgba, table_float_rgba, table_dec_ansi, table_hex_ansi\
\
    example:\
\
    local bmp_file = "8-bit-mario-24bit.bmp"\
\
    local rgb_data,_,_,_,_ = bmp2lua.bmp2lua( bmp_file )\
\
    for  x  =  1, #rgb_data     do\
    for  y  =  1, #rgb_data[x]  do\
\
         local   d  =  rgb_data[x][y]\
         print( string.format( "%5s,%-5s  r = %3s, g = %3s, b = %3s", x, y, d.r, d.g, d.b ) )\
\
    end\
    end\
'

function bmp2lua.bmp2lua(
                    bmp_filename,
                    scalemod,
                    xoffset,
                    yoffset,
                    greenscreen_color
                )

    --               [1]            [2]              [3]              [4]             [5]
--  returns     table_dec_rgb, table_dec_rgba, table_float_rgba, table_dec_ansi, table_hex_ansi

    if not bmp_filename then if bmp2lua.help then print(bmp2lua.help) ; end ; return ; end

    local x_min,y_min       = 1,1
    local x_max,y_max       = 2048,2048

    scalemod          = tonumber(scalemod          or  1)  or  1
    xoffset           = tonumber(xoffset           or  0)  or  0
    yoffset           = tonumber(yoffset           or  0)  or  0
    greenscreen_color = tonumber(greenscreen_color or -1)  or -1

    bmp_filename = tostring(bmp_filename or "") or "8-bit-mario-24bit.bmp"

    if ( bmp_filename == "" ) then bmp_filename = "8-bit-mario-24bit.bmp" ; end

    local b,g,r,a                           = 0,0,0,255
    local line_dec_rgb,table_dec_rgb,table_dec_rgb_flat      = "",{},{}
    local line_dec_rgba,table_dec_rgba,table_dec_rgba_flat   = "",{},{}
    local line_float_rgba,table_float_rgba,table_float_flat  = "",{},{}
    local line_dec_ansi,table_dec_ansi,table_dec_ansi_flat   = "",{},{}
    local line_hex_ansi,table_hex_ansi,table_hex_ansi_flat   = "",{},{}


    local f = io.open(bmp_filename,"rb")

    if ( f == nil ) then print("Error trying to open "..bmp_filename.."  Could not find?" ) ; return ; end

    -----------------------------------------------
    -- Get BMP Header Info (width,height,depth,etc)
    -----------------------------------------------

    local bmp_header      = string.byte(f:read(1))+string.byte(f:read(1))*256
    f:seek("set",10)
    local bmp_data_starts = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    f:seek("set",18)
    local bmp_width       = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    local bmp_height      = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    f:seek("set",28)
    local bmp_depth       = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    local bmp_bpp         = bmp_depth / 8
    local bmp_field_size  = bmp_width*bmp_height

    if  bmp2lua.debug  then  print("bmp_filename='"..tostring(bmp_filename).."'\nbmp_data_starts="..tostring(bmp_data_starts).."\nbmp_field_size="..tostring(bmp_field_size).."\nbmp_width="..tostring(bmp_width).."\nbmp_height="..tostring(bmp_height).."\nbmp_depth="..tostring(bmp_depth).."\nbmp_bpp="..tostring(bmp_bpp))  end

    f:seek("set",bmp_data_starts)

    for   y   = bmp_height, 1, -1  do

        table_dec_rgb[y]    = {} ; table_dec_rgb_flat[y]  = {}
        table_dec_rgba[y]   = {} ; table_dec_rgba_flat[y] = {}
        table_float_rgba[y] = {}
        table_dec_ansi[y]   = {}
        table_hex_ansi[y]   = {}

    for   x   = 1, bmp_width, 1  do

        local x_val = ( math.floor ( x / scalemod + ( xoffset - ( xoffset / scalemod ) ) ) )
        local y_val = ( math.floor ( y / scalemod + ( yoffset - ( yoffset / scalemod ) ) ) )

        if      ( bmp_bpp == 3 )
        then
                b,g,r   = string.byte(f:read(1)),string.byte(f:read(1)),string.byte(f:read(1))

        elseif  ( bmp_bpp == 4 )
        then
                b,g,r,a = string.byte(f:read(1)),string.byte(f:read(1)),string.byte(f:read(1)),string.byte(f:read(1))

        elseif  ( bmp_bpp == 1 )
        then
                b =   string.byte(f:read(1))
                r =   math.floor( r / 8 / 4 % 4 )
                g =   math.floor( r / 4 % 8 )
                b =   math.floor( r % 8 )
        end

        local color_4_bytes_fullalpha =  r + g*256 + b*256*256 + 255*256*256*256
        local color_4_bytes           =  r + g*256 + b*256*256 + a*256*256*256
        local color_4_bytes_hex       =  string.format("%08X",color_4_bytes)
        local color_3_bytes           =  r + g*256 + b*256*256
        local color_3_bytes_hex       =  string.format("%06X",color_3_bytes)
        local color_ansi              =  16 + math.floor((r+6)/51) + math.floor((g+6)/51)*6 + math.floor((b+6)/51)*6*6
        local color_ansi_hex          =  string.format("%02X",color_ansi)

        table_dec_rgb[y][x]    = { r = r, g = g, b = b, }                                         ;  table_dec_rgb_flat[y]  = { x = x, y = y, r = r, g = g, b = b, }
        table_dec_rgba[y][x]   = { r = r, g = g, b = b, a = a, }                                  ;  table_dec_rgba_flat[y] = { x = x, y = y, r = r, g = g, b = b, a = a, }
        table_float_rgba[y][x] = { r = 1.0/255*r, g = 1.0/255*g, b = 1.0/255*b, a = 1.0/255*a, }
        table_dec_ansi[y][x]   = color_ansi
        table_hex_ansi[y][x]   = color_ansi_hex

    end
        for  z = 1, bmp_width%4    do    f:read(1)   ; end  --  Munch any extra data if width is not even.
    end

    io.close(f)

    if  bmp2lua.debug and bmp2lua.help
    then
        print( bmp2lua.help )
    end

    --               [1]            [2]              [3]              [4]             [5]               [6]                [7]
    return     table_dec_rgb, table_dec_rgba, table_float_rgba, table_dec_ansi, table_hex_ansi, table_dec_rgb_flat, table_dec_rgba_flat

end

--------------------------------------------------------------------------------

function bmp2lua.table_dec_rgb(...)

    local table_dec_rgb  = bmp2lua.bmp2lua(...)

    for k,y in pairs(table_dec_rgb) do
        
    for k,x in pairs(y)             do
        print( "x,y,r,g,b = "..tostring(x)..","..tostring(y)..","..tostring(r)..","..tostring(g)..","..tostring(b) )
    end
        line_hex_ansi = "printf %b '"..line_hex_ansi.."\\e[0m\\n".."'"
        print(line_hex_ansi)
    end

    return table_dec_rgb

end

--------------------------------------------------------------------------------

function bmp2lua.bmp2ansi_executable(...)

    local _,_,_,table_dec_ansi = bmp2lua.bmp2lua(...)

    local line_hex_ansi  = ""

    for k,y in pairs(table_dec_ansi) do
        line_hex_ansi = ""
    for k,x in pairs(y)              do
        line_hex_ansi = line_hex_ansi..string.format("\\e[48;5;%dm  ",x)
    end
        line_hex_ansi = "printf %b '"..line_hex_ansi.."\\e[0m\\n".."'"
        print(line_hex_ansi)
    end

    return table_dec_ansi

end

--------------------------------------------------------------------------------

bmp2lua.args = {...}

if    ( #bmp2lua.args > 0 )
then
      print("# "..table.concat(bmp2lua.args," "))
      local command = loadstring(table.concat(bmp2lua.args,"\n"))
      if    ( command ~= nil )
      then  command()
      else  print("loadstring returned nil, meaning your command is invalid.  Good Day Sir, Good day...")
      end
else  return bmp2lua
end

--------------------------------------------------------------------------------

