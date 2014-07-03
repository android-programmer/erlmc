%%%-------------------------------------------------------------------
%%% @author P.Y. <peter.yuen@chaatz.com>
%%% @copyright (C) 2014, Chaatz Limited
%%% @doc
%%%
%%% @end
%%% Created : 02. Jul 2014 3:40 PM
%%%-------------------------------------------------------------------
-module(erlcb).
-author("P.Y. <peter.yuen@chaatz.com>").

-include("erlmc.hrl").
%% API
-compile(export_all).

encode_request(Opcode, KeySize, ExtrasSize, DataType, Reserved, BodySize, Opaque, CAS) ->
  Magic = 16#80,
  <<Magic:8, Opcode:8, KeySize:16, ExtrasSize:8, DataType:8, Reserved:16, BodySize:32, Opaque:32, CAS:64>>.

encode_request(Opcode, KeySize, ExtrasSize, DataType, Reserved, BodySize, Opaque, CAS, Body) ->
  Magic = 16#80,
  <<Magic:8, Opcode:8, KeySize:16, ExtrasSize:8, DataType:8, Reserved:16, BodySize:32, Opaque:32, CAS:64, Body:BodySize/binary>>.

encode_request(Request) when is_record(Request, plain_request) ->
  Magic = 16#80,
  Opcode = Request#plain_request.op_code,
  Extras = Request#plain_request.extras,
  ExtrasSize = size(Extras),
%%   ExtrasSize =0,
  DataType = Request#plain_request.data_type,
  VBucket = Request#plain_request.vBucket,
%%   Body = <<Extras:ExtrasSize/binary, (Request#plain_request.key)/binary, (Request#plain_request.value)/binary>>,
%%   io:format("Body:~s~n",[Body]),

  Opaque = Request#plain_request.opaque,
  CAS = Request#plain_request.cas,
  Mechanisms = <<(Request#plain_request.mechanisms)/binary>>,
  AuthToken = <<(Request#plain_request.un)/binary,(Request#plain_request.pw)/binary>>,

  MechanismsSize = size(Mechanisms),
  AuthTokenSize = size(<<AuthToken/binary>>),
  KeySize = MechanismsSize,
  BodySize = MechanismsSize + AuthTokenSize,

  io:format("Mechianism:~p~n Mech SIze : ~p~n, AuthTokenSize:~p~n, KeySize:~p~n, BodySize:~p~n",[Mechanisms,MechanismsSize,AuthTokenSize,KeySize,BodySize]),
  <<Magic:8, Opcode:8, KeySize:16, ExtrasSize:8, DataType:8, VBucket:16,
  BodySize:32, Opaque:32, CAS:64, Mechanisms:MechanismsSize/binary, AuthToken:AuthTokenSize/binary>>.

send_plain_request(Socket,{Un,Pw})->
  Bin = encode_request(#plain_request{un=Un , pw = Pw}),
  send_rec(Socket,Bin).

send_rec(Socket, Request) ->
  gen_tcp:send(Socket, Request),
  {ok, Bin} = gen_tcp:recv(Socket, 89999999999999999999),
  Bin.

plain_request() ->
  Mechanisms = <<"PLAIN">>,
  Bucket = <<"default">>,
  Username = <<"Administrator">>,
  USize = size(Username),
  Pw = <<"mosesison9">>,
  PSize = size(Pw),
  AuthToken = <<Username/binary, Pw/binary>>,
  BodySize = size(AuthToken),
  TotalBody = size(<<Mechanisms/binary, AuthToken/binary>>),
  <<?MAGIC:8, ?OP_SASL_AUTH:8, 16#00:16, 16#00:8, 16#00:8, 16#00:16, TotalBody:32, 16#00:32, 16#00:64, Mechanisms/binary, AuthToken:BodySize/binary>>.

test() ->
  R = erlcb:plain_request(),
  {ok, Socket} = gen_tcp:connect("localhost", 11211, [binary, {packet, 0}, {active, false}]),
  Res = erlcb:send_rec(Socket, R),
  io:format("~s~n", [Res]).


