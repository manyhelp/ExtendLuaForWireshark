﻿--[=======[
-------- -------- -------- --------
  Tencent SSO 2  >>>> Dissectors >>>> 0825
-------- -------- -------- --------

Ping
]=======]

local dissectors = require "TXSSO2/Dissectors";

dissectors[0x3649] = dissectors[0x3649] or {};

dissectors[0x3649][0x0825] = dissectors[0x3649][0x0825] or {};

local proto = require "TXSSO2/Proto";

local aly_lvl = require "TXSSO2/AnalysisLevel";

dissectors[0x3649][0x0825].send = function( buf, pkg, root, t )
  local ver = buf( 1, 2 ):uint();
  local cmd = buf( 1 + 1 + 1, 2 ):uint();
  local seq = buf( 1 + 1 + 1 + 2, 2 ):uint();

  local key = buf:raw( 0x1A, 0x10 );
  TXSSO2_Add2KeyChain( TXSSO2_MakeKeyName( cmd, seq, pkg.number ), key );

  local lvl = aly_lvl();

  if lvl >= alvlC then
    local tt = t:add( proto, buf( 1, 0xA ), "bufPacketHeader");
    dissectors.add( tt, buf, 1,
      ">cMainVer B",
      ">cSubVer B",
      ">wCsCmdNo W",
      ">wCsIOSeq W",
      ">dwUin D"
      );
    dissectors.add( t, buf, 0xB,
      ">xxoo_a", 3,
      ">dwClientType D",
      ">dwPubNo D",
      ">xxoo_d",
      ">bufCsPrefix", 0x10
      );
  end

  local rest = buf:len() - 1 - 0x2A;
  local data = buf:raw( 0x2A, rest );
  
  local refkeyname,refkey, ds = dissectors.TeanDecrypt( data );
  if ds == nil or #ds == 0 then
    t:add( proto, buf( 0x2A, rest ), string.format(
      "GeneralCodec_Request [%04X] 解密失败！！！！",
      rest )
      );
    return;
  end
  data = ByteArray.new( ds, true ):tvb( "Decode" );

  local info = string.format(
    "GeneralCodec_Request [%04X] >> [%04X]       With Key",
    rest,
    data:len()
    );
  local c, s, n = TXSSO2_AnalysisKeyName( refkeyname );
  if c then
    if n == tostring( pkg.number ) then
      info = info .. "    by frame self ↑↑↑";
    else
      info = info .. ":" .. refkey:sub( 1, 0x10 ):hex2str( true ) .. "       form FrameNum:" .. n;
    end
  else
    info = info .. "[" .. refkeyname .. "]:" .. refkey:sub( 1, 0x10 ):hex2str( true );
  end
  local tt = t:add( proto, buf( 0x2A, rest ), info );

  dissectors.dis_tlv( data, pkg, root, tt, 0, data:len() );
end

dissectors[0x3649][0x0825].recv = function( buf, pkg, root, t )
  local ver = buf( 1, 2 ):uint();
  local cmd = buf( 1 + 1 + 1, 2 ):uint();
  local seq = buf( 1 + 1 + 1 + 2, 2 ):uint();

  local lvl = aly_lvl();

  if lvl >= alvlC then
    local tt = t:add( proto, buf( 1, 0xA ), "bufPacketHeader");
    dissectors.add( tt, buf, 1,
      ">cMainVer B",
      ">cSubVer B",
      ">wCsCmdNo W",
      ">wCsIOSeq W",
      ">dwUin D"
      );
    dissectors.add( t, buf, 0xB,
      ">xxoo_a", 3
      );
  end

  local rest = buf:len() - 1 - 0xE;
  local data = buf:raw( 0xE, rest );
  
  local refkeyname,refkey, ds = dissectors.TeanDecrypt( data );
  if ds == nil or #ds == 0 then
    t:add( proto, buf( 0xE, rest ), string.format(
      "GeneralCodec_Response [%04X] 解密失败！！！！",
      rest )
      );
    return;
  end
  data = ByteArray.new( ds, true ):tvb( "Decode" );

  local info = string.format(
    "GeneralCodec_Response [%04X] >> [%04X]       With Key",
    rest,
    data:len()
    );
  local c, s, n = TXSSO2_AnalysisKeyName( refkeyname );
  if c then
    if n == tostring( pkg.number ) then
      info = info .. "    by frame self ↑↑↑";
    else
      info = info .. ":" .. refkey:sub( 1, 0x10 ):hex2str( true ) .. "       form FrameNum:" .. n;
    end
  else
    info = info .. "[" .. refkeyname .. "]:" .. refkey:sub( 1, 0x10 ):hex2str( true );
  end
  local tt = t:add( proto, buf( 0xE, rest ), info );
  
  local off = 0;
  off = dissectors.add( tt, data, off, ">cResult" );

  dissectors.dis_tlv( data, pkg, root, tt, off, data:len() - off );
end