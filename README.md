# Impact Oscillator
## Overview
This project is an opportunity for me to gain experience of functional programming in [Elixir](https://elixir-lang.org/), while at the same time indulging in a bit of nostalgia by revisiting the research I did for my PhD. I have not kept up to date with research developments in the field since I left academia and so nothing in this project is likely to contribute to current research. Instead my aim is to reproduce the programming aspects of the work I did then, but with the benefit of 3 decades of software engineering experience and using a language and programming techniques which were not available back then.

## Mathematical Background
I completed my PhD in 1992 and have not followed academic developments since that time, so the work described here is probably outdated and makes no reference to more recent research.

Most of my thesis was devoted to a simple mathematical model comprising a simple harmonic oscillator whose motion is constrained by a hard obstacle, from which it rebounds instantaneously:

\begin{equation}
M\frac{\mathrm{d}^2 X}{\mathrm{d} T^2} + 2D\frac{\mathrm{d} X}{\mathrm{d} T}+KX=F\cos \left ( \omega T \right ), X<S
\end{equation}

\begin{equation}
\frac{\mathrm{d} X}{\mathrm{d} T} \mapsto -r\frac{\mathrm{d} X}{\mathrm{d} T}, X = S
\end{equation}

![equation](https://latex.codecogs.com/svg.latex?M%5Cfrac%7B%5Cmathrm%7Bd%5E%7B2%7D%7D%20X%7D%7B%5Cmathrm%7Bd%7D%20T%5E%7B2%7D%7D&plus;2D%5Cfrac%7B%5Cmathrm%7Bd%7D%20X%7D%7B%5Cmathrm%7Bd%7D%20T%7D&plus;KX%3DF%5Ccos%20%5Cleft%20%28%20%5COmega%20T%20%5Cright%20%29%2C%20X%20%3C%20S)

![equation](https://latex.codecogs.com/svg.latex?%5Cfrac%7B%5Cmathrm%7Bd%7D%20X%7D%7B%5Cmathrm%7Bd%7D%20T%7D%20%5Cmapsto%20-r%5Cfrac%7B%5Cmathrm%7Bd%7D%20X%7D%7B%5Cmathrm%7Bd%7D%20T%7D%2C%20X%20%3D%20S)

where
![equation](https://latex.codecogs.com/svg.latex?0%20%3C%20r%3C%201)

This can be nondimensionalised as follows:

![equation](https://latex.codecogs.com/svg.latex?x%3D%5Cfrac%7BK%7D%7BF%7DX%2C%20t%3D%5Csqrt%7B%5Cfrac%7BK%7D%7BM%7D%7DT)

which gives:

![equation](https://latex.codecogs.com/svg.latex?%5Cddot%7Bx%7D&plus;2%5Calpha%20%5Cdot%7Bx%7D&plus;x%3D%20%5Ccos%5Cleft%20%28%20%5Comega%20t%20%5Cright%20%29%2C%20x%20%3C%20%5Csigma)

![equation](https://latex.codecogs.com/svg.latex?%5Cdot%7Bx%7D%20%5Cmapsto%20-r%20%5Cdot%7Bx%7D%2C%20x%20%3D%20%5Csigma)

where

![equation](https://latex.codecogs.com/svg.latex?%5Calpha%20%3D%20%5Cfrac%7BD%7D%7B%5Csqrt%7BMK%7D%7D%2C%20%5Comega%20%3D%20%5COmega%20%5Csqrt%7B%5Cfrac%7BM%7D%7BK%7D%7D%2C%20%5Csigma%3D%5Cfrac%7BK%7D%7BF%7DS)

Because a coefficient of restitution of less than 1 is sufficient to introduce dissipation into the system, for most of my thesis I simplified further by setting the damping coefficient ![equation](https://latex.codecogs.com/svg.latex?%5Calpha) to zero, so that the problem reduces to:

![equation](https://latex.codecogs.com/svg.latex?%5Cddot%7Bx%7D&plus;x%3D%20%5Ccos%5Cleft%20%28%20%5Comega%20t%20%5Cright%20%29%2C%20x%20%3C%20%5Csigma)


![equation](https://latex.codecogs.com/svg.latex?%5Cdot%7Bx%7D%20%5Cmapsto%20-r%20%5Cdot%7Bx%7D%2C%20x%20%3D%20%5Csigma)

The impact introduces a discontinuity into the system which makes it strongly nonlinear, so that it exhibits many of the complex behaviours associated with nonlinear dynamical systems.

###TBD
- impact map
- (1, n) orbits
- overview of behaviours
- references

## Functionality
TBD

## Installing and Running
### Main Application (Subdirectory `./imposc`)
The charting functions use [Gnuplot Elixir](https://github.com/devstopfix/gnuplot-elixir). While this will be installed by `mix deps.get`, [Gnuplot](http://www.gnuplot.info/) itself must be installed separately.

The [Elixir](https://elixir-lang.org/) project is in the subdirectory `./imposc`. There are four ways of accessing the functionality:

- A REST server launched by `mix run --no-halt`
- The same REST server inside a [Docker](https://hub.docker.com/) container, which can be built by `make build` and launched by `make run`
- A command-line script, which can be built by `mix escript.build` and launched by `./imposc` and which has two modes, a one-shot mode which accepts a JSON string on the standard input and a console mode.
- Inside `iex -S mix`:
    - `iex> Console.run()` launches the console
    - `iex> File.read!(file_name) |> CoreWrapper.process_input_string` runs a one-shot mode from the specified file

### Web Client (not yet implemented)
All of the above is not very user-friendly because, with the exception of the console (which only has limited functionality) it requires inputs in JSON format.

Next on the to-do list, therefore, is to implement a separate web application which will send requests to the REST server. It will provide forms for constructing requests and will render the responses.

I have chosen this approach rather than, say, implementing a GUI in [Scenic](https://github.com/boydm/scenic) because:

- I can easily wrap both client and server in Docker containers
- It gave me an excuse to have a go at a REST API

The Web client will have its own project in this repository and will probably not be written in Elixir, simply because I would like to mix things up a bit.

## Architecture
### Main Application
- **Core**: this is the bit which does the maths. It comprises functions which return nested collections suitable for 
JSON-ising.
- **Charts**: this accepts nested collections as generated by core functions and generates charts, which are either 
directed to the display or to PNG files.
- **Core wrapper**: accepts (JSON-compatible) nested collections as input and interprets them into core function calls, 
directing the output where appropriate to charts calls
- **Console interface**: runs in a terminal and accepts user commands, which it interprets into core and charts commands
via the core wrapper
- **REST server** REST API which accepts requests, which it interprets into core and charts commands via the core 
wrapper
- **Command line interface**: CLI which launches the application in one of two modes:

   - a one-shot mode which accepts JSON from the standard input, interprets it into core and charts commands via the core 
     wrapper, returns any text output (e.g. JSON) to the standard output and exits.
   - a mode which launches the console interface
   
### Web Client (not yet implemented)
A web application which sends requests to the REST server. It provides forms for constructing requests (using the core 
wrapper) and renders the responses.