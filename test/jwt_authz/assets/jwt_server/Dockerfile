FROM elixir:1.14.0

ADD . /app
WORKDIR /app

RUN mix do local.hex --force, local.rebar --force, deps.get, compile

EXPOSE 4001
