# Impact Oscillator
## Overview
This project is an opportunity for me to gain experience of functional programming in [Elixir](https://elixir-lang.org/), while at the same time indulging in a bit of nostalgia by revisiting the research I did for my PhD. I have not kept up to date with research developments in the field since I left academia and so nothing in this project is likely to contribute to current research. Instead my aim is to reproduce the programming aspects of the work I did then, but with the benefit of 3 decades of software engineering experience and using a language and programming techniques which were not available back then.

## Installing and Running
### Main Application (Subdirectory `./apps/imposc/`)
The charting functions use [Gnuplot Elixir](https://github.com/devstopfix/gnuplot-elixir). While this will be installed by `mix deps.get`, [Gnuplot](http://www.gnuplot.info/) itself must be installed separately.

The [Elixir](https://elixir-lang.org/) project is in the subdirectory `./apps/imposc/`. There are four ways of accessing the functionality:

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

## Mathematical Background
I completed my PhD in 1992 and have not followed academic developments since that time, so the work described here is probably outdated and makes no reference to more recent research.

Most of my thesis was devoted to a simple mathematical model comprising a simple harmonic oscillator whose motion is constrained by a hard obstacle, from which it rebounds instantaneously:

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

### The Impact Map
A *Poincar&#233; map* is a useful way of reducing a continuous dynamical system to a discrete system with one fewer dimensions. In this case the form of the problem naturally induces a map - which we call the *impact map* - which takes the phase (time modulo the forcing period) and velocity at one impact to the phase and velocity at the next impact. What makes it interesting is that it does not strictly conform to the textbook definition of a Poincar&#233; map, because when impacts occur with zero velocity the trajectory in phase space is tangential to the surface ![equation](https://latex.codecogs.com/svg.latex?x%3D%5Csigma) . At points which map to zero-velocity impacts, the impact map is not only discontinuous but singular. This underlies many of the complex dynamics which are observed for some parameter ranges.

### Periodic Orbits
Periodic motions can be classified by labelling them with two numbers, the number of impacts in a cycle and the number of forcing periods, so that a (*m*, *n*) orbit repeats itself after *m* impacts and *n* forcing cycles. The simplest of these are (1, *n*) orbits, which correspond to fixed points of the impact map. These can be extensively studied analytically and formulas can be obtained for the impact velocity *V<sub>n</sub>* as the parameters ![equation](https://latex.codecogs.com/svg.latex?%5Comega), ![equation](https://latex.codecogs.com/svg.latex?%5Csigma) and *r* are varied.

This reveals that, as ![equation](https://latex.codecogs.com/svg.latex?%5Csigma) is varied while ![equation](https://latex.codecogs.com/svg.latex?%5Comega) and *r* are held fixed, the *V<sub>n</sub>*-response curve is an ellipse (or rather half an ellipse as negative *V<sub>n</sub>* is of no interest), centred on the origin. As ![equation](https://latex.codecogs.com/svg.latex?%5Comega) is varied, this ellipse rotates, so that its major axis is vertical for ![equation](https://latex.codecogs.com/svg.latex?%5Comega%3D2n), is tilted into the negative ![equation](https://latex.codecogs.com/svg.latex?%5Csigma) quadrant (for positive *V<sub>n</sub>*) for ![equation](https://latex.codecogs.com/svg.latex?%5Comega%3C2n) and into the positive ![equation](https://latex.codecogs.com/svg.latex?%5Csigma) quadrant for ![equation](https://latex.codecogs.com/svg.latex?%5Comega%3E2n). In the tilted cases, the lower branch of the half-ellipse always corresponds to dynamically unstable orbits. The point where the upper and lower branches meet corresponds to a *saddle-node* or *fold* bifurcation. As we vary  and move away from this point, the orbit corresponding to the upper branch will remain stable until either (i) it loses stability to a period-doubling bifurcation and is replaced by a (2, 2*n*) orbit or (ii) it is destroyed by the occurence of an intervening impact, which makes the analytically-derived (1, *n*) orbit unphysical. Case (i) is typically the prelude to a period-doubling cascade of a kind familiar to anyone who has studied chaotic dynamical systems.

It turns out that, at least for small values of ![equation](https://latex.codecogs.com/svg.latex?%5Csigma) , forcing frequencies near the 'resonant' values ![equation](https://latex.codecogs.com/svg.latex?%5Comega%3D2n%2C%20n%3D1%2C2%2C3%20...) are associated with comparatively simple dynamics dominated by globally attracting (1, *n*) orbits, while the intervening regions of parameter space are characterised by much more complex behaviour, including chaotic attractors and multiple competing periodic orbits.

### 'Grazing'
My supervisor coined the term 'grazing' for a kind of bifurcation in which a periodic orbit is destroyed by the occurence of an intervening impact. At the bifurcation point, this intervening impact has zero velocity, hence the term 'grazing'. This phenomenon can be investigated in terms of the geometry of the impact map by studying the set *S* of impact points which map to a zero velocity impact. This has the form of a 'branched manifold', i.e. a set of curves of codimension 1 which branch off each other at various points. If one draws a line transverse to this manifold and observes how the image of the impact map ![equation](https://latex.codecogs.com/svg.latex?%28%5Cphi_%7B1%7D%2C%20v_%7B1%7D%29) varies as one moves along the line, one finds that, as one crosses *S* from one direction (the *'non-impact side'*) *v<sub>1</sub>* drops discontinuously to zero, while as one approaches *S* from the other direction (the *'impact side'*) it drops continuously to zero but at a rate which ![equation](https://latex.codecogs.com/svg.latex?%5Csim%20-1/v_%7B1%7D) as ![equation](https://latex.codecogs.com/svg.latex?v_%7B1%7D%5Crightarrow%200). This results in a strong local distortion of the phase flow. It also means that much of the local dynamics can be understood by reference to a one-dimensional map.

The occurrence of intervening low-velocity impacts combined with the fact that, on the *non-impact side*, the dynamics continues to behave as if there were no intervening impact, helps to explain why for parameter values in the neighbourhood of a 'grazing' bifurcation of a stable (1, *n*) orbit, one often observes the appearance of competing (3, 3*n*) orbits. 

A chapter of my thesis was devoted to a particularly striking instance of 'grazing', which occurs in the resonant case ![equation](https://latex.codecogs.com/svg.latex?%5Comega%20%3D2n), which has certain simplifying features which make it particularly instructive.

### 'Sticking' and 'Chatter'
'Grazing' occurs when a point ![equation](https://latex.codecogs.com/svg.latex?%28%5Cphi%2C%200%29) on the impact surface corresponds to a local maximum of the motion *x*(*t*). In general, there will also be a range of points ![equation](https://latex.codecogs.com/svg.latex?%28%5Cphi%2C%200%29) for which the acceleration is positive and so the mass will be temporarily held motionless against the obstacle. If a low velocity impact occurs near this region, there will be an infinite sequence of low-velocity impacts converging in a finite time on a zero-velocity impact. This corresponds physically to a low-energy juddering of the mass against the obstacle. Our numerical simulation has to detect this behaviour and suitably truncate the infinite sequence. This behaviour can occur as part of a periodic orbit, in which case we label it ![equation](https://latex.codecogs.com/svg.latex?%28%5Cinfty%20%2C%20n%29).

### References
- F Dux “The Dynamics of Impact Oscillators”. PhD Thesis (1992). University of Bristol.
- [C Budd and F Dux “Intermittency in Impact Oscillators Close to Resonance”.  Nonlinearity 7 (1994) 1191-1224](https://iopscience.iop.org/article/10.1088/0951-7715/7/4/007/meta)
- [C Budd and F Dux “Chattering and Related Behaviour in Impact Oscillators”.  Phil, Trans. R. Soc. Lond. A (1994) 347, 365-389](https://royalsocietypublishing.org/doi/10.1098/rsta.1994.0049)
- [C Budd, F Dux and A Cliffe “The Effect of Frequency and Clearance Variations on Single-Degree-Of-Freedom Impact Oscillators”.  Journal of Sound and Vibration (1995) 184(3), 475-502 ](https://www.sciencedirect.com/science/article/abs/pii/S0022460X8570329X)

## Functionality
The software generates graphical plots of the following:

- Scatter plots of iterated applications of the impact map for a given set of parameter values and initial conditions
- Time series plots of *x*(*t*) for a given set of parameter values and initial conditions
- ![equation](https://latex.codecogs.com/svg.latex?V_%7Bn%7D%2C%20%5Csigma) response curves for (1, *n*) orbits for a given values of ![equation](https://latex.codecogs.com/svg.latex?%5Comega) and *r*, showing bifurcation points where orbits become dynamically unstable or unphysical (the latter established numerically)

Various other interesting plots will come later, time permitting.

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
- **REST server** a REST API which accepts requests, which it interprets into core and charts commands via the core 
wrapper
- **Command line interface**: CLI which launches the application in one of two modes:
    - a one-shot mode which accepts JSON from the standard input, interprets it into core and charts commands via the core 
     wrapper, returns any text output (e.g. JSON) to the standard output and exits.
    - a mode which launches the console interface
   
### Web Client (not yet implemented)
A web application which sends requests to the REST server. It provides forms for constructing requests (using the core 
wrapper) and renders the responses.
