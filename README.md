# Impact Oscillator
## Overview
This project is an opportunity for me to gain experience of functional programming in [Elixir](https://elixir-lang.org/), while at the same time indulging in a bit of nostalgia by revisiting the research I did for my PhD. I have not kept up to date with research developments in the field since I left academia and so nothing in this project is likely to contribute to current research. Instead my aim is to reproduce the programming aspects of the work I did then, but with the benefit of 3 decades of software engineering experience and using a language and programming techniques which were not available back then.

- [Mathematical Background](maths.md)
- [Architectural Overview](architecture.md)

## Functionality
TBD

## Installing and Running
The charting functions use [Gnuplot Elixir](https://github.com/devstopfix/gnuplot-elixir). While this will be installed by `mix deps.get`, [Gnuplot](http://www.gnuplot.info/) itself must be installed separately.

The [Elixir](https://elixir-lang.org/) project is in the subdirectory `./imposc`. There are four ways of accessing the functionality:

- A REST server launched by `mix run --no-halt`
- The same REST server inside a [Docker](https://hub.docker.com/) container, which can be built by `make build` and launched by `make run`
- A command-line script, which can be built by `mix escript.build` and launched by `./imposc` and which has two modes, a one-shot mode which accepts a JSON string on the standard input and a console mode.
- Inside `iex -S mix`:
    - `iex> Console.run()` launches the console
    - `iex> File.read!(file_name) |> CoreWrapper.process_input_string` runs a one-shot mode from the specified file
