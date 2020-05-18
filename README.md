# Impact Oscillator
This project is an opportunity for me to gain experience of functional programming in [Elixir](https://elixir-lang.org/), while at the same time indulging in a bit of nostalgia by revisiting the research I did for my PhD. I have not kept up to date with research developments in the field since I left academia and so nothing in this project is likely to contribute to current research. Instead my aim is to reproduce the programming aspects of the work I did then, but with the benefit of 3 decades of software engineering experience and using a language and programming techniques which were not available back then.

- [Mathematical background](maths.md)
- [Architectural overview](architecture.md)

## Installing and Running
- TBD mix deps

The charting functions use [Gnuplot Elixir](https://github.com/devstopfix/gnuplot-elixir). While this will be installed by `mix deps.get`, [Gnuplot](http://www.gnuplot.info/) itself must be installed separately.

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

###TBD
- impact map
- (1, n) orbits
- overview of behaviours
- references