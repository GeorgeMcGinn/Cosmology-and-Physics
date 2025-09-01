# Cosmology and Physics

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) ![](https://img.shields.io/badge/Linux-Any-blue.svg) ![](https://img.shields.io/badge/Windows-10+-blue.svg) ![](https://img.shields.io/badge/MacOS-Current-blue.svg)


##### Possible Languages Used:
[![Language: C](https://img.shields.io/badge/Language-C-red.svg)](https://en.wikipedia.org/wiki/C_(programming_language)) [![Language: Python](https://img.shields.io/badge/Language-Python-red.svg)](https://www.python.org/) [![Language: QB64](https://img.shields.io/badge/Language-QB64-red.svg)](https://qb64phoenix.com/) [![Language: R](https://img.shields.io/badge/Language-R-red.svg)](https://cran.r-project.org/) [![Language: NASM](https://img.shields.io/badge/Language-NASM-red.svg)](https://www.nasm.us/) [![Language: mySQL](https://img.shields.io/badge/Language-mySQL-red.svg)](https://www.mysql.com/)

## Introduction

Cosmology and Physics is a collection of scientific computing tools designed to model and answer questions on physics, cosmology, astronomy and other space sciences.

This repository provides computational solutions for analyzing extreme astrophysical scenarios, planetary dynamics, radiation physics, and fundamental cosmological problems. The tools implement both classical and modern physics principles, including relativistic mechanics, gravitational interactions, and energy transfer mechanisms.

Each toolkit is implemented across multiple programming languages (C, Python, QB64, R, ASM, etc.) to ensure accessibility for researchers, educators, and students working in different computational environments. The implementations emphasize numerical accuracy and scientific rigor while maintaining clear, educational code structure.

The software is designed for educational purposes, research applications, and theoretical exploration of astrophysical phenomena. All calculations are based on established physics principles and peer-reviewed scientific literature.

## Development Environment Requirements

The following shows the languages used (now and future software) and the versions each was tested on, along with installation guidance.

|LANGUAGE|VERSION TESTED|INSTALLATION|
|---------|-------------|------------|
|C/C++|GCC/G++ 11.4.0|**Linux:** Use your distribution's package manager (build-essential, gcc, etc.) **macOS:** Install Xcode Command Line Tools or Homebrew **Windows:** MinGW-w64, Visual Studio, or WSL|
|Python|Python 3.10.12 (should work with 3.6+)|Install from [python.org](https://python.org) or use your system's package manager|
|QB64|QB64 Phoenix Edition (latest)|Install from [QB64 Phoenix Edition GitHub](https://github.com/QB64-Phoenix-Edition/QB64pe) and follow the installation instructions|
|R Script|R 4.1.2 (2021-11-01)|Install from [r-project.org](https://r-project.org) or use your system's package manager|
|ASM|NASM 2.15.05|**Linux:** Use your distribution's package manager **macOS/Windows:** Download from [nasm.us](https://www.nasm.us/) or use Homebrew|
|mySQL/MariaDB|mySQL 8+<br>MariaDB 6.4+|Install from [mySQL](https://www.mysql.com/) or [MariaDB](https://mariadb.org/) or use your system's package manager|


**Note:** All C code is written to compile and run in both C and C++ environments. Python compatibility is guaranteed for 3.10.12+ but should work with earlier versions down to 3.6.


## Contents

### <u>Planetary Impact Physics Simulator</u>
> 
> **Directory:** [`planetary-impact-physics/`](planetary-impact-physics/)
> 
> A scientific computing toolkit for modeling extreme astrophysical impact scenarios. This suite calculates the energy requirements for planetary-scale events and estimates resulting radiation effects using both classical and relativistic physics models.
> 
> #### Key Components
> 
> - **unbindEnergy**: Calculates impactor requirements to overcome the selected planet/celestial body's gravitational binding energy
>   - Mass-to-velocity calculations with relativistic corrections
>   - Size-based impact modeling with density considerations  
>   - Comparative analysis using Mercury and Ceres mass scales
>   - Planet-specific atmospheric effects from Earth's dense atmosphere to Moon's virtual vacuum
>   
> - **unbindDose**: Models radiation exposure from high-energy impact events
>   - Distance-dependent dose calculations in Grays (Gy)
>   - Angular exposure corrections for realistic scenarios
>   - Safety threshold warnings for biological effects
>   - Optional atmospheric transmission modeling
> 
> #### Implementation Languages
> 
> - **C**: High-performance native execution with mathematical precision
> - **Python**: Cross-platform compatibility with scientific libraries
> - **QB64**: Legacy BASIC implementation for educational environments
> 
> #### Scientific Applications
> 
> - Astrophysical research and impact crater modeling
> - Planetary defense scenario analysis
> - Educational demonstrations of relativistic physics
> - Comparative planetology and scaling law studies
> 
> **Requirements**: GCC, Python 3.6+, QB64, basic mathematical libraries  
> **License**: MIT License

---

*Subdirectory sections will be added below as new tools are developed.*