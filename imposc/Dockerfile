FROM elixir:slim


# Install Gnuplot (needed for Gnuplot-Elixir)
RUN apt-get update
RUN apt-get install -y gnuplot

#Copy the source folder into the Docker image
COPY . .

#Install dependencies 
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix do deps.get, deps.compile, compile

#Set environment variables and expose port
EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

#Set default entrypoint 
ENTRYPOINT ["mix", "run", "--no-halt"]
