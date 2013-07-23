/*
 *  Music player - a distributed tool for playing & managing music
 *  Copyright (C) 2013 Paul O'Neil <redballoon36@gmail.com>
 *  
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module sync;

import std.stdio;
private import std.traits;

public bool isSyncType(alias T)() {
    static if( is( T.superclass == Sync_check ) ) {
        return true;
    }
    else {
        static assert(0);
        return false;
    }
}

public struct Sync(alias T, alias R)
{
    private alias Sync_check superclass;
    alias T var;
    alias R encodeField;
    //size_t encode_length = S;
    /*Sync!T opCast(Q : Sync!T)() {
        assert(0);
    }*/
}
private struct Sync_check
{
}


string generateGetField(alias field)()
{
    string field_name = __traits(identifier, field);
    pragma(msg, __traits(getAttributes, field));
    string ret = "auto getField(string key : \"" ~ field_name ~ "\")() {\n";
    ret ~= "    return this." ~ field_name ~ ";\n";
    ret ~= "}";
    return ret;
}
mixin template encodeField(alias field)
{
    /*void encodeField_ext(alias key)(T obj, ubyte[] result, size_t index)
    {
        import std.stdio;
        //auto value = ;
        //pragma(msg, __traits(getMember, obj, key));
        //auto traits = __traits(getAttributes, __traits(getMember, obj, key));
        auto traits = __traits(getAttributes, key);
        writeln("traits = ", traits);
        //pragma(msg, traits);
        static if( is( traits[0] : Sync) ) {
            pragma(msg, "Hello************************");
        }
    }*/
    typeof(field) getField(string key)()
        if ( key == __traits(identifier, field) )
    {
        pragma(msg, "Hello!");
        return field;
    }
}
