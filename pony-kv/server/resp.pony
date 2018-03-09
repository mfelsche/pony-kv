"""
REdis Serialization Protocol support for Pony

See: https://redis.io/topics/protocol
"""
use "buffered"
use "debug"

class val RESPError
  let data: String val

  new val create(src: String val) =>
    data = src

class val RESPBulkString
  embed data: String val

  new val create(src: Array[U8] val) =>
    data = String.from_array(src)

class val RESPArray
  embed data: Array[RESP] iso

  new trn create(len: USize) =>
    data = recover Array[RESP](len) end


type RESP is (
  None val |
  String val |
  RESPError val |
  I64 val |
  RESPBulkString val |
  RESPArray val
)

primitive RESPCodec

  fun serialize(resp: RESP): ByteSeqIter =>
    let writer: Writer ref = Writer
    serialize_raw(resp, writer)
    writer.done()

  fun serialize_raw(resp: RESP, writer: Writer) =>
    match resp
    | None => writer.write("$-1\r\n")
    | let t: String =>
      writer
        .>u8('+')
        .>write(t)
        .write("\r\n")
    | let e: RESPError =>
      writer
        .>u8('-')
        .>write(e.data)
        .write("\r\n")
    | let i: I64 =>
      writer
        .>u8(':')
        .>write(i.string())
        .write("\r\n")
    | let array: RESPArray val =>
      writer
        .>u8('*')
        .>write(array.data.size().string())
        .write("\r\n")
      for elem in array.data.values() do
        serialize_raw(elem, writer)
      end
    | let bulk: RESPBulkString =>
      let size_str = bulk.data.size().string()
      let s = size_str.size()
      writer
        .>reserve_current(bulk.data.size() + s + 5)
        .>u8('$')
        .>write(consume size_str)
        .>write("\r\n")
        .>write(bulk.data)
        .write("\r\n")
    end

  fun deserialize(reader: Reader): RESP ? =>
    // TODO: handle error cases where there is not enough data
    // and try to read again once more data is there
    // set some state
    match reader.peek_u8()?
    | '*' => // array
      if reader.peek_u8(1)? == '-' then
        reader.line()? // consume line
        Debug("Null Array")
        None
      else
        let size = reader.>skip(1)?.line()?.usize()? // max is 512 MB
        let array = RESPArray(size)
        Debug("RESPAarray of size: " + size.string())
        var i: USize = size
        while i > 0 do
          let resp = deserialize(reader)?
          array.data.push(resp)
          i = (i - 1)
        end
        consume array
      end
    | '+' => // simple string
      Debug("RESPSimpleString")
      reader.>skip(1)?.line()?
    | '-' => // error
      Debug("RESPError")
      RESPError(reader.>skip(1)?.line()?)
    | ':' => // integer
      Debug("RESPInteger")
      reader.>skip(1)?.line()?.i64()?
    | '$' => // bulk string
      if reader.peek_u8(1)? == '-' then
        // Null Bulk String
        reader.line()? // consume line
        Debug("Null Bulk String")
        None
      else
        let size = reader.>skip(1)?.line()?.usize()? // max is 512 MB
        Debug("RESPBulkString of size: " + size.string())
        let block = reader.block(size)?
        let bulk = RESPBulkString(consume block)
        reader.u16_be()? // consume last CRLF
        consume bulk
      end
    end


