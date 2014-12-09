%% Copyright (c) 2014 Radoslaw Gruchalski <radek@gruchalski.com>
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.

-module(web_api_v1_overlays).

-export([init/2]).

init(Req, Opts) ->
  {ok, reply(cowboy_req:method(Req), Req), Opts}.

reply(<<"GET">>, Req) ->
  reply_with_data(data, Req);
reply(_, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).

reply_with_data(data, Req) ->
  case gen_server:call( gossiperl_web, { authorize, rest_user, Req } ) of
    authorized ->
      Response = jsx:encode( [
        { overlays, gossiperl_sup:list_overlays() },
        { operation, <<"overlays">> },
        { timestamp, gossiperl_common:get_timestamp() }
      ] ),
      cowboy_req:reply(200, [
        {<<"content-type">>, <<"application/json; charset=utf-8">>}
      ], Response, Req);
    { error, not_configured } ->
      cowboy_req:reply(412, [], <<"Superuser not configured.">>, Req);
    { error, no_auth } ->
      cowboy_req:reply(401, [
        {<<"www-authenticate">>, <<"Basic realm=\"Overlays\"">>}
      ], <<"Authorization required.">>, Req)
  end.
  