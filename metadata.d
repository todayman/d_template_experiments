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

module metadata;

import std.signals;
private import std.bitmanip;
private import std.system;
private import std.exception : enforce;
private import std.conv : to;

private import sync;

class FileData
{
        ulong _hash;
        string _url;
        ulong _filesize;

    public:
        this()
        {
        }
        
        this(hash_t h, string u, ulong s)
        {
            _hash = h;
            _url = u;
            _filesize = s;
        }

        this(FileData other)
        {
            _hash = other.hash;
            _url = other.url;
            _filesize = other.filesize;
        }

    @property {
        // TODO sync attribute without the ()
        @Sync!(hash)()
        hash_t hash() const {
            return _hash;
        }
        void hash(hash_t new_hash) {
            if (_hash != new_hash) {
                _hash = new_hash;
                hashChanged.emit(this);
            }
        }
    }
    mixin Signal!(FileData) hashChanged; // TODO should I pass the new value here?
    @property {
        @Sync!(url)() string url() const {
            return _url;
        }
        void url(string new_url) {
            if ( _url != new_url ) {
                _url = new_url;
                urlChanged.emit(this);
            }
        }
    }
    mixin Signal!(FileData) urlChanged;
    @property {
        @Sync!(filesize)() ulong filesize() const {
            return _filesize;
        }
        void filesize(ulong new_filesize) {
            if ( _filesize != new_filesize ) {
                _filesize = new_filesize;
                filesizeChanged.emit(this);
            }
        }
    }
    mixin Signal!(FileData) filesizeChanged;

    override bool opEquals(Object o) const
    {
        auto rhs = to!(const FileData)(o);
        if( rhs is null ) {
            return false;
        }
        else {
            return hash == rhs.hash && filesize == rhs.filesize && url == rhs.url;
        }
    }

    override int opCmp(Object o) const {
        // TODO implement this sensibly
        assert(0);
    }

    /* I want to do this,
    enum Field : string {
        HASH = "hash",
        URL = "url",
        FILESIZE = "filesize",
    }
    but then the switch here isn't over a string, it's over a Field,
    so the compiler won't let me.
    This might also have problems when I pass string arguments
    into the applyUpdate method.
     */
    enum Field_HASH = "hash";
    enum Field_URL = "url";
    enum Field_FILESIZE = "filesize";
    void applyUpdate(string key, const (ubyte)[] data)
    {
        switch( key ) {
            case Field_HASH:
                enforce( data.length == hash_t.sizeof );
                hash = data.read!hash_t();
                break;
            case Field_URL:
                enforce(data.length % char.sizeof == 0);
                auto str_len = data.length / char.sizeof;
                char[] new_url = new char[str_len];
                foreach(idx ; 0..str_len ) {
                    new_url[idx] = data.read!char();
                }
                // TODO without the extra copy?
                url = new_url.idup;
                break;
            case Field_FILESIZE:
                enforce(data.length == ulong.sizeof);
                filesize = data.read!ulong();
                break;
            default:
                assert(0);
        }
    }

    auto getField(string key)() {
        return __traits(getMember, this, key);
    }

    static bool doesFieldSync(string key)() {
        //static if( key[0] == '_' ) {
        //    return false;
        //}
        static if( __traits(compiles, __traits(getMember, FileData,key)) ) {
            return doesFieldSync_imp!(__traits(getMember, FileData, key)) ();
            //alias mixin("FileData." ~ key) field;
            static if( __traits(getAttributes, mixin("FileData." ~ key)).length == 0 ) {
                return false;
            }
            else {
                //sync.isSyncType!(__traits(getAttributes, __traits(getMember, new FileData(),key))[0]);
                //return doesFieldSync!(__traits(getMember, fd, key))();
                return false;
            }
        }
        else {
            pragma(msg, "no compile for " ~ key);
            return false;
        }
    }
    static bool doesFieldSync_imp(alias field)() {
        /*immutable attribs = __traits(getAttributes, field);
        static if( attribs.length == 0 ) {
            //pragma(msg, "field " ~ __traits(identifier, field) ~ " does not sync");
            return false;
        }
        else {
            alias typeof(attribs[0]).superclass s; 
            static if( is( s : sync.Sync!field) ) {
                pragma(msg, "field " ~ __traits(identifier, field) ~ " syncs");
            }
            else {
                pragma(msg, "field " ~ __traits(identifier, field) ~ " does not sync");
            }
            return is( s : sync.Sync!field);
        }*/
        return false;
    }
    // This is the method I'm trying to write
    static string[] syncableFields() {
        auto result = new string[0];
        foreach( key ; __traits(allMembers, FileData) )
        {
            if( doesFieldSync!key() ) {
                result ~= key;
            }
        }
        return result;
    }
}
