package flixel;

typedef ByteInt = #if cpp cpp.Int8 #elseif cs cs.Int8 #elseif java java.Int8 #else Int #end;
typedef ShortInt = #if cpp cpp.Int16 #elseif cs cs.Int16 #elseif java java.Int16 #else Int #end;
typedef MiddleInt32 = #if cpp cpp.Int32 #else Int #end;
typedef LongInt = #if cpp cpp.Int64 #elseif cs cs.Int64 #elseif java java.Int64 #else Int #end;

typedef ByteUInt = #if cpp cpp.UInt8 #elseif cs cs.UInt8 #else UInt #end;
typedef ShortUInt = #if cpp cpp.UInt16 #elseif cs cs.UInt16 #else UInt #end;
typedef MiddleUInt32 = #if cpp cpp.UInt32 #else UInt #end;
typedef LongUInt = #if cpp cpp.UInt64 #else UInt #end;

typedef Float32 = #if cpp cpp.Float32 #else Float #end;
typedef Double = #if cpp cpp.Float64 #else Float #end;

#if (!java && !cs && !hl && !cpp)
typedef Single = Float;
#end